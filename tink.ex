defmodule Tink do
  @moduledoc """
  tink data-flow node frame protocol (universal, language-agnostic).

  Frame = `[len u32 BE][payload][crc u32 BE]`; `crc` = CRC32-IEEE (0xEDB88320).
  Mirrors `std/tink.tie` (tie standard library) and the other-language tink
  libraries; pure functions over binaries, IO (stdin/stdout) left to the
  caller. Elixir / Erlang, no dependencies.
  """

  @mask 0xFFFFFFFF

  @doc """
  CRC32-IEEE over an IO data binary (bit-loop, no table).
  Check vector: `Tink.crc32("123456789") == 0xCBF43926`.
  """
  @spec crc32(binary()) :: non_neg_integer()
  def crc32(data) do
    crc =
      :binary.bin_to_list(data)
      |> Enum.reduce(@mask, fn b, acc -> crc_byte(b, acc) end)

    Bitwise.band(Bitwise.bxor(crc, @mask), @mask)
  end

  defp crc_byte(b, crc) do
    crc = Bitwise.bxor(crc, b)
    Enum.reduce(1..8, crc, fn _, acc ->
      Bitwise.band(acc, 1)
      |> case do
        0 -> Bitwise.bsr(acc, 1) |> Bitwise.band(@mask)
        _ -> Bitwise.bxor(Bitwise.bsr(acc, 1), 0xEDB88320) |> Bitwise.band(@mask)
      end
    end)
  end

  @doc """
  Encode a payload into a full frame: `[len u32 BE][payload][crc u32 BE]`.
  Returns a binary of `byte_size(payload) + 8` bytes.
  """
  @spec frame_encode(binary()) :: binary()
  def frame_encode(payload) do
    n = byte_size(payload)
    <<n::unsigned-big-32>> <> payload <> <<crc32(payload)::unsigned-big-32>>
  end

  @doc """
  Parse one frame at `pos` (verifies CRC). Returns `{payload, next}` on
  success, or `nil` on out-of-bounds / CRC mismatch. The payload is a copy.
  """
  @spec frame_next(binary(), non_neg_integer()) :: {binary(), non_neg_integer()} | nil
  def frame_next(bytes, pos) when pos >= 0 do
    if byte_size(bytes) < pos + 8 do
      nil
    else
      <<_::binary-size(pos), n::unsigned-big-32, rest::binary>> = bytes
      if byte_size(rest) < n + 4 do
        nil
      else
        <<payload::binary-size(n), want::unsigned-big-32, _::binary>> = rest
        if crc32(payload) == want do
          {payload, pos + 8 + n}
        else
          nil
        end
      end
    end
  end

  def frame_next(_, _), do: nil

  @doc """
  Skip one frame at `pos` without copying or verifying (zero-copy).
  Returns the position after the frame, or `nil` on out-of-bounds.
  """
  @spec frame_skip(binary(), non_neg_integer()) :: non_neg_integer() | nil
  def frame_skip(bytes, pos) when pos >= 0 do
    if byte_size(bytes) < pos + 8 do
      nil
    else
      <<_::binary-size(pos), n::unsigned-big-32, rest::binary>> = bytes
      if byte_size(rest) < n + 4 do
        nil
      else
        pos + 8 + n
      end
    end
  end

  def frame_skip(_, _), do: nil
end
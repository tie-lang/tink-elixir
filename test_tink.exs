# test_tink.exs —— unit tests for tink.ex. Run: elixir test_tink.exs
Code.require_file("tink.ex", __DIR__)

failures = :ets.new(:failures, [:named_table])
:ets.insert(failures, {:n, 0})

check = fn cond, name ->
  if cond do
    IO.puts("[PASS] #{name}")
  else
    :ets.update_counter(failures, :n, 2, {:n, 1})
    IO.puts("[FAIL] #{name}")
  end
end

# crc32 check vector (0xCBF43926)
check.(Tink.crc32("123456789") == 0xCBF43926, "crc32 vector")

# frame roundtrip
p = <<1, 2, 3>>
frame = Tink.frame_encode(p)
check.(byte_size(frame) == byte_size(p) + 8, "frame length")
case Tink.frame_next(frame, 0) do
  {payload, next} ->
    check.(next == byte_size(frame), "frame next == length")
    check.(payload == p, "frame payload roundtrip")
  nil ->
    check.(false, "frame present")
end

# empty frame roundtrip
fe = Tink.frame_encode("")
case Tink.frame_next(fe, 0) do
  {payload, next} -> check.(next == byte_size(fe) and byte_size(payload) == 0, "empty frame roundtrip")
  nil -> check.(false, "empty frame present")
end

# CRC tamper rejected
ft = Tink.frame_encode(p)
<<a, b, c, d, e, f, g, h, i, j, k>> = ft
ft2 = <<a, b, c, d, e + 1, f, g, h, i, j, k>> # tamper payload[0]
check.(Tink.frame_next(ft2, 0) == nil, "crc tamper rejected")

# frame_skip matches length
fs = Tink.frame_encode(p)
check.(Tink.frame_skip(fs, 0) == byte_size(fs), "frame_skip matches length")

# out of bounds
check.(Tink.frame_next(frame, byte_size(frame)) == nil, "frame_next out of bounds")
check.(Tink.frame_skip(frame, byte_size(frame)) == nil, "frame_skip out of bounds")
check.(Tink.frame_next("", 0) == nil, "frame_next empty input")

if :ets.lookup(failures, :n) |> hd() |> elem(1) > 0 do
  IO.puts("some checks FAILED")
  System.halt(1)
end
IO.puts("all tests passed")
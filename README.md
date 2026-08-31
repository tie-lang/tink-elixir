# tink-elixir

tink data-flow node frame protocol — Elixir module (no dependencies).
Universal and language-agnostic: any component that obeys the frame protocol
can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries; pure functions over binaries, IO (stdin/stdout) left to the caller.
Names follow the Elixir convention (`Tink` module, snake_case functions).

## API (`module Tink`)

| function | description |
| --- | --- |
| `Tink.crc32(data) -> non_neg_integer` | CRC32-IEEE over a binary. Check vector: `Tink.crc32("123456789") == 0xCBF43926` |
| `Tink.frame_encode(payload) -> binary` | encode a payload into a full frame `[len][payload][crc]` |
| `Tink.frame_next(bytes, pos) -> {payload, next} \| nil` | parse one frame at `pos`, verify CRC; `nil` on out-of-bounds / mismatch |
| `Tink.frame_skip(bytes, pos) -> pos \| nil` | skip one frame at `pos` without copying or verifying; `nil` on out-of-bounds |

## Usage

```elixir
frame = Tink.frame_encode(<<1, 2, 3>>)
case Tink.frame_next(frame, 0) do
  {payload, next} -> :ok
  nil -> :error
end
```

## Test

```bash
elixir test_tink.exs
```

## Cross-language

tink 帧协议各语言实现（API 语义与校验向量一致）：

| language | library |
| --- | --- |
| tie | `std/tink.tie` |
| Rust | `tink-rust`（tink crate） |
| C | `tink-c`（`tink.h` + `tink.c`） |
| Python | `tink-python`（`tink.py`） |
| JavaScript | `tink-js`（`tink.js` + `tink.d.ts`） |
| C++ | `tink-cpp`（`tink.hpp`） |
| Java | `tink-java`（`org.tielang.tink`） |
| C# | `tink-csharp`（namespace `Tink`） |
| Go | `tink-go`（package `tink`） |
| Zig | `tink-zig`（`tink.zig`） |
| Lua | `tink-lua`（`tink.lua`） |
| GDScript | `tink-godot`（`tink.gd`） |
| F# | `tink-fsharp`（`Tink.fs`） |
| PowerShell | `tink-powershell`（`tink.ps1`） |
| Kotlin | `tink-kotlin`（`Tink.kt`） |
| Ruby | `tink-ruby`（`tink.rb`） |
| Julia | `tink-julia`（`tink.jl`） |
| Nim | `tink-nim`（`tink.nim`） |
| Dart | `tink-dart`（`tink.dart`） |
| Crystal | `tink-crystal`（`tink.cr`） |
| PHP | `tink-php`（`tink.php`） |
| V | `tink-v`（`tink.v`） |
| Odin | `tink-odin`（`tink.odin`） |
| Elixir | this module（`tink-elixir`） |

## License

本仓库使用 **TIE-LANG Open Source License v1.1**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **TIE-LANG Open Source License v1.1** — see [LICENSE](LICENSE) for the full text.
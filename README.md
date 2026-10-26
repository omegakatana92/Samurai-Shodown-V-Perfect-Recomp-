# Samurai Shodown V Perfect: static recompilation

**Samurai Shodown V Perfect (SNK, 2004 / `samsh5pf`) running as a native PC
program: its 68000 program is recompiled to C and runs on the
[neogeorecomp](https://github.com/sp00nznet/neogeorecomp) board model.**

The real MVS system ROM and the game's own code do the work: the BIOS boots,
checks its own checksum and RAM, and starts the cartridge exactly as on
hardware. There are no game-specific patches in this repository — only the
ROM layout of the set and generic hardware behaviour in the runtime.

> **No game data here.** You need your own dumps of the `samsh5pf` set and the
> `neogeo` system ROMs. The recompiled C is generated from your dump on your
> machine into `build/generated/`; it is never committed or distributed, and
> neither is anything else derived from the ROMs.

## Status

**v0.1.0, alpha — boots and plays on recompiled code.**

- Boot through the real MVS BIOS: RAM test, BIOS checksum, cartridge header
  check, watchdog reset during backup-RAM initialisation, title, attract mode.
- Coin and start are handled by the BIOS; a 1P match runs (character select,
  tutorial, stage) with the default inputs.
- The generator translates **472,131 instructions into 40,337 entry points**.
  The 19,000-frame soak (coin, start, a full match) executes
  **19,427,952 native blocks with 114 interpreted instructions and 0
  uncovered entry points** — effectively 100% recompiled.
- `--verify` re-runs every recompiled block in the Musashi interpreter and
  compares registers, flags and the **complete bus access log** (address,
  size, value, order): **0 mismatches** over 1,710,056 blocks of the
  coin/start/combat session.
- With no input, the recompiled and interpreter-only builds produce
  **pixel-identical frames** (checked at frames 3000 and 5000). With scripted
  combat input the two runs can diverge: the recompiled dispatcher takes
  interrupts at recompiled-block boundaries, while Musashi checks them
  between every instruction, so a button press can land on a different game
  frame in each build.

Audio runs through the Z80/YM2610 path and produces signal (a 30-second
scripted session captures with peak 13604, RMS 1992 at 55.5 kHz stereo), but
the mix has not been listened to yet; treat quality as unverified.

## Requirements

- CMake 3.21+ and a C/C++ toolchain (Visual Studio 2022/2026 with *Desktop
  development with C++* on Windows; gcc/g++ on Linux).
- SDL2 for the window. Headless runs do not need it. On Windows the builds in
  this tree expect `deps/SDL2-2.32.10` (CMake variable `SDL2_DIR`), on Linux
  use your distribution's SDL2 (`libsdl2-dev`).
- Your ROM files, unzipped into `roms/`:

  From `samsh5pf.zip`:
  `273-p1.bin`, `273-s1.bin`, `273-m1.bin`, `273-c1d.bin` … `273-c8d.bin`,
  `273-v1d.bin`, `273-v2d.bin`.

  From `neogeo.zip`:
  `sp-s2.sp1`, `sfix.sfix`, `sm1.sm1`, `000-lo.lo`.

## Build

```
cmake -S . -B build -DSAMSH5PF_ROM_DIR=<absolute path to this repo>/roms
cmake --build build --config Release --target samsh5pf
```

`SAMSH5PF_ROM_DIR` is needed at *build* time: the generator reads the program
ROMs and emits the C translation into `build/generated/`. Without it the
player builds interpreter-only, which is also a good way to check your ROMs
and BIOS first:

```
cmake -S . -B build-interp
cmake --build build-interp --config Release --target samsh5pf
```

To build with no window at all (headless-only), add
`-DCMAKE_DISABLE_FIND_PACKAGE_SDL2=ON` to the configure step. This is also the
way to avoid a MinGW SDL2 being picked up by an MSVC build.

## Run

```
samsh5pf.exe --rom-path roms
```

Useful flags: `--headless`, `--frames N`, `--input FILE`,
`--screenshot N:FILE`, `--wav FILE`, `--interp`, `--verify`,
`--dump-misses FILE`, `--scale N`. Run `--help` for the list.

### Controls

| Key | Action |
| --- | --- |
| Arrow keys | Move |
| Z / X / C / V | A / B / C / D |
| 5 | Coin |
| 1 | Player 1 Start |
| 2 | Player 2 Start |
| Esc | Exit |

SDL2 gamepads are supported.

## Verification

Scripted sessions under `tests/` drive the game through the BIOS:

```
samsh5pf --headless --rom-path roms --frames 6000 --dump-misses entries.txt
samsh5pf --headless --rom-path roms --frames 19000 --input tests/play_long.txt --dump-misses entries.txt
```

`entries.txt` collects entry points that are only reached at run time
(computed jumps into unrolled code). Rebuilding with it recompiles those too;
the `profile` target does both steps:

```
cmake --build build --config Release --target profile
cmake --build build --config Release --target samsh5pf
```

## Layout

```
src/game.c        ROM set definition (P/C/S/M/V layout) — the port itself
src/main.c        player entry point
src/recomp_main.c generator entry point
tests/            scripted input sessions
docs/             porting notes: ROM set, boot sequence, runtime changes
neogeorecomp/     vendored toolkit at the commit in toolkit.ref (MIT)
```

## License

The project's own code is released under the **PolyForm Noncommercial
License 1.0.0** (see `LICENSE`). Third-party components keep their own
licenses; see `NOTICE.md`.

This project contains no SNK code or data. Samurai Shodown and Neo Geo are
trademarks of SNK Corporation. You are responsible for using ROM images you
are legally allowed to use.

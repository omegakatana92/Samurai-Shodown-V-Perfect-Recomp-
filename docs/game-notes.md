# Game notes: Samurai Shodown V Perfect (`samsh5pf`)

## ROM set

The program is a single 8 MB file whose fixed 1 MB bank sits first (the
`NEO-GEO` header is at `$100` of the file), so it maps straight onto the
program region. The runtime's standard scheme — first 1 MB fixed at
`$000000`, the remaining 7 MB banked at `$200000` — applies unchanged.

| File | Size | CRC32 |
| --- | ---: | --- |
| `273-p1.bin` | 8388608 | `e3d18d3a` |
| `273-s1.bin` | 131072 | `abb3baf9` |
| `273-m1.bin` | 131072 | `654e9236` |
| `273-c1d.bin` | 8388608 | `ec9fda8d` |
| `273-c2d.bin` | 8388608 | `d2fc888d` |
| `273-c3d.bin` | 8388608 | `b0ea781b` |
| `273-c4d.bin` | 8388608 | `d34ac591` |
| `273-c5d.bin` | 8388608 | `1b5c1ea2` |
| `273-c6d.bin` | 8388608 | `deeaad58` |
| `273-c7d.bin` | 8388608 | `af90afc8` |
| `273-c8d.bin` | 8388608 | `b14872da` |
| `273-v1d.bin` | 8388608 | `3bf61586` |
| `273-v2d.bin` | 8388608 | `95fe7646` |

System ROMs (`neogeo` set; the default BIOS is `sp-s2.sp1`, MVS
Asia/Europe):

| File | Size | CRC32 |
| --- | ---: | --- |
| `sp-s2.sp1` | 131072 | `9036d879` |
| `sfix.sfix` | 131072 | `c2ea0cfd` |
| `sm1.sm1` | 131072 | `94416d67` |
| `000-lo.lo` | 131072 | `5a86cff2` |

The graphics and audio files use the decrypted `…d` variants, so no CMC/SMA
decryption step is needed. The P ROM is byte-swapped in the set (`swap = 1`
in `src/game.c`); the runtime loads it into 68000 order.

The set is distributed in ROM collections as a bootleg/hack of Samurai
Shodown V Special. The cartridge itself is a normal MVS program: it has the
standard header, boots through the stock BIOS and uses no protection device.

## Boot sequence

1. The 68000 starts from the BIOS vectors (`$C00402`) because the runtime
   selects the BIOS vector page at power-on, as the hardware does.
2. The BIOS tests work RAM, verifies its own checksum
   (`$000000-$00007F` plus `$C00082-$C1FFFF` against the byte at `$C00080`),
   clears work RAM, and initialises its menu/state block.
3. It locks backup RAM, selects the cartridge vectors and jumps to the cart's
   `USER` vector (`$122` → `$EA18`), passing a boot mode in `$10FDAE`.
4. The cartridge initialises its data and saves backup-RAM state, then
   returns to the BIOS (`jmp $C00444`). The BIOS re-enters the cartridge with
   mode 2 to start the game.

### The backup-RAM / watchdog step

At `$E778` the cartridge initialises backup RAM and writes a validation word
at `$D00100`. Between the two halves of that work it runs a fixed delay:

```
00E7CA  move.l  #$30d40,D0
00E7D0  subq.l  #1,D0
00E7D2  bcc     $E7D0
```

0x30D40 iterations take longer than the board's watchdog timeout
(3,244,030 master clocks, ~135 ms), so on real hardware the board resets in
the middle of the delay. The reboot runs with valid backup RAM and the game
continues. This is the deliberate protection scheme documented in MAME's
Neo Geo driver:

> if the game doesn't find valid data in the backup ram it will initialize
> it, then sit in a loop. The watchdog should then reset the system while it
> is in this loop. If the watchdog fails to reset the system the code will
> continue and set a value in backup ram to indicate that the protection
> check has failed.

A runtime without the watchdog never resets, falls through, marks the check
as failed and parks forever on the cartridge's own screen:

```
WARNING
THIS ROM CARTRIDGE IS FOR USE WITH ORIGINAL SNK BOARDS ONLY
```

Implementing the watchdog fixed the boot with no game-specific code; see
`runtime-changes.md`.

## Cartridge entry points

| Header | Value | Meaning |
| --- | --- | --- |
| `$122` | `$EA18` | `USER` (boot / per-frame service) |
| `$128` | `$EAEA` | player start |
| `$12E` | `$EAF8` | demo start (clears palette) |
| `$134` | `$EAE0` | credit |
| `$10E` | `$0010E000` | user subroutine pointer (RAM) |
| `$112` | `0x1000` | user subroutine size |

`$10FDAE` selects the boot path in `$EA18`: 0 = cold initialisation,
2 = game start with no saved settings, 3 = game start with saved settings.

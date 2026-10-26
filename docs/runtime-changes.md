# Changes to the vendored runtime

`neogeorecomp/` is the upstream toolkit at the commit in `toolkit.ref` plus
the changes below. All of them are generic board behaviour, not game-specific
hacks.

## Watchdog timer (`io.c`, `neogeo.c`, `ng_internal.h`)

The runtime had no watchdog. The real board resets the 68000 if `$300001` is
not written for 3,244,030 master clocks ([MAME's timing](https://github.com/mamedev/mame/blob/master/src/mame/snk/neogeo.cpp)),
and several SNK titles use a longer-than-timeout busy-wait as a deliberate
reset (see `game-notes.md`).

- `io_watchdog_kick()` is called from an odd write in `$300000-$31FFFF`
  (`$300001` is the watchdog register; mirrors cover the block).
- `neogeo.c` includes the deadline in the scheduler, and on expiry runs a
  board reset: `bus_reset`, `lspc_reset`, palette bank 0, BIOS fix/audio
  select, `audio_reset`, `exec_reset`. Work RAM and backup RAM are preserved,
  as on hardware. IRQ3 is *not* re-asserted: MAME asserts it only at
  power-on, not on a watchdog reset.
- Timeout is expressed in the runtime's 68k clock domain, so it is
  `3244030 / 2 = 1622015` clocks.

This is the only functional change; without it the port hangs on the
cartridge's anti-tamper screen.

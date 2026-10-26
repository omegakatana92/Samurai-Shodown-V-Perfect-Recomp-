# Notices

## Project code

`LICENSE` (PolyForm Noncommercial License 1.0.0) covers the code written for
this port: `src/`, `tests/`, `docs/`, the build files, and the local changes
to the runtime listed in `docs/runtime-changes.md`.

## neogeorecomp

`neogeorecomp/` is a vendored copy of the neogeorecomp toolkit
(<https://github.com/sp00nznet/neogeorecomp>) at the commit recorded in
`toolkit.ref`. It is licensed under the MIT License; the full text is in
`neogeorecomp/LICENSE`, and the upstream notices are in
`neogeorecomp/NOTICE` and `neogeorecomp/LICENSES/`. The vendored copy carries
the local hardware fixes described in `docs/runtime-changes.md`; those changes
are released under the same MIT terms as the toolkit.

## SDL2

SDL2 is not vendored here. Builds with a window link against SDL2
(<https://www.libsdl.org/>), which is distributed under the zlib license.
The optional `scripts/build-appimage.sh` bundles the `libSDL2-2.0.so.0`
runtime library inside the generated AppImage; that copy remains under the
zlib license.

## ROM data

No ROM images, BIOS images, or code generated from them are part of this
repository. The generator produces the recompiled C from the user's own ROM
files into the build directory, and `.gitignore` keeps that directory, the
`roms/` directory and any entry-point lists out of version control.

Samurai Shodown and Neo Geo are trademarks of SNK Corporation. This project
is not affiliated with or endorsed by SNK.

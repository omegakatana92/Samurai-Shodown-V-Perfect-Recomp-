#!/usr/bin/env bash
# Build the Linux x86_64 player and package a Steam Deck / Linux AppImage.
#
# Prerequisites: gcc, g++, cmake 3.21+, make, libsdl2-dev, wget, and the
# game's ROM files (the samsh5pf set plus the neogeo system ROMs), unzipped.
#
# Usage:
#   ./scripts/build-appimage.sh [ROM_DIR] [OUTPUT_APPIMAGE]
# Defaults: ROM_DIR=./roms, OUTPUT=./Samsh5pf-x86_64.AppImage
#
# The AppImage contains only the recompiled program built from *your* ROMs on
# *your* machine. ROMs are not included; the game loads them from a `roms`
# directory next to the AppImage (or from --rom-path / SAMSH5PF_ROM_DIR).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROMS="${1:-$ROOT/roms}"
OUT="${2:-$ROOT/Samsh5pf-x86_64.AppImage}"
BUILD="${BUILD_DIR:-$ROOT/build-linux}"
APPDIR="$BUILD/AppDir"

echo "== build (Release) =="
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DSAMSH5PF_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$(nproc)" --target samsh5pf

echo "== assemble AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib"
cp "$BUILD/samsh5pf" "$APPDIR/usr/bin/samsh5pf"

# Bundle the SDL2 the build linked against, so the AppImage runs on systems
# without libsdl2 installed (SteamOS has it, but not every distribution does).
SDL=$(ldd "$BUILD/samsh5pf" | awk '/libSDL2-2\.0\.so/{print $3; exit}')
if [ -n "$SDL" ]; then cp "$SDL" "$APPDIR/usr/lib/"; fi

cp "$ROOT/launcher/samsh5pf.png" "$APPDIR/samsh5pf.png"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# ROMs live next to the .AppImage by default; --rom-path on the command line
# still wins because the runtime takes the last one it sees.
if [ -n "${APPIMAGE:-}" ]; then
    ROMDIR="$(dirname "$APPIMAGE")/roms"
else
    ROMDIR="$PWD/roms"
fi
[ -d "$ROMDIR" ] || ROMDIR="${SAMSH5PF_ROM_DIR:-$ROMDIR}"
exec "$HERE/usr/bin/samsh5pf" --rom-path "$ROMDIR" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/samsh5pf.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Samurai Shodown V Perfect
Comment=Native static recompilation of Samurai Shodown V Perfect (Neo Geo)
Exec=samsh5pf
Icon=samsh5pf
Categories=Game;ArcadeGame;
Terminal=false
EOF

echo "== appimagetool =="
TOOL="${APPIMAGETOOL:-$BUILD/appimagetool.AppImage}"
if [ ! -x "$TOOL" ]; then
    wget -q -O "$TOOL" \
        https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"
echo "wrote $OUT"

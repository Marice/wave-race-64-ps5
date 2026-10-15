#!/usr/bin/env bash
# Assembles the title folder dist/PPSA69424 from the build: eboot, home screen files, the system libc
# module and the frontend's assets (staged by CMake next to the executable).
#   tools/package.sh           title folder, for upload.sh (no ROM: the player's dump goes in by hand)
#   tools/package.sh --release title folder zipped with its sha256
set -euo pipefail
release=false
[[ ${1:-} == --release ]] && release=true
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build="$root/build-ps5/wr64"
radv="$root/radv/mihawk-vulkan-review"
app="$root/dist/PPSA69424"

rm -rf -- "$app"
mkdir -p "$app/sce_sys" "$app/sce_module"
cp "$build/WaveRace64Recomp" "$app/eboot.bin"
cp "$root/sce_sys/param.json" "$app/sce_sys/"
# Home screen icon (512x512) from assets/icon.png; backgrounds from assets/background.png (once, with
# a venv: python3 -m venv .home/venv-art && .home/venv-art/bin/pip install pillow etcpak).
python3 -I - "$root/assets/icon.png" "$app/sce_sys/icon0.png" <<'PY'
import sys
from PIL import Image
Image.open(sys.argv[1]).convert("RGB").resize((512, 512), Image.LANCZOS).save(sys.argv[2], optimize=True)
PY
[[ -f $root/sce_sys/pic0.dds ]] || "$root/.home/venv-art/bin/python" -I "$root/tools/make-backgrounds.py" "$root/assets/background.png" "$root/sce_sys"
cp "$root"/sce_sys/{pic0.dds,pic1.dds} "$app/sce_sys/"
cp "$radv/runtime/libc.prx" "$app/sce_module/libc.prx"
cp -r "$build/assets" "$app/assets"
if $release; then
    version=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["contentVersion"])' "$app/sce_sys/param.json")
    zip="$root/dist/WaveRace64Recompiled-PS5-$version.zip"
    rm -f "$zip"
    (cd "$root/dist" && zip -qr -9 "$zip" PPSA69424)
    (cd "$root/dist" && sha256sum "$(basename "$zip")" > "$(basename "$zip").sha256")
    echo "package.sh: $zip ($(du -h "$zip" | cut -f1))"
else
    echo "package.sh: $app ($(du -sh "$app" | cut -f1))"
fi

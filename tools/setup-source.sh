#!/usr/bin/env bash
# Sets up the sources the PS5 build needs, next to this repository's files:
#   src-upstream/  Wave Race 64: Recompiled at the pinned commit with its submodules, upstream's own
#                  submodule patches (tools/patch_*.py, committed in each submodule as its base) and then
#                  this port's patches/; the reference decompilation at the pinned commit
#   radv/          Mihawk's PS5_Vulkan, PS5_Mesa and PS5_PayloadSDK at the pinned commits
# and, given the Wave Race 64 (USA) (Rev A) ROM, generates the recompiled game code from it.
#   tools/setup-source.sh "Wave Race 64 (USA) (Rev A).z64"
#   tools/setup-source.sh            sources only, no game code
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
rom=${1:-}
[[ -z $rom ]] || rom=$(realpath "$rom")

upstream_url=https://github.com/danielgomesvieira2000/wave-race-64-recomp
upstream_commit=b7c677a4a9a9c73e4be3ab2c7e29f3fbbf14aaab   # main after v1.0.2, 1.0.3 withdrawn
decomp_url=https://github.com/LLONSIT/Wave-Race-64.git
decomp_commit=7784087f69562ede44867900e9d82131dcc23853   # before d9c9043 renamed func_800CB0A8, which recomp/wr64.toml names
src="$root/src-upstream"

if [[ ! -f $src/.port-setup ]]; then
    [[ -d $src/.git ]] || git clone -q "$upstream_url" "$src"
    git -C "$src" checkout -q "$upstream_commit"
    git -C "$src" submodule update --init --recursive --jobs 8
    # Upstream's own submodule changes, committed in each changed submodule (new files included) so
    # tools/make-patches.sh diffs only this port's changes against them.
    "$root/docker/run.sh" "cd src-upstream && for p in rt64 n64recomp rsprecomp librecomp recompinput runtime_shutdown; do
        python3 tools/patch_\$p.py >/dev/null; done"
    git -C "$src" submodule foreach --quiet --recursive \
        'if [ -n "$(git status --porcelain)" ]; then git add -A && git -c user.name=base -c user.email=base@local commit -qm "wave-race-64-recomp tools/patch_*.py"; fi'
    # The decompilation, for the symbols and the ELF the recompiler reads.
    [[ -d $src/reference/wr64-decomp/.git ]] || git clone -q "$decomp_url" "$src/reference/wr64-decomp"
    git -C "$src/reference/wr64-decomp" checkout -q "$decomp_commit"
    git -C "$src/reference/wr64-decomp" submodule update --init --recursive --jobs 8
    # This port's changes: patches/wr64.patch for upstream's own tree, patches/<submodule path>.patch
    # (slashes as "__") for each submodule.
    for patch in "$root"/patches/*.patch; do
        [[ -e $patch ]] || continue
        name=$(basename "$patch" .patch)
        if [[ $name == wr64 ]]; then dir=$src; else dir="$src/${name//__//}"; fi
        git -C "$dir" apply --whitespace=nowarn "$patch"
    done
    touch "$src/.port-setup"
fi

# Mihawk's RADV port at the commits pinned for rush2-ps5 (from ProsperoEden's tools/deps.json).
mkdir -p "$root/radv"
for pin in "PS5_Vulkan mihawk-vulkan-review 5b5e4fc2d80fdb67a4f61ba9e6a8a424026bb8a5" \
           "PS5_Mesa mihawk-mesa-review 7b59ef27c1b09b9671bc4153c41940c3155c3af2" \
           "PS5_PayloadSDK mihawk-sdk-review b83202be73e930050e00de0f1b4d9ec46c0391bf"; do
    read -r repo dir commit <<< "$pin"
    [[ -d $root/radv/$dir ]] || git clone -q "https://github.com/mihawk-99/$repo" "$root/radv/$dir"
    git -C "$root/radv/$dir" checkout -q "$commit"
done
# PS5_Vulkan's scripts look for the Mesa and SDK checkouts under these names.
ln -sfn mihawk-sdk-review "$root/radv/PS5_PayloadSDK"
ln -sfn mihawk-mesa-review "$root/radv/PS5_Mesa"

# The recompiled game code: the recompiler, splat's environment, the decompilation's ELF and the
# generated sources, all by upstream's own scripts, in the build container.
if [[ -n $rom ]]; then
    # A copy inside the mounted tree, with the dump's own extension (generate_game.py reads the byte order
    # from the header).
    copy=".rom.${rom##*.}"
    cp "$rom" "$src/$copy"
    "$root/docker/run.sh" "cd src-upstream && bash tools/wsl_build_recompiler.sh >/dev/null &&
        bash tools/wsl_setup_splat.sh && python3 tools/generate_game.py $copy"
    rm -f "$src/$copy"
fi
echo "setup-source.sh: sources ready; next: ./build.sh radv, ./build.sh configure, ./build.sh"

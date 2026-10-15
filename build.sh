#!/usr/bin/env bash
# Builds Wave Race 64: Recompiled for the PS5 in the build container.
#   ./build.sh radv        RADV, the payload SDK fork and the title converter (once)
#   ./build.sh configure   host tools + CMake configure (build-ps5/wr64)
#   ./build.sh [build]     compile (after configure)
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# The PacBrew sysroot (SDL2, FreeType...): downloaded into .deps/ by tools/setup-pacbrew.sh unless PACBREW is set.
: "${PACBREW:=$("$root/tools/setup-pacbrew.sh")}"
export PACBREW
sdk="$root/radv/mihawk-vulkan-review/.deps/native/ps5-payload-sdk"
env="export PS5_PAYLOAD_SDK=$sdk RADV_ROOT=$root/radv/mihawk-vulkan-review PACBREW=$PACBREW WR64_HOST_TOOLS=$root/build-host/file_to_c;"
case ${1:-build} in
radv)
    WORKDIR="$root/radv/mihawk-vulkan-review" "$root/docker/run.sh" "
        bash tools/setup-native-dependencies.sh && bash tools/build-radv.sh release &&
        n=tooling/native && z=.deps/native/zlib/root/usr && mkdir -p build/host &&
        clang++-18 -std=c++20 -O2 -I \$z/include \$n/native_app_builder.cpp \$n/self_container.cpp \
            \$n/elf_object.cpp \$n/sce_module_writer.cpp \$z/lib/libz.a -o build/host/ps5-native-tool &&
        bash tools/rebuild-libc.sh" ;;
configure)
    "$root/docker/run.sh" "$env
        cmake -S src-upstream/lib/RT64/src/tools/file_to_c -B build-host/file_to_c -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null &&
        cmake --build build-host/file_to_c >/dev/null &&
        cmake -S src-upstream -B build-ps5/wr64 -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCMAKE_TOOLCHAIN_FILE=$root/cmake/ps5-toolchain.cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DWR64_WITH_RUNTIME=ON -DWR64_WITH_RECOMPILED=ON -DWR64_WITH_FRONTEND=ON -DWR64_LINUX_MATH_COMPAT=OFF" ;;
build)
    "$root/docker/run.sh" "$env cmake --build build-ps5/wr64 --target WaveRace64Recomp -- -k 0" ;;
*)
    echo "usage: $0 [configure|build]" >&2; exit 2 ;;
esac

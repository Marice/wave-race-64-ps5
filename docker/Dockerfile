# Build environment for RADV (Mesa), the decompilation's ELF and the PS5 title: Ubuntu 26.04 with LLVM 18 and 21.
FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
COPY packages.txt /tmp/packages.txt
RUN apt-get update && apt-get install -y --no-install-recommends $(cat /tmp/packages.txt) sudo \
    && rm -rf /var/lib/apt/lists/*
# Upstream's decompilation scripts call plain clang and clang++ (pad_data_objects.py: clang -E).
RUN ln -s /usr/bin/clang-21 /usr/local/bin/clang && ln -s /usr/bin/clang++-21 /usr/local/bin/clang++

#!/usr/bin/env bash
# Feature clang-toolchain: clang, compiler-rt (libFuzzer, sanitizer runtimes), LLVM development files and nasm for C and assembly
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends clang libclang-rt-dev llvm-dev nasm
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' clang libclang-rt-dev llvm-dev nasm

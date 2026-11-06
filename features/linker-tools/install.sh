#!/usr/bin/env bash
# Feature linker-tools: GNU binutils (multiarch), lld and llvm tools as reference linkers and for map/ELF comparison
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends binutils binutils-multiarch lld llvm
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' binutils binutils-multiarch lld llvm

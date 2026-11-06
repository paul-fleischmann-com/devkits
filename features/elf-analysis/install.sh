#!/usr/bin/env bash
# Feature elf-analysis: pyelftools (Python ELF/DWARF parser), patchelf, pax-utils (scanelf) and dwarfdump for ELF and debug-info analysis
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends python3-pyelftools patchelf pax-utils dwarfdump
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' python3-pyelftools patchelf pax-utils dwarfdump

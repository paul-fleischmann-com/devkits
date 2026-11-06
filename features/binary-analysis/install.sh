#!/usr/bin/env bash
# Feature binary-analysis: elfutils, file, xxd and gdb-multiarch to inspect linker output (ELF, sections, symbols)
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends elfutils file xxd gdb-multiarch
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' elfutils file xxd gdb-multiarch

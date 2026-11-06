#!/usr/bin/env bash
# Feature debuggers: gdb, lldb, valgrind and strace for debugging, DWARF and core dump analysis
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends gdb lldb valgrind strace
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' gdb lldb valgrind strace

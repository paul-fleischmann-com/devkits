#!/usr/bin/env bash
# Feature fuzzing: AFL++ and the AddressSanitizer/UndefinedBehaviorSanitizer runtimes for fuzzing ELF parsers and linker inputs
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends afl++ libasan8 libubsan1
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' afl++ libasan8 libubsan1

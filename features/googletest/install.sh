#!/usr/bin/env bash
# Feature googletest: GoogleTest and GoogleMock (headers and sources for CMake/CTest)
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends libgtest-dev libgmock-dev googletest
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' libgtest-dev libgmock-dev googletest

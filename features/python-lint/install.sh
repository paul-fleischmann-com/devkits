#!/usr/bin/env bash
set -euo pipefail
# The Debian packages `ruff` and `mypy` (the programs `ruff` and `mypy`, which the check steps call). If the snapshot of the kit lacks one of the names, the build stops
# here and says so; the kit works without them (a check step then reports "nicht verfügbar", it never fails the job).
apt-get update
apt-get install -y --no-install-recommends ruff mypy

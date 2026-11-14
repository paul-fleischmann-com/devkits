#!/usr/bin/env bash
set -euo pipefail
# The Debian package `staticcheck`. If the snapshot of the kit has no package of this name, the build stops here and says so; the kit works without it
# (the check step of the factory then reports "nicht verfügbar", it never fails the job).
apt-get update
apt-get install -y --no-install-recommends staticcheck

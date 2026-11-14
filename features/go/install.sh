#!/usr/bin/env bash
set -euo pipefail
# Go from the Debian snapshot. A go.mod that asks for a newer Go than this one is answered by the test run with a clear message; with the package sources
# (proxy.golang.org, sum.golang.org) Go fetches the newer toolchain itself (GOTOOLCHAIN=auto, set by the factory only then).
apt-get update
apt-get install -y --no-install-recommends golang-go

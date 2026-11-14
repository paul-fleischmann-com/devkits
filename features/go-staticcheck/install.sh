#!/usr/bin/env bash
set -euo pipefail
# The Debian package `go-staticcheck` (the package `staticcheck` does not exist in trixie, #573). Its program is called `/usr/bin/go-staticcheck`, the check step of the factory
# calls `staticcheck`: a link under the expected name. The package is version 2024.1, built with Go 1.24: it may not know the newest language features of a module (UDAL asks
# for Go 1.27); the check step is optional, so a complaint of it is a warning and never fails the job.
apt-get update
apt-get install -y --no-install-recommends go-staticcheck
ln -sf /usr/bin/go-staticcheck /usr/local/bin/staticcheck
test -x /usr/bin/go-staticcheck && command -v staticcheck

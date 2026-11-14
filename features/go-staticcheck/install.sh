#!/usr/bin/env bash
set -euo pipefail
# The Debian package `go-staticcheck` (the program `staticcheck`, which the check step calls; the package `staticcheck` does not exist, build of #573 stopped with
# "Unable to locate package"). It is version 2024.1, built with Go 1.24: it may not know the newest language features of a module (UDAL asks for Go 1.27); the check step is
# optional, so a complaint of it is a warning and never fails the job.
apt-get update
apt-get install -y --no-install-recommends go-staticcheck
command -v staticcheck

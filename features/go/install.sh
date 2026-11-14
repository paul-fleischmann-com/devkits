#!/usr/bin/env bash
set -euo pipefail
# Go from the Debian snapshot. A go.mod that asks for a newer Go than this one is answered by the test run with a clear message; with the package sources
# (proxy.golang.org, sum.golang.org) Go fetches the newer toolchain itself (GOTOOLCHAIN=auto, set by the factory only then).
# ca-certificates (#573): the base image has no CA bundle and `--no-install-recommends` does not pull it in; without it that download fails with
# "x509: certificate signed by unknown authority" (the test proxy only tunnels, the certificate is the one of proxy.golang.org).
apt-get update
apt-get install -y --no-install-recommends ca-certificates golang-go

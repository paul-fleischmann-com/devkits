#!/usr/bin/env bash
set -euo pipefail
# `staticcheck`, the program that the check step `staticcheck` of the factory calls (#651). The Debian package `go-staticcheck` is version 2023.1/2024.1, built with an old Go: for every
# module that asks for a newer Go it only said "module requires at least go1.25.0, but Staticcheck was built with go1.24.4" (a warning, the step is optional). So it is built from source with
# the Go 1.27 of the feature `go` (it must come before this feature in the kit) in ONE fixed version, with `go install pkg@version`, like `buf-tools`: the build needs the network ONCE,
# the module checksums are verified by sum.golang.org, nothing is piped into a shell, and the result is the same until the version below is changed. Change the version here, not in the project.
# STATICCHECK_VERSION=v0.8.2 is the release 2026.2.2 (12 Oct 2026): 2026.2 added support for Go 1.27 (release notes of staticcheck.dev), 2026.2.2 supports the export data format of Go 1.27.2.
# The `go` line of its go.mod is 1.26.0, so the Go 1.27 of the image builds it with GOTOOLCHAIN=local (no toolchain is fetched). An older release (2026.1 = v0.7.0) does not know Go 1.27.
STATICCHECK_VERSION=v0.8.2

export GOBIN=/usr/local/bin GOPATH=/tmp/gopath GOCACHE=/tmp/gocache GOFLAGS=-trimpath GOTOOLCHAIN=local CGO_ENABLED=0
go install "honnef.co/go/tools/cmd/staticcheck@${STATICCHECK_VERSION}"
# the module cache and the build cache are only for the build: not part of the image (the file system of a test container is read-only anyway)
chmod -R u+w /tmp/gopath 2> /dev/null || true
rm -rf /tmp/gopath /tmp/gocache
command -v staticcheck
staticcheck -version

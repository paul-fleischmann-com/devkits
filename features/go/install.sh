#!/usr/bin/env bash
set -euo pipefail
# Go 1.27 from the Debian package `golang-1.27-go` (#573). trixie has only Go 1.24; the snapshot carries 1.27 in the suite trixie-backports. UDAL (go.work) asks for 1.27;
# with an older Go in the image, Go fetches the toolchain from storage.googleapis.com, a host that is never a package source. Still only Debian packages from the dated
# snapshot (same date, same keyring as the base source `snapshot.sources`), nothing is fetched from anywhere else.
# The suite is added for this install only (`-t` takes just what the package needs from it) and removed again: the image keeps trixie as its only suite.
# To use another Go: change the three occurrences of 1.27 (package, folder) and check that the snapshot has the package.
GO_PACKAGE=golang-1.27-go
GO_HOME=/usr/lib/go-1.27

sed 's/^Suites: .*/Suites: trixie-backports/' /etc/apt/sources.list.d/snapshot.sources > /etc/apt/sources.list.d/snapshot-backports.sources
grep -q '^Suites: trixie-backports$' /etc/apt/sources.list.d/snapshot-backports.sources
apt-get update
# ca-certificates: the base image has no CA bundle; Go needs it later for proxy.golang.org (#573).
apt-get install -y --no-install-recommends -t trixie-backports ca-certificates "$GO_PACKAGE"
rm -f /etc/apt/sources.list.d/snapshot-backports.sources
ln -sf "$GO_HOME/bin/go" /usr/local/bin/go
ln -sf "$GO_HOME/bin/gofmt" /usr/local/bin/gofmt
go version | grep -q 'go1\.27'

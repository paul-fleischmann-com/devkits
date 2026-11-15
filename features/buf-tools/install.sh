#!/usr/bin/env bash
set -euo pipefail
# `buf` and the plugins of the generator of a project like UDAL (#606, part of #602): the tools that create generated code from `.proto` files offline, in the container of the stage
# "generate" (no network there). Needs the feature `go` in front of it in the kit.
# Debian trixie has no `buf` and only grpc-gateway v1 (UDAL uses v2), so the tools are built from source in fixed versions with `go install pkg@version`: the build needs the network ONCE,
# the module checksums are verified by sum.golang.org, nothing is piped into a shell, and the result is the same until a version below is changed. Change a version here, not in the project.
# Not in this image: the dependency `buf.build/googleapis/googleapis` of a `buf.yaml` (it is fetched from buf.build, which the container cannot reach). A project that generates
# offline needs a `buf.yaml` without that dependency (the `google/api/*.proto` files in the repository) -- see docs/FACTORY.md, "Erzeugten Code neu erzeugen".
BUF_VERSION=v1.75.0
PROTOC_GEN_GO_VERSION=v1.36.12
PROTOC_GEN_GO_GRPC_VERSION=v1.6.2
GRPC_GATEWAY_VERSION=v2.33.0

export GOBIN=/usr/local/bin GOPATH=/tmp/gopath GOCACHE=/tmp/gocache GOFLAGS=-trimpath GOTOOLCHAIN=local CGO_ENABLED=0
go install "github.com/bufbuild/buf/cmd/buf@${BUF_VERSION}"
go install "google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO_VERSION}"
go install "google.golang.org/grpc/cmd/protoc-gen-go-grpc@${PROTOC_GEN_GO_GRPC_VERSION}"
go install "github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@${GRPC_GATEWAY_VERSION}"
go install "github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@${GRPC_GATEWAY_VERSION}"
# the module cache and the build cache are only for the build: not part of the image (the file system of a test container is read-only anyway)
chmod -R u+w /tmp/gopath 2> /dev/null || true
rm -rf /tmp/gopath /tmp/gocache
for tool in buf protoc-gen-go protoc-gen-go-grpc protoc-gen-grpc-gateway protoc-gen-openapiv2; do
    command -v "$tool"
done
buf --version

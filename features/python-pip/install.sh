#!/usr/bin/env bash
set -euo pipefail
# `venv` and `pip` for Python 3 (#614). The preset `pip install .[dev] und pytest` of the stack python creates a virtual environment in /tmp and installs the dependencies of the
# project into it (network package-sources only); without these two packages `python3 -m venv` fails. Debian packages from the dated snapshot, nothing fetched here.
apt-get update
apt-get install -y --no-install-recommends python3-venv python3-pip

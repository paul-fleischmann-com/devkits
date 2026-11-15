#!/usr/bin/env bash
set -euo pipefail
# `ruff` and `mypy`, the programs that the check steps `ruff` and `mypy` of the factory call (#652). Debian trixie has no package `ruff`, so both come from PyPI in ONE fixed version
# each, into their own virtual environment (/opt/python-lint) with `pip install name==version`, like `buf-tools` and `go-staticcheck`: the build needs the network ONCE, nothing is piped into
# a shell, and the result is the same until a version below is changed. Change the versions here, not in the project. The feature `python-pip` (venv and pip) must come before this one in the kit.
# RUFF_VERSION is the one the repository itself is checked with; MYPY_VERSION the current release at the time of writing.
RUFF_VERSION=0.16.4
MYPY_VERSION=2.4.1

python3 -m venv /opt/python-lint
/opt/python-lint/bin/python -m pip install --no-cache-dir --disable-pip-version-check "ruff==${RUFF_VERSION}" "mypy==${MYPY_VERSION}"
ln -s /opt/python-lint/bin/ruff /usr/local/bin/ruff
ln -s /opt/python-lint/bin/mypy /usr/local/bin/mypy
command -v ruff
ruff --version
mypy --version

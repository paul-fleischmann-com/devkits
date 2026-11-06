#!/usr/bin/env bash
# Feature docs: Doxygen, Sphinx (Markdown via MyST, Mermaid, RTD theme) and graphviz for API documentation
# Runs as root inside the build, once. Packages come from the dated Debian snapshot of the kit (see scripts/compose.py): the same kit gives the same image.
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends doxygen graphviz python3-sphinx python3-myst-parser python3-sphinx-rtd-theme python3-sphinxcontrib-mermaid
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f='${Package} ${Version}\n' doxygen graphviz python3-sphinx python3-myst-parser python3-sphinx-rtd-theme python3-sphinxcontrib-mermaid

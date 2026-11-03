#!/usr/bin/env bash
# Install the Lean toolchain this package pins (through elan) if it is missing, and build the monitor.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/lean"
export PATH="$HOME/.elan/bin:$PATH"
if ! command -v lake >/dev/null 2>&1; then
  echo "== installing elan (the Lean toolchain manager) into ~/.elan"
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain none
fi
echo "== building the monitor with $(cat lean-toolchain) (first build: a few minutes)"
lake build monitor
echo "== done: ./verify --help"

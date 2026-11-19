#!/usr/bin/env bash
# One-time setup: Lean toolchain + Python dependencies.
#
# Idempotent: safe to re-run. Steps that are already satisfied are reported and
# skipped rather than treated as errors.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# ── 1. elan ──────────────────────────────────────────────────────────────
echo "==> Checking for elan (Lean toolchain manager)"
if ! command -v elan >/dev/null 2>&1; then
  echo "    elan not found. Installing..."
  curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --default-toolchain none
  # shellcheck disable=SC1090
  source "${HOME}/.elan/env" 2>/dev/null || export PATH="${HOME}/.elan/bin:${PATH}"
else
  echo "    elan present: $(elan --version)"
fi

# ── 2. toolchain ─────────────────────────────────────────────────────────
# `elan toolchain install` exits non-zero when the toolchain is already
# present, so check first rather than letting `set -e` abort the script.
TOOLCHAIN="$(cat library/lean-toolchain)"
echo "==> Toolchain pinned by library/lean-toolchain: ${TOOLCHAIN}"
if elan toolchain list 2>/dev/null | grep -qF "${TOOLCHAIN}"; then
  echo "    already installed"
else
  echo "    installing..."
  elan toolchain install "${TOOLCHAIN}"
fi

# ── 3. Python dependencies ───────────────────────────────────────────────
# The packages pyproject.toml declares: fire (the command line), the OpenAI SDK (the concept
# review and the aggregate verifier) and jsonschema (the behaviour-property review's answer
# schemas). Install into whatever environment is active (conda, venv, or system). Only fall back
# to creating a local .venv if that is not possible. No API request is sent.
echo "==> Python dependencies"
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' \
  || { echo "    Python 3.11 or newer is required (python3 is $(python3 -c 'import sys; print(sys.version.split()[0])'))" >&2; exit 1; }
PY_PACKAGES=("fire>=0.6.0" "openai>=1.66" "jsonschema>=4.18")
PY_IMPORTS='import fire; from openai import OpenAI, APIError, APITimeoutError, RateLimitError; import jsonschema, referencing'
VENV_CREATED=0
if python3 -c "$PY_IMPORTS" >/dev/null 2>&1; then
  echo "    fire, openai and jsonschema already available in the active environment"
elif python3 -m pip install --quiet "${PY_PACKAGES[@]}" >/dev/null 2>&1 && python3 -c "$PY_IMPORTS" >/dev/null 2>&1; then
  echo "    installed fire, openai and jsonschema into the active environment"
else
  echo "    could not install into the active environment; creating .venv"
  python3 -m venv .venv
  ./.venv/bin/pip install --quiet --upgrade pip
  ./.venv/bin/pip install --quiet "${PY_PACKAGES[@]}"
  ./.venv/bin/python -c "$PY_IMPORTS" || { echo "    the packages did not import in .venv" >&2; exit 1; }
  VENV_CREATED=1
fi

# ── 3b. the doctor's corpus and split tools ─────────────────────────────
# A run's checkout is the whole WorldModelSpec repository: pipeline/ontology_provenance/ (nrs_tools)
# lies beside this directory, where the doctor and the launcher find it.
echo "==> The doctor's split tools (nrs_tools)"
TOOLS="$(cd "$REPO_ROOT/.." && pwd)/ontology_provenance"
if [ -f "$TOOLS/nrs_tools/atoms_train.py" ]; then
  echo "    found beside this directory: $TOOLS"
elif python3 -c "import nrs_tools.atoms_train" >/dev/null 2>&1; then
  echo "    found on PYTHONPATH"
else
  echo "    MISSING: $TOOLS/nrs_tools is not there and PYTHONPATH has no nrs_tools." >&2
  echo "      Clone the whole WorldModelSpec repository (the run branch carries pipeline/ontology_provenance/)," >&2
  echo "      or put the directory holding nrs_tools/ on PYTHONPATH. The doctor refuses every run without it." >&2
  exit 1
fi

# ── 4. Claude Code ───────────────────────────────────────────────────────
echo "==> Checking for Claude Code"
if command -v claude >/dev/null 2>&1; then
  echo "    claude present: $(claude --version 2>/dev/null || echo installed)"
else
  echo "    claude NOT found — needed only to run the loop, not to build."
  echo "      https://claude.com/claude-code"
fi

# ── 5. build the library ─────────────────────────────────────────────────
# Deliberately last: it is the slowest step and the one most likely to fail,
# and everything above is useful even when it does.
echo "==> Building the Lean library (compiles Core; no mathlib needed)"
if ( cd library && lake build ); then
  echo "    build ok"
else
  cat <<'EOF'

    BUILD FAILED.

    Fix the errors above, then re-run just the build:

      cd library && lake build

    TrafficSpec/Tests/ contains `#guard` assertions; a failed assertion
    reports a library regression after the toolchain starts successfully.
EOF
  exit 1
fi

echo ""
echo "Setup complete. Next:"
if [ "${VENV_CREATED}" -eq 1 ]; then
  echo "  source .venv/bin/activate"
fi
cat <<'EOF'
  python3 -m harness init
EOF

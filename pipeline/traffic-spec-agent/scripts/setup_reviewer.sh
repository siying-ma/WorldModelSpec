#!/usr/bin/env bash
# One-time setup of the second-vendor reviewer: the OpenAI SDK, the API key, one test call.
#
# The key is kept outside the repository, in ~/.config/traffic-spec/openai.env (mode 600), so no
# agent session can read it (sessions are jailed to their own directories) and git never sees it.
# The harness reads OPENAI_API_KEY from its own environment and launches every Claude session
# without it. Idempotent: re-run to replace the key or re-test it.
set -euo pipefail

ENV_FILE="${HOME}/.config/traffic-spec/openai.env"
MODEL="${1:-gpt-5}"

echo "==> Python package 'openai'"
if python3 -c "import openai" >/dev/null 2>&1; then
  echo "    present: $(python3 -c 'import openai; print(openai.__version__)')"
else
  python3 -m pip install --quiet openai && echo "    installed"
fi

echo "==> API key (${ENV_FILE})"
if [ -f "${ENV_FILE}" ] && [ "${REPLACE_KEY:-0}" != "1" ]; then
  if ! grep -q '^export OPENAI_API_KEY=' "${ENV_FILE}"; then
    # a file holding the bare key (written by hand): rewrite it as the export line `source` needs
    KEY="$(tr -d '[:space:]' < "${ENV_FILE}")"
    [ -n "${KEY}" ] || { echo "    ${ENV_FILE} is empty; REPLACE_KEY=1 $0 to enter the key"; exit 1; }
    ( umask 077; printf 'export OPENAI_API_KEY=%q\n' "${KEY}" > "${ENV_FILE}" )
    echo "    rewrote the bare key as an export line"
  fi
  chmod 600 "${ENV_FILE}"
  echo "    already stored (REPLACE_KEY=1 $0 to replace it)"
else
  read -r -s -p "    OpenAI API key: " KEY; echo
  [ -n "${KEY}" ] || { echo "    no key given"; exit 1; }
  mkdir -p "$(dirname "${ENV_FILE}")"
  umask 077
  printf 'export OPENAI_API_KEY=%q\n' "${KEY}" > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  echo "    stored"
fi

echo "==> Test call to ${MODEL}"
# shellcheck disable=SC1090
source "${ENV_FILE}"
python3 - "${MODEL}" <<'EOF'
import sys
from openai import OpenAI
model = sys.argv[1].split(":", 1)[-1]
r = OpenAI(timeout=120).responses.create(model=model, input='Answer with the JSON {"ok": true} and nothing else.', store=False)
print("    answered:", (r.output_text or "").strip()[:80])
EOF

cat <<EOF

Reviewer ready. Before each launch, in the shell that runs the loop:
  source ${ENV_FILE}
Then add to the loop command:  --reviewer_model ${MODEL}
EOF

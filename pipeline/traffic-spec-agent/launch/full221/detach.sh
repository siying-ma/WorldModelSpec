# Sourced by the full221 scripts. start_detached ACTION PREFIX starts scripts/run-generation.sh ACTION in its own
# session (setsid nohup: closing the terminal or the ssh connection does not stop it) with the caller's exported
# settings, then returns. It records the launcher's pid in PREFIX.pid and, when the launcher ends, its exit
# status in PREFIX.exit: the script's own status says only that it started. It also starts
# launch/full221/watch.sh, which reports on the run until the launcher ends.
# The account: the claude CLI bills its logged-in account (CLAUDE_CONFIG_DIR's when set, the default login
# otherwise; the same for every launch of the run); ANTHROPIC_API_KEY is cleared so that no launch can bill a key.
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_VERTEX_BASE_URL ANTHROPIC_BEDROCK_BASE_URL
unset CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
export PYTHONDONTWRITEBYTECODE=1        # a doctor import must not rewrite a tracked cache and dirty the checkout
[ -d harness ] && [ -x scripts/run-generation.sh ] || { echo "refusing: run from pipeline/traffic-spec-agent"; exit 2; }

start_detached() {
  local action=$1 prefix=$2
  [ ! -e "$prefix.pid" ] || { echo "refusing: $prefix.pid exists (a launch with this name was started before)"; return 2; }
  echo "claude account: CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-the default login}"
  setsid nohup bash -c 'scripts/run-generation.sh "$1"; echo $? > "$2.exit"' _ "$action" "$prefix" > "$prefix.out" 2>&1 < /dev/null &
  local pid=$!
  echo "$pid" > "$prefix.pid"
  setsid nohup bash launch/full221/watch.sh "$RUN_ID" "$pid" "$prefix" > /dev/null 2>&1 < /dev/null &
  echo "started $action of $RUN_ID (pid $pid)"
  echo "  output: $prefix.out; progress: .runtime/$RUN_ID/launcher.log"
  echo "  the launcher's exit status, once it ends: $prefix.exit; a report every 10 minutes: .runtime/$RUN_ID/watch.log"
}

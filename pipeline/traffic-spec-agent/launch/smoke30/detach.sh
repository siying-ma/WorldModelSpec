# Sourced by the smoke30 scripts. start_detached ACTION PREFIX starts scripts/run-generation.sh ACTION in the
# background with the caller's exported settings, then returns. It records the launcher's pid in PREFIX.pid and,
# when the launcher ends, its exit status in PREFIX.exit: the script's own status says only that it started.
# It also starts launch/smoke30/watch.sh, which reports on the run until the launcher ends.
# The account: the claude CLI bills the login of CLAUDE_CONFIG_DIR (the default login when unset);
# ANTHROPIC_API_KEY is cleared so that no launch, new or resumed, can bill a key.
unset ANTHROPIC_API_KEY
export PYTHONDONTWRITEBYTECODE=1        # a doctor import must not rewrite a tracked cache and dirty the checkout

start_detached() {
  local action=$1 prefix=$2
  [ ! -e "$prefix.pid" ] || { echo "refusing: $prefix.pid exists (a launch with this name was started before)"; return 2; }
  echo "claude account: ${CLAUDE_CONFIG_DIR:-the default login}"
  nohup bash -c 'scripts/run-generation.sh "$1"; echo $? > "$2.exit"' _ "$action" "$prefix" > "$prefix.out" 2>&1 < /dev/null &
  local pid=$!
  echo "$pid" > "$prefix.pid"
  nohup bash launch/smoke30/watch.sh "$RUN_ID" "$pid" "$prefix" > /dev/null 2>&1 < /dev/null &
  echo "started $action of $RUN_ID (pid $pid)"
  echo "  output: $prefix.out; progress: .runtime/$RUN_ID/launcher.log"
  echo "  the launcher's exit status, once it ends: $prefix.exit; a report every 10 minutes: .runtime/$RUN_ID/watch.log"
}

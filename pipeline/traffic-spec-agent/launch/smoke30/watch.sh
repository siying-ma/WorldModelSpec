#!/usr/bin/env bash
# Observe one launch of a smoke30 run, read-only: every 10 minutes it appends one line to
# .runtime/<run id>/watch.log with the run's iteration, status and stop, the laws by state, and the spend
# against the run's budgets (the harness's own fold of usage.jsonl: each request's first settled row, an
# unsettled request's reservation once), with ALERT when Claude or the total passes 80% of its limit.
# It ends at the first report after the launcher ends, logging its exit status, or ALERT when the launcher
# is gone with no exit status written. It never signals, edits or stops anything; its log ends in .log,
# which the coding gate's tree digest leaves out. Started by launch/smoke30/detach.sh with every launch.
#   bash launch/smoke30/watch.sh <run id> <launcher pid> <launch file prefix>
RUN_ID=${1:?run id}; LPID=${2:?launcher pid}; PREFIX=${3:?launch file prefix}
R=results/$RUN_ID; LOG=.runtime/$RUN_ID/watch.log
mkdir -p ".runtime/$RUN_ID"
report() {
  python - "$R" <<'PY' >> "$LOG" 2>&1
import json, sys, time
from pathlib import Path
from harness.store.budget import fold
r = Path(sys.argv[1])
def load(name):
    try:
        return json.loads((r / name).read_text())
    except Exception:
        return {}
s, o = load("summary.json"), load("options.json")
rows = []
if (r / "usage.jsonl").exists():
    for line in (r / "usage.jsonl").read_text().splitlines():
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
spent = fold(rows)[0]
claude, openai = spent.get("anthropic", 0.0), spent.get("openai", 0.0)
limits = {"claude": o.get("claude_budget_usd"), "total": o.get("total_budget_usd")}
used = {"claude": claude, "total": claude + openai}
alerts = [f"ALERT {k} spend {used[k]:.2f} of {v}" for k, v in limits.items() if v and used[k] >= 0.8 * float(v)]
print(time.strftime("%Y-%m-%d %H:%M"), f"iteration {s.get('iteration')} status {s.get('status')} stop {s.get('stop') or '-'}",
      f"laws {s.get('laws')}", f"claude ${claude:.2f}/{limits['claude']} openai ${openai:.2f}/{o.get('openai_budget_usd')}",
      *alerts, flush=True)
PY
}
while kill -0 "$LPID" 2>/dev/null; do
  report
  sleep 600
done
report
if [ -f "$PREFIX.exit" ]; then
  echo "$(date '+%Y-%m-%d %H:%M') launcher $LPID ended with exit status $(cat "$PREFIX.exit")" >> "$LOG"
else
  echo "$(date '+%Y-%m-%d %H:%M') ALERT launcher $LPID is gone and wrote no exit status: it was killed" >> "$LOG"
fi

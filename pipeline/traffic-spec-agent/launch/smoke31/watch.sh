#!/usr/bin/env bash
# Observe one launch of a smoke31 run, read-only: every 10 minutes it appends one line to
# .runtime/<run id>/watch.log with the run's live state (state.json: the iteration, its stage, the laws by
# ledger state), the last iteration's end (summary.json: status and stop), and the spend against the run's
# budgets from usage.jsonl by the harness's own fold, settled apart from reserved: a settled request counts
# its cost, a request in flight or of unknown cost its reservation. The budget the harness enforces counts
# both, so ALERT is written when Claude's or the total's settled plus reserved spend passes 80% of its limit.
# It ends at the first report after the launcher ends, logging its exit status, or ALERT when the launcher
# is gone with no exit status written. It never signals, edits or stops anything; its log ends in .log,
# which the coding gate's tree digest leaves out. Started by launch/smoke31/detach.sh with every launch.
#   bash launch/smoke31/watch.sh <run id> <launcher pid> <launch file prefix>
RUN_ID=${1:?run id}; LPID=${2:?launcher pid}; PREFIX=${3:?launch file prefix}
R=results/$RUN_ID; LOG=.runtime/$RUN_ID/watch.log
mkdir -p ".runtime/$RUN_ID"
report() {
  python - "$R" <<'PY' >> "$LOG" 2>&1
import json, sys, time
from collections import Counter
from pathlib import Path
from harness.store.budget import fold
r = Path(sys.argv[1])
def load(name):
    try:
        return json.loads((r / name).read_text())
    except Exception:
        return {}
st, s, o = load("state.json"), load("summary.json"), load("options.json")
laws = dict(sorted(Counter(e.get("state") for e in st.get("ledger", []) if isinstance(e, dict)).items()))
rows = []
if (r / "usage.jsonl").exists():
    for line in (r / "usage.jsonl").read_text().splitlines():
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
spent, unresolved, _settled, vendor_of = fold(rows)
reserved = Counter()
for q, v in unresolved.items():
    reserved[vendor_of[q]] += v
settled = {v: spent.get(v, 0.0) - reserved[v] for v in ("anthropic", "openai")}
committed = {"claude": spent.get("anthropic", 0.0), "total": spent.get("anthropic", 0.0) + spent.get("openai", 0.0)}
limits = {"claude": o.get("claude_budget_usd"), "total": o.get("total_budget_usd")}
alerts = [f"ALERT {k} settled+reserved {committed[k]:.2f} of {v}" for k, v in limits.items() if v and committed[k] >= 0.8 * float(v)]
print(time.strftime("%Y-%m-%d %H:%M"), f"iteration {st.get('iteration')} stage {(st.get('prog') or {}).get('stage')}",
      f"laws {laws}", f"last end: status {s.get('status')} stop {s.get('stop') or '-'}",
      f"claude settled ${settled['anthropic']:.2f} reserved ${reserved['anthropic']:.2f} of {limits['claude']}",
      f"openai settled ${settled['openai']:.2f} reserved ${reserved['openai']:.2f} of {o.get('openai_budget_usd')}",
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

# NRS_484B_153_3 — task result

## Final verdict
**OK** (4 witnesses, 3 names, composes nothing). The gate ran once.

## Gate runs
1. `OK`: first run. Nothing changed after it.

Before that, I accidentally made one shell call that was not the gate command: the gate command with `--help` appended. It was denied and never ran, so it used none of the gate budget.

## The rule
- Class of `subject`: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")` (e1).
- Applicability: `sig_door_open(subject, traffic)`, meaning the door on the traffic side is open now (e2, the record's applicability).
- Obligation: `¬ holdsFor .time p.traffic_side_door_max_open subject (sig_door_open(subject, traffic))` (e3, the operationalization).

## Choices the node left open
None beyond the record. The record already states the observable readings (the person is read through the vehicle's door; the purpose is read as a time limit), so I did not repeat them. I declared no narrowing of my own.

## Witnesses
All scenes are sampled at 1 s, with a car stopped at the curb of an east-bound roadway.
- `forbid`: the traffic-side door is open for 0–300 s, judged over 61–300 s → violated.
- `permit`: the traffic-side door is open only for 80–94 s (15 s), judged over 61–150 s → compliant.
- `idle`: only the curb-side door is open → not applicable.
- `blind`: `sig.door_open` is masked → unknown.

## Why I finished
The gate returned OK on the first run.

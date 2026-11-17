# NRS_484B_557_o1 — task result

## Final verdict: OK

## Gate runs
1. `OK` — 6 witnesses, 10 names, composes nothing; 1 coder narrowing declared. Nothing changed after it.

(One stray command, the gate command with an added `--help` piped to `head`, was attempted
before the first run and denied by the sandbox; it ran nothing and does not count as a gate run.)

## How the rule is written
- **Class (s4):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s1–s3):** this is the entry event, under ∃ railway crossing `x`, highway `h`, travel region `r` and stop sign `d`:
  - `rises (rel_occupies subject x)`;
  - `since (rel_occupies subject x) (¬rel_occupies subject x ∧ rel_occupies subject r ∧ dev_governs d r)`. Together with the rise, this pins the governed-region occupancy to the observation just before the entry.
  - `st_on_way r h ∧ st_on_way x h`.
- **Obligation (s5):** ∀ `x h r d` with the same `entry` formula (the whole selection is bound again, per rule 3c), the formula `since searchStep haltInZone` must hold:
  - `haltInZone` means not on `x`, distance to `x` ≤ 50 ft and ≥ 15 ft, and `drv_motion_complete_halt(subject, p.halt_speed_tolerance)`.
  - `searchStep` is the entry observation itself, or a stopping-zone observation (not on `x`, distance ≤ 50 ft) that is not the previous exit (`¬rises(¬occupies x)`).
  - The search ends at the approach start (distance > 50 ft) or at the previous exit.
  - If the search reaches the start of the trace while still inside the zone, Core's `since` truncation makes it unknown.

## Choice the node left open
- **s5 (narrowing, kind `reading`):** I read the previous-exit end of the search as including the exit observation itself. A halt there in the zone counts, but the search does not go past it.

## Witnesses
The geometry is described in the witness file header.

| Witness | Trace | Verdict |
|---|---|---|
| `forbid` | Car enters from 26 m out without halting | violated |
| `permit` | Car halts 10 m out, then enters | compliant |
| `idle` | Stop sign governs only the opposite lane | not applicable |
| `blind` | `st.region_geometry` masked; the car halts | unknown |
| `history_boundary` | Car is already 12 m out at the start of the trace and never halts | unknown, from the truncated `since` |
| `branch_1` | Car halts only 3 m out | violated |

## Why I finished
The gate returned `OK` on the first run.

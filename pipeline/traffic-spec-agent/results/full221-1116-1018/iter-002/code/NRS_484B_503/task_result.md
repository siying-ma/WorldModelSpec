# NRS_484B_503 — task result

## Final verdict
**OK** (13 witnesses, 24 names, composes nothing, 2 coder narrowings).

## Gate runs
1. An accidental invocation, `python -m harness gate … | head -0; echo skip`, broke the
   "exactly one command" rule. It ran before any edit, on the harness skeletons, and its output was
   discarded. If the harness counted it, it used one run of the budget. Nothing changed after it.
2. `python -m harness gate --run_id full221-1116-1018 --node_id NRS_484B_503` returned **OK**.
   This was the first run on the written rule and witnesses.

## How the node is written
- **Class:** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability:** this is s5 ∧ s6.
  - s5: some `curb_zone` z that the subject occupies, with `st_curb_zone_kind` = passenger_loading.
  - s6: every `zone_sign` of kind parking_restricted that governs a `travel_region` the subject
    occupies has `prim_conditions_hold(sign, subject)`. When no such sign exists the clause is
    vacuously true, so the zone counts as effective at all hours.
- **Obligation:** for every curb_zone selected again with the applicability's full selection (z
  occupied, passenger_loading, regulations effective), one of these holds:
  - `¬complete_halt`, or
  - (a) **queue:** another user (`¬same`) is `rel_ahead_behind_in_lane(o, subject)` and
    `rel_surface_gap(subject, o)` (the distance read) ≤ p.queue_halt_gap, or
  - (b) **device or officer:** an occupied travel region is governed by:
    - a stop sign or a yield sign;
    - a signal showing red or yellow (circular or an arrow) or flashing_red;
    - a railway device with lights flashing or the gate lowering, down or raising;
    - a police officer indicating stop.
  - (c) **loading:** `¬parked(tol, p.standing_min_duration)` ∧ (`halted since (halted ∧ door open)`
    ∨ `halted until (halted ∧ door open)`).
- **s2:** a residue, as the node says.

## Choices the node left open (declared as narrowings on s1)
- **"Gate not up"** is read as a gate that is lowering, down or raising. A crossing with no gate
  (gate state `none`) excuses a halt only through flashing lights.
- **"Red or yellow indication"** is read as circular_red, circular_yellow, and red_arrow(d) or
  yellow_arrow(d) for every direction, plus flashing_red. Flashing yellow and flashing yellow arrows
  are left out because they permit proceeding.

## Witnesses beyond the plan
I added these so that every exception limb and every s6 leaf, both in the applicability and in the
repeated selection inside the obligation, moves a decided witness:
- **branch_3 to branch_7 (compliant):** a long halt excused, in turn, by a stop sign, a yield sign,
  a red signal, a railway device (flashing with the gate up, then dark with the gate down), and a
  police officer indicating stop.
- **branch_8 (violated):** a parking_restricted sign is in hours.
- **branch_9 (violated):** out of hours, but the sign on the lane is a school sign, and the
  parking_restricted sign governs only the neighbouring lane.

## Why I finished
The gate returned OK.

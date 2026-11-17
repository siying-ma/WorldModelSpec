# NRS_484B_263_o2 — task result

## Final verdict: OK

## Gate runs
1. `OK` — 5 witnesses, 9 names, composes nothing. Nothing was changed after this run.

Note: before the first gate run I sent one command that was not the gate command (a `--help` probe). It was denied and did not run. No gate budget was used by it.

## How the rule is written
- **Subject (a1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (a2):** the subject is moving (`kin_speed > p.halt_speed_tolerance`), and there is some
  `controlled_access` region c where the latest entry or exit happened at least one observation ago and no more than `p.merge_window` before:
  `0 < sinceRise(rises(occ subject c) ∨ rises(¬occ subject c)) ≤ p.merge_window`.
  - An entry is when the subject's overlap with c starts.
  - An exit is when non-overlap starts right after overlap.
  - `kin.time` is read through `sinceRise`.
- **Obligation (a4–a7):** for every `controlled_access` c, I wrote the same selection again (rule 3c). For every road user v in such a c that meets all of these:
  - v is not the subject;
  - v is in both the traffic and the vehicle aggregates;
  - v is moving;
  - v occupies c;
  - `rel_bearing v subject "ahead"` holds.

  The duty is: `¬rel_contact subject v` and
  `¬(prim_closest_approach_within subject v p.conflict_horizon ∧ prim_closest_approach_distance … < p.conflict_centre_clearance)`.

## Choices the node left open
- **Writing "the latest entry or exit":** I wrote it as the time since the latest rise of the disjunction "overlap rises, or non-overlap rises". This is the record's own wording, so I added no narrowing.
- **Witnesses and `window`:** every witness sets `window` to the instants after the recorded entry. Before the first recorded rise, the time since entry or exit is honestly unknown, because an entry or exit could have happened before the recording started.

## Why I finished
The gate returned `OK` on the first run.

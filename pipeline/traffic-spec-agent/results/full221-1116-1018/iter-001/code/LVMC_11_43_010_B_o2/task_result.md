# LVMC_11_43_010_B_o2 — task result

## Final verdict
SCOPE_VIOLATION (infrastructure). The gate never judged the two node files.

## Gate runs
1. **SCOPE_VIOLATION.** Every path it listed is a runtime temp file under `.runtime/tmp/claude-154266/…`
   (`tasks/*.output` of this and other parallel coding sessions, plus `cache-break-state-*.json`).
   None of them is one of my two files, and I wrote none of them myself: the tool runtime writes
   them for each shell command, the gate command included. No files were changed after this run.
2. **SCOPE_VIOLATION.** Same list again, this time with a fresh `tasks/*.output` for this
   session's second gate call. This confirms that every gate invocation creates a file the gate
   then flags. I stopped here and kept the remaining 4 runs, since no edit on my side can change
   this verdict.

Process note: before the first gate run I also ran one `grep` over
`Core/Vocab/Primitives.lean` to read `closestApproach`. That broke the one-command shell rule;
every later Core read used the Read tool. Its runtime output may be one of the flagged temp files.

**For the harness:** the scope check should ignore `.runtime/tmp/`, or the runtime temp directory
should sit outside the tree the check diffs. Until then every session that runs a shell command
gets SCOPE_VIOLATION. The harness's own re-run after the session may behave differently.

## How the rule is written
- Class (b2, b4): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (b3, b5, b12): `existsRegion "roundabout" r (rises (rel_occupies subject r))`.
  st.roundabout is the quantifier's kind, and entering means occupancy rising.
- Obligation (b9, b10, b11): `forallRegion "roundabout" r (rises (rel_occupies subject r) →
  forallUser u ((¬ same u subject ∧ ru_aggregate u "DEF-NRS-484A-285::traffic" ∧ rel_occupies u r)
  → ¬ (prim_closest_approach_within(subject,u; p.roundabout_critical_gap) ∧
  prim_closest_approach_distance(subject,u; p.roundabout_critical_gap) < p.conflict_centre_clearance)))`.
  The obligation selects r again in full, as rule 3c requires.
- Narrowings: none of my own. The record's b4 and b9 narrowings are not restated.

## Choices left open / node discrepancy
- **rel.contact.** The record's `obligation` prose says "the subject is not in contact with u
  (rel.contact)", but no element or operationalization claims `rel.contact`. Writing it would be
  UNCLAIMED_ATOM, so the rule leaves it out. **The plan agent should either claim rel.contact
  (on b10 or b11) or drop it from the obligation prose.**

## Witnesses (geometry in the witness header)
- forbid: the car enters at 3 m/s. A pedestrian on a crosswalk inside the roundabout comes
  closest in 2.2 s at about 1.9 m, which is under 3 m and under 4.5 s. Expected: violated.
- permit: the car waits, then enters at 4 m/s. A circulating car moving away comes closest at
  about 10 m, so `within` holds but the distance does not. Expected: compliant.
- idle: a street with no roundabout. Expected: not applicable.
- blind: the permit scene with rel.occupies masked. Expected: unknown.
- branch_1: the car enters an empty roundabout. Expected: compliant.

None of these were checked by the gate.

## Why I finished
The gate fails on files outside my scope that the runtime creates every time the gate runs.
Spending more of the budget could not change the verdict, so I left the files as they are for
the harness's own re-run.

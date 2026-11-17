# LVMC_11_30_060_B — coding session result

## Final verdict
`SCOPE_VIOLATION` on both gate runs. The gate never looked at the rule or the witnesses. **This is an
infrastructure problem, not a problem with the node's files.**

## Gate runs
1. `SCOPE_VIOLATION`: the gate listed these as "changed outside the node's files":
   - `.runtime/tmp/claude-154266/.../tasks/*.output`: the agent runtime writes one of these task-output files for each running tool command. One belongs to *this* session (the gate command's own output file). The others belong to concurrent sessions for LVMC_11_18_020, LVMC_11_30_050 and LVMC_11_43_010_B_o1.
   - `.runtime/tmp/claude-154266/cache-break-state-<session>.json`
   I did not write any of these, and none of them is under `library/`. I left the files as they were and ran the gate once more to check whether the problem was transient.
2. `SCOPE_VIOLATION`, same list. The only difference is a new task-output file name for this session's second gate command. The problem is deterministic: every gate run from this sandbox creates such a file itself, so the gate cannot pass here.

**Operator action:** exclude `.runtime/` (the agent runtime's tmp directory) from the gate's scope check, or move the runtime tmp directory outside the repository. Then re-run the gate on the files as they now stand. The harness does this automatically after the session ends.

## What was written
The rule (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_30_060_B.lean`):
- **Class (g1):** `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- **Applicability:** both of these hold.
  - Some `roadway` r satisfies `roadwayCrossed r`:
    - the subject `rel_occupies` r;
    - and either some `lane` k that the subject occupies has `drv_motion_moving_across_carrier(subject, k; p.halt_speed_tolerance, p.crossing_motion_cos)`, or the same concept holds for r itself;
    - and no `regulatory_sign` d with `dev_regulatory_sign_code = pedestrians_prohibited` has `dev_governs(d, r)` (g8).
  - Some `pedestrian_grade_separation` g has `st_region_geometry_distance(subject, g) ≤ p.grade_separation_reach` (g3).
- **Obligation (g4, g5, g6):** for every user v that is a `DEF-NRS-484A-320::vehicle` and occupies some roadway r chosen by the same whole selection `roadwayCrossed r` (re-bound, per rule 3c):
  - not `rel_contact(subject, v)`;
  - and not all three of: `kin_speed(subject) > p.halt_speed_tolerance`, `prim_closest_approach_within(subject, v; p.conflict_horizon)`, and `prim_closest_approach_distance(subject, v; p.conflict_horizon) < p.conflict_centre_clearance`.
- `narrowings := []`. I made no readings beyond the record's own narrowings.

Witnesses: the four planned ones, plus four branch witnesses that exercise individual leaves:
- **forbid** (violated)
- **permit** (compliant)
- **idle** (not_applicable): the overpass is 300 m away.
- **blind** (unknown): `st.region_geometry` is masked.
- **branch_1** (not_applicable): a pedestrians_prohibited sign governs the roadway.
- **branch_2** (compliant): the car is 80 m away, so there is no approach within the horizon. This exercises `rel_contact` and the conflict leaves.
- **branch_3** (violated): the roadway carries the direction and no lanes are mapped. This exercises the "r itself" disjunct of the crossing condition.
- **branch_4** (compliant): the pedestrian straddles a signed roadway and an unsigned one, and the car is only on the signed roadway. This exercises the g8 exclusion inside the obligation's re-bound selection.

The geometry margins are in the witness header. The conflict case is a closest approach of about 0.99 m at about 1.99 s, against a 3 m clearance and a 3 s horizon. The overpass is 9.75 m from the pedestrian's body, against a 30 m reach.

## Choices the node left open
- The lane k in g2 is any lane the subject occupies. It is not tied to r, because the record states it that way: "moves across a carrier k it occupies (st.lane or the roadway)".
- In the obligation, r is re-bound using the whole selection: occupancy, the crossing condition, and the g8 sign exclusion. The g3 overpass condition does not involve r, so it is not repeated there.

## Why I finished
Both gate runs returned `SCOPE_VIOLATION`, triggered by files the agent runtime writes. One of them is the output file of the gate command itself. No edit to my two files can change this, so spending more of the budget would not produce a verdict. The rule and the witnesses are complete as written, but **no gate has checked them**: I have not confirmed that they build or that the witnesses give the expected verdicts.

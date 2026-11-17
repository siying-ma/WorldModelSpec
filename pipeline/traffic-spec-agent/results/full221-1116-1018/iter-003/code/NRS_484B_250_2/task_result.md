# NRS_484B_250_2 — task result

## Final verdict

`WITNESS_FAIL` — `blind: expected unknown, got violated; the manifest masks rel.bearing`.

**The node is wrong:** the planned `blind` scenario can't be built. Details are below.

## Gate runs (3 of 6 used)

1. **Baseline** (the harness skeleton, before any edit): `UNUSED_CLAIM` (dev_governs, dev_stop_sign, dev_traffic_signal, dev_yield_sign, …), which is expected from the placeholders.
   - My mistake: I appended an `ls` of the Core directory to this command. Later I also ran one `grep` and one `wc` outside the gate. All three only read Core files. They changed nothing.
2. **After writing the rule and nine witnesses** (the seven planned plus `branch_4` and `branch_5`): `WITNESS_FAIL`. Only `blind` failed. It came out `violated` instead of `unknown`, and every other witness reached its planned verdict.
3. **Diagnostic run**, with `blind` temporarily set to expect `violated`, to see whether the later checks (adequacy and the rest) pass: `WITNESS_FAIL: the witness declares violated, the plan requires unknown`.
   - The gate checks the planned verdict first, so nothing can get past `blind`.
   - I restored the planned expectation (`unknown`, masking `rel.bearing`) afterwards.

## Why the node is wrong (scenario `blind`, span e/h, masked atom `rel.bearing`)

The plan's `blind` witness masks only `rel.bearing` and expects `unknown` "because which vehicle is on the right is unknown". Under Core that can't happen:

- `rel_bearing` (`Core/Vocab/Atoms.lean`, `rel_bearing` / `relFrame`) uses a measured bearing when the source supplies one. Otherwise it computes the bearing from `kin.position` of both road users and `kin.heading` of the subject.
- Masking `rel.bearing` (`Core/Runtime/Manifest.lean`, `Mask.relation`) only drops a measured value. The Mask docstring says: "The computed relations are blanked through the kinematics they would be computed from only when the source lacks those too."
- With positions and headings observed, the bearing is still computed and decided. So the masked trace gives the same verdict as `forbid`: `violated`.
- Removing the kinematics from the trace instead doesn't work either:
  - Without the subject's heading there is no footprint.
  - A track whose occupancy is observed must have a footprint (TraceLint), and dropping the subject from `occupancyObserved` makes `rel.occupies` unknown.
  - Without v's position, v's distance to X is unknown.
  - Either way the witness becomes unknown for unmasked atoms (`rel_occupies`, `st_region_geometry_distance`), which the gate rejects as stray reasons.

**What the plan must change:** mask an atom that Core reads straight from a field and never recomputes. `kin.speed` works: the subject proceeding above `p.halt_speed_tolerance` becomes unknown, so the duty is unknown, and nothing else changes. I checked this against this rule and the `blind` trace in the witness file:

- The duty `¬(speed > halt ∧ approach ∧ distance < clearance)` becomes unknown, with `absentAtom kin_speed` as the only reason.
- The other bindings stay decided, including the intersection itself acting as a candidate carrier.

`st.on_way` would **not** work on this geometry. With it masked, the pairing where the intersection stands in as c1 also goes unknown, through `st_lane_enters` on the intersection, which is a stray reason.

More generally, no computed `rel.*` relation (`rel.bearing`, `rel.contact`, `rel.centre_distance`, …) should be a `blind` mask when the trace carries full kinematics.

## How the rule is written

Rule file: `library/TrafficSpec/Rules/NRS_484B/NRS_484B_250_2.lean`. Its header records the reading span by span.

- **Class:** `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **Arrival (b):** `st_lane_enters(c, X) ∧ since (occ(x, c) ∨ occ(x, X)) (rises (occ(x, c) ∧ st_region_geometry_distance(x, X) ≤ p.stop_point_tolerance))`. X ranges over intersections and c over travel regions.
- **Applicability:** some intersection X where the subject has arrived on some c1, and X is not controlled; and `¬ruleApplies` for `NRS_484B_250_4_o1` and `NRS_484B_250_4_o2` (subject ↦ subject).
- **Control (j):** one device quantifier for each of traffic_signal, stop_sign and yield_sign. The device governs X, or governs a travel region c with `st_lane_enters(c, X)`.
- **Obligation:** X and c1 are selected again exactly as in the applicability, including "not controlled" (rule 3c). Then the duty runs for every other user v and every carrier c2 where:
  - v is a member of the aggregate and arrived on c2 in the same way;
  - some highway h has `st_on_way(c2, h)` and not `st_on_way(c1, h)`;
  - `|sinceRise(subject arrival) − sinceRise(v arrival)| ≤ p.same_time_arrival_window`;
  - v is on the subject's right at the later of the two arrivals. This is written as the bearing at the latest rise of either arrival: `since (¬(rises A_s ∨ rises A_v)) ((rises A_s ∨ rises A_v) ∧ rel_bearing(subject, v, right))`;
  - the pair is not excepted. A pair is excepted when the dot product of the c1 and c2 lane directions is below −p.oncoming_heading_cos, and one of these holds:
    - the subject or v declares `int.left_turn` at X;
    - v's `headingSince` since its entry into X (step `p.heading_since_step_carla_scene_graph`) is in [p.turn_heading_min, p.u_turn_heading_min).

  The duty itself: `¬rel_contact` and `¬(kin_speed > p.halt_speed_tolerance ∧ prim_closest_approach_within ∧ prim_closest_approach_distance < p.conflict_centre_clearance)`.
- **Choices left open:** none were needed beyond the record, so `narrowings` is empty. One choice I did make: I wrote "at the later of the two arrivals" as "at the latest rise of either arrival". Each arrival is the latest rise of its own formula, so this is the same instant and needs no window.

## Witnesses

Witness file: `library/TrafficSpecWitness/NRS_484B/NRS_484B_250_2.lean`.

- The seven planned witnesses use map G1:
  - forbid
  - permit
  - idle (a yield sign governs c1)
  - blind
  - branch_1 (v from the left)
  - branch_2 (v arrives 6 s later)
  - branch_3 (subject alone)
- `branch_4` (violated) and `branch_5` (compliant) are added and use map G2. They exercise the exception for opposed approaches: lane directions, intents and v's heading change. Around v's entry into X they use 50 ms steps, so `headingSince` is decided.
- G1 also has a stop sign that governs an approach to a different intersection Y. This exercises the governs/enters leaves of the control exception.
- Every witness except `blind` reached its planned verdict in run 2. Adequacy (`VACUOUS`) was never reached, because the gate stops at the `blind` failure.

## Why I finished

The node's `blind` scenario can't be built under Core's semantics (computed relations ignore the mask), and a planned verdict isn't mine to change. The rest of the rule and the witnesses are in place. The plan agent needs to re-plan `blind` with a directly read atom such as `kin.speed`. The existing `blindTrace` should then pass as written, with only the manifest's masked id changed.

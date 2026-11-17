# NRS_484B_307_9c — task result

## Final verdict

**UNANCHORED_VARIABLE** (node defect: the node claims no atom that the gate accepts as an anchor for the signal-head device variable).

## Gate runs

1. **UNUSED_CLAIM** on the harness skeleton (a baseline run before I wrote anything): every claim was unused, as expected for `.tt` placeholders.
2. **BUILD_FAIL** at witness line 41: a structure-update expression (`{ Build.signal … with … }` across two lines) did not parse. I rewrote each update as `let d := …; { d with … }`.
3. **UNANCHORED_VARIABLE**: "the quantified variable `h` shares no atom with a binder …; tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder". The facing test compared `dev_position(h)` against `kin_position(subject)` inside one `cmp`, as squared distance and as a dot product.
4. **UNANCHORED_VARIABLE**, same message. I had restated `H·D ≥ 0` in an exactly equivalent form, `H·pos(h) ≥ H·pos(subject)`, with the head on one side and the subject on the other. The gate still did not accept it. A comparison of a device's `dev_position` with the subject's `kin_position` does not anchor the device, whichever way it is written.

I stopped with 2 of the 6 runs unused.

## How the rule is written

- **s2**: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` is the binder class.
- **s1 and s3** share one `existsDevice "traffic_signal" h`, so the head that shows the red is the head the subject faces ("such a signal").
  - **s1** inside that quantifier: the head shows `circular_red`, shows a green arrow (`green_arrow(left|right|straight|u_turn)`, one disjunction over the enumeration), and does not show `circular_green`.
  - **s3**: let D = `dev_position(h)` − `kin_position(subject)` and H = `kin_heading(subject)`. The head is within reach when |D|² ≤ reach². The subject faces it when H·D ≥ 0 and (H·D)² ≥ cos²·|D|². This is the cosine bound with no square root or division (the heading is read as a unit vector).
- **s4**: `¬ rises (∃ roadway r, rel_occupies subject r)`. This is the record's obligation.
- **s5**: four `.not (.ruleApplies id [("subject","subject")])` clauses in the applicability, one per exception.
- No narrowings: I made no choice beyond the record's own.

### Witnesses

- **Layout**: near sidewalk, a 12 m roadway, far sidewalk, and a crosswalk.
- **Head**: at (0, 16), 18 m straight ahead of the pedestrian. That is well inside the 60 m reach, and the cosine is 1 against the 0.87 bound.
- **Pedestrian**: at y = −2 until t = 2 s, then at y = +2 (forbid, idle, blind, branch_1). In permit it stays at y = −2.
- **branch_1**: adds a pedestrian signal at the far curb that governs the crosswalk and shows walk.
- **Window**: every witness is judged on t ∈ [1 s, 3 s], because `rises` needs the observation before. The witnesses were never evaluated, because the gate stopped at the anchoring check.
- **Open risk on branch_1**: I cannot read NRS_484B_283_1d1, so I could not confirm that this scene engages it.

## Why I finished

Hard rule 3b: every quantified variable must be tied to a binder through an anchoring atom, and "if the node claims no anchoring atom, the node is wrong: report it."

- **What is anchored**: the roadway region in s4 is anchored through `rel_occupies`.
- **What is not**: the device `h` in s1/s3 is not. The record ties it to the pedestrian only by comparing `dev.position` with `kin.position` and `kin.heading`. Two runs show the gate does not accept that comparison as an anchor for a device, however it is written.
- **What the gate accepts**: for a device, `dev_governs` (device ↔ region, with the region anchored by `rel_occupies`), or a relation to a binder. The node claims neither for `h`.

## What the plan agent must change (span s3, and s1 with it)

Pick one of these:

1. **Change the mapping.** Have s1/s3 claim `dev.governs` and tie the head to a region tied to the subject. For example: the head governs a crosswalk or roadway region that the subject is about to enter, or the approach whose sidewalk the subject occupies. Keep the facing test (`dev.position`, `kin.heading`, `kin.position`) as written, so that `h` is anchored as `dev_governs h r ∧ rel_occupies subject r'` with the record stating how r and r' relate. This is a new reading of "facing such a signal", so the plan has to state it.
2. **Fix the check, if comparisons are meant to anchor.** If the anchoring check is meant to accept "a comparison that reads both" (as the coding brief says), it should accept a comparison of `dev_position(h)` with `kin_position(subject)`. In that case this is a harness defect, not a node defect.

The same issue applies to NRS_484B_307_2b and NRS_484B_307_8b, which this node says it reuses for the s3 mapping.

The rule and witness files are exactly as they were for gate run 4.

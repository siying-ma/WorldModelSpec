# NRS_484B_307_4b — task result

## Final verdict

`UNANCHORED_VARIABLE` (gate run 2 of 6). I stopped because the node is wrong (span s3; see below).

## Gate runs

1. **`UNUSED_CLAIM`** on the harness skeleton (every formula still `.tt`). I ran this before
   editing, by mistake; it spent one run. After it I wrote the rule and the witnesses.
2. **`UNANCHORED_VARIABLE`**: "the quantified variable `s` shares no atom with a binder, nor with
   a variable that does … tie it in the formula through `rel_occupies`,
   `st_region_geometry_distance`, `dev_governs` or a relation to a binder".

(I also tried a `--help` variant of the gate command by mistake. The permission layer denied it,
nothing ran, and it did not count as a gate run.)

## What is written

- Class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- s1 + s3: `existsDevice "traffic_signal" s` such that:
  - Reach: |dev_position(s) − kin_position(subject)|² ≤ reach².
  - Facing: h·d ≥ 0 ∧ (h·d)² ≥ cos²·|d|². This is the cosine bound written without a square root,
    exact for a non-negative bound.
  - Arrow alone: s shows green_arrow(left|right|u_turn) and none of the other 20 indications.
- s4: R := `existsRegion "roadway" r (rel_occupies subject r)`.
  - The applicability carries the record's "at the previous observation, no roadway" as
    `rises R ∨ (¬R ∧ ¬rises ¬R)`, which equals ¬R at the previous observation.
  - The obligation is ¬R.
- s5: the four `.not (.ruleApplies … [("subject","subject")])` exceptions.
- No narrowings of my own.
- Witnesses: forbid, permit, idle, blind (heading masked), and branch_1 (ped head WALK) as planned.
  I added branch_2 to branch_5 as rule tests, all expecting not_applicable:
  - branch_2: the pedestrian is already on the roadway.
  - branch_3: it heads away from the head.
  - branch_4: the head is beyond reach.
  - branch_5: the arrow is shown with circular_red, so it is not alone.
  - Each witness has `window` 1–2 s, because `rises` has no previous observation at 0 s.
- The gate has not judged the witnesses yet: it stopped at the anchoring check.

## Why I finished — the node is wrong (span s3)

"Facing such a signal" is the only relation the node claims between the subject and the signal
head s of s1: `dev.position` compared with `kin.position` and `kin.heading`.

The gate does not take a comparison of `dev_position(s)` with `kin_position(subject)` as anchoring
a device variable. It accepts only `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or
a relation atom to a binder. The node claims none of these for the device:

- `dev.governs` is unclaimed.
- `st.region_geometry` is unclaimed.
- `rel.occupies` ties only the roadway region of s4. Nothing ties that region to s.

Under hard rule 3b ("If the node claims no anchoring atom, the node is wrong: report it") I cannot
fix this in Lean without using an unclaimed atom.

**What the plan agent must change:**

- **(a)** Claim an anchoring atom for the head in s1/s3. For example, `dev.governs` between s and
  the roadway or crosswalk the pedestrian is about to enter, together with that region's selection.
  This adds a condition to the trigger that the words do not state, so it needs the record's own
  justification.
- **(b)** Or, if the harness is meant to accept a comparison that reads both `dev.position` of the
  quantified device and `kin.position` of the binder (as rule 3b's "a comparison that reads both"
  suggests), the anchoring check needs to accept it for device variables. That is a harness
  question, not one for this node.

The sibling node NRS_484B_307_2b uses "the same words, same atoms" for s3 and will meet the same
check.

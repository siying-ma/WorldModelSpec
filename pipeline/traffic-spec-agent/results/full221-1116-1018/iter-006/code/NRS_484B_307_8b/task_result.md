# NRS_484B_307_8b — task result

## Final verdict

**UNANCHORED_VARIABLE** (2 gate runs used of 6). The node claims no atom that can anchor the
signal head it quantifies over: report to the plan agent (hard rule 3b).

## Gate runs

1. **UNANCHORED_VARIABLE**: "the quantified variable `head` shares no atom with a binder, nor with
   a variable that does … tie it in the formula through `rel_occupies`,
   `st_region_geometry_distance`, `dev_governs` or a relation to a binder".
   The rule binds the head with `existsDevice traffic_signal "head"` and ties it to the subject
   only through the s3 'facing' comparisons. They read `dev_position head` against
   `kin_position subject` (and `kin_heading subject`), which is how the node's s3 element words it.
2. **UNANCHORED_VARIABLE** (same message). As a probe I added two conjuncts that follow from the
   Euclidean reach bound: `|dev_x − pos_x| ≤ reach` and `|dev_y − pos_y| ≤ reach`. In these the
   measures sit only under `sub`/`abs`, not under products. The verdict did not change, so the
   gate does not count a comparison of a device's position with the subject's as an anchor at all.
   I then took the probe conjuncts back out; the files hold the clean version.

## Why the node is wrong

- **Span s1/s3 (the head the pedestrian faces).** The node's only atoms that mention the head are
  `dev.traffic_signal` (its kind and indications) and `dev.position` (its place). The gate's
  anchors for a device are `dev_governs` or a relation to a binder. `dev.governs` is not claimed,
  and no other claimed atom relates a device to a road user or to a region. A comparison of
  `dev_position` with `kin_position` is the record's own way of saying 'facing' (and the index's
  for NRS_484B_307_2b), but this gate does not accept it as anchoring.
- **What the plan agent must change** (one of these):
  - Claim `dev.governs` on s1/s3 and say which region the faced head must govern. For example: a
    roadway, or the crosswalk/roadway the pedestrian is about to enter, which the obligation's
    `rel_occupies`/`st_roadway` then select. That is a reading choice for the plan, not for me.
  - Or, if a position comparison is meant to anchor a device (the coding surface does say "or a
    comparison that reads both"), raise it as a gate defect: the gate rejects
    `cmp(|dev_position(head) − kin_position(subject)|², ≤, reach²)` as an anchor.

## What is written (ready once the anchoring is resolved)

- **Class:** `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **Applicability:** four parts, conjoined.
  - **s1 + s3, on one head:** `existsDevice traffic_signal head (facing ∧ steadyRedAlone)`.
    - `facing` (s3): |d|² ≤ reach², h·d ≥ 0, and (h·d)² ≥ cos²·|d|²·|h|². Here d = head − position
      and h = heading. There is no root, and no divisor that reads a measured atom.
    - `steadyRedAlone` (s1): `shows circular_red ∧ ¬(shows any other indication)`. The other
      indications are circular green/yellow, flashing red/yellow, dark, unknown, and every arrow
      in every direction.
  - **Off the roadway at the previous observation:** there is no 'previous' operator, so with
    R = ∃ roadway r. `rel_occupies subject r` this is written
    `rises R ∨ (¬R ∧ ¬rises ¬R)`, which is exact after the first observation.
  - **s5:** `¬ruleApplies` for each of `NRS_484B_283_1d1`, `NRS_484B_283_1d2`,
    `NRS_484B_283_1d3_o2` and `NRS_484B_283_1d4_o2`, each with map subject ↦ subject.
- **Obligation:** `¬R`.
- **Witnesses:** forbid, permit, idle, blind (masks `kin.heading`) and branch_1 as planned, plus:
  - `branch_2` (not applicable): the head shows a green left arrow beside circular red, so the red
    is not alone.
  - `branch_3` (not applicable): a pedestrian already on the roadway steps back. This exercises
    the `¬rises ¬R` leaf.

  All witnesses set `window := (1000, 2000)` because `rises` is truncated at instant 0. None of
  them has been run yet: the gate stopped at anchoring.
- **Choices left open:** none beyond the record; no narrowing is declared.

## Process note

Once, to look up `dev_traffic_signal_shows`, I ran a `grep` on Core `Vocab/Atoms.lean` through
the shell. That is outside the one permitted gate command; after it I used only the Read tool and
the gate.

## Why I finished

The gate returned UNANCHORED_VARIABLE twice. The second run showed that no rewriting of the
claimed atoms can anchor the device. Using `dev_governs` would be an unclaimed atom, and inventing
which region the head governs would repair the blueprint in Lean. By hard rule 3b the node is
wrong and is returned to the plan agent.

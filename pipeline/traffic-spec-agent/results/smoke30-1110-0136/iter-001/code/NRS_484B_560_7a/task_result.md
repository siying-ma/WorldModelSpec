# NRS_484B_560_7a — task result

**Final verdict: OK** (9 witnesses, 14 names, composes nothing) — 5 of 6 gate runs used.

## Gate runs

1. `WITNESS_FAIL` — blind: expected unknown, got violated. Masking `rel.surface_gap` only drops a
   *supplied* gap (`Runtime/Manifest.lean`, `Mask.relation`); Core still computed it from the two
   footprints. Fix: in `blind`, the source does not observe y's extent, so the gap can't be computed.
2. `WITNESS_FAIL` — blind: track 2 was in `occupancy_observed` without a footprint. Fix: `blind`
   observes only x's occupancy (`occupancyObserved := [1]`, y's occupancy pairs filtered out).
3. `WITNESS_FAIL` — blind: unknown came from `assumption_missing:asm.undercarriage_grounded`, not from
   the masked atom. Fix: `blind` declares the assumption **false**, so the masked gap alone leaves
   the cause unknown. (The narrative's "declares no undercarriage assumption" is read here as "the
   assumption is not declared to hold". An undeclared assumption would be a second source of
   unknown.)
4. `VACUOUS` — the obligation's `st_region_geometry_distance < 15 ft` leaf moved no witness. Fix:
   added `branch_5` (violated): x halts behind a queued y with its trailing end 2 m past the
   crossing, short of 15 ft, so it is still crossing.
5. `OK`.

## How the rule is written

- Class: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- `onCrossing r` (s2 + s6): `since (st_region_geometry_distance x r < Units.feet 15) (rel_occupies x r)`.
  x occupies r now, or occupied it earlier and has stayed less than 15 ft from it since.
- Applicability: `∃ r : railway_crossing, onCrossing r`.
- Obligation: `∀ r : railway_crossing, onCrossing r → ¬(halted ∧ (spaceTaken ∨ grounded) ∧ ¬(conflictAvoided ∨ officerDirected))`
  - halted: `drv_motion_stopped x [p.motion_speed_tolerance]`
  - spaceTaken (s4): `∃ y ≠ x`, `rel_bearing x y "ahead"` (longitudinal component > 0) and
    `rel_surface_gap x y` (the distance) `≤ p.queue_standstill_gap`
  - grounded (s5): `asm "asm.undercarriage_grounded"`
  - conflictAvoided: `∃ z ≠ x`, `prim_closest_approach_within z x [horizon]` and
    `prim_closest_approach_distance z x [horizon] < p.conflict_centre_clearance`
  - officerDirected: `∃ d : human_direction`, role `police_officer`, indication `stop`,
    `∃ q : travel_region`, `dev_governs d q ∧ rel_occupies x q`

## Choices the node left open

- In the obligation, the crossing is bound again with the whole applicability selection under
  `forallRegion`. Since the halt condition does not depend on r, this is equivalent to the record's
  "for a railway crossing r selected".
- y (s4) and z (conflict exclusion) range over every road user of the scene other than x. The
  record names no class for them.
- No narrowings of my own: every reading used is the record's, so `narrowings` stays empty.

## Witnesses

forbid (violated), permit (compliant), idle (not applicable), blind (unknown, `rel.surface_gap`
masked), branch_1 (compliant, halts 9 m past), branch_2 (violated, asm declared), branch_3
(compliant, police officer directs stop), plus two I added:
- branch_4 (compliant): a pedestrian closing on x within the horizon and clearance, which
  exercises the conflict exclusion.
- branch_5 (violated): x halts 2 m past the crossing, which exercises the s6 distance limb.

## Note for the harness

To make `blind` work, the source had to also lack y's extent and occupancy, because a computed gap
survives masking. Planners writing a `blind` scenario that masks a computed relation should expect
to do the same.

## Why I finished

The gate returned `OK`.

# NRS_484B_260 — task result

## Final verdict

**WITNESS_FAIL** on `blind` only. The rule is written in full. Every other planned witness
(forbid, permit, idle, branch_1, branch_2) passed the witness stage: the gate reported only `blind`.
**The node is wrong:** its planned `blind` scenario cannot be built against Core (see below).

## Gate runs

1. `UNUSED_CLAIM` (every claimed name). I ran this one by mistake on the untouched skeleton. Then I
   wrote the rule and witnesses.
2. A second invocation by mistake, with `| head -0` appended to the gate command. Its output was
   discarded. It was not the command exactly as prescribed; I'm reporting it as a protocol slip, and
   it probably counted against the budget.
3. `WITNESS_FAIL`: blind expected unknown, got violated, with rel.bearing masked. Masking
   `rel.bearing` drops only a measured bearing. `rel_bearing` then falls back to `relFrame`, which
   uses v's position and heading and the subject's position. To fix this, I gave the blind scene a v
   whose heading is unobserved.
4. `WITNESS_FAIL`: the blind trace was not admitted. "track 2 is in occupancy_observed but lacks a
   position, a non-zero heading or an extent". After this run I reverted blind to the (admissible)
   forbid scene and stopped.

## Why the node is wrong (the blind scenario, span s6 / `masked: ["rel.bearing"]`)

- `rel.bearing` is computed from kinematics (`Atoms.lean`, `rel_bearing` → `relFrame`). The mask
  (`Runtime/Manifest.lean`, `Mask.relation`) blanks only the measured `bearing` field, so the
  computed value survives. Core's own words: "The computed relations are blanked through the
  kinematics they would be computed from only when the source lacks those too".
- `relFrame v subject` needs v's position and heading and the subject's position. The adapter's
  admission requires position, a non-zero heading and an extent of every track whose occupancy is
  observed.
- s6 needs v's occupancy (`rel.occupies v t` with `st.on_way t h`), and s2/s3 need the subject's.
  So whenever those leaves are decided, the bearing is decided too.
- If v's occupancy is left unobserved, the antecedent becomes unknown for `rel.occupies`, which is
  not masked. The gate rejects that as a stray reason.
- No admissible scene therefore leaves the verdict unknown for the masked `rel.bearing` alone.

**What the plan must change:** pick a `blind` scenario whose masked atom Core actually blanks and
that decides the verdict. For example, mask `kin.speed`: v's "moving" leaf becomes unknown, though so
does the subject's applicability, which is still an unknown verdict for a masked atom. Or mask
`st.on_way`: v's travel region lying on h becomes unknown, but so does the selection of r on h.
Choose one, so that the verdict is unknown for the masked atom only.

## How the rule is written (no narrowing declared)

- **s1**: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s2/s3 (applicability)**:
  - The subject is moving (`kin_speed > p.halt_speed_tolerance`).
  - It overlaps no `alley`.
  - There are some `highway` h, `roadway` r with `st_on_way r h`, and `driveway_or_alley_entrance`
    e, such that the subject overlaps r and e and
    `since (occ e) (occ e ∧ ¬occ r)` holds.
- **s6**:
  - v ranges over all road users other than the subject (`¬ same v subject`), of the vehicle
    aggregate and moving.
  - v overlaps some `travel_region` t with `st_on_way t h`.
  - The subject is ahead of v: `rel_bearing v subject "ahead"`, the Boolean form of "longitudinal
    component positive".
- **s4/s5**: `¬rel_contact`, and not (`prim_closest_approach_within` over p.conflict_horizon and
  `prim_closest_approach_distance` below p.conflict_centre_clearance).
- **Obligation**: `forallRegion` over h, r and e, with the same `selection` formula as the
  applicability (the full re-binding), then `forallUser v (approaching → yields)`.

## Choices left open

- The bearing is written with the Boolean `rel_bearing … "ahead"` (exactly `long > 0`), not the
  measure, whose selectors are only "x"/"y".
- The witnesses state occupancy explicitly, since bodies straddle the entrance and the roadway.
  `window := (0, 2000)` covers the whole trace.

## Why I finished

The only failing witness is a planned scenario that this Core can't build. Rule 7 forbids inventing
a different blind, and the remaining budget can't fix a plan defect. The node needs a repair to
its `blind` scenario (the masked atom).

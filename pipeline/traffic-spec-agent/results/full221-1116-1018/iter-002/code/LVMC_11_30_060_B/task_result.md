# LVMC_11_30_060_B — task result

**Final verdict: OK** (8 witnesses, 14 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — run on the untouched skeleton (all formulas `.tt`) as a baseline.
2. `VACUOUS` — rule and seven witnesses written. Four obligation leaves did no work:
   - the re-bound sign leaves (`dev_regulatory_sign_code`, `dev_governs`) in the obligation's
     selection of the roadway: the only signed scene (`branch_2`) was already not applicable;
   - `kin_speed > p.halt_speed_tolerance` and the closest-approach distance: `forbid` reached body
     contact at its third instant, which hid the conflict leaves.
   Changes: `forbid` cut to two instants (no contact; the violation is the projected conflict);
   added `branch_4` (compliant), where the pedestrian is across the edge of two roadways and a
   conflicting car is only on the one a pedestrians_prohibited sign governs.
3. `OK`. After it, only the witness header comment was updated to describe the new geometry.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- Applicability: some roadway r the subject occupies, which it moves across (r itself or some
  lane k it occupies, via `drv_motion_moving_across_carrier` [p.halt_speed_tolerance,
  p.crossing_motion_cos]), and which no `regulatory_sign` with code `pedestrians_prohibited`
  governs. In addition, some `pedestrian_grade_separation` g has to be within
  p.grade_separation_reach of the subject's body (`st_region_geometry_distance`).
- Obligation: for every user v that is a `DEF-NRS-484A-320::vehicle` and occupies a roadway
  selected exactly as in the applicability: not `rel_contact`, and not (speed > p.halt_speed_tolerance
  ∧ `prim_closest_approach_within` [p.conflict_horizon] ∧ `prim_closest_approach_distance`
  [p.conflict_horizon] < p.conflict_centre_clearance).

## Choices the node left open
- "Vehicles upon the roadway" is read as vehicles on any roadway that meets the full selection.
  That is the roadway the subject occupies and crosses, with no prohibition sign; normally there
  is only one. This follows the record's "re-bound with the same selection" and adds no narrowing.
- The carrier k in g2 is "st.lane or the roadway": I wrote it as a disjunction, the roadway r
  itself or some lane the subject occupies.
- No narrowings declared.

## Why I finished
The gate returned `OK` on run 3 of 6.

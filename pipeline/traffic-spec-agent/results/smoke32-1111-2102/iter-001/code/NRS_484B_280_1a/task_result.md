# NRS_484B_280_1a — task result

**Final verdict: OK** (5 witnesses, 5 names, composes nothing), after 3 of 6 gate runs.

## The rule

- `clsEgo` = `ru_aggregate ego "DEF-NRS-484A-130::motor_vehicle"`.
- `applicability` = `.tt`, because the node has no trigger or condition span and the duty is judged at every observation.
- `obligation` = `forallUser p. (¬ same p ego ∧ ru_aggregate p "DEF-NRS-484A-165::pedestrian") →
  (drv_motion_at_rest ego [p.rest_speed_tolerance] ∨ (¬ rel_contact ego p ∧ ¬ (prim_closest_approach_within ego p [p.conflict_horizon] ∧ prim_closest_approach_distance ego p [p.conflict_horizon] < p.pedestrian_conflict_clearance)))`.
  This is the record's `obligation` sentence translated operator by operator. The distance is only read inside the conjunction with `prim_closest_approach_within`. Where the centres do not approach, the distance is undefined, and the false conjunct decides the conjunction.
- `p` is anchored to ego by `rel_contact` and the two primitives.

## Gate runs

1. **WITNESS_FAIL**: `blind` was expected to be unknown but came out compliant. The cause: masking `rel.contact` only drops a contact value the source supplied (`Core/Runtime/Manifest.lean:252`, "computed relations are blanked through the kinematics they would be computed from only when the source lacks those too"). `rel_contact` then falls back to the surface gap, which Core computes from the footprints. **Change:** in the blind scene, the pedestrian's body extent is not observed (`kin.extent := none`), so contact cannot be computed. Closest approach still decides, because it reads only position and velocity.
2. **WITNESS_FAIL**: the adapter check rejects a track that has no footprint while its occupancy counts as observed. **Change:** in the blind scenes, `occupancyObserved := [1]` (ego only). The rule never reads occupancy.
3. **OK**.

## Witnesses
These use the run's reading values: horizon 3 s, clearance 2.5 m, rest tolerance 0.1 m/s.

- **forbid**: car moving east at 10 m/s; a pedestrian crosses north at 1.5 m/s from (20, −3). The projected meeting is at t* = 2 s with a centre distance of 0 m.
- **permit**: a pedestrian on the sidewalk at y = 8 walks east at 1.5 m/s. The closest centre distance is 8 m and the bodies never touch.
- **idle**: ego is a bicycle (outside the motor vehicle aggregate) passing 2 m from a standing pedestrian.
- **blind**: the permit geometry with `rel.contact` masked. The pedestrian's extent is unobserved, so contact is unknown and decides the verdict.
- **branch_1**: ego alone on the roadway.

## Choices the node left open
None. I declared no narrowings of my own; the record's two narrowings (p1 agency, p2 reading) are not restated.

## Note for the harness / plan
A `blind` witness that masks a relation Core can compute from geometry (`rel.contact`) cannot be unknown just by masking it in the manifest. The scene must also lack the kinematics the relation is computed from. That then needs `occupancyObserved` narrowed to pass the adapter check. The behaviour is consistent with Core's documented masking; I'm noting it for later sessions.

## Why I finished
The gate returned OK.

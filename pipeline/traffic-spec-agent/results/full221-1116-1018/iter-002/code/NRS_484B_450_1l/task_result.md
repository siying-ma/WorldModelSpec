# NRS_484B_450_1l — task result

## Final verdict

`WITNESS_FAIL`: only `blind` fails (it expects unknown and gets violated, with rel.bearing masked). The other 13 witnesses pass.
**The node is wrong:** its planned `blind` scenario can't be built.

## Gate runs

1. `CHECK_FAIL`: `units: compares m^2 with m`. I had written "same nonzero sign" as
   `lateral(rel_bearing) × prim_region_lateral_offset > 0`, and the unit check refuses a product of two lengths.
   I rewrote it as `(lat < 0 ∧ off < 0) ∨ (lat > 0 ∧ off > 0)`. I also added `branch_10`, a mirror of forbid with both vehicles heading west, so b and the edge are on the subject's left. It exercises the left-side limb and expects violated.
2. `WITNESS_FAIL`: `blind: expected unknown, got violated; the manifest masks rel.bearing`. Diagnosed below; no further runs.
   (One extra command, the gate with `--help`, was refused by the permission system and never ran.)

## How the rule is written

- **Class (s1):** `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **Applicability (s9–s11):** there is a road user b, not the subject, that:
  - is in the `DEF-NRS-484A-320::vehicle` aggregate;
  - is at rest: `drv_motion_complete_halt(b, p.halt_speed_tolerance)`;
  - has a road edge e (a `road_edge` region) that lies on (`st_on_way`) some `highway` region, with `st_region_geometry_distance(b, e) ≤ p.edge_standing_gap`.

  In addition:
  - the subject is side by side with b: `rel_longitudinal_overlap(subject, b) ≥ 0`;
  - b and e are on the same side of the subject, both left or both right: the lateral component `y` of `rel_bearing(subject, b)` and `prim_region_lateral_offset(subject, e)` are nonzero and of the same sign.
- **Obligation:** the subject is not at rest, or one of these exceptions holds:
  - **queue (s3/s4):** some road user o, not the subject, in the `DEF-NRS-484A-285::traffic` aggregate, with `rel_ahead_behind_in_lane(o, subject)` and `rel_surface_gap(subject, o) ≤ p.queue_halt_gap`;
  - **devices and police (s5–s7):** a `travel_region` r that the subject occupies (`rel_occupies`) is governed (`dev_governs`) by one of:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing circular_red, flashing_red or red_arrow (any direction);
    - a railway signal or gate with lights flashing, or gate lowering or down;
    - a human direction with role police_officer and indication stop.

  s5 and s7 both name the stop sign and the red signal; each is written once.
- **Narrowings:** none of my own. The record's three (s1, s3, s7) are the plan's and are not restated.

## Choices the node left open

- I wrote "same nonzero sign" as two strict-inequality cases (left/left or right/right), because the unit check rejects a product of two lengths. It means exactly what the record says.
- `red_arrow(dir)` is written as one disjunct per direction (left, right, straight, u_turn). These are values of one atom, so they count as one leaf.

## Why the node is wrong (span s9, scenario `blind`)

The planned `blind` scenario masks only `rel.bearing` and expects unknown. Core can't produce that:

- `rel_bearing(a, b)` falls back to `relFrame` when the source doesn't supply it (`Core/Vocab/Atoms.lean`, `rel_bearing`). `relFrame` computes the bearing from three inputs: `kin.position` of the subject, `kin.position` of b, and `kin.heading` of the subject.
- The masking code (`Core/Runtime/Manifest.lean`, `Mask.scene`) says so directly: computed relations are blanked "only when the source lacks those too". Masking `rel.bearing` drops only a supplied bearing.
- The node's other applicability atoms need those same three inputs:
  - `prim.region_lateral_offset(subject, e)` needs the subject's position and heading;
  - `st.region_geometry` distance from b to e needs b's position.
- So whenever the rest of the applicability is decided, the bearing is computable and decided as well. If one of those kinematics is removed instead, the verdict becomes unknown for an atom the manifest doesn't mask (`rel.longitudinal_overlap`, `st.region_geometry`, the primitive), and the gate rejects it as a stray reason.

No scene can make this witness unknown for `rel.bearing` alone.

**What the plan agent must change:** have `blind` mask an atom whose absence actually decides the verdict. For example, mask `st.region_geometry` (claimed by s11); the narrative would become "the source maps the regions without their outlines". Alternatively, mask an atom that is never computed from kinematics.

The witness file keeps `blind` as narrated (the forbid scene with `rel.bearing` masked), so the failure stays visible.

## Witnesses (all on one geometry; described in the witness file header)

| witness | expects | status |
|---|---|---|
| forbid | violated | passes |
| permit | compliant | passes |
| idle | not_applicable | passes |
| blind | unknown | **fails**: node defect, see above |
| branch_1 | not_applicable | passes |
| branch_2 | not_applicable | passes |
| branch_3 (circular-red signal) | compliant | passes |
| branch_4 (stop sign) | compliant | passes |
| branch_5 (yield sign) | compliant | passes |
| branch_6 (rail lights flashing) | compliant | passes |
| branch_7 (rail gate down) | compliant | passes |
| branch_8 (police officer, stop) | compliant | passes |
| branch_9 (queue, 3 m ahead) | compliant | passes |
| branch_10 (mirrored, left side) | violated | passes |

"Passes" means the run-2 gate failed only `blind`.

## Why I finished

The only remaining failure is the planned `blind` scenario. No witness can satisfy it under Core's semantics, because `rel.bearing` is computed from kinematics the rest of the applicability needs. That's a defect in the node, so I stopped with 4 of 6 gate runs unused.

# NRS_484B_213_2c — task result

**Final verdict: OK** (5 witnesses, 14 names, composes nothing; 1 coder narrowing)

## Gate runs
1. `CHECK_FAIL` — `units: compares m^2·s^-1 with m`: the s4 dot product (velocity × displacement)
   was compared with `zeroMetres`. Changed: the dot product being positive is now written as
   `vx·(ex−px) > −(vy·(ey−py))`, which has the same unit on both sides and needs no new literal.
2. `OK`.

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability = ¬s5 ∧ s3 ∧ s4:
  - s5: no `one_way_roadway` that the subject occupies (`rel_occupies`).
  - s3 (operationalization): some `highway` h that the subject occupies has
    `st_sight_distance(h) < kin_speed(subject) · p.passing_sight_time`.
  - s4: some `elevated_structure` e has `st_region_geometry_distance(subject, e) ≤ 100 ft`
    (`Units.feet 100`), and the dot product of `kin_velocity` with (e's reference point from
    `st_region_geometry` minus `kin_position`) is positive.
- Obligation (s2): for every `highway` h that the subject occupies and every `centre_line` c with
  `st_on_way(c, h)`, `prim_region_lateral_offset(subject, c) ≥ 0`.

## Choices the node left open
- **s3 (narrowing, kind `reading`)**: the node says "st.sight_distance at the subject's point"
  but doesn't name the region it is read from. I read it from the highway region the subject
  occupies, using existential choice over such highways. `st.highway` and `rel.occupies` are
  both claimed by the node, and the highway is the only claimed region kind that holds the
  subject.
- The dot product is written as a comparison between its two components so the units
  match. This is the same condition, not a narrowing.

## Witnesses
The highway is 10, the centre line 11 (on highway 10), the bridge 12 with reference point
(40, 0), and the one-way roadway 13. The subject is a motor vehicle heading east at 20 m/s,
three instants 250 ms apart. At that speed the bound is 220 m. Its front stays 7.5–17.5 m from
the bridge.
- forbid: y = +2 (left), sight distance 100 m → violated.
- permit: y = −2 (right), sight distance 100 m → compliant.
- idle: y = +2, sight distance 1000 m → not applicable.
- blind: y = +2, sight distance absent (masked `st.sight_distance`) → unknown.
- branch_1: same as forbid, with a one-way roadway covering the highway → not applicable.

## Why I finished
The gate returned OK on the second run.

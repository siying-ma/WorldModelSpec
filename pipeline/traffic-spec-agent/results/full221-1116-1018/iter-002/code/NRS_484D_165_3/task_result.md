# NRS_484D_165_3 — task result

**Final verdict: OK** (5 witnesses, 10 names, composes nothing).

## Gate runs
1. `OK`: first run, so nothing changed after it.

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- t1: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- t2: the subject occupies some roadway, **or** it occupies some shoulder that lies (`st_on_way`) on a highway on which some roadway also lies. This follows the record's applicability: "a shoulder lying on the same highway as a roadway". Every region variable is anchored: `sh` through `rel_occupies`, `hw` through `st_on_way(sh, hw)`, and `rw2` through `st_on_way(rw2, hw)`.
- t4 and t6: `env_darkness ∨ env_visibility < Units.feet 1000`. Both spans map to the same atoms and the same figure, so the formula is written once.
- t7 (with t8): `sig_position_lamp(subject)`.
- t3, t9 and t10 are residues and were not changed.

## Choices the node left open
- The roadway limb of t2 has no extra highway condition. By its contract a roadway is part of a highway, and the record states the "same highway" condition only for the shoulder.
- t4 and t6 are written as one disjunction rather than the same disjunction twice. Both spans name the same atoms and literal.
- No narrowings were declared. Every span is written as the record maps it.

## Witnesses
The scenes have a highway (10), a roadway (11) and a paved shoulder (12), with the roadway and shoulder lying on the highway. A motor vehicle stands still in each one.
- forbid: on the roadway at night (darkness true, visibility 2,000 m), lamps off → violated.
- permit: the same, lamps lit → compliant.
- idle: on the roadway by day (darkness false, visibility 5,000 m) → not applicable.
- blind: on the roadway at night, with `sig.position_lamp` masked → unknown.
- branch_1: on the shoulder in fog (darkness false, visibility 120 m, below 304.8 m), lamps off → violated. This is the only witness that reaches the shoulder limb and the visibility limb.

## Why I finished
The gate returned OK on the first run.

# NRS_484B_633_2 — task result

## Final verdict
**OK** (6 witnesses, 11 names, composes nothing).

## Gate runs
1. `OK`. Nothing was changed afterwards.

(Before that, a stray command — the gate command with an extra `--help` and a pipe — was denied
by the permission system and never ran. It used none of the gate budget.)

## How the rule is written
- Class (y1): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (y2, y4/y9): at the same observation, the subject occupies an `elevated_structure` region `e`
  that lies (`st_on_way`) on a `highway` region `h`, **and** some `speed_limit_sign` `d` of kind
  `structure_maximum` governs (`dev_governs`) a `travel_region` `r` the subject occupies.
- Obligation (y3): for every speed limit sign `d` and every travel region `r` that meet the
  applicability's full selection (the subject is on an elevated structure on a highway, `d` is of kind
  structure_maximum, `r` is occupied by the subject and governed by `d`), `kin_speed subject ≤
  dev_speed_limit_sign_value d`.

## Choices the node left open
- None that needed a narrowing. "While on the structure" is read as both occupancies holding at
  the same observation, which is how the record states it. The obligation repeats the whole
  selection (rule 3c), so it re-binds every qualifying sign.

## Witnesses
- forbid: truck at 16 m/s on bridge lane 31, with a structure_maximum sign of 11 m/s → violated.
- permit: the same scene at 10 m/s → compliant.
- idle: car on the bridge, where the only sign is of kind `maximum` → not applicable.
- blind: as in forbid, with `dev.governs` masked and the sign's `governsObserved := false` → unknown.
- branch_1: car at 16 m/s on approach lane 30, which the structure_maximum sign governs, but off
  the bridge → not applicable.
- branch_2 (added): truck at 16 m/s on a signposted bridge that lies on no highway (`ways := []`)
  → not applicable. This exercises the `st_on_way` leaf.

## Why I finished
The gate returned OK on the first run.

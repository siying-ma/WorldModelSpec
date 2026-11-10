# drv.interaction.overtaking — task result

**Final verdict: OK** (gate run 1 of 6: "3 witnesses, 3 names, reads 3 atom(s)").

## Gate runs
1. `OK` — first run, after writing the body and the witnesses. Nothing changed after it.

## Body
`rel_same_direction(a, b; cos_tol) ∧ rel_longitudinal_overlap(a, b) ≥ 0 ∧ kin_speed(a) − kin_speed(b) > speed_tol`

- "rel.longitudinal_overlap not negative" → `≥ 0` (zero, touching projections, counts as side by side).
- "exceeds b's by more than `speed_tol`" → a strict `>` on the difference.
- There are no time operators, sides, regions or classes, because the contract excludes them all.
- The zero is written `Units.metres 0`.

## Choices the record left open
None. The contract decides every choice, so there are no narrowings.

## Witnesses
- **Setup:** bicycle (track 1) at 6 m/s and car (track 2) at 3 m/s, both heading east with 2 m between them laterally. There are 3 observations 0.5 s apart.
- **Instance:** `cos_tol` = 9/10, `speed_tol` = 0.1 m/s.
- **Relations:** none are supplied. Core computes them from the kinematics.
- **holds:** the bicycle's centre moves from 1.5 m behind the car's centre to 1.5 m ahead of it, so the projections overlap at every observation.
- **fails:** the car's centre is 14 m ahead of the bicycle's at the start, which leaves a gap of more than 10 m between the projections.
- **blind:** the geometry of holds, with `kin.speed` masked and unset on both users.

## Why I finished
The gate returned `OK`.

One read of Core was denied: a `grep` through Bash, because only the gate command may run. I read `Vocab/Atoms.lean` with the Read tool instead, to confirm that Core computes the `rel_*` atoms from kinematics.

# LVMC_11_40_180_A — task result

**Final verdict: OK** (6 witnesses, 4 names, composes nothing)

## Gate runs
1. `OK`: this was the first run, and nothing changed after it.

## Rule
- Class (a2): the three `ru_aggregate` atoms joined by `or`. Each atom takes its aggregate id as its literal argument (`DEF-NRS-484A-025::bicycle`, `DEF-LVMC-11-02-082::electric_bicycle`, `DEF-LVMC-11-02-083::electric_scooter`).
- Applicability (a3, a4): `existsRegion "sidewalk" sw (rel_occupies subject sw)` and `asm.fremont_street_main_to_seventh`. The st.sidewalk claim is written as the quantifier kind `sidewalk`, because `st_sidewalk` is not a Boolean formula atom.
- a5 is a residue and is not written.
- Obligation (a1): `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.

## Choices left open
- None that needed a narrowing, so `narrowings` is empty. Reading "ride" as motion is the record's own observable reading and is not restated.

## Witnesses
- The roadway is y ∈ [0,7] and the sidewalk is y ∈ [7,10]. The device moves at 4 m/s, or is at rest at 0 m/s; the tolerance is 0.1 m/s.
- `forbid`: a bicycle moving on the sidewalk, with the assumption true → violated.
- `permit`: a bicycle at rest on the sidewalk → compliant.
- `idle`: a bicycle moving on the roadway; occupancy is observed and no sidewalk is occupied → not applicable.
- `blind`: a bicycle on the sidewalk whose speed and velocity are none, with kin.speed masked → unknown.
- `branch_1`: a bicycle moving on the sidewalk, with the assumption false → not applicable.
- `branch_2` (added): an electric bicycle moving on the sidewalk → violated. It exercises the electric-bicycle aggregate leaf.
- Under the run's reading, the electric-scooter aggregate includes no class. It can therefore never be true: it can only be unknown or false. This is as the node intends: the scooter's limits are unobserved, so membership is unknown.

## Why I finished
The gate returned OK.

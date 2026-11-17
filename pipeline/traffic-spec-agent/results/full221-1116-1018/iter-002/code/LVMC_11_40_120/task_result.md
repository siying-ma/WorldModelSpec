# LVMC_11_40_120 — task result

## Final verdict: OK (14 witnesses)

## Gate runs
1. **VACUOUS**: in the obligation, `dev_governs` and `dev_regulatory_sign_code` (the usability test inside "occupies no usable path") moved no witness.
   Change: added the witnesses `branch_8`, `branch_9` and `branch_10`, all violated. In each, the rider rides along the roadway while also on a second bicycle lane (16) at the roadway's edge. That lane is unusable: closed by a closed_to_traffic sign, closed by temporary traffic control, or only 1 m wide. A usable path (13) lies on the same highway.
2. **OK**.

## How the formulas are written
- Class: the three admitted aggregates joined by `or`, each written as `ru_aggregate` with its id.
- Applicability: the subject is not `complete_halt` (tolerance `p.halt_speed_tolerance`), and for some highway h:
  - the subject occupies a roadway or a bicycle lane or path that lies on h;
  - a usable bicycle lane or path lies on h;
  - a roadway lies on h.
- Usable: `st_lane_width ≥ p.usable_path_width_min`, no regulatory sign with code closed_to_traffic or bicycles_prohibited governs it, and no temporary traffic control governs it.
- Obligation: for every highway h, if the subject occupies a roadway on h, a usable path lies on h, and the subject occupies no usable path on h, then it must move across either a lane it occupies or a roadway on h that it occupies (`moving_across_carrier` with `p.halt_speed_tolerance` and `p.rider_crossing_motion_cos`).
- Region and device kinds are written as quantifier kinds.
- No narrowings were added; the record's own are not restated.

## Choices the node left open
- **Which lanes count for crossing:** a lane only has to be occupied by the subject. It does not also have to lie on h.
- **Roadway direction in the witnesses:** a roadway needs its own designated direction for the roadway branch to be decided. The witnesses give it one wherever that branch has to decide.

## Deviation from the planned narrative, and a reading issue
- The `forbid` narrative names an electric scooter. Under the run's reading, the aggregate `DEF-LVMC-11-02-083::electric_scooter` includes no class: `ru.electric_scooter` is only unresolved. So a rider who is only an electric scooter always has an unknown class, and `forbid` would come out unknown.
- I therefore made the `forbid` and `permit` riders electric bicycles; everything else follows the narrative.
- **Plan/reading agent:** decide whether `ru.electric_scooter` should be included in the electric_scooter aggregate. As it stands, this rule can never decide a verdict for an electric scooter.

## Witnesses added beyond the plan
- `branch_3`: the path is too narrow (n/a).
- `branch_4`: a bicycles_prohibited sign governs the path (n/a).
- `branch_5`: crossing a roadway that has no lanes (compliant).
- `branch_6`: riding along a roadway that has no lanes (violated).
- `branch_7`: the rider is stopped (n/a).
- `branch_8`, `branch_9`, `branch_10`: riding on an unusable edge lane, with a usable path elsewhere on the highway (violated).

## Why I finished
The gate returned OK.

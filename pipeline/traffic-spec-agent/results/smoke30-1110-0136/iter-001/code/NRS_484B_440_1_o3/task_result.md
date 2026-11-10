# NRS_484B_440_1_o3 — task result

**Final verdict: OK** (gate run 1 of 6)

## Gate runs
1. `OK` — 7 witnesses, 7 names, composes nothing; 1 coder narrowing declared. No changes after.

## How the rule is written
- Class (e4): `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability:
  - e1 + e6: some `highway` h and `roadway` rw, with x occupying both and `st_on_way(rw, h)`.
  - e2: `not asm.business_or_residence_district`.
  - x is halted: `drv_motion_stopped x [p.motion_speed_tolerance]`.
  - e11–e13 exception: `not (asm.vehicle_disabled ∧ ∃ roadway r. rel_occupies x r ∧ asm.disabled_vehicle_immovable)`.
- Obligation (e10): for every (h, rw) pair, selected the same way as in the applicability, `st_sight_distance(rw) ≥ 200 ft`. The 200 ft is written as `Units.feet 200`.
- Residue e5 is kept unchanged from the node.

## Choices the node left open
- **e10, declared as a `reading` narrowing:** "x's place" means each roadway region x occupies on the highway it occupies. The sight distance read is the one the source records for that roadway, and every such roadway must meet 200 ft.

## Witnesses
The highway (10) and the roadway on it (11) are rectangles, and car 1 is a motor vehicle heading east. The rule reads no history, so no scene needs a `window`.
- `forbid`: halted in its lane; sight distance 40 m → violated.
- `permit`: halted in its lane; sight distance 300 m → compliant.
- `idle`: moving at 15 m/s → not applicable.
- `blind`: halted; sight distance not recorded and the atom masked → unknown.
- Extra branch witnesses:
  - `branch_1`: business or residence district → not applicable.
  - `branch_2`: vehicle disabled and immovable on the roadway → not applicable.
  - `branch_3`: halted on the highway but off the roadway → not applicable.

## Why I finished
The gate returned `OK` on the first run.

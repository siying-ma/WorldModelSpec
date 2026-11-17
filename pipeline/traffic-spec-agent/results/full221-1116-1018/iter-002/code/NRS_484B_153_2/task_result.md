# NRS_484B_153_2 — task result

## Final verdict
**OK** (9 witnesses, 6 names, composes nothing).

## Gate runs
1. `OK`: this was the first run. No changes were needed after it.

## How the rule is written
- **Binder class (d1, d3):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (d2, d3):** `sig_door_open subject "traffic"`, meaning the subject's door on the traffic side is open.
- **Obligation (d5, d4):** `forallUser c`, it is not the case that all of the following hold:
  - c is not the subject;
  - c is `DEF-NRS-484A-285::traffic`;
  - c is `DEF-NRS-484A-320::vehicle`;
  - c is not at rest: `not drv_motion_complete_halt(c; p.halt_speed_tolerance)`;
  - and either:
    - `rel_contact(subject, c)`, or
    - `rel_longitudinal_overlap(subject, c) > 0` and the lateral part of `rel_surface_gap(subject, c)` is ≤ `p.door_swing_reach`.

## Choices the node left open
- **"Projections share length":** I wrote this as a strictly positive overlap (`> 0`). Two bodies that only touch end to end share no length. That case is caught by `rel_contact` instead. This is the record's own wording, so I declared no narrowing.
- I declared no narrowings of my own, and the residues are left as the record has them.

## Witnesses
The subject is a parked car at (0,0) heading east, 4.5 × 1.8 m. The other road user moves at 1 m/s, which is well above the 0.1 m/s halt tolerance.

| Witness | Scene | Expected |
|---|---|---|
| forbid | lateral gap 0.5 m with overlap | violated |
| permit | lateral gap 2.5 m | compliant |
| idle | doors closed (`doorsOpen = some []`) | not applicable |
| blind | `sig.door_open` masked, traffic 0.5 m away | unknown |
| branch_1 | no other road user | compliant |
| branch_2 | car at rest 0.5 m alongside (exercises the halt leaf) | compliant |
| branch_3 | moving bicycle 0.5 m alongside: traffic but not a vehicle (exercises the vehicle leaf) | compliant |
| branch_4 | moving car 0.5 m to the side but wholly ahead (exercises the overlap leaf) | compliant |
| branch_5 | moving car touching the subject's rear bumper end to end, overlap 0 (exercises the contact leaf) | violated |

## Note on the `traffic` aggregate
Every class included in `DEF-NRS-484A-320::vehicle` is also included in `DEF-NRS-484A-285::traffic`. So no scene can make the traffic leaf matter on its own: anything that passes the vehicle test also passes the traffic test. The gate accepted the rule anyway (it returned no VACUOUS verdict). I'm noting it here so the plan agent knows.

## Why I finished
The gate returned `OK` on the first run.

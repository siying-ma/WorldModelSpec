# LVMC_11_52_040_A — task result

## Final verdict
`OK` (6 witnesses, 10 names, composes nothing).

## Gate runs
1. `OK`, the first run. No change after it.

## How the node is written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability:
  - `drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration)` (s2).
  - Some `roadway` the subject occupies (s3).
  - No `regulatory_sign` d whose code is `angle_parking` governs a `travel_region` the subject occupies (s1, the exception).
- Obligation (s4): `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ for every `travel_region` l the subject occupies, heading·direction(l) ≥ `p.parked_heading_cos`. Both vectors are read normalised, as x·x + y·y.

## Choices the node left open
- **Where the traffic aggregate goes.** The traffic aggregate claimed on s4 is a conjunct of the obligation. It says the subject is a member of the traffic whose lawful direction the carrier designates. Every vehicle class is included in that aggregate, so for any vehicle it is true. It is there because the node claims it.
- **No narrowings declared.**

## Witness geometry
- **Layout:** an eastbound roadway (region 10, also given a designated direction of east) contains the eastbound curbside lane l (region 11). Car 1 stands at (100, 2).
- **Timing:** 15 scenes, 10 s apart. The judged window is 80–140 s, so the 60 s standing window is always fully covered.
- **Headings:** west gives a dot product of −1, east gives 1, north gives 0.
- **Idle:** the car moves at 1 m/s.
- **branch_2:** an `angle_parking` regulatory sign (`conditions := some {}`) governs l.

## Note for the plan (not blocking)
- **"Not an intersection" is not written.** The obligation text says it covers every travel region "(… not an intersection)". The node claims no `st.intersection` atom, so the rule quantifies over every occupied `travel_region`.
- **Effect:** an occupied intersection, or any occupied travel region with no designated direction, leaves the duty **unknown** rather than exempt. This is why the witnesses give the roadway a direction too; without it, `permit` would come out unknown.
- **Fix if wanted:** if the plan wants such carriers excluded, it should claim `st.intersection` on s4 (and add a scenario for it).

## Why I finished
The gate returned `OK`.

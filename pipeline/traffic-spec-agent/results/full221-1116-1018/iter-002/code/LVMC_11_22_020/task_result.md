# LVMC_11_22_020 — task result

## Final verdict: OK

## Gate runs
1. **OK** — 6 witnesses, 7 names, composes nothing. Nothing changed after it.

## The rule
- Binder `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (s2), one atom, not expanded.
- Applicability: `existsRegion "highway" hw (rel_occupies subject hw)` (s4: rel.occupies, st.highway as the quantifier kind),
  `asm "asm.within_city_limits"` (s5), and `kin_speed subject > p.halt_speed_tolerance` (s1, the plan's observable reading
  of "drive or operate": a moving vehicle counts as driven).
- Obligation (s3, surrogate): no other road user `other` (any class; `same other subject` excludes the subject) for which
  `rel_contact subject other` holds, or for which `prim_closest_approach_within subject other [p.conflict_horizon]` holds and
  `prim_closest_approach_distance subject other [p.conflict_horizon] < p.conflict_centre_clearance`.

## Witnesses
- `forbid` (violated): the subject drives at 15 m/s toward a halted car offset 1 m sideways, 30 m ahead. The closest approach
  is 2 s ahead at a centre distance of 1 m. The bodies never touch.
- `permit` (compliant): the subject drives alone on the highway at 12 m/s.
- `idle` (not applicable): the subject drives at 5 m/s outside the highway rectangle. The highway is built, and occupancy is
  observed and false.
- `blind` (unknown): the subject drives at 10 m/s, 12 m behind a car doing 5 m/s, so the projected conflict has a centre
  distance of 0. Occupancy is not observed and `rel.occupies` is masked.
- `branch_1` (violated): the bodies overlap while a faster car pulls away ahead. The centres separate, so contact alone
  decides the verdict.
- `branch_2` (compliant): the subject approaches a halted car in the next lane within the horizon, but the centre distance
  at closest approach is 5 m, which keeps the clearance.

## Choices the node left open
- The s1 movement condition goes in the applicability, as the record's applicability text states. I declared no
  narrowings of my own; the record's s1 and s3 narrowings belong to the plan and are not restated.
- "Another road user" is written as any road user of the scene other than the subject, with no class restriction, as the
  obligation states.
- I added the `branch_1` and `branch_2` witnesses so that each limb of the standard decides at least one witness by itself.

## Why I finished
The gate returned OK on the first run.

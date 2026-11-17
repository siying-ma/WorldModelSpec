# LVMC_11_40_130 — task result

**Final verdict: OK** (gate run 1 of 6: `OK — 8 witnesses, 7 names, composes nothing`).

## Gate runs
1. `OK` on the first write. No changes after it.

## How the node is written
- Class (s2): `ru_aggregate subject "DEF-NRS-484A-025::bicycle"`.
- Applicability (s1): `kin_speed subject > p.halt_speed_tolerance`.
- Obligation (s3 + s4), as a product bound so that no measured atom is a divisor:
  `v·v ≤ 2·a·(D − v·p.bicycle_reaction_time)`. The factor 2 is written as `X + X` because the only
  literal a rule may use is zero.
  - `a` is `Term.cond`: ice → `p.bicycle_decel_ice`, else wet road or precipitation →
    `p.bicycle_decel_wet`, else `p.bicycle_decel_dry`.
  - `D`: the bound is checked at `env_visibility`, and where `env_darkness` holds it is also checked at
    `p.bicycle_lamp_reach`. The bound only gets easier as `D` grows, so holding at both distances is
    the same as holding at the smaller one, which is what the record says. Writing it this way keeps
    the measured visibility out of any selection condition.

## Choices left open
- I wrote "the smaller of" as two bounds joined by "and" rather than as a `cond` minimum. The two
  say the same thing, so I declared no narrowing.
- I added no narrowings. The record's own narrowings (the agency reading on s1 and the reading of
  "conditions" on s4) are left as they are.

## Witnesses
Each witness has one bicycle riding east for 3 instants, with every environment field the rule
reads set: forbid (fog, 10 m), permit, idle (speed 0), blind (`env.visibility` masked), and
branch_1 (ice). I added three more branches so that every leaf changes some decided verdict:
- branch_2: wet road.
- branch_3: precipitation only.
- branch_4: darkness, where the headlamp's reach decides the result.

## Why I finished
The gate returned OK on the first run.

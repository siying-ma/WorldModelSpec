# Formula rewrites — phase 1 evidence (2026-09-28)

`Rewrites_2026-09-28.lean` is the test module as it was built against the old `Derived.lean`,
with every `-- DIFF` guard comparing a rewrite with the old body on the test traces. It built
green. Results:

| old concept | rewrite | needs | differential result |
|---|---|---|---|
| drv.moving_off | `rises (speed > eps)` | E1 | identical on both traces |
| drv.lane_change | `∃ lane l. rises(occ l) ∧ ∃ lane m. prev-occupied(m) ∧ adjacent(l, m)` | E1 | identical |
| drv.entering_intersection, drv.crossing_line | `rises (∃ region k r. occ r)` | E1, E5 | identical |
| drv.in_intersection | `∃ region k r. occ r` | E5 | identical |
| drv.arrival_order | `once(in_b) ∧ sinceRise(in_a) − sinceRise(in_b) > τ ∨ ¬once(in_b) ∧ sinceRise(in_a) > τ` | E2 | **contract change**: an arrival already in progress at the first observation is unknown, where the old body decided it from an upper bound |
| drv.speed_below_traffic | `speed ≤ median_{y ≠ x, in range, same direction} speed(y) − margin` | E3, `same` | identical where every relation is observed; an unobserved relation now makes the result unknown (the old body dropped the member) |
| drv.lane_change_feasible | `definedWhen (¬ straddling) (∃ neighbour n on side. ¬ ∃ o ≠ x. occ(o, n) ∧ gap ≤ g)` | E4, `same` | **old bug**: an unobserved neighbour lane was `false`; the rewrite reports unknown |
| drv.turning, drv.u_turn | over `prim.heading_change` | P1 | identical |
| drv.time_to_conflict, drv.meeting | over `prim.closest_approach_within/time/distance` | P2 | the time agrees where a conflict exists; "no conflict" is an explicit `undefined`, not the horizon |
| drv.condition_in_effect | `prim.conditions_hold` | P3 | the same body |

The extension `same a b` (an identity test on two bound entities) was added during this phase: a
quantifier or aggregate over road users includes the subject, and the old bodies excluded it with
`others`.

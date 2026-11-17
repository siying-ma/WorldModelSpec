# LVMC_11_43_010_B_o1 — task result

## Final verdict (files as left): UNUSED_CLAIM (`kin_speed`) — node defect

## Gate runs (2 of 6 used)

1. `UNUSED_CLAIM kin_speed`: the rule as the node states it (see below) never reads `kin.speed`.
2. Diagnostic only: I temporarily added an inert disjunct `kin_speed(subject) < 0 m/s` to the yield
   formula to see whether anything else fails. Result: **`OK` — 8 witnesses**. So the formulas
   and witnesses are otherwise sound. I reverted the disjunct straight after this run. It can never
   be true, so it reads the atom only to get past the claim check. It also makes the verdict
   unknown wherever speed is unobserved, which the node's obligation does not say.
The gate was not run on the reverted files. They hold run 1's rule and unchanged witnesses, so the
harness re-run should return `UNUSED_CLAIM kin_speed` again.

(A stray compound command at the start was denied by the permission layer and did not run.)

## The defect (for the plan agent)

- **Span b6 ("shall yield")** claims the atoms `kin.speed` and `rel.contact` "as in the mapping index".
- The node's **obligation** says: no `rel.contact` with each vehicle already in r, and not
  (`prim.closest_approach_within` ∧ `prim.closest_approach_distance` < `p.conflict_centre_clearance`).
  It gives speed no role at all. Narrowing b6 says yielding is judged at the entry by the absence of
  conflict, which also leaves speed out.
- So the node claims an atom its own obligation does not use. I cannot write `kin.speed` into the rule
  without inventing a condition the record does not state.
- **Fix:** either remove `kin.speed` from b6's atoms, or state in the obligation what the subject's
  speed decides (for example, a duty to be stopped or slowed at the entry while a conflicting
  vehicle is present), with a parameter if it needs one.

Nothing else in the node needs changing: with the speed claim dropped, the rest passes the gate (run 2).

## How the rule is written (choices the node left open)

- Subject class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability (b3/b5): `∃ r : roundabout, rises(rel_occupies(subject, r))`, meaning occupied here
  and not at the observation before.
- Obligation: `∀ r : roundabout, rises(rel_occupies(subject, r)) → ∀ v, (v ≠ subject ∧
  ru_aggregate(v, vehicle) ∧ rel_occupies(v, r) ∧ ¬rises(rel_occupies(v, r))) → (¬rel_contact(subject, v) ∧
  ¬(prim_closest_approach_within(subject, v; h) ∧ prim_closest_approach_distance(subject, v; h) < clearance))`.
  - r is selected again in the obligation the same way as in the applicability (rule 3c), and the duty
    applies at every roundabout entered.
  - "Occupies r at the observation before and at the entry" (b8) is written as "occupies here and
    did not just start occupying" (`occ ∧ ¬rises occ`). This is equivalent wherever v occupies r here.
- No narrowings of my own.

## Witnesses

There is one roundabout rectangle, x ∈ [0,40], y ∈ [−20,20], and three instants 1 s apart. The
subject enters from the west at 5 m/s. Planned witnesses:

| witness | expected | what happens |
|---|---|---|
| `forbid` | violated | the closest approach is 0 m at 1.2 s |
| `permit` | compliant | the closest approach would be 4 s ahead, beyond the horizon |
| `idle` | not applicable | the subject circulates inside the whole time; the window is t = 1000–2000 ms, because `rises` has no previous observation at t = 0 |
| `blind` | unknown | `rel.occupies` is masked |
| `branch_1` | compliant | the roundabout is empty |

Added witnesses:

| witness | expected | what happens |
|---|---|---|
| `branch_2` | violated | the bodies touch while both cars move at the same velocity, so contact alone decides |
| `branch_3` | compliant | the road user in conflict is a pedestrian, not a vehicle |
| `branch_4` | compliant | the car in conflict enters at the same instant, so it is not already in the roundabout |

## Why I finished

The node claims `kin.speed` (b6), but its obligation leaves speed out, so the gate returns
`UNUSED_CLAIM`. The only ways to use the atom would add a condition the record does not state, or an
inert one written just to satisfy the gate. Following the procedure, I'm reporting the node instead
of working around it.

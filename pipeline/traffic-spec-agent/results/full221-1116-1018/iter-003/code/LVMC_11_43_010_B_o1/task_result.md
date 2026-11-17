# LVMC_11_43_010_B_o1 — task result

**Final verdict: OK** (8 witnesses, 6 names, composes nothing)

## Gate runs
1. OK — first run; nothing changed after it.

(One stray non-gate shell command, `echo skip`, was issued by mistake before the gate; it had no effect.)

## Rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (b3, b5): `existsRegion roundabout r (rises (rel_occupies subject r))`.
- Obligation: for every roundabout region r with `rises (rel_occupies subject r)`, for every road user v
  with `¬ same v subject ∧ ru_aggregate v vehicle ∧ rel_occupies v r ∧ ¬ rises (rel_occupies v r)` (b8),
  `¬ rel_contact subject v` (b6) and `¬ (prim_closest_approach_within subject v h ∧
  prim_closest_approach_distance subject v h < p.conflict_centre_clearance)` (b7, h = p.conflict_horizon).

## Choices left open
- The skeleton routed b8 to the applicability, but the record places it in the obligation ("An entry with
  no such vehicle is compliant"; branch_1 expects compliant), so I followed the record.
- "Occupies r at the observation before the entry and at the entry" is written as
  `rel_occupies v r ∧ ¬ rises (rel_occupies v r)`. Given that v occupies r now, this is equivalent to v
  having occupied r at the previous observation. The language has no "previous" operator; this is an
  encoding, not a narrowing.
- No narrowings declared. The record's own narrowings (b4, b6) are not restated.

## Witnesses
Every witness judges instants 1000–2000 ms (`window`), because `rises` looks back one observation.
The 5 planned witnesses (forbid, permit, idle, blind, branch_1) plus three I added to exercise the
remaining leaves:
- branch_2 (violated): a stopped bus is already in the roundabout and its body overlaps the entering car.
  It is a violation by contact alone: the centres are 6 m apart at closest approach, above the clearance.
- branch_3 (compliant): the forbid scene with a pedestrian instead of a car, so the other road user is
  not of the aggregate.
- branch_4 (compliant): another car enters at the same observation on a conflicting course, so it is not
  already in the roundabout.

## Why I finished
The gate returned OK on the first run.

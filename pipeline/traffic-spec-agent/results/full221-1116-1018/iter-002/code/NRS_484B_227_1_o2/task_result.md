# NRS_484B_227_1_o2 — task result

**Final verdict: OK** (7 witnesses, 7 names, composes nothing). 4 of 6 gate runs used.

## Gate runs
1. `UNUSED_CLAIM` (all claims): run on the untouched skeleton as a baseline. Nothing changed.
2. `UNUSED_CLAIM` (same): run again by mistake before any edit. This was a wasted run, and nothing changed.
3. `VACUOUS`: obligation leaves `st_on_way i h` and `rel_occupies subject i` (the intersection limb
   repeated in the obligation's re-selection of h) moved no witness. With a single highway the
   applicability already excludes that case. I kept the record's whole re-selection (rule 3c) and
   added witness `branch_3` (compliant). In it the subject straddles two divided highways and is in an intersection
   that lies on highway 10 only. The exception lifts the duty on highway 10, and highway 11's duty is kept and met.
   If either leaf is flipped, the occupied, unopened median of highway 10 becomes a violation.
4. `OK`.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: some `highway` h with `rel_occupies subject h`, some `median_or_divider` md with
  `st_on_way md h`, and no `intersection` i with `st_on_way i h ∧ rel_occupies subject i`.
- Obligation: for every highway h selected the same way (all three conditions repeated), and every
  `median_or_divider` m with `st_on_way m h`: `¬ rel_occupies subject m ∨ st_median_or_divider_opening m`.

## Choices the node left open
- None that narrow a span. "Over, across or within" is the footprint overlap, as element d says. The
  opening and crossover limbs are both the `opening` attribute, as elements f and g say. The intersection limb
  is scoped to intersections lying on the same highway h, as the applicability says. There are no narrowings
  of my own.
- Witness occupancy is stated per instant (`occupies`) from the footprint rather than derived from
  the reference point, so bodies that straddle two regions are recorded correctly.

## Why I finished
The gate returned OK.

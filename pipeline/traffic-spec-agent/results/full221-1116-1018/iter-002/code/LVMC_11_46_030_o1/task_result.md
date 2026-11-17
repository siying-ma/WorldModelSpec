# LVMC_11_46_030_o1 — task result

**Final verdict: OK** (9 witnesses, 14 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs
1. **VACUOUS**: the antecedent leaves of the "nearest crosswalk" clause (`st_on_way c2 w`,
   `prim_region_offset_along subject c2 g > 0`) did not change any decided witness, because every scene
   had only one crosswalk. Change: added `branch_4` (violated). It has a crosswalk on w behind the
   subject and a nearer crosswalk ahead that lies on a parallel street w2. Neither one displaces c, but
   each one would if its leaf were dropped.
2. **OK**.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Selection (applicability, repeated in full in the obligation):
  - a travel region g that the subject occupies;
  - a device d that governs g and gives warning. This is either a `crossing_warning_signal` with
    `active`, or a `human_direction` of any role with indication `stop`. Each kind has its own
    quantifier.
  - a highway w with `st_on_way g w`;
  - a crosswalk c with `st_on_way c w`, an offset along g greater than 0, and no crosswalk on w nearer
    ahead.
- Event: `rises (st_region_geometry_distance subject c < 50 ft)`.
- Obligation: the duty must hold for every selection at which the event holds (forall/implies). The
  duty is:
  `since (warn ∧ aheadUnder, halt ∧ dist ≥ 50 ft ∧ warn ∧ aheadUnder) ∧ count (dist < 50 ft) act ≤ 1`.
  `aheadUnder` means "c is ahead of the subject along a travel region it occupies that d governs".

## Choices the node left open
- **The "previous occurrence of the same event" end of the search.** The record writes this as a
  conjunct of the `since`'s left operand. That cannot be written literally: `since` also reads its
  left operand at the judged observation, and the event itself holds there, so the search would always
  stop at once. I wrote it instead as the conjunct `count (within 50 ft) act ≤ 1`. This says the only
  rise of "within fifty feet of c" since the latest halt is the judged one. A halt only counts at 50 ft
  or more, so no rise can fall inside the halt itself. The verdicts are the same as the record's search,
  so I declared no narrowing. `branch_3` exercises it: the subject halts, comes within 50 ft, rolls
  back, and comes within 50 ft again. That is violated.
- **The `permit` narrative does not fit the record's applicability as written.** The narrative has the
  guard switch to proceed before the subject comes within 50 ft. But the applicability requires the
  warning at the moment of the event, so a scene built that way would be not applicable, not
  compliant. In the witness, the guard still shows stop when the subject crosses the 50 ft line, and
  switches to proceed just after. The plan agent may want to reword that narrative.
- **Warning onset in `forbid`, `blind`, `branch_1` and `branch_4`.** The guard (or signal) is present
  at every scene but shows proceed (or inactive) at the first scene, so the warning's onset is
  observed. If the warning were on from the first scene, the result would be the `history_boundary`
  case, which is unknown.
- **"The guard then steps out" in `branch_2`.** The device is present throughout and indicates
  proceed before the stop begins. A device that is absent from a scene would make its indication
  unknown, not false.
- No narrowings declared.

## Why I finished
The gate returned OK.

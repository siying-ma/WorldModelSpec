# NRS_484B_307_8d — task result

## Final verdict: WITNESS_FAIL (branch_1 only) — the node is wrong on branch_1

```
WITNESS_FAIL
   branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle,
   aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle,
   aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
```

On run 5, branch_1's car temporarily had an empty class list so the gate could get past it. On
that run the gate returned **OK** ("16 witnesses, 23 names, composes nothing"): every other
witness, the vacuity check and every other check passed. I then gave the car back its honest class
(`motor_vehicle`), and run 6 shows that branch_1 is the only failure. A passenger car cannot be
shown with an empty class list just to reach `not_applicable` (rule 7: an unobserved fact is never
made false).

## The defect (for the plan agent)

**Span s4 / scenario branch_1.** The planned scenario says a passenger car is "not of the classes
of s4" and expects `not_applicable`. The run's reading does not allow that:

- `DEF-NRS-484A-125::moped` leaves `ru.motor_vehicle` (and every other motor class) **unresolved**.
- So do `DEF-NRS-484A-135::motorcycle`, `DEF-NRS-484B-017::electric_bicycle` and
  `DEF-NRS-484B-018::electric_scooter`.
- So a road user labelled `motor_vehicle` is *unknown* for four of the s4 aggregates. The binder
  class is therefore unknown, and with the wait and entry present the verdict is `unknown`.
- No class in the vocabulary is decided false for all six class elements. Every class is either
  included in, or left unresolved by, one of the s4 aggregates.

So no honest witness of a road user outside the s4 classes can reach `not_applicable` while the
applicability otherwise holds. The plan must change one of these:

- (a) the scenario: expect `unknown` for a passenger car, or replace it with a road user whose
  class the reading decides is outside s4;
- (b) the aggregate classifications: decide `ru.motor_vehicle` (a passenger car) as excluded from
  the moped, motorcycle, electric-bicycle and electric-scooter definitions, if the reading means
  that.

Related: `ru.motorcycle` adds nothing beside `ru.aggregate=DEF-NRS-484A-135::motorcycle`, which
includes `ru.motorcycle`. Its class leaf can only matter for a subject that every s4 aggregate
decides false, and with the current tables that is only a subject observed with no class at all.
Once branch_1 is honest, the vacuity check may flag that leaf.

## Gate runs

1. **UNUSED_CLAIM** (the untouched skeleton; I ran it by mistake before writing anything). Nothing
   changed after it.
2. **BARE_LITERAL** ("formula literals [] ≠ [('2','count')]"). The gate does not read the `Nat`
   of `Formula.count` as a literal. I now compare the count with the literal as a count term:
   `cmp (cond (count edge onset .ge 2) (lit 2 .count) (lit 0 .count)) .ge (lit 2 .count)`.
   This means exactly `count ≥ 2`. It is a workaround for how the gate reads literals, not a
   change of meaning; please check that this is the intended form.
3. **WITNESS_FAIL**:
   - branch_1: the defect above.
   - branch_3 and branch_9: my yaw rates did not match the headings. The yaw rate at a scene now
     covers the interval before it (rate 0 at the entry, ±425°/s over k = 13…16), and the
     headings follow it in five-decimal unit vectors.
4. **VACUOUS** (diagnostic run, with branch_1 temporarily on an empty class list):
   - The "no stop line marks c" guards: in branch_7 and branch_8 the far approach now has its own
     stop line, one that does not mark c.
   - The obligation's copy of the turn-sign condition: I added three violated witnesses.
     - branch_10: a no_right_turn sign governs only the cross approach; the rider turns right.
     - branch_11: a no_left_turn sign governs c; the rider turns right.
     - branch_12: a no_right_turn sign governs i; the rider goes straight and its exit is recorded.
5. **OK** (still diagnostic, branch_1 on the empty class list).
6. **WITNESS_FAIL** on branch_1 only: final state, with the honest class restored.

## How the rule is written (choices the record left to the coder)

- **The previous observation.** "Having occupied c at the observation before" and "the wait held
  up to the entry" are read with `rises (occ i ∨ ¬occ c ∨ ¬waited)`. At the entry this is true
  exactly when, at the observation before, the subject was on c, outside i, and `waited` held.
- **"From the latest onset of the halt."** This is
  `since (redAlone s ∧ ¬occ i) (rises halt ∧ redAlone s ∧ ¬occ i)`. The count of rising greens
  starts at the beginning of the latest run of `halt`, which is that same onset.
- **The place of the stop (s2/s3).**
  - Order: a stop line recorded as marking c; else a crosswalk recorded as marking c; else i.
  - Near the mark: the footprint does not overlap the region, `prim_region_offset_along` along c is
    positive, and `st_region_geometry_distance` ≤ `p.stop_point_tolerance`.
  - The halt also requires that the subject occupies c ("on that approach").
- **The heads of the installation (s7).** A head counts when it governs a travel region that
  enters i, and that region is other than i itself (`¬ same headCarrier i`). An intersection is no
  approach of itself, and `st.lane_enters` is not recorded on an intersection region. Without this
  guard, the blind witness would also be unknown for `st_lane_enters` on the intersection region,
  an atom it does not mask. This adds no condition the record does not imply.
- **Turn prohibitions (s10/s11).** For each regulatory sign governing c or i:
  - coded no_right_turn: a right turn recognized at the exit is prohibited, read ahead with
    `until (occ i) (right_turn)`;
  - coded no_left_turn: the same with `left_turn`.
  
  Where no such sign governs, the condition holds. Where one governs and the exit is unrecorded, it
  is unknown, as the record says.
- **Obligation.** It repeats the whole selection of i (`sel`) for every intersection so selected
  (rule 3c) and requires `yields p` for every road user p who is pedestrian or traffic and is
  proceeding as directed, as the record states.
- **Narrowings.** None declared; every reading above is the record's own statement of a condition
  span.

## Why I finished

All six gate runs are used. The rule and fifteen of the sixteen witnesses are complete: run 5
returned OK with branch_1 temporarily on an empty class list. The one remaining failure, branch_1,
cannot be fixed honestly in the witness, because the reading's aggregate tables make a passenger
car's s4 class unknown. The plan has to change, as described above.

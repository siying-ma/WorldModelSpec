# NRS_484B_307_8d — task result

## Final verdict: BARE_LITERAL

On the final files the gate returns
`formula literals [] ≠ the node's declared literals [('2', 'count')]`.
This cannot be fixed in the two files I own. Everything else in the rule and the witnesses
passes. A diagnostic run with a temporary tautology carrying the literal got **OK** (15
witnesses, 23 names). That tautology has been removed (details below).

## Gate runs (4 of 6 used)

1. **BARE_LITERAL**: the rule and the 15 witnesses as first written. The count threshold "two"
   is written as `Formula.count (green h) halt .ge 2`.
2. **WITNESS_FAIL** (diagnostic): I temporarily added `cmp (lit 2 count) ≥ (lit 2 count)` beside
   the count so the gate would check past the literal. Result: `blind` was unknown for
   `absent_atom:st_lane_enters` as well as the masked `dev.governs`. The cause: in the cycle
   head's `∃ c2 (governs h c2 ∧ lane_enters c2 i)`, c2 also ranges over the intersection itself,
   which is a travel region with no entry record. Fix: `¬ st_intersection c2` (see choices).
3. **OK** (diagnostic, with the temporary tautology still in): 15 witnesses, 23 names, composes
   nothing. Build, static check, anchoring, claims, declarations, parameters, every witness and
   mutation adequacy all pass.
4. **BARE_LITERAL**: the tautology removed. These are the final files.

## Why the node and the gate disagree (what must change)

Span **s7** declares the literal `two` (value 2, unit `count`). The text's "waits for two
complete cycles" is a count of rising edges of a head's green indication since the halt's onset.
The only operator for that is `Formula.count edge since op (n : Nat)`, and its threshold is a
`Nat`. The gate's literal check (`Formula.literals` in `Core/Language/Formula.lean`) collects only
`Term.lit` values and skips `count`'s `n`:

```
| .count e s _ _ => literals e ++ literals s
```

No `Term` counts rising edges either. `Term.aggregate .count` counts road users, and no measure
does it. So a rule can't carry the declared `(2, count)` as a `Term.lit` in any honest
comparison, and the check can't be satisfied without a tautology. I didn't leave one in.

What needs to change, in either of two places:

- **Core/harness:** `literals` should return `(n, .count)` for `Formula.count _ _ _ n` when
  n ≠ 0. That's the natural fix, because the node's literal is correct: the law states "two".
- **Or the plan:** if Core stays as it is, the plan for s7 must not declare a count literal that
  can only be written through `Formula.count`. That would be wrong on the merits, since a figure
  the law states belongs on its span, so the Core fix is the better one.

With either change, the final files should get OK. Run 3 shows the only difference was the
literal.

## Choices the node left open

- **Entry (s5):** "having occupied c at the observation before". The language has no
  previous-observation operator, so I wrote the entry as `inI ∧ rises(inI ∨ ¬(onC ∧ wait))`.
  Where inI holds now, this is exactly: not in i, on c, and the wait satisfied at the observation
  before. The judged observations are `since inI entry`: the entry and every later observation at
  which the subject still overlaps i.
- **Latest onset of the halt (s2/s7/s8):** `since (redAlone s ∧ ¬inI) (rises halt ∧ redAlone s ∧ ¬inI)`,
  read at the observation before the entry. The two cycles use
  `count (green h) halt ≥ 2`, which counts edges since the start of the latest run of `halt`,
  also read there. So red alone and "not in i" hold from the onset through the observation
  before the entry, and red alone also holds at the entry itself.
- **The halt's place (s2/s3):** `halt` = complete_halt ∧ occupies c ∧ place. The place is the
  stop line recorded as marking c, else the crosswalk recorded as marking c, else i. Being "at"
  a region means: not overlapping it, `prim_region_offset_along(subject, r, c) > 0` (upstream,
  read along c's direction), and `st_region_geometry_distance ≤ p.stop_point_tolerance`.
  "occupies c" carries the record's "on the approach that ends in this entry".
- **Steady red alone:** circular_red and none of the other 22 spellings of the state enumeration.
- **Cycle heads:** any traffic-signal head that governs a travel region c2 entering i. I added
  `¬ st_intersection c2`, using an atom the node claims. The `st.lane_enters` contract admits only
  lanes, roadways, shoulders and bicycle lanes or paths as carriers, so an intersection is never
  an approach. Its lane_enters is absent, not false, and without this term it made `blind`
  unknown for an atom the manifest doesn't mask. This is a reading of the claimed relation's
  domain, not a narrowing.
- **Turn prohibition (s10/s11):** a regulatory sign governing c or i, coded no_right_turn, with
  `until inI right_turn_through_region(subject, i)`, and the same for left. This is unknown where
  a sign governs and the exit is unrecorded.
- **Obligation and rule 3c:** for every intersection i selected exactly as in the applicability
  (lane_enters, governs, and the whole entry/halt/wait selection), every p ≠ subject that is a
  pedestrian or traffic and is proceeding (speed above the halt tolerance, and in i, or in a
  crosswalk marking a carrier into i, or on a carrier into i governed by a green head) gets: no
  (subject moving ∧ closest approach within the horizon ∧ distance below the clearance), and no
  contact. I didn't repeat the turn prohibition in the obligation, because it conditions the
  movement and doesn't select i. Repeating it would also leave leaves that no witness can move.
- No narrowings declared.

## Witnesses (15)

The planned six plus nine branches, each exercising a leaf:
- branch_4: left turn under a no_left_turn sign governing i (NA).
- branch_5: a car on the cross approach under green (V).
- branch_6: a car inside i (V).
- branch_7: a pedestrian standing still (C).
- branch_8: a moving body with no road-user class (C).
- branch_9: the rider halts in i (C).
- branch_10: the entrance is marked by a crosswalk only (V).
- branch_11: no marks at all (V).
- branch_12: contact with the halted rider (V).

The turn branches are sampled at 50 ms from the observation before the entry, matching the
step bound.

## Why I finished

The only remaining verdict, BARE_LITERAL, comes from the mismatch between Core and the node
described above, and no change to the two files can fix it honestly. Using more runs wouldn't
change that.

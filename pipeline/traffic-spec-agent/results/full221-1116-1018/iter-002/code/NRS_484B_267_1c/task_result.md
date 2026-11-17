# NRS_484B_267_1c — task result

## Final verdict: UNEXPRESSED (u4, no_atom)

The rule and its 18 witnesses are complete. Without the declaration, the same formulas and witnesses
got **OK**. The verdict is UNEXPRESSED only because I declared that "facing front" on u4 cannot be
written.

## Gate runs (3 of 6 used)

1. **VACUOUS**: the obligation's copy of
   `ru_aggregate(e, DEF-NRS-484A-020::authorized_emergency_vehicle)` moved no witness.
   - **Change:** added `branch_14` (compliant): a permit scene plus a second flashing road user (a
     bicycle, which the aggregate excludes, of official kind `municipal`). It closes at the same
     instant and never passes. If that leaf is forced true, a duty is owed to the bicycle and stays
     open, so the verdict changes.
2. **OK**: 18 witnesses, 25 names.
   - **Change:** the formula left out "facing front" on a condition span, which the hard rules
     forbid (see below). I declared it as a `no_atom` narrowing on u4 and wrote the per-span
     reading into the header.
3. **UNEXPRESSED**: u4 (no_atom), as declared.

## The node defect: u4 "facing front" cannot be stated

- **What the record says:** the u4 element and the applicability read the lamp (with the borrowed
  u5 words "at least one flashing red warning lamp visible from the front") as `sig.warning_lamp`
  with colour red, mode flashing, **facing front**.
- **What Core allows:** the evaluator's `sig_warning_lamp` forms take `[track, colour]` or
  `[track, colour, mode]` only (`Core/Language/Semantics.lean:181-182`). `WarningLamp.facing`
  exists in the world, but no formula can read it.
- **Why I can't work around it:** u4 is a condition span. It may not be narrowed or written with a
  weaker fact, and a lamp of any facing is weaker.
- **What the plan or repair session must do, one of:**
  - withdraw "visible from the front" / "facing front" as a gap or residue of u4 and keep red and
    flashing; or
  - get a Core form that reads the facing (e.g. `sig_warning_lamp [x, colour, mode, facing]`).
- **Once that's settled:** if the facing is withdrawn, the rule needs only the narrowing removed.
  If Core gains the form, it needs only `.lit "front"` added to the lamp atom. Every witness already
  builds its lamps with `facing := .front`.

## Reading defect to pass on: the authorized-emergency-vehicle aggregate has no included class

The run's reading classifies `DEF-NRS-484A-020::authorized_emergency_vehicle` as "included (none)",
with every vehicle class unresolved.

- **Consequence:** `ru_aggregate(e, …authorized_emergency_vehicle)` is never true. For any motor
  vehicle (an ambulance included) it is unknown, and false only for classes outside both lists
  (such as a bicycle).
- **Effect on the u2 limb:** an ambulance, fire apparatus or police car can never decide the
  trigger, and a vehicle that isn't a regulatory-agency official vehicle makes the trigger unknown,
  not false.
- **Effect on the witnesses:** the forbid, permit and blind narratives say "ambulance e". Built as
  an ambulance, they would all come out unknown. So every decided witness uses an official vehicle
  of kind `regulatory_agency` (the u3 limb).
- **Who should fix it:** the reading, by ruling at least `ru.emergency_vehicle` (and
  `ru.fire_apparatus`) included. It's outside this node's files.

## Choices the node left open

None beyond the formula shape the record spells out:
- the trigger is `rises` of the conjunction;
- the obligation applies to every `e` other than the subject whose trigger rises;
- the obligation is `(¬Passed) U (AtPos ∧ (AtPos U Passed))` with strong until, so a vehicle that
  never passes leaves the duty unknown at the trace end, as the record's own narrowing says.

`ru.official_vehicle` is written through its attribute form `ru_official_vehicle_kind(e,
regulatory_agency)`.

## Witnesses

| Witness | Expected | What it shows |
|---|---|---|
| forbid | violated | stops at the edge, moves off while e is still behind, e passes |
| permit | compliant | rests 0.3 m from the right edge until e passes |
| idle | not applicable | lamps off |
| blind | unknown | `sig.warning_lamp` masked |
| branch_1 | violated | rests mid-lane, 5 m from either edge |
| branch_2 | violated | never stops |
| branch_3 | not applicable | a police officer governs the subject's lane |
| branch_4 | not applicable | flashing bicycle of official kind municipal |
| branch_5 | violated | rests 0.3 m from the *left* edge |
| branch_6 | compliant | rests on a paved shoulder, no right-edge region |
| branch_7 | violated | that shoulder is signed `shoulder_use_permitted` |
| branch_8 | violated | rests inside an intersection |
| branch_9 | violated | rests angled to the lane (cosine ≈ 0.89) |
| branch_10 | violated | moves off while e is alongside (bearing behind, projections overlapping) |
| branch_11 | not applicable | flashing e is standing still |
| branch_12 | not applicable | flashing e is ahead of the subject |
| branch_13 | not applicable | flashing e stays beyond 100 m |
| branch_14 | compliant | permit plus a flashing excluded-class road user that never passes |

## Note on my conduct

My first shell call was not the gate command; it was a malformed no-op, and permissions denied it
before it ran. It did not count against the gate budget.

## Why I finished

The rule is complete and gets OK except for "facing front". That one qualification of a condition
span can't be written with this vocabulary, so I declared it as `no_atom` as the rules require. The
remaining fix belongs to the plan or repair session (withdraw the facing, or get a Core form that
reads it), not to this session.

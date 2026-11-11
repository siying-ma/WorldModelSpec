# NRS_484B_307_9a_o2 — task result

## Final verdict

`WITNESS_FAIL` (1 of 6 gate runs used). The node is wrong at span **b3** (subject); the session ends here.

## Gate runs

1. `WITNESS_FAIL`:
   - forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]
   - permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]
   - blind: unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian], not for an atom the manifest masks
   - branch_1, branch_2: expected violated, got unknown for the same reason
   - idle: passed. The rule builds and passes every static check: no CHECK_FAIL, UNCLAIMED_ATOM, UNUSED_CLAIM, UNANCHORED_VARIABLE or DECLARATION_MISMATCH was reported before the witnesses ran.

   Nothing changed after this run. See below for why.

## Why the node is wrong (span b3, subject)

The node writes "vehicular traffic" as: x carries `ru.aggregate=DEF-NRS-484A-285::traffic` and
**does not carry** `ru.aggregate=DEF-NRS-484A-165::pedestrian`. Under the run's reading,
`DEF-NRS-484A-165::pedestrian` includes only ru.child, ru.pedestrian and
ru.pedestrian_with_white_cane_or_guide_animal. It leaves every other class **unresolved**,
including ru.motor_vehicle, ru.bicycle, ru.truck and the rest of the vehicle classes.
`Semantics.aggregateMembership` reports an unresolved class as unknown (`aggregateUnresolved`).
So `¬ ru_aggregate(x, pedestrian)` is unknown for every vehicle. Every class of traffic is either
included or unresolved under the pedestrian aggregate, so no road user can be both decidedly in
traffic and decidedly not a pedestrian.

The result is that the binder class is never true. The rule can only be not applicable or
unknown, and the planned `forbid`, `permit` and `blind` scenarios cannot be reached by any scene.

This is a subject span, so I may not narrow it or write it with a weaker fact. For example, I
cannot drop the pedestrian exclusion or replace it with class atoms the node does not claim.

**What the plan must change:** state "vehicular" in b3 with something the run's reading decides
for vehicles. Options:
- claim the vehicle classes directly (ru.motor_vehicle, ru.bicycle and so on, or a vehicle
  aggregate the corpus defines);
- exclude pedestrians through the ru.pedestrian / ru.child / ru.pedestrian_with_white_cane_or_guide_animal class atoms;
- or have the reading of `DEF-NRS-484A-165::pedestrian` classify the vehicle classes as excluded.

The obligation's use of the pedestrian aggregate (b9, for the parties yielded to) works and can stay.

## Choices the node left open (as written in the rule)

- **Carrier quantifier kind:** c (b4) and c2 (b9) are quantified over `travel_region`, the claimed
  abstract kind, which covers every carrier kind `st.lane_enters` admits.
- **Facing the signal:** an existential over traffic signals that govern c or i. The
  "red with arrow" display is `circular_red ∧ (green_arrow(left) ∨ green_arrow(right))`, read at
  the entry observation.
- **"Since its latest entry":** `since (rel_occupies x i) (entering_region(x,i) ∧ …)`. This is
  unknown where the entry lies before the recording.
- **Selected intersection in the obligation:** the applicability's whole selection of i is
  restated there, and the duty is required at every such i (`forallRegion`).
- **Yielding:** moving(x) → for every party, not (closest approach within the gap ∧ closest
  distance < clearance). The "other traffic" party excludes x with `.not (.same u x)`. The
  pedestrian party does not need that, because x is excluded by its own class.
- No narrowings of my own were declared.

## Witnesses

The six witnesses (`forbid`, `permit`, `idle`, `blind`, `branch_1` for another vehicle in the
intersection, `branch_2` for a signal governing the intersection itself) are written so they are
correct once b3 is decidable. The geometry is described in the witness file's header.

## Why I finished

The only failure is the subject class in b3, which is undecidable for every vehicle under the
run's reading. That is a defect in the node (subject span). I may not repair it in Lean by
narrowing or weakening the subject, so further gate runs cannot reach OK.

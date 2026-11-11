# NRS_484B_307_9a_o1: task result

## Final verdict

**WITNESS_FAIL.** The node is wrong. Under this run's reading, its subject span b3 can never be
decided for a vehicle. 2 of 6 gate runs used.

## Gate runs

1. **WITNESS_FAIL.**
   - forbid, blind, branch_2: unknown, citing `aggregate_unresolved` for
     DEF-NRS-484A-165::pedestrian and for the motorcycle, moped, electric_bicycle and
     electric_scooter aggregates.
   - permit, branch_3, branch_4: rejected by the adapter. In my turning traces the heading stayed
     fixed while the yaw rate was non-zero.
   - Changed after it: I rebuilt the turning traces. The yaw rate is ±100 °/s over 18 intervals of
     50 ms, the heading turns 5° per interval (cos/sin table), and the position moves 1 m per
     interval along that heading. I also widened the intersection so a turn leaves it at instant 32.
2. **WITNESS_FAIL.** The adapter accepts every trace now. The only remaining failures are
   aggregate unknowns:
   - forbid, branch_2, branch_3: unknown for the pedestrian aggregate plus the motorcycle, moped,
     e-bike and e-scooter aggregates.
   - permit, branch_4: unknown for DEF-NRS-484A-165::pedestrian only.
   - blind: unknown, but for the aggregates rather than the masked `dev.traffic_signal`.
   - idle and branch_1 pass.

## Why the node is wrong (span b3, and the reading of DEF-NRS-484A-165::pedestrian)

The record writes 'vehicular' (b3) as "x … does not carry ru.aggregate=DEF-NRS-484A-165::pedestrian".
This run's reading classifies DEF-NRS-484A-165::pedestrian as:
- **included:** child, pedestrian, pedestrian_with_white_cane_or_guide_animal;
- **unresolved:** every other class (motor_vehicle, bicycle, motorcycle, bus, truck, …).

By `aggregateMembership` (Core/Language/Semantics.lean), a road user that carries only an
unresolved class is `unknown (aggregateUnresolved)`. So `not (ru_aggregate x pedestrian)` is
unknown for every vehicle and false for every pedestrian, and it is never true. The applicability
therefore never holds, and no witness can be `violated` or `compliant`. A vehicle class that would
make the conjunct true does not exist, because every class DEF-NRS-484A-285::traffic includes is
either included or unresolved under the pedestrian aggregate.

The gate shows the same thing. Permit and branch_4 are unknown only for `aggregate_unresolved:DEF-NRS-484A-165::pedestrian`.

Under the hard rules I may not drop a subject qualifier or weaken it, so I did not write around it.
**What the plan has to change** (one of these):
- have the reading resolve the vehicle classes as *excluded* from DEF-NRS-484A-165::pedestrian
  ("a person afoot, a person in a wheelchair"); or
- state 'vehicular' with atoms that decide for vehicles. For example, the node's own reading names
  conveyances. Note that `ru.aggregate` is not a stand-in for a class atom the reading permits.

**Second blocker (in NRS_484B_307_9b_o1, not this node's mapping):** for a motor vehicle,
`ruleApplies NRS_484B_307_9b_o1` is unknown wherever the arrow situation holds. The gate cites
`aggregate_unresolved` on DEF-NRS-484A-135::motorcycle, DEF-NRS-484A-125::moped,
DEF-NRS-484B-017::electric_bicycle and DEF-NRS-484B-018::electric_scooter, because motor_vehicle is
unresolved in each. So the b2 exception `not (ruleApplies …)` is undecided for every car under a
red with a green arrow. That too has to be resolved, in 9b_o1's classes or in those aggregates'
readings, before forbid can come back `violated`.

## How the rule is written (no narrowings chosen)

- **Class:** `ru_aggregate x "DEF-NRS-484A-285::traffic"`. The applicability adds
  `not (ru_aggregate x "DEF-NRS-484A-165::pedestrian")`.
- **Judged observation:** x leaves an intersection i (`drv_motion_leaving_region`).
- **The entry:** the latest entry is reached by `since (not entering) (entering ∧ E)`. With no
  entry in between, x occupied i continuously up to the leaving; an entry before the recording
  stays unknown.
- **E (b1/b4):** some travel region c with `rel_occupies (x, c)` and `st_lane_enters (c, i)`, and
  some traffic signal s with `dev_governs (s, c) ∨ dev_governs (s, i)`, showing `circular_red` and
  `green_arrow(left)` or `green_arrow(right)`. The claimed `dev.traffic_signal` is read through its
  `shows` accessor, and the device quantifier ranges over `traffic_signal`.
- **b2:** `not (ruleApplies "NRS_484B_307_9b_o1" {x ↦ x})`.
- **Obligation (b6):** for every intersection i, the obligation restates the whole selection. Where
  that selection holds, it requires either:
  - a left arrow at the entry and `heading_change_since_entry (x, i) ≥ p.turn_recognition_angle`, or
  - a right arrow and that change `≤ −p.turn_recognition_angle`.
  The step is `p.heading_since_step_carla_scene_graph`.
- **Witnesses:** the five planned scenarios, plus branch_2 (signal governs the intersection only),
  branch_3 (right arrow, left turn: violated) and branch_4 (right arrow, right turn: compliant).
  These cover the `dev_governs (s, i)` and `green_arrow(right)` leaves. All witnesses use window
  50–1750 ms, which leaves out instant 0, the one with no prior observation.

## Why I finished

Every remaining failure comes from aggregate membership that the run's reading leaves unresolved
for every vehicle class. Nothing in the two files can fix that without dropping or weakening the b3
subject qualifier and the b2 exception, which the rules forbid. The traces are now valid for the
adapter. Once the reading or the node decides 'vehicular' for vehicles, and 9b_o1 decides for motor
vehicles, the witnesses should be judged as written.

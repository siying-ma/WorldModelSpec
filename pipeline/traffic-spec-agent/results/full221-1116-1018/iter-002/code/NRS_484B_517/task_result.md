# NRS_484B_517 — task result

## Final verdict

**WITNESS_FAIL**, on `branch_1` and `branch_2` only. Under this run's reading, neither planned witness can be built as `violated`. The other 12 witnesses pass: forbid, permit, idle, blind and branch_3 to branch_10.

```
WITNESS_FAIL
   branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-NRS-484A-270::taxicab]
   branch_2: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-270::taxicab]
```

## Gate runs

0. A command I issued by mistake early on (`python -m harness gate … | head -0`) may have run the gate against the harness skeleton. Its output was discarded. It may have used one run of the budget.
1. **BUILD_FAIL**: one closing parenthesis too many in `deviceCompliance`. I removed it.
2. **WITNESS_FAIL**: branch_1 and branch_2 come out unknown. The reason is the reading, explained below. Everything else passes. I stopped here.

## The defect: the run's reading makes the planned branches impossible

The run's reading classifies the two aggregates as follows:

- `DEF-NRS-484A-030::bus` has **no included class**. Every motor-vehicle class is unresolved except `ru.taxicab`, and that includes `ru.bus`, `ru.transit_bus` and `ru.school_bus`.
- `DEF-NRS-484A-270::taxicab` has **no included class**. Every motor-vehicle class is unresolved, `ru.taxicab` included.

`Semantics.aggregateMembership` gives "unknown (aggregateUnresolved)" for any road user carrying an unresolved class. That has three consequences:

1. **No road user is ever decidedly a bus or a taxicab.** The s13–s14 limb ("a bus or taxicab waiting to enter") is at best unknown. So `branch_1` (a car stopped briefly with a door open while a bus waits) can only come out unknown, never violated.
2. **No vehicle is ever decidedly not a taxicab.** The taxicab-stand branch of the applicability (s4–s5) is never decided true. So `branch_2` (a truck in a taxicab_stand) can only come out unknown. Moving the truck to a bus stop doesn't help: `ru.truck` is unresolved for bus as well.
3. **Only a road user whose sole class is `taxicab` is decidedly a vehicle and decidedly not a bus.** So no decided witness can exercise the passenger-vehicle test (`ru_truck`, `ru_trailer_or_combination`) or the interference limb.

**What the plan agent or the reading must change.** The reading should classify `ru.bus`, `ru.transit_bus` and `ru.school_bus` (and whichever other classes the definition's words admit) as included in `DEF-NRS-484A-030::bus`, and `ru.taxicab` as included in `DEF-NRS-484A-270::taxicab`. Then branch_1, branch_2 and idle ("a bus in a bus stop") can be decided. If the classification stays as it is, the scenario plan must be re-planned around it: branch_1 and branch_2 cannot be violated, and idle cannot be a bus.

The rule's formulas follow the record as written. I did not work around the problem in Lean.

## Choices made where the node left them open

- **Zone quantifier.** The applicability is `∃ z: curb_zone. zoneSel z`. The obligation re-selects z with the same `zoneSel` (the subject occupies z, and z is a bus_stop for a non-bus or a taxicab_stand for a non-taxicab). It states the duty for every such z, which is how I read the record's "wherever".
- **"Red or yellow indication or flashing_red".** Written as circular_red, circular_yellow, red_arrow(dir) and yellow_arrow(dir) for all four directions, plus flashing_red. Flashing yellow and flashing yellow arrows are left out: the record names flashing_red separately, which suggests "red or yellow" means the steady indications.
- **"Gate not up".** Written as gate ∈ {lowering, down, raising}, all from the same enumeration. A device recorded with gate `none` has no gate to be "not up".
- **Door "at some observation of the same halt, before or after".** Written as `since halt (halt ∧ door) ∨ until halt (halt ∧ door)`. `sig_door_open` is read without a side.
- **"At no observation of the halt up to the judged one".** Written as `¬ since halt (halt ∧ ∃ w. …)`.
- **Avoid-conflict limb.** "o ahead of subject" is `rel_ahead_behind_in_lane o subject`. The gap is the distance read of `rel_surface_gap subject o`.
- **Narrowings.** None declared: every choice above sits within the record's own wording.

## Witness adaptations forced by the reading (please review)

- **The "passenger car" in forbid, permit and blind** is a car of class `taxicab` alone. It is the only class that is decidedly a vehicle and decidedly not a bus.
- **idle**: the narrative's "a bus in a bus stop" cannot be decided. Instead the subject stands in a `passenger_loading` curb zone, which is neither a bus stop nor a taxicab stand, so the applicability is decided false.
- **blind**: uses a bus_stop zone rather than the narrative's taxicab_stand. In a taxicab_stand the applicability is already unknown because of the taxicab aggregate, so the masked door would not be what decides. In the bus stop, the masked `sig.door_open` is the deciding atom.
- **Added branches**, each passing:
  - branch_3: a stop sign governs the lane (compliant).
  - branch_4: a yield sign governs the lane (compliant).
  - branch_5: a signal shows circular red (compliant).
  - branch_6: railway lights flashing, gate up (compliant).
  - branch_7: railway gate down, lights dark (compliant).
  - branch_8: a police officer indicates stop (compliant).
  - branch_9: queued 2 m behind a vehicle ahead (compliant).
  - branch_10: the vehicle ahead is 15 m away, beyond the queue gap (violated).

## Why I finished

The only failures left are branch_1 and branch_2. Neither can reach its planned verdict under the run's aggregate reading, whatever the Lean says. The fix belongs to the reading or the plan, not to this session. I did not spend the remaining gate runs on changes that cannot change that result.

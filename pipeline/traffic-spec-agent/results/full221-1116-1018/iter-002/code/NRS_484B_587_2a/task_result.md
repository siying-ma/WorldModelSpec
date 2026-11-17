# NRS_484B_587_2a — task result

## Final verdict

`WITNESS_FAIL` (run 2 of 6): `branch_1: expected compliant, got unknown for
[aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle,
aggregate_unresolved:DEF-NRS-484A-280::tow_car, aggregate_unresolved:DEF-NRS-484A-030::bus]`.
Every other witness (forbid, permit, idle, blind, branch_2..branch_6) gives its expected verdict.
I stopped because the problem is in the node and the run's reading, not in the Lean.

## Gate runs

1. `BUILD_FAIL`: a stray parenthesis in the witness helper `mover`. I fixed the parenthesis.
2. `WITNESS_FAIL` on `branch_1` (above). I made no change after this run. See "Why I finished".

## How the rule is written

- Binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability has three parts:
  - **e4:** the subject is moving, i.e. `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` does not hold.
  - **e5:** some `controlled_access` region is occupied by the subject.
  - **e1:** the emergency exception does not apply. The exception is `sig_hazard`, or `ru_emergency_vehicle` together with a warning lamp lit (any of the four colours).
- Obligation (e6) has three parts:
  - no `median_or_divider` is occupied;
  - every occupied `shoulder` is authorized;
  - some `lane` is occupied, or else some authorized `shoulder` is occupied.
- A shoulder is authorized (e2/e10/e12–e18) when all of these hold:
  - the subject is a listed vehicle: AEV aggregate, or `ru_official_vehicle` of kind incident_management/coroner, or tow_car aggregate, or (bus aggregate and `ru_transit_bus`);
  - `st_shoulder_paved`;
  - `st_on_way` to a `highway` region the subject occupies;
  - a `regulatory_sign` of code `shoulder_use_permitted` governs the shoulder (`dev_governs`) and `prim_conditions_hold` for the subject.
- **Choice left open:** the record says "every non-lane region it overlaps is an authorized shoulder". I read this over the kinds the element names: lane, shoulder, and median or divider. The controlled-access and highway regions the subject always overlaps are the highway itself, not a portion outside a lane. Read literally over every region, that clause would always fail. I explained this in the header and declared no narrowing, because this restates the record's meaning rather than narrowing it.
- **Added witnesses:**
  - `branch_5`: a police car with a flashing blue lamp on the shoulder; expects not_applicable. It exercises `ru_emergency_vehicle` and `sig_warning_lamp`.
  - `branch_6`: an incident-management vehicle on a paved shoulder with an unrestricted sign; expects compliant. It exercises the authorized-shoulder conjuncts.

## Why I finished — the node is wrong (with the run's reading)

**Spans e12/e13, e15 and e17.** The node maps three of the listed vehicle classes to admitted aggregates:

- DEF-NRS-484A-020::authorized_emergency_vehicle
- DEF-NRS-484A-280::tow_car
- DEF-NRS-484A-030::bus

For all three, the run's reading has **included (none)**: every vehicle class is *unresolved*. So `ru_aggregate` on these ids can never be true for any road user. For a vehicle it is always unknown (`aggregate_unresolved`).

Consequences:

1. **The planned `branch_1` cannot be met.** A transit bus on a signed paved shoulder whose conditions hold for it should be compliant. But (f) is written as `ru_aggregate bus ∧ ru_transit_bus`, which is unknown ∧ true = unknown. The other disjuncts are unknown too, so the witness can only be unknown. The planned compliant verdict is impossible however faithfully the scene is built. The only listed class that can be decided is `ru_official_vehicle` (incident management or coroner), which `branch_6` shows.
2. **The three aggregate leaves can never move a decided witness.** They are always unknown, so their only effect is to make a verdict unknown. The mutation adequacy check would report them as unexercised (`VACUOUS`) even if `branch_1` were dropped.

What the plan agent must change. Either of these would fix it:

- **Fix the reading:** classify the classes the definitions plainly cover as included, for example:
  - `ru.transit_bus` (and `ru.bus`) under DEF-NRS-484A-030::bus — "a vehicle … designed and used for the transportation of persons for compensation";
  - `ru.emergency_vehicle` / `ru.fire_apparatus` under DEF-NRS-484A-020::authorized_emergency_vehicle;
  - (if defensible) `ru.official_vehicle` of kind tow under DEF-NRS-484A-280::tow_car.
- **Or re-map the elements:**
  - e17 to `ru.transit_bus` alone ("bus in public transit service" already implies a bus);
  - e15 to `ru.official_vehicle` kind tow;
  - e12/e13 to classes the reading can decide.

Then `branch_1` can be compliant and each listed class becomes an exercisable leaf.

No concept is at fault: `drv.motion.complete_halt` behaved as its contract states. I wrote no `dependency_defect.json`.

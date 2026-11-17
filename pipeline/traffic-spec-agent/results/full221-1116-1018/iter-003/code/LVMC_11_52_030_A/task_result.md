# LVMC_11_52_030_A — task result

## Final verdict

**VACUOUS** (gate run 1 of 6; run 2 was a duplicate call made by mistake with its output discarded, no file changed in between).

```
VACUOUS
   applicability leaf 2: atom ru_aggregate [subject, "DEF-LVMC-11-02-150::tour_bus"] (one of 4 literal variants of this atom; none exercised)
```

The build, the static check, the declarations and all 16 witnesses passed: VACUOUS is the
adequacy step that runs after them, and it lists no other leaf. The one leaf family it names
cannot be exercised by any witness under this run's reading (shown below). The node is wrong, or
the reading is.

## Gate runs

1. VACUOUS: the `ru_aggregate(subject, ·)` family in the applicability (tour_bus, shuttle_bus, limo,
   rtc_bus).
2. (Accidental re-run of the same files, output discarded, so the verdict is not known. Same
   files, so presumably the same VACUOUS.)

No edit after run 1. The leaf can't be exercised (see below), and deleting the atoms is
forbidden.

## Why the family cannot be exercised (the defect)

The node says the subject is `ru.aggregate=DEF-NRS-484A-320::vehicle`. It reads exceptions (2) and (3)
through `ru.aggregate=DEF-LVMC-11-02-150::tour_bus`, `…::shuttle_bus`, `DEF-LVMC-11-02-090::limo`
and `DEF-LVMC-11-02-120::rtc_bus`. In the run's reading:

- vehicle: **included** = {bus, commercial_motor_vehicle, emergency_vehicle, fire_apparatus, moped,
  motor_vehicle, motorcycle, official_vehicle, school_bus, taxicab, tour_bus_or_limousine,
  trailer_or_combination, transit_bus, truck}; unresolved = {electric_scooter, rail_vehicle}.
- tour_bus, shuttle_bus, limo: **included = none**; unresolved = exactly the vehicle-included set above.
- rtc_bus: **included = none**; unresolved = the same set plus rail_vehicle.

So every road user that can be bound to `subject` (vehicle membership true) carries a class that
these four aggregates leave unresolved. For any such user, each of the four atoms is unknown at every
instant: never true, never false. Under Kleene evaluation, an instant decided while the atom is
unknown stays decided the same way when the atom is replaced by `tt` or `ff`. An episode that is
decided while it contains unknown instants must be `violated` at some other instant, and that
violated instant does not depend on the atom. So `Adequacy.unexercised` can never find a decided
witness that this family moves, whatever scene is built. The node expects this ("where it includes
no class under an id, the atom is unknown … and the exception is then unknown wherever membership
decides it"), but the gate requires each leaf to do work in a decided witness.

**What the plan / reading must change (spans s9–s12):** one of these:
- the reading classifies at least one vehicle class under each id (e.g. `tour_bus_or_limousine`
  as included in `DEF-LVMC-11-02-150::tour_bus` / `::shuttle_bus` / `DEF-LVMC-11-02-090::limo`,
  `transit_bus` as included in `DEF-LVMC-11-02-120::rtc_bus`, or some vehicle class as excluded), so
  that membership can be decided; or
- the planner takes exceptions (2)/(3) membership out of what this run can decide, e.g. as a
  gap on s9/s11 pending a reading of the LVMC 11-02 definitions.
  The plan agent decides which.

## How the rule is written

- Class: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- Applicability: `existsRegion curb_zone z (rel_occupies(subject,z) ∧ st_curb_zone_colour(z, red) ∧
  ¬(e2 ∨ e3 ∨ e4 ∨ e5))`, where
  - e2: (tour_bus ∨ shuttle_bus ∨ limo aggregate) ∧ st_curb_zone_kind(z, tour_bus_loading) ∧ halt ∧
    sinceRise(halt ∧ rel_occupies(subject,z)) ≤ `Units.minutes 30`;
  - e3: rtc_bus aggregate ∧ st_curb_zone_kind(z, bus_stop) ∧ halt ∧ the same time ≤ 30 min;
  - e4: (ru_official_vehicle ∧ ru_official_vehicle_kind armored_car) ∨ ru_emergency_vehicle;
  - e5: ∃ obstruction o (st_obstruction_kind(o, mail_drop_box) ∧ st_region_geometry_distance(subject,o) ≤
    p.mail_drop_box_reach) ∧ halt ∧ the same time ≤ p.mail_deposit_max_halt.
  - halt = `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- Obligation: `halt → (∃u ≠ subject: rel_ahead_behind_in_lane(u, subject) ∧ rel_surface_gap(subject,u) ≤
  p.queue_halt_gap) ∨ ∃ travel_region r occupied by subject governed by (a human_direction device
  with role police_officer and indication stop | a traffic_signal showing circular_red, flashing_red or
  red_arrow(any dir) | a stop_sign)`.

## Choices the node left open

- Exception (4) has no halt condition: the record's applicability states it as the class alone.
- The obligation does not re-bind z. The duty is the halt, and the halt can only be judged where the
  applicability has selected a red zone the subject occupies.
- `red_arrow(dir)` is written as the four spellings over `ArrowDir`, one disjunct each.
- No narrowings were added.

## Witnesses

These are the planned forbid, permit, idle, blind and branch_1–branch_5, plus:
- branch_6 (ambulance, NA)
- branch_7 (drop-box halt too long, violated)
- branch_8 (drop box out of reach, violated)
- branch_9 (police stop, compliant)
- branch_10 (red signal, compliant)
- branch_11 (stop sign, compliant)
- branch_12 (transit bus 40 min at bus_stop, violated)

All passed the witness check in run 1.

## Why I finished

The only remaining defect is the VACUOUS aggregate family. As shown above, no witness can
exercise it under this run's reading, and the instructions forbid deleting a claimed atom. The
defect is in the node/reading (spans s9–s12), not in the Lean, so more gate runs would not change
the verdict.

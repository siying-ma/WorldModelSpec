# LVMC_11_60_030_A4 — task result

## Final verdict
`WITNESS_FAIL`. The cause is the run's reading of the node's admitted aggregates, not the formulas or the scenes.

## Gate runs
1. `UNUSED_CLAIM` (drv_motion_complete_halt, kin_heading, prim_region_lateral_offset,
   rel_occupies, …). This was the untouched skeleton. I ran it as a probe, and by mistake with a
   `| head` pipe (I then also ran one `grep`/`ls` on Core files). Then I wrote the rule and the witnesses.
2. `WITNESS_FAIL`: forbid, permit, blind, branch_1 and branch_2 all came out unknown, each for
   `[aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus]`.
   `idle` passed: its halt is decided false, which makes it not applicable.

## Why the node cannot pass as read
The run's reading classifies the two aggregates this node claims as follows:
- `DEF-NRS-484A-030::bus`: **included (none)**. Every bus-like class (ru.bus, ru.transit_bus,
  ru.school_bus, ru.tour_bus_or_limousine, …) is unresolved.
- `DEF-LVMC-11-02-150::tour_bus`: **included (none)**. Every vehicle class, ru.bus and
  ru.transit_bus included, is unresolved.

Core (`Semantics.aggregateMembership`) gives:
- true for a user only when it carries an included class;
- unknown (`aggregateUnresolved`) when it carries an unresolved class;
- false otherwise.

So no road user can be decidedly a member of `DEF-NRS-484A-030::bus`. Its binder class (c1) is
either unknown or false. The exception (c2) is unknown for every bus. The rule can therefore never
be violated or compliant: only not_applicable or unknown. The planned `forbid`/`permit`/`branch_1`
verdicts are unreachable. A `blind` witness also cannot be unknown *for the masked atom alone*,
because the unresolved aggregates always add their own unknown.

**What must change (plan / reading, span c1 and c2):** the reading must resolve the classes:
- At least ru.bus and ru.transit_bus must be **included** in `DEF-NRS-484A-030::bus`.
- ru.transit_bus (and ru.bus where the definition allows it) must be **excluded** from, or
  covered by, `DEF-LVMC-11-02-150::tour_bus`, so that a transit bus is decidedly not a tour bus.

If the run cannot resolve these, the node has to be re-planned, for example by mapping c1/c2 to
class atoms that the definitions and the representation decisions permit.

## The rule as written (left in place; I expect it to pass once the reading resolves)
- class: `ru_aggregate(subject, DEF-NRS-484A-030::bus)`
- applicability:
  - ¬tour_bus aggregate;
  - occupies (transit_stop ∨ curb_zone of kind bus_stop/passenger_loading);
  - occupies highway;
  - complete_halt(p.halt_speed_tolerance);
  - sig_door_open(subject), meaning any door.
- obligation:
  - some road_edge with st_region_geometry_distance ≤ `Units.inches 18` and
    prim_region_lateral_offset < 0;
  - and some occupied travel_region with |heading·lane_direction| ≥ p.curb_parallel_cos.
- Witnesses: forbid, permit, idle, blind and branch_1 as planned. I added branch_2 (transit stop
  without a curb zone, compliant) so the transit_stop leaf is exercised.

## Choices the node left open
- I did not add any narrowing of my own. "A door open" is written as `sig_door_open [subject]`
  (any side), as the record's applicability states.

## Why I finished
Every decided witness except `idle` is blocked by the reading's unresolved aggregate
classification for c1/c2. Nothing in the two files I may edit can change that, and the remaining
gate runs would only repeat the same `WITNESS_FAIL`.

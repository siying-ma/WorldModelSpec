# NRS_484B_560_3_o1: result

**Final verdict: OK** (9 witnesses, 19 names, no compositions)

## Gate runs
1. **OK** on the first run. Nothing changed after it.

## The rule
- **Class (s3):** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability (s1 ∧ s2):**
  - **s1:** ∃ travel_region r with `rel_occupies(subject, r)`, governed (`dev_governs(d, r)`) by at least one of these:
    - a `railway_signal_or_gate` with lights `flashing` or gate `lowering`/`down`
    - a `stop_sign`
    - a `traffic_signal` showing `circular_red`
    - a `human_direction` with role `police_officer`/`railroad_flagger` and indication `stop`
  - **s2:** ∃ railway_crossing c with `st_region_geometry_distance(subject, c) ≤ p.railroad_crossing_approach_reach`.
- **Obligation (s4 + s5):** ∃ highway h with `rel_occupies(subject, h)`, and on it a road_edge e with `st_on_way(e, h)`, `prim_region_lateral_offset(subject, e) < 0` and `st_region_geometry_distance(subject, e) ≤ p.pullover_edge_gap`.

## Choices left open
None. The rule is written exactly as the record's applicability and obligation state it, so no narrowings were declared.

## Witnesses
All are one-way two-lane approaches unless noted.
- **forbid** (violated): lights flashing, gate down; the car is in the left lane, 4.5 m from the right edge.
- **permit** (compliant): lights flashing, gate up; the car is in the right lane, 0.4 m from the right edge.
- **idle** (not applicable): lights dark, gate up, and no other device.
- **blind** (unknown): lights flashing; `st.region_geometry` is masked, so the distances to the crossing and to the edge are unknown.
- **branch_1** (violated): a stop sign governs the right lane of a two-way road; the car straddles the lane line, 2.5 m from the edge. Its occupancy of both lanes and the highway is stated rather than derived.
- Added to exercise leaves the planned scenes don't reach (all violated):
  - **branch_2:** gate lowering with the lights dark.
  - **branch_3:** a red traffic signal.
  - **branch_4:** a police officer signalling stop.
  - **branch_5:** the car is 0.4 m from the *left* road edge, so the offset is positive, and 4.8 m from the right edge.

## Why I finished
The gate returned OK on the first run.

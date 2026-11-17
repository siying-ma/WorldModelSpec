# NRS_484B_450_1j — task result

**Final verdict: OK** (13 witnesses, 23 names, composes nothing)

## Gate runs
1. `BUILD_FAIL`: I had passed a third (params) argument to `Term.measure`, which takes only the atom and its args. Removed it in both places.
2. `WITNESS_FAIL` (blind): I had built the blind entrance with `boundary := none`. The adapter refuses that when occupancy is observed. Changed blind to the forbid scene and left the masking of `st.region_geometry` to its manifest.
3. `OK`.

(Before run 1 I mistakenly tried to run the gate with an extra `--help` piped command. It was denied and never ran, so it did not use a gate run.)

## How the record is written
- **Class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** two branches joined by `or`:
  - **s9:** some `fire_station_entrance` f with `st_region_geometry_distance subject f ≤ 20 ft`.
  - **s10 + s11:** some `fire_station_entrance` f such that:
    - the subject occupies a `highway` h, and some `road_edge` e1 lies on h (`st_on_way`);
    - e1's lateral offset, read toward f's side, is > 0 and ≤ |lf|;
    - every `road_edge` e2 on h whose offset toward f's side is < 0 is nearer than e1;
    - the distance to that same f is ≤ 75 ft.
- **Obligation:** `¬halt ∨ queueAhead ∨ directedHalt`.
  - **halt:** `drv_motion_complete_halt` with `p.halt_speed_tolerance`.
  - **queueAhead:** some other user of `DEF-NRS-484A-285::traffic` with `rel_ahead_behind_in_lane o subject` and a body gap (`rel_surface_gap`, distance) ≤ `p.queue_halt_gap`.
  - **directedHalt:** some `travel_region` r the subject occupies, governed by any of:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing circular_red, red_arrow(any direction) or flashing_red;
    - a railway signal or gate with lights flashing, or gate lowering or down;
    - a human direction with role police_officer and indication stop.

## Choices the record left open
- **"Of the sign of lf" (s10):** written with `Term.cond (lf > 0) l (−l)`, which reads each offset toward the entrance's side, rather than as a product of offsets. Where lf = 0 the side test fails, which matches the record. This is a writing choice, not a narrowing, so no narrowing is declared.
- **Shared exceptions:** s5's stop sign and red signal are also in s7's list, so each is written once.
- **Extra witnesses:** I added `branch_4`–`branch_9`, one per exception leaf: stop sign, yield sign, red signal, rail lights, rail gate, and a queue vehicle 2 m ahead in the same lane.

## Why I finished
The gate returned `OK`.

# NRS_484B_307_9a_o1 — task result

## Final verdict: OK

`OK — 14 witnesses, 17 names, composes NRS_484B_307_9b_o1,NRS_484B_307_9b_o2,NRS_484B_307_9b_o3,NRS_484B_307_9b_o4`
(6 of 6 gate runs used).

## Gate runs

1. **BUILD_FAIL** (witness file): `fun k => … (k : Int)` made `k` an `Int` against `List.range`,
   and `until` is a keyword. Fix: typed binders with `Int.ofNat`; parameter renamed `upto`.
2. **WITNESS_FAIL**:
   - Turning traces were rejected as not adapter-producible, because the heading did not follow the yaw rate.
     Fix: the path is now integrated from the yaw rate, 3° per 50 ms step at ±60 deg/s, in µm fixed point.
   - forbid, blind, branch_1, branch_5, branch_7, branch_8 and history_boundary came out not_applicable.
     Cause: `Build.scene` takes occupancy from the reference point only, so at the entry the body was never on lane c and in i at the same time.
     Fix: occupancy is now stated from the footprint (`Geom.polygonsOverlap` of `footprint`).
3. **WITNESS_FAIL**:
   - branch_6 came out violated.
   - history_boundary (ru.bus) was unknown for `aggregate_unresolved` (DEF motorcycle, moped, e-bike, e-scooter), which comes from E1 = `ruleApplies NRS_484B_307_9b_o1` on a bus.
4. **WITNESS_FAIL**, a deliberate probe run. I added temporary witnesses, later removed, to find out how 9b_o2 reads "two complete cycles":
   - A 600 s halt under a steady red + green arrow was **violated**.
   - A 56 s halt with five 10 s arrow cycles **passed**.
   - A 600 s halt with ten 60 s cycles (the new branch_6) **passed**.

   So o2 counts cycles rather than duration. The motorcycle history probe was uninformative: it started 2.25 m from the line, which is itself an approach start.
5. **VACUOUS**:
   - The exception's leaves inside the obligation were idle, because engagement already gates it.
   - `st_entrance_of(w, c)` (the crosswalk place) never moved a verdict.

   Fix: the obligation repeats only the selection of i (leaving, entry, carrier, signal). Added branch_9: a motorcycle halts at a crosswalk-marked entrance, waits through the cycles and goes straight, which is not_applicable.
6. **OK**.

## Choices the node left open

- **c ≠ i guard (b4/b5).** The intersection is itself a `travel_region`, and Core returns `st_lane_enters` unknown on a region without a lane record. So the intersection stood as an undecided candidate carrier into itself. This made E2 unknown in branch_5, where the signal governs i.
  - I added `.not (.same c i)`. An approach carrier entering i is never i itself, so this adds no condition the record lacks.
  - It is not declared as a narrowing; b4/b5 are triggers.
- **End of the E2 search at the previous visit.**
  - The record ends the search at x's previous entry into i. The formula ends it at that visit's leaving (`drv_motion_leaving_region`), because a `since` cannot exclude the current entry observation.
  - No act can lie between a previous entry and its leaving, since the act requires x off i, so both ends decide alike.
  - The search reaching the trace start is `since`'s truncation, which gives unknown as the record asks.
- **Same carrier and signal for E2.** E2 is read at the same entry, through the same carrier c and signal as the selection; it is not a free `∃c`.
- **Exception placement.** E1 and E3 are read at the judged (leaving) observation. E2 is read at the entry, inside the same `since`.
- **No narrowings were added** (`narrowings := []`).

## Witness notes and deviations from the narratives

- **history_boundary is a ru.motorcycle, not the narrative's ru.bus.**
  - The narrative's own reasoning ("x's class under paragraph (b) is unresolved, so the exception is unknown") produces an unknown carrying `aggregate_unresolved`. The gate's history-boundary check rejects that reason.
  - With a motorcycle, E1 is decided, and the exception turns only on the unrecorded halt (`window_truncated:since`).
  - The planned verdict (unknown) and boundary are kept. **For the plan agent:** a history_boundary narrative for this node should name a class that paragraph (b) decides (motorcycle or moped).
- **branch_6's cycles.** "Two complete cycles in which the signal does not change for it" is built as ten 60 s arrow cycles over a steady circular red, during a 600 s halt 0.25 m short of the line. Under the composed 9b_o2, a 40 s halt with two arrow rises did not satisfy the condition, while five cycles did.
- **Added branches:**
  - branch_7 (violated): bus, entrance marked by a crosswalk only, no halt.
  - branch_8 (violated): bus, no marks, no halt.
  - branch_9 (not_applicable): motorcycle halting at the crosswalk.
- **Windows.** Every witness speaks from its second scene on. The first scene has no prior observation, so entry and exit are unknown there.
- **Accidental shell commands.** Twice I issued a shell command other than the gate. Both were denied by the environment and nothing ran.

## Why I finished

The gate returned OK on run 6, the last of the budget.

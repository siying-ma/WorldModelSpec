# NRS_484B_400_1_o1 — task result

**Final verdict: OK** (7 witnesses, 13 names, composes nothing). 3 of 6 gate runs used.

## Gate runs

1. **WITNESS_FAIL**: the traces were not ones the adapter can produce. The heading stayed fixed while the yaw rate was non-zero, and in the lane-change branches the lateral jumps made the path length grow less than the straight-line displacement.
   - Fix: rebuilt the traces kinematically. Heading now rotates 4.5° per 50 ms scene, written as the cosine and sine of 4.5·j° to six decimals. Position follows heading. Displacement is 0.45 m per scene against 0.5 m of path. Lane changes move 0.2 m sideways per scene.
2. **WITNESS_FAIL**: `blind` was unknown for `absent_atom:st_lane_direction` as well as for the masked `st.lane_enters`.
   - Cause: the carrier quantifier (kind `travel_region`, claimed for e3) also ranges over the intersection i itself. An intersection records neither `st_lane_enters` nor `st_lane_direction`, so that disjunct stayed unknown.
   - Fix: added `not (same c i)` to the carrier selection (see choices below), plus a `branch_3` witness in which that conjunct decides the verdict.
3. **OK**.

## The rule

- **Class:** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Selection** `S(body)`, the same in both formulas (rule 3c). For some intersection i:
  - `rises (headingChangeSinceEntry(x,i; p.heading_since_step_carla_scene_graph) ≤ −p.turn_recognition_angle)`, and
  - `since (¬entering(x,i)) (…)`, which reads back to x's latest entry into i. At that entry:
    - `entering_region(x,i)` and `intent int.turn x i`;
    - some travel region c ≠ i with `st_lane_enters c i` and `rel_occupies x c`, lying on a highway h (`st_on_way c h`);
    - some `turn_lane` r with `st_turn_lane_side r right`, `st_lane_enters r i`, `st_on_way r h` and `¬ opposed_directions(r, c; p.opposed_carriers_cosine)`, then `body`.
- **Applicability:** `S(tt)`.
- **Obligation:** `S(rel_occupies x r ∧ holdsFor .path p.turn_approach_length x ((∃ travel_region a. st_lane_enters a i ∧ rel_occupies x a) → rel_occupies x r))`.
  - The path window is read at the entry, inside `since`. The choice among qualifying turn lanes stays existential, as the record states.

## Choices the node left open

- **`not (same c i)` on the approach carrier (e3).** The record says x "entered i from a carrier c with st.lane_enters(c, i)". A carrier that enters i is never i, but i is itself a `travel_region`, and on it the source records no `st_lane_enters` or lane direction. Those values are unknown, not false, so without this conjunct every scene's verdict would carry an unknown from the intersection. The conjunct follows from the record's words and does not narrow them, so no narrowing is declared.
  - Branch_3 is a cross-street approach with no right turn lane. There this conjunct turns the verdict from unknown into not_applicable.
- **The approach condition (e6)** is written as the record's `obligation` states it: wherever x occupies a carrier entering i in the window, it occupies R. A body straddling c and R therefore complies at those observations.
  - The record's own narrowing on e6 says "every carrier … must be the right turn lane", which reads slightly stricter for a straddling body. I followed the obligation field. The plan may want to reconcile the two wordings.
- **Unused skeleton literal.** `zeroMetres` is not used; it is left as the harness wrote it.

## Witnesses

All witnesses use one geometry, given in the witness file header. Every scenario names the instants from the entry on (`window := (3150, 4450)`), because before the entry the heading-since-entry term and the `since` read-back are unknown.

- `forbid` (violated): through lane c, then a right turn.
- `permit` (compliant): on R throughout, then a right turn.
- `idle` (not applicable): from c, a left turn.
- `blind` (unknown): `forbid`'s trace with `st.lane_enters` masked.
- `branch_1` (violated): a late lane change into R, within 15 m of path before the entry.
- `branch_2` (compliant): an early lane change into R, before the 15 m window.
- `branch_3` (not applicable): a right turn from the cross highway's lane; R lies on the other highway.

## Why I finished

The gate returned OK on both files.

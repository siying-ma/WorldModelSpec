# NRS_484B_400_1_o2 — task result

**Final verdict: OK** (6 witnesses, 15 names, composes nothing). 4 of 6 gate runs used.

## Gate runs

1. **UNUSED_CLAIM** on the untouched skeleton. I ran this by mistake before I had written anything, so it cost one run. Before it, I also tried a malformed gate command with an extra pipe. The permission layer denied it and it did not run.
2. **WITNESS_FAIL**: the trace admission rejected every witness. Each heading stayed fixed while the yaw rate said it was turning, and in `branch_1` a 4 m lane jump in one step was longer than the path-length increment.
   - Fix: I rebuilt the kinematics with an exact rational rotation per step, (312/313, 25/313), about 4.5812°, with a yaw rate of ±91.624 deg/s held over the 50 ms before each scene.
   - Positions are integrated along the heading at 0.49995 m per step, and path length grows 0.5 m per step.
   - The lane change is now a smooth S-curve.
3. **VACUOUS** on the obligation's copy of the "no right turn lane" leaves (`st_turn_lane_side`, `st_lane_enters`, `st_on_way`, `drv_road_opposed_directions` on `tl`). No witness had a turn lane that fails the test while the rule applies.
   - Fix: I added `branch_2`. It has four turn lanes that do not count, each failing exactly one requirement: a left turn lane; an opposed southbound right turn lane; a right turn lane on the cross highway h2; and a right turn lane entering another intersection i2.
   - The second intersection made the applicability unknown when the carrier variable was an intersection, because `st_lane_enters` reads unknown on a region with no lane record. So I replaced `¬same(c, i)` with `¬st_intersection(c)`; see the choices below.
4. **OK**.

## How the rule is written

- **Class:** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **e5:** the right turn counts as recognized at the observation where the heading change since entry first reaches the angle. In Lean that is `rises (heading_change_since_entry(x, i; p.heading_since_step_carla_scene_graph) ≤ −p.turn_recognition_angle)`.
- **e2/e3:** the entry is found with `since (¬entering(x,i)) (entering(x,i) ∧ intent int.turn x i ∧ occupies(x,c))`, with c a `travel_region` such that `st_lane_enters(c,i)`, `st_on_way(c,h)` and h a `highway`.
- **e7/e8:** written negated: there is no `turn_lane` tl that has side right, enters i, lies on h, and is not `drv_road_opposed_directions(tl, c)`.
- **e9:** checked at the same `since` anchor. There must be a `lane` L that enters i, lies on h, is not opposed to c, has adjacency ordinal = count, and is occupied by x. In addition, `holdsFor .path p.turn_approach_length x` must hold for: every travel region a that x occupies and that enters i, x also occupies L.
- **Obligation:** `∀ i c h (selection → since(¬entering, entering ∧ extreme-right-lane duty))`. It restates the applicability's whole selection (recognition, entry with the intention, carrier, highway, no right turn lane).

## Choices the node left open

- **"Entered from c":** read as x's footprint overlapping c at the entry observation, which is the plain reading of the record's trigger. It is not declared as a narrowing.
- **`¬st_intersection(c)`:** this is the one conjunct the record does not spell out. A reviewer should look at it.
  - It states what the `st.lane_enters` contract makes a carrier: a lane, a kind refining a lane, or a directed roadway, shoulder or bicycle segment, never an intersection.
  - `st_lane_enters(c, i)` already implies it, but on an intersection that atom is unknown rather than false. Without the conjunct, a not-applicable verdict cannot be decided.
- **Duty for every selected (i, c, h):** where x straddles two carriers, each is held to the duty.
- **Straddling:** a vehicle straddling L1 and the extreme right lane L2 meets the window clause, because the record only asks that x occupy L wherever it occupies a carrier entering i.
- **Narrowings:** none declared.

## Witnesses

All witnesses judge the window from 3300 to 4950 ms: after the entry at k = 60, so the heading change since entry exists, and before the recognition at k ≈ 74.

| Witness | Expected | Scene |
|---|---|---|
| forbid | violated | Two lanes; x in L1, ordinal 1 of 2. |
| permit | compliant | Two lanes; x in L2, ordinal 2 of 2. |
| idle | not_applicable | x in a right turn lane TL entering i on h, northbound. |
| blind | unknown | Permit geometry with `st.lane_adjacency` masked. |
| branch_1 | violated | x moves from L1 to L2 inside the 15 m approach window. |
| branch_2 | violated | Four turn lanes that do not count; x turns from L1, ordinal 2 of 3. |

## Why I finished

The gate returned OK. The node did not appear wrong, and no concept showed a defect against its contract.

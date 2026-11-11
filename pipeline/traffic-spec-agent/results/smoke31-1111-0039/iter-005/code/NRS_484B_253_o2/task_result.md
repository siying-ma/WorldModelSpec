# NRS_484B_253_o2 — task result

**Final verdict: OK** (gate run 4: "9 witnesses, 10 names, composes NRS_484B_253_o1"). After that run I changed only a comment in the rule file's header; no formula or witness changed.

## Gate runs
1. **UNUSED_CLAIM**: I ran this by mistake on the untouched skeleton, which still had `.tt` placeholders. Next I wrote the rule and all nine witnesses.
2. **WITNESS_FAIL**: the adapter could not have produced the traces. At t=6000 y's yaw rate was 12 deg/s, but its heading did not change. The check holds each scene's yaw rate over the interval before that scene. Fix: y's headings now follow its yaw rate. After the onset y keeps a heading 12° left of north (written to 5 decimal places). In branch_3, a 78 deg/s step brings it exactly west. Positions now also follow the speeds.
3. **WITNESS_FAIL** (forbid, blind): the verdict was unknown because `st_lane_enters` and `st_lane_direction` were absent. The intersection is itself a `travel_region`, so i was a candidate for x's carrier c and y's carrier c2. It has no lane record, so `st_lane_enters i i` and the opposed-directions test read unknown. Fix: `approachTo c i := ¬st_intersection c ∧ st_lane_enters c i`.
4. **OK**.

## Choices the node left open
- **A carrier is never an intersection** (`not st_intersection` on c and c2). The `st.lane_enters` contract lists the carriers as a lane, roadway, one-way roadway, shoulder or bicycle lane or path, so this only states what the contract already says. Without it, no entry by x is ever decided, because x occupies i whenever it enters i. I declared no narrowing because the reading is not narrower than the record's. `st_intersection` is a claimed atom. A reviewer may still read this as an added exclusion; if so, the plan should say so on s2 and s13.
- **Several carriers:** the record says that where x enters through several carriers and their verdicts differ, which one governs is unknown. I wrote this as `definedWhen (∀(sel→ok) ∨ ∀(sel→¬ok)) (∀(sel→ok))` over every (i, c) x enters through.
- **Since operators:** the record's past readings use `since` (Core: ψ now, or φ now and since at the previous observation):
  - (1) within the intersection: `since (occ y i) (entering y i ∧ occ y c2)`
  - (3) the turn's onset: `since (occ y i) (rises (turning_left y ∧ occ y i) ∧ since o1 (o1 ∧ entering y i))`
  - (4) the signal: `since (occ y c2 ∨ occ y i) (signal ∧ since (occ y c2 ∨ occ y i) (entering y c2))`

  c2 is bound by `existsRegion travel_region` outside these, and both (1) and (4) read it.
- **Witness geometry:** in the witnesses x (and in branch_2 also y) touches two regions at its entry. Occupancy comes from each body's reference point, so for those instants I listed both regions explicitly.
- **My guesses about NRS_484B_253_o1:** I could not read o1's file, so I placed x to fit the forbid and branch_2 narratives. In forbid, x is 68 m from i at 4 m/s at the onset (about 17 s away). In branch_2, x is 1 m from i at 10 m/s. The gate accepted both.

## Why I finished
The gate returned OK on run 4, with 2 of the 6 runs left. Nothing in the node needs changing.

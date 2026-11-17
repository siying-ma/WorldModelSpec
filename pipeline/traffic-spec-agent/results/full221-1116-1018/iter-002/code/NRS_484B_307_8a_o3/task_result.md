# NRS_484B_307_8a_o3 — task result

## Final verdict: OK

`9 witnesses, 27 names, composes nothing`. Afterwards I changed only comment lines in the
witness header (the geometry description), not the code.

## Gate runs (5 of 6 used)

1. **UNUSED_CLAIM** on the harness skeleton, every claimed name (formulas were `.tt`). Nothing had
   been written yet.
2. **No verdict.** I ran the gate by mistake with its output piped to `head -0`. That spent a run
   and I saw nothing. (A separate `--help` call was denied by the sandbox and did not run.)
3. **WITNESS_FAIL**: `branch_2` was expected violated but got not_applicable. Cause: the one-way
   roadway 30 stopped at the intersection edge. At the entry observation the subject's reference
   point is in the intersection, so "the subject occupies a one-way roadway" read false. Fix:
   roadway 30 now runs through the intersection, as a roadway does. The scene changed; the rule
   did not.
4. **VACUOUS** on 6 applicability leaves and 13 obligation leaves. Fixes, all in scenes:
   - The absence tests (`st_entrance_of(sl2|sl3|cw2, c)`) had no instance. I added marks on a
     cross-street approach that do not mark c: stop line 21 on lane 14 in the crosswalk-approach
     scenes, and stop line 21 plus crosswalk 42 on lane 15 in the no-marking scene.
   - The median test had no instance. I added median 50 on the main road.
   - `st_on_way(i, h)` could not move a verdict. I added a highway 3 elsewhere that fails the
     direction test (westbound in the right-turn map, eastbound in the left-turn map).
   - The obligation's copies of the crosswalk-place and one-way-right paths were only reached by a
     compliant witness. I added `branch_5` (violated).
5. **OK**.

## Witnesses

| name | verdict | what it shows |
|---|---|---|
| forbid | violated | right turn on red from lane ordinal 2 of 2, stop line, two-directional cross street; cross car on a green approach, closest approach 1.5 s ahead at 0.95 m |
| permit | compliant | the same, with no other road user |
| idle | not_applicable | the head shows circular_green alone at the entry |
| blind | unknown | as forbid, with `st.lane_adjacency` masked; the left branch is decided false because there is no one-way roadway |
| branch_1 | not_applicable | halted 15 m short of the stop line, then rolled in; the trace starts with the car on the stretch before c, so "no halt at the place" is decided |
| branch_2 | violated | left turn from lane ordinal 1 of 1 on a one-way roadway, cross street one-way to the left; pedestrian in the crosswalk marking the cross-street lane's entrance, 2.0 s ahead at 0.52 m |
| branch_3 | compliant | approach marked by a crosswalk only, cross street one-way to the right; cross car proceeding but 6.6 s away (beyond the horizon), no contact |
| branch_4 | violated | approach with no marking, so the halt is before the intersection; cyclist already inside the intersection, 0.8 s ahead at 1.0 m |
| branch_5 | violated | as branch_3, with the conflicting cross car from forbid |

`branch_2` does not match the planned narrative's figures. A pedestrian in the crosswalk on the
cross street's approach (the far side for a left turn) cannot reach a closest approach of
1.2 s / 0.7 m at 1.3 m/s. I built a one-lane one-way approach, which is still "ordinal 1" as
planned, and the closest approach is 2.0 s / 0.52 m. The planned verdict is unchanged.

## Choices the node left open

None was declared as a narrowing (`narrowings := []`). Choices about how to write a span:

- **Entry (s9/s13), "occupied c and not i at the observation before".** There is no
  previous-observation operator. I wrote `rises(occupies i) ∧ ¬rises(occupies i ∨ occupies c)`.
  Given the rise into i, this is exactly "occupied c at the observation before".
- **s7 history bound.** The record cites the "history bound of NRS_484B_307_8a_o1", which I cannot
  see. I wrote it from this node's atoms as "the approach that ends in this entry". From the halt
  at the place up to the entry, the subject occupied c and not i at every observation; the entry
  observation itself is the rise into i (`since`).
- **s12, "ordinal 1".** I wrote this through the claimed atom's neighbour reading: no lane is c's
  left neighbour of the same direction (`st_lane_adjacency` with side `left`). Core decides that
  false for every lane exactly where c's ordinal is 1. This avoids a count literal (1) that the
  node does not declare. If the plan wants the ordinal compared with a literal, it should declare
  that literal.
- **s1, "steady red alone".** `circular_red` shown, and none of the other 22 indications of the
  enumeration shown, including `dark` and `unknown`.
- **Shared selection, rule 3c.** The selection of (i, c, s) is written once (`selection`) and
  repeated in the obligation. The obligation quantifies over every selected (i, c, s), which is
  the duty at each entry selected.

## Observations for the harness

- Witness occupancy behaves as reference-point occupancy (`Build.scene`), not footprint overlap.
  This is how the `branch_2` failure resolved. Core's TraceLint header describes footprint
  overlap after `completeOccupancy`. The scenes are now built so both readings agree.

## Why I finished

The gate returned OK on run 5 of 6.

# NRS_484B_203_1_o2 — task result

**Final verdict: OK** (13 witnesses, 15 names, composes nothing)

## Gate runs
1. `OK`: first run, with the rule and all 13 witnesses written.
2. `OK`: re-run after I added the per-span reading to the rule's header comment. This was a comment-only change.

Two runs of the 6 allowed were used. One stray `python -m harness gate --help` call was denied by permissions and did not run.

## How the rule is written
- **Class:** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability:** `¬drv_motion_complete_halt(subject, p.halt_speed_tolerance)` ∧ ∃ highway `way` occupied by the subject ∧ ∃ lane `lane` occupied by the subject with `st_lane_adjacency_count(lane) ≤ 1`. The count literal is written as `.lit (Units.ratio 1 1) .count`, because Units has no count constructor.
- **Obligation:** ∀ user `other`, ∀ highway `way`:
  - **Condition:** `other` is a vehicle (aggregate), and the subject and `other` both occupy `way`. `other` is also `rel_oncoming(subject, other, p.oncoming_heading_cos)` and meeting the subject, which means `prim_closest_approach_within(subject, other, p.meeting_horizon)` ∨ `rel_longitudinal_overlap > 0`.
  - **Then:** ∀ centre line `line` with `st_on_way(line, way)`, one of these holds:
    - `2·prim_region_lateral_offset(subject, line) ≥ kin_extent(subject, width) − 2·p.lateral_position_tolerance`
    - ∃ road edge `edge` with `st_region_geometry_distance(subject, edge) ≤ tol` and `prim_region_lateral_offset(subject, edge) < 0`.

## Choices the node left open
- **Half-width bound written doubled:** "at least half the width less tolerance" is written as 2·offset ≥ width − 2·tol. A ½ literal is not allowed, and the doubled form is mathematically the same.
- **No explicit `same(other, subject)`:** `rel_oncoming` already excludes the subject itself, because its heading cannot be opposed to its own. An explicit clause would be a leaf that does no work.
- **Lane quantifier nested under the highway quantifier:** this changes nothing, since there is no tie between the two. The record states no `st_on_way` relation between the lane and the highway, so none was added.
- **Road edge not tied to the way:** the record does not tie the road edge to the way, so any road edge counts.
- **Narrowings:** none declared beyond the record's own.

## Witnesses
| Witness | Expected | Scene |
|---|---|---|
| forbid | violated | Subject straddles the centre line by 1 m; oncoming car 2 s away; 2 m of room to its right edge |
| permit | compliant | Subject body stays right of the centre line |
| idle | not_applicable | Lanes count 2 per direction; a count-1 lane exists on another highway |
| blind | unknown | `st.region_geometry` masked |
| branch_1 | compliant | Straddling, no other vehicle |
| branch_2 | compliant | Narrow road; body crosses the line by 0.5 m with its right side at the road edge |
| branch_3 | violated | Oncoming car alongside; its velocity is unobserved, so `rel.oncoming` is supplied as measured. Exercises the longitudinal-overlap branch |
| branch_4 | violated | Subject hugs the left road edge; exercises the "on its right" test |
| branch_5 | not_applicable | Subject at rest |
| branch_6 | compliant | Same-direction car ahead, nothing oncoming |
| branch_7 | compliant | Oncoming pedestrian, not a vehicle |
| branch_8 | compliant | Oncoming car on a separate highway |
| branch_9 | not_applicable | Single-lane private road, on no highway |

## Why I finished
The gate returned `OK` and was confirmed by a second run.

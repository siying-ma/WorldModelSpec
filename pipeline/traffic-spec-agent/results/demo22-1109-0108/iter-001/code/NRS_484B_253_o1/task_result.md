# NRS_484B_253_o1 — coding session result

**Final verdict: `OK`** (11 witnesses, 12 names, composes nothing, 3 coder narrowings).

## The two files

- `library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o1.lean` — binder class, applicability,
  obligation, and three declared narrowings on `ob1`.
- `library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o1.lean` — the four planned scenes, the two
  planned branches, and five branch witnesses of my own (`branch_3` … `branch_7`).

How each span is written (the header of the rule file carries the same, per span):

- `s1` → `ru_aggregate v "DEF-NRS-484A-320::vehicle"` as the binder's class, one atom, never the
  classes it covers.
- `t1` → `existsRegion "intersection" "j" (rel_occupies v j ∧ …)`; the junction is the subject's own
  by occupancy, and the same whole selection (occupancy **and** the declared intention) is written
  again in the obligation under `forallRegion "intersection" "j"`, since the duty is owed at every
  junction so selected and a region bound in one formula is not in scope in the other.
- `c1` → `intent "int.left_turn" v j`, read at the judged observation (no future operator over it).
- `ob1` → `forallUser "u"` with the subject excluded by `same`; `u` of the aggregate; "approaching
  from the opposite direction" through the carriers (`rel_occupies`, `st_lane_enters` on a
  `travel_region`, and the normalised dot product of the two carriers' `st_lane_direction` at or
  below `−p.same_direction_cosine_tolerance`); "within the intersection" as `rel_occupies u j`;
  granting precedence as no `rel_contact` and no loss of clearance.
- `st1` → `st_region_geometry_distance u j ≤ kin_speed u × p.yield_headway_time` (a product, never a
  ratio) or the clearance lost within `p.yield_conflict_horizon`.

## Gate runs

1. **`WITNESS_FAIL`** — (a) `blind` was unknown for `absent_atom:st_lane_enters` as well as for the
   masked `st.lane_direction`: the carrier quantifier ranges over `travel_region`, which covers the
   intersection, and `st_lane_enters` is unrecorded (unknown, not false) on the junction region
   itself, so that unknown leaked into the verdict's reasons. (b) `branch_3` built the junction
   without an outline, which the adapter cannot produce ("where occupancy is observed every
   structure needs one").
   *Changed:* excluded the junction from being its own approach carrier (`¬ same cu j`,
   `¬ same cs j`), declared as narrowing 3; rebuilt `branch_3` as a van whose body and lane are
   observed but whose speed and velocity are not.
2. **`VACUOUS`** — obligation leaf 9, the headway comparison, moved no decided witness: in
   `branch_1` the clearance limb was true as well, and in `branch_2` making it true left the duty
   discharged. *Changed:* added `branch_7`, the one shape in which that limb alone decides — a
   truck waiting mid-turn, an oncoming van 2.3 m short of the junction at 2 m/s (bound 3.0 m) that
   is **not** within the junction and whose centre approach falls past the horizon (9 m at 2 m/s),
   clipping the truck's nose, so precedence is denied by contact while the headway limb alone makes
   it owed.
3. **`OK`**.

## Choices the node left open (all declared as narrowings, kind `reading`, on `ob1`)

1. **What "its closest approach" is measured by.** The record names `prim.closest_approach_within`,
   `prim.closest_approach_distance` *and* `rel.surface_gap` for one clearance. Written as: the
   centres approach within `p.yield_conflict_horizon`, and at that approach either the centre
   distance or the gap between the nearest points of the two bodies lies below
   `p.yield_min_clearance`. The `within` primitive gates both, so two bodies already drawing apart
   are not read as a failure to grant precedence (contact is read beside it on its own atom), and
   the undefined value the distance primitive carries where no approach occurs never reaches a
   verdict. `branch_6` is the witness in which the nearest-point limb alone decides and `branch_5`
   the one in which contact alone does.
2. **The subject's approach carrier is existential** — some carrier it occupies whose entrance end
   is that junction. The ontology fixes a road user's approach by occupancy and entrance topology,
   and the words single no further one out.
3. **The junction is not its own approach carrier.** `st.travel_region`, the kind the record names,
   covers the intersection, but `st.lane_enters` is the source's record of an approach segment and
   is never recorded on the junction it enters ("A carrier enters one intersection at most"), so on
   the junction region that relation is unknown rather than false. Excluding it
   removes no case the relation could decide and no vehicle the duty could reach; keeping it in only
   put a spurious unknown into every verdict (which is what run 1 showed on `blind`).

Other writing decisions that follow the record's words and are therefore not narrowings: `le` for
"at most its speed times p.yield_headway_time" and `lt` for "below p.yield_min_clearance"; the
standard's two limbs joined by `or`, as the record's obligation states; `forallRegion` over the
selected junctions, since the record requires the duty at each.

## Witnesses

| name | verdict | what it exercises |
|---|---|---|
| `forbid` | violated | van within the junction on the opposing approach, bodies touching |
| `permit` | compliant | subject alone in the scene; nothing owed precedence |
| `idle` | not applicable | the declared plan at that junction is **not** a left turn (decided false) |
| `blind` | unknown | `st.lane_direction` masked: opposition unknown, contact denies precedence, verdict unknown for that atom only |
| `branch_1` | violated | van 15 m out at 12 m/s (bound 18 m) and a 0.52 m centre approach within the horizon |
| `branch_2` | compliant | van 150 m out at 10 m/s; neither limb of the standard, duty discharged |
| `branch_3` | violated | van's speed and velocity unobserved: only "within the intersection" makes it owed |
| `branch_4` | violated | van 21.5 m out (bound 18 m), so owed by the clearance limb alone (0.02 m approach) |
| `branch_5` | violated | both at rest and touching: no centre approach within the horizon, contact alone |
| `branch_6` | violated | centres never closer than 2.55 m, bodies 0.5 m apart: the nearest-point limb |
| `branch_7` | violated | the headway limb alone makes the van owed (see run 2) |

Geometry (one map for all scenes): a 7 m × 7 m junction (region 10), the subject's northbound
approach lane (region 11) and the opposing southbound approach lane (region 12), their designated
directions exactly opposed. Occupancy is stated in every scene, since each body lies across two
regions and a reference point lies in one. Nothing Core computes is supplied: the surface gap, the
contact and the closest approach all come from the positions, headings, extents and velocities.

## Why I finished

The gate returned `OK` on run 3 of a budget of 6: every declaration matches the node, every claimed
atom, primitive and parameter is used and used as its contract states, every quantified variable is
anchored to the binder by `rel_occupies`, all eleven witnesses reach their planned verdicts (the
`unknown` one for the masked atom only), and no leaf is idle. The node needed no repair: every span
it carries could be written with the atoms it claims.

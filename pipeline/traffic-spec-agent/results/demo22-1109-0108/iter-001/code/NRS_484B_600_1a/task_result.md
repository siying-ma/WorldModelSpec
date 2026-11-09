# NRS_484B_600_1a — coding session result

## Final verdict

`OK` — `11 witnesses, 15 names, composes nothing; narrowings declared by the coder: 2`.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session finished on it |

Budget: 1 of 6 runs used. Before running the gate I read the Core files the surface did not settle:
`Language/Formula.lean` (what a quantifier's kind reads as an atom, `cond`/`aggregate` semantics,
what counts as a leaf), `Language/RuleEval.lean` and `Language/Semantics.lean` (atom arity and
argument sorts as the evaluator dispatches them), `Vocab/Primitives.lean` (concept dispatch),
`Evidence/Builders.lean`, `Evidence/TraceLint.lean`, `Runtime/Admission.lean` and
`Vocab/Ontology/Structure.lean` (what a hand-written trace is held to, and the kind refinements, so
that the highway, roadway and lane quantifiers are disjoint in the witnesses).

## The rule

- **s1 (subject)** — `clsV` is `ru_aggregate v "DEF-NRS-484A-320::vehicle"`: the aggregate id, not
  the classes the reading files under it. The applicability is
  `not drv_motion_standstill(v, p.standstill_speed_tolerance)`, the record's observable reading of
  'to drive or operate' through the vehicle's controlled motion (the plan's narrowing, not restated
  in `narrowings`).
- **s2 (obligation)** — `kin_speed v` compared with the bound s3 sets, written as `speed ≤ bound`.
- **s3 (standard)** — one operationalization, surrogate, bounding the speed at the regions the
  subject occupies: a highway region `h` it occupies; the roadway region `r` it occupies that lies
  on `h` (`st_on_way`), carrying the slope (`st_grade`) and the sight distance
  (`st_sight_distance`) of its place; the lane region `l` it occupies that lies on `h`, carrying the
  width (`st_lane_width`). The bound is the base limit less the wet decrement where `env_wet_road`
  or `env_precipitation` holds, less the winter decrement where `env_ice_or_snow` holds, less the
  per-user decrement times the count of the scene's road users whose footprint lies on `h`, less the
  grade decrement times `|st_grade r|`; and the speed times the lateral-recovery time is at most the
  lane's width, the speed times the stopping time at most the place's sight distance and at most
  `env_visibility`.

All 15 claimed names are read and all 8 named parameters are used; no literal other than the zero of
a speed and the zero of a count appears, and no value of the reading lives in the rule.

## Choices the node left open

1. **Which region carries which figure** (declared as a narrowing on s3). The record names
   `st.highway`, `st.roadway`, `st.lane`, `st.on_way`, `st.grade`, `st.sight_distance` and
   `st.lane_width` without saying which region carries the slope, the sight distance and the width.
   I read 'the subject's place' as the roadway region it occupies (slope, sight distance) and the
   'width of the highway' as the lane region it occupies (width), both tied to the highway region by
   `st_on_way`, which is also what anchors the region variables to the binder.
2. **Definite 'the highway'/'the lane' where several regions qualify** (declared as a narrowing on
   s3). The duty is required at every occupied region of each kind that lies on the way (nested
   `forallRegion` with the selection as the antecedent), the stricter of the readings the words
   allow. In every witness exactly one region of each kind is occupied, so the choice is not what
   decides any verdict.
3. **Whose footprint 'the traffic' counts** — every road user of the scene whose footprint lies on
   the highway region the subject occupies, the subject included. That is the record's wording read
   as it stands ("each road user of the scene whose footprint overlaps the st.highway region v
   occupies"), so it is not declared as a narrowing; it matters only as a constant 0.5 m/s of the
   bound, and it is noted here because the convention could also have been read as 'the other road
   users'.
4. **Ratios written as products** — the convention divides the lane width, the sight distance and
   the visibility distance by a time. `Term.div`'s contract refuses a measured atom in a divisor and
   a zero divisor is unknown, so each bound is written as `speed × time ≤ distance`, which decides
   the same sense for a positive time. This is a form of writing, not a change of the reading, so it
   is recorded in the rule's header rather than as a narrowing.

## The witnesses

One straight east–west map in every witness: a highway region 20 m wide, its roadway 14 m wide
carrying the slope and the sight distance, and the eastbound lane whose polygon is as wide as the
width it records; `forbid` adds the opposing lane so its stretch is the narrative's two-lane
highway. Occupancy is derived from the geometry and every body lies wholly inside its lane, so
position-in-polygon and footprint overlap agree. Each trace is three unchanged instants a second
apart; no formula looks back, so no witness names a window and none declares a boundary.

Beyond the four planned witnesses and the node's two branches I added five, so that every leaf and
every limb of the bound decides a witness of its own:

| witness | verdict | the leaf it moves |
|---|---|---|
| `forbid` | violated | the lowered limit (wet surface, five users on the way) and the sight bound |
| `permit` | compliant | every bound kept, no decrement selected |
| `idle` | not applicable | the applicability: 0.05 m/s is inside the standstill tolerance |
| `blind` | unknown | `env.visibility` masked; every other bound kept by a margin |
| `branch_1` | violated | the lane-width bound (2.5 m lane at 25 m/s) |
| `branch_2` | violated | the grade decrement (8% downgrade at 27 m/s) |
| `branch_3` | violated | the precipitation limb of the wet decrement (27.5 m/s) |
| `branch_4` | violated | the winter-surface decrement (22 m/s on ice) |
| `branch_5` | violated | the traffic decrement alone (seven users on the way at 27 m/s) |
| `branch_6` | violated | the visibility bound alone (50 m of visibility at 25 m/s) |
| `branch_7` | violated | the sight-distance bound alone (50 m of sight at 25 m/s) |

The region-selection leaves (`rel_occupies` of the highway, the roadway and the lane, and the two
`st_on_way` relations) are moved by `forbid` and `branch_1`: blanking any of them makes the nested
implication vacuous and turns a violated witness compliant.

## Why I finished

The gate returned `OK` on the first run: the rule builds, checks, says what the node's elements and
its one operationalization say with only the names the node claims, and the eleven witnesses reach
the verdicts they declare, with every leaf exercised by a decided witness. Nothing in the node was
wrong, so no defect is reported and no `dependency_defect.json` is written.

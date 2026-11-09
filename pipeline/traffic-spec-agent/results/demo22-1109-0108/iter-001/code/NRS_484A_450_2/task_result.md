# NRS_484A_450_2 — coding session result

## Final verdict

`OK` — `11 witnesses, 18 names, composes nothing; narrowings declared by the coder: 3`.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session finished on it (budget 6, one used) |

Before the single run I read, from Core only, the files that decided the writing:
`Language/RuleEval.lean` (the static check), `Language/Semantics.lean` (three-valued evaluation,
quantifier ranges, `ru_aggregate`), `Foundations/Temporal.lean` (`sinceAll`, `risesAll`,
truncation), `Foundations/Unknown.lean` (`R.all []`/`R.any []` on an empty quantifier range),
`Vocab/Atoms.lean` (`st_entrance_of`, `st_lane_enters`, `st_sight_along_way`, `rel_occupies`,
`st_region_geometry_distance`), `Language/Rule.lean` (`Narrowing`, `verdictAt`) and
`Evidence/Builders.lean` (the builders and `Scenario.run`).

## How the node is written

- **s1** → `clsV = ru_aggregate(v, "DEF-NRS-484A-320::vehicle")`, the aggregate id itself.
- **s2** → `approachCarrier`: `st_travel_region(L) ∧ rel_occupies(v, L) ∧ st_lane_enters(L, X) ∧
  ∃ stop sign d: dev_stop_sign(d) ∧ dev_governs(d, L)`, with `X` bound by an `intersection`
  quantifier and `st_intersection(X)` read on it.
- **s5** → `entersNow = .rises (rel_occupies v X)`; the applicability holds at the entry
  observation only, so the duty is judged once per entry.
- **s3** → `dutyThroughCarrier`: the crossing that marks the carrier's entrance, else (where no
  crosswalk marks it) the stop line that marks it, else the view point; each place's duty is
  `haltSearch = .since (.not bound) halt`, the record's history bound, whose boundaries are
  `zoneOutsideMark` (the start of the approach) and `inJunctionBefore` (the previous entry). The
  place is `atMark`: off the mark and the junction (`rel_occupies`), the mark ahead along the
  carrier's designated direction (`prim.region_offset_along` with `st_lane_direction`), the body
  within `p.stop_point_tolerance` (`st_region_geometry`). The act is
  `drv.motion.standstill(p.standstill_speed_tolerance)`.
- **s4** → the operationalization bounds the third place only:
  `st_sight_along_way(v, W) ≥ p.intersecting_way_view_distance` for a highway `W` the junction
  lies on and the carrier does not (`st_highway`, `st_on_way`), and every other road user on `W`
  visible from the vehicle (`rel_visible`).

The recording's start is no boundary of the search: a search that reaches it is unknown, which is
what the history-boundary witness shows; `since` is in `Scenario.pastOps`, so that witness's
unknown is the truncation its `boundary` names and nothing else.

## Choices the node left open (declared as narrowings, all on s3)

1. **The view point's stopping zone.** The record gives a stopping zone for a *mark* (off it,
   short of it, farther than `p.stop_point_tolerance`) and gives the third place without one. I
   read the view point's zone as the stretch of the carrier, outside the junction, on which the
   view of s4 is met: the search ends at the last observation on the carrier at which the view was
   not met.
2. **`st.lane_direction` read on its own.** The record claims it beside the primitive for the side
   of the mark without saying what the rule states with it. I read it as the carrier carrying a
   designated direction at the observation judged (`carrierDirected`: the magnitude of the
   normalised direction above zero — true where the source records one, unknown where it does
   not), the place being read only where the side can be read along it.
3. **The carrier quantification.** “the carrier the vehicle approaches through” is written as
   *every* carrier the vehicle occupies that enters the junction entered and that the sign
   governs (`forallRegion` with the record's whole selection as the guard), because
   `st.lane_enters` directs that a rule never picks the carrier that favours the road user. With
   one such carrier — the ordinary case, and every witness here — the readings agree.

Two further writing decisions are the record's own reading, not mine, so they are not declared:
“approaching traffic” as the road users on that way (the operationalization's convention states
it), and the previous-entry boundary as the first observation after any at which the vehicle
occupied that junction (the record's “at the previous entry … a halt made before the previous
entry discharged that entry”; placing it one observation after the entry is what makes a halt at
or before that entry unavailable to this one, and no halt can be made at an observation inside the
junction anyway).

## Witnesses

The five planned ones, plus six `branch_*` witnesses for the leaves the plan's scenes never reach:

| witness | verdict | what it exercises |
|---|---|---|
| `forbid` | violated | the crossing branch: an observation inside the stopping zone at 4 m/s, then entry |
| `permit` | compliant | a halt 0.5 m short of the crossing, off it and off the junction |
| `idle` | not_applicable | a pedal cycle: the aggregate decided false |
| `blind` | unknown | the forbid trace with `kin.speed` absent; the zone observation is the one the speed decides |
| `history_boundary` | unknown | the recording begins over the stop line, inside the zone; the search reaches neither boundary |
| `branch_1` | compliant | the stop-line branch (no crosswalk marks the lane) |
| `branch_2` | violated | the view branch: the zone begins where the view opens (40 m → 120 m), no halt |
| `branch_3` | compliant | the view branch: a halt where the view is met and the cross traffic is visible |
| `branch_4` | violated | the view branch: the sight distance is met but the cross vehicle is occluded (`rel_visible` false) |
| `branch_5` | violated | two entries: the halt before the first does not discharge the second (`inJunctionBefore`) |
| `branch_6` | not_applicable | the stop sign governs the northbound approach, not the carrier the car occupies |

Occupancy is stated in every scene (a body overlaps several regions while its reference point lies
in one polygon); every other fact is built from the geometry, and `rel_visible` — which Core never
computes — is the only supplied relation.

## Why I finished

The gate returned `OK` on the first run: the rule states every span the node carries with the
names it claims and no others, the three readings the node left open are declared as narrowings,
and the eleven witnesses reach the planned verdicts with the planned unknown reasons (a masked
atom for `blind`, a truncated `since` for `history_boundary`). Nothing in the node looked wrong to
me, so there is nothing for the plan agent to change.

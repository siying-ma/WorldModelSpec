# NRS_484B_257_1_o1 — coding session result

**Final verdict: `OK`** (13 witnesses, 24 names, composes nothing, 3 coder narrowings).

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `WITNESS_FAIL` — `branch_8: expected violated, got compliant` | `branch_8`'s last observation put the car's reference point exactly on the approach lane's far boundary (y = −1 m, the lane's edge), so `rel.occupies` on the carrier was not decided true there and the duty was vacuous at the entry. Moved that observation to y = −1.5 m, inside both the lane and the junction. Nothing in the rule changed. |
| 2 | `OK` | — |

Budget used: 2 of 6 runs.

## How the node is written

- **s1** → the binder's class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`.
- **c1** → `properSignGoverns`: a `stop_sign` or `yield_sign` device whose `dev.governs` falls on the
  carrier the subject occupies. The carrier is `approachSelected`: `rel.occupies` on a
  `travel_region` whose `st.lane_enters` is the quantified `intersection`, and not that
  intersection itself (`same`).
- **e1** → `trafficControlled`, negated in the applicability: the subject is a member of
  `DEF-NRS-484A-285::traffic`, and a `human_direction` device in the role `police_officer` with a
  direction given, or a `traffic_signal`, governs the junction or the approach carrier.
- **ob1** → judged at `drv.motion.region_entry (v, j)`; the act is found by
  `count actedAtPlace (¬(approachStarted ∨ entersIntersection)) ≥ 1`, so the search runs back from
  the entry to the start of that approach or to a previous entry into the same junction, and a
  search that reaches neither end (the history begins before the recording) is unknown. The act is
  the halt (`drv.motion.standstill` at `p.standstill_speed_tolerance`) or, under a yield sign,
  `kin.speed ≤ p.yield_sign_slowed_max_speed`, with the footprint not yet in the junction, at the
  place read in the words' order (stop line marking the carrier → crosswalk marking it → the view
  point), the mark tested by `st.region_geometry` distance ≤ `p.stop_point_tolerance` and
  `prim.region_offset_along ≥ 0`.

## Choices the node left open (all declared as narrowings on `ob1`)

1. **The third place.** No region of a scene is "the point nearest the intersection where the
   driver has a view". It is written as an observation at which the subject, on the approach
   carrier and not yet in the junction, has `st.sight_along_way` on the crossing way at or above
   `p.intersecting_way_view_distance`; "nearest the intersection" is not read as a spatial minimum.
   The start of the approach for that place is read as the last observation on the carrier at which
   that sight still fell short of the distance (the record defines the start of the approach through
   a mark, and that place has none).
2. **The through highway.** Read as a highway region the junction lies on (`st.on_way`) that the
   subject's own approach carrier does not lie on. `dev.governs` records the carrier a sign governs
   and no atom places a sign at a way's entrance, so the crossing way is identified by the junction
   and the carrier rather than by the sign's position on it.
3. **The search.** `count` reads the act at its onset (rising edges since the start of the search's
   latest run), so an act that already held at the first observation after the end of the search is
   not counted. This is the only way the language expresses a search that ends exactly where the
   record says while still terminating at a previous entry into the same junction: `since` would
   have to read the search's end at the judged observation, where the entry itself holds, and would
   decide the duty on that observation alone.

Two further choices, both inside the record's words and not narrowings of the duty:

- `carrierDirected` (the carrier's `st.lane_direction` is observed and non-zero) is a conjunct of
  the obligation's selection, not of the applicability, so that an unobserved designated direction
  leaves the **duty** unknown, as the record's obligation requires, rather than the engagement.
- `.not (.same l j)` in the selection: an intersection is itself a travel region, and without this
  the quantifier would offer the junction as its own approach carrier, for which `st.lane_enters`
  is never observed. It states no fact about the world (`same` compares two bound variables) and
  adds no atom.

## Witnesses

Beyond the node's `forbid`, `permit`, `idle`, `blind`, `branch_1`, `branch_2` and
`history_boundary`, the adequacy rule needed six more, each a one-line narrative in the file:
`branch_3` (the view point, complied with), `branch_4` (the officer governs the lane, not the
junction), `branch_5` and `branch_6` (a signal governing the junction, and one governing the lane),
`branch_7` (the crosswalk place, complied with) and `branch_8` (a yield sign crossed at 8 m/s —
violated; it is what exercises the yield limb of the obligation's own selection).

All thirteen traces share one map, and each begins with the car clear of the approach lane (the
rule is not engaged at the first observation, where a look back from the trace's start could say
nothing) and ends at the observation whose entry into the junction is the same instant whether
occupancy is read from the reference point or from the footprint.

## Why I finished

The gate returned `OK`: the rule builds and checks, every claimed name is used and no other is
read, every leaf of the applicability and the obligation moves a decided witness, and all thirteen
witnesses reach their planned verdicts — the `blind` one unknown for the masked `dev.governs`
alone, and `history_boundary` unknown only for the search truncated at the start of its recording.
The node is sound as written; I found nothing in it for the plan agent to change.

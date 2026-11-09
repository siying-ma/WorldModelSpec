# NRS_484B_407 — coding session

**Final verdict: `OK`** (`13 witnesses, 10 names, composes nothing`), on gate run 3 of a budget of 6.

## Files

- `library/TrafficSpec/Rules/NRS_484B/NRS_484B_407.lean` — `clsV`, `applicability`, `obligation`
  and the named sub-formulas they are built from; declarations the node fixes (`laws`, `binders`,
  `assumptions`, `intentions`, `operationalizations`, `residues`, `surrogate`) left as the harness
  wrote them. `narrowings := []`.
- `library/TrafficSpecWitness/NRS_484B/NRS_484B_407.lean` — the ten planned scenarios plus three
  `branch_*` scenarios, all built from `Build.*`.

## The rule, span by span

- **s1** — `ru_aggregate` of the binder with the claimed aggregate id as its literal argument.
- **s2** — the one call the element names, `drv_motion_u_turn`, with the three parameters of its
  signature in order (heading step, onset yaw rate, reversal angle). The record declares
  `boundary: "event"` and a recognition "where the concept rises", so the obligation is
  `.not (.rises uTurnReversal)`: the duty is broken at the recognition observation and at no later
  observation of the same manoeuvre.
- **s3 / s4 / s5** — one region quantifier over `roadway` per element, each anchored to the binder
  by `rel_occupies` and naming `st_roadway` as the record maps it; then the curvature at or above
  `p.curvature_resolution` (s3), a `crest` region whose ground distance from the body
  (`st_region_geometry_distance`) is at most `p.crest_approach_distance` (s4), and the place's
  `st_sight_distance` below the text's own 500 feet (s5). "or" joins s3 and s4; "where" joins s5 to
  them: `conditions = (s3 ∨ s4) ∧ s5`, so one and the same observation carries the place and the
  sight.
- **the occasion** — `onset` is the record's onset element (`.rises` of
  `|kin_yaw_rate| > p.turn_onset_yaw_rate`), `underWay` its under-way element in its own terms
  (that magnitude above the onset rate, and the heading change accumulated since the onset still
  below the reversal angle, with the reviewed step bound of the acquisition profile). The
  applicability is `.since (.not onset) (underWay ∧ conditions)`: the conditions held together at
  some observation of the stretch from the observed onset of this manoeuvre to the observation being
  judged. `.not onset` as the left operand of `since` ends the search exactly at that onset, which
  is what makes the four `occasion_*_outside` witnesses not applicable.

## Choices the node left open

1. **One quantifier per condition span, not one shared region.** Each of s3, s4, s5 claims its own
   `rel.occupies` and `st.roadway`, so each is written with its own `roadway` quantifier. A single
   shared region variable would have been narrower than the words (it would require one roadway to
   carry the curvature, the crest and the sight distance), and these are condition spans, which are
   never narrowed. No narrowing is declared.
2. **The crest distance is the body-to-region distance of `st.region_geometry`.** The record's s4
   justification names exactly this reading, so it is the plan's and is not restated as a narrowing.
3. **`.since (.not onset) …` for `some_moment` over an event act.** The record gives the onset
   element and the recognition point but no window parameter; `since` with the onset as its right
   operand is the only operator that bounds the search at the declared onset of the occurrence being
   judged. Before any observed onset the rule is unknown (the recording cannot say whether a
   manoeuvre was already under way), which is why every witness names its window from the onset
   observation on — the plan declares no history boundary, and no witness is unknown for a
   truncation.
4. **Witness kinematics.** Figures are the witness's own: 4 m/s, a sweep of 2.794362050° per 50 ms
   observation (the exact rational rotation cos 840/841, sin 41/841, which is what the recorded
   55.887241 deg/s turns over one interval), a turning radius of about 4.1 m, bends of 50 m radius
   (curvature twenty times the resolution), sight distances of 60 m and 400 m against the text's
   152.4 m, crest distances of about 138 m and 155 m against the 150 m of the reading.
5. **`occasion_s4`'s narrative is met in part, and the file says so.** A 150° sweep displaces a body
   by about twice its turning radius — some 4 m here — so no physically consistent trace can show a
   crest passing out of a 150 m approach distance *within* the manoeuvre. In `occasion_s4` the crest
   stands within the approach distance at the onset and at every later observation of the act (by
   11 m or more), which is what makes the witness violated through the s4 limb;
   `occasion_s4_outside` is the witness that shows the span held only outside the act, its straight
   run before the onset carrying the body from 5 m within the approach distance to 5 m beyond it.
   This is recorded in the witness file's header.
6. **Three added `branch_*` witnesses**, so that every leaf is decided and pivotal in some witness:
   `branch_1` a pedal cycle (outside the aggregate) reversing on the blind bend; `branch_2` the
   subject turning around on the footway, occupying the way and no roadway; `branch_3` a straight
   stretch with short sight distance and a crest region 400 m away, far beyond the approach
   distance.

## Gate runs

1. **`WITNESS_FAIL`** — every trace rejected: "track 1 keeps the heading it had at t=100, but its
   yaw rate turns it 3° over the interval". My first witnesses stepped the heading through a few
   exact rational unit vectors while the yaw rate turned it 3° per observation. *Changed:* the
   source was made to record no heading vector at all (position, speed, path length, extent and yaw
   rate only), since the rule reads no heading and Core reads the crest distance from the reference
   point where no footprint is observed.
2. **`WITNESS_FAIL`** — "track 1 is in occupancy_observed but lacks a position, a non-zero heading
   or an extent, so its footprint is undefined": a heading is required of an observed body.
   *Changed:* the witnesses were rebuilt around an exact rational rotation — cos 840/841,
   sin 41/841 — with the recorded yaw rate defined as that rotation's angle over the 50 ms interval,
   the place advancing 0.2 m along the heading each interval (so the path is the arc of that rate),
   and each heading component recorded to the nanometre so the iterated rotation stays a measured
   figure. The geometries were re-laid for the shorter displacement of a real sweep: the
   bend-to-tangent change of `occasion_s3`/`occasion_s5` is now the two halves of a divided highway
   that the sweep carries the body across, the `*_outside` pair keeps the stretch boundary on the
   straight run before the onset, and the crest witnesses are as described in choice 5.
3. **`OK`**.

## Why I finished

The gate returned `OK` on the two files with the thirteen witnesses built, the formulas using every
claimed name and no other, and the record's declarations untouched. Nothing in the node is wrong:
every span it carries is written with the atoms it claims, so there is no `no_atom`, `no_operator`
or mapping defect to report, and no concept computed anything its contract excludes (no
`dependency_defect.json`).

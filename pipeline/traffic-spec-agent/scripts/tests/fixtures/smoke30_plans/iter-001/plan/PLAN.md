# Plan — batch 01 (iteration 1)
## Nodes
## Concept records
## For the operator

- **Roundabout reference point.** `drv.motion.clockwise_about_region` treats the `st.region_geometry`
  reference point of a `st.roundabout` as the island centre. Adapters should place it there.
- **Map frame orientation.** The concept also assumes the world frame is the ontology's
  counterclockwise-positive frame (the frame in which `kin.yaw_rate` counts a left turn as
  positive). A left-handed simulator frame must be converted by the adapter, or every verdict flips.
- **Caravan assumption is per trace.** `asm.caravan_or_motorcade` declares that the vehicles
  travelling in line in one lane form a caravan. A trace that mixes caravan and ordinary traffic
  cannot be declared correctly; a per-road-user fact would need an ontology change.
- **Intentions on CARLA.** `int.turn_right` must be supplied by the source for NRS_484B_223_4a.
  Where the `carla_scene_graph` profile carries no planner intentions, that rule reports unknown.
- **Turn recognition window.** `p.turn_recognition_window` is proposed long enough for a three-point
  turn. On long sweeping ramps, a heading change of that size inside the window would be recognized
  as a turn; the values are awaiting review.
- **Capital-C "City".** "City" in LVMC 11.38.030 was resolved by the table to the NRS definition
  ("any incorporated city"). If an LVMC definition of "City" (the City of Las Vegas) is posted,
  the assumption's meaning should narrow.

<!-- batch-02 -->
# Plan — batch 02 (iteration 001)
## Conventions shared by the yield nodes
## Nodes
## Concept records
## Parameters proposed
## For the operator

- **270-3 / 270-4 assumptions.** Exceptions (b), (d) and (f) of NRS 484B.270(3) are carried by trace assumptions. On a trace that does not declare them false, every bicycle-lane occupancy under NRS_484B_270_3_o2, and every intersection entry from the lane under NRS_484B_270_4, is `unknown`. An atom for a disabled vehicle, or a source convention that declares these facts, would make them decidable.
- **297-6 assumptions.** The missing or impassable sidewalk section, and the impassable area beside the bicycle lane, have no atom and are carried by assumptions. If the ontology gains an atom for sidewalk passability, these spans should move onto it.
- **Ramp vs mainline.** `st.controlled_access` covers the highway together with its entrance and exit lanes, so a source cannot tell a ramp from the mainline. NRS 484B.263 is therefore judged at entry into, or exit from, the whole controlled-access region.
- **Centre-distance clearance.** `p.conflict_centre_clearance` is a distance between centres, so one value has to serve car–car, car–bicycle and car–pedestrian pairs. Its proposed value should be reviewed against the labelled conflicts.

<!-- batch-03 -->
# Plan — batch 03 (iteration 1)
## Nodes
## Same words, different atoms
## For the operator

- **`ru.trimobile` gap (NRS-484B-307-9b).** No definition applies to "trimobile". `ru.motorcycle` covers three-wheelers ridden astride but not seated ones. If the coding session confirms the gap, all four 9b nodes are blocked, and 9a's exception composition with them is blocked too.
- **Same-batch composition.** 9a composes the 9b nodes planned in this same batch. If unpublished same-iteration nodes cannot be composed, 9a waits on 9b's publication.
- **Re-proposed parameters.** Every parameter catalogued only as "proposed this iteration" had to be re-proposed in each node that uses it. I copied the earlier batch's values and units unchanged. The conventions and sources are paraphrased, because the table shows them truncated.
- **Arrow-cycle counting (9b_o2).** A cycle the wait begins inside is not counted. This needs operator review against labels.

<!-- batch-04 -->
# Plan — batch 04
## Concept `drv.motion.stopping_distance` (quantity)
## NRS_484B_560_7a
## NRS_484B_600_1a
## NRS_484B_769
## NRS_484D_100_1
## NRS_484D_215_1_o1 and NRS_484D_215_1_o2
## For the operator

- **Two definition texts were missing from the prompt.** The bracketed sources DEF-NRS-484B-420 (cited by NRS-484B-769) and DEF-NRS-484D-210-1-2 (cited by NRS-484D-215-1) were not among the injected definition texts. The `definition` references quote "extended horizontally" and "lowermost distribution of light". These are the phrases those sections use as I know them, and the validator accepted them, but please check them against the corpus text.
- **Gap `dev.lamp_use_sign`** (NRS-484D-100-1, clause (c)). This blocks that law, and therefore both NRS-484D-215-1 nodes, which compose it, until it is decided.
- **Earlier-batch parameters re-proposed.** The validator's catalogue did not yet contain the parameters proposed by earlier batches: `p.motion_speed_tolerance`, `p.queue_standstill_gap`, `p.conflict_time_horizon`, `p.conflict_centre_clearance`. They are proposed again here with the same values and units.
- **New parameters awaiting review:**
  - `p.perception_reaction_time`
  - `p.surface_friction_accel_dry`, `_wet`, `_ice_or_snow`
  - `p.following_min_time_headway`
  - `p.lane_keeping_margin_per_speed`
  - `p.low_beam_seeing_distance`
  - `p.oncoming_cos_tolerance`

  The low-beam seeing distance and the reaction time decide how often low beams on lit urban streets are flagged by NRS_484D_215_1_o1.
- **"Stopping" in NRS-484B-560-7a.** Its definition is DEF-NRS-484A-260. It reuses `drv.motion.stopped`, whose contract quotes DEF-NRS-484A-255; the halt is the same physical notion, and 260's exceptions are carried by the rule. If the operator wants one concept per definition, a qualified record would be needed.

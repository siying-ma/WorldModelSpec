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

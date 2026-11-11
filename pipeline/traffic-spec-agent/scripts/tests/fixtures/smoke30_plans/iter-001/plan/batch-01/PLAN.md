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

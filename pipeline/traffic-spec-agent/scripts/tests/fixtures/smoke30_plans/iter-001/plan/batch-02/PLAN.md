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

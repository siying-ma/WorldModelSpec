# Observable readings and identity-class carriers (as of iteration 2)

Rebuilt in full from the latest record of each node of the run each time it is written. A report: nothing here files a gap, returns a record, holds a law or grants a change.

## (a) Every observable reading, with the ids that carry its span

- `LVMC_11_30_030` span s3 "to permit a pedestrian to cross the roadway" · `purpose` · carried by `ru.aggregate=DEF-NRS-484A-165::pedestrian`, `drv.position.near_region` · from `iter-001/plan/blueprint.jsonl`
- `LVMC_11_30_030` span s4 "the driver of any other vehicle approaching from the rear" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle`, `drv.position.behind` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_113_3` span s1 "The driver of a vehicle:" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_117_1` span s3 "shall not drive upon or within any sidewalk area" · `agency` · carried by `st.sidewalk`, `rel.occupies`, `drv.motion.at_rest` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o1` span d2 "driven upon a divided highway" · `agency` · carried by `st.highway`, `st.median_or_divider`, `st.on_way`, `st.roadway`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o1` span d8 "or at a crossover or intersection established by a public authority." · `status` · carried by `st.median_or_divider`, `st.intersection`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o2` span d2 "driven upon a divided highway" · `agency` · carried by `st.highway`, `st.median_or_divider`, `st.on_way`, `st.roadway`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o2` span d8 "or at a crossover or intersection established by a public authority." · `status` · carried by `st.median_or_divider`, `st.intersection`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o3` span d2 "driven upon a divided highway" · `agency` · carried by `st.highway`, `st.median_or_divider`, `st.on_way`, `st.roadway`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_227_1_o3` span d8 "or at a crossover or intersection established by a public authority." · `status` · carried by `st.median_or_divider`, `st.intersection`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_250_1` span e1 "The driver of a vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_250_1` span e7 "this section does not apply at intersections controlled by official traffic-control devices" · `status` · carried by `dev.traffic_signal`, `dev.stop_sign`, `dev.yield_sign`, `dev.governs`, `st.intersection`, `st.lane_enters`, `st.travel_region` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_250_4_o1` span a4 "the driver of the vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_250_4_o1` span a6 "at a clearly marked stop line" · `status` · carried by `st.stop_line`, `st.entrance_of`, `st.region_geometry`, `st.lane_direction`, `prim.region_offset_along` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_250_4_o1` span a8 "or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway." · `perception` · carried by `st.intersection`, `st.region_geometry`, `rel.occupies`, `st.lane_enters` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_250_4_o2` span a4 "the driver of the vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_253_o1` span f1 "The driver of a vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_253_o2` span f13 "and the drivers of all other vehicles approaching the intersection from the opposite direction" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle`, `st.lane_enters`, `st.lane_direction`, `st.travel_region`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_257_1_o1` span g3 "the driver of a vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_257_1_o1` span g2 "When proper signs have been erected," · `status` · carried by `dev.stop_sign`, `dev.yield_sign`, `dev.governs`, `st.lane_enters`, `st.travel_region`, `st.intersection` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_257_1_o1` span g5 "at a clearly marked stop line" · `status` · carried by `st.stop_line`, `st.entrance_of`, `st.region_geometry`, `st.lane_direction`, `prim.region_offset_along` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_257_1_o1` span g7 "or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway." · `perception` · carried by `st.intersection`, `st.region_geometry`, `rel.occupies`, `st.lane_enters` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_257_1_o2` span g3 "the driver of a vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_257_1_o2` span g2 "When proper signs have been erected," · `status` · carried by `dev.stop_sign`, `dev.yield_sign`, `dev.governs`, `st.lane_enters`, `st.travel_region`, `st.intersection` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_280_1a` span p1 "A driver of a motor vehicle" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-130::motor_vehicle` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_297_6_o1` span s8 "to move around such an obstruction." · `purpose` · carried by `rel.occupies`, `st.sidewalk`, `st.obstruction`, `drv.position.near_region` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_297_6_o2` span s8 "to move around such an obstruction." · `purpose` · carried by `rel.occupies`, `st.sidewalk`, `st.obstruction`, `drv.position.near_region` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_297_6_o3` span s8 "to move around such an obstruction." · `purpose` · carried by `rel.occupies`, `st.sidewalk`, `st.obstruction`, `drv.position.near_region` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_307_9b_o1` span b2 "A person driving a motorcycle, moped" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-135::motorcycle`, `ru.aggregate=DEF-NRS-484A-125::moped` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_307_9b_o2` span b2 "A person driving a motorcycle, moped" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-135::motorcycle`, `ru.aggregate=DEF-NRS-484A-125::moped` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_307_9b_o2` span c2 "(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change" · `status` · carried by `dev.traffic_signal`, `dev.governs`, `rel.occupies`, `st.intersection`, `st.lane_enters`, `drv.motion.at_rest` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_307_9b_o4` span b2 "A person driving a motorcycle, moped" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-135::motorcycle`, `ru.aggregate=DEF-NRS-484A-125::moped` · from `iter-001/plan/blueprint.jsonl` — carried by identity classes only
- `NRS_484B_440_1_o1` span e3 "no person shall stop, park or leave standing" · `agency` · carried by `rel.ahead_behind_in_lane`, `rel.surface_gap`, `dev.traffic_signal`, `dev.stop_sign`, `dev.human_direction`, `dev.governs`, `drv.motion.at_rest` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_600_1a` span u1 "It is unlawful for any person to drive or operate" · `agency` · carried by `kin.speed` · from `iter-001/plan/blueprint.jsonl`

## (b) Readings whose span identity classes carry together with ids of another family (whether those ids are the conduct or the feature the words refer to is for the operator to check)

- `LVMC_11_30_030` span s3 "to permit a pedestrian to cross the roadway" · `purpose` · carried by `ru.aggregate=DEF-NRS-484A-165::pedestrian`, `drv.position.near_region` · from `iter-001/plan/blueprint.jsonl`
- `LVMC_11_30_030` span s4 "the driver of any other vehicle approaching from the rear" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle`, `drv.position.behind` · from `iter-001/plan/blueprint.jsonl`
- `NRS_484B_253_o2` span f13 "and the drivers of all other vehicles approaching the intersection from the opposite direction" · `agency` · carried by `ru.aggregate=DEF-NRS-484A-320::vehicle`, `st.lane_enters`, `st.lane_direction`, `st.travel_region`, `rel.occupies` · from `iter-001/plan/blueprint.jsonl`

## (c) Records with no observable reading whose span names a duty, a role or a status and is carried by identity classes only

(none)

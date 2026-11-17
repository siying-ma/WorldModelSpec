# Plan — batch 03 (iteration 001)

No law-local aggregates: `aggregates.jsonl` is empty. Every road-user term is either an admitted aggregate from the definitions table or, where no definition applies ("motor scooter"), mapped to its class atom. Three concept records are proposed: `drv.motion.left_turn`, `drv.motion.right_turn`, `drv.motion.u_turn`. The U-turn record is born from DEF-NRS-484B-077. Proposed concepts from earlier batches are reused by id: `drv.motion.complete_halt` and `drv.motion.moving_across_carrier`. The validator accepts every node and concept. Three nodes carry gaps and will not be coded.

## LVMC_11_30_070_B — crossing only within a crosswalk in a business district
- **Mapping.** The words "No pedestrian" and "shall cross a roadway" reuse the mappings of LVMC_11_30_050: the pedestrian aggregate, `drv.motion.moving_across_carrier` on a lane or roadway the pedestrian occupies, and occupancy of a `st.roadway`.
- **Exception.** The marked or unmarked crosswalk is `st.crosswalk`, with both values of its `marked` attribute, plus `rel.occupies`.
- **Business district.** This is a legal region class, carried by the new assumption `asm.business_district`. The catalogued `asm.business_or_residence_district` means something wider, so it is not reused.
- **Scope.** Standing on the roadway or walking along it is not a crossing. LVMC_11_30_090 judges walking along the roadway.
- **Reversal signal:** a label that treats walking along the roadway outside a crosswalk as "crossing".

## LVMC_11_30_090 — no walking along the roadway where sidewalks exist
- **Sidewalks provided.** "Where sidewalks are provided" is a `st.sidewalk` lying on the same `st.highway` as the occupied roadway (`st.on_way`). "adjacent" is read through that same relation.
- **Walk along.** This means moving (not `drv.motion.complete_halt`) and *not* `drv.motion.moving_across_carrier`. It uses the same tolerance `p.crossing_motion_cos` that separates crossing from walking along in LVMC_11_30_050, so the two pedestrian rules split the pedestrian's motion between them consistently.
- **Reversal signal:**
  - a map whose highway regions are long enough that a sidewalk far away makes the duty apply. The fix would then be a distance-bounded adjacency, which needs an atom relating two regions.
  - a reviewer ruling that "along" needs its own concept.

## LVMC_11_30_140_B_o1 / _o2 — blind persons
There are two obligations, so there are two nodes:
- **o1:** "immediately come to a full stop". "immediately" is a standard, bounded by `p.immediate_stop_window`. Not a surrogate.
- **o2:** "take such precautions before proceeding as may be necessary…". This is a **surrogate**: the standard is the duty. It is bounded by contact and closest approach (`p.conflict_horizon`, `p.conflict_centre_clearance`), reusing the yield conventions of LVMC_11_12_070_B.

**Which definition of "stop" applies.** "stop" is ambiguous in the table between two definitions that each state their own scope. Here a stop is *required*, so DEF-NRS-484A-255 ("when required") governs by its own words. `drv.motion.complete_halt` quotes that definition.

**Readings, disclosed here because the validator rejects narrowings on subject and trigger spans:**
- **(a) The protected person.** The person "wholly or partially blind, carrying a cane … or being assisted by a person" is `ru.pedestrian_with_white_cane_or_guide_animal`. That class contract restates these words.
- **(b) The subject's own blindness.** "not wholly or partially blind" is read as the subject *not* being of that class. A blind pedestrian with no cane and no guide is therefore bound. **Reversal signal:** a reviewer rejecting (b). The span then becomes an atom gap for visual impairment, which would block the law.
- **(c) "approaches".** This is the moving subject's centre distance first falling to `p.blind_person_approach_reach`, or the start of contact. The trigger is that *first* reaching, so a subject that halts and then moves on within the reach does not approach again. Without this, o1 and o2 would contradict each other.
- **(d) "with wisdom".** This qualifies the helper, not the protected person. It is a residue of scope none.
- **(e) "before proceeding" (o2).** This refers to o1's stop. It keeps its subject, its object (the same person), its event and its order: a halt after the event, then motion after the halt. It is carried by `drv.motion.complete_halt`, not by composing o1, because the words require the stop itself and not compliance with a rule.

**Reversal signal:** a label that counts a vehicle passing a white-cane pedestrian well outside the reach as an approach. That would change the reach value, not the structure.

## LVMC_11_38_030 — no motorcycles or motor scooters on sidewalks
- **Classes.** "motorcycle" is the admitted aggregate. "motor scooter" has no definition. Large scooters are already motorcycles under the NRS definition, and small ones are mopeds, which that definition excludes. So "motor scooter" maps to `ru.moped`. The stand-up electric scooter is excluded because the code defines it separately and regulates it in chapter 11.40.
- **Duty.** "be ridden" means not `drv.motion.complete_halt`, read as an agency observation. "of the City" reuses `asm.within_city_limits`.
- **Reversal signal:** an LVMC definition of "motor scooter" that includes electric scooters. Then add `ru.electric_scooter`.

## LVMC_11_38_120_B_o1 — lamp equipment (gap)
- **Why a gap.** "shall carry at least one lighted headlamp capable of … and one tail lamp mounted on the rear …" is an equipment duty. `sig.headlamp` and `sig.position_lamp` only say whether a lamp is lit at an observation.
- **Gap filed:** atom `ru.lamp_equipment`. The node will not be coded.
- **Subject reference.** "covered under this Section, as provided in Section 11.38.080" points to a section outside the corpus. It is a residue, so the rule binds the whole vehicle aggregate.
- **Reversal signal:** the ontology admitting lamp equipment, or 11.38.080 entering the corpus. That reference would then become a composition or a law-local aggregate.

## LVMC_11_38_120_B_o2 — lamps burning when in motion in darkness or poor visibility
- **Duty.** The vehicle is in motion (not `complete_halt`), and either `env.darkness` holds or `env.visibility` is below the stated 500 ft. Then `sig.headlamp` must be `low_beam` or `high_beam`, and `sig.position_lamp` must be lit.
- **"The lights required by this Section".** This refers back to s3's headlamp and tail lamp. Their colour and visible range belong to o1's equipment duty. Being lit is this node's duty.
- **Reversal signal:** a reviewer requiring the tail lamp to be told apart from the other position lamps. That would need an atom gap.

## LVMC_11_40_070 — obey the traffic-control devices that apply to vehicles (gap)
- **Why a gap.** The instructions a device gives *vehicles* are stated by the corpus's vehicle rules. A bicycle, electric bicycle or electric scooter is excluded from the vehicle aggregate. `Formula.rule` treats an engaged-less rule as complied with, so composing a vehicle rule for a bicycle would always report compliance.
- **Gap filed:** operator `ruleAsClass`, which reads a rule with its subject's class replaced.
- **Exception.** "unless otherwise directed by a Police Officer" is `dev.human_direction` with role `police_officer`, governing the subject's region. This follows the flagman pattern of LVMC_11_16_030.
- **Reversal signal:** the operator admitting `ruleAsClass`, or deciding that device obedience is to be written per device kind in the rule itself.

## LVMC_11_40_080_o1 — restricted turns for bicycles and scooters
- **Trigger.** A `dev.regulatory_sign` with code `no_right_turn`, `no_left_turn` or `no_u_turn` governs (`dev.governs`) a travel region the rider occupies at some moment while the turn is under way.
- **Obligation.** The rider does not make the turn the sign's code prohibits. Turns are recognised by the three new turn concepts. The left and right turns use a heading band [`turn_min`, `u_turn_min`). The U-turn uses [`u_turn_min`, 360° − `u_turn_min`], so no turn is counted twice and a full loop is not a U-turn. Each turn is recognised when the yaw rate settles.
- **Timing of the trigger and exception.** The sign is read `some_moment`. "dismounts … to make any such turn" is an exception read `throughout`: the person is in the pedestrian aggregate (afoot) at every under-way observation of the turn. This is disclosed here because a narrowing on an exception span is rejected.
- **Reversal signals:**
  - a label that counts a sign governing only the approach lane, before the turn begins. The trigger would then need an event-relative history instead of `some_moment`.
  - a three-point U-turn being recognised as a left turn at its mid pause.

## LVMC_11_40_080_o2 — pedestrian rules after dismounting (gap)
- **Why a gap.** "in which event such person shall then obey the regulations applicable to pedestrians" requires the open set of pedestrian rules. `Formula.rule` composes one named node at a time, and none of the corpus's pedestrian nodes is published as composable yet.
- **Gap filed:** operator `compliesWithClassRules`, which is close to the carried-over G22. Note: this gap also keeps LVMC-11-40-080 blocked as a law, even though o1 is codable.
- **Reversal signal:** the operator deciding that the clause adds no duty beyond the pedestrian rules' own scope. It would then become a scope-none residue.

## LVMC_11_40_120 — use the bicycle path, not the roadway
This is one obligation, not two: "shall use such path and shall not use the roadway" states one choice of place, positively and negatively.
- **Condition.** "usable" is a standard. A path is usable when its width (`st.lane_width`) is at least `p.usable_path_width_min` (AASHTO operating space) and no device closes it: no `dev.regulatory_sign` with code `closed_to_traffic` or `bicycles_prohibited`, and no governing `dev.temporary_traffic_control`.
- **Path and adjacency.** The path is `st.bicycle_lane_or_path`. "adjacent to a roadway" is read through `st.on_way` on a shared `st.highway`. No relation atom separates a path beside the roadway from a bike lane inside it, so both count. This is disclosed here because a narrowing on a condition span is rejected.
- **Obligation.** Travelling along the roadway while off the path is violated. Crossing the roadway (`moving_across_carrier` with the new `p.rider_crossing_motion_cos`, a rider version of the pedestrian tolerance) is not a use of it. A rider on the sidewalk is not judged.
- **Reversal signal:** a reviewer splitting the obligation into two nodes. The second node would then judge a rider who is off the path and on the sidewalk.

## For the operator
- **`env.darkness` boundary.** LVMC_11_38_120_B_o2 reads "from one-half hour after sunset to one-half hour before sunrise" through `env.darkness`. That atom's sunset and sunrise offset is a reading parameter, and the reading must set it to the half hour the law states.
- **LVMC 11.38.080.** This section is cited by LVMC-11-38-120-B but is not in the corpus. Until it is added, both of that law's nodes bind every vehicle.
- **New parameters.** These are proposed with provisional values: `p.blind_person_approach_reach`, `p.immediate_stop_window`, `p.turn_window`, `p.turn_heading_min`, `p.u_turn_heading_min`, `p.turn_yaw_rate_tol`, `p.usable_path_width_min` and `p.rider_crossing_motion_cos`. Earlier-batch parameters are proposed again unchanged: `p.halt_speed_tolerance`, `p.crossing_motion_cos`, `p.conflict_horizon` and `p.conflict_centre_clearance`.
- **Gaps filed.** `ru.lamp_equipment` (atom), `ruleAsClass` (operator) and `compliesWithClassRules` (operator, close to G22). Deciding the two operator gaps together would unblock LVMC-11-40-070 and LVMC-11-40-080.
- **Blindness.** The ontology has no atom for a road user's visual impairment. LVMC_11_30_140_B reads the subject's not being blind as not being of the white-cane class. If that is unacceptable, an atom is needed, and the law blocks without it.

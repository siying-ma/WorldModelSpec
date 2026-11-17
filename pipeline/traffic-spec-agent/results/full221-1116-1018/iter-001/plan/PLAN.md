<!-- batch-01 -->
# Plan — batch 01 (iteration 001)

Eleven nodes and one concept record (`drv.motion.complete_halt`). No law-local aggregates (`aggregates.jsonl` is empty). Two nodes have gaps and will not be coded: `LVMC_11_16_030` and `LVMC_11_16_090_A_o2`.

Shared decisions:
- **Right-of-way.** Every yield duty (`LVMC_11_12_070_B`, `LVMC_11_20_060_o2`, `LVMC_11_20_060_o3`) uses one operationalization of DEF-NRS-484A-210's "danger of a crash unless one grants precedence". The subject must not proceed (speed above `p.halt_speed_tolerance`) while the constant-velocity closest approach of centres to the other road user falls below `p.conflict_centre_clearance` within `p.conflict_horizon`. It must also never touch that road user (`rel.contact`). All three nodes propose these parameters with identical conventions.
  - Reverse if: a label shows a yield violated where the subject slowed but did not stop. That would mean a deceleration bound is needed rather than a halt.
- **"Driver" / "operator" / "person".** These are read through the vehicle's controlled motion (`observable_reading`, category `agency`). The class is the admitted aggregate `DEF-NRS-484A-320::vehicle`.
  - LVMC-11-16-030, 11-16-040 and 11-16-060 do not use the word "vehicle". For those, the subject's class comes from the driver definition's own words ("drives ... a vehicle"), and for 060 from the fact that a speed limit binds the vehicle travelling there. The validator accepted this id for those laws.
  - Reverse if: the selection role rules that a speed limit with no "vehicle" in its words binds every road user.
- **Prima facie limits** (030, 040, 060) are read as maximums. This is disclosed as a narrowing on the obligation span, because the rebuttal is not modelled.

## LVMC_11_12_070_B
- **Duty.** The through-highway vehicle (subject) yields to the vehicle entering from a stop- or yield-controlled entrance.
- **"Through highway"** (DEF-NRS-484A-275) is read through the devices on the road (`status`). The entering carrier is governed by a stop sign, a yield sign or a flashing-red signal (read as the "other official traffic-control device"). The subject's own carrier is governed by none of these. An all-way stop is therefore not a through highway (branch_1).
- **"Said driver having so yielded"** refers to an act stated in subsection (A). `LVMC_11_12_070_A` is neither accepted nor in this plan, so the validator rejected a composition. The referent is carried in full as the act itself, over o's approach, from the rise of its occupancy of c2 to its entry into j:
  - o halts (`drv.motion.complete_halt`) where a stop sign or flashing red governs c2; and
  - o never proceeds while in a crash-danger conflict with a through vehicle, nor touches one.
  - The weaker fact (o merely entered from a stop approach) would change the verdict. branch_2 (no halt) and branch_3 (o pulled out into the subject's conflict bound) show this: both are not_applicable.
- **"May proceed"** is a permission to the entering driver. It is a scope-`none` residue.
- **"About to enter"** is read as o entering j within `p.conflict_horizon`, or already crossing j (`intention` reading).
- Reverse if: (A) is accepted with a yield duty whose contract differs (for example, no halt at a yield sign). Its record should then be composed `as: compliance` together with the act read here.

## LVMC_11_16_030 (gap — not coded)
- **The structure mirrors 040.** Traversing `st.railway_crossing` above the literal fifteen mph is checked when, in the 100 ft `.path` window before entry, the view fell short.
- **Exceptions.** A flagger or railroad flagger, or a railway signal or gate that governs the subject's carrier at the crossing and shows dark lights with the gate up or absent (`status` readings).
- **Gap.** The view "for a distance of four hundred feet in both directions along such railway" has no atom. `st.sight_along_way` measures along a public way and `st.sight_distance` along the road. The gap is `st.sight_along_railway`.
- **Residue.** "Of a steam, electric or any other motor railway" excludes no railway, so it is a scope-`none` residue.
- Reverse if: the operator declares that `st.sight_along_way` admits a railway as its way.

## LVMC_11_16_040
- **Obligation.** Speed at most fifteen mph while occupying intersection j.
- **Condition.** It applies when, at some observation in the 100 ft `.path` window behind entry to j, any of these held:
  - `st.sight_distance` was below the body-to-j distance (view of the intersection);
  - `st.sight_along_way` along some way the intersection lies on was below 100 ft; or
  - some traffic-aggregate member on such a way within 100 ft of j was not `rel.visible`.
- **Exceptions.**
  - "Through street": same device reading as 070-B, taken on the carrier occupied at entry.
  - "Traffic-controlled intersection": a non-dark signal, a stop sign or a yield sign governs j or a carrier entering it.
  - The second exception covers almost all of the first. Both are kept because the words state both.
- **Residue.** "Or street or highway" is a scope-`none` residue, since every intersection joins highways.
- Reverse if: a label treats a stop-sign-controlled minor approach as not "traffic-controlled". Then d10 should be narrowed to signals.

## LVMC_11_16_060
- **Obligation.** Speed at most twenty-five mph on any highway region (`st.highway`). Streets plus highways cover all of them, so no city-limit assumption is needed.
- **Exception.** A speed-limit sign of kind maximum, structure_maximum or zone governs a travel region the subject occupies. "As set forth in this Title" names no specific rule, so it is read as the posting's status (sign presence) and not composed.
- Reverse if: the corpus gains a specific posting rule the words should compose.

## LVMC_11_16_090_A_o1 (surrogate)
- **Why surrogate.** "Speed contest or exhibition of power or speed" is a conduct category defined by purpose and is the whole duty.
- **Operationalization.** It reads each named factor:
  - exhibition of power: acceleration ≥ `p.exhibition_accel_min`;
  - exhibition of speed: speed ≥ `p.exhibition_speed_min`;
  - contest: another motor vehicle side by side in the same direction, both accelerating ≥ `p.contest_accel_min` throughout `p.contest_window`.
- **Disclosed limits.** Burnouts and sliding are not read.
- Reverse if: labelled exhibitions consist mainly of yaw-dominated manoeuvres. A yaw-rate factor would then be needed.

## LVMC_11_16_090_A_o2 (gap — not coded)
- **Duty.** "Aid or abet" another's contest is conduct, but no atom records it. Proximity (`rel.centre_distance`) is not assistance, and `dev.human_direction` roles do not include starting a race.
- **Gap.** `rel.contest_assistance`.
- **The other party's contest** reuses o1's surrogate operationalization and parameters.

## LVMC_11_18_020
- **Authority sentences.** The two sentences authorizing the City Traffic Engineer impose nothing on road users. They are scope-`none` residues, because the duty selects the crosswalk by the displayed sign.
- **Duty.** The subject must not drive into (occupancy rising) crosswalk cw when all of the following hold:
  - cw marks the entrance of the carrier the subject occupies (`st.entrance_of`);
  - a `dev.zone_sign` of kind school_crossing governs that carrier;
  - a person is in cw — a pedestrian, or a rider of a bicycle, e-bicycle or e-scooter. The riders are added because "any person" is wider than `ru.pedestrian`'s contract.
- **"On the side of the roadway on which said vehicle is coming."** Using `prim.region_lateral_offset` to the centre line and the lateral bearing to the person, the person counts when on the subject's side of the centre line. On a one-way roadway, the whole crosswalk counts.
- **"Attempting to cross"** is read as presence in the crosswalk (`purpose`).
- Reverse if: labels count a person on the far half as the subject's side on narrow two-lane streets.

## LVMC_11_20_060_o1 (rule 4c)
- **Event.** The subject begins to occupy a sidewalk s while occupying a driveway/alley entrance or an alley. A building's vehicle access counts as a driveway under DEF-NRS-484A-190 ("every way or place in private ownership and used for vehicular travel"). This applies within `asm.business_or_residence_district`.
- **Act and place.** `drv.motion.complete_halt` within `p.stop_point_tolerance` of s, outside it.
- **"Stop".** The definition is DEF-NRS-484A-255, by its own scope "when required". DEF-NRS-484A-260 is "when prohibited".
- **Search.** It runs back over the unbroken run in the stop zone and ends at the last observation outside the zone upstream, or at a previous entry onto s. A history_boundary scenario is planned.
- **Spans.** "Immediately prior to" is cut into the obligation span, so the trigger is carried as its words say.
- Reverse if: labels accept a halt farther up the driveway as "immediately prior".

## LVMC_11_20_060_o2
- **Duty.** While on the sidewalk, coming from or going to a driveway or alley, the subject yields to every pedestrian-aggregate member. This uses the shared right-of-way bound, which also operationalizes "as may be necessary to avoid collision".
- **Quantified party.** With no pedestrian present, the verdict is compliant (branch_1).

## LVMC_11_20_060_o3
- **Duty.** While emerging onto roadway r — having occupied the driveway/alley since an observation off r — the subject yields to every vehicle on r, using the shared bound. "Approaching" is the constant-velocity approach of the centres.
- **Scope.** Entering a driveway from the roadway is not emerging, so it is not_applicable.

## LVMC_11_22_010 (surrogate)
- **Why surrogate.** Attention is a state of mind.
- **Applicability.** "Operating" is read as moving.
- **Surrogate test.** No contact with any road user or structure, and no closest approach to the road user ahead in the lane below `p.conflict_centre_clearance` within `p.attention_ttc_min`.
- Reverse if: the operator prefers lane-keeping or reaction-time surrogates.

## For the operator
- `LVMC-11-12-070-A` is not available to compose. 070-B carries its referent as observed conduct (halt at a stop/flashing-red entrance, no conflicting entry). Once (A) is planned, check that its yield contract matches this reading.
- Two atom gaps are filed:
  - `st.sight_along_railway` blocks LVMC-11-16-030;
  - `rel.contest_assistance` blocks LVMC-11-16-090-A_o2.
- All parameter values here are provisional and await review. They are:
  - `p.conflict_horizon`, `p.conflict_centre_clearance`, `p.halt_speed_tolerance`, `p.stop_point_tolerance`, `p.attention_ttc_min`;
  - the five `p.exhibition_*` / `p.contest_*` parameters.
- `asm.business_or_residence_district` is a new assumption id. Traces must declare it for LVMC-11-20-060 to be decided.

<!-- batch-02 -->
# Plan — iter-001, batch 02

Eight laws, eight nodes, two new concept records (`drv.interaction.overtake_pass`,
`drv.motion.moving_across_carrier`). `drv.motion.complete_halt`, proposed earlier in this iteration,
is reused unchanged. Five nodes carry no gap and can be coded. Three carry gaps and stay blocked:
LVMC_11_22_100, LVMC_11_22_120_B and LVMC_11_27_010_A. No law-local aggregates
(`aggregates.jsonl` is empty). The validator accepts every node and both concepts.

## LVMC_11_22_020 — careless or imprudent driving (surrogate)
The whole duty is a standard of care, so the node is marked **surrogate**. "careless or imprudent
manner" is operationalized by the traffic-conflict technique. While the subject vehicle moves on a
highway in the City, it must not touch another road user (`rel.contact`). Nor may it have a projected
closest approach within `p.conflict_horizon` at a centre distance below `p.conflict_centre_clearance`.
Both parameters are re-proposed with the values LVMC_11_12_070_B gave them. "drive or operate" is
read through controlled motion (agency). "on any highway" reuses the index mapping
(`rel.occupies`, `st.highway`). "in the City" is a city limit, which is a legal region class, so it is
the new assumption `asm.within_city_limits`. *Reversal signal:* operator review classifies a careless
manoeuvre with no conflict (e.g. weaving alone on the road) as a violation. That would require more
factors in the operationalization.

## LVMC_11_22_100 — new pavement or closed street (gapped)
The duty: do not drive over pavement newly laid or repaired that a barricade, a flagger or warning
sign, or a "highway closed" sign marks. The marks map to existing atoms through `dev.governs`:
- the barricade to `dev.temporary_traffic_control`;
- the flagger or warning sign to `dev.human_direction`, `dev.temporary_traffic_control` and
  `dev.regulatory_sign`;
- the closed sign to `dev.regulatory_sign` code `closed_to_traffic`.

"pavement newly laid or repaired" has no atom. The duty turns on it, so it is the atom gap
`st.fresh_pavement`. The exception for "employees actually engaged in the paving or repair" turns on
the work a road user is doing. The validator rejected reading it through the `ru.official_vehicle`
class, so it is the atom gap `ru.road_work_activity`. *Reversal signal:* the operator retires either
gap with an atom, or rules that a works closure (`dev.temporary_traffic_control` governing a region)
may stand for the fresh pavement.

## LVMC_11_22_120_B — nonmotorized-traffic street closures (gapped)
The obligation is the second sentence: disobeying the posted restriction means using
(`rel.occupies`) a roadway that a restricting sign governs while being of the class the sign
prohibits. The first sentence describes which signs count. The designation by the Traffic Engineer
and "appropriate signs" are read as status through the sign's presence. The listed classes map as:
- bicycles to the admitted aggregate `DEF-NRS-484A-025::bicycle`;
- other nonmotorized traffic to `DEF-NRS-484A-285::traffic` with the nonmotorized qualifier;
- motor-driven cycles to `ru.moped` / `ru.motorcycle` (no definition applies).

There is no class for a horse-drawn vehicle, so the span carries the atom gap `ru.animal_drawn_vehicle`.
The subject is "no person". The index maps "A person" (LVMC_11_22_010) to the vehicle aggregate.
Here the words reach every road user a sign may restrict, pedestrians and bicycles included, so the
subject is the traffic aggregate. *Reversal signal:* the operator adds an animal-drawn-vehicle class.

## LVMC_11_27_010_A — motorized vehicles on trails (gapped)
The subject is the vehicle aggregate. The law's own word "motorized" narrows it to the motorized
classes, which stand beside the aggregate and never replace it. "operate" is read as controlled
motion: the vehicle is moving. The three conditions on the right-of-way map as follows:
- the trails-plan designation and the dedication to the City are legal region classes, so they
  become the assumptions `asm.designated_trail` and `asm.trail_dedicated_to_city`;
- the posting is a `motor_vehicles_prohibited` regulatory sign governing the travel region the
  subject occupies.

The exceptions:
- **Emergency vehicles:** `ru.emergency_vehicle`, the class alone, because the words name the class.
- **Maintenance use:** "being used in connection with maintenance of the right-of-way" is a use. A
  class can't evidence a use, so it carries the gap `ru.road_work_activity`, the same proposal as
  LVMC_11_22_100's.
- **Wheelchairs and mobility devices:** a scope-`none` residue. Such devices carry none of the
  motorized classes the subject must carry, so the duty is the same either way.
- **"Except as otherwise provided in Subsection (B)":** a scope-`none` residue. Subsection (B) is this
  text's own exception list, already carried.

*Reversal signal:* `ru.road_work_activity` is admitted, or the operator rules that maintenance
livery may evidence the use.

## LVMC_11_30_030 — passing a vehicle stopped at a crosswalk
The obligation "approaching from the rear shall not overtake and pass such stopped vehicle" maps to
the new act concept `drv.interaction.overtake_pass(a, b)`. It holds where a, travelling in the same
direction as b, comes from having b ahead (positive bearing, no longitudinal overlap) to having b
behind, within a recognition window. Being an act, it is judged at recognition with window
`p.overtake_window`. The trigger names the stopped vehicle b, the crosswalk (marked, or unmarked at
an intersection — both are `st.crosswalk`) and the pedestrian. It is read `some_moment` while the
pass is under way:
- b is at a complete halt;
- b's body is on the crosswalk or within `p.stop_point_tolerance` of it;
- the crosswalk is not behind b along a carrier it occupies (`prim.region_offset_along`).

"to permit a pedestrian to cross" is a purpose. It is read through the conduct it explains: a
pedestrian occupies that crosswalk. b and the pedestrian are quantified, not bound. *Reversal
signal:* a labelled recording where a halt for a pedestrian still on the curb counts. That would
need the pedestrian's approach to the crosswalk to be read.

## LVMC_11_30_050 — route of crossing a roadway
The new concept `drv.motion.moving_across_carrier(a, r)` is a state of motion at one observation:
the road user moves, and the absolute cosine between its velocity and r's designated direction is at
most `cos_max`. It is used twice:
- "cross a roadway" uses `p.crossing_motion_cos`. It tells crossing from walking along.
- "at right angles to the curb / shortest route to the opposite curb" uses
  `p.right_angle_crossing_cos`. The curb runs with the carrier's direction, and between parallel
  curbs the shortest route is the perpendicular one.

The perpendicular reading is disclosed as a narrowing. A pedestrian inside a crosswalk is excepted.
*Reversal signal:* recordings with unlaned two-way roadways, where the duty reports unknown for lack
of a direction. That would call for a curb-direction atom.

## LVMC_11_30_060_A / LVMC_11_30_060_B — crossing outside a crosswalk / at a grade separation
Both nodes read "crossing a roadway" with the same concept and tolerance as LVMC_11_30_050. Where
they differ:
- (A) applies where the pedestrian occupies no crosswalk.
- (B) applies where a `st.pedestrian_grade_separation` is within `p.grade_separation_reach` of the
  pedestrian (`st.region_geometry`).

"shall yield" reuses the index mapping (`kin.speed`, `rel.contact`). The standard "the right-of-way"
is its definition's danger of a crash from "direction, speed and proximity". It is operationalized,
as in LVMC_11_12_070_B, by the constant-velocity closest approach (`p.conflict_horizon`,
`p.conflict_centre_clearance`). "all vehicles upon the roadway" are quantified on the roadway the
pedestrian crosses, re-bound in the obligation.

The closing sentence names Section 11.30.070. The validator rejects composing it because it is
neither accepted nor planned in this run. So the reference words are a residue, and the exception's
own words, "when pedestrians are prohibited from crossing at certain designated places", are carried
by a `pedestrians_prohibited` regulatory sign governing the roadway (status reading). *Reversal
signal:* LVMC 11.30.070 enters the library. Then the reference becomes an `exception` composition
on that node and replaces the sign reading.

## For the operator
- **Right-of-way in LVMC-11-27-010-A.** The resolved definition, DEF-NRS-484A-210, is the
  precedence right "to proceed in a lawful manner in preference to another". The law uses
  "right-of-way" for a strip of land ("upon or within a right-of-way that … has been dedicated to the
  City"), which that definition can't bear. The plan reads the place, carried by occupancy and the
  assumptions. The definition precedence for this law may need review.
- **LVMC 11.30.070 is not in the library.** LVMC_11_30_060_A and LVMC_11_30_060_B read the exception
  only through a posted pedestrian prohibition. If 11.30.070 also prohibits crossing in other places
  (for example between adjacent signalized intersections), those places are not excepted until that
  law is planned and the reference composed.
- **No sign code for motor-driven cycles.** `dev.regulatory_sign` has no code for a prohibition of
  motor-driven cycles. The validator rejects a gap on an existing atom, so it is reported here: once
  LVMC_11_22_120_B is unblocked, a sign prohibiting motor-driven cycles will not engage it.
- **Shared gap.** `ru.road_work_activity` is proposed on two laws, LVMC_11_22_100 a7 and
  LVMC_11_27_010_A c9, with the same row.
- **New parameters.** `p.overtake_window`, `p.overtake_same_direction_cos`, `p.crossing_motion_cos`,
  `p.right_angle_crossing_cos` and `p.grade_separation_reach` are proposed with provisional values
  for review. `p.halt_speed_tolerance`, `p.stop_point_tolerance`, `p.conflict_horizon` and
  `p.conflict_centre_clearance` are re-proposed with the values already given this iteration.

<!-- batch-03 -->
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

<!-- batch-04 -->
# Plan — batch 04 (LVMC 11.40.130 – 11.43.010)

Ten nodes over eight law lines, and two new concept records. Every node is `accept` by the
validator. Two nodes carry atom gaps: `LVMC_11_40_170` (two gaps) and `LVMC_11_40_180_B` (one gap).
The coder does not write those two nodes, and their laws stay blocked until the gaps are resolved.
`aggregates.jsonl` is empty. No law here defines its own members, and every aggregate claimed is
listed as admitted in the definitions table.

## Concepts proposed

- **`drv.motion.parked`** (definition `DEF-NRS-484A-155`). The road user is at rest at every
  observation of a window behind it, of length `min_duration`. The rest test reuses
  `drv.motion.complete_halt` with `speed_tol`.
  - The quoted words are "the standing of a vehicle, whether occupied or not", so no occupancy is
    read.
  - The definition's exclusion of a temporary loading halt is a purpose. A purpose cannot be
    observed, so it is a residue, read only through the halt's duration.
  - Reversal signal: a labelled recording where a long halt during loading is judged not parked.
    That would call for a gap on the purpose, not a different duration.
- **`drv.motion.circulating_clockwise_about`** (region formal `r`). The road user moves clockwise
  about `r`'s reference point.
  - The test is the sign of the cross product of the offset from that point with the velocity. A
    squared, sine-tolerance band excludes motion toward or away from the point (roundabout entry
    and exit).
  - Clockwise is read in the frame where a left turn is counter-clockwise, as `kin.yaw_rate`
    defines it.
  - The concept denotes clockwise, not counter-clockwise, so that radial motion is not a
    violation.
  - Reversal signal: a source whose roundabout reference point is not the centre of the island.

Reused, not re-proposed: `drv.motion.complete_halt` and `drv.interaction.overtake_pass`. Neither
record declares an `act`, so no node here declares `occasion`.

## Nodes

**`LVMC_11_40_130` — bicycle speed (surrogate).**
- The whole duty is the standard "reasonable and prudent under the conditions then existing". It is
  operationalized as a bicycle stopping-sight-distance bound: reaction distance plus braking
  distance must not exceed the visibility.
- The surface selects the deceleration: `Term.cond` picks ice/snow, else wet or precipitation, else
  dry. Darkness caps the distance seen at the reach of a bicycle headlamp. Each factor moves the
  bound by its degree, not through one fixed switch.
- `st.sight_distance` was dropped. It needs a region kind and an anchor, and the text names no
  place. The catch-all is therefore disclosed as read only through visibility, surface and
  darkness; bends, crests, traffic density and grade are not read.
- "operate" is an `agency` observable reading. The rule applies only while the bicycle moves.
- Reversal signal: an operator decision to judge speed against sight distance on the travel region
  occupied. That would add `st.travel_region` + `rel.occupies` and narrow where the rule applies.

**`LVMC_11_40_140_o1` — halt before crossing the sidewalk.**
- This is the rule-4c duty of an act before an event, mapped the same way as `LVMC_11_20_060_o1`:
  "shall stop such vehicle immediately prior to" → `drv.motion.complete_halt`, and the sidewalk
  words → `rel.occupies`, `st.region_geometry`, `st.sidewalk`.
- The event is the subject's footprint coming onto sidewalk `s`. The place is the zone outside `s`
  within `p.stop_point_tolerance` of it.
- The search runs back through the run of observations within that zone. It ends at the approach
  start (the subject farther than the tolerance from `s`) or at the subject's previous occupancy of
  `s`. If it reaches neither end, the verdict is unknown; a `history_boundary` scenario covers this.
- **Deviation from the mapping index:** the trigger "entering into or emerging from an alley,
  driveway or building" adds `st.highway` to the earlier atoms (`rel.occupies`, `st.alley`,
  `st.driveway_or_alley_entrance`).
  - Why: "building" means coming from, or going to, beyond the property line. That is observable as
    occupying no `st.highway` region at the observation before entry, or occupying `s` until no
    highway region is occupied (entering a building, read through the movement itself).
  - The earlier mapping drops "building", which would narrow the trigger.
- "such vehicle" does not add a class condition. It refers back to the device the subject operates.
  `DEF-NRS-484A-320` excludes human-powered devices, electric bicycles and electric scooters, so
  reading it as a class would leave the duty empty. The vehicle aggregate is deliberately not
  claimed.
- "stop" resolves to `DEF-NRS-484A-255` ("when required"), the definition `complete_halt` carries.
- Reversal signal: the selection role insisting that "such vehicle" be claimed as an aggregate.

**`LVMC_11_40_140_o2` — yield to pedestrians while crossing the sidewalk.**
- "yielding the right-of-way to any pedestrian" → `kin.speed`, `rel.contact` (as the index maps
  "yielding") plus the pedestrian aggregate.
- The standard "as may be necessary to avoid collision" is bounded by the conflict technique:
  closest approach within `p.conflict_horizon` and below `p.conflict_centre_clearance`, while the
  subject moves.
- The rule applies while the subject stays on the sidewalk it entered under the o1 trigger. The
  trigger conditions are restated in full, not composed: the o1 node is not yet coded, and
  composing it would test compliance, not the event.
- A scenario with no pedestrian shows that the duty binds the subject alone.

**`LVMC_11_40_170` — parking (two atom gaps).**
- "park" → the new `drv.motion.parked` (`p.parking_min_duration`), with a `purpose` observable
  reading. "upon a street" → `st.highway` + `rel.occupies`. The city-limits half of the street
  definition is the code's own territorial scope, as the justification records.
- The allowed places are `exception` spans:
  - roadway against the curb: `rel.contact` with `st.road_edge`;
  - on the sidewalk at the curb: `st.region_geometry` distance to `st.road_edge` within
    `p.parked_edge_reach`.
- The standard "least obstruction to" (pedestrian traffic → pedestrian aggregate) means the body is
  within the placement margin of its edge and no pedestrian is in contact with it. The comparative
  "least" is disclosed as a narrowing.
- **Gaps:**
  - "in a rack to support …": `st.obstruction{sidewalk_fixture}` cannot tell a rack from a pole or a
    bench.
  - "or against a building": no atom carries a building's wall; `st.highway`'s boundary is the
    property line.
  - Either nearest atom would widen the allowance, which is an approximation the termination rule
    forbids.
- Reversal signal: an ontology revision adding a rack or a building region.

**`LVMC_11_40_180_A` — no riding on the Fremont Street sidewalks.**
- The named stretch is a legal designation of a way, carried by a new assumption
  `asm.fremont_street_main_to_seventh`.
- "ride" → not `drv.motion.complete_halt`, consistent with the index's "shall be ridden". This is
  an `agency` reading: a bicycle pushed along on foot is not told apart from one ridden.
- The second sentence directs the City to post signs. The prohibition does not depend on the
  signs, so it is a residue with scope `none`.
- Reversal signal: a labelled walked-bicycle scene, which would require reading
  `ru.rider_posture`.

**`LVMC_11_40_180_B` — sign-posted riding prohibitions (one atom gap).**
- The roadway branch: a `dev.regulatory_sign` of code `bicycles_prohibited` that governs
  (`dev.governs`) the roadway the subject occupies. "in the City" → `asm.within_city_limits`, as
  `LVMC_11_22_020` reads it.
- The Director's authority and determination are read through the sign's presence (`status`
  observable readings). "by any person" is a residue with scope `none`.
- **Gap:** "on any other sidewalk". `dev.governs` excludes regions no vehicle travels in, so no
  atom ties a sign to a sidewalk. Distance cannot stand in for belonging.
- Reversal signal: `dev.governs` extended to sidewalks.

**`LVMC_11_40_180_C_o1` — yield to pedestrians on the sidewalk.**
- The trigger covers riding (not at rest) on a sidewalk.
- "such person shall yield" → `kin.speed`, `rel.contact`. "the right-of-way" is the standard,
  bounded by the conflict technique per the danger-of-crash words of `DEF-NRS-484A-210`, as in
  `LVMC_11_43_010_B_o1`.
- A scenario with no pedestrian is compliant.

**`LVMC_11_40_180_C_o2` — audible signal before passing a pedestrian.**
- The pass is `drv.interaction.overtake_pass`. The signal is `sig.horn` or `sig.siren` (horn,
  bell, whistle). A spoken warning has no atom and is disclosed as a narrowing.
- "before" is a rule-4c search back from the pass onset, the last observation at which the
  pedestrian was ahead with headings aligned (`atLast` over `p.overtake_window`). The search covers
  the run in which the pedestrian stayed ahead and ends at its start. The `history_boundary`
  scenario covers a run that begins before the recording.
- The sidewalk trigger is read at some moment of the pass, documented in `applicability`.
  `branch_1` and `branch_2` cover a pass partly on the sidewalk and one where the rider is on the
  sidewalk only before the pass.
- Reversal signal: the pass concept gaining an `act` declaration, which would require an
  `occasion` block.

**`LVMC_11_43_010_A` — counterclockwise travel in a roundabout.**
- The preamble's "within a roundabout" → `rel.occupies` + `st.roundabout`. "All vehicular travel"
  → vehicle aggregate, not at rest.
- The obligation is the negation of `drv.motion.circulating_clockwise_about` on the occupied
  roundabout `r`, with `p.roundabout_clockwise_sin_tol`.
- The reference point is read as the centre of the island (a narrowing). The circulatory-roadway
  definition `DEF-LVMC-11-02-040` ("travel counterclockwise around a central island") supports
  this.
- An electric scooter is not applicable, because the vehicle definition excludes it.

**`LVMC_11_43_010_B_o1` — yield to vehicles already in the roundabout.**
- The event is the footprint coming onto the roundabout. "Already in" means a vehicle occupying it
  at the observation before and at the entry.
- Same conflict bound as the other yield nodes, judged at the entry.

**`LVMC_11_43_010_B_o2` — enter only at a gap in traffic.**
- A second obligation verb ("and wait … before entering"). "wait" is read as entering only at a
  gap; no halt is required where a gap already exists (a narrowing).
- The gap is the gap-acceptance standard: no traffic-aggregate member in the roundabout (pedestrians
  on its crosswalks included) comes within the clearance before `p.roundabout_critical_gap`.
- Reversal signal: a label requiring a halt at every entry.

## Parameters

- Proposed again with the values and conventions catalogued this iteration:
  `p.halt_speed_tolerance`, `p.stop_point_tolerance`, `p.conflict_horizon`,
  `p.conflict_centre_clearance`, `p.overtake_window`, `p.overtake_same_direction_cos`.
- New: `p.bicycle_reaction_time`, `p.bicycle_decel_dry`, `p.bicycle_decel_wet`,
  `p.bicycle_decel_ice`, `p.bicycle_lamp_reach`, `p.parking_min_duration`, `p.parked_edge_reach`,
  `p.roundabout_clockwise_sin_tol`, `p.roundabout_critical_gap`.

## For the operator

- **Gaps filed:**
  - `st.bicycle_rack` and `st.building` (both `LVMC-11-40-170`).
  - `dev.governs_walkway` (`LVMC-11-40-180-B`). The same need will recur for any sign-posted
    sidewalk restriction.
- **Frame handedness:** `drv.motion.circulating_clockwise_about` relies on the world frame in which
  a left turn is counter-clockwise, as the ontology states for `kin.yaw_rate` and
  `prim.region_lateral_offset`. A CARLA adapter that passes raw left-handed coordinates would
  reverse the sense.
- **Roundabout reference point:** `LVMC_11_43_010_A` needs the `st.roundabout` region's reference
  point at the centre of the central island. The manifest should say whether it is.
- **Audio:** sources without audio declare `sig.horn` and `sig.siren` absent, so
  `LVMC_11_40_180_C_o2` is unknown on them by design.
- **Fog/visibility:** `LVMC_11_40_130` is unknown wherever `env.visibility` is not observed.

<!-- batch-05 -->
# Plan — batch 05 (iteration 001)

No law-local aggregates: `aggregates.jsonl` is empty.

## New concepts

`drv.motion.left_turn_through_region`, `drv.motion.right_turn_through_region` and `drv.motion.u_turn_through_region` are new. Each takes a road user `a` and a region `r`. Each is recognized at the observation where `a` leaves `r`, and its band is applied to the heading change since `a` entered `r` (`headingSince`, onset = the rise of `rel.occupies(a, r)`).

The proposed `drv.motion.left_turn`, `drv.motion.right_turn` and `drv.motion.u_turn` concepts do not fit a roundabout:
- Their fixed window behind the observation does not start at the entry, so a turn that takes longer than the window is lost.
- They are recognized when the yaw rate settles, not at the exit from the region the words name.

The U-turn record quotes DEF-NRS-484B-077. A full turn is a geometric literal, so that a loop is told apart from a reversal.

**Reversal signal:** the concept review finds `headingSince` cannot take a formal step parameter in a concept body.

## LVMC_11_43_010_C1 / LVMC_11_43_010_C2

One node per subsection. Each is judged at the observation where the vehicle leaves the roundabout `r` after a left turn or U-turn (C1) or a right turn (C2) through it.

**How the words are read:**
- **"who intends to exit"** is read through the exit itself (`observable_reading` intention, occasion `at_recognition`). It is not a declared intention: rule 2 limits `int.*` to an intention to turn, and the words state an intention to exit.
- **Turn direction** is read from the net heading change between entry and exit, so the counter-clockwise circulation in between does not count.
- **"Use the left lane"** means: every lane the vehicle occupies within `r`, from entry to exit, has ordinal 1.
- **"Use the right lane"** means: every such lane has ordinal equal to the count of lanes in that direction.

A single-lane roundabout complies trivially.

**Reversal signal:** the source declares route intentions (`int.*`) at roundabouts, or labels judge the lane on approach before entry.

## LVMC_11_46_030_o1

The duty is to stop not less than fifty feet from the crosswalk while the warning is given. It is planned under rule 4c.

**Event:** the vehicle comes within the literal fifty feet of the crosswalk (body distance from `st.region_geometry`) while a device governing its travel region warns. The warning is either:
- an active `dev.crossing_warning_signal`, or
- a `dev.human_direction` of any role with indication stop.

**Which crosswalk:** "the school pedestrian lane where [the device] is stationed" is the nearest crosswalk ahead of the vehicle (`prim.region_offset_along` > 0) on the same way (`st.on_way`). No atom relates a device's position to a crosswalk, so the device is tied to the crosswalk through the travel region it governs and the way both lie on (`observable_reading` status/intention). The warning's content, children crossing, is read through the warning itself.

**Search for the halt:** it runs back through observations where the warning holds continuously and the crosswalk stays ahead. It ends at whichever comes first:
- the warning's onset (a halt before the warning is no halt for it), or
- the previous entry into the fifty-foot zone, or
- an observation where the crosswalk is not ahead.

If the search runs into the recording's start, the result is unknown (`history_boundary`).

"stop" is read with DEF-NRS-484A-255, because its own scope ("when required") is the one these words meet.

**Reversal signal:** an atom relating a device's station to a crossing is added, or labels count a halt made before the warning began.

## LVMC_11_46_030_o2

"Unlawful to proceed" refers to the stop of the first clause. That stop is carried in full as a condition of this node: a halt at or beyond fifty feet while that device warns. It is not composed from o1, because it requires the act, not compliance with o1.

The duty holds while that device's warning lasts (`since`). It ends when:
- the signal goes inactive or disappears, or
- the person shows proceed, leaves, or no longer governs the lane.

**Reversal signal:** labels judge a vehicle that stopped closer than fifty feet as bound not to proceed. Then the fifty-foot qualification would be dropped from the condition.

## LVMC_11_48_050

The node is blocked by two atom gaps:
- **`ru.unladen_weight`:** "in excess of eight thousand pounds unladen weight" has no atom. `ru.commercial_motor_vehicle` and `ru.truck` are classes, not a weight.
- **`ru.special_permit`:** the Department's written special permit, with its conditions, has no observable counterpart. The proviso and the permit-conditions sentence are one exception span.

The weight figure has no literal, because the literal units have no mass unit. The gap carries the figure.

**What the node carries:**
- "Street" maps to `st.highway`, as in the index.
- "Truck route" is read through the truck_route regulatory sign (§9: a designation marked by a sign is read by the sign).
- "Residence district" is the new assumption `asm.residence_district`. The catalogue holds only the business-district ids, which have a different meaning.
- The hours are `env.civil_time` against the literals seven p.m. and six a.m.

The definitions table lists the truck aggregate for this law, but "truck" appears only in "truck route", which names a route, not road users. So the aggregate is not claimed.

**Reversal signal:** a mass attribute and a permit atom enter the ontology.

## LVMC_11_48_060

The words name no road user. The node reads the duty as binding trucks (`ru.aggregate=DEF-NRS-484A-305::truck`, claimed on "from one truck route to another"), the vehicles truck routes exist for. Binding every vehicle would forbid ordinary traffic from crossing between two truck routes, which the section does not mean.

**Trigger:** the truck comes onto a travel region governed by a truck_route sign.

**Violation:** in the stretch behind it, the truck stayed continuously on streets off truck routes, back to a truck-route region on a highway the new one does not lie on (`st.on_way`). That different highway is "another".

**Exception:** "unless pick-up, delivery or essential use is required" is a purpose. It is read through a parked halt on the stretch (`drv.motion.parked`, minimum duration `p.delivery_halt_min_duration`). An "essential use" that shows in no such halt is not read.

**Reversal signal:** the selection role or a label shows the ban binds every vehicle, or that a stretch returning to the same truck route counts.

## LVMC_11_52_030_A

**The duty:** red means no stopping. "Stopping" (DEF-NRS-484A-260) is any halt, carried by `drv.motion.complete_halt`, so standing and parking add nothing. Subsection (1) restates no parking for a red curb, so it is a condition span, not a second obligation.

**The definition's own exclusions** are carried beside the halt:
- **Avoiding conflict with traffic:** a road user ahead in the same lane within `p.queue_halt_gap`.
- **Following an officer or device:** a police stop indication, a red signal indication, or a stop sign governing the vehicle's travel region.

**Exceptions:**
- **(2) Tour buses, shuttle buses and limos:** the admitted aggregates, in a zone of kind `tour_bus_loading`, for up to the literal thirty minutes.
- **(3) RTC buses:** the admitted aggregate, in a zone of kind `bus_stop`, for up to the literal thirty minutes.
- **(4) Armored cars and emergency vehicles:** any halt. "The period necessary to conduct their business" is a purpose read through the halt.
- **(5) Mail drop box:** the vehicle's body is within `p.mail_drop_box_reach` of the box, and the halt so far is within `p.mail_deposit_max_halt`. "Expeditiously" is an operationalized standard; it is not a surrogate.

The duration tests in (2), (3) and (5) use `sinceRise` from the halt's start in the zone.

The second sentence ("shall be established by posting…") is the city's duty. It is read only as the signed or marked zone's presence (status).

**Reversal signal:** labels treat a vehicle queued at a red curb behind a vehicle farther away than the queue gap as compliant.

## LVMC_11_52_030_B

The yellow zone is "for" commercial vehicles and taxicabs. It is read as barring any other halt in the zone. The two listed uses are exceptions: the admitted aggregate, plus the conditions of an accompanying `dev.zone_sign` (kind `parking_restricted`) governing the curbside lane holding for the vehicle (`prim.conditions_hold`).

**Narrowing:** a halt outside the sign's posted times is read as outside "the conditions and times posted", so it is restricted, not freed.

"stop" has two posted definitions, each with its own scope. Both are a halting, which is all the node reads, so no choice between them is made.

**Reversal signal:** labels treat parking in a yellow zone outside the posted hours as compliant. The posted hours would then move to applicability, which would need an operator that tests a sign's time windows alone (`prim.conditions_hold` couples time and class).

## LVMC_11_52_040_A

**Trigger:** a vehicle stands or parks (`drv.motion.parked`, minimum duration `p.standing_min_duration`) in a roadway. The definitions' exclusion for passengers or loading is read through the halt's length.

**Duty:** the vehicle's heading is aligned, within `p.parked_heading_cos`, with the designated direction of every carrier it occupies. The edge runs along that direction, so this one reading gives both "parallel with the edge" and "headed in the direction of lawful traffic". The definitions table admits "traffic" for this law, so the traffic aggregate is claimed on that span.

**"Except as otherwise provided in this Chapter":** no corpus node states such a provision. It is read through a posted angle_parking sign (status).

**Reversal signal:** a corpus node of the Chapter that states a different placement rule appears. The exception would then become an `unless` composition.

## For the operator

- **LVMC-11-48-050** is blocked until the ontology carries a vehicle's unladen mass (`ru.unladen_weight`) and a permit status (`ru.special_permit`).
- The literal units have no mass unit (for example `lb`). The figure "eight thousand pounds" therefore lives only in the gap.
- No atom relates a device's position to a crossing or a curb zone (a device "stationed at" a pedestrian lane, or a sign "accompanying" a curb zone). LVMC-11-46-030 and LVMC-11-52-030-B read the link through the travel region the device governs. A `dev.stationed_at` relation would make that link exact.
- The definitions table lists the truck aggregate for LVMC-11-48-050 and LVMC-11-48-060, where the word occurs only in "truck route". It is claimed only in LVMC-11-48-060, where it names the road users the ban concerns.

<!-- batch-06 -->
# Plan — batch 06 (LVMC 11.52.060, 11.52.070, 11.52.130 (A)(2), (4), (5), (7), (11), (12))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse
`drv.motion.complete_halt` and `drv.motion.parked`, which an earlier batch of this iteration proposed.

## LVMC_11_52_060 — projection into street (coded)

**Decision.** There is one node with one obligation span: "project into the street more than fifteen feet
measured on a line at right angles to the curb." The subject is a vehicle or a trailer, both
claimed as their admitted aggregates.
- "project" is read for a vehicle that is **parked** (`drv.motion.parked` with
  `p.halt_speed_tolerance`, `p.parking_min_duration`). The section sits in the
  stopping/standing/parking chapter and measures from the curb the vehicle stands at. Read
  literally, every vehicle driving in a lane more than fifteen feet from the curb would violate.
- "street" (DEF-NRS-484A-265) is `st.highway` anchored by `rel.occupies`, as the mapping index
  already reads it.
- "the curb" is the `st.road_edge` lying on that street (`st.on_way`) that is nearest the body.
- The projection is the body-to-curb ground distance (`st.region_geometry`) plus the body's extent
  across the curb line. That extent is length·|heading × dir| + width·|heading · dir|, where dir is
  the designated direction (`st.lane_direction`) of the travel region the vehicle occupies. That
  direction is read as the curb's line, and the reading is disclosed.
- A load is judged only inside the body outline the source reports. That limit is disclosed as a
  narrowing, because no atom carries an overhanging load.
- "attached to such vehicle" is a scope-none residue: a trailer is "a vehicle" by DEF-LVMC-11-02-170,
  so its own body is judged whether or not it is attached.

**What would reverse it.** If a labelled moving vehicle is judged under 11.52.060, drop the parked
reading. If an ontology atom for a curb's direction or for a load overhang is added, use it in
place of the carrier direction or kin.extent.

## LVMC_11_52_070 — angle parking (coded)

**Decision.** There is one node.
- The Traffic Engineer's determination and the duty to sign or mark the streets are not road-user
  duties. They are read as `status` observable readings: what shows them is an `angle_parking`
  regulatory sign governing the occupied travel region, or an occupied marked bay whose angle
  stands clear of zero. "Clear of zero" uses the new parameter `p.parking_space_angle_resolution`,
  which only states the source's resolution. The same mapping as the index precedent "The City
  Traffic Engineer is authorized to determine…" applies.
- The obligation span reuses the index mapping of "No person shall stand or park a vehicle"
  (`drv.motion.parked` with `p.standing_min_duration`). It also reuses the index mapping of
  "headed in the direction of lawful traffic movement" (`kin.heading`, `st.lane_direction`,
  `rel.occupies`, `st.travel_region`, traffic aggregate).
- "Front pointed toward" is a positive dot product of heading and designated direction on every
  selected travel region the vehicle occupies.
- A vehicle wholly inside a bay that overlaps no travel region is not judged. This is disclosed as
  a reading.

**What would reverse it.** If the source's `st_parking_space_angle` is not measured from the curb
line (for example, 90° for a parallel bay), the bay-angle test must change. A label that judges a
vehicle that is entirely within a bay would require a different direction source.

## LVMC_11_52_130 (A)(2), (A)(4), (A)(5), (A)(7), (A)(11), (A)(12) — no stopping at places (gapped)

**Decision.** All six share one preamble, and it is segmented the same way in each node:
- **"stop, stand or park".** "Stop" is prohibited here, so DEF-NRS-484A-260 applies by its own
  scope ("when prohibited, any halting, even momentarily"). The three verbs together therefore
  mean any halt: `drv.motion.complete_halt`. The index maps "No person shall stand or park" to
  `drv.motion.parked`; the word "stop" is why this mapping differs.
- **"except when necessary to avoid conflict … with other traffic".** This is a standard. It is
  operationalized by a road user of traffic (the admitted aggregate) ahead in the same lane within
  `p.queue_halt_gap` (`rel.ahead_behind_in_lane`, `rel.surface_gap`). Reading conflict only as
  traffic ahead in the lane is disclosed as a narrowing.
- **"the directions of a police officer".** `dev.human_direction` with role police_officer and
  indication stop, governing the occupied region. This is the index mapping.
- **"a traffic control device".** A stop sign, yield sign, red/yellow signal or active railway
  signal or gate governing the occupied region.
- **"in compliance with law" is an `operator` gap.** It excepts any halt that another law requires:
  yielding to a pedestrian at a crosswalk, stopping before the sidewalk when emerging from a
  driveway, stopping for a school bus or an emergency vehicle. No atom carries this, and
  `Formula.rule` composes only one named rule. The composable candidates are all "not composable"
  this iteration. The open gap smoke31-1111-0039:G22 proposes the same operator for the same
  words. Dropping the exception would make A12 and A11 report every lawful yield at a crosswalk or
  intersection as a violation. So all six nodes carry the gap and are not coded.

Places and their own gaps:
- **A11.** `st.intersection` and `st.region_geometry` within the literal fifteen feet.
- **A12.** Marked `st.crosswalk` within the literal twenty feet.
- **A2.** `st.curb_zone` of kind fire_lane, occupied. The designation and posting are a status
  reading. The Fire Code reference is out of the corpus and is a residue. "attended or unattended"
  and "public or private property" are scope-none residues.
- **A4.** `st.fire_hydrant` within a bound chosen by `Term.cond`: twenty feet where an
  angle-parking or no-parking sign, an angled bay or a no-parking/no-stopping/fire-lane zone
  applies, otherwise fifteen feet. The "posted / painted red / public or private" clauses are
  scope-none residues.
- **A5.** Has a second gap, an atom gap `st.sidewalk_elevator_or_chute`. `st.obstruction` kind
  sidewalk_fixture cannot tell an elevator from a bench. The frontage is read with the new
  parameter `p.curb_frontage_reach` and with `prim.region_offset_along` within five feet plus half
  the vehicle's length.
- **A7.** Has three further atom gaps:
  - `st.driveway_entrance`: the contract of `st.driveway_or_alley_entrance` says it cannot tell a
    driveway from an alley.
  - `rel.premises_privilege`: the exemption for the driveway's owner, controller, family or
    invitee.
  - `ru.postal_vehicle`: `ru.official_vehicle` has no postal kind.

  Also on A7:
  - "near a private driveway" is a standard, bounded by `p.driveway_near_reach`.
  - "on official business" is a `purpose` reading through the halt.
  - Paragraph (B)'s mention of Paragraph (1) concerns another line, so this node carries only the
    exception for (7).

**What would reverse it.** If the operator accepts G22, or an equivalent `requiredByRuleSet`
operator, the four laws whose only gap is p4 can be re-planned unchanged and coded: A2, A4, A11,
A12. If the operator rejects the gap with an allowed reading, for example "a law-required halt is
read through the device and traffic exceptions", p4 becomes an `observable_reading` on those atoms.

## For the operator

- **G22 ("in compliance with law") blocks LVMC-11-52-130 (A)(2), (4), (5), (7), (11) and (12).** It
  is the same open gap as smoke31-1111-0039:G22, proposed here as `Formula.requiredByRuleSet`. One
  decision on G22 unblocks four of these laws outright.
- **New parameters proposed:** `p.parking_space_angle_resolution` (deg), `p.curb_frontage_reach`
  (m) and `p.driveway_near_reach` (m).
- **`st.parking_space` angle attribute.** Its reference direction is not stated in the ontology.
  These plans assume 0° means parallel to the curb.

<!-- batch-07 -->
# Plan — batch 07 (LVMC 11.52 parking, 11.60.030 buses)

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts: every "park/stand" is the
earlier batch's `drv.motion.parked` (temporary halt excluded by `min_duration`, disclosed as a
`purpose` reading), every "stopped" is `drv.motion.complete_halt`. Re-proposed parameters keep the
earlier batches' name, value, unit and convention (`p.halt_speed_tolerance`, `p.parking_min_duration`,
`p.standing_min_duration`, `p.queue_halt_gap`). New: `p.curb_parallel_cos`,
`p.commercial_loading_max_halt`. Five nodes are codable. Three carry gaps (180-C, 305-A, A1/A2).

## LVMC_11_52_136 — parking in an access aisle
I map "No person shall park" to `drv.motion.parked` with `p.parking_min_duration`, the same as the
index's "It shall be unlawful for any person to park". "a vehicle" is the admitted vehicle
aggregate. "in an access aisle." is `st.parking_space` with designation `access_aisle`, anchored by
`rel.occupies`. The definition's design and marking clauses are read through the mapped designation
(`status`). Reversal signal: a source that maps access aisles as an area separate from the bays
rather than as a bay designation.

## LVMC_11_52_180_C — 30 minutes within any hour in an alley
"parked in an alley" is `drv.motion.parked` with `rel.occupies`/`st.alley`. The obligation limits
the **total** time parked within any one-hour window. `holdsFor` and `sinceRise` can only measure a
single continuous run. Writing the limit with them would let a vehicle that leaves for a moment and
comes back escape the limit, and that is a narrowing that drops what the words require. So the span
carries an `operator` gap (`durationWithin`) and the node is not coded. I read "otherwise lawfully"
as a residue of scope `none`: it says that complying with every other rule does not excuse going
over the limit. It does not exempt a vehicle that is unlawfully parked in some other way. Reversal
signal: a reviewer who reads "otherwise lawfully" as restricting the duty. That would need the
pending G22-style operator, "in compliance with law".

## LVMC_11_52_300 — non-motor vehicles, 1–6 a.m.
The subject is a vehicle and not a motor vehicle; the exception uses the admitted motor-vehicle
aggregate. "on any street" is mapped to `rel.occupies` and `st.highway`, the same as the index's
"upon any street". The city-limits part of the definition of "street" is the jurisdiction this city
ordinance already applies in, so it gets no assumption. The hours are compared on `env.civil_time`,
the same as the index's "between the hours of seven p.m. and six a.m.". Together with "for a period
of time longer than thirty minutes", this makes one continuous `.time` window. At every observation
in that window the vehicle is parked on the street within the hours. A period that starts before
1 a.m. only counts the minutes inside the hours (branch_1). Reversal signal: a label that counts
parking begun before 1 a.m. toward the thirty minutes.

## LVMC_11_52_305_A — commercial vehicles, RVs, trailers near residences, schools, parks
- **Subject.** The three admitted aggregates, plus `ru.trailer_or_combination` with the vehicle and
  trailer aggregates for "any combination of vehicle and trailer".
- **Length.** The overall length is `kin.extent`, compared with the literal 24 ft.
- **Location.** Adjacency to a residence district, public school or public park is a legal region
  class. It is the new assumption `asm.street_adjacent_to_residence_school_or_park`. The section's
  own meaning of "residence district" is a residue tied to that declaration.
- **Prohibited conduct.** "stand, park or store" is one standing prohibition
  (`p.standing_min_duration`).
- **Exception (1).** I read it as a commercial vehicle at rest with a door open. The `standard`
  "expeditiously" is operationalized as the current halt being no longer than
  `p.commercial_loading_max_halt`.
- **"Except as otherwise provided in this Section".** A residue of scope `none`, because the
  Section's other provisions are subsection (B), which is carried here.
- **Gaps (node not coded).** There are three atom gaps:
  - `dev.parking_permission_sign` for "as permitted by posted sign". No regulatory code or zone-sign
    kind permits parking for a class of vehicle.
  - `ru.unladen_mass` for the 8,000-pound weight. The earlier batch mapped LVMC_11_48_050's similar
    words to `ru.commercial_motor_vehicle`/`ru.truck`. I dispute that: the contract's "commercial
    mass class" is a threshold the jurisdiction sets, not this stated unladen weight. I declare no
    literal, because pounds is not a literal unit.
  - `ru.work_service_use` for exception (2).

  Reversal signal: the ontology adding any of these atoms.

## LVMC_11_52_340 — municipal parking spaces
"such space" points back to the space the first sentence designates. Both spans are carried by
`st.parking_space` with designation `municipal`, and the posted or marked designation is read
through the mapped bay (`status`). The second span is anchored by `rel.occupies`. "other than a City
vehicle" is `ru.official_vehicle` of kind `municipal`. I disclose that a city-owned vehicle without
municipal livery, such as a city fire engine labelled only as an emergency vehicle, is read as not a
City vehicle. Reversal signal: a label that excuses a city emergency vehicle parked in a municipal
space.

## LVMC_11_60_030_A1 — bus standing only at stops, stands and its own route's terminus
The subject is a bus and not a tour bus, with an `agency` reading for "operator". "Not stand or
park" is `drv.motion.parked` with `p.standing_min_duration`. The places come from LVMC 11.60.010
through a `definition` reference: "shall be designated by appropriate signs". So a bus stand and a
terminus are read as the signed bus zone (`st.curb_zone` kind `bus_stop`), and a bus stop is that
zone or `st.transit_stop`. "for the route to which such vehicle is assigned" has no carrier: nothing
ties a bus to its route or a route to its termini. It is an atom gap, `rel.route_terminus_of`, and
the node is not coded. Dropping the words would excuse standing at another route's terminus. Reading
them as never satisfied would forbid standing at the bus's own terminus. Reversal signal: a route
assignment atom in the ontology.

## LVMC_11_60_030_A2 — bus stops to load only at designated places
"stop" is a prohibited stop, so it falls under DEF-NRS-484A-260 by that definition's own scope. That
definition excludes halts made to avoid conflict with traffic, or made because a police officer or a
device directs them. `drv.motion.complete_halt` does not make those exclusions, so they are carried
beside it with the same atoms as the index's LVMC_11_52_130_A11: a queue gap (`p.queue_halt_gap`)
and governing devices or human direction. I use a bare road user rather than the traffic aggregate,
which the table does not admit for this law. The purpose "for loading or unloading passengers or
their baggage" is read as a door open while halted (`sig.door_open`, `purpose`). There are two atom
gaps: the same route gap as A1, and `env.emergency` for "except in case of an emergency". The
emergency gap matches the pending gap G20's proposal. The node is not coded. Reversal signal: both
atoms being added.

## LVMC_11_60_030_A4 — bus position at the curb when loading
- **Trigger.** A bus, not a tour bus, at rest with a door open while it occupies a bus stop, a
  signed bus zone (standing in for a bus stand or terminus, a `status` reading) or a passenger
  loading zone on a street.
- **Obligation.** Some road edge on the bus's right (`prim.region_lateral_offset` negative) is
  within the literal 18 in of the body outline (`st.region_geometry`).
- **Standard.** "approximately parallel to the curb so as not to unduly impede…" is operationalized
  with `p.curb_parallel_cos`, using the heading and the occupied carrier's direction.
- **Disclosed readings.** I read the wheel through the body outline: this is lenient by the tyre's
  inset from the body side. "Unduly impede" is read only through the alignment, and the movement of
  actual other traffic is not read.
- **Reversal signal:** a source that carries wheel positions, or a label that turns on another
  vehicle's movement being impeded.

## For the operator
- **Cumulative duration.** LVMC 11.52.180(C) needs an operator for the total time a condition holds
  within a sliding window (`durationWithin`). Several parking-limit ordinances with the shape "N
  minutes within any M-hour period" will hit the same gap.
- **Vehicle weight.** Unladen weight thresholds ("in excess of eight thousand pounds") have no atom.
  I dispute the earlier batch's mapping of LVMC_11_48_050's similar words to
  `ru.commercial_motor_vehicle`. The literal unit list has no pound, so the figure cannot be declared
  as a literal.
- **Bus route assignment** (`rel.route_terminus_of`) blocks both LVMC 11.60.030(A)(1) and (A)(2).
  **Emergency** (`env.emergency`) repeats the pending gap G20.
- **Permissive parking signs** have no regulatory code or zone kind (`dev.parking_permission_sign`).

<!-- batch-08 -->
# Plan — batch 08 (iteration 001)

Eight laws, eight nodes, one new concept (`drv.motion.moving_backward`). Every node passes the validator. One node, `LVMC_11_60_030_A5`, carries an atom gap and will not be coded. No law-local aggregates (`aggregates.jsonl` is empty).

## New concept

**`drv.motion.moving_backward`** (used by `NRS_484B_113_2` and `NRS_484B_113_3`). The road user's velocity, projected onto its heading, is below minus `speed_tol`. It is a state at one observation, not an act, so the nodes that use it need no `occasion`. Backing is read from kinematics, never from `kin.gear`, as `kin.gear`'s contract requires. There is one parameter, the speed resolution, filled with `p.halt_speed_tolerance`. Nothing in the catalogue or the concepts proposed this iteration denotes backing. **What would reverse this:** an accepted concept that denotes motion against the heading; that concept would then be reused instead.

## Nodes

**`LVMC_11_60_030_A5` — gap, not coded.**
- **Spans reused from the index:**
  - subject: bus aggregate
  - exception: "other than a tour bus" (tour-bus aggregate)
  - place: bus-stop curb zone or transit stop, anchored by `rel.occupies`
- **Obligation:** "Not stand or park a bus", read as `drv.motion.complete_halt`.
- **The gap:** the duty turns on "a period of time longer than has been designated for such bus stop". The span borrows from LVMC 11.60.010 through a `definition` reference: "he may designate the length of time that a bus may stand or park at each".
  - The period belongs to each stop and is posted on that stop's sign.
  - The `conditions` attribute of `dev.zone_sign` and `dev.regulatory_sign` lists "a duration limit", but §11 gives no measure to read it. `prim.conditions_hold` decides only time windows, occupancy and class.
  - A reading parameter would fix one period for every stop, which contradicts "such bus stop".
  - So the node files the atom gap `dev.posted_duration_limit`.
- **What would reverse this:** an ontology measure (or primitive) that exposes a sign's posted duration.

**`LVMC_11_60_040`.**
- **Subject:** taxicab aggregate.
- **Applicability:** the taxicab is on a highway ("upon any street", same atoms as the index).
- **Obligation:** wherever it stands (`drv.motion.parked` with `min_duration = p.standing_min_duration`), it is in a `taxicab_stand` curb zone.
  - "stand or park" is read as standing, because standing contains parking under DEF-NRS-484A-250 and DEF-NRS-484A-155.
- **"at any place other than in a taxicab stand…"** is an exception span. A node may carry only one obligation span.
- **The second sentence (temporary passenger stop):**
  - It is carried by the halt-duration reading of purpose: a halt shorter than `p.standing_min_duration` is not standing.
  - "in accordance with other stopping or parking regulations" is a scope-`none` residue. This provision does not forbid such a stop. Whether the stop complies with other regulations is judged by those rules, and a non-standing halt gets the same verdict here either way.
- **What would reverse this:**
  - a label that treats a short passenger stop that breaks another regulation as a violation of this section; or
  - an accepted operator for "in compliance with law" (gap G22). The span would then become a composition.

**`LVMC_11_60_090`.**
- **Subject:** "cab" has no applicable definition in the table, so it maps to `ru.taxicab`.
- **"stand":** the table resolves it to DEF-NRS-484A-250, which defines the *act* of halting. Here the word is a noun for a place, so the element maps it to the `taxicab_stand` curb zone and says why.
- **The sign:** a `right_turn_only` regulatory sign that governs the region the cab occupies as it leaves the stand, with its conditions holding for the cab (status reading).
- **Obligation:** at the exit from the first intersection after leaving the stand, `drv.motion.right_turn_through_region` holds.
  - "First" is written as: no other intersection occupied *since* the departure from the stand with the sign condition.
  - The occasion is boundary `event`: onset at entry into r, recognition at exit.
  - All trigger and condition spans are read `at_recognition`, looking back to the departure. None is read while the turn is under way, so there are no occasion scenarios.
- **What would reverse this:** a source or label where the notice sign is recorded as governing the intersection rather than the cab's lane, or as a sign kind other than `right_turn_only`.

**`NRS_484A_450_2` (stop sign; approach convention, rule 4c).**
- **Trigger:**
  - Entry into intersection r, through a carrier c that `st.lane_enters` r, where a stop sign governs c.
  - "before entering the intersection" is the event span.
- **Obligation:** one span, holding the three ordered places, each read through c:
  - the crosswalk marking c (`st.entrance_of`), halting off it and short of it within `p.stop_point_tolerance`;
  - else the stop line marking c;
  - else c's entrance end at r.
- **History bound:** the obligation text states it in full — the search back to the approach start or the previous entry, what begins a new approach, and where missing evidence leaves the verdict unknown.
- **The view clause:** "where the driver has a view of approaching traffic" is disclosed as a reading on the obligation span.
  - The point nearest the intersecting highway before entering is the intersection's edge, and the view along that highway is widest there.
  - So the edge within the tolerance is read as that point, and `st.sight_along_way` is not compared with a bound.
  - **What would reverse this:** a label that counts a halt at the edge with an obstructed view as non-compliant (or a halt farther back with a view as compliant). That would need a sight-distance parameter.
- **Stop sign governance:** a stop sign that governs only the intersection is not read as facing c. Otherwise through traffic would owe a stop.
- **Scenarios:** besides the standard ones, branches cover each place and a halt far back, plus `history_boundary`.

**`NRS_484A_450_3` (yield sign).**
- Same structure as 450-2, with a yield sign governing c.
- **"if required for safety to stop"** is a standard, operationalized with the traffic-conflict technique:
  - At some observation of the approach, another road user of traffic on a highway is on a closest approach with the subject within `p.conflict_horizon`, at a centre distance below `p.conflict_centre_clearance`.
  - If no such observation exists, the duty does not arise.
  - Not a surrogate: the standard qualifies a concrete duty.
- **Traffic aggregate:** claimed on the obligation span, whose words name "approaching traffic". The validator rejects an aggregate id inside an operationalization's concept list.
- **What would reverse this:** a label requiring a stop at a yield sign only for a conflict at the moment of entry. The window would then move to the observation before entry.

**`NRS_484B_110`.**
- **Subject:** vehicle aggregate.
- **"shall at any time be driven"** is the trigger: the vehicle is moving (not `complete_halt`), an agency reading.
- **Obligation:** its footprint overlaps no `st.safety_zone`.
- A vehicle at rest is idle.
- **What would reverse this:** a label that counts a vehicle standing inside a safety zone as violating. The rule would then drop the motion trigger.

**`NRS_484B_113_2`.**
- **Applicability:** the vehicle is backing (`drv.motion.moving_backward`).
- **Obligation (one span):** none of the following holds:
  - its footprint comes to overlap an intersection (backing *into* it);
  - it overlaps a crosswalk;
  - it occupies an intersection and its heading has changed by at least `p.turn_heading_min` since backing within that intersection began (`Term.headingSince`), which is "around a street corner".
- **Disclosed readings:**
  - Backing straight out of an intersection is not "into" it.
  - The city-limit qualifier in the definition of "street" is not read for the corner (noted as a broadening).
- **What would reverse this:** a label that treats any backing inside an intersection as backing into it.

**`NRS_484B_113_3`.**
- **Applicability:** the line is subsection (3) of "Limitations on backing", so "in every case" is read as every case of backing. Applicability is the vehicle backing. This is disclosed on the obligation span, because reading it everywhere would require every vehicle always to yield.
- **Standard:** "the right-of-way" (DEF-NRS-484A-210, "danger of a crash"), operationalized with the closest-approach primitives and the conflict parameters.
- **Who is yielded to (condition span):**
  - moving traffic: the traffic aggregate, on a highway, not at rest;
  - pedestrians: the pedestrian aggregate, moving or not, because moving pedestrians are already traffic.
- **What would reverse this:**
  - a corpus decision that the line binds forward driving too; or
  - a label showing that "moving" also qualifies pedestrians.

## Mapping reuse and departures

- The following reuse their index mappings:
  - "The operator of a bus,"
  - "other than a tour bus,"
  - "The driver of a vehicle"
  - "No vehicle"
  - "upon any street"
  - "approaching the intersection" (plus the sign)
- "such vehicle" in LVMC-11-60-040 also claims the vehicle aggregate, because the word is the defined term. The taxicab carries it.

## For the operator

- **Gap `dev.posted_duration_limit` (LVMC-11-60-030(A)(5)).**
  - The sign `conditions` attribute already lists "a duration limit" but no §11 measure exposes it.
  - Adding a measure (for example `dev_zone_sign_duration_limit`, in s) would unblock this law. It would also unblock any time-limited parking posting.
- **`p.halt_speed_tolerance` and friends.** Parameters re-proposed here with the values and conventions already proposed this iteration:
  - `p.halt_speed_tolerance`
  - `p.standing_min_duration`
  - `p.stop_point_tolerance`
  - `p.conflict_horizon`
  - `p.conflict_centre_clearance`
  - `p.turn_heading_min`
  - `p.u_turn_heading_min`
- **Stop and yield sign governance.** The NRS 484A.450 nodes read a sign only where the source records it governing the approach carrier. A source that records only junction-level governance will make these rules not applicable on such approaches.

<!-- batch-09 -->
# Plan — batch 09 (iteration 001)

There are nine nodes for eight law lines. There are no law-local aggregates, so `aggregates.jsonl` is empty. There are no new concept records. The plan reuses `drv.motion.complete_halt` and `drv.interaction.overtake_pass`, which an earlier batch proposed. The validator accepts every node. Two nodes carry gaps and will not be coded until those gaps are decided: `NRS_484B_117_1` and `NRS_484B_127_3`.

## NRS_484B_117_1 — driving on a sidewalk (carries gaps)

**What the node judges.** The subject is a vehicle (the aggregate `DEF-NRS-484A-320::vehicle`) that overlaps a sidewalk.
- **Violation:** at any observation where the vehicle is moving (not `drv.motion.complete_halt`) on the sidewalk without also overlapping a `st.driveway_or_alley_entrance`.
- **Two reading choices:**
  - "Drive" is read as not being at rest.
  - "Permanent or temporary" excludes nothing, because the entrance kind covers both.
- **Mapping difference:** this differs from LVMC_11_20_060_o1, which maps "driving onto a sidewalk" with `st.region_geometry`. These words name no distance, so occupancy alone carries them.

**Why it is blocked.** The subsection 2 exception cannot be carried by any atom:
- "powered solely by electricity and designed to travel on three wheels" → gap `ru.electric_three_wheeler`.
- The operator's role and duty ("officer … of a law enforcement agency", "security guard", "in the course of … official duties") → gap `ru.operator_role`.
- A role a person holds is never an assumption, and it is not one of the observable-reading categories.
- A vehicle class (`ru.emergency_vehicle`, `ru.official_vehicle`) is not the role of the person driving.

**Other spans.**
- The two "as that term is defined" spans are `definition` references, quoting DEF-NRS-239C-065 and DEF-NRS-648-016.
- The penalty sentence is `boilerplate`: it states a sanction, not conduct.
- "Except as otherwise provided in subsection 2" is a scope-`none` residue: subsection 2 is in this same line and its own spans carry it.

**Reversal signal:** the operator retires either gap with an atom, or rejects it with a reading that permits a class stand-in.

## NRS_484B_127_1 — following too closely (surrogate)

**Why it is a surrogate.** "Reasonable and prudent" is the whole duty, so any bound on it is a policy choice.

**The bound.** The longitudinal body gap to every vehicle ahead in the same lane must be at least:
- the subject's speed × a headway H, **plus**
- (subject speed² − leader speed²) / (2 × a deceleration D).

**How the factors are read.**
- The speeds of both vehicles enter the bound by degree.
- The surface condition picks H and D:
  - ice or snow (`env.ice_or_snow`) → the `_ice` pair;
  - otherwise a wet road or falling rain (`env.wet_road`, `env.precipitation`) → the `_wet` pair;
  - otherwise → the `_dry` pair.
- Narrowing: "the traffic upon the highway" is read only through the followed vehicle. The traffic aggregate is therefore not claimed, and the validator accepts this.

**Party-free case:** a vehicle with no one ahead → compliant.

**Reversal signal:** a labelled case where traffic density, rather than the leader's speed, decides the verdict.

## NRS_484B_127_2 — wide truck following a wide truck: leave 500 ft

**Who it binds and when.**
- The subject is a truck or a combination of vehicles (admitted aggregates) whose full width (`kin.extent`) is at least 80 in.
- It follows such a vehicle immediately ahead in its lane, with no road user between them.
- **Exemption:** if the subject's lane counts two or more lanes in its direction, the rule does not apply.

**What it requires.** One of these must hold, or the node reports a violation:
- the body gap is at least 500 ft; or
- conditions do not permit; or
- an overtaking pass by the subject (`drv.interaction.overtake_pass`) is recognized within the window ahead (`p.overtake_window`).

**How "whenever conditions permit" is read.** Conditions permit the space when, for the whole window `p.truck_space_open_time`:
- the leader has been the subject's immediate leader, and
- neither vehicle has been at rest.

The purpose clause ("so that an overtaking vehicle may enter …") is a disclosed narrowing on the obligation span: the duty is the stated space.

**Reversal signal:** a recording where a queue moving slowly at below the window's duration is labelled a violation.

## NRS_484B_127_3 — caravan spacing (carries a gap, surrogate)

**Why it is blocked.** I kept gap `smoke31-1111-0039:G17` (`ru.procession_member`) on "in a caravan or motorcade", because it is still pending. Following and same-direction relations cannot tell a procession from ordinary traffic.

**Everything else is planned.**
- "Outside of a business district" is the negation of `asm.business_district`.
- "Whether or not towing" is a scope-`none` residue.
- **Sufficient space** is at least: design-combination length + 2 × speed × headway.

**Reversal signal:** the operator decides G17.

## NRS_484B_153_2 — opening a door into traffic

**Who is judged.** The person is read through the vehicle's traffic-side door (`sig.door_open`, side traffic). This is an agency reading, and it is the same subject mapping LVMC_11_22_010 gives "A person". Boarding and alighting are read through that same open door.

**What counts as interference.** Some moving vehicle of the traffic either:
- touches the subject, or
- is alongside it with a lateral body gap within `p.door_swing_reach`.

A vehicle that brakes or swerves earlier to avoid the door is not read (disclosed narrowing).

**Party-free case:** a door open with no traffic → compliant.

## NRS_484B_153_3 — leaving a traffic-side door open

**The bound.** A violation is reported where the traffic-side door has been open at every observation of the window `p.traffic_side_door_max_open`.

**Disclosed narrowing.** Whether loading is going on, and whether it is passengers or cargo, is a purpose that cannot be observed. It is read as this one duration bound.

**Reversal signal:** labelled cargo deliveries longer than the bound that are judged compliant. That would call for a cargo-specific bound, which needs evidence of cargo handling that no atom carries.

## NRS_484B_203_1_o1 / _o2 — vehicles meeting from opposite directions

The line holds two obligations. Each node segments the whole line and marks the other's obligation as `sibling`.

**_o1 — keep to the right.**
- The subject is a moving vehicle.
- Every oncoming vehicle on the same highway that is alongside it must lie on its left (`rel.bearing`).

**_o2 — give half the road on narrow highways.**
- It applies on highways where the subject's lane counts at most one lane in its direction.
- While an oncoming vehicle is meeting the subject (closest approach within `p.meeting_horizon`, or alongside), the subject's body must stay right of the centre line, within `p.lateral_position_tolerance`.
- "As nearly as possible" is read through the room left to the right road edge.
- The paved portion is read as the roadway the centre line divides (narrowing).

**Reversal signal:** unmarked narrow roads, where `st.lane_adjacency` is absent, that are labelled decided. That would call for a lane-free width reading.

## NRS_484B_208_1 — leaving the left lane on controlled-access highways

**Where it applies.**
- The subject is a motor vehicle in the leftmost of two or more lanes on a controlled-access highway.
- It is not an authorized emergency vehicle showing warning lamps or a siren.
- The reading does not place it within a city or town (new assumption `asm.within_city_or_town_limits`). The existing `asm.within_city_limits` means only the one city whose ordinances the reading applies, so it does not fit "a city or town".

**When it is violated.** Call the following state S: the subject is in the leftmost lane, below the posted maximum (`dev.speed_limit_sign` governing where it is), and not excused by exceptions (a)(1)–(4), (b) or (c). A violation is reported when both hold:
- **Continued too long:** for the whole window `p.left_lane_move_over_time`, S has held continuously since a faster motor vehicle was behind the subject in its lane.
- **Still followed:** a motor vehicle is still behind it at the judged observation.

The validator rejected an added closing-horizon reading on "being overtaken", so the trigger is now read as its words say.

**How each exception is read.**
- **(a)(1) overtaking:** an overtake pass (`drv.interaction.overtake_pass`) recognized within the window ahead.
- **(a)(2) left turn:** the declared intention `int.left_turn` at an intersection.
- **(a)(3) high-occupancy lane:** the subject occupies a reserved high-occupancy lane, is a high-occupancy vehicle, and `prim.conditions_hold` for the governing high-occupancy-lane sign.
  - This is the requirement DEF-NRS-484A-460-2 says those signs advise.
  - Outside the posted hours, `prim.conditions_hold` is false, so the exception does not excuse.
- **(a)(4) highway work:** a highway-maintenance official vehicle with its amber warning lamp lit.
- **(b) traffic, weather, obstructions or hazards:** the left lane is necessary where any of these falls below the same stopping distance S_stop used in NRS_484B_127_1:
  - the body gap to a traffic member in the right neighbouring lane;
  - the distance to an obstruction on the subject's right;
  - the visibility distance.
- **(c) devices and officers:** the right neighbouring lane is closed by a lane-control signal, a sign, temporary traffic control, or a police officer's stop direction.

**Readings the validator required.** Purpose words may not be carried by a road-user class alone, so:
- (a)(4) is read through the amber warning lamp;
- (d) "official duties" is read through warning lamps or a siren.

Both are stricter than the words: an on-duty vehicle that shows neither is not excused.

**Reversal signals:**
- the operator accepts NRS-484B-323-1 into the build, which would let (a)(3) compose it as compliance;
- labelled on-duty emergency or maintenance vehicles without lamps that are judged excused.

## For the operator

- **NRS-484B-323-1 is not composable.** NRS-484B-208-1(a)(3) cites it, but it is neither accepted nor planned. I carried the requirement as the qualified fact (high-occupancy membership plus the posted lane conditions), not as a composition. If NRS-484B-323-1 is coded, replanning (a)(3) as a `compliance` composition would follow the bracket exactly.
- **New gap `ru.operator_role`** (on NRS-484B-117-1). Several laws exempt road users by the role of the person driving (an officer, a security guard, on duty). The ontology has no atom for an operator's role or duty status, and a vehicle class is not one.
- **New gap `ru.electric_three_wheeler`** (on NRS-484B-117-1). No class atom states electric-only propulsion together with three wheels.
- **Shared parameters.** Several new parameters are shared across these nodes, each proposed with the same value and convention everywhere:
  - the six `p.following_headway_*` and `p.following_decel_*` parameters (NRS-484B-127-1 and the (b) exception of NRS-484B-208-1);
  - `p.halt_speed_tolerance`, `p.overtake_window` and `p.overtake_same_direction_cos` are proposed again here with their catalogue values.
- **Penalty sentence.** The NRS-484B-117-1 penalty sentence is segmented as `boilerplate`, because a sanction is not conduct a trace can check.

<!-- batch-10 -->
# Plan — batch 10 (NRS 484B.210, 484B.213, 484B.413(2))

No law-local aggregates: `aggregates.jsonl` is empty. Every class word claims its admitted aggregate
(`DEF-NRS-484A-320::vehicle`, `DEF-NRS-484A-285::traffic`, `DEF-NRS-484A-020::authorized_emergency_vehicle`,
`DEF-NRS-484A-280::tow_car`, `DEF-NRS-484A-030::bus`). "Driver" is read through the vehicle's controlled
motion (observable_reading, agency).

## New concepts

- `drv.interaction.overtake_pass_on_right` — the proposed `drv.interaction.overtake_pass` (reused by id,
  same window and heading tolerance) plus the side: b lies on a's left (rel.bearing lateral component
  positive) at recognition and at every side-by-side observation (rel.longitudinal_overlap ≥ 0) since
  the act began. Act concept, window boundary. Used by 210-1, 210-2, 210-3. *Reversal signal:* the
  reviewer finds the side should come from lane order (`rel.ahead_behind_in_lane`, `st.lane_adjacency`)
  rather than the bearing.
- `drv.lane.heading_left_of_carrier` / `drv.lane.heading_right_of_carrier` — a moving road user's
  heading turned left (right) of a carrier's designated direction by more than `sin_tol` and still
  pointing along it. These are separate concepts because a literal formal cannot pick the side. They are
  state concepts, not acts. Used by 413-2 as the onset of a course change. *Reversal signal:* junction
  turns in the traces whose heading never departs from any occupied lane (the turn follows a junction
  connector lane from its first observation), which would call for a heading-change onset instead.

## Nodes

**NRS_484B_210_1** (gap, so it is not coded). Passing on the right (`overtake_pass_on_right`, b of vehicle)
is forbidden unless one of (a)–(d) holds. Each condition is read as an exception: (a), (b), (c) and (d)
must hold `throughout` the act, and the subsection-4 exemption (the 200-ft limit of (c)(1) does not apply)
must also hold throughout for its shoulder and sign spans. (a) is read as b's left indicator or arm
signal, or b's `drv.motion.left_turn` completed within the turn window ahead. "Sufficient width for two
or more lines" is a lane count, since a lane is "a strip of roadway for one line of vehicles". (c)(1)
uses `Term.distanceWhile` on the unmarked pavement (a paved shoulder, or roadway outside every lane)
against the literal 200 ft. Subsection 4's "Except as otherwise provided" pointer is a scope-none residue,
because its content is carried by spans s12–s21. The references to NRS 484A.480 and 484A.490 are
residues: those laws are outside the corpus. **Gap:** "past any private way that is used to enter or exit
the highway". `st.driveway_or_alley_entrance` is expressly not a stand-in for telling an alley's
entrance from a private road's or driveway's. Under DEF-NRS-484A-190 a private way excludes an alley,
and an alley is a public highway, so the distinction decides whether passing an alley mouth on the
shoulder is permitted. I proposed `st.private_way_entrance`. *Reversal signal:* an ontology revision
adds a kind attribute to the entrance atom that separates a driveway or private road from an alley.

**NRS_484B_210_2** (surrogate). The movement is "in safety" when, throughout the right-side pass, no
road user is in contact with the subject and none has a constant-velocity closest approach within
`p.conflict_horizon` closer than `p.conflict_centre_clearance`. It is marked surrogate because the
safety standard is the whole content of the duty: the act itself is lawful under 210-1. *Reversal
signal:* the operator classes "conditions permitting ... in safety" as a qualification of a concrete
duty, as in a hazard-qualified yield. That would drop the surrogate flag and change no formula.

**NRS_484B_210_3.** The duty is violated if, at some moment of the right-side pass, the subject's
footprint overlaps a shoulder with `paved` unset or a road edge whose surface beyond is unpaved. The
condition span is read `some_moment`. "Requires" is read through the movement as made. *Reversal
signal:* a label that counts a pass needing, but not making, a move off the pavement.

**NRS_484B_213_1.** The obligation span is one cut covering left of the centre line, the two-lane
two-directional highway and the act of overtaking (`drv.interaction.overtake_pass`). The validator
requires one obligation span holding the act. A pass on a wider road is therefore compliant, not
not-applicable. Left of centre means `prim.region_lateral_offset` to the `st.centre_line` on the
occupied highway is negative. Two-directional means a centre line lies on the way, which by its
contract divides one two-way roadway. Two-lane means one lane in each direction (`st.lane_adjacency`
count). The exception spans are read throughout the act, at the observations on the left side:
- the sight distance at the subject's point is at least its speed × `p.passing_sight_time` (MUTCD
  Table 3B-1 passing sight distance ÷ speed);
- every oncoming member of traffic is at least that far away;
- there is no conflict (contact, or a closest approach within `p.conflict_horizon` closer than
  `p.conflict_centre_clearance`) with an oncoming vehicle or with b.

*Reversal signal:* labels that judge visibility only at the start of the pass, which would read the
exception at the act's beginning instead.

**NRS_484B_213_2a / 2b / 2c.** These are three state rules with one obligation: the subject's reference
point is not left of the centre line of the highway it occupies. A one-way roadway exempts it in each.
- 2a applies where the subject is approaching a crest or is on a curve, and the sight distance is
  below speed × `p.passing_sight_time`. Approaching a crest means the velocity points toward the
  crest's reference point and the crest is within that same distance. On a curve means `st.curvature`
  is above `p.curvature_resolution`, the feature's presence.
- 2b applies within the literal 100 ft of an intersection or railway crossing while moving toward it,
  or while overlapping it.
- 2c applies within 100 ft of an `st.elevated_structure`, while moving toward it, with the view
  obstructed. That span is a standard bounded by the same passing-sight-distance convention.

"Approaching" is read by the velocity toward the region, not by `st.lane_enters`: a vehicle on the left
side occupies the opposing lane, which does not enter that junction. *Reversal signal:* a reviewer who
reads the crest or structure "approach" through an along-carrier offset (`prim.region_offset_along`).

**NRS_484B_413_2.** The trigger is a course change: the rise of `heading_left/right_of_carrier` for an
occupied lane. It is read only where the subject occupies a lane (definedWhen), and is unknown
elsewhere. The obligation is that the matching-side indicator or arm signal held at every observation
of a `.path` window. The window is the literal 100 ft where `asm.business_or_residence_district` holds
and the literal 300 ft where it does not (`Term.cond`). The words fix their own window, so this is not a
rule-4c search and has no history_boundary scenario. "Regardless of the weather" is a scope-none
residue. The window lengths are cut as condition spans so that the node carries one obligation span.
*Reversal signal:* a label that counts a turn signalled by its indicator only after the heading began
to turn.

## For the operator

- Gap on 210-1 s10 (`st.private_way_entrance`): the entrance atom cannot tell a private way from an
  alley. This blocks NRS-484B-210-1 only.
- New parameters proposed: `p.passing_sight_time` (11 s, MUTCD Table 3B-1),
  `p.curvature_resolution` (0.0005 1/m), and `p.course_departure_sin_tol` (0.035). The other
  parameters re-propose the values earlier batches proposed, unchanged.
- `rel.bearing` carries the unit m and gives no sign convention for its lateral component. The
  on-the-right concept assumes left is positive, as `prim.region_lateral_offset` states. A source
  with the opposite sign would swap the sides.

<!-- batch-11 -->
# Plan — batch 11 (NRS 484B.217(2)–(4), 484B.220, 484B.223)

No law-local aggregates (`aggregates.jsonl` is empty). Two new concepts are proposed:
`drv.motion.moving_against_carrier` and `drv.lane.entering_adjacent_lane`. All nodes and concepts
pass the validator (`accept`).

## NRS_484B_217_2

**Decision.** This is one node. Its one obligation span is "shall not drive on the left side of
the highway within such zone or drive across or on the left side of any pavement striping…".
- **Zone membership.** "Such zone" is the no-passing zone that subsection 1 lets an authority
  mark "by signs or markings". A vehicle is in the zone when either holds:
  - it occupies a travel region governed by a `dev.zone_sign` of kind `no_passing` that is not an
    end sign; or
  - the left `st.lane_marking` of its lane is a solid or double solid yellow line.
  - Where that marking is `solid_broken`, the atom does not say which side the solid half is on,
    so membership is unknown.
- **The breach.** Driving on the left side of the highway and crossing the zone striping are
  read as one fact: the body reaches past the centre line. That is, the
  `prim.region_lateral_offset` of `st.centre_line` is below half the `kin.extent` width minus
  `p.lateral_position_tolerance`. This reuses the index's mapping for NRS_484B_213_2a.
- **Subsections 3 and 4 are this line's own exceptions.** So "Except as otherwise provided in
  subsections 3 and 4" is boilerplate.
- **(3), crossing to an adjoining highway.** The vehicle reaches another highway within
  `p.vehicle_turn_window` (observable_reading `purpose`). It must also have given a left signal
  at the observation before the crossing, and there must be no closest-approach conflict with
  oncoming or following members of `DEF-NRS-484A-285::traffic`.
- **(4), crossing to make a left-hand turn.**
  - The vehicle has a declared `int.left_turn` at an intersection or driveway entrance.
  - It gave the left signal, and NRS_484B_413_2 is complied with (a `compliance` composition on
    the reference span).
  - "Safe" and "no impediment" are operationalized with the conflict technique
    (`p.conflict_horizon`, `p.conflict_centre_clearance`).
  - "Except where otherwise provided" names no rule, so it is a residue of scope `none`.
- **Subject.** "A driver" maps to `DEF-NRS-484A-320::vehicle` with an `agency` reading, as the
  index maps "the driver" (LVMC_11_16_030). The table lists no vehicle row for this law. The
  driver definition borrows "vehicle" ("drives … a vehicle").
- **Disclosed narrowing.** Zone striping is read only where it lies along the centre line. A
  no-passing line between two lanes of the same direction is not read.

**Reversal signals.**
- Labels that treat a lane-line no-passing stripe as the zone striping.
- A selection-role ruling that the vehicle aggregate may not be claimed for "driver" here.
- A source whose `solid_broken` record states the solid side.

## NRS_484B_220_1

**Decision.**
- The condition is a `st.one_way_roadway` the vehicle occupies. "Designated and signposted" is an
  observable_reading of category `status`: the one-way roadway's presence is the evidence.
- The obligation is that new concept `drv.motion.moving_against_carrier(subject, r)` does not
  hold. Its `speed_tol` is `p.halt_speed_tolerance`.
- Velocity across the direction, as when entering or leaving the roadway, is not a breach. This
  is a disclosed reading.
- "Traffic" is claimed as the admitted aggregate on the condition span. This follows the index's
  "(d) Upon any highway on which traffic is restricted…".

**Reversal signals.**
- Labels that require a recorded `one_way` sign.
- Labels that count backing along a one-way roadway as compliant.

## NRS_484B_220_2

**Decision.**
- The vehicle occupies a `st.roundabout`. Driving "to the right of such island" means that
  `drv.motion.circulating_clockwise_about(subject, r)` does not hold. This is the concept the
  index maps for LVMC_11_43_010_A.
- The island's centre is read as the roundabout's reference point. This is a disclosed reading.
- "Traffic" in "rotary traffic island" names a structure, not the road users the duty turns on,
  so the traffic aggregate is not claimed. The validator accepts this.

**Reversal signal.** A roundabout whose reference point is not its island centre in the
source's maps.

## NRS_484B_223_1b

**Decision.**
- The condition is the subject's lane, with a `st.lane_adjacency` count of at least the literal
  2. "Clearly marked" is a `status` reading.
- The obligation span covers both "Not be moved from that lane" and "until … appropriate turn
  signal". The validator requires one obligation span per node.
- The move is the new event concept `drv.lane.entering_adjacent_lane(subject, l1, l2, side)`.
  Its literal side is matched with `sig.turn_indicator` or `sig.hand_signal` of the same side.
  The signal is read at the move and at the observation before it.
- "Ascertained that such movement can be made with safety" is a `perception` reading of the
  outcome. Safety is operationalized as no contact and no closest-approach conflict at the onset
  of the move.

**Reversal signal.** Labels that require the signal for a duration, which would call for
composing NRS_484B_413_2. The words here do not name that rule.

## NRS_484B_223_3a

**Decision.**
- The vehicle occupies a `st.centre_turn_lane`. Its presence there is excused in either case:
  - **"From the highway":** a declared `int.left_turn` at an intersection or driveway entrance.
  - **"Onto the highway":** the vehicle has stayed in the lane since a `drv.motion.left_turn`
    recognized there, and some observation in the turn window before that turn found it off
    that highway. This is a `purpose` reading through conduct.
- An intention cannot carry the "onto" case: once the turn has been made, the plan declares it
  false.

**Reversal signal.** A source that declares intentions for completed turns.

## NRS_484B_223_3b

**Decision.**
- The duty is judged when a `drv.motion.left_turn` is recognized whose window shows that the
  vehicle came out of the centre turn lane.
- At the last observation in that lane, the continuous run in it (`Term.distanceWhile` over
  `rel.occupies`; claims `kin.path_length`) must be at most the literal 200 ft.
- A run that began before the recording is unknown.

**Reversal signal.** Labels that judge the travel before an intended turn that has not yet been
made. That reading would need `int.left_turn` in place of the act.

## NRS_484B_223_3c

**Decision.**
- The run is in the centre turn lane since a left turn recognized there, after the vehicle was
  off that highway within the turn window. Its `distanceWhile` must be at most the literal
  50 ft.
- "Merging" ends when the footprint leaves the lane. Distance travelled while straddling counts;
  this is a disclosed reading.

**Reversal signal.** Labels that end the count when the vehicle first overlaps the through lane.

## NRS_484B_223_4a

**Decision.**
- The vehicle occupies a `st.turn_lane` of side `right`. Its presence is excused only by a new
  declared intention `int.right_turn` at an intersection or driveway entrance.
- `int.right_turn` mirrors the catalogue's `int.left_turn`. "For the purpose of making a right
  turn" is intention to turn, so no act read ahead may carry it.

**Reversal signal.** None in the words. A source with no plans makes the rule unknown by
design.

## New parameter

`p.vehicle_turn_window` (10 s) is used by 217(2), 223(3)(a), 223(3)(b) and 223(3)(c). The
catalogue's `p.turn_window` is not used, because its convention is the turn of a bicycle or a
scooter.

## For the operator

- **No-passing striping.** `st.lane_marking` `solid_broken` does not say which side is solid. A
  no-passing striping is therefore unknown for a lane with that marking.
- **Composition on NRS_484B_413_2.** NRS_484B_217_2 composes NRS_484B_413_2, which is planned
  this iteration and not yet composable. Its coding waits on that node's publication.
- **"Driver" in NRS 484B.217(2).** The defined-terms table lists no vehicle aggregate for this
  law. The plan claims `DEF-NRS-484A-320::vehicle` for "a driver" through the driver
  definition's own words "drives … a vehicle".

<!-- batch-12 -->
# Plan — batch 12 (iteration 1)

Eight law lines, fourteen nodes. No new concepts, no law-local aggregates (`aggregates.jsonl` is empty), no gaps. Every node calls concepts this iteration has already proposed (`drv.motion.complete_halt`, `right_turn_through_region`, `left_turn`, `u_turn`, `moving_against_carrier`) by id. Every yield duty uses the same conflict reading: the subject breaks the duty when it touches the protected vehicle (`rel.contact`), or when it keeps moving (`kin.speed` above `p.halt_speed_tolerance`) while the two centres' closest approach falls within `p.conflict_horizon` at a distance below `p.conflict_centre_clearance`. "Right-of-way" (DEF-NRS-484A-210, "danger of a crash") and "immediate hazard" are standards. Each is operationalized with these primitives and parameters, and none is a surrogate. "Shall yield" and "yielding" reuse the index mapping (`kin.speed`, `rel.contact`). The drivers named in each node are read through the vehicle's controlled motion (`observable_reading`, agency).

The stop-before-entry duties (250-4 o1, 257-1 o1, 257-2 o1) follow the ontology's approach convention (rule 4c):
- **Event:** the subject's entry into X from a carrier `c` that `st.lane_enters` X.
- **Place:** a stop line marking `c`, else the crosswalk marking `c`, else `c`'s entrance end.
- **Search bound:** the search runs back to the approach start or to the previous entry. Each of these nodes has a `history_boundary` scenario.

The stop is DEF-NRS-484A-255. Its scope is a stop "when required". DEF-NRS-484A-260 governs stopping where it is prohibited, so it does not apply here. "The point nearest the intersection where the driver has a view of approaching traffic" is read as `c`'s entrance end. This is a perception reading: the view is read through the place the words describe, and no sight distance is measured. Reversal signal: a labelled scene where a halt at the edge of the intersection is judged non-compliant because the view was blocked there. That would require `st.sight_along_way` and a new sight parameter.

## NRS_484B_223_4b
The duty is: from the right-turn-only lane, do not pass through the intersection; the passage must be a right turn. It is judged at the exit from X using `drv.motion.right_turn_through_region(subject, X)`. That concept's onset is the entry into X and it is recognized at the exit; the occasion uses `boundary: event`. "While being driven in the right turn lane" is read `some_moment`, because at the entry the footprint overlaps the lane L and X together. The trigger (a right turn lane on the highway) is a fixed feature of the map, so it is read `at_recognition`.

"A single right lane" keeps the index mapping from 223-4a (`rel.occupies`, `st.turn_lane`). "Single" is read as "one lane": `st.lane` is "a strip ... for one line of vehicles". It is not read as a count of right turn lanes.

Reversal signal: a labelled dual right-turn approach judged out of scope.

## NRS_484B_227_1_o1 / _o2 / _o3
There are three obligation spans:
- **o1, "only upon the right-hand roadway":** the subject must not move against the designated direction of any roadway of the divided highway it occupies (`drv.motion.moving_against_carrier`).
- **o2, "over, across or within any dividing space":** the footprint must not overlap a `st.median_or_divider` on the highway.
- **o3, "left turn, semicircular turn or U-turn":** `drv.motion.left_turn` or `drv.motion.u_turn`. A semicircular turn is a reversal of direction, so it falls in the u_turn band.

"Divided highway" (DEF-NRS-484A-070) is read as a highway with a divider lying on it (`st.on_way`). The exception (an opening, or a crossover or intersection) is read as the footprint overlapping a divider region that has the `opening` attribute, or an intersection lying on the highway. The exception applies to all three nodes: o1 also needs it, because a vehicle crossing at an opening or intersection briefly moves across the opposing roadway.

In o3 the trigger and both exceptions are read `some_moment` within the turn window. A turn "through" an opening or "at" an intersection passes through that place for part of its path. Reading the exceptions `throughout` would excuse no turn, since every turn begins on the approach roadway. The turn window is `p.vehicle_turn_window`.

Reversal signal: a source that draws median openings as gaps rather than as divider regions. o2 is unaffected by this; o3 would then need the opening to be a region of its own.

## NRS_484B_250_4_o1 / _o2
**o1** is the stop. The trigger is the entry into X under a governing `dev.traffic_signal` that is `dev.inoperative` at that observation. The signal is "installed ... uncovered ... inoperative", which matches the contract of `dev.inoperative` word for word. "Proceed as if a stop sign had been erected at each entrance" and the list of places that follows form one obligation span.

**o2** is "proceed cautiously, yielding". It applies while the subject is in X after an entry made under an inoperative signal. Two cross-references:
- **Referring span:** "After making such a stop" (p1). **Defining span:** o1's obligation. p1 is carried as compliance with `NRS_484B_250_4_o1`, read at the subject's entry. o1 is engaged at exactly that observation, so compliance there means the stop was made at its place. The weaker fact "some halt on the approach" is not used. Branch 3 shows that omitting the stop makes o2 not applicable; the omission is judged by o1.
- **"Vehicles which have previously completed a stop":** another vehicle that halted on its own approach carrier before the subject's own halt (the order of a four-way stop), and that has stayed on its approach or in X since.

"Cautiously" is read only through the yielding joined to it (a narrowing on the standard span). Reversal signal: a label requiring a lower crossing speed when no vehicle is in conflict.

## NRS_484B_250_1 and NRS_484B_250_2
**250-1:** while the subject approaches X (it occupies a carrier entering X), it yields to a vehicle that has continuously occupied X since leaving a carrier on a highway on which the subject's carrier does not lie.

**250-2:** "enter ... at approximately the same time" is read as both vehicles arriving at the intersection's edge (body within `p.stop_point_tolerance`, which is a "standard" span operationalized with the new parameter `p.same_time_arrival_window`). The reason: a vehicle that yields at the edge never enters together with the other, so reading the footprint's entry would make the duty disappear exactly when it is performed. "On the right" is read with `rel.bearing` at the later of the two arrivals.

The controlled-intersection exception reuses the index mapping from LVMC 11.16.040 (signal, stop sign or yield sign governing X or one of its entrances).

The opposite-direction / left-turn exception is applied per pair of vehicles:
- Approach direction is read through each carrier's `st.lane_direction`, as `rel.oncoming`'s exclusion clause requires (`p.oncoming_heading_cos`).
- "Intending to" is the declared intention `int.left_turn` at X (reused id).
- "Is making a left turn" is a heading change since entering X, computed with heading-since over `kin.yaw_rate` and step `p.heading_since_step_carla_scene_graph`, between `p.turn_heading_min` and `p.u_turn_heading_min`.

**"Except as otherwise provided in subsection 4":** subsection 4 concerns only signal-controlled intersections, so the carve-out keeps subsection 4 itself in force. It does not reopen subsections 1–2 at those intersections. The span is therefore composed `as: exception` with `NRS_484B_250_4_o1` and `_o2` (one composition per node of the named rule). This adds nothing beyond the controlled-intersection exception, and is consistent with it. Reversal signal: an operator reading that 250-1/250-2 also apply at an intersection with an inoperative signal. The fix then is `as: unless` scoped to span h/j, with a rule whose engagement covers the approach.

## NRS_484B_253_o1 / _o2
**o1:** the subject is in X and declares `int.left_turn` at X. It yields to vehicles approaching from the opposite direction, read through the carriers' directions, that are within X or are an immediate hazard (a standard operationalized by the conflict primitives).

**o2:** "the drivers of all other vehicles approaching ... from the opposite direction" yield to the turning vehicle t. o2 has three cross-references to words stated elsewhere:
- **"Such driver" (spans a–c):** t is in X and declares `int.left_turn`.
- **"Having so yielded" (span i, defining span is o1's obligation):** composed as compliance with `NRS_484B_253_o1` (binder `subject ↦ t`), read at the observation where t's current movement in X began (its entry, or its start from rest). Reading it at the current observation would be circular: once the opposing vehicle closes in, t is "not yielding" by the same symmetric bound.
- **"Having given a signal when and as required":** a left indicator or left arm signal given at some point after t came onto its approach carrier. The signalling rule `NRS_484B_413_2` is listed as not composable, so its distances are not composed or inlined.

Branch 1 shows the verdict changing on the weaker fact: a t that did not yield is not protected. Reversal signal: `NRS_484B_413_2` becomes composable. Span j should then be composed `as: compliance`.

## NRS_484B_257_1_o1 / _o2
The exceptions are "traffic ... controlled by a police officer", read as `dev.human_direction` with role `police_officer` governing the approach or X, and "a traffic-control signal", read as an operating signal (not `dev.inoperative`). Both are read at the entry. They claim the admitted traffic aggregate, of which the subject is a member.

**o1:** at a stop sign, the act is a complete halt at the place. At a yield sign it is "slowed or stopped", the words of the next sentence: `kin.speed` within the place's stopping zone at or below the new parameter `p.yield_line_speed_max`. That is the speed from which the car can still halt within the stop-point tolerance.

**o2:**
- **Referring span:** "After having stopped or ... slowed or stopped". **Defining span:** o1's obligation. It is composed as compliance with `NRS_484B_257_1_o1` at the entry, as in 250-4.
- **"Such through highway"** (DEF-NRS-484A-275) is read from the devices: a highway X lies on, other than the subject's, none of whose entrances into X has a stop or yield sign.
- **"During the time such driver is moving across or within":** the subject occupies X and `kin.speed` is above the tolerance.

Reversal signal: a labelled scene where a driver who ran the stop sign is judged on the yield. That would turn j into an order word rather than a referenced act.

## NRS_484B_257_2_o1 / _o2
**o1:** stop in obedience to, or yield in compliance with, the sign governing the subject's own entrance. "In compliance with the manner prescribed in subsection 1" is composed as compliance with `NRS_484B_257_1_o1`, and the same place search is written out. "Prior to entering an intersection" is the trigger: the entry is the event.

"Although not a part of a through highway" is a concessive, carried as a residue of scope `none`. The duty at a signed entrance is the same whether or not the intersection is part of a through highway, and subsection 1 states the same act where it is. Reversal signal: an operator reading that excludes through-highway intersections from subsection 2.

**o2:** "proceed cautiously, yielding to vehicles not so obligated". This means vehicles whose approach carrier, and X itself, is governed by no stop or yield sign, and that are within X or are an immediate hazard, while the subject moves within X. Branch 2 (an all-way stop) shows that a vehicle under its own stop sign is not protected.

## For the operator
- **New parameters proposed:**
  - `p.same_time_arrival_window` (s): a two-second-rule headway, for "approximately the same time".
  - `p.yield_line_speed_max` (m/s): the speed from which a passenger car halts within the stop-point tolerance at a comfortable deceleration.

  Their values are in the nodes' `param_proposals`.

  All other parameters are proposed again with the values and conventions already recorded this iteration.
- **Compositions to nodes of this batch:** the validator accepted compositions to nodes planned in this same batch (`NRS_484B_250_4_o1/_o2`, `NRS_484B_253_o1`, `NRS_484B_257_1_o1`). Their build order follows the composed nodes.
- **`dev.governs` on an intersection:** the controlled-intersection readings assume a source that writes `dev.governs` on either the approach carriers or the intersection. If it writes neither, every "controlled" exception is unknown.

<!-- batch-13 -->
# Plan — batch 13 (iteration 001)

Ten nodes for eight law lines. No concept is proposed: the nodes reuse `drv.motion.complete_halt`, and everything else is written with atoms and primitives. No law-local aggregate (`aggregates.jsonl` is empty). No gap. Every node is `accept` in the validator.

Some yield duties appear in several nodes: 260, 263, 267(1)(a), and the caution of 267(2)(b). They all use one representation, the mapping index's `shall yield` → `kin.speed`, `rel.contact`. The danger of a crash in the right-of-way definition (DEF-NRS-484A-210) is operationalized with the traffic-conflict pair `prim.closest_approach_within` / `prim.closest_approach_distance` under `p.conflict_horizon` / `p.conflict_centre_clearance`. These are the parameters an earlier batch proposed, and they are proposed again here unchanged. The yield is judged only while the subject moves, because a subject at rest grants precedence. "Driver" is always read through the vehicle's controlled motion (`observable_reading` / agency).

## NRS_484B_260 — entering a highway from a private way
- **Decision.** The rule judges each observation at which the moving subject straddles a `st.driveway_or_alley_entrance` region and a roadway on highway h, having come onto the entrance from off the roadway (formula `since`). At that observation, no moving vehicle on a travel region of h, with the subject ahead of it in its frame, may be in conflict or contact with the subject.
- **Private way.** "From a private way" is carried by the entrance atom plus the condition that the subject overlaps no `st.alley`. The atom's own exclusion says it cannot tell an alley entrance from a driveway, and an alley is a highway (DEF-NRS-484A-015). "Approaching" is carried by `rel.bearing` (subject ahead in v's frame) and v's speed.
- **About to.** "About to enter or cross" is an imminent movement, read by the entry itself (`observable_reading` / intention). A crossing beyond the straddle is judged through the constant-velocity closest approach at the straddle.
- **Reversal signal.** A labelled crossing whose conflict arises only after the subject has left the entrance region would argue for judging the whole crossing.

## NRS_484B_263_o1 / _o2 — entering or exiting a controlled-access highway
- **Why two nodes.** The line carries two obligation spans: "shall yield the right-of-way" and "shall continue to yield … until … reasonable safety".
- **o1.** Judged at the entry into or exit from a `st.controlled_access` region c: the rise of the subject's overlap with c, or of its non-overlap after overlap. The duty covers moving vehicles on c with the subject ahead of them, and "immediate hazard" is the conflict bound.
- **o2.** Judged at the observations strictly after that event, within the new `p.merge_window`. It concerns "that traffic", which refers back to o1's words. Those words are carried in o2 with every qualification (vehicles on c, approaching, the immediate-hazard bound) and claim the admitted traffic aggregate as well. "Reasonable safety" is read through the same conflict bound: the subject may proceed once no such vehicle is in conflict with it.
- **Reversal signal.** A source that maps entrance ramps inside the controlled-access region moves the judged entry to where the ramp begins (disclosed on a2). A labelled merge conflict that this misses would argue for an attribute that tells entrance lanes from through lanes (see the operator section).

## NRS_484B_267_1a — yield to an emergency or regulatory vehicle in immediate approach
- **Trigger.** e is either in the AEV aggregate (DEF-NRS-484A-020) or an `ru.official_vehicle` of kind `regulatory_agency`. It shows a lit warning lamp that is red, flashing and facing front. The words quote DEF-NRS-484A-480-3 as a `definition` reference: "at least one flashing red warning lamp visible from the front". The required lamp must be in use; blue, rotating or steady lamps alone do not engage the duty.
- **Immediate approach.** This is a standard, operationalized as: e moving, the subject ahead of e in e's frame, and their distance within the new `p.emergency_immediate_approach_reach`.
- **Exception.** "Otherwise directed by a law enforcement officer" reuses the index mapping: a police_officer `dev.human_direction` governs a region the subject occupies, whatever indication it gives.
- **Obligation.** While the subject moves, there is no conflict and no contact with e.
- **Reversal signal.** A labelled scene in which a police vehicle shows only blue lamps and is judged engaged would widen the lamp reading.

## NRS_484B_267_1b_o1 — drive immediately to the right-hand edge, clear of intersections
- **Why two nodes.** Paragraph (b) carries two obligations: the pull-over, and "shall not drive to and stop … on a paved shoulder … where lawfully placed signage allows …".
- **When it is judged.** At the rise of the trigger, the subject must reach the position within the new `p.emergency_pullover_window` ("immediately"). The duty ends early if e has passed (the subject behind e in its frame, with no longitudinal overlap).
- **The position.**
  - **Parallel:** the heading is within `p.curb_parallel_cos` of the occupied carrier's direction. That parameter was proposed by an earlier batch and is proposed again unchanged.
  - **As close as possible to the edge or curb (standard):** the body is within the new `p.pullover_edge_gap` of a `st.road_edge` on the subject's right, on the same highway, or the subject is on a paved shoulder.
  - **Clear of any intersection.**
  - **Not on a signed shoulder:** the subject does not occupy a paved shoulder governed by a `shoulder_use_permitted` sign. This is how the node carries "Except as otherwise provided in this paragraph".
- **Reversal signal.** A label that treats the outer boundary of the public way as "the edge of a highway".

## NRS_484B_267_1b_o2 — do not stop on a signed shoulder
- **Decision.** While the trigger holds, the subject must not come to rest (rise of `drv.motion.complete_halt`) on a paved shoulder governed by a `shoulder_use_permitted` regulatory sign. "Lawfully placed" is read through the sign's presence (`observable_reading` / status).
- **The appended list.** The list of NRS 484B.210(4) is the legend of that sign. It is carried as a `definitional` span on `dev.regulatory_sign`, and the classes it names are not read: the subject's duty does not depend on its own class.

## NRS_484B_267_1c — stop and remain until the vehicle has passed
- **"Such position".** This refers to the position paragraph (b) describes, and the words require the state itself, not compliance with 1b. So it is carried in full with 1b_o1's atoms and parameters: parallel, at the right edge or on a paved shoulder, clear of intersections, off signed shoulders.
- **Formula.** Judged at the trigger's rise: (not passed) strong-until (halted at the position, and halted at the position strong-until passed).
- **Witnesses.** Two scenarios differ only in where the subject halts: at the edge (compliant) and mid-lane (violated, `branch_1`).
- **Reversal signal.** A label that accepts a stop not yet complete when the vehicle passes.

## NRS_484B_600_1a — basic speed rule (surrogate)
- **Decision.** The standard is the whole duty, so this node is a surrogate. Each named factor is read by its degree:
  - **Surface and weather:** wet, icy and precipitation select the braking deceleration, using the earlier batch's `p.following_decel_*`, proposed again unchanged.
  - **Weather:** visibility caps the sight available.
  - **Traffic:** the assured clear distance to any road user ahead in the lane, crediting that road user's own braking distance. Any road user counts, because DEF-NRS-484A-285 counts all of them.
  - **Width of the highway:** the time-to-line-crossing bound against the occupied lane's width and the subject's width.
  - **Other conditions (catch-all):** read only through sight distance, curvature (side-friction bound) and darkness (low-beam reach).
- **Traffic aggregate.** The validator refused an aggregate id among an operationalization's concepts, so the road user ahead is unrestricted by class. That is exact under the traffic definition.
- **Reversal signal.** Labels that flag ordinary following at a reasonable headway would mean the traffic bound is too strict.

## NRS_484B_267_2a — decrease speed on approaching (subsection 2)
- **Trigger.** e is moving, or preparing to move. Preparing to move uses the section's own definition: an indication that is visible (`rel.visible`, `observable_reading` / perception) — a movement, a hand signal, or, from the open list, a turn indicator. The subject approaches e within the new `p.emergency_approach_reach`. "Arriving at or leaving the scene" is a scope-none residue: it only illustrates the moving case.
- **Reasonable speed.** "To a speed that is reasonable and proper, pursuant to … NRS 484B.600" is composed as compliance with `NRS_484B_600_1a`, which states that bound as its own obligation.
- **Decrease.** "Decrease the speed" is a deceleration beyond the new `p.speed_decrease_decel_min` before the subject draws level with e (strong until from the trigger's rise).
- **Reversal signal.** A label that counts an already slow, steady approach as compliant.

## NRS_484B_267_2b — proceed with caution (surrogate)
- **Decision.** Same trigger as 2a. Caution is a standard of the driver's care, so the node is a surrogate. It is operationalized through the clearance kept from e: no conflict, no contact, and, when side by side, a body gap of at least the new `p.emergency_pass_clearance`.
- **Reversal signal.** Labels that judge caution by speed, which 2a already covers.

## For the operator
- `st.controlled_access` has no attribute that tells its entrance or exit lanes from its through lanes. NRS 484B.263 is therefore judged where the source's controlled-access region begins and ends. If sources map ramps inside that region, the merge itself is judged only through the constant-velocity conflict at the region boundary and through o2's merge window.
- The validator rejects `ru.aggregate=<id>` in an operationalization's `concepts` list, but asks for that form when the bare atom is used. A standard whose factor is a legal aggregate ("the traffic") therefore cannot claim the aggregate. For NRS 484B.600(1)(a) this costs nothing, because the traffic definition covers every road-user class.
- New parameters awaiting review: `p.emergency_immediate_approach_reach`, `p.emergency_pullover_window`, `p.pullover_edge_gap`, `p.emergency_approach_reach`, `p.speed_decrease_decel_min`, `p.emergency_pass_clearance`, `p.merge_window`, `p.driver_reaction_time`, `p.curve_lateral_accel_max`, `p.lane_keeping_heading_error`, `p.lane_departure_time_min`, `p.low_beam_sight_reach`.

<!-- batch-14 -->
# Plan — batch 14 (NRS 484B.267(2)(c)–(f), 484B.270(1)–(2)(b), 484B.297(6))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse
`drv.interaction.overtake_pass`, `drv.lane.heading_right_of_carrier` and `drv.motion.complete_halt`,
all proposed earlier this iteration.

## Shared reading of NRS 484B.267(2)

All five 267(2) nodes use the same cut of the common lead-in.

- **s1, trigger.** The opening words through "in any direction" form one span. It carries the
  approach and the vehicle's class: the admitted authorized-emergency-vehicle aggregate or
  `ru.official_vehicle` of kind `regulatory_agency`. It also carries the vehicle's state, moving or
  preparing to move. This keeps the occasion scenarios of 2d to four spans.
- **Approach.** The subject is moving and has the vehicle ahead (`rel.bearing`), within
  `p.emergency_approach_reach` (`rel.centre_distance`). This reuses the atoms and parameter of
  NRS_484B_267_2a's "Upon approaching".
- **Preparing to move.** The section defines this as a visible indication. It is read as
  `rel.visible` plus an arm signal or a lit turn indicator, or as the vehicle's own movement. The
  intention and perception readings are disclosed on s1, because the validator does not accept a
  narrowing on a definitional span.
- **Flashing lights.** The words "subsection 3 of NRS 484A.480" are a `definition` reference to
  DEF-NRS-484A-480-3. They borrow "at least one flashing red warning lamp visible from the front",
  so the lamp is `sig.warning_lamp` red, flashing, facing front.
- **Examples.** The "arriving at or leaving the scene" list adds no restriction and is a residue
  with scope `none`.
- **Officer exception.** The officer is `dev.human_direction` of role `police_officer`, governing
  a travel region the subject occupies.
- **Reversal signals.**
  - A labelled case where the vehicle approaches from behind and the label expects 267(2) to apply
    would widen the approach to mutual closing, which needs `kin.velocity`.
  - A case where a blue-only light bar triggers the duty would drop the colour constraint.

## Nodes

**NRS_484B_267_2c — accept.**
- **Decision.** "Be prepared to stop." is the whole obligation and has no observable meaning of its
  own. It is a surrogate. The subject's stopping distance (reaction plus braking, deceleration
  chosen by ice, wet road or dry) must not exceed the body gap to the vehicle (`rel.surface_gap`).
- **Definition of "stop".** "Stop" is ambiguous between two definitions. DEF-NRS-484A-255 ("when
  required") is the reading, because the stop here is one the driver must be ready to make.
- **Reversal signal.** A label that treats any slowing as preparedness would replace the model with
  a deceleration check.

**NRS_484B_267_2d — accept.**
- **Decision.** Two prohibited behaviours, each re-binding the approached vehicle:
  - "Overtake" is `drv.interaction.overtake_pass`, an act with window `p.overtake_window`.
  - "Drive abreast" is side by side (`rel.longitudinal_overlap ≥ 0`) while the subject moves. This
    is a disclosed narrowing.
- **Condition.** The vehicle is moving with aligned headings.
- **Occasion.** The trigger, lamp and condition spans are read `some_moment` of the pass. The
  officer exception is read `throughout`. The four pairs of occasion scenarios are planned.
- **Reversal signal.** A label that counts a stationary subject being passed as "abreast".

**NRS_484B_267_2e — accept.**
- **Adjacency.**
  - A lane is adjacent when it is the same-direction neighbour (`st.lane_adjacency`).
  - For a vehicle moving the opposite way, the two leftmost lanes (ordinal 1) are adjacent when
    their directions are opposed on one shared `st.roadway`. A divided highway's separate
    roadways are never adjacent.
  - The vehicle's own lane is not adjacent to itself, which is the literal reading.
- **"If possible"** is operationalized two ways:
  - The approach must have lasted `p.emergency_lane_change_window` (new parameter).
  - A candidate lane must exist: a lane of the subject's direction on the same highway that is not
    adjacent to the vehicle's lane.
- **"Unless … unsafe or impossible"** excuses the duty where:
  - every candidate lane is closed (`dev.temporary_traffic_control`), or
  - every candidate lane is blocked by a road user nearer than speed × headway (headway chosen by
    surface), or
  - the road is icy, or
  - visibility is below speed × the lane-change time.

  The catch-all "other conditions" is read only through these, which is disclosed.
- **Traffic in the gap check.** The gap check reads any road user other than the subject. The
  validator rejects an aggregate in an operationalization's concepts, and the posted definition of
  traffic ("pedestrians, ridden or herded animals, vehicles and other conveyances") covers every
  road user on the highway.
- **Reversal signal.** A label that treats following the vehicle in its own lane as a breach.

**NRS_484B_267_2f_o1 — accept.**
- **Decision.** "Proceed" is the obligation span, carried by the subject's motion. "As required
  pursuant to subsection 1 […]" is a reference span. It is carried by four `compliance`
  compositions: NRS_484B_267_1a, NRS_484B_267_1b_o1, NRS_484B_267_1b_o2 and NRS_484B_267_1c.
- **Condition.** "Approaches the driver's vehicle" is the vehicle moving with the subject ahead of
  it, within the approach reach.
- **Narrowing.** Together with the subject's own approach, this applies to head-on closing only. A
  vehicle coming from behind is still governed directly by the subsection 1 rules.
- **Reversal signal.** The same as for the shared approach reading.

**NRS_484B_267_2f_o2 — returned by the validator.**
- **Decision.** "Stops" is `drv.motion.complete_halt` on the vehicle. It must have held at every
  observation since an observation at which the trigger held (the past mirror of until). This
  bounds the history by the halt's onset. "As required pursuant to NRS 484B.607 […]" is a
  `compliance` composition of NRS 484B.607's nodes.
- **Why it is returned.** No NRS 484B.607 node is accepted or planned. The validator therefore
  rejects the compositions (NRS_484B_607_1a … _1d).
- **Why it is not worked around.** The duty is compliance with that section. Inlining it is
  forbidden, and dropping it would lose the duty. The record is kept as written.
- **Reversal signal.** Once NRS 484B.607 is planned, re-run with its actual node ids, which may
  carry `_oN` suffixes.

**NRS_484B_270_1 — accept, carries an operator gap.**
- **Decision.** "intentionally interfere" is a state of mind and is a surrogate. Interference is
  read as either:
  - contact, or
  - a closest-approach conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`) during which
    the rider brakes beyond `p.rider_evasive_decel` (new parameter).
- **Gap.** "Lawfully riding" restricts the protected riders to those whose conduct is lawful. The
  ontology reads that only through rule composition, and the words name no rule. So the span is
  an `operator` gap: `lawful(who)`. This is close to, but not the same as, the pending G22 ("in
  compliance with law"). The law stays blocked until it is resolved.
- **Reversal signal.** An operator decision that "lawfully" adds no restriction (scope `none`)
  would remove the gap.

**NRS_484B_270_2a_o1 / NRS_484B_270_2b_o1 — accept (surrogate).**
- **Decision.** "shall exercise due care and:" is an obligation of its own: a standard of care,
  which is a state of mind. Each line gives it its own node, so that the surrogate does not
  contaminate the concrete lane and clearance duties.
- **Reading.** It is read through the outcome of the pass: no contact, and no evasive braking by
  the rider while the two are side by side.
- **Trigger.** "When overtaking or passing" is `drv.interaction.overtake_pass` plus
  `rel.longitudinal_overlap`, with the same atoms in all five 270(2) nodes. The duty is judged at
  the pass's recognition over the window behind.
- **Reversal signal.** A label that judges care by the lateral gap would merge it into the
  clearance node.

**NRS_484B_270_2a_o2 — accept.**
- **Condition.** More than one lane exists: the rider's lane has a same-direction count greater
  than 1 (literal).
- **Obligation.** At every side-by-side observation of the pass, the subject is wholly in the left
  neighbour of the rider's lane.
- **Standard.** "If the lane is available and moving into the lane is reasonably safe" is read at
  the pass's start, the last observation at which the rider was ahead. The lane is available and
  safe when its left neighbour exists, is not closed, and has no road user nearer than speed ×
  headway.
- **Traffic.** In "lanes for traffic", "traffic" names the lanes' direction, which
  `st.lane_adjacency` carries. No membership is read, and no aggregate is claimed. This matches
  the index's precedent for "path for bicycles … has been provided".
- **Reversal signal.** A label that accepts a partial lane change (straddling) as compliance.

**NRS_484B_270_2b_o2 — accept.**
- **Condition.** Only one lane (literal 1).
- **Obligation.** "Pass to the left" means that while side by side, the rider is on the subject's
  right (`rel.bearing` lateral component negative).
- **Clearance.** "At a safe distance, which must be not less than 3 feet …" is one standard span.
  The body gap (`rel.surface_gap`, "any portion of the vehicle") must be at least the larger of
  the literal 3 ft and `p.bicycle_pass_safe_gap` (new parameter).
- **Reversal signal.** A label expecting a speed-dependent clearance.

**NRS_484B_270_2b_o3 — accept.**
- **Obligation.** "Shall not move again to the right side of the highway" is
  `drv.lane.heading_right_of_carrier` on the rider's lane, after the subject has the rider on its
  right.
- **Standard.** "Until … safely clear" means the rider is behind the subject with a gap of at
  least the rider's speed × headway, headway chosen by surface.
- **Reversal signal.** A label that counts a slow drift back as a move.

**The 270(2)(b) authorization sentence.** It permits passing left of the center or in a no-passing
zone. That relaxes NRS 484B.213 and 484B.217, not this paragraph.
- In all three 2b nodes it is an exception span carried as a residue with scope `none`.
- Its "Except as otherwise provided in NRS 484B.213 and 484B.217 […]" reference is carried by five
  `unless` compositions scoping it, as rule 5 requires.

**NRS_484B_297_6_o1 / NRS_484B_297_6_o2 — accept, carry an atom gap.**
- **Trigger.** The pedestrian, on a sidewalk, came within `p.obstruction_encounter_reach` of an
  obstruction. Since then it has been off every sidewalk and on a travel region of the same
  highway.
- **"On the sidewalk".** No atom relates the obstruction's region to the sidewalk's. These words are
  read through the pedestrian being on that sidewalk when it meets the object.
- **(a).** The body must be within `p.pedestrian_side_margin` of the sidewalk, or of the obstruction
  where it reaches off the sidewalk.
- **(d).** A pedestrian still off the sidewalk after a full `p.pedestrian_return_window` beyond the
  obstruction violates the duty.
- **Permissions.**
  - "With due care" qualifies the permission and is a residue with scope `none`.
  - (b) does not change (a) or (d) and is a residue with scope `none`.
  - (c) is an exception of (a) and a sibling in (d).
- **Gap.** "A short section of the sidewalk that is missing or impassable" extends the trigger
  beyond objects, and (c)'s "area … impassable" needs the same notion. Neither is an
  `st.obstruction`. Both are the atom gap `st.impassable_section`, the same proposal as the pending
  smoke31-1111-0039:G18. The law stays blocked until it is decided.
- **Reversal signal.** An operator ruling that an excavation-kind obstruction covers a missing
  section.

## For the operator

- **NRS 484B.607 has no node.** NRS_484B_267_2f_o2 composes its rules (`compliance`) and is
  returned only for that reason. Plan NRS 484B.607 first. Then re-run 2f with the actual node ids.
- **Proposed operator gap `lawful(who)`.** Raised on NRS 484B.270(1) "a person lawfully riding".
  Consider it together with G22 ("or in compliance with law"). Both need compliance with every
  engaged rule rather than one named rule.
- **Pending atom gap G18 (`st.impassable_section`).** It is carried again on NRS 484B.297(6).
- **New parameters.** `p.emergency_lane_change_window`, `p.rider_evasive_decel`,
  `p.bicycle_pass_safe_gap`, `p.obstruction_encounter_reach`, `p.pedestrian_side_margin`,
  `p.pedestrian_return_window`.

<!-- batch-15 -->
# Plan — batch 15 (iteration 1)

Eight laws, nine nodes. No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse `drv.interaction.overtake_pass`, `drv.motion.moving_across_carrier` and `drv.motion.complete_halt`, which earlier batches of this iteration proposed. The validator accepts every node. One node, `NRS_484B_270_3_o2`, carries three atom gaps and is not coded.

## NRS_484B_270_3_o1 — yield to riders and to 297(6) pedestrians on the bicycle lane

**Decision.** The subject is the motor-vehicle aggregate, with "driver" read through the vehicle's controlled motion (agency). "shall yield" reuses the index mapping (`kin.speed`, `rel.contact`).

"the right-of-way" is the standard. Its definition, DEF-NRS-484A-210, sets the bound: "danger of a crash". It is operationalized with the closest-approach primitives under `p.conflict_horizon` and `p.conflict_centre_clearance`. It is not a surrogate.

**The other party.** It is quantified inside the obligation and has no binder. It is either:
- a moving member of the bicycle, electric-bicycle or electric-scooter aggregates ("riding", read as an agency reading, as the index maps "a person lawfully riding"), or
- a pedestrian for whom `NRS_484B_297_6_o1` applies. This uses a `condition` composition with its subject mapped to the quantified pedestrian.

**The lane.** "on the pathway or lane" refers to the "pathway or lane provided for bicycles…" that the next sentence names. The node carries it with its full qualification as `st.bicycle_lane_or_path`, anchored by `rel.occupies` to the other road user. The obligation reads the same lane again for the subject.

**What counts as failing to yield.** Contact, or the subject overlapping that lane while moving with a conflicting closest approach. This is disclosed as a narrowing on the obligation: a conflict while the subject stays outside the lane is not read.

**The composition.** It names only `_o1` of NRS-484B-297-6, because `_o1` is the node that carries 297(6)(c), the pedestrian's permission to use the bicycle lane.

**Branch scenarios.** `branch_2` and `branch_3` differ only in whether 297(6) applies to the pedestrian.

**Reversal signal.** If `NRS_484B_297_6_o1`'s applicability turns out not to cover a pedestrian already in the bicycle lane, compose `_o2` as well, or carry 297(6)(c) as a `definition` reference.

## NRS_484B_270_3_o2 — no entering, stopping, standing, parking or driving within the bicycle lane (blocked)

**Decision.**
- **The verbs.** Every verb is the footprint overlapping the lane, whether moving or halted. "Stop" is prohibited here, so DEF-NRS-484A-260 states its own scope; the outcome does not depend on choosing between the two "stop" definitions.
- **(a) alley or driveway.** Read with `until`/`since` on the subject's stretch in the lane: the stretch ends in, or began from, an alley or a driveway/alley entrance.
- **(c) avoid conflict.** Read through conduct (purpose): when the subject came into the lane, a member of traffic had a conflicting closest approach with it.
- **(e) police officer.** Reuses the index mapping: `dev.human_direction` with role police_officer, governing the occupied region.

**Gaps.** Three exceptions have no carrier:
- **(b) disabled vehicle.** Re-filed as gap `ru.disabled` (pending G19 of smoke31).
- **(f) emergency.** Re-filed as gap `env.emergency` (pending G20).
- **(d) official duties.** The validator rejected reading this through the emergency or official class: a class is no evidence of what the vehicle is doing, and warning lamps show on duty and off it alike. It is filed as a new atom gap, `ru.on_official_duty`. The index maps the same words for `NRS_484B_117_1` to the classes; this node departs from that mapping for the validator's reason.

The node is not coded. Its law stays blocked until the gaps are decided.

**Reversal signal.** An ontology revision that adds a condition-of-vehicle atom, an emergency atom and an on-duty atom, or an operator ruling that the vehicle classes may carry (d).

## NRS_484B_270_4 — no entering an intersection while driving within the bicycle lane

**Decision.** The obligation is that the moving subject's footprint does not overlap both a bicycle lane or path and an intersection.

"Except as otherwise provided in subsection 3" is composed with `NRS_484B_270_3_o2` `as: compliance`. What subsection 3 "otherwise provides" is its exceptions (a)–(f). An `exception` composition would not work: it would remove the duty wherever o2 is engaged, which is every time the subject is in the lane. Compliance with o2 while the subject is in the lane is exactly "one of (a)–(f) holds".

**Consequence.** This node is valid but cannot be built until `NRS_484B_270_3_o2` is coded, so the law effectively waits on that node's gaps. The node does not inline the exceptions, which would only move the same gaps here.

**Reversal signal.** A ruling that "as otherwise provided" should be a `definition` reference borrowing the exception words.

## NRS_484B_270_5a — due care to avoid a collision with a rider (surrogate)

**Decision.** "Exercise due care" is a standard about state of mind, so the node is a surrogate.

While the subject moves, it must have no contact (from "to avoid a collision") and no conflicting closest approach (`p.conflict_horizon`, `p.conflict_centre_clearance`) with any riding member of the three aggregates. The catch-all character of "due care" is disclosed as a reading.

**Reversal signal.** Label evidence that riders at rest must be covered: drop the "riding = moving" reading.

## NRS_484B_270_7a — no intentional interference with a motor vehicle (surrogate)

**Decision.** The validator requires an obligation span, so the text is split:
- "shall not: Intentionally" is the standard (intent): a surrogate, operationalized through evasive braking and conflict.
- "interfere with the movement" is the obligation: the motor vehicle's motion (`kin.speed`, `kin.accel_longitudinal`), with the rider ahead of it (`rel.bearing`).

A violation is a moving motor vehicle, with the rider ahead of it, braking beyond `p.vehicle_evasive_decel` while their closest approach conflicts. `p.vehicle_evasive_decel` is a new parameter, proposed at about 0.4 g, above comfortable braking.

**Disclosed limit.** The node cannot tell intentional interference from accidental interference.

**Reversal signal.** Label disagreement on rider-ahead conflicts the car caused itself, for example a car overtaking too close. Such cases call for a condition on the rider's own deceleration.

## NRS_484B_270_7b — no overtaking a motor vehicle unless safe

**Decision.** The act is `drv.interaction.overtake_pass(subject, m)`, with occasion boundary `window` and window `p.overtake_window`. The node has no trigger, condition or exception spans, so the occasion maps no spans.

The "unless … safely" clause is a standard, not a surrogate. It is read in the obligation over the whole pass, from the concept's own beginning (the last observation with the vehicle ahead and headings aligned) to its recognition, using `since`. At every observation of the pass:
- there is no contact;
- the gap between bodies (`rel.surface_gap`) is at least `p.bicycle_pass_safe_gap`;
- no other road user has a conflicting closest approach with the subject.

The occupants are read through the passed vehicle's body. "can do so" is read through the pass actually made (perception). `p.bicycle_pass_safe_gap` is reused from `NRS_484B_270_2b_o2`, since it is the same clearance between a bicyclist's and a motor vehicle's bodies.

**Reversal signal.** The operator separates the passing-bicycle clearance into its own parameter.

## NRS_484B_280_1a — due care to avoid a collision with a pedestrian (surrogate)

**Decision.** Same construction as 270-5a, applied to the pedestrian aggregate.

**Reversal signal.** As for 270-5a.

## NRS_484B_280_1c — proper caution upon observing a pedestrian at the listed places (surrogate)

**Decision.** The validator requires an obligation span, so "shall: Exercise" is the obligation (`kin.speed`, `rel.contact`) and "proper caution" is the surrogate standard (closest approach).

**Trigger.** "upon observing" is `rel.visible`, a perception reading taken at the judged observation.

**Places.** "near" uses one new reach parameter, `p.pedestrian_near_reach`, for all the places:
- **(1) Highway, street or road.** Together these are every highway, so the node reads `st.highway`.
- **(2) Stops and boarding.**
  - "bus stop", "bench", "shelter" and "transit stop" are `st.transit_stop`. "stop" here is part of a place name, not the defined halt.
  - "boarding" is read through conduct (purpose): the pedestrian is within reach of a halted bus or transit bus with a door open.
- **(3) Zones and crosswalks.**
  - School zones and school crossing zones are "marked", so the zone sign is the atom (`dev.zone_sign` of kind school or school_crossing, through `dev.governs`). NRS 484B.363 is not in this corpus, so accordance with it is a status reading.
  - Crosswalks are `st.crosswalk`, marked or unmarked.

**Reversal signal.** Label evidence that pedestrians who were seen and are now occluded must be covered: read `rel.visible` in a window behind instead.

## NRS_484B_287_1c — pedestrians cross only in marked crosswalks between adjacent signalized intersections

**Decision.** The validator rejects narrowings on condition spans, so both conditions are carried as their words say, and the readings are argued in the justifications.

**"Between adjacent intersections".** It is read through relation atoms tied to the carriers the pedestrian occupies:
- **The first intersection (i1).** The pedestrian occupies a carrier that `st.lane_enters` an intersection i1. The carrier is the stretch from the previous junction, so no other intersection lies between.
- **The second intersection (i2).** It is found in one of two ways:
  - the pedestrian also occupies the opposing carrier, which enters i2; or
  - a lane that enters i2 leads into the occupied lane (`st.lane_connectivity`), directly or through one connector lane.
- **Exclusions.** A pedestrian inside either intersection, or in a crosswalk that `st.entrance_of` records as marking an occupied carrier's entrance, is at the intersection, not between.

**"Official traffic-control devices are in operation".** The words "in operation" limit the defined term (DEF-NRS-484A-145) to devices that operate. That means uncovered signal heads that are neither dark nor `dev.inoperative`. Signs and markings are posted or painted and do not operate, so stop-controlled intersections are not read.

**Crossing.** "Cross" is `drv.motion.moving_across_carrier` on the occupied carrier. The exception is occupancy of a crosswalk whose marked attribute is true.

**The reference.** `[LVMC-11-30-140-B]` names one law line with two nodes, so it is composed as an `exception` with both `LVMC_11_30_140_B_o1` and `_o2`.

**Reversal signal.**
- An operator ruling that stop and yield signs are "in operation". The fix would be to add `dev.stop_sign` and `dev.yield_sign` to v3.
- Label evidence on one-way mid-block crossings where lane connectivity is not mapped.

## For the operator

- **G19 and G20 (smoke31) still decide NRS-484B-270-3(b) and (f).** They are re-filed on the same words. A third atom gap, `ru.on_official_duty`, is filed for (d) "In the performance of official duties". The validator ruled that vehicle classes are no evidence of duty; that ruling also affects how the index maps the same words for `NRS_484B_117_1`, which reads them through the classes.
- **NRS-484B-270-4 waits on `NRS_484B_270_3_o2`.** It composes that node `as: compliance`, so it stays unbuildable until the three gaps above are decided.
- **The pedestrian and rider surrogates read conflicts by centre distance (270-5a, 280-1a, 280-1c, 7b's other-traffic check).** With `p.conflict_centre_clearance` at about 3 m, a vehicle passing close to a pedestrian standing at the curb can be flagged. The value is the operator's to review.
- **New parameters:**
  - `p.pedestrian_near_reach` (280-1c);
  - `p.vehicle_evasive_decel` (270-7a).

<!-- batch-16 -->
# Plan — batch 16 (NRS 484B.287(1)(d)–(e), NRS 484B.283(1)(a), (b), (d)(1)–(4))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the one manoeuvre-like notion (moving across or along a carrier) reuses `drv.motion.moving_across_carrier`, which an earlier batch proposed. No gaps. All ten nodes pass the validator.

## Shared decisions

**Which pedestrian signal a pedestrian obeys.** Subsections 283(1)(d)(1)–(4) apply to "pedestrians facing the signal", the pedestrian proceeding "in the direction of the signal", and "such signals". The ontology has no relation between a pedestrian head and the crosswalk it controls, and no atom for the direction a head's face points. I read "the signal" as a `dev.pedestrian_signal` head that meets two conditions:
- **It governs the roadway or lane being crossed** (`dev.governs`). Its contract covers "the travel regions whose traffic the device controls", and traffic includes pedestrians (DEF-NRS-484A-285). This separates two heads on one corner pole that control perpendicular crossings.
- **The pedestrian faces it.** Its `dev.position` lies ahead of the pedestrian's `kin.position` along `kin.heading`, within a cone (`p.ped_signal_facing_cos`) and a reach (`p.ped_signal_facing_reach`). This excludes heads at the far end of the same roadway segment.

The coder writes "facing" in the node formula with squared comparisons, because a concept cannot take a device formal.
- *Reversal signal:* if the sources do not record `dev.governs` for pedestrian heads, or record it on the intersection only, these nodes report unknown. A gap for a `dev.controls_crossing` relation (pedestrian head → crosswalk) would then be the right fix.

**"Cross the highway" / "entered the highway".** The highway (DEF-NRS-484A-095) includes the sidewalk. However, the law's own words in (d)(3)–(4) name the curb and sidewalk as the places of safety a crossing pedestrian proceeds to. So I read the crossing as being on the roadway or lane, and "entered the highway" as the step from a sidewalk onto it.
- *Reversal:* a reviewer holding the defined word to its whole extent.

**"Except as otherwise provided in …".** Each named rule is an `exception` composition, using the node ids the library lists:
- `NRS_484B_287_1c`, `_1d`, `_1e`, `LVMC_11_30_060_A`, `_B`
- both nodes of `LVMC_11_30_140_B`
- both nodes of `LVMC_11_46_030`

Mapping of each composed rule's subject:
- **Pedestrian rules in the vehicle-subject nodes (1a, 1d1):** mapped to the quantified pedestrian `p`.
- **School-crossing rule (`LVMC_11_46_030`) in the pedestrian-subject nodes:** mapped to a quantified vehicle `v`.
- **All others:** mapped to `subject`.

**Readings moved out of `narrowings`.** The validator does not accept `reading` narrowings on trigger, condition or exception spans. Those readings are now stated in the element justifications and listed below, so they are still disclosed.

## Nodes

**NRS_484B_287_1d** — "shall not cross an intersection diagonally". The pedestrian occupies an intersection, and its velocity is oblique to every lane entering it. This is `moving_across_carrier` at the across-vs-along tolerance (`p.crossing_motion_cos`) and *not* at the right-angle tolerance (`p.right_angle_crossing_cos`).
- **"Unless authorized by official traffic-control devices":** read as a marked crosswalk under the pedestrian (DEF-NRS-484A-065(2) markings), with `official` disclosed as a status reading. A sign that authorizes diagonal crossing without a marking is not read.
- **Judgement point:** each observation, not a corner-to-corner path.
- **Exception:** composes both `LVMC_11_30_140_B` nodes.
- *Reversal:* a labelled diagonal crossing authorized only by a sign, or a non-right-angle junction that this reading misjudges.

**NRS_484B_287_1e** — "cross only in accordance with the devices pertaining to such crossing movements". The start of an authorized diagonal crossing is the moment the pedestrian enters an intersection while in a marked crosswalk and moving diagonally (same reading as 1d).
- **Obligation:** no faced pedestrian head shows a steady don't-walk, or a flashing don't-walk without countdown.
- **Not read:** conduct after the start of the crossing, and devices other than pedestrian heads (disclosed narrowing on the obligation).
- **Why not compose the (d) subparagraphs:** they except 287(1)(e), so composing them as `compliance` would create a cycle.
- *Reversal:* a scramble recording where the label judges mid-crossing conduct.

**NRS_484B_283_1a** — the driver yields to a pedestrian in a crosswalk when devices are not in place or not in operation.
- **"Devices not in operation":** every vehicular head governing the subject's region is dark or `dev.inoperative`, and every pedestrian head governing the pedestrian's region is dark. I read signal heads only, because signs and markings do not allot the crossing in time; this widens applicability rather than narrowing it.
- **"Half of the highway":** read with the section's own definition. The lanes or one-way roadway under the pedestrian have a designated direction that points with the vehicle's `kin.heading`. While turning, the vehicle's half is the one its heading has turned onto.
- **Opposite half:** the pedestrian counts only when "in danger", operationalized as a predicted closest approach within `p.conflict_horizon` below `p.conflict_centre_clearance`.
- **Yield:** no contact, and, while moving above `p.halt_speed_tolerance`, no such predicted conflict (traffic-conflict technique; reuses the index mapping of "shall yield the right-of-way").
- *Reversal:* a yield label that disagrees with the heading-based half on a turning vehicle.

**NRS_484B_283_1b** — "shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle which is so close that it is impossible for the driver to yield". This is now one obligation span, as the validator requires.
- **Event:** the pedestrian's footprint comes onto a roadway from a sidewalk, safety zone or median ("other place of safety" is read only through those three; disclosed).
- **"Suddenly":** read through the vehicle's closeness at that moment (disclosed).
- **"Impossible to yield":** a stopping-distance model. The time to closest approach is below the reaction time plus speed ÷ (2 × deceleration), written as a product. Deceleration is chosen by surface: ice, else wet, else dry.
- *Reversal:* a label that judges the pedestrian's own abruptness rather than the vehicle's closeness.

**NRS_484B_283_1d1** — drivers must give the right-of-way to pedestrians facing a walk head that governs the roadway they are on.
- **"Proceed across the highway in the direction of the signal":** read as the pedestrian on the governed roadway facing the head, whether at rest or moving.
- **Right-of-way:** the danger-of-crash standard (DEF-NRS-484A-210), operationalized as in 1a.
- *Reversal:* see the shared signal decision.

**NRS_484B_283_1d2** — a pedestrian who enters during a flashing don't-walk with countdown must complete the crossing before the countdown reaches zero.
- **When it is judged:** at the head's change from flashing-with-countdown to steady. The timer's displayed number is not an atom; the change ends the interval the timer counts (disclosed).
- **Who it applies to:** pedestrians whose latest entry onto the roadway was made, facing the head, during that same countdown interval.
- **Obligation:** the footprint has left that roadway.
- **Event-relative history:** the past search ends at the entry. A `history_boundary` scenario covers an entry made before the recording began.
- *Reversal:* a source that carries the countdown's value, which would allow reading zero directly.

**NRS_484B_283_1d3_o1 / _o2** — two obligations in one line. The shared clause about a pedestrian who "entered … lawfully pursuant to subparagraph (1)" is an exception in o1 and the subject condition in o2.
- **Reference handling:** the bracketed reference is a `definition` reference. It borrows (1)'s words: walk illuminated, pedestrian facing the signal, proceeding in its direction.
  - Subparagraph (1)'s rule is a driver duty, so whether it was complied with says nothing about the pedestrian's entry. Composing it would weaken the condition.
  - The referring span is `e1`; the defining text is NRS-484B-283-1d1.
- **o1:** while the faced head flashes without a countdown, a pedestrian who is off the governed roadway does not step onto it. A pedestrian continuing a lawful walk-phase crossing (no sidewalk since that entry) is excepted.
- **o2:** a lawful walk-phase entrant still on the roadway during the flashing interval must be off it when the head turns steady. "Place of safety" is read as anywhere off the governed roadway (disclosed).
- *Reversal:* a label that also requires the pedestrian to reach a sidewalk or safety zone specifically.

**NRS_484B_283_1d4_o1 / _o2** — the same structure as 1d3, under the steady indication. The lawful entry is borrowed from both (1) and (2), so there are two `definition` references.
- **o1:** no stepping onto the governed roadway under a steady don't-walk, unless continuing a lawful crossing.
- **o2:** "as soon as possible" is a standard. It is operationalized as a speed floor while still on the roadway (`p.pedestrian_clearing_speed_min`). The convention is MUTCD 4E.06 clearance walking speeds, with the floor set at about half the slow-pedestrian speed. Direction of travel and the pedestrian's own ability are not read (disclosed).
- *Reversal:* a label that flags a brief pause, or a slow wheelchair user; either would argue for a duration window or a lower floor.

## Parameters

**Reused from the iteration's proposed list** (re-proposed with identical values and conventions):
- `p.halt_speed_tolerance`, `p.crossing_motion_cos`, `p.right_angle_crossing_cos`
- `p.conflict_horizon`, `p.conflict_centre_clearance`
- `p.driver_reaction_time`
- `p.following_decel_dry`, `p.following_decel_wet`, `p.following_decel_ice`

**New:**
- `p.ped_signal_facing_cos` (ratio)
- `p.ped_signal_facing_reach` (m)
- `p.pedestrian_clearing_speed_min` (m/s)

## For the operator

- **Pedestrian heads have no "controls this crossing" relation.** The (d) subparagraphs and 287(1)(e) depend on reading `dev.governs` from a pedestrian head to the roadway or lane it controls, together with a facing cone on `dev.position`. Adapter authors need to know that pedestrian heads are expected to carry `dev.governs` onto the crossed roadway or lane. If sources cannot provide it, a gap for `dev.controls_crossing` (pedestrian head → crosswalk) or a device face-orientation atom is the cleaner fix. Either would decide which indication a pedestrian obeys at a pole carrying two heads.
- **`dev.pedestrian_signal` exposes the countdown only as present or absent.** 283(1)(d)(2) ("before the countdown timer gets to zero") is therefore read at the change to steady. A source that shows a countdown reaching zero before the steady indication (a buffer interval) would be judged late by up to that interval.
- **The new parameter values are provisional and need review:** `p.ped_signal_facing_cos` = 0.87, `p.ped_signal_facing_reach` = 40 m, `p.pedestrian_clearing_speed_min` = 0.5 m/s.

<!-- batch-17 -->
# Plan — batch 17 (NRS 484B.293, 484B.297(2), 484B.307(2)(a), (2)(b), (3)(a), (4)(a), (12)(a), (12)(b))

All nine nodes pass the validator (`accept`). No concept is proposed: every manoeuvre or state is a
concept already proposed this iteration (`drv.motion.complete_halt`, `moving_across_carrier`,
`moving_against_carrier`, `left_/right_/u_turn_through_region`), reused by id. No gap and no law-local
aggregate (`aggregates.jsonl` is empty).

## Nodes

**NRS_484B_293** (pedestrians on the right half of crosswalks). One obligation: "upon the right half of
crosswalks". "shall move" is a condition: the duty applies only while the pedestrian moves (not
`drv.motion.complete_halt`). The right half is read from the crosswalk's reference point
(`st.region_geometry`) and the pedestrian's velocity. The pedestrian complies when that point is not to
its right by more than the new `p.pedestrian_lateral_tolerance`. "whenever practicable" is
operationalized, not surrogate. Keeping right is impracticable when one of two things lies on the
pedestrian's right within `p.pedestrian_near_reach`:
- another road user ahead in the same crosswalk (`rel.bearing`, `rel.surface_gap`);
- an obstruction (`prim.region_lateral_offset`, `st.region_geometry`).

The narrowing says the catch-all is read only through those two. *Reversal signal:* sources where a
crosswalk's reference point is not its centroid; then a geometric "half of a region" primitive is
needed (see operator section).

**NRS_484B_297_2** (walk on the left, facing traffic, where no sidewalk is provided). The two
obligation phrases are one obligation span. "Left side" is read against the centre line of the
pedestrian's highway (`prim.region_lateral_offset`), reusing the index mapping of "left side of the
highway" (NRS_484B_213_2a). "Facing the approaching traffic" means `drv.motion.moving_against_carrier`
for every lane of that highway within `p.pedestrian_near_reach`.

The trigger "walking along" reuses the atoms LVMC_11_30_090 uses for "walk along": moving, and not
`moving_across_carrier` for the nearby lanes. "where sidewalks are not provided" reuses the index
mapping of "Where sidewalks are provided": no `st.sidewalk` on that highway (`st.on_way`).

"Except as otherwise provided in subsection 6" carries two exception compositions,
NRS_484B_297_6_o1 and NRS_484B_297_6_o2.

The word "traffic" (the admitted aggregate DEF-NRS-484A-285::traffic) is deliberately not claimed. It
names the stream the lanes carry, and the duty is the same whether or not a road user is approaching.
Quantifying over traffic members would report a violation against a pedestrian when a wrong-way
vehicle is present. *Reversal signals:*
- the selection or validator insists the aggregate be claimed;
- on one-way highways (no centre line) the left side is read through the facing element only, which
  the narrowing discloses — reverse if the operator wants a road-edge reading there.

**NRS_484B_307_12a** (downward green arrow over a lane: "may drive in any lane …"). The text grants a
permission and states no duty, but the harness requires a violable rule. I read the permission as its
scope:
- It applies to a moving vehicle that faces a green arrow over some lane and drives in a lane with a
  lit lane-control signal facing it.
- It complies when the signal over the vehicle's own lane shows `green_down_arrow`.

Driving under another lit indication is reported as outside the permission. The narrowing says
whether that conduct is also forbidden is for (12)(b) and the following paragraphs. "facing the
signal" reuses the "pedestrians facing the signal" mapping (`dev.position`, `kin.position`,
`kin.heading`): the head lies ahead along the heading. *Reversal signal:* an operator rule that
permissive clauses are not formalized as violable rules, or a label showing yellow-X lanes judged
`not_applicable` under (12)(a).

**NRS_484B_307_12b** (red X: must not enter or drive in the lane). This applies where a lane-control
signal showing `red_x` is over some lane and faces the subject. The subject must not enter that lane
(`rel.occupies` rises) and must not occupy it while moving. A vehicle halted in the lane neither
enters nor drives in it (disclosed). *Reversal signal:* a label that treats a halted vehicle in a
red-X lane as a violation.

**NRS_484B_307_2a** (circular green alone: yield). There is one obligation, "must yield". The
right-of-way standard (DEF-NRS-484A-210, "danger of a crash") is operationalized by the
constant-velocity closest approach, with `p.conflict_horizon` and `p.conflict_centre_clearance` as
proposed by LVMC_11_12_070_B. "must yield" reuses the index mapping `kin.speed`, `rel.contact`.

The subject is traffic and a vehicle. "Facing the signal" means the subject is on, or entered the
intersection from, an approach carrier (`st.lane_enters`) governed by a signal (`dev.governs`) that
shows circular green alone.

The parties are other vehicles and pedestrians within the intersection or an adjacent crosswalk. An
adjacent crosswalk is one that marks the entrance (`st.entrance_of`) of a carrier into the same
intersection. "lawfully" is not read (see operator section). "unless another device … prohibits …
turns" limits the permission to turn, not the yield. It is a `scope: none` residue.

*Reversal signal:* the operator directs that "lawfully within" be composed with specific rules.

**NRS_484B_307_2b** (pedestrians facing circular green "may proceed … within any … crosswalk"). This
is a permission, read as its scope, the same way as (12)(a):
- It applies to a pedestrian who faces a circular-green-alone head and crosses a roadway lane
  (`moving_across_carrier`).
- It complies when the pedestrian occupies a crosswalk.

Facing uses two new parameters, `p.ped_traffic_signal_facing_cos` and
`p.ped_traffic_signal_facing_reach`. The pedestrian-signal parameters `p.ped_signal_facing_*` are
about pedestrian heads, so they are not reused. "unless directed otherwise by another device as
provided in NRS 484B.283 […]" names law lines 283-1d1 to 1d4. It becomes six exception compositions,
one per node of those lines: NRS_484B_283_1d1, _1d2, _1d3_o1, _1d3_o2, _1d4_o1 and _1d4_o2.
*Reversal signal:* same as (12)(a). A second signal would be if NRS_484B_283_1d1's subject turns out
to be the driver rather than the pedestrian; that composition would then never fire and could be
dropped.

**NRS_484B_307_3a** (circular green with green turn arrow: yield). This has the same structure as
(2)(a), with protected parties pedestrians in an adjacent crosswalk and other traffic
(DEF-NRS-484A-285::traffic) using the intersection. Two spans are `scope: none` residues:
- "to make the movement indicated … or such other movement as is permitted by the circular green
  signal" — the yield binds whatever the movement;
- the advisory sentence ("Drivers turning … are thereby advised …") — it requires nothing.

"Vehicular traffic" claims DEF-NRS-484A-320::vehicle although the definitions table lists no
"vehicle" term for this law. "Vehicular" is the defined word's adjective. Without it the subject
would include pedestrians and bicycles (human-powered devices are excluded from "vehicle" by
NRS 484A.320). *Reversal signal:* the selection role keeps its decision. If so, the subject becomes
traffic alone and a narrowing discloses the broader class.

**NRS_484B_307_4a_o1** (green turn arrow alone: proceed only in the arrow's direction). The obligation
is an act judged when the passage is recognized at the subject's exit from the intersection:
`left_/right_/u_turn_through_region` matched to the arrow's direction. The occasion boundary is the
event of entering the intersection (onset). "Where the signal is a green turn arrow alone" is read at
`some_moment` of the passage, with scenarios `occasion_s1` and `occasion_s1_outside`. "so long as the
arrow is illuminated" belongs to the obligation span and is read the same way (disclosed). A straight
arrow is no "turn arrow", so no straight case is needed. The vehicle aggregate claim is the same as
in 3a. *Reversal signal:* a label that reads the arrow at the entry instant only, which `atLast` on
the entry would carry.

**NRS_484B_307_4a_o2** (green turn arrow alone: yield). This has the same structure as 3a. "the
adjacent crosswalk" is read as every crosswalk marking an entrance into the intersection, because the
turning vehicle's exit leg is not known before the turn ends. The conflict bound then picks the
crosswalk its path meets (disclosed on the standard span).

## Conditions referring to words stated elsewhere

- **NRS_484B_297_2:** the reference span s1 points to NRS 484B.297(6). It is composed as an exception,
  so the duty does not apply where either node of (6) applies. (6) is about pedestrians moving around
  a sidewalk obstruction, a situation (2) would otherwise cover with a contrary direction rule.
- **NRS_484B_307_2b:** s6 points to NRS 484B.283(1)(d). It is composed as an exception, so where a
  pedestrian signal governs the crossing, its rules apply instead.
- **Nodes not yet published:** both sets of composed nodes are planned this iteration and not yet
  published. The compositions are kept regardless, because rule 5 says a dependency not yet coded is
  no reason to weaken them.

## For the operator

- **Permissions without a duty.** NRS 484B.307(12)(a) and (2)(b) grant permissions and impose no duty
  of their own. The harness requires a `forbid → violated` scenario, so each is read as the scope of
  its permission, disclosed on the obligation span. A corpus-wide convention for permissive clauses
  would settle whether such lines should be formalized at all.
- **"lawfully" in (2)(a), (3)(a), (4)(a).** The ontology says lawfulness of another road user's
  conduct is a rule composition, but these words name no rule. The parties' lawful presence could
  rest on 307(2)(b), 283(1)(d) or entries on earlier phases. The plan protects every party within,
  disclosed on the standard span. This over-reaches only toward unlawfully present parties. If the
  operator names the rules that make a party "lawfully within", the compositions can be added.
- **Facing a signal.** No atom carries a signal head's orientation, so "facing the signal" is read
  from where the head is (`dev.position`) relative to the road user's heading. Back-to-back heads at
  one gantry (reversible lanes) both lie "ahead". A device-facing attribute in the ontology would
  remove that ambiguity.
- **Halves of a crosswalk.** NRS 484B.293 relies on the crosswalk's reference point being its centre.
  A primitive for a region's half relative to a road user's motion would not need that assumption.
- **New parameters:**
  - `p.pedestrian_lateral_tolerance` — NRS_484B_293 and NRS_484B_297_2;
  - `p.ped_traffic_signal_facing_cos` — NRS_484B_307_2b;
  - `p.ped_traffic_signal_facing_reach` — NRS_484B_307_2b.

  Their provisional values are in the nodes' `param_proposals`. All other parameters are re-proposed
  with the earlier batches' names, values, units and conventions.

<!-- batch-18 -->
# Plan — batch 18: NRS 484B.307 paragraphs (4)(b), (5)(a), (6)(a), (7)(a), (8)(a)–(d)

There are 13 nodes. `aggregates.jsonl` is empty because no clause defines, adds or excludes members of its own. No new concept records are proposed: the nodes reuse `drv.motion.complete_halt`, `drv.motion.left_turn_through_region`, `drv.motion.right_turn_through_region` and `drv.motion.u_turn_through_region`. No gaps. The validator accepts every node.

Conventions used throughout:
- **"Facing the signal" for vehicular traffic** uses the index mapping from `NRS_484B_307_2a`: the subject occupies a carrier `c` whose entrance end is intersection `i` and that the head governs.
- **"Facing" for pedestrians** uses the index mapping from `NRS_484B_307_2b`: `dev.position`, `kin.heading` and `kin.position`, with that node's proposed parameters `p.ped_traffic_signal_facing_cos` and `p.ped_traffic_signal_facing_reach`, proposed again unchanged.
- **"Steady red / yellow alone"** means `circular_red` / `circular_yellow` and no other state.
- **"Yield the right-of-way"**:
  - "yield" is mapped to `kin.speed` and `rel.contact`, as in the index.
  - "the right-of-way" (DEF-NRS-484A-210) is operationalized by the traffic-conflict technique: `prim.closest_approach_*` with `p.conflict_horizon`, `p.conflict_centre_clearance` and `p.halt_speed_tolerance`.
- **"Stop"** is the ambiguous term. In every span here a stop is *required*, so DEF-NRS-484A-255 ("complete cessation from movement") applies, through `drv.motion.complete_halt`.

## Nodes

**NRS_484B_307_4b** — A pedestrian facing a vehicular head that shows a green turn arrow alone must not step onto the roadway.
- "Enter the highway" is read as entering the roadway, disclosed as a narrowing. The highway's defined width includes the sidewalk the pedestrian already stands on, and the index reads "cross the highway" the same way in 283-1d3.
- The bracket "as provided in NRS 484B.283" carries four exception compositions:
  - `_1d1` (walk) and `_1d2` (flashing with countdown) are the provisions that permit proceeding.
  - `_1d3_o2` and `_1d4_o2` are the provisions that let a lawfully entered pedestrian continue (for example onto a second roadway).
  - `_1d3_o1` and `_1d4_o1` were not composed: they forbid proceeding, so making them exceptions would excuse entry on "don't walk".
- Reversal signal: `NRS_484B_283_1d1`'s binder is the yielding vehicle rather than the pedestrian. In that case `ruleApplies` would never hold for a pedestrian, and the walk exception would need re-mapping.

**NRS_484B_307_5a_o1** — Under a green straight-through arrow alone, the subject's passage through the intersection must not be a right turn, a left turn or a U-turn.
- The U-turn is read as a turn (narrowing).
- The obligation is an act recognized at the exit, with an event boundary (onset at entry).
- The trigger is read at `some_moment` while the passage is under way, the default where the words say nothing of time. Scenarios `occasion_s1` and `occasion_s1_outside` are included.
- Reversal signal: a label that reads the arrow only at entry.

**NRS_484B_307_5a_o2** — Under that arrow, yield to vehicles and pedestrians that were within the intersection or an adjacent crosswalk at the time the arrow was exhibited.
- "At the time the signal is exhibited" is read at the arrow's latest onset, through a past operator.
- "Lawfully" is read through presence (narrowing), following the index for 2a.
- `branch_1` differs from `forbid` only in that weaker fact (present now, but not at the onset).

**NRS_484B_307_6a** — Traffic that faced the steady yellow alone on its approach must not enter the intersection while the steady red is shown.
- The warning sentence is a `definitional` residue: it imposes no duty.
- "The red signal" is read as `circular_red` without a green or flashing-yellow arrow, so that the arrow paragraphs govern arrow movements (narrowing).

**NRS_484B_307_7a_o1 / _o2 / _o3** — The line has three obligation spans: "is permitted to cautiously enter … only to make the movement indicated", "must yield" to pedestrians, and "and yield" to other traffic. Each is its own node.
- **o1** is an act recognized at the exit.
  - The movement indicated by the flashing yellow turn arrow is required; a left arrow also covers the U-turn.
  - The exception "other such movement … permitted by other indications displayed at the same time" is read at `some_moment`, the same moment as the arrow, because the words say "at the same time".
  - "Cautiously" is operationalized as no traffic conflict at the entry observation.
- **o2** and **o3** are yield duties toward pedestrians within the intersection or an adjacent crosswalk, and toward traffic within the intersection. "Lawfully" is read through presence.
- Reversal signal: a reviewer who requires one node for the coordinated "must yield … and yield …" would merge o2 and o3.

**NRS_484B_307_8a_o1** — Rule 4c duty: the subject must halt before the intersection when it enters on a steady red alone.
- The place is, in order: the stop line marking the carrier's entrance, else the crosswalk marking it, else the intersection's edge.
- The search uses the approach convention. The `history_boundary` scenario is planned.
- "Sign or pavement marking indicates where the stop must be made" is read as the recorded stop line (narrowing). A free-standing "stop here" sign has no regulatory-sign code.

**NRS_484B_307_8a_o2** — "Remain stopped or standing until the green signal is shown" is read as not entering the crosswalk that marks the carrier's entrance, nor the intersection, while the steady red alone is shown (narrowing: closing up in a queue is not leaving the stop).
- **Exceptions.** The bracket says "(c) is appended below", so the exception for paragraph (c) is carried inline by the appended words s7–s15, as exception spans. The exception for (d) is a composition with `NRS_484B_307_8d`.
  - Inlining (c) also avoids a composition cycle: o2 → 8c → (yield beneficiaries).
- **"After complying with the requirement to stop" (s7).**
  - Referring span: s7. Defining span: s3, the stop place and order of o1.
  - The halt itself is carried, with o1's place, zone and history bound, not compliance with o1. Compliance would be granted wherever o1 is not engaged, which would wrongly satisfy the condition.
- **"For a right turn" / "for a left turn"** use the catalogued declared intentions `int.right_turn` and `int.left_turn` at the intersection. The words state the turn the entry is made for, and the exception must be decided at the entry, before the turn is recognized at the exit.
- **Other conditions:**
  - "Extreme right": `st.lane_adjacency` ordinal equals the lane count.
  - "Extreme left of a one-way highway": ordinal 1 on a `st.one_way_roadway`.
  - The intersecting highway is every way the intersection lies on other than the subject's own.
  - "Two-directional" quotes DEF-NRS-484B-073: no median lies on the way, and two lanes on it are opposed within `p.lane_opposed_direction_cos`.
  - "One-way to the right/left": every lane on the way points to that side of the approach's direction by more than `p.cross_direction_sin_min`.
  - Both of those parameters are proposed new.
- Scenarios: `branch_1` and `branch_3` differ only in the referred halt.

**NRS_484B_307_8a_o3** — The obligation "but must yield" of the appended (c) words, which this line contains.
- Its applicability is the permitted turn on red, with the same conditions as o2's (c) exception.
- "Pedestrians and other traffic proceeding as directed by the signal" is read as: moving road users that are within the intersection or an adjacent crosswalk, or on an approach whose head shows a green indication (narrowing). This node is word-for-word the duty of `NRS_484B_307_8c`, because the corpus appends (c) to this line.
- Reversal signal: the operator removes the appended text from 8a's line. In that case o3 is withdrawn and o2's (c) exception becomes a composition with `NRS_484B_307_8c`.

**NRS_484B_307_8b** — Same as 4b, with the steady red alone. The four 283 exception compositions are the same, for the same reasons.

**NRS_484B_307_8c** — Same duty as 8a_o3.
- "The requirement to stop" names 8a's words from another line, so it is a `definition` reference to NRS-484B-307-8a with the stop words quoted. "After complying with" carries the halt itself, with `source_spans` [s3]; the reference's `why` says why no 8a rule need apply.

**NRS_484B_307_8d** — The permission for motorcycle, moped, trimobile, bicycle, electric-bicycle and electric-scooter riders is the applicability; (3) "the person yields" is the obligation. 8a_o2 is excused through `ruleApplies(8d)`, and a failure to yield is 8d's own violation, so together they cover what the "if" makes unlawful.
- **(1) Two complete cycles.** Since the onset of the rider's halt at the place, some head governing an approach of the intersection has begun a green indication at least the literal two times, and the rider's own head kept the steady red alone throughout (s8).
- **The malfunction / detection-failure cause** is a `scope: none` residue: the unchanged red through two cycles is all the scene shows, and the duty is the same whichever cause holds.
- **(2) "No other device prohibits … such turns, if applicable".**
  - This is read through the passage's recognized turn: right or left `_through_region` at the exit, against regulatory signs coded `no_right_turn` / `no_left_turn` governing the approach or the intersection.
  - It is read from each observation of the passage forward to its exit, so that it is decided at the entry where the exit is recorded.
  - Two intention ids on one span were returned by the validator, which is why this reading was chosen.
- **"Trimobile"** has no applicable definition. It is carried by `ru.motorcycle`, whose contract includes "three-wheeled variants".
- **"After complying with the requirement to stop"** is handled as in 8c.
- Reversal signal: the operator adds a trimobile class atom or definition, or a regulatory-sign code for "no turn on red".

## For the operator

- **Duplicate text.** NRS-484B-307-8a's line contains paragraph (c)'s text ("with 484B.307(8)(c)"), and NRS-484B-307-8c is also a separate line. As a result, `NRS_484B_307_8a_o3` and `NRS_484B_307_8c` are the same duty. If the appendix exists only to resolve the (c) reference, removing it from 8a's line would drop o3 and make o2's (c) exception a composition.
- **Signs the ontology cannot express.**
  - `dev.regulatory_sign` has no code for a sign that prohibits turns only on red ("no turn on red"), nor for a free-standing "stop here on red" sign. 8d's (2) reads only `no_left_turn` / `no_right_turn`.
  - 8a's stop place is read as the recorded stop line.
  - A code for each would close both readings.
- **Trimobile** has no definition in the corpus and no class atom. `ru.motorcycle` carries it, which covers three-wheelers ridden astride but not seated three-wheelers that are not ridden astride.
- **Binder of `NRS_484B_283_1d1`.** 4b and 8b compose `NRS_484B_283_1d1` as an exception with `subject → subject` (pedestrian). If that node's binder is the yielding vehicle, the walk exception never engages for a pedestrian. Its applicability should then be exposed for the pedestrian, or 4b/8b re-planned.
- **New parameters.** `p.lane_opposed_direction_cos` (0.9) and `p.cross_direction_sin_min` (0.5) are new proposals and need review.

<!-- batch-19 -->
# Plan — batch 19 (NRS 484B.307(8)(e), (9)(a)–(c); 484B.300(1); 484B.310(1); 484B.330(1); 484B.360(1))

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts: every manoeuvre or state is a
concept this iteration already proposed (`drv.motion.complete_halt`, `drv.motion.parked`,
`drv.motion.{left,right,u}_turn_through_region`), reused by id. Two nodes carry gaps
(`NRS_484B_300_1`, `NRS_484B_360_1`), so they will not be coded. The other seven are complete.

## NRS_484B_307_8e — no cutting through property around a steady red
**Decision.** A single prohibition. The rule applies to vehicular traffic (traffic ∩ vehicle
aggregates, as the index maps "Vehicular traffic facing the signal"). It must earlier have occupied an
approach carrier `c` into intersection `i` while the governing head showed `circular_red` and no other
state. It is violated when the vehicle comes onto a highway `h2` on which `i` lies, without being in
`i`, having occupied no `st.highway` region at the previous observation. That way it reaches the
cross street from private or public property, which means ground outside every public way's boundary
lines; a sidewalk or shoulder does not count. The cross street's traffic must not face red: some head
governing an approach of `h2` into `i` shows a state other than `circular_red`. "street" is
`asm.within_incorporated_city`, a new assumption: DEF-NRS-484A-265 limits a street to a city, and a
city limit is a legal region class. "to avoid the red signal" is a purpose, read through conduct
(`observable_reading`/purpose). Since facing the red, the vehicle has neither entered `i` nor parked
(`drv.motion.parked`). A vehicle that parks on the lot is using the property, not getting around the
signal.
**Reversal.** If labels count a sidewalk-only cut as property, the property reading on s3 widens. If
labels judge a brief business stop (shorter than `p.parking_min_duration`) as compliant, the purpose
reading needs a shorter dwell parameter.

## NRS_484B_307_9a_o1 — under red + green turn arrow, enter only to make the arrow's movement
**Decision.** This is an act duty (rule 4b). The act is the passage through `i`. Its onset is the
entry (`rel.occupies` rises) and it is recognized at the exit, using the arrow direction's
through-region turn concept (left, right or U). The signal display is read at the entry observation
by a past operator. In `occasion` it is declared `some_moment`, which includes the onset; the
`occasion_s1` and `occasion_s1_outside` scenarios separate the two readings. The subject span is not
an occasion span. "Except as otherwise provided in paragraph (b)" is an `exception` composition with
`NRS_484B_307_9b`. The advisory sentence to drivers is `definitional`: a residue with no duty.
"may enter the intersection only to make the movement" is one obligation span, because the validator
allows only one per node.
**Reversal.** If labels judge a straight passage in which the red + arrow came on only after entry,
the trigger must be read only at the onset. That would need an "at onset" occasion, which the
occasion vocabulary lacks.

## NRS_484B_307_9a_o2 — yield while proceeding under red + green turn arrow
**Decision.** Applies while the subject is in `i` after entering under red + arrow. It owes way to
pedestrians in a crosswalk recorded as marking an entrance of `i`, and to other traffic in `i`.
"the right-of-way" is the standard. It is operationalized with the traffic-conflict technique:
`prim.closest_approach_within` and `prim.closest_approach_distance` with `p.conflict_horizon` and
`p.conflict_centre_clearance`, while moving faster than `p.halt_speed_tolerance`, and `rel.contact`.
The objects of the yield are condition spans. "lawfully" is not composed: every pedestrian and every
other road user is yielded to, a reading disclosed on the obligation span. The rule shares the 9b
exception. `branch_1` has no other party, to show the duty binds the subject alone.
**Reversal.** If labels excuse yielding to a road user that was itself unlawfully in the
intersection, compose the other road users' rules as `compliance`.

## NRS_484B_307_9b — motorcycle/bicycle exception under red + green turn arrow
**Decision.** Applies to the five admitted aggregates plus `ru.motorcycle` for the undefined
"trimobile", reusing the 8d mapping. The rule is judged at the exit from `i`. It applies to a passage
that entered under red + green arrow and is neither a turn in the arrow's direction nor a U-turn,
which covers straight through or turning opposite. Conditions (1)–(4) form the one obligation span:
- (1) A halt before entry, under the rule-4c approach convention with a `history_boundary` scenario.
- (2) While at rest at the place, the red + arrow display has risen at least the literal two times.
  That is how a "complete cycle" is counted, a reading disclosed on the span.
- (3) No `circular_green` appeared during the wait. The cause ("malfunction" or "failed to detect") is
  device status, read through the displays (`observable_reading`/status).
- (4) For a turn, no `no_left_turn` or `no_right_turn` regulatory sign governs.
- (5) The right-of-way is yielded, operationalized as in 9a_o2.

The occasion act is the left and right through-region concepts named in the obligation (the
validator requires exactly these). s1 and s3 are read `some_moment`, s4 `at_recognition`, and the
yield objects s8 and s9 `some_moment`, each with its occasion scenarios.
**Reversal.** If labels show that a different cycle event (for example a rise of red alone) is the
cycle the operator expects, change the counting reading.

## NRS_484B_307_9c — pedestrians facing red + green turn arrow
**Decision.** Facing a head is read as the head being within `p.ped_traffic_signal_facing_reach`
and within the facing angle `p.ped_traffic_signal_facing_cos`, the index mapping of 307_2b.
"Enter the highway" is entering the roadway, the index mapping of 307_8b. The pedestrian already
stands on the highway's sidewalk; that reading is disclosed. "unless permitted … as provided in
NRS 484B.283" is one `exception` per pedestrian-signal rule: `NRS_484B_283_1d1`, `_1d2`, `_1d3_o1`
and `_1d4_o1`. Where a pedestrian signal governs, its own rule decides. Under the "don't walk"
indications, that rule itself forbids starting.
**Reversal.** If labels judge a pedestrian under "don't walk" by 9c rather than by 283, compose only
1d1 and 1d2 as exceptions.

## NRS_484B_300_1 — obey any official traffic-control device (gap)
**Decision.** "the instructions of any official traffic-control device" names no rule. No atom
carries what a device instructs: device atoms carry a state or a code, never the conduct it requires.
The span is mapped to the nearest device atoms and filed as an `operator` gap,
`compliesWithDeviceRules`. The "Except as otherwise provided in NRS 484B.307" list is composed as one
`exception` per 307 node. `NRS-484B-307-11` has no node in the library or this plan, so its bracket
id is its own reference span with a residue. The police-officer exception reuses the index mapping.
**Reversal.** An operator for compliance with every engaged device rule (compare G22) is admitted, or
the operator names the device rules to compose as `compliance`.

## NRS_484B_310_1 — flashing red: stop before entering
**Decision.** A rule-4c duty: a halt is owed before the entry into `i` through a carrier governed by
a `flashing_red` head. The crosswalk and the limit line are read as alternative places (a disclosed
reading). Where the complete entrance lists show neither, the place is `i`'s edge. The search bound
follows the ontology's approach convention, with a `history_boundary` scenario. "the right to
proceed shall be subject to the rules applicable after making a required stop" names no rule. It is
a `reference` span with a residue: the proceeding is judged by those rules themselves.
**Reversal.** If the operator identifies the rules meant (for example `NRS_484B_257_2_o2`), compose
them as `compliance`.

## NRS_484B_330_1 — comply with an authorized flagger
**Decision.** Applies where a `dev.human_direction` with role flagger governs the subject's travel
region. That region must be on a highway and governed by temporary traffic control devices, or by a
temporary-traffic-control zone sign. "Authorized", "clearly marked" and "designated" are status
readings. Compliance is read per indication:
- stop: not passing the flagger's position (`dev.position` against `kin.position`/`kin.heading`).
- slow: not accelerating toward the flagger (`kin.accel_longitudinal` against `p.speed_decrease_decel_min`).
- turn(dir): by the time the subject passes the flagger, its heading has turned toward dir by at
  least `p.turn_heading_min`, or `p.u_turn_heading_min` for a U-turn (`Term.headingSince` from the
  indication's rise).
- proceed: a permission, so not acting on it is not judged.

**Reversal.** If labels treat a constant-speed approach under "slow" as a violation, the slow reading
must require deceleration. If labels judge a vehicle that stays halted under "proceed", that reading
must change.

## NRS_484B_360_1 — school bus 55 mph (gap)
**Decision.** The speed limit is the literal 55 mph on `kin.speed`. "when transporting pupils to and
from school" is a condition the validator will not let `ru.occupant_count` carry as a purpose
reading, because it is an identity attribute. No conduct in the scene tells a pupil trip from any
other. The span is mapped to `ru.occupant_count` as its nearest atom and filed as an `atom` gap,
`ru.pupil_transport_service`.
**Reversal.** The operator admits a service-state atom, or rules that carrying passengers is an
acceptable reading of the words.

## For the operator
- **G (NRS-484B-300-1, operator `compliesWithDeviceRules`).** This decides what conduct a governing
  device requires. It is related to the pending G22 ("in compliance with law"); a single
  "compliance with the engaged rules of a named class" operator would retire both.
- **G (NRS-484B-360-1, atom `ru.pupil_transport_service`).** Needed only if carrying passengers
  (`ru.occupant_count`) is not acceptable as the reading of "transporting pupils".
- **NRS-484B-307-11** is named in 484B.300(1)'s exception list but has no node; it is carried as a
  residue until one exists.
- **Occasion vocabulary.** Signal-phase triggers fixed to the moment of entry (9a_o1, 9b) are
  declared `some_moment`, the nearest available value. An `at_onset` occasion value would state them
  exactly.
- **Vehicle aggregate.** "Vehicular traffic" (8e, 9a) and "driver" (300-1) claim
  `DEF-NRS-484A-320::vehicle`, following the index precedent (NRS_484B_307_2a, LVMC_11_16_030),
  although the term table for those laws lists only `traffic` or `driver`. The validator accepted
  this.

<!-- batch-20 -->
# Plan — batch 20 (NRS 484B.363, 484B.400, 484B.403(2))

No new concepts, no law-local aggregates, no gaps. Concepts reused: `drv.motion.u_turn`,
`drv.interaction.overtake_pass`, `drv.motion.left_turn_through_region`,
`drv.motion.moving_against_carrier`. Declared facts introduced: `asm.school_in_session_day`,
`asm.school_outside_operation_margin`, `asm.pupils_in_class`; intentions reused: `int.right_turn`,
`int.left_turn`. New parameter: `p.approach_lane_same_direction_cos`; the others are proposed again
with the values and conventions already in the catalogue.

## NRS_484B_363_1 — school zone speed (15 mph)

Decision: a motor vehicle (admitted aggregate) whose footprint overlaps a travel region governed
by a `dev.zone_sign` of kind `school` (not an end sign) must not exceed the literal 15 mph.
"Designated as a school zone" is read through the sign, following ontology §9: where a sign marks
the category, the sign is the atom. "Designated" is an `observable_reading` of category `status`.
The exceptions are:
- (a) and (b) are calendar and clock conditions (§9 legal region classes), so they are carried as
  assumptions. (b) is one assumption whose meaning keeps the half-hour margins. Building it from an
  "in operation" assumption with half-hour windows would make almost every short trace unknown,
  because the windows would be truncated.
- (c) is an operational beacon (`dev.speed_limit_beacon` governing the region and not
  `dev.inoperative`) together with `asm.pupils_in_class` and the beacon not flashing.
- (d) is no operational beacon together with `prim.conditions_hold` false for the zone sign.

The section's own definition of "speed limit beacon" is the contract of
`dev.speed_limit_beacon`. Reversal signal: a gate ruling that `dev.inoperative` (contract: "a
signal head") cannot be read on a beacon. That would make "operational" an `atom` gap.

## NRS_484B_363_2 — school crossing zone speed (25 mph)

This node has the same structure as 363_1, with a zone sign of kind `school_crossing` and the
literal 25 mph. Exception (d) in this subsection says "the sign designating the *school zone*".
It is read as the sign designating the zone of this duty, the school crossing zone. The subsection
speaks of no other zone, and a crossing zone need not carry a school-kind sign. Reading the words
literally would make (d) unreachable in most crossing zones. Reversal signal: a label that treats a
crossing zone with no school-zone sign as never excused under (d).

## NRS_484B_363_3 — no U-turn in a school or school crossing zone

Decision: the obligation forbids `drv.motion.u_turn`, the window act with DEF-NRS-484B-077 as its
definition. Occasion:
- The zone trigger is read `some_moment` while the U-turn is under way. "Under way" means the yaw
  rate is above `p.turn_yaw_rate_tol` within the window `p.vehicle_turn_window`.
- The exceptions mapped by elements ((a), (d), (e)) are read `throughout`, each with its two
  occasion scenarios.
- The assumption spans are read the same way in the applicability text. The validator accepts the
  occasion only over element-mapped spans, so they have no occasion scenarios.

"No children present" means no `ru.child` within `p.pedestrian_near_reach` of any region the zone
sign governs. This reads presence in the area, including the sidewalk, and the reach relates a
region to a road user.

Disclosed narrowing of the exception: a child riding a device is not `ru.child`, so it is not
counted, which makes the duty slightly broader than the words. Reversal signal: a labelled scene
in which a child on a bicycle in the zone excuses the U-turn.

## NRS_484B_363_4 — no overtaking in a school or school crossing zone

Decision: the obligation forbids `drv.interaction.overtake_pass(subject, b)`. Here `b` is any other
road user in the vehicle aggregate, quantified in the rule and not a binder. The concept says
nothing of whether `b` moves, so "traveling" is carried beside it: `b`'s `kin.speed` must exceed
`p.halt_speed_tolerance` at some moment of the pass. Occasion:
- Window `p.overtake_window`.
- `under_way` reads the subject's speed together with the bearing, overlap and heading relations
  that begin the act.
- The zone trigger is read `some_moment` and the exceptions `throughout`.

The permit scenario has no other vehicle and expects compliance, which shows the duty binds the
subject alone. Reversal signal: a label that judges a pass of a vehicle at rest in the zone as a
violation (then drop the travelling condition).

## NRS_484B_400_1_o1 / NRS_484B_400_1_o2 — right turn lane or extreme right lane

Decision: the line holds two alternative duties: the right turn lane where the highway has one,
and otherwise the extreme right lane. These cannot be one contiguous obligation span, so they are
two nodes, each the other's `sibling`.

"Intends to turn" and "The turn is a right turn" are both carried by `int.right_turn` at the
intersection `i`. The approach and the turn are read at the observation before the subject enters
`i`: the approach ends there and the turn begins there.
- `_o1` requires occupying the single right `st.turn_lane` that enters `i` with a direction aligned
  to the subject's approach lane.
- `_o2` applies where there is no such lane. It requires the lane entering `i` whose
  `st.lane_adjacency` ordinal equals its count. An unlaned directed approach segment is read as a
  single line of traffic.

Referring and defining spans: "as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a,
NRS-484B-223-4b]" is a `definition` reference. It borrows "a single right lane to be used only for
turning"; "single" is kept as "exactly one". It composes neither rule, because the lane exists
whatever any vehicle does in it.

Disclosed narrowing: a lane change into the required lane earlier on the approach is not a breach.
Reversal signal: a label that judges such a late lane change a violation, which would require
reading the whole approach segment.

## NRS_484B_400_2a — left-turn approach next to the centerline

Decision: the node applies where `int.left_turn` is declared at intersection `i` and every highway
`i` lies on is two-directional. Two-directional (DEF-NRS-484B-073) means no `st.median_or_divider`
on the highway and two of its carriers with opposed designated directions, within
`p.lane_opposed_direction_cos`.

At the observation before entry, the subject must occupy a carrier entering `i` that is lane
ordinal 1 of its direction, or, where it occupies no lane entering `i`, a directed approach segment.
It must also occupy no carrier on the same way whose direction is opposed.

The side of the centerline is read through designated directions, because DEF-NRS-484A-040 says the
line marks "each portion of a highway allocated to traffic proceeding in the two opposite
directions". `st.centre_line` is not used: no relation ties a centre-line region to the subject's
approach without using distance as belonging. "That portion … nearest the centerline" is read at
the granularity of lanes; this narrowing is disclosed. Reversal signal: a label that requires a
lateral position within a single approach lane.

## NRS_484B_400_2b — leave the intersection right of the centerline

Decision: the act is `drv.motion.left_turn_through_region(subject, i)`. Its boundary is an event:
the onset is the entry into `i` and the recognition is the exit. At the exit, the subject must move
against the designated direction of no lane its footprint overlaps (`drv.motion.moving_against_carrier`,
speed tolerance `p.halt_speed_tolerance`).

The intention is read at some observation while the turn is under way (branch_2 and branch_3 show
both sides). The intersection kind and the two-directional condition are static map facts read at
recognition. The validator accepts the occasion only over element-mapped spans.

Disclosed narrowing: an entered highway with no mapped lane is not read. Reversal signal: a source
whose receiving roadways carry no lanes.

## NRS_484B_403_2 — obey a device prohibiting U-turns

Decision: the devices whose indication is a U-turn prohibition are read as `dev.regulatory_sign`
of code `no_u_turn` while its conditions hold. A signal's arrows indicate stop or go, and no marking
in the ontology states a U-turn prohibition. "Obey the directions" means that `drv.motion.u_turn`
is not recognized while, at some moment of the turn, the subject is under the sign. "Under the
sign" means one of:
- the subject occupies a region the sign governs; or
- the subject occupies an intersection that a governed lane enters, having come from that lane.

The second case reads the sign's control of the junction through `dev.governs` and
`st.lane_enters`, as the ontology prescribes.

The subject's class uses the run's admitted `DEF-NRS-484A-320::vehicle`. It is the vehicle named in
the words of the "driver" definition; the table lists no vehicle row for this law, and the
validator accepted the claim. Reversal signal: the selection role ruling that this law may not
claim that aggregate.

## For the operator

- **Beacon "operational".** It is read through `dev.inoperative`, whose contract names "a signal
  head". If a source cannot declare it for speed limit beacons, exceptions (c)/(d) of 363(1)–(4)
  will be unknown wherever a beacon is present. Consider widening that contract to lamp devices.
- **School assumptions.** `asm.school_in_session_day`, `asm.school_outside_operation_margin` and
  `asm.pupils_in_class` must be declared per trace. Wherever the duty would otherwise be breached,
  an undeclared assumption makes the verdict unknown.
- **Child presence.** `ru.child` covers pedestrians only. Children on bicycles or scooters in a
  school zone cannot be counted for 363(3)(a).
- **Pavement markings.** No marking atom carries a U-turn prohibition or similar word or symbol
  marking (403(2)).

<!-- batch-21 -->
# Plan — batch 21 (iteration 1)

Eleven nodes for eight law lines. No new concept records: every manoeuvre or state of motion is a
concept already proposed in this iteration (`drv.motion.u_turn`, `drv.motion.complete_halt`). No
law-local aggregate (`aggregates.jsonl` is empty). Two kinds of gap are filed: the atom gap
`ru.disabled` (NRS-484B-440-1, three nodes) and the operator gap for "in compliance with law"
(NRS-484B-450-1a/1c/1e). Those six nodes are not coded until the operator decides the gaps.

## NRS_484B_403_3 — no U-turn in a business district

**Decision.** The act is `drv.motion.u_turn` on the vehicle aggregate. The definition DEF-NRS-484B-077
says "upon a highway", which the concept does not carry, so the rule carries it beside the concept:
`rel.occupies` of an `st.highway`. The index maps "shall not make a U-turn" to the concept alone
(NRS_484B_363_3). Here the defined word adds the highway, so the mapping adds it too. The business
district is the declared assumption `asm.business_district`, read where the act is recognized; the
validator does not let an occasion name an assumption-carried span. The exception "at an
intersection" is read `throughout` the act (the default for an exception). "On a divided highway" is
`rel.occupies` of a highway on which an `st.median_or_divider` lies, also read `throughout`. "Where an
appropriate opening or crossing place exists" is the divider's opening attribute that the footprint
overlaps at `some_moment` of the act, with a status reading of "appropriate". The reversal is
recognized with the act's window `p.vehicle_turn_window`. **Reversal signal:** a labelled
intersection U-turn whose turn begins on the approach lane before the intersection would show that
the intersection should be read `some_moment`, not `throughout`.

## NRS_484B_407 — no turn-around on a curve or near a crest without 500 ft of sight

**Decision.** The act is `drv.motion.u_turn`; its contract quotes "so as to proceed in the opposite
direction".
- "Upon any curve" is the feature with no size given. It is read as `st.curvature` at the subject's
  place on its `st.roadway` standing clear of zero, above `p.curvature_resolution` (a resolution only).
- "The approach to or near the crest of a grade" is the ground distance from the body to an
  `st.crest` region (`st.region_geometry`) at most `p.crest_near_reach` (proposed: 150 m, the AASHTO
  crest-curve and stopping-sight length).
- "Cannot be seen … within 500 feet" is `st.sight_distance` below the literal 500 ft, with a
  perception reading. The sight-distance contract states what could be seen at a place, whether or
  not another vehicle is there, so no other vehicle is quantified.

The conditions are read at `some_moment` of the act, (curve or crest) and sight together at one
observation. **Reversal signal:** if `p.crest_near_reach` is judged to widen the condition beyond the
words, the operator lowers the value. The rule names only the parameter.

## NRS_484B_410_o1 / NRS_484B_410_o2 — start or enter only with safety

**Decision.** There are two prohibited acts, so two nodes: starting a halted vehicle on a highway
(o1), and entering upon a highway (o2).
- "Stopped, standing or parked": the union of the three definitions is every halt, so it is read as
  `drv.motion.complete_halt`. Their exclusions (conflict or device halts, passenger halts, loading
  halts) overlap only on purposes that no conduct shows.
- **Start:** the halt held at the previous observation, on a highway, and does not hold now.
- **Entry:** occupancy of a highway rises.
- **The exception** "except when stopping, standing or parking where no parking is permitted" is read
  on the halt just before the event. It holds if the vehicle was halted in a no-parking curb zone or
  red curb, or in a travel region governed by a no-parking, no-standing or no-stopping sign whose
  conditions hold (status reading).
- **"With safety"** qualifies a concrete act, so it is not a surrogate. It is operationalized by the
  traffic-conflict technique: at the onset, no other road user has a closest approach within
  `p.conflict_horizon` at or below `p.conflict_centre_clearance`.

**Reversal signal:** if the exception's literal reading proves to have been meant only for the start
(o1), it is dropped from o2.

## NRS_484B_413_3 — signal before stopping or sudden slowing

**Decision.** There is one obligation span: "without first giving an appropriate signal". It is read
as `sig.brake_lamp` lit or `sig.hand_signal` stop_or_slow, shown at the onset or within
`p.stop_signal_lead_window` behind it.
- "Shall not stop" is a trigger: the onset of `complete_halt`. Here stopping is prohibited, so
  DEF-NRS-484A-260 applies, and its exclusion is carried beside the concept. That exclusion is a
  halt behind a road user ahead in the lane within `p.queue_halt_gap`, or one a stop sign, yield
  sign, red signal, railway signal or officer's stop direction requires in the region the vehicle
  occupies.
- "Suddenly decrease the speed" is the standard: deceleration beyond `p.sudden_decel_min`
  (proposed: the AASHTO comfortable deceleration, 3.4 m/s²).
- "Immediately to the rear" is a condition: a vehicle behind in the same lane within
  `p.rear_signal_reach`. No such vehicle means no duty (idle scenario).

**Reversal signal:** if a label treats the signal as owed with no follower present, the follower
condition is wrong.

## NRS_484B_440_1_o1 / _o2 / _o3 — stopping on rural highways

**Decision.** There are three obligations, so three nodes:
- **o1:** no halt on the roadway where it is practicable to leave the vehicle off it. "Practicable" is
  operationalized as a shoulder or bay on the same way within `p.offroad_refuge_reach`.
- **o2:** a free width of at least `p.free_passage_width` to the far road edge beside a standing
  vehicle, with no obstruction.
- **o3:** `st.sight_distance` of at least 200 ft at the standing vehicle.

All three share these readings:
- The district is the negation of `asm.business_or_residence_district`.
- "Whether attended or unattended" is a scope-none residue.
- The paved or main-traveled part is `st.roadway`.

The disabled-vehicle exception restricts the duty, and no atom carries a vehicle's condition. The
ontology forbids an assumption for it. So it is mapped to its nearest atoms (`kin.engine_running`,
`sig.hazard`) with the atom gap `ru.disabled`, the same proposal as smoke31 G19. **Reversal signal:**
acceptance of a `ru.disabled` atom (or of G19) lets all three nodes carry the exception and be coded.

## NRS_484B_450_1a / 1c / 1e — no halting on a sidewalk, within an intersection, on a crosswalk

**Decision.** "Stop, stand or park" is every halt (`complete_halt`), the same mapping as the index row
"No person shall stop, stand or park a vehicle". The DEF-260 exclusion is the law's own exception.
- **"Necessary to avoid conflict with other traffic"** is a standard. It is read as a road user
  ahead in the same lane within `p.queue_halt_gap`. The traffic aggregate is not listed: the
  validator does not admit an aggregate as an operationalization concept. "Traffic" covers every
  class, so any road user counts.
- **"The directions of a police officer"** and **"official traffic-control device"** reuse the index
  atoms.
- **"In compliance with law"** carries the operator gap. On 1c the validator requires smoke31 G22
  (still proposed). The same words in 1a and 1e mean the same thing, so they carry the same gap
  (rule 7). Device-required halts are only part of the halts that law requires. A left turner held
  inside an intersection by oncoming traffic, for example, halts in compliance with NRS 484B.253,
  and no device shows that.
- In 1a, subsection 3 (bicycles, electric bicycles and electric scooters on a sidewalk) is a
  scope-none residue. DEF-NRS-484A-320 excludes all three classes from "vehicle", so the duty never
  binds them. "Except as otherwise provided in subsection 3" is therefore boilerplate.

**Reversal signal:** an operator decision on G22 (an operator added, or a reading allowed) lets the
three nodes be re-recorded with `gap_resolutions` naming it.

## For the operator

- **G22 ("in compliance with law")** now blocks NRS-484B-450-1a, -1c and -1e. LVMC_11_52_130_A11 in
  this iteration maps the same words with device atoms and no gap. Whichever way G22 is decided
  should be applied to both.
- **`ru.disabled`** (as in G19) blocks NRS-484B-440-1 and, by the pending G19, NRS-484B-270-3.
- **NRS-484B-410's exception** "except when stopping, standing or parking where no parking is
  permitted" reads oddly in the corpus text. It is planned as written; the source wording may be
  worth checking.
- **New parameter proposals:** `p.crest_near_reach`, `p.sudden_decel_min`, `p.rear_signal_reach`,
  `p.stop_signal_lead_window`, `p.offroad_refuge_reach`, `p.free_passage_width`. All other
  parameters are re-proposed with the values already listed this iteration.

<!-- batch-22 -->
# Plan — batch 22: NRS 484B.450(1)(g)–(m), (o)

All eight lines share one preamble, and every node segments it the same way, reusing the mappings earlier batches made of the same words:

- "A person" maps to the vehicle aggregate, through the vehicle's controlled motion (an `agency` reading).
- "shall not stop, stand or park a vehicle," maps to `drv.motion.complete_halt` plus the vehicle aggregate.
- "with other traffic" maps to `rel.ahead_behind_in_lane`, `rel.surface_gap` and the traffic aggregate.
- "or in compliance with law" maps to a stop sign or a red traffic signal governing the occupied travel region.
- "or the directions of a police officer" maps to `dev.human_direction` with role police_officer and indication stop.
- "or official traffic-control device," maps to a stop sign, a yield sign, a red signal or an active railway signal or gate governing the occupied region.

"except when necessary to avoid conflict" is a `standard`. It is operationalized as a halt behind a member of traffic ahead in the same lane, within `p.queue_halt_gap`; a narrowing discloses that halts for crossing traffic are not read. Stop, stand and park are each a halting under DEF-484A-260/250/155, so forbidding all three forbids any halt. One concept carries that: the catalogued proposal `drv.motion.complete_halt`. No node proposes a new concept, and `aggregates.jsonl` is empty because no clause defines its own members.

**NRS_484B_450_1g.** The place is the approach to a vehicular traffic signal (`dev.traffic_signal`, per DEF-484A-290 "alternately directed to stop or proceed"). The approach is a travel region the subject occupies that the signal governs, or that enters an intersection the signal governs. The head (`dev.position`) must lie ahead along that region's direction, and the subject's front must be within the literal 30 ft of it. "Located at the side of a highway" means the head lies laterally beyond a roadway edge in the subject's frame (`prim.region_lateral_offset`), rather than over the roadway. Pedestrian, lane-control and railway signals are left out by the definition and the law's own words. Reversal signal: a source that records how a signal is mounted, or a reviewer who rejects the lateral test against the roadway edge.

**NRS_484B_450_1h.** The adjacent curb is the roadway edge nearest the safety zone, computed from both regions' signed lateral offsets from the subject. The subject is "between" when the zone and that edge lie on opposite sides of it, the zone is alongside (body distance at most the lateral offset), and the subject is not inside the zone. "Within 30 feet of points on the curb opposite the ends" is the right-triangle combination of two gaps: the gap along the carrier beyond the zone's end (`prim.region_offset_along` less half the subject's length) and the gap to that curb. Reversal signal: a reviewer who rules that "adjacent" between two regions needs its own relation atom; that would be an atom gap on s9.

**NRS_484B_450_1i — carries a gap.** "the nearest rail of a railroad" can only reach `st.railway_crossing`, which holds rails only where a railway crosses the roadway. That leaves two problems:
- a railroad's rails running beside a highway are read by no atom;
- the crossing kind cannot exclude streetcars, as DEF-484A-200 requires.

Since a duty must cover its domain, I filed the atom gap `st.railway_track` (kind ∈ {railroad, streetcar}) on s9 instead of narrowing the trigger. The node keeps its full mapping to the nearest atoms. Reversal signal: the operator retires the gap, or declares that railway crossings are the only rails a source maps within 50 ft of a highway and that streetcars are out of scope.

**NRS_484B_450_1j.** The first place is within the literal 20 ft of a `st.fire_station_entrance`. The driveway definition's "private ownership" is read from the feature's presence (a `status` reading). The second place is "on the side of a highway opposite the entrance". The subject occupies a highway, and some roadway edge of that highway lies between the subject and the entrance that is farther from the subject than every edge on its other side. That means the subject is past the middle of the way, which works for two-way, one-way and divided ways without needing a centre line. The subject must also be within the literal 75 ft of that same entrance region. Reversal signal: a source that maps highways without their outer edges.

**NRS_484B_450_1k.** "Alongside or opposite" means a `st.obstruction` of any kind, lying on the highway the subject occupies, is off to the subject's side rather than ahead or behind. "Would obstruct traffic" is a standard operationalized with `p.free_passage_width`. Traffic is obstructed when the free width is too narrow on both sides of the halted vehicle: between its body and the object, and between its body and the roadway edge on its other side. A narrowing on that standard span discloses two things: the passage beyond the object's far side is not read, and "traffic" is read as the passage traffic needs, not as traffic actually present. Reversal signal: a labelled scene in which traffic passes beyond the object while the rule reports a violation.

**NRS_484B_450_1l.** "any vehicle stopped or parked" is another vehicle of the aggregate, quantified inside the applicability (the idle scenario has none). It is at rest (`drv.motion.complete_halt`), and its body is within the new proposed parameter `p.edge_standing_gap` of a roadway edge lying on a highway. The subject is on its highway side when the two are side by side (`rel.longitudinal_overlap` ≥ 0) and the other vehicle and its edge lie on the same side of the subject. The words state no distance, so none is added.

**NRS_484B_450_1m.** `st.elevated_structure` ("bridge, viaduct or tunnel carrying the roadway") carries both the bridge/elevated-structure span and the "highway tunnel" span, anchored by `rel.occupies`.

**NRS_484B_450_1o.** The prohibiting devices are:
- `dev.regulatory_sign` with code no_stopping, no_standing or no_parking, under `prim.conditions_hold` and governing the occupied region;
- `st.curb_zone` of kind no_stopping or no_parking that the subject occupies.

The obligation is read respectively, and a `reading` narrowing on the obligation span s2 discloses this:
- under no-stopping, any halt is forbidden;
- under no-standing, `drv.motion.parked` with `p.standing_min_duration`;
- under no-parking, `drv.motion.parked` with `p.parking_min_duration`.

The purpose part of standing and parking is read through how long the vehicle has been at rest (a `purpose` reading). Reversal signal: a reviewer who holds the literal reading, under which any halt at any of these places is forbidden.

**"or in compliance with law" (every node).** I mapped it as earlier batches did (NRS_484B_450_1a, LVMC_11_52_130_A11): a halt commanded by a stop sign or a red signal that governs the occupied region. The validator does not allow a narrowing on an exception span, so the limits of this reading are stated in the element's justification and here: a halt that another law requires without such a device is not excused.

## For the operator

- Open operator gap smoke31-1111-0039:G22 sits on the same words "or in compliance with law", filed on NRS-484B-450-1c. This iteration's batches, and this one, carry those words with device atoms instead. If G22 is accepted, these eight nodes, 1a, 1c, 1e and LVMC_11_52_130_A11 should be re-planned together with it.
- The NRS_484B_450_1i gap `st.railway_track` blocks only (1)(i). A road-crossing-only reading would unblock it, but the rule would then be wrong next to rails running beside a road and next to streetcar lines.
- The parameters re-proposed here are `p.halt_speed_tolerance`, `p.queue_halt_gap`, `p.free_passage_width`, `p.standing_min_duration` and `p.parking_min_duration`, each with the same name, value, unit and convention earlier batches used. The only new one is `p.edge_standing_gap`.

<!-- batch-23 -->
# Plan — batch 23 (NRS 484B parking: curb position, angle, night lamps, alleys, narrow and one-way highways)

No new concepts: every node reuses `drv.motion.complete_halt` or `drv.motion.parked` from this iteration. No law-local aggregates (`aggregates.jsonl` is empty). No composition: the library has no composable node, and no span of these laws names another rule. Every parameter is one an earlier batch proposed, reused with its value and convention unchanged, except `p.bay_angle_cos_tolerance` and `p.entrance_block_gap`, both of which are new and belong to gapped nodes.

**How "stop, stand or park" is read where it is prohibited (NRS_484B_460, NRS_484B_477_1a, NRS_484B_477_1b, NRS_484B_477_2).** The table resolves "stop" to two definitions, each with its own scope. Where stopping is prohibited, DEF-NRS-484A-260 applies: "any halting, even momentarily … except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device". Standing and parking are halts too, so the three verbs together are read as the halting they all are (`drv.motion.complete_halt`), with the stopping definition's exception carried by observable conduct:
- a halt in a travel region governed by a signal, a stop sign, a yield sign, a railway device or a person directing traffic; or
- a halt queued behind a road user ahead in the lane within `p.queue_halt_gap`.

This follows the index mapping of "shall not stop" (NRS_484B_413_3). The words "No person shall stop, stand or park a vehicle" are mapped in the index to the halt alone (LVMC_11_52_130_A11). That node carries the exception on other spans of its own, which is why the device and queue atoms here sit on the obligation span. Each node discloses this as a narrowing. The signal that would reverse it: a labelled recording in which a vehicle queued or halted at a signal inside the regulated place is labelled violated.

**NRS_484B_457_1** — one obligation: the right-hand wheels parallel to the right-hand curb and within 18 inches of it. Subsections (2) and (3), which the text appends, are exceptions of this node.
- **Trigger.** "stopped or parked" is a halt (`complete_halt`). A halt made for traffic (at a device governing the subject's region, or queued) is read as not the stop the section speaks of. This is disclosed as an `observable_reading` of category `purpose`, since why a vehicle is stopped is not observed; DEF-NRS-484A-260 supports it. The validator refused a plain narrowing on the trigger.
  - Reversal: a label that treats a vehicle halted at a red light away from the curb as violating 457(1).
  - The words "stopped or parked" are mapped differently from the index (450_1l maps them to the halt alone): there they describe another vehicle; here they decide when the subject's duty arises.
- **Curbs.** "Adjacent curbs" is read from `st.lane_marking` type `curb`, because `st.road_edge` ("curb or edge") cannot tell a curbed edge from a plain one. The distance to the curb is measured to a road edge on the same way, on the subject's right.
- **Wheels and parallel.** The body outline stands for the wheels, which is lenient by the wheels' inset (a narrowing). "Parallel" means within `p.parked_heading_cos` of the carrier direction, headed with it.
- **Left-curb exception (2).** Permission by ordinance shows on no road feature, so it is the assumption `asm.left_curb_parking_permitted`, a legal designation of the way.
- **Angle-parking exception (3).** Read from the posted `angle_parking` sign or an angled bay (status). The words binding the Department and local authorities, on where angle parking may be permitted, are part of the device's presumed lawful status: they are carried inside that exception span, not as a road-user condition.
- **The opening words.** "Except as otherwise provided in this section" only points at (2) and (3), so it is a residue of scope `none`.

**NRS_484B_460** — planned but not codable: an `operator` gap.
- The vehicle's angle to the curb has a cosine (its heading dotted with the carrier direction), while the angle the device indicates is the bay's `angle` attribute in degrees. Term has no trigonometric operator, so the two cannot be compared. The gap proposes `Term.cosDeg`.
- The obligation words are one span (the validator requires one obligation span), carried by the halt plus the nearest atoms of the angle.
- "Those highways which have" devices is read as the region the angle sign governs, or an angled bay the subject occupies, where an indicated angle exists.
- Reversal: an operator able to compare the two, or an ontology row giving a bay's orientation as a direction.

**NRS_484B_473_2** — planned but not codable: an `operator` gap on "lawfully".
- "Lawfully parked" turns on the verdict of every parking rule the vehicle engages, and the words name none. `Formula.rule` composes one named rule. No published parking rule exists to compose either.
- The gap repeats the need of carried-over gap smoke31-1111-0039:G22 ("in compliance with law").
- The rest is planned:
  - parked: `drv.motion.parked`;
  - nighttime: `env.darkness`;
  - on a highway: `st.highway`;
  - lights displayed: headlamp or position lamp;
  - "cowl or parking lamps not used": the headlamps are lit. `sig.position_lamp` also lights with the headlamps, so it cannot tell parking lamps used in their place.
  - The duty is that the headlamp is not `high_beam`.
- Reversal: the operator retires G22 or decides this gap.

**NRS_484B_477_1a**
- "Unless otherwise provided by ordinance" is the assumption `asm.local_alley_ordinance`: an administrative designation of the alley, with no road feature.
- "In a business district" reuses `asm.business_district`.
- The standard "expeditious loading or unloading of goods" is operationalized by `drv.motion.parked` with `p.parking_min_duration`. The unobserved purpose is read through the halt's brevity: a halt beyond the temporary-halt bound is not excepted. This is disclosed on the standard span.
- Reversal: a labelled short halt without loading judged violated, which would call for door-open evidence (`sig.door_open`) instead of duration.

**NRS_484B_477_1b**
- "In any other" refers to paragraph (a)'s "alley in a business district". It is carried as `asm.business_district` not holding, so the alleys of (a) are left out with their qualification intact.
- The words "in such a manner, or under such conditions as to leave available less than 10 feet …" are a condition on the prohibited halt (the validator requires one obligation span).
- The free width is measured on each side of the body:
  - to the nearest road edge (ground distance, side from the lateral offset);
  - or to an obstruction or a halted member of traffic alongside on that side;
  - a side is free when everything on it is at least 10 feet away.
- "Vehicular traffic" claims the traffic and vehicle aggregates: members of traffic halted alongside narrow the width, and the width serves vehicles whether or not one is present.
- The obligation is the halt's prohibition, with the stopping definition's exception.

**NRS_484B_477_2** — planned but not codable: an `atom` gap.
- `st.driveway_or_alley_entrance` "does not tell an alley's entrance from a private road's or driveway's". Inside an alley it would mark the alley's own mouth onto the street, which is no "entrance to any abutting property".
- The gap proposes `st.property_entrance`.
- "Block" is read as overlapping the entrance's mouth, or standing within `p.entrance_block_gap` of it (newly proposed).
- Reversal: an attribute or atom telling property entrances apart.

**NRS_484B_490**
- "Devices … prohibiting parking upon a narrow highway" is the `dev.zone_sign` kind `narrow_highway` governing the subject's travel region, with its conditions holding. The highway's narrowness is the posting's designation, read from the sign (status).
- "Upon any such highway" is the same governed region.
- "Park" is `drv.motion.parked` with `p.parking_min_duration`.
- Reversal: if the narrow_highway zone sign proves to be a warning only, the trigger needs a no_parking regulatory sign inside such a zone.

**NRS_484B_493**
- Notice is read from:
  - a `no_standing` or `no_parking` regulatory sign whose conditions hold, governing the subject's region; or
  - a `no_parking` / `no_stopping` curb zone the subject occupies.
- "Street" is a highway inside a city (DEF-NRS-484A-265), carried by `asm.within_incorporated_city` on its own span. The way itself is carried by the one-way roadway it lies on.
- The left-hand side is relative to the roadway's designated direction: the subject is nearer a road edge on the left of that direction than every edge on its right. The side is taken from the lateral offset, signed by heading·direction.
- "Stand or park" is `drv.motion.parked` with `p.standing_min_duration`, following the index mapping of "No person shall stand or park a vehicle".

## For the operator

- Three nodes carry gaps and will not be coded until they are decided:
  - `Term.cosDeg` (NRS_484B_460);
  - a compliance-with-all-engaged-rules operator for "lawfully" (NRS_484B_473_2, the same need as G22);
  - `st.property_entrance` (NRS_484B_477_2).
- `asm.local_alley_ordinance` (new) and `asm.business_district` must be declared per map for the alley nodes. An undeclared assumption leaves their verdicts unknown.
- `p.parking_min_duration` (180 s) and `p.standing_min_duration` (60 s) are windows behind the observation. On recordings shorter than these windows, every long halt reads unknown, not violated.
- `st.lane_marking` type `curb` is the only atom that shows the presence of curbs in NRS_484B_457_1. A source that does not label curb-type lane sides leaves that law unknown.

<!-- batch-24 -->
# Plan — batch 24 (NRS 484B.497 – 484B.557)

No law-local aggregates (`aggregates.jsonl` is empty); every class claim uses an admitted id of the
definitions table. No new concept: all nodes use `drv.motion.complete_halt` and `drv.motion.parked`
as proposed earlier in this iteration. No gap. The validator accepts all nine nodes.

**"Stop" with two posted definitions.** The table lists "stop" as ambiguous between
DEF-NRS-484A-255 ("when required") and DEF-NRS-484A-260 ("when prohibited"). Each definition states
its own scope, so the clause's own words pick one; that is not a choice between competing definitions.
The prohibitions (500, 503, 507, 510, 517) meet 260's scope: in 507, 510 and 517 the table itself
resolves "stopping" to 260. 557's "shall stop" meets 255's scope. In every "stop, stand or park"
obligation, 260's exclusions are carried beside the halt, as the mapping index does for "shall not
stop, stand or park a vehicle" (NRS_484B_477_2):
- a halt in a queue (`rel.ahead_behind_in_lane`, `rel.surface_gap` ≤ `p.queue_halt_gap`);
- a halt on a region governed by a stop sign, a yield sign, a red or yellow signal, a railway
  signal, or a police officer's stop indication.

"Other traffic" is read as any road user ahead, without the traffic aggregate, because that
aggregate is not admitted for these laws.
Reversal signal: a label that counts a halt queued in a loading zone as a violation.

## NRS_484B_497
- **Decision:** one node. "Stand or park" maps to `drv.motion.parked` with `p.standing_min_duration`, as in the index (LVMC_11_52_040_A).
- **Left-hand side:** the road edge nearest the vehicle, on the way of the one-way roadway, lies to the left of the roadway's designated direction. That side is `prim.region_lateral_offset`, turned into the roadway's frame by the sign of heading·direction, because a parked car may face either way.
- **Laned:** some `st.lane` lies on the same way.
- **Permitting devices:** a marked `st.parking_space`, an `angle_parking` regulatory sign, or a `parking_restricted` zone sign whose conditions hold.
- **Reversal signal:** a labelled recording that judges a vehicle parked against the left curb inside a signed time-limited zone as violating, or one that counts a laned two-way roadway's left curb.

## NRS_484B_500
- **Decision:** one node.
- **Designated places:** a hazardous place is a `dev.zone_sign` of kind `hazardous_place`. A congested place, which has no zone kind, is a `no_stopping` regulatory sign. Either sign's presence stands for the authority's designation (status reading).
- **Reversal signal:** an operator ruling that a no-stopping sign alone is not a congested-place designation. The `congested` branch would then become an atom gap (a zone kind `congested_place`).

## NRS_484B_503
- **Decision:** one node. "Expeditious" is operationalized as a halt that has not lasted `p.standing_min_duration`.
- **Loading passengers:** read by conduct, as a door open (`sig.door_open`) at some observation of the same halt (purpose reading).
- **Hours:** read from `parking_restricted` zone signs governing the vehicle's region (`prim.conditions_hold`). A marked zone with no such sign is read as effective at all hours.
- **Residue:** "for any purpose or period of time" is a scope-none residue.
- **Reversal signal:** a zone whose hours are set by ordinance, not posted. That would need an assumption for those hours.

## NRS_484B_507_1
- **Decision:** one node for both sentences, because 507(2) is an exception to 507(1).
- **Materials exception:** a door open during a halt by a truck or commercial motor vehicle, bounded by `p.commercial_loading_max_halt`. The class tells goods loading from passenger loading.
- **Passenger exception:** a door open during a halt within `p.standing_min_duration`, provided no truck (`ru.aggregate` motor_vehicle plus `ru.truck`, whose contract is "for carrying goods") stands halted outside the zone within the new `p.zone_entry_wait_reach`.
- The validator rejected a purpose reading carried by a class on "used for the transportation of materials". That span is now carried by `ru.truck`'s contract, not by a reading.
- **Reversal signal:** a passenger car making a package delivery labelled compliant past the standing duration.

## NRS_484B_510
- **Decision:** one node.
- **Restricted purpose:** a halt is for the restricted purpose where the governing `parking_restricted` zone sign's conditions hold for the vehicle. This includes its class condition, through `prim.conditions_hold`.
- **Known defect:** the primitive joins hours and class, so a halt outside the posted hours reads as not for the purpose (disclosed).
- **Passenger vehicle:** this term is undefined; it is read as the vehicle aggregate, neither `ru.truck` nor `ru.trailer_or_combination`.
- **Reversal signal:** a labelled halt outside posted hours that is judged compliant. That would need an operator that splits time conditions from class conditions (see below).

## NRS_484B_517
- **Decision:** one node.
- **Prohibition:** a non-bus in a `bus_stop` curb zone, or a non-taxicab in a `taxicab_stand` curb zone, may not halt. The admitted aggregates for bus and taxicab are used.
- **Designated and signed:** read from the curb zone's presence.
- **Exception:** "temporarily" and "expeditiously" are both bounded by `p.standing_min_duration`. Interference means a bus or taxicab halted outside the zone within the waiting reach.
- **Reversal signal:** a label treating a briefly halted car as compliant while a bus waits behind it.

## NRS_484B_533
- **Decision:** one node with a single obligation span. The validator requires exactly one, so the engine, brake and wheels spans were merged.
- **Applicability:** a halt (stand, DEF-NRS-484A-250) with nobody in the vehicle (`ru.occupant_count`). The grade must exceed `p.grade_resolution`: "perceptible" is the grade's presence at the source's resolution.
- **Obligation:** engine off, parking brake set, and the front wheels steered beyond `p.steer_angle_resolution` toward the nearest road edge.
- "Stand" here is the bare halt, not `parked`, because an unattended vehicle receives no passengers.
- **Reversal signal:** a label that counts a driver beside the car as attending it.

## NRS_484B_557_o1 / NRS_484B_557_o2
- **Decision:** two obligations — "shall stop within … of the nearest track" and "afterward may proceed only upon exercising due care".
- **First sentence:** it empowers the Department of Transportation and local authorities. It is carried as conditions: the crossing (`st.railway_crossing` on a highway) and the stop sign. The designation is read from the sign's presence. The sign is tied to the crossing through a chain: the sign governs the approach region, and that region lies on the same highway as the crossing.
- **o1:** a duty of rule 4c. The event is the entry into the crossing. The act is a halt with the body between the two literal distances, outside the crossing. The search runs back to the approach start (last farther than the upper literal) or to the previous exit. It has a `history_boundary` scenario.
- **o2:** the condition "afterward" refers to the halt that o1 states, so o2 carries that halt in full (the same span as a condition), not compliance with o1. "Due care" is a state-of-mind standard, so o2 is a **surrogate**. It is read as no rail-vehicle conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`) and no contact while the vehicle is on the crossing.
- **Reversal signal for o1:** a crossing whose region outline does not begin at the nearest rail. Its distances would then need the rail itself.

## For the operator
- `kin.steer_angle` states no sign convention. NRS_484B_533 reads it left-positive, like `kin.yaw_rate`; a source with the opposite convention inverts that node's verdicts.
- `prim.conditions_hold` joins a sign's time windows and its class or occupancy conditions into one verdict. NRS_484B_510 needs the class condition alone ("the purpose to which parking … is restricted") outside the posted hours. Without a way to read them separately, a halt outside the posted hours reads as not for the restricted purpose.
- There is no device kind for a "congested place". NRS_484B_500 reads it as a `no_stopping` regulatory sign.
- New parameters proposed for review: `p.zone_entry_wait_reach` (10 m), `p.grade_resolution` (0.005), `p.steer_angle_resolution` (2 deg).

<!-- batch-25 -->
# Plan — batch 25 (iteration 001)

Eight law lines, nine nodes. No law-local aggregate (`aggregates.jsonl` is empty). No new concept record. The plan reuses `drv.motion.complete_halt` and `drv.lane.entering_adjacent_lane` from earlier batches. No gap is carried.

## NRS_484B_560_3_o1 — keep as far right when a stop is required at a railroad crossing
- **Decision.** The line has two obligations, so it becomes two nodes. In this node the second obligation and its "unless … four or more lanes" exception are `sibling`.
- **Trigger ("When stopping is required").** The requirement to stop is read from the devices that require a halt of the subject's traffic. Each must govern a travel region the subject occupies. They are:
  - a railway signal with its lights flashing, or its gate lowering or down;
  - a stop sign;
  - a traffic signal showing circular red;
  - a police officer or railroad flagger directing stop.
- **"At a railroad crossing".** The subject's body is within the new parameter `p.railroad_crossing_approach_reach` of a `st.railway_crossing`.
- **The standard "as far to the right … as possible".** It is bounded by a road edge on the subject's right (negative lateral offset), on the way the subject occupies, within `p.pullover_edge_gap`. That parameter was proposed earlier this iteration by NRS_484B_267_1b_o1 and is proposed again here with the same value.
- **Subject.** "The driver" claims `DEF-NRS-484A-320::vehicle`, through the driver definition "drives … a vehicle". The run's index maps "the driver" the same way.
- **What would reverse this.** A label that judges vehicles of the subsection 1 classes at crossings that have no device; see "For the operator" below.

## NRS_484B_560_3_o2 — do not form two lanes of traffic
- **Trigger and condition.** Same as o1.
- **Obligation.** No other member of the traffic aggregate stands or moves side by side with the subject, at the same crossing. "Side by side" means:
  - it occupies a lane;
  - it heads the same direction (`p.side_by_side_same_direction_cos`, newly proposed);
  - the two bodies' longitudinal overlap is positive.
- **Why the other road user must occupy a lane.** This leaves out a pedestrian on a sidewalk, who forms no lane of traffic.
- **Exception.** "Marked for four or more lanes" holds where four pairwise distinct lanes lie on the highway the subject occupies. The four is a literal.
- **Who formed the second line.** Both road users of the pair are held to have formed it; arrival order is not told apart.
- **What would reverse this.** A label that blames only the vehicle that pulled alongside. That would need an arrival-order reading.

## NRS_484B_560_7a — completely cross without stopping
- **Applicability.** A `since` over the traversal: the body has been within the literal 15 ft of the crossing at every observation since its footprint last overlapped the crossing.
- **Obligation.** `drv.motion.complete_halt` does not hold.
- **Where the definition's distance comes in.** Subsection (8)'s definition of "completely cross" is carried as an element on its own definitional span, with the 15 ft literal. Its reading (crossing outline as the nearest rail, body outline as the trailing end) is disclosed on the obligation span.
- **"Due to insufficient space / undercarriage clearance".** This is read as an `observable_reading` of category `purpose`, through the halt those causes explain.
- **What would reverse this.** A label that excuses a halt on the tracks for some other cause, such as a flagger's direction. The cause words would then need an observable carrier (a vehicle ahead, a crest), or a gap.

## NRS_484B_560_7b — obey devices and police at a railroad crossing
- **When it is judged.** At the subject's entry into a railroad crossing.
- **Obligation.** Every device governing a region the subject occupies at that entry is obeyed:
  - **railway lights and gate:** not flashing, gate not lowering, down or raising;
  - **traffic signal:** not circular red;
  - **police stop:** no entry;
  - **yield sign:** no rail vehicle in conflict within `p.conflict_horizon` and `p.conflict_centre_clearance`;
  - **stop sign:** a halt before the entry.
- **The stop-sign search (rule 4c).** It runs back to the approach start (the subject leaving `p.railroad_crossing_approach_reach`) or to the previous entry. A `history_boundary` scenario is planned.
- **Not read.** Instructions that do not bear on entering the crossing, and directions to proceed. This is disclosed on the obligation span.
- **What would reverse this.** A labelled violation that turns on another instruction, such as a do-not-enter sign at the crossing.

## NRS_484B_587_1 — enter or leave a controlled-access highway only at indicated entrances and exits
- **The notice condition.** Read from the presence of an entrance- or exit-coded `dev.regulatory_sign`.
- **Why these words map differently from NRS_484B_493.** The run's index maps the same words, for NRS_484B_493, to curb zones. Here they mean notice of controlled access, not of a parking restriction, so they are mapped to the sign alone (rule 7).
- **Entry.** The subject's footprint comes to overlap the controlled-access region while it occupies a travel region governed by an entrance-coded sign.
- **Departure.** At the observation before the departure, the subject occupied the highway and a travel region governed by an exit-coded sign. This is written as `rises(not X)`.
- **What would reverse this.** Sources that mark ramps without signs. "Indicated" would then need a lane-role atom.

## NRS_484B_587_2a — stay within marked lanes on a controlled-access highway
- **Obligation.** While moving on the controlled-access highway, the subject overlaps:
  - no median or divider;
  - no shoulder other than an authorized one;
  - and it overlaps some lane, unless every non-lane region it overlaps is an authorized shoulder.
- **"Required by an emergency".** Read through the conduct that shows it: hazard lamps, or an emergency vehicle with a lit warning lamp (`purpose` reading).
- **Why this departs from the index.** The index maps "in an emergency" to the emergency-vehicle class plus hazard lamps. Here the warning lamp is added, because the class alone "is not responding".
- **Subsection 3 and the 484B.210(4) list.**
  - The vehicles are mapped as the index maps them in NRS_484B_210_1: authorized emergency vehicle aggregate, official vehicle (incident-management and coroner kinds), tow-car aggregate, and bus aggregate together with `ru.transit_bus`.
  - The permission is a paved shoulder governed by a `shoulder_use_permitted` sign whose conditions hold.
  - The reference to the list is a `definition` composition; it composes no rule.
  - The list's introductory sentence about 484B.210(1)(c)(1) is a residue.
- **What would reverse this.** A source that maps gore areas, which would need a kind of their own.

## NRS_484B_587_2b — do not cross a solid white line between entrance/exit lanes and traffic lanes
- **Obligation.** `drv.lane.entering_adjacent_lane` from lane r1 into r2, across a solid or double-solid white marking on that side of r1, is forbidden where one of the two lanes is governed by an entrance- or exit-coded sign and the other is not.
- **How entrance and exit lanes are identified.** By the sign that indicates them (`status` reading).
- **Exceptions.** Carried exactly as in 2a, for consistent mapping of the shared words.
- **What would reverse this.** A lane-role attribute on `st.controlled_access`, which would replace the sign reading.

## NRS_484B_600_1c — the posted speed
- **Applicability and obligation.** For every speed limit sign governing a region the subject occupies, of kind maximum, structure maximum or zone, `kin.speed` is not above the sign's value. No parameter is needed.
- **Mapping.** "Drive or operate" and "a vehicle of any kind or character" reuse the index mappings. "Posted by a public authority" is a `status` reading.

## NRS_484B_600_1e — 80 mph
- **Obligation.** `kin.speed` is not above the literal 80 mph.
- **"In any event".** A residue of scope none: it adds no condition.

## For the operator
- **NRS-484B-560-3, "When stopping is required".** This is read only through devices that require a halt. NRS 484B.560(1) requires certain classes of vehicle to stop at every crossing, but its text is not in this line and no node for it is in the library. Such a vehicle at a crossing with no device is therefore not judged by these two nodes. A trigger narrowing is not accepted, so this is recorded here rather than in the record. If 484B.560(1) enters the corpus, the trigger should also compose it, `as: condition`.
- **The emergency exception in 2a/2b.** The open gap smoke31-1111-0039:G20 (`env.emergency`) concerns the same notion. Once that gap is decided, the hazard-lamp/warning-lamp reading of "required by an emergency" should be revisited.

<!-- batch-26 -->
# Plan — batch 26 (iteration 1)

There are 9 nodes across 8 laws. No concept records were proposed: the only concept used is `drv.motion.complete_halt`, which an earlier batch proposed. There are no law-local aggregates (`aggregates.jsonl` is empty). The validator accepts every node. `NRS_484B_627_1c` carries an atom gap.

## NRS_484B_603_1_o1 — decrease speed under listed conditions (surrogate)

**Decision.** The line has two obligation spans, so it gives two nodes:
- `o1` covers "does not relieve … from the duty to decrease speed when …".
- `o2` covers "and speed must be decreased as may be necessary …".

`o1` applies when any listed condition holds. The conditions read as follows:
- **Intersection.** The subject occupies an intersection, or a carrier that `st.lane_enters` one. This reuses the index mapping of "approaching an intersection".
- **Curve.** The roadway curvature is clear of `p.curvature_resolution` at the subject's place, or within a `.path` window ahead of `p.curve_approach_reach` (new parameter).
- **Hill crest.** A crest lies ahead of the subject's velocity within `p.crest_near_reach`. This reuses the mapping of the 213-2a crest.
- **Narrow or winding highway.** Lane width is at or below `p.narrow_lane_width` (new parameter), or curvature is clear of resolution.
- **Pedestrians or other traffic.** A pedestrian aggregate is on a roadway, or a traffic road user is in predicted conflict.
- **Weather.** Precipitation, a wet road, ice or snow, or visibility below the sight distance.
- **Other highway conditions.** This is the catch-all of the "special hazards" standard. It is read through obstructions within the stopping distance and through temporary traffic control, and a narrowing discloses that.

The duty to "decrease speed" is a standard with no stated amount, so I marked the node **surrogate**. The bound is the AASHTO stopping-sight model: the stopping distance must fit within the sight distance and the visibility at the subject's surface deceleration. On a bend there is also a lateral-acceleration bound, and toward a road user in conflict the stopping distance must fit within the surface gap. Each factor enters the bound by its degree.

The clause "speed lower than the prescribed limits" adds no restriction. It is carried as a residue of scope `none`.

**Reversal signal.** A label set that judges "decrease speed" as an observed deceleration on every approach, rather than as reaching an adequate speed, would reverse the reading on `s4`.

## NRS_484B_603_1_o2 — decrease speed as necessary to avoid colliding (surrogate)

**Decision.** For every other road user on or entering a highway that is in predicted conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`), the subject must do one of the following:
- be at rest;
- be decelerating by at least `p.speed_decrease_decel_min`;
- have a stopping distance within the surface gap. This is the due-care bound.

Contact while moving is a violation. "Any person, vehicle or other conveyance" covers every road user, so the rule quantifies over all of them, and the vehicle aggregate is claimed only for its word. I read "in compliance with legal requirements" as qualifying the speed decrease, carried through the due-care bound, and disclosed it as a narrowing on that standard span.

**Reversal signal.** The words could instead mean "a person lawfully entering". A corpus reading that restricts the parties that way would turn the clause into a lawfulness composition.

## NRS_484B_620_2 — speed in a speed zone

**Decision.** The rule applies to a motor vehicle in a travel region on a highway that is governed by a `dev.zone_sign` of kind speed_zone and a speed limit sign of kind zone or maximum. The speed must not exceed that sign's value. The establishment of the zone is read from the signs (an observable reading of category status).

"Upon the road" uses DEF-NRS-484A-215, under which a road lies outside the territorial limits of a city. That legal region class is carried by `asm.within_incorporated_city`, reused and declared false. I reused it rather than minting its complement.

**Reversal signal.** If the operator decides "road" here means any highway, the assumption should be dropped.

## NRS_484B_627_1a, _1b, _1c — slow vehicle impeding traffic

**Shared trigger.** "So slow as to impede" is a standard. It is operationalized as conduct sustained over `p.left_lane_move_over_time` (the time to move over). Over that window:
- the subject moves at least `p.impeding_speed_margin` (new parameter, about 10 mph) below the posted maximum governing its region;
- a traffic road user is behind it in the same lane within `p.rear_signal_reach`;
- no road user is ahead of it within that reach, so the subject is not itself queued.

Where no maximum sign governs the subject's region, the reference speed is unobserved and the result is unknown. A narrowing on `u3` discloses this.

- **1a.** The condition is one lane in the subject's direction plus an opposed-direction lane on the same highway that also has a count of one, using `p.lane_opposed_direction_cos`. "The width of the paved portion permits" is a standard: the paved half-width, from the centre line to the right edge, must be at least the vehicle's width plus `p.free_passage_width`. The obligation is that the right side of the body is within `p.pullover_edge_gap` of the right roadway edge. "Comply with NRS 484B.630" is a residue because NRS 484B.630 has no node in the library.
- **1b.** The condition is a lane count of at least two (a literal) in the subject's direction. The obligation is to occupy the lane whose ordinal equals the count. The exception covers passing a slower vehicle on the right that is either side by side with the subject or ahead and closing within `p.overtake_window`.
- **1c.** "Use alternate routes whenever possible" depends on whether another route exists, and no atom carries that. The node carries an **atom gap** (`st.alternate_route`), mapped to its nearest atoms `rel.occupies` and `st.controlled_access`. The law stays blocked until the gap is decided.

**Reversal signal.** The labels might call a vehicle impeding where no posted limit governs it. In that case the reference speed should come from the traffic behind instead.

## NRS_484B_627_2 — complete stop on a roadway impeding traffic

**Decision.** The subject is a vehicle on a roadway. It violates the rule when it is at rest (`drv.motion.complete_halt`) while a traffic road user behind it in its lane, within `p.rear_signal_reach`, is halted or decelerating. Two exceptions apply:
- **"Necessary for safe operation"** is a standard. It holds when the subject is queued behind a road user within `p.queue_halt_gap`, or a road user is in predicted conflict.
- **"In compliance with law"** holds when a control requiring a halt governs the subject's region: a stop sign, a yield sign, a red signal, a person directing traffic to stop, or a railway signal or gate.

For "in compliance with law" I extended the index mapping of NRS_484B_450_1a (stop sign and signal only) with the other halt-requiring controls that NRS_484B_477_1a's mapping reads. The words call for every legal requirement, and the validator does not allow a narrowing on an exception span.

The term "stop" is marked ambiguous between DEF-NRS-484A-255 and DEF-NRS-484A-260. I did not choose between them. Both denote the halt `drv.motion.complete_halt` reads, and DEF-260's own exceptions ("to avoid conflict with other traffic", "directions of a police officer or official traffic-control device") fall within this node's two exceptions.

**Reversal signal.** If gap G22 (an operator for "in compliance with law") is accepted, `x8` should be re-planned through it.

## NRS_484B_633_2 — speed over a signposted bridge or elevated structure

**Decision.** The subject is a vehicle on an `st.elevated_structure` lying on a highway. When a `dev.speed_limit_sign` of kind structure_maximum governs the travel region it occupies there, its speed must not exceed the sign's value. "Maximum speed … with safety to the bridge" is the authority's declared value, not a driver's judgement, so it is not a standard. The appended subsection (3) is carried as follows:
- The investigation, the finding and the declaration are residues: the rule reads the posted sign as their evidence (status reading on `y4`).
- "Suitable signs stating such maximum speed" maps to the sign and its value.
- The placement 100 feet before each end is a residue, because the rule reads the sign's governance, not its position.

**Reversal signal.** A label that excuses a vehicle because the sign is misplaced would require reading `dev.position` against the structure.

## NRS_484B_653_1a — reckless driving (surrogate)

**Decision.** "Willful or wanton disregard" is a state of mind, so the node is **surrogate**. It is read through conduct: a speed of at least `p.exhibition_speed_min`, or acceleration of at least `p.exhibition_accel_min` into a predicted conflict with another road user. "On a highway" reuses the index mapping. "Premises to which the public has access" is a legal region class that the ontology names explicitly. It is carried by a new assumption, `asm.public_access_premises`.

**Reversal signal.** Labels that call collisions or near-misses at ordinary speed reckless would add a conflict branch that does not depend on acceleration.

## For the operator

- **New parameters** (proposed, awaiting review): `p.narrow_lane_width` (3.0 m), `p.curve_approach_reach` (150 m), `p.impeding_speed_margin` (4.5 m/s). Every other parameter repeats an earlier batch's proposal with the same value and convention.
- **Atom gap `st.alternate_route`** (NRS-484B-627-1c): whether an alternate route exists between a road user's entry to and exit from a controlled-access highway. Without it the duty to "use alternate routes whenever possible" cannot be judged.
- **"In compliance with law"** (NRS_484B_627_2 `x8`) is carried by halt-requiring controls. A halt that another law requires and no control displays (for example, yielding to a school bus or to an emergency vehicle) is not covered. The pending operator gap G22 would carry it in full.
- **NRS 484B.630**, which NRS-484B-627-1a refers to, has no node in the library, so that reference is a residue. If it is added to the corpus, 627-1a should compose it (`as: compliance`).

<!-- batch-27 -->
# Plan — batch 27 (iteration 1)

Eight law lines, nine nodes. No law-local aggregates (`aggregates.jsonl` is empty): every defined term the duties turn on is an admitted aggregate or a `not_aggregate` place word. No new concepts. The nodes reuse `drv.motion.complete_halt`, `drv.motion.parked` and `drv.interaction.overtake_pass`, all proposed earlier in this iteration. Three nodes carry gaps and will not be coded: `NRS_484B_769`, `NRS_484B_913` and `NRS_484D_100_1`.

## NRS_484B_769 — hand signals of bicycle, electric bicycle and electric scooter operators (gap)

**What the line requires.** It requires every signal to be given "by hand and arm in the manner required by NRS 484B.420". The exception lets a right-turn signal be given with the right arm extended horizontally to the right.

**How the words are carried.**
- The reference span s4 (`by NRS 484B.420 [DEF-NRS-484B-420],`) is a `definition` reference. It borrows the manner text of DEF-NRS-484B-420.
- The obligation element s3 carries the borrowed words, with `source_spans` set to s4.
- "by hand and arm" is carried by `sig.hand_signal`. A signal given by the turn indicator alone (`sig.turn_indicator`) fails it.

**Gap.** "The manner" is which arm is used, the side it is extended beyond, and the direction it points. The exception turns on that same posture. `sig.hand_signal` carries only the *meaning* of a signal. Meaning "right" is the same for the left arm extended upward and the right arm extended horizontally, so neither the duty's manner nor its exception can be decided. I filed an `atom` gap (`sig.hand_signal_posture`) on s3 and on s5, and did not treat the manner as a residue: the manner is what this section regulates, and dropping it would weaken the duty.

**Reversal signal.** I would revise this if the operator rules that the decoded meaning is enough evidence of the statutory manner. In that case s3/s5 map to `sig.hand_signal` alone and the node is coded.

## NRS_484B_777_1_o1 — ride as near to the right side of the roadway as practicable

The line has two obligation spans: "ride as near to the right side…" (o1) and "exercising due care when passing…" (o2). Each node segments the whole line.

**The duty.**
- "as practicable" (s9) is operationalized as the gap between the rider's body and a mapped road edge on its right. The edge must lie on a highway that the occupied roadway lies on. The gap is computed as `prim.region_lateral_offset` minus half of `kin.extent` width, and must be at most `p.bicycle_keep_right_gap` (proposed; AASHTO shy distance).
- Where no right-side edge is mapped, the verdict is unknown, not violated.

**Exception (a): lawful speed, commensurate with nearby traffic.** Its referring span is s3 ("a lawful rate of speed").
- Lawfulness is a composition `as: compliance` with `NRS_484B_785_1a`, the scooter speed line planned in this batch. For a bicycle or electric bicycle that rule is not engaged, so it counts as complied with.
- "commensurate with the speed of" (s4) is a standard. Every traffic-aggregate road user within `p.nearby_traffic_reach` may be faster than the subject by at most `p.commensurate_speed_margin`.
- "any nearby traffic" (s4b) is read in every direction, and holds vacuously when no traffic is nearby. So a lone rider is excused, which matches the exception's purpose of not holding traffic back.
- Reversal signal: a label that judges a lone mid-lane rider as violating.

**Exception (b): preparing to turn left.** This is the declared intention `int.left_turn`. The words name no place, so the intention is read at every kind of region where a left turn off a roadway is made: intersections and driveway/alley entrances.

**Exception (c): not safe.** The standard s7, the subsection-2 preamble s12 and the narrow-lane standard s14 are bounded by two conditions:
- **Something impedes the right side (s13):** an obstruction ahead on the rider's right within `p.right_side_impede_reach` (measured along the roadway's direction), or a vehicle, bicycle or pedestrian (admitted aggregates) ahead on its right within that reach. Animals and surface hazards are `st.obstruction`.
- **Lane too narrow (s14):** the occupied lane is narrower than `p.shared_lane_min_width` (14 ft wide-outside-lane guidance).

The catch-all "include, without limitation" is disclosed as read only through these contracts. That reading excludes electric bicycles and electric scooters, which the vehicle and bicycle definitions leave out.

**Span cut.** "shall, except:" is kept inside the condition span s2 ("upon a roadway shall, except:"), following the index precedent ("the driver or operator shall:"), so that no words that require anything are labelled boilerplate.

## NRS_484B_777_1_o2 — due care when passing a standing vehicle or one proceeding the same way (surrogate)

**The duty.** "exercising due care" is the whole obligation and a state-of-mind standard, so this node is a **surrogate**. It is bounded by the clearance kept while side by side during a pass recognized by `drv.interaction.overtake_pass`:
- There must be no contact.
- The lateral body gap must be at least `p.door_swing_reach` when the passed vehicle is at rest, and at least `p.bicycle_pass_safe_gap` when it is moving. The bound is selected at each side-by-side observation.

**Standing.** "standing" (DEF-NRS-484A-250, not an aggregate) is read as the vehicle at rest (`drv.motion.complete_halt`). The definition's exclusion of a halt to receive or discharge passengers turns on purpose, so it is disclosed as an `observable_reading` of category `purpose`.

**Exceptions do not apply.** I read the exceptions (a)–(c) as qualifying only the keep-right duty, so they are `sibling` spans here. Exception (c) speaks of "doing so", subsection 2 defines it entirely in keep-right terms, and a left-turn preparation cannot excuse care in passing. Reversal signal: a label that exempts a careless pass because the rider was preparing a left turn.

**When "upon a roadway" is read.** The validator rejected an `occasion` record because the obligation span maps to no act concept. The pass is therefore the trigger, recognized where the concept rises. "upon a roadway" is read at some observation since the pass began, as branch_3/branch_4 show.

**Known limit.** `overtake_pass` recognizes a pass only when the two headings were aligned as it began. A standing vehicle parked facing the other way is therefore not read as passed (see the operator section).

## NRS_484B_777_3 — not more than two abreast

The obligation forbids the moving subject from being in a row with two other moving riders of the bicycle, electric bicycle or electric scooter aggregates:
- every pair overlaps longitudinally;
- headings are aligned (`p.side_by_side_same_direction_cos`);
- at least two of the three pairs are within `p.abreast_gap_max` (proposed: group-riding spacing), so that riders lanes apart are not counted as abreast.

The exception (s4) is the subject's footprint on `st.bicycle_lane_or_path`. The three device words in s4 name whom the facility is reserved for, which is the kind's own contract, so they claim no aggregate. The permit scenario has the rider alone, which shows the duty binds the subject alone. Reversal signal: a label that counts a third rider in an adjacent lane at 2 m as abreast.

## NRS_484B_785_1a — electric scooter at most 15 mph on roadway, bicycle lane, path or route

**The duty.** The permission "may be operated … at a speed of not more than 15 miles per hour" is read as its limit, using the literal 15 mph against `kin.speed`.

**Places.** Roadway is `st.roadway`. Bicycle lane and path are `st.bicycle_lane_or_path`. A "route" runs on those, so it adds no place.

**"Except as otherwise provided" (s1).** The bracketed ordinance (DEF-LVMC-11-40-185-A) says where scooters may be operated and states no speed, so nothing in it provides otherwise on this bound. s1 is therefore a residue of scope `none`. Reversal signal: a posted ordinance text that sets a different scooter speed.

**"may be operated:" (s3).** This is also scope `none`, because a scooter at rest meets the bound anyway.

**Admitted bicycle aggregate.** The table lists `bicycle` for this law, but the word appears only inside "bicycle lane", the name of a structure kind, so no `ru.aggregate` for bicycle is claimed.

## NRS_484B_913 — driving over a fire hose (two gaps)

**How the words are carried.**
- Driving over the hose is the moving vehicle's footprint overlapping (`rel.occupies`) an `st.obstruction` of kind hose.
- "of a fire department" and "for use at any fire…" are `observable_reading`s, of categories `status` and `purpose`, carried by the hose laid on the way.
- "on any highway or private way or place" names every place, so it is a residue of scope `none`.

**Gaps.**
- "unprotected" distinguishes a bare hose from one under a hose bridge or ramp. No atom carries that, so I filed an `atom` gap (`st.protected_hose`).
- "the consent of the fire department official in command" has no carrier. `dev.human_direction`'s roles do not include a fire official, so I filed an `atom` gap (`dev.fire_official_direction`).

**Reversal signal.** I would revise this if the operator adds a protection attribute to `st.obstruction`, or a fire-official role to `dev.human_direction`.

## NRS_484D_100_1 — when lighted lamps are required (gap G21)

**How the words are carried.**
- Highway is `st.highway` with `rel.occupies`. "of this State" is a residue of scope `none`, because the corpus is applied in its own jurisdiction.
- The display duty is headlamps lit plus position lamps lit, reusing the index mapping of "lights … shall be burning".
- "as respectively required in this chapter for different classes" is a residue. The per-class equipment sections are not corpus lines, and no atom carries a lamp's specification.
- (a) is `env.darkness`; the sunset boundary is the reading parameter, and the law's figure is a literal.
- (b) is `env.darkness` or `env.visibility` below the literal 1,000 ft, as the index maps these words.

**Parked-vehicle exceptions (s4).** The reference to "exceptions with respect to parked vehicles as stated in chapters 484A to 484E" is composed `as: exception` with `NRS_484D_165_3`. That is the corpus line stating when a parked or stopped vehicle displays lamps, and this subsection yields to it. Reversal signal: a further corpus line on parked-vehicle lamps (e.g. 484D.165(2)), which would be added as a second exception composition.

**Gap (c).** "When directed by an official traffic control device" has no device atom. The open gap smoke31-1111-0039:G21 (`dev.lamps_on_sign`) is carried again on these words, so the law stays blocked until it is decided.

## NRS_484D_165_3 — lamps on a parked or stopped vehicle

**Trigger and place.** The trigger is the vehicle at rest (`drv.motion.complete_halt`, as indexed for "stopped or parked"). It must be on the roadway (the "traveled portion") or on a shoulder of the same highway.

**"the times mentioned in NRS 484D.100" (t4/t5).** The referring span t4 carries the borrowed periods (a) and (b) as `env.darkness` or `env.visibility` below 1,000 ft. t5 is a `definition` reference to NRS-484D-100-1.
- It is not a rule composition. 100-1 itself excepts parked vehicles by composing this node, so a composition would form a cycle, and it would read that line's exception, not its times.
- 100-1's third circumstance (a device directing lamps on) is not borrowed. The conjoined condition t6 (insufficient light to reveal within 1,000 ft) entails period (b), so the times hold wherever t6 holds. The G21 gap therefore does not reach this node.

**The lamps.** The obligation is `sig.position_lamp` lit, the parking and tail lamps. Their description is borrowed by the reference t8 from the appended subsection 1. The lamps' colour, 500-ft reach and location (t9, t10) are residues, because no atom carries lamp fitment.

**Reversal signal.** A labelled parked vehicle at night under street lighting whose label is `not_applicable`. That would show that `env.darkness` (natural light only) applies this duty more widely than "insufficient light" does.

## NRS_484D_165_4 — headlamps on a parked vehicle depressed or dimmed

The trigger is a parked vehicle (`drv.motion.parked` with `p.parking_min_duration`, as indexed for "parked") with headlamps lit. The obligation is `sig.headlamp` = `low_beam`, reusing the index mapping of "such lights shall be depressed or dimmed" from NRS_484B_473_2. A short halt in traffic is not parked (branch_1). Reversal signal: a label that treats a twenty-second halt with high beams as violating, which would call for `drv.motion.complete_halt` instead.

## For the operator

- **Gaps filed:**
  - `sig.hand_signal_posture`, on NRS_484B_769 s3 and s5.
  - `st.protected_hose` and `dev.fire_official_direction`, on NRS_484B_913.
  - `dev.lamps_on_sign`, on NRS_484D_100_1 s10. This re-carries the pending gap smoke31-1111-0039:G21.
- **Pass of an opposite-facing standing vehicle.** `drv.interaction.overtake_pass` requires aligned headings at the start of the pass, so NRS_484B_777_1_o2 does not recognize a pass of a standing vehicle parked facing the other way. A concept for passing a standing object whatever its heading would close this. I did not propose one here because the validator rejects narrowing a trigger.
- **Natural darkness only.** `env.darkness` is insufficient *natural* light. NRS_484D_165_3 and NRS_484D_100_1 speak of insufficient light, which street lighting can supply, so both apply wherever it is naturally dark. An atom for illumination at a place would decide this.
- **New parameters proposed:** `p.bicycle_keep_right_gap`, `p.nearby_traffic_reach`, `p.commensurate_speed_margin`, `p.right_side_impede_reach`, `p.shared_lane_min_width` and `p.abreast_gap_max`.
  - In particular, `p.shared_lane_min_width` (14 ft) makes most urban lanes "too narrow", which excuses keep-right in them. This follows the shared-lane guidance, but it largely decides the reach of NRS_484B_777_1_o1.

<!-- batch-28 -->
# Plan — batch 28

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts were proposed.

## NRS_484D_215_1_o1 — use a beam that reveals at a safe distance (blocked: gap)

**Decision.** This line has two obligation spans: the beam that reveals at a safe distance (o1) and dimming for oncoming traffic (o2). The trigger reads a motor vehicle (DEF-NRS-484A-130 aggregate) on a roadway or shoulder lying on a highway, reusing the NRS_484D_165_3 mapping. The words "the times specified in NRS 484D.100" are a `definition` reference to NRS-484D-100-1. They borrow the three time qualifiers (a)–(c) whole, but none of that law's duty to show lamps. (a) and (b) map to `env.darkness`, plus `env.visibility` below the borrowed 1,000 feet. No atom carries (c), "when directed by an official traffic control device": `dev.regulatory_sign` has no lamps-on code. The span is mapped to its nearest atoms and carries an atom gap, `dev.lamps_on_sign`, which matches the pending smoke31-1111-0039:G21 on NRS-484D-100-1. The law therefore stays blocked.

**Obligation.** Using a beam means a headlamp state of `low_beam` or `high_beam`. The standard "directed high enough and of sufficient intensity to reveal … at a safe distance" uses a stopping-sight-distance model:
- the high beam always meets it;
- the low beam meets it only where `p.low_beam_sight_reach` is at least the stopping distance at the subject's speed, using `p.driver_reaction_time` and `p.following_decel_dry`.

**Limitation.** The oncoming limitation (s8) is the clause the first duty is "subject to". Here it is an exception that relaxes only the reach requirement: the low beam suffices while an oncoming vehicle is within 500 ft (surface gap). The lamps must still be lit.

**Narrowings.** The model assumes a dry surface. A following-vehicle limitation, which this line does not state, is not read.

**Reversal signals.**
- A label that judges low-beam night driving at urban speed compliant with no oncoming traffic: then reduce the obligation to "a beam lit".
- The operator retiring G21 or adding a lamps-on code: then the gap is resolved.

## NRS_484D_215_1_o2 — dim for an oncoming vehicle within 500 ft (blocked: same gap)

**Decision.** This node shares o1's trigger and times, so it carries the same gap. It applies when another vehicle is oncoming (`rel.oncoming`, `p.oncoming_heading_cos`) within 500 ft by `rel.surface_gap`. The surface gap is used rather than the centre distance, because the centre distance "overstates a clearance".

**Obligation.** The headlamp is not `high_beam`. The lowermost beam is a `definition` reference to DEF-NRS-484D-210-1-2, deemed to avoid glare "at all times, regardless of road contour and loading", so `low_beam` complies. An unlit lamp is left to o1. Reading glare through the beam selected is a disclosed narrowing.

**Reversal signal.** A label that judges a high beam aimed away from the oncoming driver (for example, on a divided road) as compliant.

## NRS_484D_400_5 — siren only when responding or in pursuit

**Decision.**
- **Subject:** the admitted aggregate DEF-NRS-484A-020::authorized_emergency_vehicle.
- **Obligation:** `sig.siren` is not sounding.
- **Exceptions (s4, s5):** "operated in response to an emergency call" and "immediate pursuit" are purposes. `ru.emergency_vehicle` says responding is conduct and not a class, so both exceptions are read through the vehicle's warning lamps flashing or rotating. This is an `observable_reading` of category `purpose`, and the lamp is never read as the sound.
- **Residues:** the equipment permission (s2), the restated permission "to warn pedestrians and other drivers" (s6, scope none) and the lamps-without-siren permission (s7) impose no duty.

**Reversal signal.** A label that excuses a siren used without lamps on a response. Such a response is not recognised here.

## NRS_486_341 — do not deprive a motorcycle or moped of its lane

**Decision.** The subject is a motor vehicle (DEF-NRS-484A-130). The motorcycle or moped (DEF-NRS-486-041 / DEF-NRS-486-038 aggregates) is quantified inside the obligation: it must be on the highway and occupying a lane. "Deprive … of such use" is read as sharing that lane side by side: the subject occupies the same lane and `rel.longitudinal_overlap` ≥ 0. This is a disclosed reading, and no parameter is needed. A scene with no motorcycle present is decided as compliant. "traffic lane" is read as `st.lane`, and the traffic aggregate is not claimed (the word names a lane, not road users); the earlier index mapping of "marked traffic lane" did the same.

**Reversal signals.**
- A label flagging deprivation from the adjacent lane without the subject entering the motorcycle's lane.
- A label excusing two motorcycles riding abreast with consent. NRS 486.351(3) allows this, and this line has no exception for it.

## NRS_486_351_1 — no lane splitting

**Decision.** The subject is a motorcycle or moped.

**Obligation.** There are no two vehicles v1 and v2 such that:
- v1 is to the subject's left and v2 to its right (`rel.bearing`);
- each is side by side with the subject;
- they occupy distinct lanes that are adjacent, either by `st.lane_adjacency` (same direction) or because the subject's footprint overlaps both lanes. Overlapping both shows the lanes touch whatever their directions.

The one case not read is a subject wholly within one lane between that lane's vehicle and a vehicle in an opposing lane (disclosed narrowing).

**Exception (s2).** The first draft read the police officer through the vehicle class alone, and the validator returned it: a class is no evidence of conduct. The exception is now read through conduct: a police vehicle displaying flashing or rotating warning lamps. This matches the index mapping of "(d) In the performance of official duties;" (`ru.emergency_vehicle` plus `sig.warning_lamp`).

**Reversal signal.** A label that excuses a police officer lane-splitting without lamps.

## NRS_486_351_2 — no riding abreast, overtaking or passing within one lane

**Decision.** The subject is a motorcycle, moped or trimobile.

**Obligation.** For every other vehicle in the subject's lane that is side by side with it, the pair must be excused, otherwise the duty is violated. The pair is excused (the subsection 3 sentence) when:
- both are motorcycles or mopeds;
- they travel in the same direction (`rel.same_direction`, `p.side_by_side_same_direction_cos`). This is how the drivers' consent is read, an `observable_reading` of category `intention`;
- no third vehicle is abreast in the lane ("two" is a literal).

"Except as provided in subsection 3" is a pointer to words this node carries, so it is a residue with scope none.

**Reading of "overtake or pass."** The index maps "overtake and pass" to `drv.interaction.overtake_pass`. Here the words forbid the *place* of the pass, within the same lane. A pass within one lane always brings the two side by side in that lane, so the duty is judged at those observations. The act concept is recognised only once the other vehicle is behind, when the subject may already have left the lane, so it is not used.

**Reversal signal.** A label that flags an unconsented same-direction pair, which this reading cannot tell from a consented one.

## For the operator

- **G21 blocks NRS-484D-215-1.** Both nodes carry the same atom gap as smoke31-1111-0039:G21 (`dev.lamps_on_sign`). Retiring G21, or adding a lamps-on code to `dev.regulatory_sign`, would unblock this law and NRS-484D-100-1 together.
- **Low beam at speed is a judgement call.** Under the stopping-distance reading of "safe distance", the low beam fails above about 17 m/s in darkness when no vehicle is oncoming. If the label contract treats any lit beam as compliant, `p.low_beam_sight_reach` (or the reading) needs review before labels drive repair.

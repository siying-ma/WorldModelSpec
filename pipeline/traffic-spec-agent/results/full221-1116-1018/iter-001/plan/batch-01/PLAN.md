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

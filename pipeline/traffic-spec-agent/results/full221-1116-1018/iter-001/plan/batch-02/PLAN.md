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

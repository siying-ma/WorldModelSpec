/-
  NRS_484B_127_2 — NRS-484B-127-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of any truck or combination of vehicles 80 inches or more in overall width,
    s2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width,
    s3 (standard): shall, whenever conditions permit,
    s4 (obligation): leave a space of 500 feet
    s5 (condition): so that an overtaking vehicle may enter and occupy such space without danger,
    s6 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.
    s7 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent'], derived ['drv.interaction.following']
    s4: atoms ['rel.surface_gap', 'rel.ahead_behind_in_lane'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.overtaking']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'st.highway', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.on_way', 'rel.occupies'], derived ['drv.motion.standstill']

  Literals the text states (each written through its Units constructor):
    s1: 80 in — 80 inches
    s2: 80 in — 80 inches
    s4: 500 ft — 500 feet
    s7: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s1 (the subject, `v`) and s2 (the trigger): both spans name the same two defined terms with the
  same figure, so one formula, `truckOrWideCombination`, writes them for the road user it is given:
  the admitted aggregate DEF-NRS-484A-305::truck (`ru_aggregate` with the aggregate id), or the
  admitted aggregate DEF-NRS-484A-050::combination_of_vehicles with the width the words measure —
  `kin_extent` read by its `width` selector, which the atom's contract gives as the full width, at
  or above the literal 80 inches. The figure attaches to "combination of vehicles" as the record's
  applicability states, and not to the truck limb. `clsV` is that formula on the binder; the
  trigger is the same formula on a road user `u` quantified inside the applicability, `u` held
  apart from the subject (`.not (.same u v)`) and following it by the catalogue's concept
  `drv.interaction.following`, parametrized with `p.same_direction_cosine_tolerance`, the cosine the
  concept leaves to its caller. The followed road user is no binder, as the record directs: the
  duty exists for the subject whether or not a scene supplies one, so the applicability
  existentially quantifies it and the obligation quantifies it again.

  s3 (the standard) is the node's operationalization, written leaf for leaf from its convention and
  from no other words:
    - the subject's `kin_speed` at or above `p.conditions_permit_min_speed`;
    - the count of road users that occupy a roadway the subject occupies (`st.roadway` through a
      region quantifier, `rel_occupies` of both), are ahead of it in its lane
      (`rel_ahead_behind_in_lane`) and lie at a smaller longitudinal `rel_surface_gap` than the
      road user the space is owed to, at most `p.conditions_permit_max_intervening_users`. The
      count is `Term.aggregate .count` over the scene's road users; the subject and the followed
      road user are excluded by `same`, the convention's "between the subject and the road user it
      follows";
    - no `st.obstruction` on the highway the lane the subject occupies lies on (`st.lane` and
      `rel_occupies` for the lane, `st_on_way` to the highway and from the obstruction to the same
      highway) nearer to the subject's body than that longitudinal gap, the distance read through
      `st.region_geometry`'s body-to-region distance;
    - no `dev.temporary_traffic_control` (a device quantifier over that kind) governing
      (`dev_governs`) a lane or a roadway the subject occupies.
  The four leaves are conjoined: the conditions permit where all of them hold. The standard stands
  in the obligation as the duty's precondition, which is the record's own wording ("at each
  observation at which the applicability holds and the conditions of s3 permit"), so a scene in
  which the conditions do not permit is compliant and not unengaged.

  s4 (the duty): the longitudinal component of `rel_surface_gap` from the subject to the road user
  it follows, at or above the literal 500 feet, owed at every road user the s2 selection picks out
  — the obligation is a universal over road users whose antecedent is that whole selection written
  again, since the applicability's quantifier does not reach into it, with `rel_ahead_behind_in_lane`
  fixing that the space measured is the one ahead of the subject towards that road user.

  s5 is the node's residue: no leaf of this rule reads those words.

  s6 (the first exception): `.not` of the span's content in the applicability — the subject is of
  the truck or the combination aggregate (the span's own words; the binder carries the same two
  aggregates) and some other road user of the vehicle or the combination aggregate is being passed,
  `drv.interaction.overtaking` with `p.same_direction_cosine_tolerance` and
  `p.overtaking_min_speed_excess`. The overtaken road user is quantified and held apart from the
  subject; the span puts no width on either limb and none is written.

  s7 (the second exception): `.not` of its content — the subject is of the vehicle or the
  combination aggregate, it is moving (`.not` of `drv.motion.standstill` with
  `p.standstill_speed_tolerance`, the posted definition of complete cessation read as a motion
  state), it occupies a highway (`st.highway` quantified, `rel_occupies`) through a lane
  (`st.lane` quantified, `rel_occupies`) that lies on that highway (`st_on_way`), and the count of
  lanes in that lane's direction of travel (`st.lane_adjacency` read by its `count` selector) is at
  or above the literal two. `st.lane_direction` is read on that same lane, as the squared length of
  the direction the atom returns above zero: the lane the subject occupies carries a designated
  direction of travel, which is what makes the count the atom gives a count of lanes available for
  traffic moving in the direction the subject travels in, and which the atom reports as unknown
  where the lane carries none. That is the atom carrying its own words on the span the record maps
  it to; the exception is written as the node maps it and is narrowed nowhere.

  The regions of s7 are bound inside the applicability and the regions of s3 inside the obligation:
  each formula binds its own, with the whole of the record's selection (the occupancy that anchors
  them to the subject, and the way relation between them) written again where it is read.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The road users and the regions the formulas quantify over. -/
def uV : Arg := .var "u"
def wV : Arg := .var "w"
def hV : Arg := .var "h"
def lV : Arg := .var "l"
def rwV : Arg := .var "rw"
def olV : Arg := .var "ol"
def owV : Arg := .var "ow"
def obV : Arg := .var "ob"
def dV : Arg := .var "d"
def dlV : Arg := .var "dl"
def drV : Arg := .var "dr"

/-- The admitted aggregates the node claims, each by its id. -/
def aggTruck : Arg := .lit "DEF-NRS-484A-305::truck"
def aggCombination : Arg := .lit "DEF-NRS-484A-050::combination_of_vehicles"
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConditionsPermitMaxInterveningUsers : Term := .param "p.conditions_permit_max_intervening_users"
def pConditionsPermitMinSpeed : Term := .param "p.conditions_permit_min_speed"
def pOvertakingMinSpeedExcess : Term := .param "p.overtaking_min_speed_excess"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio
def zeroCount : Term := .lit Q.zero .count

/-- The text's own figures, each through the `Units` constructor of its unit. -/
def eightyInches : Term := .lit (Units.inches 80) .metre
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre
def twoLanes : Term := .lit (Q.ofInt 2) .count

/-- s1, s2: the full width of a road user's body, as `kin.extent` gives it. -/
def overallWidth (x : Arg) : Term := .measure "kin_extent" [x, .lit "width"]

/-- s1, s2: a truck of DEF-NRS-484A-305::truck, or a road user of
    DEF-NRS-484A-050::combination_of_vehicles 80 inches or more in overall width. -/
def truckOrWideCombination (x : Arg) : Formula :=
  .or (.atom "ru_aggregate" [x, aggTruck] [])
      (.and (.atom "ru_aggregate" [x, aggCombination] [])
            (.cmp (overallWidth x) .ge eightyInches))

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-305::truck, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, kin.extent -/
def clsV : Formula := truckOrWideCombination vV

/-- s4: the longitudinal component of the clearance between the subject's body and `x`'s. -/
def spaceTo (x : Arg) : Term := .measure "rel_surface_gap" [vV, x, .lit "longitudinal"]

/-- s2: the road user the subject is following — another road user of the two defined terms, with
    the concept of the catalogue for the following itself. -/
def followedRoadUser (x : Arg) : Formula :=
  .and (.not (.same x vV))
    (.and (truckOrWideCombination x)
          (.derived "drv_interaction_following" [vV, x] [pSameDirectionCosineTolerance]))

/-- s7: the designated direction of travel of a lane, by component. -/
def laneDirX (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "x"]
def laneDirY (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "y"]

/-- s7: the lane carries a designated direction of travel, so that the count of lanes the next
    leaf reads is a count in the direction the subject travels in. -/
def laneHasDirection (r : Arg) : Formula :=
  .cmp (.add (.mul (laneDirX r) (laneDirX r)) (.mul (laneDirY r) (laneDirY r))) .gt zeroRatio

/-- s7: the count of lanes in that lane's direction of travel. -/
def lanesInDirection (r : Arg) : Term := .measure "st_lane_adjacency" [r, .lit "count"]

/-- s7 (exception): the subject, a vehicle or a combination, is moving on a highway on which there
    are two or more lanes available for traffic moving in the same direction. -/
def multiLaneHighwayException : Formula :=
  .and (.or (.atom "ru_aggregate" [vV, aggVehicle] [])
            (.atom "ru_aggregate" [vV, aggCombination] []))
    (.and (.not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance]))
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "rel_occupies" [vV, hV] [])
          (.existsRegion (.lit "lane") "l"
            (.and (.atom "rel_occupies" [vV, lV] [])
              (.and (.atom "st_on_way" [lV, hV] [])
                (.and (laneHasDirection lV)
                      (.cmp (lanesInDirection lV) .ge twoLanes))))))))

/-- s6 (exception): the subject, a truck or a combination, is overtaking and passing another
    vehicle or combination of vehicles. -/
def overtakingException : Formula :=
  .and (.or (.atom "ru_aggregate" [vV, aggTruck] [])
            (.atom "ru_aggregate" [vV, aggCombination] []))
    (.existsUser "w"
      (.and (.not (.same wV vV))
        (.and (.or (.atom "ru_aggregate" [wV, aggVehicle] [])
                   (.atom "ru_aggregate" [wV, aggCombination] []))
              (.derived "drv_interaction_overtaking" [vV, wV]
                 [pSameDirectionCosineTolerance, pOvertakingMinSpeedExcess]))))

/-- s3: the road users that occupy a roadway the subject occupies, ahead of it in its lane and
    nearer to it than the road user the space is owed to. -/
def interveningRoadUsers (x : Arg) : Term :=
  .aggregate .count "w"
    (.and (.not (.same wV vV))
      (.and (.not (.same wV x))
        (.and (.existsRegion (.lit "roadway") "rw"
                (.and (.atom "rel_occupies" [vV, rwV] [])
                      (.atom "rel_occupies" [wV, rwV] [])))
          (.and (.atom "rel_ahead_behind_in_lane" [wV, vV] [])
                (.cmp (spaceTo wV) .lt (spaceTo x))))))
    zeroCount

/-- s3: an obstruction on the highway the lane the subject occupies lies on, nearer to the
    subject's body than the space owed. -/
def obstructionWithinTheSpace (x : Arg) : Formula :=
  .existsRegion (.lit "lane") "ol"
    (.and (.atom "rel_occupies" [vV, olV] [])
      (.existsRegion (.lit "highway") "ow"
        (.and (.atom "st_on_way" [olV, owV] [])
          (.existsRegion (.lit "obstruction") "ob"
            (.and (.atom "st_on_way" [obV, owV] [])
                  (.cmp (.measure "st_region_geometry_distance" [vV, obV]) .lt (spaceTo x)))))))

/-- s3: a temporary traffic control device governing a lane or a roadway the subject occupies. -/
def worksZoneGovernsTheSubject : Formula :=
  .existsDevice (.lit "temporary_traffic_control") "d"
    (.or (.existsRegion (.lit "lane") "dl"
            (.and (.atom "rel_occupies" [vV, dlV] []) (.atom "dev_governs" [dV, dlV] [])))
         (.existsRegion (.lit "roadway") "dr"
            (.and (.atom "rel_occupies" [vV, drV] []) (.atom "dev_governs" [dV, drV] []))))

/-- s3 (standard): whenever conditions permit — the operationalization's four leaves. -/
def conditionsPermit (x : Arg) : Formula :=
  .and (.cmp (.measure "kin_speed" [vV]) .ge pConditionsPermitMinSpeed)
    (.and (.cmp (interveningRoadUsers x) .le pConditionsPermitMaxInterveningUsers)
      (.and (.not (obstructionWithinTheSpace x))
            (.not worksZoneGovernsTheSubject)))

/-- Applicability: s2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width,; s5 (condition): so that an overtaking vehicle may enter and occupy such space without danger,; s6 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.; s7 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction. -/
def applicability : Formula :=
  .and (.existsUser "u" (followedRoadUser uV))
    (.and (.not multiLaneHighwayException) (.not overtakingException))

/-- s4: the space of 500 feet, owed ahead of the subject towards the road user it follows. -/
def spaceOwed (x : Arg) : Formula := .cmp (spaceTo x) .ge fiveHundredFeet

/-- Obligation: s3 (standard): shall, whenever conditions permit,; s4 (obligation): leave a space of 500 feet -/
def obligation : Formula :=
  .forallUser "u"
    (.implies (.and (followedRoadUser uV) (.atom "rel_ahead_behind_in_lane" [uV, vV] []))
      (.implies (conditionsPermit uV) (spaceOwed uV)))

def rule : Rule :=
  { id := "NRS_484B_127_2"
    laws := ["NRS-484B-127-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "whenever conditions permit"
          concepts := ["dev.governs", "dev.temporary_traffic_control", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.highway", "st.lane", "st.obstruction", "st.on_way", "st.region_geometry", "st.roadway"]
          params := ["p.conditions_permit_min_speed", "p.conditions_permit_max_intervening_users"]
          convention := "Traffic-flow feasibility convention (free-flow versus congested operation in highway capacity practice): leaving and holding a long space ahead is possible only where the stream runs freely and nothing occupies or closes the space. The conditions permit at an observation where the subject's kin.speed, “magnitude of velocity”, is at least p.conditions_permit_min_speed, so that a queue or stop-and-go running is not read as a failure to leave the space; where the number of road users that occupy a roadway the subject occupies (rel.occupies with st.roadway) between the subject and the road user it follows — ahead of it in its lane (rel.ahead_behind_in_lane) and at a smaller longitudinal rel.surface_gap than that road user — is at most p.conditions_permit_max_intervening_users, so that a vehicle that has moved into the space is not read as the subject's closing of it; where no st.obstruction, “a physical object on or beside the roadway that is not a road user”, lies on the highway the lane the subject occupies lies on (st.lane, rel.occupies, st.on_way, st.highway) nearer to the subject's body than that longitudinal gap, the distance read through st.region_geometry, which carries “the ground distance from a road user's body outline to it”; and where no dev.temporary_traffic_control, “cones, barricades, temporary signs and flashers marking works, a closure or an obstruction”, governs a lane or roadway the subject occupies — dev.governs, “the travel regions whose traffic the device controls”, which is the atom that ties a device to the subject, a device quantifier being otherwise unanchored — since a works zone or a closure of the subject's own lane makes the space impossible to hold. Both magnitudes are parameters of the reading; the words state none."
          surrogate := false } ]
    residues := ["The purpose clause explains the figure the law itself fixes: the space is 500 feet, and the words “so that an overtaking vehicle may enter and occupy such space without danger” state what that space is for, adding no further requirement to the duty, which is met by leaving the stated space and breached by not leaving it. The ontology reads a purpose through the conduct it explains, and here that conduct is the leaving of the space the next words measure. The rule is held to this: no verdict of the node turns on these words."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_2

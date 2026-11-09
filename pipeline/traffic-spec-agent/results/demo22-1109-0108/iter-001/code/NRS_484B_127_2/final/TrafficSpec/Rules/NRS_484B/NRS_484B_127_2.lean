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
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'st.highway', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.on_way', 'rel.occupies'], derived ['drv.motion.standstill']

  Literals the text states (each written through its Units constructor):
    s1: 80 in — 80 inches
    s2: 80 in — 80 inches
    s4: 500 ft — 500 feet
    s7: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s1 (the binder's class, `clsV`). `truckOrWideCombination v`: the admitted aggregate
  DEF-NRS-484A-305::truck, or the admitted aggregate DEF-NRS-484A-050::combination_of_vehicles
  with the read width (`kin_extent`, component `width`, which the vocabulary reads as the full
  width) at least the text's 80 inches. The qualifier "80 inches or more in overall width" is
  attached to the combination limb, as the record's `applicability` states it. "The driver of" is
  the record's own observable reading (agency) and is not restated in `narrowings`.

  s2 (`followsWideTruck`, in the applicability). Some road user other than the subject
  (`.not (.same v u)`) is itself a truck of that aggregate or a combination of that width, and the
  subject is following it (`drv.interaction.following`, the same-direction tolerance of the
  reading). The followed road user is quantified, not bound: the duty exists for the subject
  whether or not a scene supplies one.

  s3 (`conditionsPermit`, the operationalization, in the obligation). The subject's `kin_speed`
  at least `p.conditions_permit_min_speed`; the count of other road users that occupy a roadway
  the subject occupies (`st.roadway` with `rel.occupies`), lie ahead of the subject in its lane
  (`rel.ahead_behind_in_lane`) and lie nearer than the followed road user (the longitudinal
  component of `rel.surface_gap`), at most `p.conditions_permit_max_intervening_users`; and no
  `st.obstruction` on the way (see the narrowing below). The convention's fourth leaf, that no
  `dev.temporary_traffic_control` lies in the space, is not written at all: the node claims no atom
  that relates a device to the subject or to a region (`dev.governs` and `dev.position` are atoms
  of the surface, and this node claims neither), so a device quantifier would range over every
  device of the scene, the subject's or not. That is a defect of the node's mapping, not a reading
  open to me, and it is reported rather than declared here.

  s4 (the obligation). For every road user the subject is following in the sense of s2 and that is
  ahead of it in its lane (`rel.ahead_behind_in_lane`, the s4 claim that fixes which space is
  meant), where the conditions of s3 permit, the longitudinal component of `rel.surface_gap`
  between the two bodies is at least the text's 500 feet. The obligation re-selects the followed
  road user with the whole of s2's selection, since the applicability's binding does not reach it.
  The record's reading of "a space of 500 feet" as that longitudinal clearance is the plan's
  narrowing on s4 and is not restated here.

  s5 is the record's residue: no verdict turns on it.

  s6 (`overtakingAnyVehicle`, negated in the applicability). Some road user other than the subject
  is a vehicle of DEF-NRS-484A-320::vehicle or a combination of DEF-NRS-484A-050, and the subject
  is passing it (`drv.interaction.overtaking`, with the reading's same-direction tolerance and
  minimum speed excess). The overtaking road user is the subject, whose class s1 already fixes.

  s7 (`movingOnMultiLaneHighway`, negated in the applicability). The subject is a vehicle or a
  combination; it is not at a standstill (`drv.motion.standstill`, the posted definition of a
  complete cessation from movement, negated for "while moving"); it is traffic
  (DEF-NRS-484A-285::traffic), which fixes whose movement the lanes are available for; and it
  occupies (`rel.occupies`) a lane (`st.lane`) that lies on a highway (`st.on_way`, `st.highway`)
  on which two or more lanes run in that lane's direction of travel. The last is read from the two
  observations the claimed atoms carry of that one fact: the lane's recorded count of lanes in its
  direction (`st.lane_adjacency`, field `count`) is at least the text's two, or another lane on the
  same highway carries the same direction of travel (`st.lane_direction`, both components). Either
  observation establishes the fact the words state; neither adds a requirement to it, and the
  direction read is the one the subject travels in because it is the direction of the lane the
  subject occupies.

  THE READING I CHOSE (declared in `narrowings`)

  s3: "no obstruction lies in that space". The atoms the node claims for this standard carry no
  relation that places a structure region within the space between two bodies: `rel.occupies`
  relates a road user to a region, `rel.surface_gap` two road users, and the node claims no
  `st.region_geometry`. The leaf is therefore read at the coarsest place those atoms reach: an
  `st.obstruction` region that lies on the highway the subject's lane lies on makes the conditions
  not permit, so the reading relieves the duty in some scenes where the words would relieve it only
  for an obstruction in the space itself.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified variables: the followed road user, an overtaken road user, a road user in the
    space, the highway and lanes of s7, the roadway and the obstruction of s3. -/
def uU : Arg := .var "u"
def wW : Arg := .var "w"
def hwR : Arg := .var "hw"
def lnR : Arg := .var "ln"
def ln2R : Arg := .var "ln2"
def hw2R : Arg := .var "hw2"
def ln3R : Arg := .var "ln3"
def rdR : Arg := .var "rd"
def obR : Arg := .var "ob"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConditionsPermitMaxInterveningUsers : Term := .param "p.conditions_permit_max_intervening_users"
def pConditionsPermitMinSpeed : Term := .param "p.conditions_permit_min_speed"
def pOvertakingMinSpeedExcess : Term := .param "p.overtaking_min_speed_excess"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's own figures. -/
def eightyInches : Term := .lit (Units.inches 80) .metre
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre
def twoLanes : Term := .lit (Units.ratio 2 1) .count

-- The admitted aggregates the node claims, each by its id.
def truckAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-305::truck"] []
def combinationAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-050::combination_of_vehicles"] []
def vehicleAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
def trafficAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-285::traffic"] []

/-- The overall width the words measure: `kin.extent`'s width read, which is the full width. -/
def overallWidth (x : Arg) : Term := .measure "kin_extent" [x, .lit "width"]

/-- s1 and s2: a truck of the truck aggregate, or a combination of that aggregate 80 inches or
    more in overall width. -/
def truckOrWideCombination (x : Arg) : Formula :=
  .or (truckAggregate x)
    (.and (combinationAggregate x) (.cmp (overallWidth x) .ge eightyInches))

/-- The space between the two bodies, along the subject's heading. -/
def gapAhead (a b : Arg) : Term := .measure "rel_surface_gap" [a, b, .lit "longitudinal"]
/-- `a` is ahead of `b` in the lane the two share. -/
def aheadInLane (a b : Arg) : Formula := .atom "rel_ahead_behind_in_lane" [a, b] []
def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

def following (a b : Arg) : Formula :=
  .derived "drv_interaction_following" [a, b] [pSameDirectionCosineTolerance]
def overtaking (a b : Arg) : Formula :=
  .derived "drv_interaction_overtaking" [a, b] [pSameDirectionCosineTolerance, pOvertakingMinSpeedExcess]
def standstill (x : Arg) : Formula :=
  .derived "drv_motion_standstill" [x] [pStandstillSpeedTolerance]

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-305::truck, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, kin.extent -/
def clsV : Formula := truckOrWideCombination vV

/-- s2: the subject is following another truck or wide combination. -/
def followsWideTruck : Formula :=
  .existsUser "u"
    (.and (.not (.same vV uU))
      (.and (truckOrWideCombination uU) (following vV uU)))

/-- s6: the subject is overtaking and passing a vehicle or a combination of vehicles. -/
def overtakingAnyVehicle : Formula :=
  .existsUser "w"
    (.and (.not (.same vV wW))
      (.and (.or (vehicleAggregate wW) (combinationAggregate wW)) (overtaking vV wW)))

/-- The count of lanes in a lane's direction of travel. -/
def laneCount (ln : Arg) : Term := .measure "st_lane_adjacency" [ln, .lit "count"]
def laneDirectionX (ln : Arg) : Term := .measure "st_lane_direction" [ln, .lit "x"]
def laneDirectionY (ln : Arg) : Term := .measure "st_lane_direction" [ln, .lit "y"]

/-- s7: two or more lanes of the highway `hw` run in the direction of travel of the lane `ln` the
    subject occupies — the lane's recorded count in that direction is at least two, or another lane
    on the same highway carries the same direction. -/
def twoOrMoreLanesInDirection : Formula :=
  .or (.cmp (laneCount lnR) .ge twoLanes)
    (.existsRegion (.lit "lane") "ln2"
      (.and (.atom "st_lane" [ln2R] [])
        (.and (.atom "st_on_way" [ln2R, hwR] [])
          (.and (.not (.same lnR ln2R))
            (.and (.cmp (laneDirectionX ln2R) .eq (laneDirectionX lnR))
                  (.cmp (laneDirectionY ln2R) .eq (laneDirectionY lnR)))))))

/-- s7: the subject, a vehicle or a combination and a member of traffic, is moving on a highway on
    which two or more lanes are available for traffic moving in its direction. -/
def movingOnMultiLaneHighway : Formula :=
  .and (.or (vehicleAggregate vV) (combinationAggregate vV))
    (.and (.not (standstill vV))
      (.and (trafficAggregate vV)
        (.existsRegion (.lit "highway") "hw"
          (.and (.atom "st_highway" [hwR] [])
            (.existsRegion (.lit "lane") "ln"
              (.and (.atom "st_lane" [lnR] [])
                (.and (.atom "rel_occupies" [vV, lnR] [])
                  (.and (.atom "st_on_way" [lnR, hwR] [])
                        twoOrMoreLanesInDirection))))))))

/-- Applicability: s2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width,; s5 (condition): so that an overtaking vehicle may enter and occupy such space without danger,; s6 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.; s7 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction. -/
def applicability : Formula :=
  .and followsWideTruck
    (.and (.not overtakingAnyVehicle) (.not movingOnMultiLaneHighway))

/-- s3: the road users that occupy a roadway of the subject's and lie in the space between the
    subject and the road user `u` it follows. `count` reads no value of its term, so the term is
    zero. -/
def interveningUsers (u : Arg) : Term :=
  .aggregate .count "w"
    (.and (.not (.same wW vV))
      (.and (.not (.same wW u))
        (.and (.existsRegion (.lit "roadway") "rd"
                (.and (.atom "st_roadway" [rdR] [])
                  (.and (.atom "rel_occupies" [vV, rdR] [])
                        (.atom "rel_occupies" [wW, rdR] []))))
          (.and (aheadInLane wW vV)
                (.cmp (gapAhead vV wW) .lt (gapAhead vV u))))))
    zeroMetres

/-- s3: no obstruction lies on the highway the subject's lane lies on (the narrowing declared
    below: the claimed atoms place no region within the space itself). -/
def noObstructionOnTheWay : Formula :=
  .not (.existsRegion (.lit "highway") "hw2"
    (.and (.atom "st_highway" [hw2R] [])
      (.and (.existsRegion (.lit "lane") "ln3"
              (.and (.atom "st_lane" [ln3R] [])
                (.and (.atom "rel_occupies" [vV, ln3R] [])
                      (.atom "st_on_way" [ln3R, hw2R] []))))
            (.existsRegion (.lit "obstruction") "ob"
              (.and (.atom "st_obstruction" [obR] [])
                    (.atom "st_on_way" [obR, hw2R] []))))))

/-- s3 (the operationalization "whenever conditions permit"). The convention's last leaf, that no
    `dev.temporary_traffic_control` lies in the space, is not written: the node claims no atom that
    ties a device to the subject or to a region (`dev.governs`, `dev.position`), so a device
    quantifier would range over every device of the scene, the subject's or not. See the header and
    `task_result.md`: this is a defect of the node's mapping, and the gate reports the claim as
    unused. -/
def conditionsPermit (u : Arg) : Formula :=
  .and (.cmp (speedOf vV) .ge pConditionsPermitMinSpeed)
    (.and (.cmp (interveningUsers u) .le pConditionsPermitMaxInterveningUsers)
          noObstructionOnTheWay)

/-- Obligation: s3 (standard): shall, whenever conditions permit,; s4 (obligation): leave a space of 500 feet -/
def obligation : Formula :=
  .forallUser "u"
    (.implies
      (.and (.not (.same vV uU))
        (.and (truckOrWideCombination uU)
          (.and (following vV uU) (aheadInLane uU vV))))
      (.implies (conditionsPermit uU) (.cmp (gapAhead vV uU) .ge fiveHundredFeet)))

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
          concepts := ["dev.temporary_traffic_control", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.obstruction", "st.roadway"]
          params := ["p.conditions_permit_min_speed", "p.conditions_permit_max_intervening_users"]
          convention := "Traffic-flow feasibility convention (free-flow versus congested operation in highway capacity practice): leaving and holding a long space ahead is possible only where the stream runs freely and nothing occupies the space. The conditions permit at an observation where the subject's kin.speed, “magnitude of velocity”, is at least p.conditions_permit_min_speed, so that a queue or stop-and-go running is not read as a failure to leave the space; and where the number of road users that occupy the subject's roadway (rel.occupies with st.roadway) between the subject and the vehicle it follows, read through the longitudinal component of rel.surface_gap and rel.ahead_behind_in_lane, is at most p.conditions_permit_max_intervening_users, so that a vehicle that has moved into the space is not read as the subject's closing of it; and where no st.obstruction, “a physical object on or beside the roadway that is not a road user”, and no dev.temporary_traffic_control, “cones, barricades, temporary signs and flashers marking works, a closure or an obstruction”, lies in that space, since a works zone or a blocked lane makes the space impossible to hold. Both magnitudes are parameters of the reading; the words state none."
          surrogate := false } ]
    residues := ["The purpose clause explains the figure the law itself fixes: the space is 500 feet, and the words “so that an overtaking vehicle may enter and occupy such space without danger” state what that space is for, adding no further requirement to the duty, which is met by leaving the stated space and breached by not leaving it. The ontology reads a purpose through the conduct it explains, and here that conduct is the leaving of the space the next words measure. The rule is held to this: no verdict of the node turns on these words."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The standard's words relieve the duty where an obstruction lies in the space between the two bodies. The atoms this operationalization claims place no structure region within that space: rel.occupies relates a road user to a region, rel.surface_gap two road users, and the node claims no st.region_geometry. The leaf is therefore read at the coarsest place those atoms reach — an st.obstruction region lying on the highway the subject's lane lies on — so the conditions are read as not permitting in some scenes where the words would still require the space."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_2

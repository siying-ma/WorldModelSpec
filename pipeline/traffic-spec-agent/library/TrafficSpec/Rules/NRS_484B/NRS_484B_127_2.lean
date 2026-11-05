/-
  NRS_484B_127_2 — NRS-484B-127-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of any truck or combination of vehicles 80 inches or more in overall width,
    s2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width, shall,
    s3 (standard): whenever conditions permit,
    s4 (obligation): leave a space of 500 feet
    s5 (definitional): so that an overtaking vehicle may enter and occupy such space without danger,
    s6 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.
    s7 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'kin.extent', 'rel.occupies', 'st.lane'], derived ['drv.interaction.following_vehicle_ahead']
    s4: atoms ['rel.surface_gap'], derived ['drv.interaction.following_vehicle_ahead']
    s6: atoms ['ru.aggregate=DEF-NRS-484A-305::truck', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane'], derived ['drv.interaction.passing_vehicle_ahead']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'st.highway', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.on_way', 'rel.occupies', 'kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s1: 80 in — 80 inches
    s2: 80 in — 80 inches
    s4: 500 ft — 500 feet
    s7: 2 count — two or more lanes

  How each span is written.

  s1 — `clsSubject` (= `wideTruckOrCombination vSubject`): the two admitted aggregates as two
  `ru_aggregate` atoms under their admitted ids, joined by `.or` ("any truck or combination of
  vehicles"), and "80 inches or more in overall width" as `kin_extent` read with the `width`
  selector, which Core reads as the full width (twice the half-extent the trace writes), at or
  above the text's 80 inches. The record's observable reading of "the driver of" (the vehicle's
  controlled motion) is the plan's and is not restated in `narrowings`.

  s2 — `leaderSelection`: a road user other than the subject (`same`), of the same two admitted
  aggregates and of the same width, that the subject follows: `drv.interaction.following_vehicle_ahead`
  of the subject and that road user, with the reading's `p.same_direction_tolerance` as the
  alignment tolerance and `p.motion_speed_tolerance` as the motion tolerance (the concept's two
  formal magnitudes, in its order). The line of travel the relation is read on is anchored as the
  record states, by `rel.occupies` on the `st.lane` quantifier (`occupiesLane`): the subject's
  footprint overlaps a region of kind lane, and that the leader's body lies on that same lane is
  what the relation the concept is built on (`rel.ahead_behind_in_lane`, which holds only where a
  region both road users occupy is of kind lane) already says, so both bodies are anchored on one
  lane and the condition is the same one either way of writing it. Reading the leader's own
  `rel.occupies` a second time would add nothing to the condition and would make the trigger
  unreadable of a leader whose footprint a source does not draw, which is the one source under
  which the `blind` witness's masked atom can be absent.

  s3 — `conditionsPermit`, the operationalization: the subject's own speed at or above
  `p.free_flow_min_speed` (`kin_speed`), and no third road user of the vehicle aggregate inside
  the space it must leave — a road user other than the vehicle it follows, in the vehicle
  aggregate, ahead of the subject in the same line of travel (`rel_ahead_behind_in_lane` with the
  third user first, which Core reads as "the first is ahead of the second", on a lane both
  footprints overlap), whose longitudinal body gap to the subject is below the 500 feet the
  obligation states. Declared as a narrowing on s3.

  s4 — `spaceLeft`: the longitudinal component of `rel_surface_gap` between the subject's body and
  the body of the truck or combination it follows, at or above 500 feet. The record's element
  fixes the component ("read as its longitudinal component along the subject's heading") and
  refuses `rel.centre_distance`. The duty is written for every road user the trigger selects
  (`forallUser` with the whole of `leaderSelection` restated, so the obligation speaks of the same
  road user the applicability selected): where more than one wide truck travels ahead of the
  subject in its line of travel, the space is owed to each. Declared as a narrowing on s4.

  s5 — residue, the node's: the purpose the legislature gives for the figure adds no observable
  condition, and the duty is the 500-foot space itself.

  s6 — `passesVehicleAhead`, negated in the applicability: a road user other than the subject, of
  the vehicle aggregate, that the subject is going by — `drv.interaction.passing_vehicle_ahead`
  with `p.pass_window` as the window, `p.same_direction_tolerance` as the alignment tolerance and
  `p.motion_speed_tolerance` as the closing tolerance, the only speed resolution the node's
  parameters carry (the speed difference below which a reading counts as no gain is read at the
  reading's resolution for no travel). The lane and the anchor are the record's `st.lane` and
  `rel.occupies`, on a lane both footprints overlap. The span's words "any vehicle or combination
  of vehicles" are carried by the vehicle aggregate alone: under the run's reading the
  combination-of-vehicles aggregate includes exactly `ru.trailer_or_combination`, which the
  vehicle aggregate also includes, so the two aggregates' union is the vehicle aggregate and the
  second limb could never decide a case; the combination aggregate is claimed and written where it
  does decide, on s1 and s2.

  s7 — `onMultiLaneWay`, negated in the applicability: the subject is of the vehicle aggregate (by
  the same equality of the two aggregates' union as on s6) and of the traffic aggregate — it is
  itself traffic moving in that direction — it is moving (`kin_speed` above the reading's motion
  tolerance), and it occupies a lane (`st.lane`, `rel.occupies`) that lies (`st_on_way`) on a
  highway (`st.highway`), whose `st.lane_adjacency` records two or more lanes in that lane's
  direction and which carries a designated direction of travel at all (`st.lane_direction`: the
  sum of the absolute components of the direction Core reads is positive, so a lane with no
  direction recorded leaves the exception unknown rather than engaged — the count is the count of
  lanes in a direction, and a lane with no direction carries no traffic moving in one).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The road users the formulas quantify over, each anchored to the subject. -/
def vLeader : Arg := .var "leader"
def vPassed : Arg := .var "passed"
def vThird : Arg := .var "third"

/-- The regions the formulas quantify over, each anchored to a road user. -/
def vLane : Arg := .var "lane"
def vSpaceLane : Arg := .var "space_lane"
def vOwnLane : Arg := .var "own_lane"
def vWay : Arg := .var "way"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFreeFlowMinSpeed : Term := .param "p.free_flow_min_speed"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pPassWindow : Term := .param "p.pass_window"
def pSameDirectionTolerance : Term := .param "p.same_direction_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

/-- The literals the text states. -/
def inches80 : Term := .lit (Units.inches 80) .metre
def feet500 : Term := .lit (Units.feet 500) .metre
def twoLanes : Term := .lit (Q.ofInt 2) .count

/-- The admitted aggregates the node claims, each as one atom under its admitted id. -/
def inTruck (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-305::truck"] []
def inCombination (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-050::combination_of_vehicles"] []
def inVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
def inTraffic (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-285::traffic"] []

/-- s1, s2: "80 inches or more in overall width" — the body's own full width. -/
def widthAtLeast80 (x : Arg) : Formula :=
  .cmp (.measure "kin_extent" [x, .lit "width"]) .ge inches80

/-- s1, s2: a truck or a combination of vehicles, 80 inches or more in overall width. -/
def wideTruckOrCombination (x : Arg) : Formula :=
  .and (.or (inTruck x) (inCombination x)) (widthAtLeast80 x)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-305::truck, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, kin.extent -/
def clsSubject : Formula := wideTruckOrCombination vSubject

/-- s2, s4: the subject travels behind that road user in the same line of travel. -/
def followsAhead (x y : Arg) : Formula :=
  .derived "drv_interaction_following_vehicle_ahead" [x, y]
    [pSameDirectionTolerance, pMotionSpeedTolerance]

/-- s2, s6, s3: the line of travel the relations are read on — a lane (`st.lane`) the subject's
    footprint overlaps (`rel.occupies`), which also anchors the quantified lane to the binder. That
    the other body travels in that same lane is what `rel.ahead_behind_in_lane` says, which every
    relation read here is built on: it holds of two road users only where a region both occupy is
    of kind lane, so the two bodies are anchored on one lane exactly as the record states. -/
def occupiesLane (v : String) (vr : Arg) : Formula :=
  .existsRegion (.lit "lane") v (.atom "rel_occupies" [vSubject, vr] [])

/-- s2: the road user the subject is following — a truck or a combination of vehicles 80 inches or
    more in overall width, ahead of the subject in its own line of travel. -/
def leaderSelection : Formula :=
  .and (.not (.same vLeader vSubject))
    (.and (wideTruckOrCombination vLeader)
      (.and (occupiesLane "lane" vLane)
            (followsAhead vSubject vLeader)))

/-- s6: the subject is overtaking and passing a vehicle. -/
def passesVehicleAhead : Formula :=
  .existsUser "passed"
    (.and (.not (.same vPassed vSubject))
      (.and (inVehicle vPassed)
        (.and (occupiesLane "lane" vLane)
              (.derived "drv_interaction_passing_vehicle_ahead" [vSubject, vPassed]
                 [pPassWindow, pSameDirectionTolerance, pMotionSpeedTolerance]))))

/-- s7: the lane carries a designated direction of travel at all. -/
def laneHasDirection : Formula :=
  .cmp (.add (.abs (.measure "st_lane_direction" [vOwnLane, .lit "x"]))
             (.abs (.measure "st_lane_direction" [vOwnLane, .lit "y"])))
       .gt zeroRatio

/-- s7: the subject is moving on a highway on which there are two or more lanes available for
    traffic moving in the same direction. -/
def onMultiLaneWay : Formula :=
  .and (inVehicle vSubject)
    (.and (inTraffic vSubject)
      (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pMotionSpeedTolerance)
        (.existsRegion (.lit "highway") "way"
          (.existsRegion (.lit "lane") "own_lane"
            (.and (.atom "rel_occupies" [vSubject, vOwnLane] [])
              (.and (.atom "st_on_way" [vOwnLane, vWay] [])
                (.and (.cmp (.measure "st_lane_adjacency" [vOwnLane, .lit "count"]) .ge twoLanes)
                      laneHasDirection)))))))

/-- Applicability: s2 (trigger): which is following a truck, or combination of vehicles 80 inches or more in overall width, shall,; s6 (exception): but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicle or combination of vehicles.; s7 (exception): This subsection does not apply to any vehicle or combination of vehicles while moving on a highway on which there are two or more lanes available for traffic moving in the same direction. -/
def applicability : Formula :=
  .and (.existsUser "leader" leaderSelection)
    (.and (.not passesVehicleAhead) (.not onMultiLaneWay))

/-- s3: a third road user of the vehicle aggregate already inside the space to be left — ahead of
    the subject in the same line of travel, nearer than the space the obligation states. -/
def spaceOccupied : Formula :=
  .existsUser "third"
    (.and (.not (.same vThird vSubject))
      (.and (.not (.same vThird vLeader))
        (.and (inVehicle vThird)
          (.and (.atom "rel_ahead_behind_in_lane" [vThird, vSubject] [])
            (.and (occupiesLane "space_lane" vSpaceLane)
                  (.cmp (.measure "rel_surface_gap" [vSubject, vThird, .lit "longitudinal"])
                        .lt feet500))))))

/-- s3: whenever conditions permit — the subject's own travel free, and the space not already
    occupied. -/
def conditionsPermit : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .ge pFreeFlowMinSpeed) (.not spaceOccupied)

/-- s4: the space of 500 feet, as the longitudinal gap between the two bodies. -/
def spaceLeft : Formula :=
  .cmp (.measure "rel_surface_gap" [vSubject, vLeader, .lit "longitudinal"]) .ge feet500

/-- Obligation: s3 (standard): whenever conditions permit,; s4 (obligation): leave a space of 500 feet -/
def obligation : Formula :=
  .forallUser "leader"
    (.implies leaderSelection (.implies conditionsPermit spaceLeft))

def rule : Rule :=
  { id := "NRS_484B_127_2"
    laws := ["NRS-484B-127-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "whenever conditions permit"
          concepts := ["drv.interaction.following_vehicle_ahead", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.lane"]
          params := ["p.free_flow_min_speed", "p.motion_speed_tolerance", "p.same_direction_tolerance"]
          convention := "space-keeping convention of traffic-stream practice: the 500-foot space can be left only where the stream ahead of the subject runs freely, so the condition is read by the degree to which the subject's own travel is free — its speed at or above p.free_flow_min_speed, the speed below which the stream is queued or congested and a follower cannot open a gap of that length — and by there being no third road user of the vehicle aggregate in the same line of travel between the subject and the vehicle it follows (rel.ahead_behind_in_lane on the subject's lane, with rel.surface_gap placing it inside the space), since a vehicle already occupying the space makes leaving it impossible. The following relation it is read on is recognized with p.same_direction_tolerance and p.motion_speed_tolerance."
          surrogate := false } ]
    residues := ["The purpose the legislature gives for the figure — that an overtaking vehicle may enter and occupy the space without danger — states no further duty: the duty is the 500-foot space itself, which the obligation span carries in full, and the words add no observable condition to it. Nothing of the obligation is dropped by not modelling the danger an overtaking vehicle would otherwise run."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "the space is owed to every road user the trigger selects: the obligation restates the whole of the trigger's selection (`leaderSelection`) under a `forallUser`, so where more than one truck or combination of vehicles 80 inches or more in overall width travels ahead of the subject in its own line of travel, the longitudinal body gap of 500 feet is required of each of them, not of a chosen one."
          kind := "reading" }
      , { span := "s3"
          why := "\"conditions permit\" is read, as the operationalization's convention directs, by two observable facts and no others: the subject's own speed at or above `p.free_flow_min_speed`, and the space to be left not already occupied — no road user of the vehicle aggregate, other than the one the subject follows, ahead of the subject in a lane both bodies overlap whose longitudinal body gap to the subject is below the 500 feet the obligation states. Where neither fact fails the conditions count as permitting; weather, surface and visibility are not read into the span, as the record's narrowing on s3 states."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_2

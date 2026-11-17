/-
  NRS_484B_208_1 — NRS-484B-208-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    k1 (exception): Except as otherwise provided in subsection 2,
    k2 (condition): on a controlled-access highway
    k3 (condition): which has two or more clearly marked lanes for traveling in the same direction,
    k4 (obligation): a driver may not continue to operate a motor vehicle in the extreme left lane
    k5 (trigger): if the driver knows, or reasonably should know, that he or she is traveling at a rate of speed which is less than the posted speed limit for that portion of the controlled-access highway
    k6 (trigger): and is being overtaken in that lane from the rear by a motor vehicle traveling at a higher rate of speed.
    k8 (exception): The requirements of subsection 1 do not apply: (a) To a driver operating a motor vehicle that is:
    k9 (exception): (1) Overtaking another vehicle proceeding in the same direction;
    k10 (exception): (2) Preparing for a left turn
    k11 (exception): at an intersection;
    k12 (exception): (3) Traveling in a lane designated for the use of high-occupancy vehicles pursuant to NRS 484A.460,
    k13a (exception): if the driver complies with the requirements to travel in such a lane
    k13b (reference): [DEF-NRS-484A-460-2, NRS-484B-323-1]
    k14 (exception): or (4) Engaged in the construction, maintenance or repair of the highway, including, without limitation, the removal of snow.
    k15 (exception): (b) When traffic conditions, inclement weather, obstructions or hazards
    k16 (standard): make it necessary to drive in the extreme left lane.
    k17 (exception): (c) When compliance with an official traffic control device or the directions given by a peace officer makes it necessary to drive in the extreme left lane.
    k18 (exception): (d) To the driver of an authorized emergency vehicle in the course of his or her official duties.
    k19 (exception): (e) To a driver operating a motor vehicle
    k20 (exception): within the geographical limits of a city or town.

  Elements (span → atoms, derived):
    k2: atoms ['rel.occupies', 'st.controlled_access'], derived []
    k3: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    k4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    k5: atoms ['kin.speed', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    k6: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'rel.ahead_behind_in_lane', 'kin.speed'], derived []
    k8: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    k9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.overtake_pass']
    k11: atoms ['st.intersection'], derived []
    k12: atoms ['rel.occupies', 'st.reserved_lane'], derived [], borrowing ['k13b']
    k13a: atoms ['ru.aggregate=DEF-NRS-484A-460-2::high_occupancy_vehicle', 'dev.zone_sign', 'dev.governs', 'prim.conditions_hold'], derived [], borrowing ['k13b']
    k14: atoms ['ru.official_vehicle', 'sig.warning_lamp'], derived []
    k15: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.lane', 'st.lane_adjacency', 'env.precipitation', 'env.wet_road', 'env.ice_or_snow', 'env.visibility', 'st.obstruction', 'st.region_geometry', 'prim.region_lateral_offset'], derived []
    k17: atoms ['dev.governs', 'dev.lane_control_signal', 'dev.regulatory_sign', 'dev.temporary_traffic_control', 'dev.human_direction', 'rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    k18: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle', 'sig.warning_lamp', 'sig.siren'], derived []
    k19: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    k13b: DEF-NRS-484A-460-2: (a) A vehicle that is transporting more than one person; (b) A motorcycle, regardless of the number of passengers; (c) A bus, regardless of the number of passengers; and (d) Any other vehicle designated by regulation.

  Literals the text states (each written through its Units constructor):
    k3: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN
    k8, k19 (class): the subject is `ru_aggregate DEF-NRS-484A-130::motor_vehicle`.
    k2: some `controlled_access` region the subject occupies (`onControlledAccess`).
    k3, k4 ("extreme left lane" of "two or more … lanes … in the same direction"): some lane the
      subject occupies whose `st_lane_adjacency` count is at least the text's two, and which has no
      left neighbouring lane of the same direction (`st_lane_adjacency l "left" l'` false for every
      lane l'). Core decides that relation false for every l' exactly where the lane is first from
      the left (ordinal 1) and has no left neighbour, so this is the record's "ordinal first" read
      without writing an ordinal figure the text does not state (`inExtremeLeftLane`).
    k5: some maximum `dev_speed_limit_sign` governing a travel region the subject occupies, with the
      subject's `kin_speed` below its value (`belowPostedLimit`).
    k6: O — some motor vehicle c (not the subject) behind the subject in its lane
      (`rel_ahead_behind_in_lane subject c`: the subject is ahead of c in a shared lane) whose speed
      is above the subject's (`overtakenFromRear`).
    k9: within the window ahead of p.overtake_window, `drv_interaction_overtake_pass(subject, c)` for
      some vehicle c other than the subject (`overtaking`).
    k10, k11: `intent int.left_turn` of the subject at some intersection region (`preparingLeftTurn`).
    k12, k13a, k13b: the subject occupies a reserved lane of class high_occupancy, is a
      DEF-NRS-484A-460-2::high_occupancy_vehicle, and `prim_conditions_hold(z, subject)` for every
      zone sign z of kind high_occupancy_lane governing that lane (`inHovLaneComplying`).
    k14: the subject is an official vehicle of kind highway_maintenance showing an amber warning
      lamp, flashing or rotating (`engagedInRoadWork`).
    k15, k16: S_stop = speed × H + speed² / (D + D) (the convention's 2 × D written as D + D, so no
      figure enters), with H, D selected by surface: _ice where env.ice_or_snow, else _wet where
      env.wet_road or env.precipitation, else _dry (`stoppingDistance`). The left lane is necessary
      where a traffic member (not the subject) occupies the lane to the right of a lane the subject
      occupies with longitudinal surface gap below S_stop (`trafficTooClose`), or an obstruction lies
      within ground distance S_stop with negative lateral offset (`obstructionOnRight`), or
      env.visibility is below S_stop (`visibilityShort`).
    k17: a device governing the lane to the right of a lane the subject occupies closes it: a lane
      control signal red_x or yellow_x, a regulatory sign closed_to_traffic or do_not_enter, a
      temporary traffic control, or a human direction by a police_officer indicating stop
      (`rightLaneClosed`).
    k18 (applicability): not (the subject is an authorized emergency vehicle and shows a warning
      lamp of any colour flashing or rotating, or sounds a siren) (`aevOnDuty`).
    k20 (applicability): not `asm.within_city_or_town_limits`.
    S (`stays`): k2 ∧ k3/k4 ∧ k5 ∧ none of k9, k10/k11, k12/k13a, k14, k15/k16, k17.
    Obligation: not (holdsFor time p.left_lane_move_over_time of since(S, O ∧ S), and some motor
      vehicle other than the subject behind the subject in its lane now) — the record's.
  Each formula binds its own quantifier variables under a distinct suffix, so no two quantifiers of
  one formula share a name.

  OPEN DEFECTS OF THE NODE (reported in task_result.md, not repaired here)
    k10/k11: the intersection the intention targets is bound only by the intention; the gate does
      not take `intent` as an anchor, and k11 claims no anchoring atom (UNANCHORED_VARIABLE).
    k18 / branch_4 and k14: the reading resolves DEF-NRS-484A-020::authorized_emergency_vehicle for
      no class, so for any motor vehicle with a lamp flashing or rotating the applicability is
      unknown: branch_4 cannot be not_applicable, and the k14 exception (an amber lamp) can never
      be decided.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_208_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pLeftLaneMoveOverTime : Term := .param "p.left_lane_move_over_time"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- k3: "two or more … lanes": the text's literal. -/
def twoLanes : Term := .lit (Units.ratio 2 1) .count

-- ---------------------------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------------------------
def allOf : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (allOf rest)

def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

def aggMotorVehicle : String := "DEF-NRS-484A-130::motor_vehicle"
def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggHighOccupancy : String := "DEF-NRS-484A-460-2::high_occupancy_vehicle"
def aggTraffic : String := "DEF-NRS-484A-285::traffic"
def aggEmergency : String := "DEF-NRS-484A-020::authorized_emergency_vehicle"

def member (x agg : String) : Formula := .atom "ru_aggregate" [.var x, .lit agg] []
def occupies (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def speedOf (x : String) : Term := .measure "kin_speed" [.var x]
/-- A road user other than the subject. -/
def other (x : String) : Formula := .not (.same (.var x) vSubject)

/-- sig.warning_lamp of a colour in a mode, on the subject. -/
def lamp (colour mode : String) : Formula := .atom "sig_warning_lamp" [vSubject, .lit colour, .lit mode] []
def flashingOrRotating (colour : String) : Formula := .or (lamp colour "flashing") (lamp colour "rotating")

-- ---------------------------------------------------------------------------------------------
-- Class, place
-- ---------------------------------------------------------------------------------------------
/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := member "subject" aggMotorVehicle

/-- k2: the subject occupies a controlled-access highway. -/
def onControlledAccess (sfx : String) : Formula :=
  .existsRegion (.lit "controlled_access") ("ca" ++ sfx) (occupies "subject" ("ca" ++ sfx))

/-- k3, k4: the subject occupies a lane that is first from the left of two or more lanes in its
    direction. -/
def inExtremeLeftLane (sfx : String) : Formula :=
  let l := "lane" ++ sfx
  let n := "leftNeighbour" ++ sfx
  .existsRegion (.lit "lane") l (allOf
    [ occupies "subject" l
    , .cmp (.measure "st_lane_adjacency" [.var l, .lit "count"]) .ge twoLanes
    , .not (.existsRegion (.lit "lane") n (.atom "st_lane_adjacency" [.var l, .lit "left", .var n] [])) ])

/-- k5: the subject's speed is below the value of a maximum speed-limit sign governing a travel
    region it occupies. -/
def belowPostedLimit (sfx : String) : Formula :=
  let d := "limitSign" ++ sfx
  let r := "portion" ++ sfx
  .existsDevice (.lit "speed_limit_sign") d (allOf
    [ .atom "dev_speed_limit_sign_kind" [.var d, .lit "maximum"] []
    , .existsRegion (.lit "travel_region") r (.and (occupies "subject" r) (governs d r))
    , .cmp (speedOf "subject") .lt (.measure "dev_speed_limit_sign_value" [.var d]) ])

-- ---------------------------------------------------------------------------------------------
-- Exceptions read inside S
-- ---------------------------------------------------------------------------------------------
/-- k9: within the window ahead, the subject overtakes and passes another vehicle. -/
def overtaking (sfx : String) : Formula :=
  let c := "passed" ++ sfx
  .within .time pOvertakeWindow "subject" (.existsUser c (allOf
    [ other c
    , member c aggVehicle
    , .derived "drv_interaction_overtake_pass" [vSubject, .var c] [pOvertakeWindow, pOvertakeSameDirectionCos] ]))

/-- k10, k11: the subject's declared plan includes a left turn at an intersection. -/
def preparingLeftTurn (sfx : String) : Formula :=
  let i := "turnAt" ++ sfx
  .existsRegion (.lit "intersection") i (.intent "int.left_turn" vSubject (.var i))

/-- k12, k13a, k13b: the subject travels in a high-occupancy lane, is a high-occupancy vehicle, and
    the conditions of every high-occupancy-lane zone sign governing that lane hold for it. -/
def inHovLaneComplying (sfx : String) : Formula :=
  let r := "hovLane" ++ sfx
  let z := "hovSign" ++ sfx
  .existsRegion (.lit "reserved_lane") r (allOf
    [ occupies "subject" r
    , .atom "st_reserved_lane_class" [.var r, .lit "high_occupancy"] []
    , member "subject" aggHighOccupancy
    , .forallDevice (.lit "zone_sign") z
        (.implies
          (.and (.atom "dev_zone_sign_kind" [.var z, .lit "high_occupancy_lane"] []) (governs z r))
          (.derived "prim_conditions_hold" [.var z, vSubject] [])) ])

/-- k14: a highway-maintenance vehicle at work: amber warning lamp flashing or rotating. -/
def engagedInRoadWork : Formula :=
  allOf
    [ .atom "ru_official_vehicle" [vSubject] []
    , .atom "ru_official_vehicle_kind" [vSubject, .lit "highway_maintenance"] []
    , flashingOrRotating "amber" ]

/-- k16 operationalization: the stopping distance S_stop = speed × H + speed² / (D + D). -/
def stopping (h d : Term) : Term :=
  .add (.mul (speedOf "subject") h) (.div (.mul (speedOf "subject") (speedOf "subject")) (.add d d))

def surfaceIcy : Formula := .atom "env_ice_or_snow" [] []
def surfaceWet : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

def stoppingDistance : Term :=
  .cond surfaceIcy (stopping pFollowingHeadwayIce pFollowingDecelIce)
    (.cond surfaceWet (stopping pFollowingHeadwayWet pFollowingDecelWet)
      (stopping pFollowingHeadwayDry pFollowingDecelDry))

/-- The lane to the right of a lane the subject occupies, and what holds of it. -/
def rightLaneOf (sfx : String) (body : String → Formula) : Formula :=
  let ls := "ownLane" ++ sfx
  let lr := "rightLane" ++ sfx
  .existsRegion (.lit "lane") ls (.and (occupies "subject" ls)
    (.existsRegion (.lit "lane") lr
      (.and (.atom "st_lane_adjacency" [.var ls, .lit "right", .var lr] []) (body lr))))

/-- k15, k16 (traffic conditions): a traffic member in the right neighbouring lane within S_stop
    of the subject, longitudinally. -/
def trafficTooClose (sfx : String) : Formula :=
  rightLaneOf ("T" ++ sfx) fun lr =>
    let c := "beside" ++ sfx
    .existsUser c (allOf
      [ other c
      , member c aggTraffic
      , occupies c lr
      , .cmp (.measure "rel_surface_gap" [vSubject, .var c, .lit "longitudinal"]) .lt stoppingDistance ])

/-- k15, k16 (obstructions or hazards): an obstruction on the subject's right within S_stop. -/
def obstructionOnRight (sfx : String) : Formula :=
  let o := "obstacle" ++ sfx
  .existsRegion (.lit "obstruction") o (.and
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var o]) .lt stoppingDistance)
    (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var o] []) .lt zeroMetres))

/-- k15, k16 (inclement weather): visibility below S_stop. -/
def visibilityShort : Formula := .cmp (.measure "env_visibility" []) .lt stoppingDistance

/-- k17: a device or a peace officer governing the lane to the right closes it. -/
def rightLaneClosed (sfx : String) : Formula :=
  rightLaneOf ("C" ++ sfx) fun lr =>
    let d1 := "laneSignal" ++ sfx
    let d2 := "closureSign" ++ sfx
    let d3 := "works" ++ sfx
    let d4 := "officer" ++ sfx
    anyOf
      [ .existsDevice (.lit "lane_control_signal") d1 (.and (governs d1 lr)
          (.or (.atom "dev_lane_control_signal_state" [.var d1, .lit "red_x"] [])
               (.atom "dev_lane_control_signal_state" [.var d1, .lit "yellow_x"] [])))
      , .existsDevice (.lit "regulatory_sign") d2 (.and (governs d2 lr)
          (.or (.atom "dev_regulatory_sign_code" [.var d2, .lit "closed_to_traffic"] [])
               (.atom "dev_regulatory_sign_code" [.var d2, .lit "do_not_enter"] [])))
      , .existsDevice (.lit "temporary_traffic_control") d3 (governs d3 lr)
      , .existsDevice (.lit "human_direction") d4 (allOf
          [ governs d4 lr
          , .atom "dev_human_direction_role" [.var d4, .lit "police_officer"] []
          , .atom "dev_human_direction_indication" [.var d4, .lit "stop"] [] ]) ]

/-- None of the exceptions of subsection 2 (a)(1)-(4), (b), (c) holds. -/
def unexcused (sfx : String) : Formula :=
  .not (anyOf
    [ overtaking sfx
    , preparingLeftTurn sfx
    , inHovLaneComplying sfx
    , engagedInRoadWork
    , trafficTooClose sfx
    , obstructionOnRight sfx
    , visibilityShort
    , rightLaneClosed sfx ])

/-- S: the subject is in the extreme left lane of a controlled-access highway of two or more lanes,
    slower than the posted maximum, and unexcused. -/
def stays (sfx : String) : Formula :=
  allOf [ onControlledAccess sfx, inExtremeLeftLane sfx, belowPostedLimit sfx, unexcused sfx ]

/-- k6, O: a faster motor vehicle behind the subject in its lane. -/
def overtakenFromRear (sfx : String) : Formula :=
  let c := "rear" ++ sfx
  .existsUser c (allOf
    [ other c
    , member c aggMotorVehicle
    , .atom "rel_ahead_behind_in_lane" [vSubject, .var c] []
    , .cmp (speedOf c) .gt (speedOf "subject") ])

/-- k4: a motor vehicle is still behind the subject in its lane. -/
def followedInLane (sfx : String) : Formula :=
  let c := "follower" ++ sfx
  .existsUser c (allOf
    [ other c
    , member c aggMotorVehicle
    , .atom "rel_ahead_behind_in_lane" [vSubject, .var c] [] ])

/-- k18: an authorized emergency vehicle on duty: a warning lamp flashing or rotating, or a siren. -/
def aevOnDuty : Formula :=
  .and (member "subject" aggEmergency) (anyOf
    [ flashingOrRotating "red"
    , flashingOrRotating "blue"
    , flashingOrRotating "amber"
    , flashingOrRotating "white"
    , .atom "sig_siren" [vSubject] [] ])

/-- Applicability: k2, k3/k4 (place), not k18, not k20. -/
def applicability : Formula :=
  allOf
    [ onControlledAccess "A"
    , inExtremeLeftLane "A"
    , .not aevOnDuty
    , .not (.asm "asm.within_city_or_town_limits") ]

/-- Obligation: k4 with k5, k6, k9-k17: not (S has held, for the move-over window, since an
    observation at which O and S held together, with a motor vehicle behind the subject now). -/
def obligation : Formula :=
  .not (.and
    (.holdsFor .time pLeftLaneMoveOverTime "subject"
      (.since (stays "S") (.and (overtakenFromRear "O") (stays "R"))))
    (followedInLane "F"))

def rule : Rule :=
  { id := "NRS_484B_208_1"
    laws := ["NRS-484B-208-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_city_or_town_limits"]
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "make it necessary to drive in the extreme left lane"
          concepts := ["env.visibility", "kin.speed", "rel.surface_gap", "st.region_geometry"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "Stopping-distance convention: S = speed(subject) × H + speed(subject)² / (2 × D), with H and D selected by the surface (_ice where env.ice_or_snow, _wet where env.wet_road or env.precipitation, else _dry), as for following distance. The left lane is necessary where moving right cannot be done within S: a traffic member occupying the right neighbouring lane has a longitudinal body gap to the subject (rel.surface_gap) below S, or an obstruction lies within ground distance S of the subject on its right (st.region_geometry, prim.region_lateral_offset negative), or the visibility distance (env.visibility) is below S. Each factor enters by degree: the subject's speed and the surface move S; the gap, the distance and the visibility are compared with it."
          surrogate := false } ]
    residues := ["Points to subsection 2, which is appended to this same law line and carried by its own exception spans k8-k20; the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_208_1

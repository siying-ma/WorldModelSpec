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
    k11: atoms ['st.intersection', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived []
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

  How each span is written:
    k4/k19 (subject class): `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    k2: some controlled-access region the subject occupies.
    k3/k4 (extreme left lane of two or more): some lane the subject occupies that has no left
      neighbouring lane of its direction (`st_lane_adjacency l "left" l'` for no lane l') and whose
      count of lanes in its direction is at least the text's two.
    k20: `not asm.within_city_or_town_limits` in the applicability.
    k5: some maximum speed-limit sign governing a travel region the subject occupies, the
      subject's speed below its value.
    k6 (O): some motor vehicle other than the subject behind it in a lane both occupy
      (`rel_ahead_behind_in_lane subject c`: the subject ahead of c), faster than the subject.
    k9: within the window ahead of length p.overtake_window, the subject overtakes and passes
      some vehicle (DEF-NRS-484A-320::vehicle) other than itself.
    k10/k11: some intersection the subject occupies, or that a travel region the subject occupies
      enters (`st_lane_enters`), at which the declared intention int.left_turn of the subject
      holds at the judged observation.
    k12/k13a: some reserved lane of class high_occupancy the subject occupies, the subject a
      high-occupancy vehicle, and the conditions of every high_occupancy_lane zone sign governing
      that lane hold for the subject (`prim_conditions_hold`).
    k14: the subject an official vehicle of kind highway_maintenance showing an amber warning
      lamp flashing or rotating.
    k15/k16 (b): the stopping distance S = v·H + v²/(2·D), H and D selected by the surface
      (ice, else wet road or precipitation, else dry); the divisor D + D reads the reading's
      decelerations only. Necessity: a traffic member other than the subject
      occupying the lane right of the subject's leftmost lane with longitudinal body gap below S;
      or an obstruction within ground distance S whose lateral offset from the subject is
      negative (right); or the visibility below S.
    k17 (c): a device governing that right lane closes it: lane control signal red_x or yellow_x,
      regulatory sign closed_to_traffic or do_not_enter, a temporary traffic control, or a
      police_officer human direction indicating stop.
    k18 (d): the subject an authorized emergency vehicle showing a warning lamp of any colour
      flashing or rotating, or sounding a siren.
    k4 (duty): S (the subject on a controlled-access highway in the extreme left lane of two or
      more, below the posted maximum, and no exception holding) has held at every observation of
      the window behind of length p.left_lane_move_over_time since an observation where O and S
      held together, and some motor vehicle other than the subject is behind it in its lane: the
      duty is violated there. The lane selection of the applicability is restated whole in S, and
      (b)/(c) read the right neighbour of the very lane S selects (the same bound variable).
  No choice beyond the record's words was made: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
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

/-- k3: the text's "two" lanes. -/
def twoLanes : Term := .lit (Q.ofInt 2) .count

/-- Admitted aggregates. -/
def aMotorVehicle : Arg := .lit "DEF-NRS-484A-130::motor_vehicle"
def aVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aHighOccupancy : Arg := .lit "DEF-NRS-484A-460-2::high_occupancy_vehicle"
def aTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"
def aEmergency : Arg := .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"

def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []
def other (v : String) : Formula := .not (.same (.var v) vSubject)
def subjectSpeed : Term := .measure "kin_speed" [vSubject]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aMotorVehicle] []

/-- k3/k4: lane `l` is the extreme left lane (no left neighbour of its direction) of two or more
    lanes in its direction. -/
def extremeLeftOfTwo (l aux : String) : Formula :=
  .and (.not (.existsRegion (.lit "lane") aux (.atom "st_lane_adjacency" [.var l, .lit "left", .var aux] [])))
       (.cmp (.measure "st_lane_adjacency_count" [.var l]) .ge twoLanes)

/-- k2: the subject occupies a controlled-access highway. -/
def onControlledAccess : Formula :=
  .existsRegion (.lit "controlled_access") "cah" (occ vSubject (.var "cah"))

/-- k3/k4: the subject occupies the extreme left lane of two or more in its direction. -/
def inExtremeLeftLane : Formula :=
  .existsRegion (.lit "lane") "own" (.and (occ vSubject (.var "own")) (extremeLeftOfTwo "own" "ownLeft"))

/-- k5: the subject's speed is below the value of a maximum speed-limit sign governing a travel
    region it occupies. -/
def belowPostedMaximum : Formula :=
  .existsDevice (.lit "speed_limit_sign") "lim"
    (.and (.atom "dev_speed_limit_sign_kind" [.var "lim", .lit "maximum"] [])
      (.and (.existsRegion (.lit "travel_region") "portion"
               (.and (occ vSubject (.var "portion")) (governs (.var "lim") (.var "portion"))))
            (.cmp subjectSpeed .lt (.measure "dev_speed_limit_sign_value" [.var "lim"]))))

/-- k9: within the window ahead, the subject overtakes and passes another vehicle. -/
def excOvertaking : Formula :=
  .within .time pOvertakeWindow "subject"
    (.existsUser "passed"
      (.and (.and (other "passed") (.atom "ru_aggregate" [.var "passed", aVehicle] []))
            (.derived "drv_interaction_overtake_pass" [vSubject, .var "passed"]
              [pOvertakeWindow, pOvertakeSameDirectionCos])))

/-- k10/k11: the subject is preparing for a left turn at an intersection it occupies or that a
    travel region it occupies enters. -/
def excLeftTurn : Formula :=
  .existsRegion (.lit "intersection") "ix"
    (.and (.or (occ vSubject (.var "ix"))
               (.existsRegion (.lit "travel_region") "approach"
                  (.and (occ vSubject (.var "approach"))
                        (.atom "st_lane_enters" [.var "approach", .var "ix"] []))))
          (.intent "int.left_turn" vSubject (.var "ix")))

/-- k12/k13a: the subject travels in a high-occupancy lane and meets its posted conditions. -/
def excHighOccupancy : Formula :=
  .existsRegion (.lit "reserved_lane") "hov"
    (.and (.and (occ vSubject (.var "hov"))
                (.atom "st_reserved_lane_class" [.var "hov", .lit "high_occupancy"] []))
          (.and (.atom "ru_aggregate" [vSubject, aHighOccupancy] [])
                (.forallDevice (.lit "zone_sign") "hovSign"
                  (.implies (.and (.atom "dev_zone_sign_kind" [.var "hovSign", .lit "high_occupancy_lane"] [])
                                  (governs (.var "hovSign") (.var "hov")))
                            (.derived "prim_conditions_hold" [.var "hovSign", vSubject] [])))))

/-- k14: a highway-maintenance vehicle at work: amber warning lamp flashing or rotating. -/
def excRoadWork : Formula :=
  .and (.atom "ru_official_vehicle" [vSubject] [])
    (.and (.atom "ru_official_vehicle_kind" [vSubject, .lit "highway_maintenance"] [])
          (.or (.atom "sig_warning_lamp" [vSubject, .lit "amber", .lit "flashing"] [])
               (.atom "sig_warning_lamp" [vSubject, .lit "amber", .lit "rotating"] [])))

/-- k16: surface selection of the stopping-distance convention. -/
def onIce : Formula := .atom "env_ice_or_snow" [] []
def onWet : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])
def headway : Term := .cond onIce pFollowingHeadwayIce (.cond onWet pFollowingHeadwayWet pFollowingHeadwayDry)
/-- 2·D, D the deceleration selected by the surface. -/
def twiceDecel : Term :=
  .cond onIce (.add pFollowingDecelIce pFollowingDecelIce)
    (.cond onWet (.add pFollowingDecelWet pFollowingDecelWet) (.add pFollowingDecelDry pFollowingDecelDry))

/-- k16: `x` is below the stopping distance S = v·H + v²/(2·D); the divisor 2·D reads only the
    reading's decelerations (selected by the surface), never a measurement. -/
def belowStopping (x : Term) : Formula :=
  .cmp x .lt (.add (.mul subjectSpeed headway) (.div (.mul subjectSpeed subjectSpeed) twiceDecel))

/-- k15/k16 (traffic conditions): a traffic member other than the subject occupies lane `rl` with
    a longitudinal body gap to the subject below the stopping distance. -/
def trafficInLane (rl : String) : Formula :=
  .existsUser "beside"
    (.and (.and (other "beside") (.atom "ru_aggregate" [.var "beside", aTraffic] []))
          (.and (occ (.var "beside") (.var rl))
                (belowStopping (.measure "rel_surface_gap" [vSubject, .var "beside", .lit "longitudinal"]))))

/-- k17: a device governing lane `rl` closes it, or a peace officer directs a stop on it. -/
def closedByDevice (rl : String) : Formula :=
  .or (.or (.existsDevice (.lit "lane_control_signal") "lcs"
             (.and (governs (.var "lcs") (.var rl))
                   (.or (.atom "dev_lane_control_signal_state" [.var "lcs", .lit "red_x"] [])
                        (.atom "dev_lane_control_signal_state" [.var "lcs", .lit "yellow_x"] []))))
           (.existsDevice (.lit "regulatory_sign") "closure"
             (.and (governs (.var "closure") (.var rl))
                   (.or (.atom "dev_regulatory_sign_code" [.var "closure", .lit "closed_to_traffic"] [])
                        (.atom "dev_regulatory_sign_code" [.var "closure", .lit "do_not_enter"] [])))))
      (.or (.existsDevice (.lit "temporary_traffic_control") "works" (governs (.var "works") (.var rl)))
           (.existsDevice (.lit "human_direction") "officer"
             (.and (governs (.var "officer") (.var rl))
                   (.and (.atom "dev_human_direction_role" [.var "officer", .lit "police_officer"] [])
                         (.atom "dev_human_direction_indication" [.var "officer", .lit "stop"] [])))))

/-- (b) traffic and (c) devices: the lane to the right of the subject's extreme left lane `own`
    (the lane S selects) is taken by traffic within the stopping distance or closed. -/
def rightLaneUnavailable (own : String) : Formula :=
  .existsRegion (.lit "lane") "rightLane"
    (.and (.atom "st_lane_adjacency" [.var own, .lit "right", .var "rightLane"] [])
          (.or (trafficInLane "rightLane") (closedByDevice "rightLane")))

/-- (b) obstructions, hazards and inclement weather: an obstruction on the subject's right within
    the stopping distance, or the visibility below it. -/
def conditionsNecessitate : Formula :=
  .or (.existsRegion (.lit "obstruction") "obs"
        (.and (belowStopping (.measure "st_region_geometry_distance" [vSubject, .var "obs"]))
              (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "obs"] []) .lt zeroMetres)))
      (belowStopping (.measure "env_visibility" []))

/-- k18 (d): an authorized emergency vehicle on duty: a warning lamp of any colour flashing or
    rotating, or a siren sounding. -/
def lampShows (colour mode : String) : Formula :=
  .atom "sig_warning_lamp" [vSubject, .lit colour, .lit mode] []
def excEmergency : Formula :=
  .and (.atom "ru_aggregate" [vSubject, aEmergency] [])
    (.or (.or (.or (lampShows "red" "flashing") (lampShows "red" "rotating"))
              (.or (lampShows "blue" "flashing") (lampShows "blue" "rotating")))
         (.or (.or (lampShows "amber" "flashing") (lampShows "amber" "rotating"))
              (.or (.or (lampShows "white" "flashing") (lampShows "white" "rotating"))
                   (.atom "sig_siren" [vSubject] []))))

/-- The exceptions (a)(1)–(4), (b), (c), (d), for the subject in its extreme left lane `own`; the
    deepest of them sit nearest the root, so the formula stays shallow. -/
def excused (own : String) : Formula :=
  .or (.or excOvertaking (rightLaneUnavailable own))
      (.or conditionsNecessitate
           (.or (.or excLeftTurn excHighOccupancy) (.or excRoadWork excEmergency)))

/-- S: on the controlled-access highway, below the posted maximum, in the extreme left lane of two
    or more, and no exception holding. -/
def staysSlowInLeftLane : Formula :=
  .and (.and onControlledAccess belowPostedMaximum)
       (.existsRegion (.lit "lane") "own"
          (.and (.and (occ vSubject (.var "own")) (extremeLeftOfTwo "own" "ownLeft"))
                (.not (excused "own"))))

/-- O (k6): a faster motor vehicle behind the subject in its lane. -/
def overtakenFromRear : Formula :=
  .existsUser "rear"
    (.and (other "rear")
      (.and (.atom "ru_aggregate" [.var "rear", aMotorVehicle] [])
        (.and (.atom "rel_ahead_behind_in_lane" [vSubject, .var "rear"] [])
              (.cmp (.measure "kin_speed" [.var "rear"]) .gt subjectSpeed))))

/-- A motor vehicle still behind the subject in its lane at the judged observation. -/
def followedInLane : Formula :=
  .existsUser "follower"
    (.and (other "follower")
      (.and (.atom "ru_aggregate" [.var "follower", aMotorVehicle] [])
            (.atom "rel_ahead_behind_in_lane" [vSubject, .var "follower"] [])))

/-- Applicability: k2, k3, k4 (extreme left lane of two or more on a controlled-access highway),
    k19/k20 (not within the limits of a city or town). -/
def applicability : Formula :=
  .and onControlledAccess (.and inExtremeLeftLane (.not (.asm "asm.within_city_or_town_limits")))

/-- Obligation: k4 with k5, k6 and the exceptions k8–k18, the standard k16. Not violated:
    `holdsFor(since(S, O ∧ S))` implies that no motor vehicle is behind the subject in its lane
    (the three-valued `¬(A ∧ B)`, written as `A → ¬B`). -/
def obligation : Formula :=
  .implies (.holdsFor .time pLeftLaneMoveOverTime "subject"
              (.since staysSlowInLeftLane (.and overtakenFromRear staysSlowInLeftLane)))
           (.not followedInLane)

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

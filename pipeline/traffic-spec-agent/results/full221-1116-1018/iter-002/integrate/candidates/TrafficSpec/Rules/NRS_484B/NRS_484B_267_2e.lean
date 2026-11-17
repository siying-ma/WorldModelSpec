/-
  NRS_484B_267_2e — NRS-484B-267-2e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,
    s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,
    s3 (trigger): and making use of flashing lights meeting the requirements of
    s4 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    s5 (subject): the driver of any other vehicle shall,
    s6 (exception): except when otherwise directed by a law enforcement officer:
    s7 (standard): If possible,
    s8 (obligation): drive in a lane that is not adjacent to the lane in which the authorized emergency vehicle or official vehicle of a regulatory agency is moving,
    s9 (standard): unless roadway, traffic, weather or other conditions make doing so unsafe or impossible.
    s10 (definitional): As used in this section, “preparing to move” means any indication that is visible to an approaching driver that an authorized emergency vehicle or an official vehicle of a regulatory agency is about to move, including, without limitation: (a) A movement of the vehicle; or (b) The use of hand signals by the driver of the vehicle.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.bearing', 'rel.centre_distance', 'ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle', 'ru.official_vehicle', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []
    s3: atoms ['sig.warning_lamp'], derived [], borrowing ['s4']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s8: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.roadway'], derived []
    s10: atoms ['kin.speed', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s4: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    s5: the subject's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; "other" is
        `not (same subject e)` on the approached vehicle e; the subject moving is its kin.speed above
        p.halt_speed_tolerance (applicability).
    s1/s10 (`eSel e`): e is a member of DEF-NRS-484A-020::authorized_emergency_vehicle, or an
        ru.official_vehicle whose kind is regulatory_agency; moving (kin.speed > p.halt_speed_tolerance)
        or preparing to move (rel.visible from the subject, and sig.hand_signal not no_signal or
        sig.turn_indicator not off); ahead (`rel_bearing subject e ahead`, the longitudinal component
        positive) and within the reach (`rel_centre_distance ≤ p.emergency_approach_reach`; "within"
        read inclusively).
    s3/s4: `sig_warning_lamp e red flashing`. The facing of the lamp ("visible from the front") is
        part of the record's selection, but Core's evaluator reads a warning lamp only by colour, or
        by colour and mode (Semantics.evalAtomE: `sig_warning_lamp` takes [x, colour] or
        [x, colour, mode]); no formula can read `facing`. This is reported in task_result.md; it is
        not declared as a narrowing because a trigger span is never narrowed.
    s6: some human_direction device of role police_officer governs (dev.governs) a travel_region
        the subject occupies (rel.occupies): then the rule does not apply.
    s7 (operationalization "If possible"): the duty binds for an e whose whole selection `eSel e`
        has held at every observation of the time window p.emergency_lane_change_window behind
        (`holdsFor .time`); a candidate lane C is a lane on (st.on_way) the same highway as the
        subject's lane Ls, with lane-direction dot product with Ls positive, and not adjacent to Le.
    s8: for every lane Le that e occupies and every lane Ls the subject occupies, Ls is not adjacent
        to Le or the move is excused. Adjacent (`adj`): Le is Ls's left or right neighbour
        (`st_lane_adjacency a left|right b`), or both lanes have ordinal one with opposed directions
        (dot product negative) while some roadway is occupied by both the subject and e. "Ordinal one"
        is written `ordinal × ordinal = ordinal`: lane ordinals are counted from 1 (st.lane_adjacency
        contract), so this holds exactly at ordinal 1, and the rule carries no literal the node does
        not declare.
    s9 (operationalization): excused where env.ice_or_snow; or env.visibility below the subject's
        kin.speed × p.emergency_lane_change_window; or no candidate lane is open and clear. Open: no
        temporary_traffic_control device governs C. Clear: every road user u other than the subject
        occupying C has rel.surface_gap to the subject not below kin.speed(subject) × headway, the
        headway p.following_headway_ice under ice or snow, else p.following_headway_wet under a wet
        road or precipitation, else p.following_headway_dry (`Term.cond`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_2e

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEmergencyApproachReach : Term := .param "p.emergency_approach_reach"
def pEmergencyLaneChangeWindow : Term := .param "p.emergency_lane_change_window"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

def aevId : String := "DEF-NRS-484A-020::authorized_emergency_vehicle"
def vehicleId : String := "DEF-NRS-484A-320::vehicle"

def speedOf (x : String) : Term := .measure "kin_speed" [.var x]
def moving (x : String) : Formula := .cmp (speedOf x) .gt pHaltSpeedTolerance
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- Component `k` of a lane's designated direction. -/
def dirC (r k : String) : Term := .measure "st_lane_direction" [.var r, .lit k]
/-- Dot product of two lanes' designated directions. -/
def dirDot (a b : String) : Term := .add (.mul (dirC a "x") (dirC b "x")) (.mul (dirC a "y") (dirC b "y"))
/-- The lane's ordinal from the left (st.lane_adjacency ordinal). -/
def ordinal (r : String) : Term := .measure "st_lane_adjacency" [.var r, .lit "ordinal"]
/-- Ordinal one: ordinals count from 1, so `n · n = n` holds exactly at n = 1. -/
def ordinalOne (r : String) : Formula := .cmp (.mul (ordinal r) (ordinal r)) .eq (ordinal r)

/-- s1, s3/s4, s10: the selection of the approached vehicle `e`. -/
def eSel (e : String) : Formula :=
  .and (.not (.same vSubject (.var e)))
  (.and (.or (.atom "ru_aggregate" [.var e, .lit aevId] [])
             (.and (.atom "ru_official_vehicle" [.var e] [])
                   (.atom "ru_official_vehicle_kind" [.var e, .lit "regulatory_agency"] [])))
  (.and (.atom "sig_warning_lamp" [.var e, .lit "red", .lit "flashing"] [])
  (.and (.or (moving e)
             (.and (.atom "rel_visible" [vSubject, .var e] [])
                   (.or (.not (.atom "sig_hand_signal" [.var e, .lit "no_signal"] []))
                        (.not (.atom "sig_turn_indicator" [.var e, .lit "off"] [])))))
  (.and (.atom "rel_bearing" [vSubject, .var e, .lit "ahead"] [])
        (.cmp (.measure "rel_centre_distance" [vSubject, .var e]) .le pEmergencyApproachReach)))))

/-- s6: a law enforcement officer directs traffic in a travel region the subject occupies. -/
def officerDirects : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
          (.existsRegion (.lit "travel_region") "tr"
            (.and (occ "subject" "tr") (.atom "dev_governs" [.var "d", .var "tr"] []))))

/-- s8: lane `a` is adjacent to lane `b` (the vehicle `e`'s lane); `rw` names the roadway variable. -/
def adj (a b e rw : String) : Formula :=
  .or (.atom "st_lane_adjacency" [.var a, .lit "left", .var b] [])
  (.or (.atom "st_lane_adjacency" [.var a, .lit "right", .var b] [])
       (.and (ordinalOne a)
       (.and (ordinalOne b)
       (.and (.cmp (dirDot a b) .lt zeroRatio)
             (.existsRegion (.lit "roadway") rw (.and (occ "subject" rw) (occ e rw)))))))

/-- s9: the following headway for the surface. -/
def headway : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingHeadwayIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])) pFollowingHeadwayWet
      pFollowingHeadwayDry)

/-- s9: candidate lane `c` is open (no temporary traffic control governs it) and clear (no other
    road user occupying it is nearer the subject than its speed times the headway). -/
def openClear (c : String) : Formula :=
  .and (.forallDevice (.lit "temporary_traffic_control") "k"
          (.not (.atom "dev_governs" [.var "k", .var c] [])))
       (.forallUser "u"
          (.implies (.and (.not (.same (.var "u") vSubject)) (occ "u" c))
                    (.cmp (.measure "rel_surface_gap" [vSubject, .var "u"]) .ge
                          (.mul (speedOf "subject") headway))))

/-- s7: a candidate lane: on the same highway as `ls`, pointing the subject's way, not adjacent to `le`. -/
def candidate (c ls le e : String) : Formula :=
  .and (.existsRegion (.lit "highway") "w"
          (.and (.atom "st_on_way" [.var ls, .var "w"] []) (.atom "st_on_way" [.var c, .var "w"] [])))
  (.and (.cmp (dirDot c ls) .gt zeroRatio)
        (.not (adj c le e "rwc")))

/-- s9 (and s7): the move is excused. -/
def excused (ls le e : String) : Formula :=
  .or (.atom "env_ice_or_snow" [] [])
  (.or (.cmp (.measure "env_visibility" []) .lt (.mul (speedOf "subject") pEmergencyLaneChangeWindow))
       (.not (.existsRegion (.lit "lane") "c" (.and (candidate "c" ls le e) (openClear "c")))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit vehicleId] []

/-- Applicability: s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,; s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,; s3 (trigger): and making use of flashing lights meeting the requirements of; s6 (exception): except when otherwise directed by a law enforcement officer: -/
def applicability : Formula :=
  .and (moving "subject")
  (.and (.existsUser "e" (eSel "e"))
        (.not officerDirects))

/-- Obligation: s7 (standard): If possible,; s8 (obligation): drive in a lane that is not adjacent to the lane in which the authorized emergency vehicle or official vehicle of a regulatory agency is moving,; s9 (standard): unless roadway, traffic, weather or other conditions make doing so unsafe or impossible. -/
def obligation : Formula :=
  .forallUser "e"
    (.implies (.holdsFor .time pEmergencyLaneChangeWindow "subject" (eSel "e"))
      (.forallRegion (.lit "lane") "le"
        (.implies (occ "e" "le")
          (.forallRegion (.lit "lane") "ls"
            (.implies (occ "subject" "ls")
              (.or (.not (adj "ls" "le" "e" "rws")) (excused "ls" "le" "e")))))))

def rule : Rule :=
  { id := "NRS_484B_267_2e"
    laws := ["NRS-484B-267-2e"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "If possible"
          concepts := ["rel.occupies", "st.highway", "st.lane", "st.lane_adjacency", "st.lane_direction", "st.on_way"]
          params := ["p.emergency_lane_change_window"]
          convention := "lane-change time: moving away from the vehicle's lane is possible once the approach has lasted the time a driver needs to perceive the vehicle and change one lane, and only where the subject's way carries a candidate lane: a lane on the same highway as the subject's lane (st.on_way) whose designated direction points the subject's way (st.lane_direction, positive dot product with the subject's lane direction) and that is not adjacent to the vehicle's lane"
          surrogate := false }
      , { standard := "unless roadway, traffic, weather or other conditions make doing so unsafe or impossible"
          concepts := ["dev.governs", "dev.temporary_traffic_control", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.occupies", "rel.surface_gap"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice", "p.emergency_lane_change_window"]
          convention := "gap acceptance and lane availability: a candidate lane is impossible (roadway) where a temporary traffic control device governs it, and unsafe (traffic) where a road user occupying it, other than the subject (any road user using the highway: 'pedestrians, ridden or herded animals, vehicles and other conveyances', DEF-NRS-484A-285, read without exclusion), is nearer the subject's body (rel.surface_gap) than the subject's speed times the following headway for the surface (ice or snow, else wet road or precipitation, else dry); weather makes the move unsafe where the road is icy or snow-covered, or the visibility (env.visibility) is shorter than the distance the subject travels at its speed in the lane-change time"
          surrogate := false } ]
    residues := ["'including, without limitation' lists examples of a vehicle moving or preparing to move; the duty is the same whether or not the vehicle is arriving at or leaving the scene of a crash or other incident"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_2e

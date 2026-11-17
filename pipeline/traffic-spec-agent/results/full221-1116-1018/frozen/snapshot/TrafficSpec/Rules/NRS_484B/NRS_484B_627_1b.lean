/-
  NRS_484B_627_1b — NRS-484B-627-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (subject): If any driver or operator of a motor vehicle
    u2 (trigger): drives or operates a motor vehicle
    u3 (standard): at a speed so slow as to impede the forward movement of
    u4 (trigger): traffic proceeding immediately behind the driver or operator,
    u5 (subject): the driver or operator shall:
    v6 (condition): If the highway has two or more clearly marked lanes for traffic traveling in the direction in which the driver or operator is traveling,
    v7 (obligation): drive in the extreme right-hand lane
    v8 (standard): except when necessary
    v9 (exception): to pass other slowly moving vehicles.

  Elements (span → atoms, derived):
    u1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    u2: atoms ['kin.speed', 'ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    u4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.ahead_behind_in_lane', 'rel.surface_gap'], derived []
    u5: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    v6: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.lane', 'st.lane_adjacency', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    v7: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    v9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed', 'rel.bearing', 'rel.longitudinal_overlap', 'rel.surface_gap'], derived []

  Literals the text states (each written through its Units constructor):
    v6: 2 count — two

  How each span is written:
    u1/u5  binder class: `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    u2+u3+u4 (applicability, `impeding`): at every observation of the window of
           p.left_lane_move_over_time behind (`holdsFor .time`): the subject's kin.speed is above
           p.halt_speed_tolerance; some speed_limit_sign device of kind `maximum` governs a
           travel_region the subject occupies and the subject's speed plus
           p.impeding_speed_margin is below its value; some road user t of
           DEF-NRS-484A-285::traffic has the subject ahead of it in the same lane
           (`rel_ahead_behind_in_lane subject t`) at a surface gap (distance) at or below
           p.rear_signal_reach; and no road user o is ahead of the subject in the same lane
           (`rel_ahead_behind_in_lane o subject`) within p.rear_signal_reach.
    v6     (applicability, at the judged observation): the subject occupies a lane l lying on a
           highway w (`st_on_way l w`) whose count of lanes in l's direction
           (`st_lane_adjacency_count`) is at least the stated two. 'traffic' of v6 is the same
           aggregate already read in u4.
    v7     (obligation): the subject occupies a lane l of the applicability's whole selection
           (occupied, on a highway, count ≥ 2) whose ordinal equals its count, and every lane the
           subject occupies has its ordinal equal to its count (no other lane of that direction).
    v8+v9  (obligation, alternative): some road user v of DEF-NRS-484A-320::vehicle moving above
           p.halt_speed_tolerance, slower than the subject (which excludes the subject itself), on
           the subject's right (`rel_bearing … "right"`, lateral component negative), and either
           side by side (`rel_longitudinal_overlap` ≥ 0) or ahead (`rel_bearing … "ahead"`) at a
           surface gap at or below (subject speed − v's speed) × p.overtake_window.

  Choices the record left open: none beyond the above; no narrowing declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_627_1b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pImpedingSpeedMargin : Term := .param "p.impeding_speed_margin"
def pLeftLaneMoveOverTime : Term := .param "p.left_lane_move_over_time"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pRearSignalReach : Term := .param "p.rear_signal_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- v6: the stated "two" lanes. -/
def twoLanes : Term := .lit (Units.ratio 2 1) .count

def aggMotorVehicle : Arg := .lit "DEF-NRS-484A-130::motor_vehicle"
def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

def speedOf (x : String) : Term := .measure "kin_speed" [.var x]
def gapOf (a b : String) : Term := .measure "rel_surface_gap" [.var a, .var b]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggMotorVehicle] []

/-- u2: the subject moves. -/
def moving : Formula := .cmp (speedOf "subject") .gt pHaltSpeedTolerance

/-- u3: its speed plus the margin is below the value of a maximum speed limit sign governing a
    travel region it occupies. -/
def slowUnderMaximum : Formula :=
  .existsDevice (.lit "speed_limit_sign") "d"
    (.and (.atom "dev_speed_limit_sign_kind" [.var "d", .lit "maximum"] [])
      (.and
        (.existsRegion (.lit "travel_region") "tr"
          (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
                (.atom "dev_governs" [.var "d", .var "tr"] [])))
        (.cmp (.add (speedOf "subject") pImpedingSpeedMargin) .lt
              (.measure "dev_speed_limit_sign_value" [.var "d"]))))

/-- u4: a traffic road user proceeding immediately behind the subject in its lane. -/
def trafficBehind : Formula :=
  .existsUser "t"
    (.and (.atom "ru_aggregate" [.var "t", aggTraffic] [])
      (.and (.atom "rel_ahead_behind_in_lane" [vSubject, .var "t"] [])
            (.cmp (gapOf "subject" "t") .le pRearSignalReach)))

/-- u3: no road user ahead of the subject in its lane within the reach. -/
def noneAhead : Formula :=
  .not (.existsUser "o"
    (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
          (.cmp (gapOf "subject" "o") .le pRearSignalReach)))

/-- u2+u3+u4, sustained over the move-over time. -/
def impeding : Formula :=
  .holdsFor .time pLeftLaneMoveOverTime "subject"
    (.and moving (.and slowUnderMaximum (.and trafficBehind noneAhead)))

/-- v6: lane `l` the subject occupies lies on a highway with two or more lanes in its direction. -/
def multiLaneSelection (l : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var l] [])
    (.and (.existsRegion (.lit "highway") "w" (.atom "st_on_way" [.var l, .var "w"] []))
          (.cmp (.measure "st_lane_adjacency_count" [.var l]) .ge twoLanes))

def multiLaneHighway : Formula :=
  .existsRegion (.lit "lane") "l" (multiLaneSelection "l")

/-- Applicability: u2 (trigger): drives or operates a motor vehicle; u4 (trigger): traffic proceeding immediately behind the driver or operator,; v6 (condition): If the highway has two or more clearly marked lanes for traffic traveling in the direction in which the driver or operator is traveling,; v9 (exception): to pass other slowly moving vehicles. -/
def applicability : Formula := .and impeding multiLaneHighway

def rightmost (l : String) : Formula :=
  .cmp (.measure "st_lane_adjacency_ordinal" [.var l]) .eq (.measure "st_lane_adjacency_count" [.var l])

/-- v7: in the extreme right-hand lane and in no other lane of that direction. -/
def inRightLane : Formula :=
  .and (.existsRegion (.lit "lane") "l" (.and (multiLaneSelection "l") (rightmost "l")))
       (.forallRegion (.lit "lane") "l2"
          (.implies (.atom "rel_occupies" [vSubject, .var "l2"] []) (rightmost "l2")))

/-- v8+v9: passing another slower moving vehicle on the right. -/
def passingSlower : Formula :=
  .existsUser "v"
    (.and (.atom "ru_aggregate" [.var "v", aggVehicle] [])
      (.and (.cmp (speedOf "v") .gt pHaltSpeedTolerance)
        (.and (.cmp (speedOf "v") .lt (speedOf "subject"))
          (.and (.atom "rel_bearing" [vSubject, .var "v", .lit "right"] [])
            (.or (.cmp (.measure "rel_longitudinal_overlap" [vSubject, .var "v"]) .ge zeroMetres)
                 (.and (.atom "rel_bearing" [vSubject, .var "v", .lit "ahead"] [])
                       (.cmp (gapOf "subject" "v") .le
                             (.mul (.sub (speedOf "subject") (speedOf "v")) pOvertakeWindow))))))))

/-- Obligation: u3 (standard): at a speed so slow as to impede the forward movement of; v7 (obligation): drive in the extreme right-hand lane; v8 (standard): except when necessary -/
def obligation : Formula := .or inRightLane passingSlower

def rule : Rule :=
  { id := "NRS_484B_627_1b"
    laws := ["NRS-484B-627-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "so slow as to impede the forward movement of traffic"
          concepts := ["dev.governs", "dev.speed_limit_sign", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.travel_region"]
          params := ["p.impeding_speed_margin", "p.rear_signal_reach", "p.left_lane_move_over_time", "p.halt_speed_tolerance"]
          convention := "Slow-moving-vehicle practice: the subject impedes the traffic behind it where, at every observation of the window of p.left_lane_move_over_time behind (the time a driver needs to check, signal and move over once a faster vehicle closes), it moves (speed above p.halt_speed_tolerance) at a speed more than p.impeding_speed_margin below the value of a maximum speed limit sign governing a travel region it occupies, a traffic road user is behind it in the same lane within p.rear_signal_reach, and no road user is ahead of it in the same lane within p.rear_signal_reach."
          surrogate := false }
      , { standard := "necessary to pass"
          concepts := ["kin.speed", "rel.bearing", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.overtake_window", "p.halt_speed_tolerance"]
          convention := "Overtaking duration: passing a slower vehicle is necessary while the subject is side by side with it, or while it is ahead at a body gap the subject closes within p.overtake_window at their speed difference (gap at or below the speed difference times p.overtake_window); the bound moves with the closing speed."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_627_1b

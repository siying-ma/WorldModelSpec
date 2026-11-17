/-
  NRS_484B_267_1b_o1 — NRS-484B-267-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (standard): Upon the immediate approach of
    u2 (condition): an authorized emergency vehicle
    u3 (condition): or an official vehicle of a regulatory agency,
    u4 (condition): making use of flashing lights meeting the requirements of
    u5 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    u6 (subject): the driver of every other vehicle shall,
    u7 (exception): except when otherwise directed by a law enforcement officer:
    b1 (exception): Except as otherwise provided in this paragraph,
    b2 (standard): immediately
    b3 (obligation): drive to a position parallel to, and
    b4 (standard): as close as possible to, the right-hand edge or, if applicable, curb of a highway
    b5 (condition): and clear of any intersection.
    b6 (sibling): The driver shall not drive to and stop in a position on a paved shoulder of a highway
    b7 (sibling): where lawfully placed signage allows a vehicle described in paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210 [list appended below] to drive on the shoulder.
    b8 (sibling): The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to: (a) An authorized emergency vehicle described in NRS 484A.480; (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490; (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle; or (f) A public transit motor bus, that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.

  Elements (span → atoms, derived):
    u2: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    u3: atoms ['ru.official_vehicle'], derived []
    u4: atoms ['sig.warning_lamp'], derived [], borrowing ['u5']
    u6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u7: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    b1: atoms ['st.shoulder', 'rel.occupies', 'dev.regulatory_sign', 'dev.governs'], derived []
    b3: atoms ['kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region'], derived []
    b5: atoms ['rel.occupies', 'st.intersection'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    u5: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each is written:
    u6  the subject's class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    u2/u3  the approaching road user e (any road user other than the subject, `same`): the
        authorized-emergency-vehicle aggregate, or `ru_official_vehicle` with
        `ru_official_vehicle_kind regulatory_agency`.
    u4/u5  `sig_warning_lamp e red flashing`. The formula accessor of sig.warning_lamp takes a colour
        and a mode only; the facing (front) the record names is not selectable through it, so the
        atom reads a red flashing lamp in any facing (reported in task_result.md).
    u1  e moves (`kin_speed e > p.halt_speed_tolerance`), the subject is ahead of it in e's frame
        (`rel_bearing e subject ahead`), within `rel_centre_distance ≤ p.emergency_immediate_approach_reach`.
        The applicability is the rising edge of that trigger for some e (`rises` inside `existsUser`).
    u7  no `human_direction` device of role police_officer governs a travel region the subject occupies.
    b2  for every e whose trigger rises: `within .time p.emergency_pullover_window` either e has passed
        the subject (`rel_bearing e subject behind` and `rel_longitudinal_overlap e subject < 0`) or the
        subject is at the position.
    b3  (a) some travel region the subject occupies whose designated direction's dot product with the
        subject's heading has absolute value ≥ p.curb_parallel_cos.
    b4  (b) some highway h on which a travel region the subject occupies lies, and either a road_edge g
        on h with `st_region_geometry_distance subject g ≤ p.pullover_edge_gap` and
        `prim_region_lateral_offset subject g ≤ 0`, or an occupied paved shoulder on h.
    b5  (c) no intersection the subject occupies.
    b1  (d) no occupied paved shoulder governed by a regulatory sign of code shoulder_use_permitted.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_1b_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vE : Arg := .var "e"
def vT : Arg := .var "t"
def vT2 : Arg := .var "t2"
def vH : Arg := .var "h"
def vG : Arg := .var "g"
def vS : Arg := .var "s"
def vI : Arg := .var "i"
def vD : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurbParallelCos : Term := .param "p.curb_parallel_cos"
def pEmergencyImmediateApproachReach : Term := .param "p.emergency_immediate_approach_reach"
def pEmergencyPulloverWindow : Term := .param "p.emergency_pullover_window"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPulloverEdgeGap : Term := .param "p.pullover_edge_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- u2/u3: e is an authorized emergency vehicle or an official vehicle of a regulatory agency. -/
def approachingClass : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- u4/u5: a lit red flashing warning lamp. -/
def flashingRed : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- u1: e moves with the subject ahead of it, within the immediate-approach reach. -/
def immediateApproach : Formula :=
  .and (.cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance)
    (.and (.atom "rel_bearing" [vE, vSubject, .lit "ahead"] [])
          (.cmp (.measure "rel_centre_distance" [vE, vSubject]) .le pEmergencyImmediateApproachReach))

/-- The trigger for one road user e other than the subject. -/
def trigger : Formula :=
  .and (.not (.same vE vSubject))
    (.and approachingClass (.and flashingRed immediateApproach))

/-- u7: a police officer directing traffic governs a travel region the subject occupies. -/
def directedByOfficer : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
          (.existsRegion (.lit "travel_region") "t"
            (.and (.atom "dev_governs" [vD, vT] []) (.atom "rel_occupies" [vSubject, vT] []))))

/-- Applicability: u2 (condition): an authorized emergency vehicle; u3 (condition): or an official vehicle of a regulatory agency,; u4 (condition): making use of flashing lights meeting the requirements of; u7 (exception): except when otherwise directed by a law enforcement officer:; b1 (exception): Except as otherwise provided in this paragraph,; b5 (condition): and clear of any intersection. -/
def applicability : Formula :=
  .and (.existsUser "e" (.rises trigger)) (.not directedByOfficer)

/-- b2: e has passed the subject. -/
def passed : Formula :=
  .and (.atom "rel_bearing" [vE, vSubject, .lit "behind"] [])
       (.cmp (.measure "rel_longitudinal_overlap" [vE, vSubject]) .lt zeroMetres)

/-- b3 (a): parallel, in either sense, to the designated direction of an occupied travel region. -/
def parallel : Formula :=
  .existsRegion (.lit "travel_region") "t"
    (.and (.atom "rel_occupies" [vSubject, vT] [])
          (.cmp (.abs (.add (.mul (.measure "kin_heading" [vSubject, .lit "x"])
                                  (.measure "st_lane_direction" [vT, .lit "x"]))
                            (.mul (.measure "kin_heading" [vSubject, .lit "y"])
                                  (.measure "st_lane_direction" [vT, .lit "y"]))))
                .ge pCurbParallelCos))

/-- b4 (b): at the right-hand edge of a highway the subject is on, or on a paved shoulder of it. -/
def atRightEdge : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.existsRegion (.lit "travel_region") "t2"
            (.and (.atom "rel_occupies" [vSubject, vT2] []) (.atom "st_on_way" [vT2, vH] [])))
          (.or (.existsRegion (.lit "road_edge") "g"
                 (.and (.atom "st_on_way" [vG, vH] [])
                   (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, vG]) .le pPulloverEdgeGap)
                         (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vG] []) .le zeroMetres))))
               (.existsRegion (.lit "shoulder") "s"
                 (.and (.atom "rel_occupies" [vSubject, vS] [])
                   (.and (.atom "st_shoulder_paved" [vS] []) (.atom "st_on_way" [vS, vH] []))))))

/-- b5 (c): clear of any intersection. -/
def clearOfIntersection : Formula :=
  .not (.existsRegion (.lit "intersection") "i" (.atom "rel_occupies" [vSubject, vI] []))

/-- b1 (d): not on a paved shoulder whose use signage permits. -/
def offSignedShoulder : Formula :=
  .not (.existsRegion (.lit "shoulder") "s"
    (.and (.atom "rel_occupies" [vSubject, vS] [])
      (.and (.atom "st_shoulder_paved" [vS] [])
            (.existsDevice (.lit "regulatory_sign") "d"
              (.and (.atom "dev_regulatory_sign_code" [vD, .lit "shoulder_use_permitted"] [])
                    (.atom "dev_governs" [vD, vS] []))))))

/-- The position b3–b5 and b1 require. -/
def atPosition : Formula :=
  .and parallel (.and atRightEdge (.and clearOfIntersection offSignedShoulder))

/-- Obligation: u1 (standard): Upon the immediate approach of; b2 (standard): immediately; b3 (obligation): drive to a position parallel to, and; b4 (standard): as close as possible to, the right-hand edge or, if applicable, curb of a highway -/
def obligation : Formula :=
  .forallUser "e"
    (.implies (.rises trigger)
      (.within .time pEmergencyPulloverWindow "subject" (.or passed atPosition)))

def rule : Rule :=
  { id := "NRS_484B_267_1b_o1"
    laws := ["NRS-484B-267-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the immediate approach of the emergency or regulatory vehicle"
          concepts := ["kin.speed", "rel.bearing", "rel.centre_distance"]
          params := ["p.halt_speed_tolerance", "p.emergency_immediate_approach_reach"]
          convention := "the vehicle moves with the subject ahead of it in its own frame, within the centre distance a vehicle at an urban response speed covers in the time a driver needs to perceive its lamps and begin clearing the way"
          surrogate := false }
      , { standard := "immediately"
          concepts := ["kin.time", "rel.bearing", "rel.longitudinal_overlap"]
          params := ["p.emergency_pullover_window"]
          convention := "the position is reached within a perception-reaction time plus the lane changes a pull-over takes, counted from the onset of the immediate approach; the duty to clear the way ends once the approaching vehicle has passed the subject (the subject behind it in its frame, their projections sharing no length)"
          surrogate := false }
      , { standard := "as close as possible to the right-hand edge or curb of a highway"
          concepts := ["prim.region_lateral_offset", "rel.occupies", "st.highway", "st.on_way", "st.region_geometry", "st.road_edge", "st.shoulder"]
          params := ["p.pullover_edge_gap"]
          convention := "curb-parking clearance: a vehicle pulled over to the edge stands with its body within the curb clearance of a parked car plus lane-keeping variability of the right-hand curb or roadway edge, or on an unsigned paved shoulder beyond it"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_1b_o1

/-
  NRS_484B_267_1c — NRS-484B-267-1c

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
    c1 (obligation): Stop and remain in such position until the authorized emergency vehicle or official vehicle has passed.

  Elements (span → atoms, derived):
    u2: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    u3: atoms ['ru.official_vehicle'], derived []
    u4: atoms ['sig.warning_lamp'], derived [], borrowing ['u5']
    u6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u7: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    c1: atoms ['kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region', 'st.road_edge', 'st.region_geometry', 'prim.region_lateral_offset', 'st.highway', 'st.on_way', 'st.shoulder', 'st.intersection', 'dev.regulatory_sign', 'dev.governs', 'rel.bearing', 'rel.longitudinal_overlap'], derived ['drv.motion.complete_halt']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    u5: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    u6 (class): ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    u2/u3: for a road user e (not the subject): ru_aggregate(e, DEF-NRS-484A-020::authorized_emergency_vehicle)
      or ru_official_vehicle_kind(e, regulatory_agency) (the attribute form of ru.official_vehicle).
    u4 (+u5): sig_warning_lamp(e, red, flashing). NOT CARRIED: "facing front" ('visible from the
      front'). The formula forms of sig_warning_lamp read colour and mode only, so the facing the
      record states cannot be written; declared as a no_atom narrowing on u4 (see `narrowings`).
    u1 (operationalization): kin_speed(e) > p.halt_speed_tolerance, rel_bearing(e, subject, ahead),
      rel_centre_distance(e, subject) <= p.emergency_immediate_approach_reach.
    Trigger: the conjunction above; applicability: some e other than the subject whose trigger
      rises here (true here, false at the previous observation).
    u7 (exception): no human_direction device with role police_officer governs (dev_governs) a
      travel region the subject occupies (rel_occupies).
    c1: for every e other than the subject whose trigger rises here,
      (not Passed(e)) U (AtPosition and (AtPosition U Passed(e))), strong until, where
      Passed(e) = rel_bearing(e, subject, behind) and rel_longitudinal_overlap(e, subject) < 0, and
      AtPosition = drv_motion_complete_halt(subject; p.halt_speed_tolerance)
        and |kin_heading . st_lane_direction| >= p.curb_parallel_cos for some occupied travel region
        and for some highway h on which an occupied travel region lies (st_on_way): a road_edge on h
          within st_region_geometry_distance <= p.pullover_edge_gap with prim_region_lateral_offset
          <= 0, or a paved (st_shoulder_paved) shoulder on h the subject occupies
        and no intersection occupied
        and no occupied paved shoulder governed by a regulatory sign coded shoulder_use_permitted.
      Kleene semantics: a vehicle that never passes leaves the until open at the trace end (unknown),
      as the record's narrowing states.

  Choices the record left open: none beyond the formula shape the record's obligation spells out.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_1c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurbParallelCos : Term := .param "p.curb_parallel_cos"
def pEmergencyImmediateApproachReach : Term := .param "p.emergency_immediate_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPulloverEdgeGap : Term := .param "p.pullover_edge_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Conjunction of a list (`.tt` for the empty list). -/
def conj : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (conj rest)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The approaching road user `e` (a quantifier variable). -/
def vE : Arg := .var "e"

/-- u2 / u3: an authorized emergency vehicle, or an official vehicle of kind regulatory_agency. -/
def emergencyOrRegulatory : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] [])

/-- u4 (+u5 borrowed): a lit warning lamp, red, flashing. -/
def flashingRedLamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- u1 operationalization: `e` moves (speed above the halt tolerance) with the subject ahead of it in
    its own frame, within the immediate-approach centre distance. -/
def immediateApproach : Formula :=
  conj
    [ .cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance
    , .atom "rel_bearing" [vE, vSubject, .lit "ahead"] []
    , .cmp (.measure "rel_centre_distance" [vE, vSubject]) .le pEmergencyImmediateApproachReach ]

/-- The trigger for `e`, at one observation. -/
def trigger : Formula := conj [emergencyOrRegulatory, flashingRedLamp, immediateApproach]

/-- `e` other than the subject, whose trigger rises here. -/
def triggerRises : Formula := .and (.not (.same vE vSubject)) (.rises trigger)

/-- u7: a police officer (human direction) governs a travel region the subject occupies. -/
def directedByOfficer : Formula :=
  .existsDevice (.lit "human_direction") "pd"
    (.and (.atom "dev_human_direction_role" [.var "pd", .lit "police_officer"] [])
      (.existsRegion (.lit "travel_region") "pr"
        (.and (.atom "rel_occupies" [vSubject, .var "pr"] [])
              (.atom "dev_governs" [.var "pd", .var "pr"] []))))

/-- Applicability: u2 (condition): an authorized emergency vehicle; u3 (condition): or an official vehicle of a regulatory agency,; u4 (condition): making use of flashing lights meeting the requirements of; u7 (exception): except when otherwise directed by a law enforcement officer: -/
def applicability : Formula :=
  .and (.existsUser "e" triggerRises) (.not directedByOfficer)

/-- 'has passed': the subject lies behind `e` in `e`'s frame and their projections on `e`'s heading
    share no length. -/
def passed : Formula :=
  .and (.atom "rel_bearing" [vE, vSubject, .lit "behind"] [])
       (.cmp (.measure "rel_longitudinal_overlap" [vE, vSubject]) .lt zeroMetres)

/-- Heading parallel to the designated direction of an occupied travel region. -/
def parallelToCarrier : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.cmp (.abs (.add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var "r", .lit "x"]))
                        (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var "r", .lit "y"]))))
        .ge pCurbParallelCos))

/-- At the right-hand edge of a highway it is on: a road edge lying on `h` within the edge gap of the
    body and on its right, or a paved shoulder lying on `h` that it occupies. -/
def atRightEdge : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and
      (.existsRegion (.lit "travel_region") "ro"
        (.and (.atom "rel_occupies" [vSubject, .var "ro"] []) (.atom "st_on_way" [.var "ro", .var "h"] [])))
      (.or
        (.existsRegion (.lit "road_edge") "g"
          (conj
            [ .atom "st_on_way" [.var "g", .var "h"] []
            , .cmp (.measure "st_region_geometry_distance" [vSubject, .var "g"]) .le pPulloverEdgeGap
            , .cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "g"] []) .le zeroMetres ]))
        (.existsRegion (.lit "shoulder") "s"
          (conj
            [ .atom "st_on_way" [.var "s", .var "h"] []
            , .atom "st_shoulder_paved" [.var "s"] []
            , .atom "rel_occupies" [vSubject, .var "s"] [] ]))))

/-- Clear of any intersection. -/
def clearOfIntersection : Formula :=
  .not (.existsRegion (.lit "intersection") "i" (.atom "rel_occupies" [vSubject, .var "i"] []))

/-- Off any paved shoulder a shoulder_use_permitted regulatory sign governs. -/
def offPermittedShoulder : Formula :=
  .not (.existsRegion (.lit "shoulder") "sp"
    (conj
      [ .atom "rel_occupies" [vSubject, .var "sp"] []
      , .atom "st_shoulder_paved" [.var "sp"] []
      , .existsDevice (.lit "regulatory_sign") "dv"
          (.and (.atom "dev_regulatory_sign_code" [.var "dv", .lit "shoulder_use_permitted"] [])
                (.atom "dev_governs" [.var "dv", .var "sp"] [])) ]))

/-- 'Stop … in such position': at rest, parallel, at the right-hand edge, clear of intersections, off a
    shoulder signed for use. -/
def atPosition : Formula :=
  conj
    [ .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]
    , parallelToCarrier
    , atRightEdge
    , clearOfIntersection
    , offPermittedShoulder ]

/-- Obligation: u1 (standard): Upon the immediate approach of; c1 (obligation): Stop and remain in such position until the authorized emergency vehicle or official vehicle has passed. -/
def obligation : Formula :=
  .forallUser "e"
    (.implies triggerRises
      (.until (.not passed) (.and atPosition (.until atPosition passed))))

def rule : Rule :=
  { id := "NRS_484B_267_1c"
    laws := ["NRS-484B-267-1c"]
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
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "u4"
          why := "the record reads u4 (with the borrowed u5 words 'at least one flashing red warning lamp visible from the front') as sig.warning_lamp of colour red, mode flashing, facing front; the formula forms of sig_warning_lamp read only [track, colour] or [track, colour, mode] (Semantics.evalAtomE), so no atom of the surface carries 'facing front' / 'visible from the front'; the rule as written requires only a lit red flashing lamp of any facing, which is weaker than the condition the record states"
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_1c

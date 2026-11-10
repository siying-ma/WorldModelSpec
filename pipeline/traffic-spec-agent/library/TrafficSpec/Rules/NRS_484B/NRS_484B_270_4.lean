/-
  NRS_484B_270_4 — NRS-484B-270-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (reference): Except as otherwise provided in subsection 3 [NRS-484B-270-3],
    s2 (subject): the driver of a motor vehicle
    s3 (obligation): shall not enter or proceed through an intersection
    s4 (condition): while driving within a pathway or lane provided for bicycles, electric bicycles or electric scooters.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.intersection'], derived []
    s4: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived ['drv.motion.moving']

  Compositions (span → node, as, map):
    s1: NRS_484B_270_3_o2 as condition map {'x': 'x'}

  How each is written:
    s2: x's class is `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
    s4: `drv_motion_moving x p.motion_speed_tolerance` and, for some region b of kind
        bicycle_lane_or_path, `rel_occupies x b`, at the judged observation.
    s1: `ruleApplies NRS_484B_270_3_o2 {x ↦ x}` conjoined into the applicability (as condition).
    s3: for no region i of kind intersection does `rel_occupies x i` rise at the judged
        observation (the record's own narrowing: entry, where every passage begins).
  No choice beyond the record's was made; no narrowing of this session's.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_4

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s4: x in motion with its footprint on a bicycle lane or path. -/
def drivingInBicycleLane : Formula :=
  .and (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
    (.existsRegion (.lit "bicycle_lane_or_path") "b" (.atom "rel_occupies" [vX, .var "b"] []))

/-- s1: subsection 3's rule applies to x (none of its exceptions excuses x's presence in the lane). -/
def subsection3Applies : Formula := .ruleApplies "NRS_484B_270_3_o2" [("x", "x")]

/-- Applicability: s4 (condition), with s1's composition as a condition. -/
def applicability : Formula := .and drivingInBicycleLane subsection3Applies

/-- Obligation: s3 (obligation): x's footprint does not begin to overlap any intersection here. -/
def obligation : Formula :=
  .not (.existsRegion (.lit "intersection") "i" (.rises (.atom "rel_occupies" [vX, .var "i"] [])))

def rule : Rule :=
  { id := "NRS_484B_270_4"
    laws := ["NRS-484B-270-4"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_4

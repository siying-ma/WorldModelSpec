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
    s2: the binder class, `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
    s4: `drv_motion_moving x p.motion_speed_tolerance` and some region b of kind
        bicycle_lane_or_path with `rel_occupies x b`, at the judged observation.
    s1: `ruleApplies NRS_484B_270_3_o2 {x ↦ x}` conjoined into the applicability.
    s3: for no region i of kind intersection does `rel_occupies x i` rise at the judged observation
        (`rises`: true here, false at the observation before), as the record states the entry.
  No choice beyond the record's own narrowings was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_4

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x` (s2): ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s4: x is moving with its footprint on some bicycle lane or path. -/
def inBicycleLane : Formula :=
  .and (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
    (.existsRegion (.lit "bicycle_lane_or_path") "b" (.atom "rel_occupies" [vX, .var "b"] []))

/-- Applicability: s4 (condition) while driving within a bicycle lane or path, and s1 (condition):
    NRS_484B_270_3_o2 applies to x, so none of subsection 3's exceptions excuses x's presence. -/
def applicability : Formula :=
  .and inBicycleLane (.ruleApplies "NRS_484B_270_3_o2" [("x", "x")])

/-- Obligation: s3 (obligation): x's footprint does not begin to overlap an intersection here
    (overlapping it now and not at the observation before). -/
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

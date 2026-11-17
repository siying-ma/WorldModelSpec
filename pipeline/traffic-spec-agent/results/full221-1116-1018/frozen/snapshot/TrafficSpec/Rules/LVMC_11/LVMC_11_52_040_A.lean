/-
  LVMC_11_52_040_A — LVMC-11-52-040-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except as otherwise provided in this Chapter:
    s2 (trigger): No person shall stand or park a vehicle
    s3 (condition): in a roadway
    s4 (obligation): other than parallel with the edge of the roadway headed in the direction of lawful traffic movement.

  Elements (span → atoms, derived):
    s1: atoms ['dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    s3: atoms ['rel.occupies', 'st.roadway'], derived []
    s4: atoms ['kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []

  How each span is written:
    s2: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; "stand or park"
        is `drv_motion_parked subject` with speed_tol p.halt_speed_tolerance and min_duration
        p.standing_min_duration, as the applicability states.
    s3: some region of kind `roadway` the subject occupies (`rel_occupies`).
    s1: the exception: no `regulatory_sign` device whose code is `angle_parking` governs
        (`dev_governs`) a `travel_region` the subject occupies (`rel_occupies`).
    s4: the subject, a member of the traffic whose lawful direction the carrier designates
        (`ru_aggregate subject "DEF-NRS-484A-285::traffic"`), has at every `travel_region` l it
        occupies a heading aligned with l's designated direction: the dot product of the normalised
        `kin_heading` and `st_lane_direction` (x·x + y·y) at least p.parked_heading_cos. Unknown where
        an occupied carrier's direction or the heading is unobserved.
        The record's "not an intersection" is not written: the node claims no `st.intersection`
        atom (reported in task_result.md); an occupied intersection, which carries no direction,
        leaves the duty unknown rather than vacuous.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_040_A

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkedHeadingCos : Term := .param "p.parked_heading_cos"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the vehicle stands or parks. -/
def standsOrParks : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]

/-- s3: in a roadway. -/
def inRoadway : Formula :=
  .existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, .var "rw"] [])

/-- s1: what the Chapter otherwise provides — a posted angle_parking sign governing a travel region
    the subject occupies. -/
def angleParkingPosted : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.existsRegion (.lit "travel_region") "tr"
      (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
        (.and (.atom "dev_governs" [.var "d", .var "tr"] [])
          (.atom "dev_regulatory_sign_code" [.var "d", .lit "angle_parking"] []))))

/-- Applicability: s1 (exception): Except as otherwise provided in this Chapter:; s2 (trigger): No person shall stand or park a vehicle; s3 (condition): in a roadway -/
def applicability : Formula :=
  .and standsOrParks (.and inRoadway (.not angleParkingPosted))

/-- s4: the heading aligned with the carrier's designated direction (dot product of the normalised vectors). -/
def headingAligned (l : String) : Formula :=
  .cmp
    (.add
      (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var l, .lit "x"]))
      (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var l, .lit "y"])))
    .ge pParkedHeadingCos

/-- Obligation: s4 (obligation): other than parallel with the edge of the roadway headed in the direction of lawful traffic movement. -/
def obligation : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.forallRegion (.lit "travel_region") "l"
      (.implies (.atom "rel_occupies" [vSubject, .var "l"] []) (headingAligned "l")))

def rule : Rule :=
  { id := "LVMC_11_52_040_A"
    laws := ["LVMC-11-52-040-A"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_52_040_A

/-
  NRS_484B_220_1 — NRS-484B-220-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): Upon a highway designated and signposted for one-way traffic
    s2 (subject): a vehicle
    s3 (obligation): shall be driven only in the direction designated.

  Elements (span → atoms, derived):
    s1: atoms ['rel.occupies', 'st.one_way_roadway', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms [], derived ['drv.motion.moving_against_carrier']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_220_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s2: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1: the subject is part of the traffic the designation restricts
        (`ru_aggregate subject "DEF-NRS-484A-285::traffic"`) and occupies some region of kind
        `one_way_roadway` (`rel_occupies subject r`); the one-way roadway's presence is the
        evidence of its designation and posting (the record's observable reading).
    s3: for every one-way roadway r the subject occupies (the whole selection of s1 repeated),
        `drv_motion_moving_against_carrier subject r` with speed_tol = p.halt_speed_tolerance does
        not hold. The record's own readings (agency of 'driven', the cross-motion reading of
        'only in the direction designated') are carried by the concept; no further choice was made.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject occupies a one-way roadway r. -/
def onOneWay (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Applicability: s1 (condition): Upon a highway designated and signposted for one-way traffic -/
def applicability : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.existsRegion (.lit "one_way_roadway") "r" (onOneWay "r"))

/-- Obligation: s3 (obligation): shall be driven only in the direction designated. -/
def obligation : Formula :=
  .forallRegion (.lit "one_way_roadway") "r"
    (.implies (onOneWay "r")
      (.not (.derived "drv_motion_moving_against_carrier" [vSubject, .var "r"] [pHaltSpeedTolerance])))

def rule : Rule :=
  { id := "NRS_484B_220_1"
    laws := ["NRS-484B-220-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_220_1

/-
  NRS_484B_220_2 — NRS-484B-220-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (trigger): passing around a rotary traffic island
    s3 (obligation): shall be driven only to the right of such island.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.roundabout'], derived []
    s3: atoms [], derived ['drv.motion.circulating_clockwise_about']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_220_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRoundaboutClockwiseSinTol : Term := .param "p.roundabout_clockwise_sin_tol"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s2: some region of kind `roundabout` (st.roundabout) that the subject occupies (rel_occupies).
    s3: at every roundabout the subject occupies — the applicability's whole selection repeated,
        since the node's obligation states the duty for every such roundabout — the subject is not
        circulating clockwise about it: `¬ drv_motion_circulating_clockwise_about(subject, r)` with
        speed_tol = p.halt_speed_tolerance, sin_tol = p.roundabout_clockwise_sin_tol.
  No choice beyond the record's own narrowings was needed; `narrowings` is empty.
-/

/-- The roundabout region `r` the subject occupies (s2). -/
def occupiesRoundabout (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): passing around a rotary traffic island -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" (occupiesRoundabout "r")

/-- Obligation: s3 (obligation): shall be driven only to the right of such island. -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies (occupiesRoundabout "r")
      (.not (.derived "drv_motion_circulating_clockwise_about" [vSubject, .var "r"]
        [pHaltSpeedTolerance, pRoundaboutClockwiseSinTol])))

def rule : Rule :=
  { id := "NRS_484B_220_2"
    laws := ["NRS-484B-220-2"]
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

end TrafficSpec.Rules.NRS_484B_220_2

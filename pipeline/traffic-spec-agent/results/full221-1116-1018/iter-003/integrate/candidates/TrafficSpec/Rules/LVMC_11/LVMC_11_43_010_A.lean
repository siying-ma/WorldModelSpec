/-
  LVMC_11_43_010_A — LVMC-11-43-010-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (boilerplate): The following regulations pertain to
    a2 (subject): the operation of vehicles
    a3 (trigger): within a roundabout
    a4 (subject): All vehicular travel
    a5 (obligation): shall be in a counterclockwise direction

  Elements (span → atoms, derived):
    a2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a3: atoms ['rel.occupies', 'st.roundabout'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    a5: atoms [], derived ['drv.motion.circulating_clockwise_about']

  How each is written:
    a2/a4 class: ru_aggregate(subject, "DEF-NRS-484A-320::vehicle").
    a3: existsRegion roundabout r, rel_occupies(subject, r).
    a4 'travel': not drv_motion_complete_halt(subject; p.halt_speed_tolerance).
    a5: forallRegion roundabout r, rel_occupies(subject, r) → not
        drv_motion_circulating_clockwise_about(subject, r; p.halt_speed_tolerance,
        p.roundabout_clockwise_sin_tol) — the applicability's roundabout selection written again,
        the duty at every roundabout occupied, as the record states.
  No choice beyond the record's own narrowings was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_A

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRoundaboutClockwiseSinTol : Term := .param "p.roundabout_clockwise_sin_tol"

def zeroMetres : Term := .lit Q.zero .metre

/-- a2/a4: the subject is a member of DEF-NRS-484A-320::vehicle (ru.aggregate). -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- a3: the subject's footprint occupies the roundabout region `r` (rel.occupies, st.roundabout
    by the quantifier's kind). -/
def inRoundabout (r : String) : Formula :=
  .atom "rel_occupies" [vSubject, .var r] []

/-- a4 'travel': the subject is not at rest (not drv.motion.complete_halt). -/
def travelling : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Applicability: a3 (trigger) within some roundabout, and a4 travel. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "roundabout") "r" (inRoundabout "r")) travelling

/-- Obligation: a5 — at every roundabout region the subject occupies (the applicability's
    selection written again), the subject does not circulate clockwise about its reference point. -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies (inRoundabout "r")
      (.not (.derived "drv_motion_circulating_clockwise_about" [vSubject, .var "r"]
        [pHaltSpeedTolerance, pRoundaboutClockwiseSinTol])))

def rule : Rule :=
  { id := "LVMC_11_43_010_A"
    laws := ["LVMC-11-43-010-A"]
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

end TrafficSpec.Rules.LVMC_11_43_010_A

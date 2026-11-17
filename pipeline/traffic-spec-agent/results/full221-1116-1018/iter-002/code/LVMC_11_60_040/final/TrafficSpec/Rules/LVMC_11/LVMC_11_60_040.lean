/-
  LVMC_11_60_040 — LVMC-11-60-040

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The operator of a taxicab
    s2 (obligation): shall not stand or park such vehicle
    s3 (condition): upon any street
    s4 (exception): at any place other than in a taxicab stand so designated as provided herein.
    s5 (exception): This provision shall not prevent the operator of a taxicab from temporarily stopping
    s6 (exception): in accordance with other stopping or parking regulations
    s7 (exception): at any place for the purpose of and while actually engaged in the expeditious loading or unloading of passengers.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-LVMC-11-02-140::taxicab'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    s3: atoms ['rel.occupies', 'st.highway'], derived []
    s4: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s5: atoms ['ru.aggregate=DEF-LVMC-11-02-140::taxicab'], derived ['drv.motion.complete_halt']
    s7: atoms [], derived ['drv.motion.parked']

  How each span is written:
    s1: binder class `ru_aggregate subject "DEF-LVMC-11-02-140::taxicab"`.
    s2: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (such vehicle) in the applicability;
        standing is `drv_motion_parked subject [p.halt_speed_tolerance, p.standing_min_duration]`.
    s3: some highway region h with `rel_occupies subject h` (applicability).
    s4: some curb_zone z with `rel_occupies subject z` and `st_curb_zone_kind z taxicab_stand`
        (the consequent of the obligation).
    s5: `drv_motion_complete_halt subject [p.halt_speed_tolerance]`: the duty binds a halt that is
        standing; a halt that is not standing (temporary stop) leaves the obligation true.
    s7: the same parked window: a halt shorter than p.standing_min_duration is not standing.
    s6: residue (the node's).
  No choice beyond the record's was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_60_040

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1: the taxicab, as the admitted aggregate DEF-LVMC-11-02-140::taxicab. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-140::taxicab"] []

/-- s2 "such vehicle": the taxicab is a vehicle (admitted aggregate DEF-NRS-484A-320::vehicle). -/
def isVehicle : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3 "upon any street": the subject's footprint overlaps some highway. -/
def onStreet : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vSubject, .var "h"] [])

/-- s5: the taxicab is halted at the observation. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s2/s7: standing — at rest throughout the last p.standing_min_duration; a shorter halt
    (the temporary passenger stop) is not standing. -/
def standing : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]

/-- s4: the footprint overlaps a curb zone of kind taxicab_stand. -/
def inTaxicabStand : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and (.atom "rel_occupies" [vSubject, .var "z"] [])
          (.atom "st_curb_zone_kind" [.var "z", .lit "taxicab_stand"] []))

/-- Applicability: s3 (condition) with the subject a vehicle (s2 "such vehicle"). -/
def applicability : Formula := .and isVehicle onStreet

/-- Obligation: s2 with s4, s5, s7 — a halt that is standing (s2, s7) is in a taxicab stand (s4);
    a halt that is not standing (s5) is not constrained. -/
def obligation : Formula := .implies (.and halted standing) inTaxicabStand

def rule : Rule :=
  { id := "LVMC_11_60_040"
    laws := ["LVMC-11-60-040"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'This provision shall not prevent' a temporary passenger stop: the words leave such a stop to the other stopping and parking regulations, which judge it by their own rules. A temporary stop that breaches another regulation is that regulation's violation; under this provision it is neither standing nor parking (DEF-NRS-484A-250, DEF-NRS-484A-155), so this rule's verdict is the same whether or not the stop complies with the others."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_60_040

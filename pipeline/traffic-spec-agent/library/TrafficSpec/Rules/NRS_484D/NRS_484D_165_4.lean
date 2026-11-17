/-
  NRS_484D_165_4 — NRS-484D-165-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Any lighted headlamps
    s2 (subject): upon a parked vehicle
    s3 (obligation): shall be depressed or dimmed.

  Elements (span → atoms, derived):
    s1: atoms ['sig.headlamp'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    s3: atoms ['sig.headlamp'], derived []

  How each span is written:
    s2 (subject): the binder class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; "parked"
      is `drv_motion_parked subject` with (p.halt_speed_tolerance, p.parking_min_duration), in the
      concept's formal order (speed_tol, min_duration), conjoined into the applicability.
    s1 (trigger): "lighted headlamps" is a headlamp state other than off, written as the record
      states it: `sig_headlamp subject low_beam ∨ sig_headlamp subject high_beam`.
    s3 (obligation): "depressed or dimmed" is the low beam: `sig_headlamp subject low_beam`.
  No choice was left open by the record; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484D_165_4

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the vehicle is parked (drv.motion.parked). -/
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- The subject's headlamps are in the given state. -/
def headlamp (state : String) : Formula := .atom "sig_headlamp" [vSubject, .lit state] []

/-- s1: lighted headlamps — on low beam or on high beam. -/
def lighted : Formula := .or (headlamp "low_beam") (headlamp "high_beam")

/-- Applicability: s2 (parked) and s1 (lighted headlamps). -/
def applicability : Formula := .and parked lighted

/-- Obligation: s3 — depressed or dimmed: on low beam. -/
def obligation : Formula := headlamp "low_beam"

def rule : Rule :=
  { id := "NRS_484D_165_4"
    laws := ["NRS-484D-165-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484D_165_4

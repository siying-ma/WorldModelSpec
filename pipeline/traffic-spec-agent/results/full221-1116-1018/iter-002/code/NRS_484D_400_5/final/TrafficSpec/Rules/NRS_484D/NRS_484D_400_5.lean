/-
  NRS_484D_400_5 — NRS-484D-400-5

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): An authorized emergency vehicle
    s2 (definitional): may be equipped with a siren, whistle or bell, capable of emitting sound audible under normal conditions from a distance of not less than 500 feet,
    s3 (obligation): but the siren must not be used
    s4 (exception): except when the vehicle is operated in response to an emergency call
    s5 (exception): or in the immediate pursuit of an actual or suspected violator of the law,
    s6 (exception): in which event the driver of the vehicle may sound the siren to warn pedestrians and other drivers of his or her approach.
    s7 (definitional): A driver of an emergency vehicle may operate the vehicle’s warning lamps without sounding the siren.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    s3: atoms ['sig.siren'], derived []
    s4: atoms ['sig.warning_lamp'], derived []
    s5: atoms ['sig.warning_lamp'], derived []

  How each is written:
    s1: binder class = ru_aggregate(subject, "DEF-NRS-484A-020::authorized_emergency_vehicle").
    s3: obligation = ¬ sig_siren(subject).
    s4, s5: applicability = ¬ (sig_warning_lamp(subject, colour, mode) for some colour in
        {red, blue, amber, white} and mode in {flashing, rotating}) — the record's observable
        reading, written as mapped; no choice of this file's own (no narrowing).
    s2, s6, s7: residues.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484D_400_5

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject` (s1): ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] []

/-- s4, s5 (the record's observable reading): the subject displays a warning lamp, of any colour,
    in mode flashing or rotating. -/
def lampFlashingOrRotating : Formula :=
  let shows (c m : String) : Formula := .atom "sig_warning_lamp" [vSubject, .lit c, .lit m] []
  let anyColour (m : String) : Formula :=
    .or (shows "red" m) (.or (shows "blue" m) (.or (shows "amber" m) (shows "white" m)))
  .or (anyColour "flashing") (anyColour "rotating")

/-- Applicability: s4/s5 (exception) — not at an observation at which the subject's warning lamp is
    flashing or rotating; s6 is a residue. -/
def applicability : Formula := .not lampFlashingOrRotating

/-- Obligation: s3 (obligation): but the siren must not be used — sig.siren not sounding. -/
def obligation : Formula := .not (.atom "sig_siren" [vSubject] [])

def rule : Rule :=
  { id := "NRS_484D_400_5"
    laws := ["NRS-484D-400-5"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["A permission about equipment and its audible range; it imposes no duty on conduct and the rule judges only whether the siren sounds.", "Restates the permission the exception (s4, s5) grants: in that event the siren may sound. The purpose 'to warn pedestrians and other drivers of his or her approach' is what a sounding siren does; the duty is the same whether or not these words are read.", "A permission to show warning lamps without the siren; it imposes no duty, and the siren duty never judges lamps alone."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484D_400_5

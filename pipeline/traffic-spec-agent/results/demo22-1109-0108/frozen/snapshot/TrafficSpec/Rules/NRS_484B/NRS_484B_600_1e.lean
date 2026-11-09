/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (condition): In any event,
    s3 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.standstill']
    s3: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s3: 80 mph — 80 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1 (subject). 'a vehicle of any kind or character' is the defined term the table resolves to
      DEF-NRS-484A-320, written as the binder's class `ru_aggregate v "DEF-NRS-484A-320::vehicle"`:
      the aggregate id, never the classes under it. 'to drive or operate' is the vehicle's
      controlled motion, written in the applicability as `drv.motion.standstill` negated for `v`
      with p.standstill_speed_tolerance — the plan's observable reading of agency, already on its
      record and not restated here.
    s2 (condition). Residue, verbatim from the node: the words add no observable condition, and
      nothing in the scene is read for them; the applicability carries s1's motion alone.
    s3 (obligation). 'a rate of speed greater than 80 miles per hour' is the magnitude of velocity
      against the figure the text itself states: `kin.speed v ≤ 80 mph`, the statute's own literal
      through `Units.mph`. The duty holds where the magnitude does not exceed it; nothing posted
      and no judgement standard enters.

  Nothing the node left open needed a choice beyond its elements, so `narrowings` is empty.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

/-- The figure the text states on s3: 80 miles per hour. -/
def eightyMilesPerHour : Term := .lit (Units.mph 80) .metrePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1, the vehicle is in motion — 'to drive or operate' read through its
    controlled motion. s2 ('In any event,') is residue and adds nothing. -/
def applicability : Formula :=
  .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- Obligation: s3 (obligation): a rate of speed greater than 80 miles per hour. -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vV]) .le eightyMilesPerHour

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["The words add no observable condition and no restriction to the duty: they say that the cap binds whatever the other paragraphs of the subsection allow, so the duty is the same whether or not these words hold, and nothing in the scene is read for them."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e

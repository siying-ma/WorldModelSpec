/-
  NRS_484B_785_1a — NRS-484B-785-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except as otherwise provided in an ordinance enacted pursuant to NRS 484A.469 [DEF-LVMC-11-40-185-A],
    s2 (subject): an electric scooter
    s3 (trigger): may be operated:
    s4 (condition): On a roadway, bicycle lane, path or route
    s5 (obligation): at a speed of not more than 15 miles per hour.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s4: atoms ['rel.occupies', 'st.roadway', 'st.bicycle_lane_or_path'], derived []
    s5: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 15 mph — 15 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1, s3: residues (scope none) — not written.
    s2: binder class `ru_aggregate subject "DEF-NRS-484B-018::electric_scooter"`.
    s4: applicability = (∃ roadway r, rel_occupies subject r) ∨ (∃ bicycle_lane_or_path b,
        rel_occupies subject b); the claimed structure atoms enter as the quantifier kinds.
    s5: obligation = kin_speed subject ≤ 15 mph (Units.mph 15, in m/s).
  No choice beyond the record's own narrowing (s5 read as a limit) was made.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_785_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject` (s2): membership of the admitted aggregate
    DEF-NRS-484B-018::electric_scooter, written as `ru_aggregate` with the aggregate id. -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-018::electric_scooter"] []

/-- s4: the subject's footprint overlaps some roadway (st.roadway as the quantifier kind),
    anchored by rel.occupies. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- s4: the subject's footprint overlaps some bicycle lane or path. -/
def onBicycleLaneOrPath : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "b" (.atom "rel_occupies" [vSubject, .var "b"] [])

/-- Applicability: s4 (condition) only; s1 and s3 are the node's residues (scope none). -/
def applicability : Formula := .or onRoadway onBicycleLaneOrPath

/-- s5: the text's figure, 15 mph, through its Units constructor. -/
def speedBound : Term := .lit (Units.mph 15) .metrePerSecond

/-- Obligation: s5 — kin.speed of the subject at most 15 mph. -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le speedBound

def rule : Rule :=
  { id := "NRS_484B_785_1a"
    laws := ["NRS-484B-785-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["The ordinance the words name (LVMC 11.40.185(A), posted as DEF-LVMC-11-40-185-A: 'an electric bicycle or an electric scooter may be operated on a public roadway or sidewalk, or a lane, path, or route designated for bicycle, electric bicycle, or electric scooter use') provides where a scooter may be operated and states no speed; nothing in it provides otherwise on the speed this line bounds, so the duty is the same whether or not the exception's words hold.", "The permission to operate adds no restriction to the speed bound: a scooter at rest or moving below the bound meets it alike, so the duty is the same whether or not the scooter is being operated."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_785_1a

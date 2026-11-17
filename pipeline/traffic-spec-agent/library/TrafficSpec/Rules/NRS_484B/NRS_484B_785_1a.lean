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
    s2: atoms ['ru.electric_scooter'], derived []
    s4: atoms ['rel.occupies', 'st.roadway', 'st.bicycle_lane_or_path'], derived []
    s5: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 15 mph — 15 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_785_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    s2: the binder's class is the class atom ru.electric_scooter of `subject`.
    s4: the subject's footprint overlaps (rel.occupies) some region of kind `roadway`
        (st.roadway) or some region of kind `bicycle_lane_or_path` (st.bicycle_lane_or_path);
        each quantifier ranges over its claimed kind and is anchored by rel.occupies to `subject`.
        'route' adds no place beyond these (the record's reading).
    s5: kin.speed of `subject` ≤ 15 mph, the text's literal written through `Units.mph 15`.
    s1, s3: residues (scope none), not written.
  No choice beyond the record's was made; `narrowings` is empty.
-/

/-- 15 miles per hour, the text's own figure (s5). -/
def fifteenMph : Term := .lit (Units.mph 15) .metrePerSecond

/-- Class of `subject`: ru.electric_scooter -/
def clsSubject : Formula := .atom "ru_electric_scooter" [vSubject] []

/-- s4: the subject's footprint overlaps a roadway, or a bicycle lane or path. -/
def onRoadwayOrBicycleLane : Formula :=
  .or
    (.existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, .var "rw"] []))
    (.existsRegion (.lit "bicycle_lane_or_path") "bl" (.atom "rel_occupies" [vSubject, .var "bl"] []))

/-- Applicability: s1 (exception): Except as otherwise provided in an ordinance enacted pursuant to NRS 484A.469 [DEF-LVMC-11-40-185-A],; s3 (trigger): may be operated:; s4 (condition): On a roadway, bicycle lane, path or route -/
def applicability : Formula := onRoadwayOrBicycleLane

/-- Obligation: s5 (obligation): at a speed of not more than 15 miles per hour. -/
def obligation : Formula := .cmp (.measure "kin_speed" [vSubject]) .le fifteenMph

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
    residues := ["The ordinance the words name is LVMC 11.40.185(A), posted as DEF-LVMC-11-40-185-A: 'an electric bicycle or an electric scooter may be operated on a public roadway or sidewalk, or a lane, path, or route designated for bicycle, electric bicycle, or electric scooter use'. It provides where a scooter may be operated and states no speed. Nothing in it provides otherwise on the speed this line bounds, so the duty is the same whether or not the exception's words hold.", "The permission to operate adds no restriction to the speed bound: a scooter at rest and one moving below the bound both meet it. The duty is therefore the same whether or not the scooter is being operated."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_785_1a

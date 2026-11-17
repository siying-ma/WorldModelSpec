/-
  NRS_484B_213_2b — NRS-484B-213-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): must not be driven to the left side of the highway at any time:
    s3 (trigger): When approaching within 100 feet or traversing any intersection or railroad grade crossing.
    s4 (exception): Subsection 2 does not apply upon a one-way highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['prim.region_lateral_offset', 'st.centre_line', 'st.on_way', 'st.highway', 'rel.occupies'], derived []
    s3: atoms ['st.intersection', 'st.railway_crossing', 'st.region_geometry', 'rel.occupies', 'kin.position', 'kin.velocity'], derived []
    s4: atoms ['rel.occupies', 'st.one_way_roadway'], derived []

  Literals the text states (each written through its Units constructor):
    s3: 100 ft — 100 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: for some region `x` of kind `intersection`, or (a second quantifier) of kind
        `railway_crossing`: the subject occupies `x` (traversing), or (approaching) the ground
        distance from its body to `x` (`st_region_geometry_distance`) is at most 100 ft
        (`Units.feet 100`, the text's literal) and the dot product of its `kin_velocity` with the
        vector from its `kin_position` to `x`'s reference point (`st_region_geometry` x/y) is
        strictly positive, written as vx·dx > −(vy·dy) so both sides carry one unit (m²/s). The two kinds are separate quantifiers over the same disjunction.
    s4: the subject occupies no `one_way_roadway` region (`not (existsRegion … rel_occupies)`),
        conjoined into the applicability.
    s2: for every `highway` h the subject occupies, for every `centre_line` c lying on h
        (`st_on_way c h`), `prim_region_lateral_offset(subject, c) ≥ 0`; a negative offset (the
        centre line to the subject's right, i.e. the subject left of it) violates. "at any time"
        is the per-observation sweep. "driven" is the record's observable reading (agency): it is
        written through the subject's state and adds no atom.
  No choice beyond the record's own was needed: no narrowing is declared.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The stated distance: 100 feet (s3). -/
def approachDistance : Term := .lit (Units.feet 100) .metre

/-- s3 for one region `x`: traversing it, or approaching within the stated distance. -/
def nearOrOn (x : String) : Formula :=
  let vx : Term := .measure "kin_velocity" [vSubject, .lit "x"]
  let vy : Term := .measure "kin_velocity" [vSubject, .lit "y"]
  let dx : Term := .sub (.measure "st_region_geometry" [.var x, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
  let dy : Term := .sub (.measure "st_region_geometry" [.var x, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
  .or (.atom "rel_occupies" [vSubject, .var x] [])
      (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, .var x]) .le approachDistance)
            (.cmp (.mul vx dx) .gt (.neg (.mul vy dy))))

/-- Applicability: s3 (trigger): When approaching within 100 feet or traversing any intersection or railroad grade crossing.; s4 (exception): Subsection 2 does not apply upon a one-way highway. -/
def applicability : Formula :=
  .and
    (.or (.existsRegion (.lit "intersection") "x" (nearOrOn "x"))
         (.existsRegion (.lit "railway_crossing") "x" (nearOrOn "x")))
    (.not (.existsRegion (.lit "one_way_roadway") "w" (.atom "rel_occupies" [vSubject, .var "w"] [])))

/-- Obligation: s2 (obligation): must not be driven to the left side of the highway at any time: -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.forallRegion (.lit "centre_line") "c"
        (.implies (.atom "st_on_way" [.var "c", .var "h"] [])
          (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "c"] []) .ge zeroMetres))))

def rule : Rule :=
  { id := "NRS_484B_213_2b"
    laws := ["NRS-484B-213-2b"]
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

end TrafficSpec.Rules.NRS_484B_213_2b

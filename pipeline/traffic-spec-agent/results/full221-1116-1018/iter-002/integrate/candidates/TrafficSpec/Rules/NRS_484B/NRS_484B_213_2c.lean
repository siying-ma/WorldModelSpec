/-
  NRS_484B_213_2c — NRS-484B-213-2c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): must not be driven to the left side of the highway at any time:
    s3 (standard): When the view is obstructed
    s4 (trigger): upon approaching within 100 feet of any bridge, viaduct or tunnel.
    s5 (exception): Subsection 2 does not apply upon a one-way highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['prim.region_lateral_offset', 'st.centre_line', 'st.on_way', 'st.highway', 'rel.occupies'], derived []
    s4: atoms ['st.elevated_structure', 'st.region_geometry', 'kin.position', 'kin.velocity'], derived []
    s5: atoms ['rel.occupies', 'st.one_way_roadway'], derived []

  How each span is written:
    s1: the class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    s5: no region of kind `one_way_roadway` is occupied by the subject (`rel_occupies`).
    s3: some `highway` region the subject occupies has `st_sight_distance` below
        `kin_speed(subject) * p.passing_sight_time` (the operationalization). Choice (narrowing s3):
        the "subject's point" whose sight distance is read is the highway region the subject
        occupies — the only claimed region kind that holds the subject.
    s4: some `elevated_structure` e with `st_region_geometry_distance(subject, e)` at most
        100 ft and the dot product of `kin_velocity(subject)` with the vector from
        `kin_position(subject)` to e's reference point (`st_region_geometry`, x and y) positive.
    s2: for every `highway` h the subject occupies and every `centre_line` c lying on h
        (`st_on_way c h`), `prim_region_lateral_offset(subject, c)` is not negative.

  Literals the text states (each written through its Units constructor):
    s4: 100 ft — 100 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPassingSightTime : Term := .param "p.passing_sight_time"

def zeroMetres : Term := .lit Q.zero .metre

/-- s4: the text's 100 feet. -/
def approachDistance : Term := .lit (Units.feet 100) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s5: the subject occupies a one-way roadway. -/
def onOneWay : Formula :=
  .existsRegion (.lit "one_way_roadway") "w" (.atom "rel_occupies" [vSubject, .var "w"] [])

/-- s3: the view is obstructed — sight distance at the subject's highway below speed × time. -/
def viewObstructed : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.cmp (.measure "st_sight_distance" [.var "h"]) .lt
        (.mul (.measure "kin_speed" [vSubject]) pPassingSightTime)))

/-- s4: one component of the dot product of the subject's velocity with the vector from its
    position to e's reference point. -/
def towardComponent (e sel : String) : Term :=
  .mul (.measure "kin_velocity" [vSubject, .lit sel])
    (.sub (.measure "st_region_geometry" [.var e, .lit sel]) (.measure "kin_position" [vSubject, .lit sel]))

/-- s4: approaching within 100 feet of a bridge, viaduct or tunnel. The dot product is positive,
    written as its x component above the negated y component (one unit on both sides). -/
def approachingStructure : Formula :=
  .existsRegion (.lit "elevated_structure") "e"
    (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "e"]) .le approachDistance)
      (.cmp (towardComponent "e" "x") .gt (.neg (towardComponent "e" "y"))))

/-- Applicability: s4 (trigger), s3 (standard), s5 (exception). -/
def applicability : Formula :=
  .and (.not onOneWay) (.and viewObstructed approachingStructure)

/-- Obligation: s2 — not left of any centre line lying on a highway the subject occupies. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.forallRegion (.lit "centre_line") "c"
        (.implies (.atom "st_on_way" [.var "c", .var "h"] [])
          (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "c"] []) .ge zeroMetres))))

def rule : Rule :=
  { id := "NRS_484B_213_2c"
    laws := ["NRS-484B-213-2c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the view is obstructed"
          concepts := ["kin.speed", "st.sight_distance"]
          params := ["p.passing_sight_time"]
          convention := "Passing sight distance: the MUTCD minimum passing sight distance by prevailing speed (Table 3B-1), the warrant for a no-passing zone where the view is restricted, expressed as the time the subject's speed takes to cover it. The view is obstructed where st.sight_distance at the subject's point, 'the distance along the road within which a vehicle at a point and another vehicle on the road could see each other', is below the subject's kin.speed times p.passing_sight_time; the bound moves with the subject's speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "st.sight_distance 'at the subject's point' is read off the highway region the subject occupies (rel.occupies); the view is obstructed where it is below the subject's kin.speed times p.passing_sight_time for some such highway."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_2c

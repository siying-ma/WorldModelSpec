/-
  NRS_484B_213_2a — NRS-484B-213-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): must not be driven to the left side of the highway at any time:
    s3 (trigger): When approaching the crest of a grade
    s4 (trigger): or upon a curve in the highway
    s5 (condition): where the driver’s view is obstructed
    s6 (standard): within such distance as to create a hazard in the event another vehicle might approach from the opposite direction.
    s7 (exception): Subsection 2 does not apply upon a one-way highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['prim.region_lateral_offset', 'st.centre_line', 'st.on_way', 'st.highway', 'rel.occupies'], derived []
    s3: atoms ['st.crest', 'st.region_geometry', 'kin.position', 'kin.velocity'], derived []
    s4: atoms ['st.curvature', 'rel.occupies', 'st.highway'], derived []
    s5: atoms ['st.sight_distance'], derived []
    s7: atoms ['rel.occupies', 'st.one_way_roadway'], derived []

  How each span is written:
    s1: ru_aggregate(subject, "DEF-NRS-484A-320::vehicle").
    s2: for every highway h the subject occupies (rel_occupies) and every centre_line c lying on
        it (st_on_way c h), prim_region_lateral_offset(subject, c) ≥ 0; a negative offset (the
        line to the subject's right) is the subject on the left side. Judged at every
        observation ("at any time"), which is the sweep over instants.
    s3: some crest k with velocity · (k's reference point − position) > 0, written as
        v·k > v·p so both sides carry one unit (kin_velocity, st_region_geometry x/y,
        kin_position) and st_region_geometry_distance(subject, k) at
        most the hazard distance (s6).
    s4: some highway the subject occupies with st_curvature > p.curvature_resolution.
    s5: some highway the subject occupies with st_sight_distance below the hazard distance (s6):
        "at its point" is read as the sight distance carried by the highway region the subject
        occupies, the only place region the node claims.
    s6: hazard distance = kin_speed(subject) × p.passing_sight_time.
    s7: no one_way_roadway the subject occupies (rel_occupies).
  Applicability = ¬s7 ∧ s5 ∧ (s3 ∨ s4). No compositions. No narrowings of this session.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pPassingSightTime : Term := .param "p.passing_sight_time"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s6: the hazard distance, the subject's speed times the passing sight time. -/
def hazardDistance : Term :=
  .mul (.measure "kin_speed" [vSubject]) pPassingSightTime

/-- s7: the subject occupies a one-way roadway. -/
def onOneWay : Formula :=
  .existsRegion (.lit "one_way_roadway") "ow" (.atom "rel_occupies" [vSubject, .var "ow"] [])

/-- s5 + s6: the sight distance at the subject's point (of the highway it occupies) is below the
    hazard distance. -/
def viewObstructed : Formula :=
  .existsRegion (.lit "highway") "hs"
    (.and (.atom "rel_occupies" [vSubject, .var "hs"] [])
          (.cmp (.measure "st_sight_distance" [.var "hs"]) .lt hazardDistance))

/-- s3 + s6: a crest whose reference point the subject's velocity points toward (positive dot
    product of the velocity with the vector from its position to that point) and whose ground
    distance from the subject's body is at most the hazard distance. -/
def approachingCrest : Formula :=
  .existsRegion (.lit "crest") "k"
    (.and
      (.cmp
        (.add
          (.mul (.measure "kin_velocity" [vSubject, .lit "x"])
                (.measure "st_region_geometry" [.var "k", .lit "x"]))
          (.mul (.measure "kin_velocity" [vSubject, .lit "y"])
                (.measure "st_region_geometry" [.var "k", .lit "y"])))
        .gt
        (.add
          (.mul (.measure "kin_velocity" [vSubject, .lit "x"])
                (.measure "kin_position" [vSubject, .lit "x"]))
          (.mul (.measure "kin_velocity" [vSubject, .lit "y"])
                (.measure "kin_position" [vSubject, .lit "y"]))))
      (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "k"]) .le hazardDistance))

/-- s4: the subject occupies a highway whose curvature at its point exceeds the resolution. -/
def uponCurve : Formula :=
  .existsRegion (.lit "highway") "hc"
    (.and (.atom "rel_occupies" [vSubject, .var "hc"] [])
          (.cmp (.measure "st_curvature" [.var "hc"]) .gt pCurvatureResolution))

/-- Applicability: s3 (trigger): When approaching the crest of a grade; s4 (trigger): or upon a curve in the highway; s5 (condition): where the driver’s view is obstructed; s7 (exception): Subsection 2 does not apply upon a one-way highway. -/
def applicability : Formula :=
  .and (.not onOneWay)
    (.and viewObstructed
          (.or approachingCrest uponCurve))

/-- Obligation: s2 (obligation): must not be driven to the left side of the highway at any time:; s6 (standard): within such distance as to create a hazard in the event another vehicle might approach from the opposite direction.
    For every highway the subject occupies and every centre line lying on it, the line's signed
    lateral offset from the subject is not negative (the subject is not left of it). -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.forallRegion (.lit "centre_line") "c"
        (.implies (.atom "st_on_way" [.var "c", .var "h"] [])
          (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "c"] []) .ge zeroMetres))))

def rule : Rule :=
  { id := "NRS_484B_213_2a"
    laws := ["NRS-484B-213-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "within such distance as to create a hazard in the event another vehicle might approach from the opposite direction"
          concepts := ["kin.speed", "st.region_geometry", "st.sight_distance"]
          params := ["p.passing_sight_time"]
          convention := "Passing sight distance: the MUTCD minimum passing sight distance by prevailing speed (Table 3B-1), the warrant for a no-passing zone at a crest or curve, expressed as the time the subject's speed takes to cover it. The hazard distance is the subject's kin.speed times p.passing_sight_time; the view is obstructed within it where st.sight_distance at the subject's point is below it, and a crest is approached within it where its ground distance (st.region_geometry) is at most it. The bound moves with the subject's speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_2a

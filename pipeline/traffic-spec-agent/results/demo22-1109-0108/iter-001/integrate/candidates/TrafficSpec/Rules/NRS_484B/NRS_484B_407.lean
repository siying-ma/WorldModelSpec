/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (condition): upon any curve,
    s4 (condition): or upon the approach to or near the crest of a grade,
    s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.u_turn']
    s3: atoms ['rel.occupies', 'st.curvature', 'st.roadway'], derived []
    s4: atoms ['rel.occupies', 'st.crest', 'st.region_geometry', 'st.roadway'], derived []
    s5: atoms ['rel.occupies', 'st.roadway', 'st.sight_distance'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 500 ft — 500 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:

  s1 — `clsV` is `ru_aggregate` of the binder with the aggregate id the record claims, as a
  literal argument; the classes the definition includes are the reading's, not this file's.

  s2 — `uTurnReversal` is the one call the record's element names, `drv.motion.u_turn`, with the
  three parameters of its signature in order (the heading step, the onset yaw rate, the reversal
  angle). The record uses the act as an event with `boundary: "event"`, and its `recognition` is
  "the observation at which the magnitude of the heading change accumulated since that onset first
  reaches the reversal angle, which is where the concept rises; the later observations at which the
  accumulated change still holds that angle are not the act again": the obligation is therefore
  `.not (.rises uTurnReversal)` — the duty is broken at the recognition and at no other
  observation of the same manoeuvre.

  s3, s4, s5 — the conditions, each with its own region quantifier over `roadway` (the kind the
  record names), anchored to the binder by `rel_occupies`, as each element maps it:
    * s3: the magnitude of the roadway's horizontal curvature standing at or above
      `p.curvature_resolution`, which is "any curve" as the record reads it (the parameter names
      the source's resolution and no measure of how sharp a bend must be);
    * s4: a `crest` region with the ground distance from the subject's body outline to it
      (`st_region_geometry_distance`, the accessor of `st.region_geometry` the contract names for
      that distance) at most `p.crest_approach_distance` — "the approach to or near" the crest on
      either hand of it;
    * s5: the sight distance of the place falling short of the text's own 500 feet.
  s3 and s4 are the alternatives the word "or" joins; s5 is joined to them by "where", so
  `conditions` is `(s3 ∨ s4) ∧ s5` — one and the same observation for the place and the sight.

  The occasion (`boundary: "event"`, spans s3/s4/s5 all `some_moment`) — `onset` is the record's
  onset element: the observation at which the magnitude of the subject's rate of change of heading
  (`kin.yaw_rate`, the only quantity that element reads) first rose above `p.turn_onset_yaw_rate`,
  written as the rise of that comparison, so the latest such rise is the onset of the manoeuvre
  being judged, the one the concept counts its heading change from. `underWay` is the record's
  under-way element in its own words: that magnitude standing above the onset yaw rate and the
  heading change accumulated since the onset not yet reaching the reversal angle, the accumulation
  taken with the reviewed step bound of the run's acquisition profile. The applicability is then
  `.since (.not onset) (underWay ∧ conditions)`: the conditions held, together, at some observation
  of the stretch that runs from the observed onset of this manoeuvre to the observation being
  judged — `.not onset` as the left operand ends the search at that onset and at no earlier one, so
  the same conditions holding only before the onset engage nothing. Before any observed onset the
  past of the recording cannot say whether a manoeuvre was under way, and the applicability is
  unknown there; every witness names the instants from the onset on.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrestApproachDistance : Term := .param "p.crest_approach_distance"
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnOnsetYawRate : Term := .param "p.turn_onset_yaw_rate"
def pUTurnReversalAngle : Term := .param "p.u_turn_reversal_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's own figure: 500 feet of sight distance. -/
def feet500 : Term := .lit (Units.feet 500) .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2's act: the subject's direction of travel upon a way has reversed. -/
def uTurnReversal : Formula :=
  .derived "drv_motion_u_turn" [vV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pUTurnReversalAngle]

/-- The magnitude of the subject's rate of change of heading stands above the onset yaw rate. -/
def turning : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vV])) .gt pTurnOnsetYawRate

/-- The occasion's onset: the observation at which that magnitude first rose above the onset yaw
    rate. -/
def onset : Formula := .rises turning

/-- The occasion's under-way element: that magnitude has stood above the onset yaw rate since the
    onset and the heading change accumulated since the onset has not yet reached the reversal
    angle. -/
def underWay : Formula :=
  .and turning
    (.cmp (.abs (.headingSince "v" pHeadingSinceStepCarlaSceneGraph onset)) .lt pUTurnReversalAngle)

/-- s3: upon any curve — the subject occupies a roadway whose horizontal curvature stands at or
    above the resolution of the source. -/
def uponCurve : Formula :=
  .existsRegion (.lit "roadway") "rc"
    (.and (.and (.atom "st_roadway" [.var "rc"] []) (.atom "rel_occupies" [vV, .var "rc"] []))
      (.cmp (.measure "st_curvature" [.var "rc"]) .ge pCurvatureResolution))

/-- s4: upon the approach to or near the crest of a grade — the subject occupies a roadway and the
    ground distance from its body to a crest region is at most the approach distance. -/
def nearCrest : Formula :=
  .existsRegion (.lit "roadway") "rg"
    (.and (.and (.atom "st_roadway" [.var "rg"] []) (.atom "rel_occupies" [vV, .var "rg"] []))
      (.existsRegion (.lit "crest") "cr"
        (.and (.atom "st_crest" [.var "cr"] [])
          (.cmp (.measure "st_region_geometry_distance" [vV, .var "cr"]) .le pCrestApproachDistance))))

/-- s5: the subject cannot be seen within 500 feet — the sight distance of the place it occupies
    falls short of the text's figure. -/
def unseenWithin500Feet : Formula :=
  .existsRegion (.lit "roadway") "rs"
    (.and (.and (.atom "st_roadway" [.var "rs"] []) (.atom "rel_occupies" [vV, .var "rs"] []))
      (.cmp (.measure "st_sight_distance" [.var "rs"]) .lt feet500))

/-- s3 or s4: the place the words name. -/
def place : Formula := .or uponCurve nearCrest

/-- The conditions as the text joins them: the place, and the sight condition by "where". -/
def conditions : Formula := .and place unseenWithin500Feet

/-- Applicability: s3 (condition): upon any curve,; s4 (condition): or upon the approach to or near the crest of a grade,; s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet. -/
def applicability : Formula := .since (.not onset) (.and underWay conditions)

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction -/
def obligation : Formula := .not (.rises uTurnReversal)

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407

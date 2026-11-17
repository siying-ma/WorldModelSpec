/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle:
    s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a street corner.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection', 'st.crosswalk', 'kin.yaw_rate'], derived ['drv.motion.moving_backward']

  How each is written:
    s1 — the binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`; the driver is read
         through the vehicle's controlled motion (the record's own agency narrowing).
    applicability — `drv.motion.moving_backward(subject)` with speed_tol = p.halt_speed_tolerance:
         the subject is backing at the observation.
    s2 — the obligation is the negation of three limbs, as the record states them:
      (a) back into an intersection: for some region r of kind `intersection` (st.intersection),
          `rises (rel_occupies subject r)` — the footprint overlaps r here and did not at the
          previous observation (while backing, which the applicability supplies);
      (b) on or over a crosswalk: for some region x of kind `crosswalk` (st.crosswalk),
          `rel_occupies subject x`;
      (c) around a street corner: for some region r of kind `intersection`, `rel_occupies subject r`
          and |headingSince(subject, p.heading_since_step_carla_scene_graph, ψ)| ≥ p.turn_heading_min,
          ψ = moving_backward(subject) ∧ rel_occupies(subject, r): the heading change (integrated
          from kin.yaw_rate) since the subject last began backing within r.
    No choice was left open beyond what the record states; no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject is backing: drv.motion.moving_backward with speed_tol = p.halt_speed_tolerance. -/
def backing : Formula := .derived "drv_motion_moving_backward" [vSubject] [pHaltSpeedTolerance]

/-- Applicability: the subject is backing at the observation. -/
def applicability : Formula := backing

/-- The subject's footprint overlaps region `v`. -/
def occ (v : String) : Formula := .atom "rel_occupies" [vSubject, .var v] []

/-- (a) Backs into an intersection: the footprint comes to overlap an intersection. -/
def intoIntersection : Formula :=
  .existsRegion (.lit "intersection") "r" (.rises (occ "r"))

/-- (b) On or over a crosswalk: the footprint overlaps a crosswalk. -/
def overCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "x" (occ "x")

/-- (c) Around a street corner: within an intersection, the heading has turned at least
    p.turn_heading_min since the subject last began backing within it. -/
def aroundCorner : Formula :=
  .existsRegion (.lit "intersection") "r"
    (.and (occ "r")
      (.cmp (.abs (.headingSince "subject" pHeadingSinceStepCarlaSceneGraph (.and backing (occ "r"))))
        .ge pTurnHeadingMin))

/-- Obligation: s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a street corner. -/
def obligation : Formula := .not (.or intoIntersection (.or overCrosswalk aroundCorner))

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2

/-
  NRS_484B_210_3 — NRS-484B-210-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not overtake and pass another vehicle upon the right
    s3 (condition): when such movement requires driving off the paved portion of the highway

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.passing_on_right']
    s3: atoms ['st.shoulder', 'st.road_edge', 'rel.occupies'], derived []

  How each is written:
    s1: the class of x is `ru_aggregate x DEF-NRS-484A-320::vehicle`, the aggregate claimed whole.
    s3: the applicability is the record's disjunction, written as stated: some shoulder region s
        (kind `shoulder`) that x occupies with `st_shoulder_paved s` false, or some road-edge region
        e (kind `road_edge`) that x's footprint occupies (straddles) with `st_road_edge_paved e`
        (the surface beyond it) false. Both regions are anchored to x by `rel_occupies`.
    s2: the obligation is, for every road user y of the scene other than x that is a member of
        the vehicle aggregate, not `drv.interaction.passing_on_right(x, y)` with the reading's
        cosine and speed tolerances in the concept's parameter order. With no other vehicle in
        the scene the universal holds and the duty is met.
  No choice beyond the record's own narrowings was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_210_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pSameDirectionCosTolerance : Term := .param "p.same_direction_cos_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate of s1 and s2, claimed whole. -/
def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, vehicleAggregate] []

/-- s3: x's footprint overlaps a shoulder whose paved attribute is false. -/
def onUnpavedShoulder : Formula :=
  .existsRegion (.lit "shoulder") "s"
    (.and (.atom "rel_occupies" [vX, .var "s"] [])
          (.not (.atom "st_shoulder_paved" [.var "s"] [])))

/-- s3: x's footprint straddles a road edge whose surface beyond is unpaved. -/
def onUnpavedEdge : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (.and (.atom "rel_occupies" [vX, .var "e"] [])
          (.not (.atom "st_road_edge_paved" [.var "e"] [])))

/-- Applicability: s3 (condition): when such movement requires driving off the paved portion of the highway -/
def applicability : Formula := .or onUnpavedShoulder onUnpavedEdge

/-- Obligation: s2 (obligation): shall not overtake and pass another vehicle upon the right.
    Every other vehicle `y` of the scene: x is not passing it on its right. -/
def obligation : Formula :=
  .forallUser "y"
    (.implies
      (.and (.not (.same vX (.var "y"))) (.atom "ru_aggregate" [.var "y", vehicleAggregate] []))
      (.not (.derived "drv_interaction_passing_on_right" [vX, .var "y"]
                [pSameDirectionCosTolerance, pMotionSpeedTolerance])))

def rule : Rule :=
  { id := "NRS_484B_210_3"
    laws := ["NRS-484B-210-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_210_3

/-
  NRS_484B_210_3 — NRS-484B-210-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): The driver of a vehicle
    f2 (obligation): shall not overtake and pass another vehicle upon the right
    f3 (condition): when such movement requires driving off the paved portion of the highway

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.same_direction', 'rel.longitudinal_overlap', 'rel.bearing', 'kin.speed'], derived ['drv.interaction.passing_on_right']
    f3: atoms ['st.shoulder', 'st.road_edge', 'rel.occupies'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_210_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOvertakingSpeedMargin : Term := .param "p.overtaking_speed_margin"
def pSameDirectionCosine : Term := .param "p.same_direction_cosine"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    f1: x's class is the admitted aggregate, `ru_aggregate x "DEF-NRS-484A-320::vehicle"`; the
        driver is read through the vehicle's controlled motion (the record's observable reading).
    f3: off the paved portion = x occupies (rel_occupies) a region of kind `shoulder` whose paved
        attribute (st_shoulder_paved) is false, or a region of kind `road_edge` whose paved attribute
        for the surface beyond it (st_road_edge_paved) is false. Each region is bound by its own
        quantifier over the kind and anchored to x by rel_occupies. Read at the same observation as
        the pass (the record: the movement as made).
    f2: no road user y other than x (`same`), of the same aggregate, with
        drv.interaction.passing_on_right(x, y) under p.same_direction_cosine and
        p.overtaking_speed_margin, in the order of the concept's formal parameters.
  No choice beyond the record's was needed: no narrowing of this file's own.
-/

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def isVehicle (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []

def clsX : Formula := isVehicle vX

/-- x occupies a shoulder whose paved attribute is false. -/
def onUnpavedShoulder : Formula :=
  .existsRegion (.lit "shoulder") "s"
    (.and (.atom "rel_occupies" [vX, .var "s"] [])
          (.not (.atom "st_shoulder_paved" [.var "s"] [])))

/-- x occupies a road edge whose surface beyond is unpaved. -/
def onUnpavedRoadEdge : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (.and (.atom "rel_occupies" [vX, .var "e"] [])
          (.not (.atom "st_road_edge_paved" [.var "e"] [])))

/-- Applicability: f3 (condition): when such movement requires driving off the paved portion of the highway -/
def applicability : Formula := .or onUnpavedShoulder onUnpavedRoadEdge

/-- Obligation: f2 (obligation): shall not overtake and pass another vehicle upon the right -/
def obligation : Formula :=
  .not (.existsUser "y"
    (.and (.not (.same vX (.var "y")))
      (.and (isVehicle (.var "y"))
        (.derived "drv_interaction_passing_on_right" [vX, .var "y"]
          [pSameDirectionCosine, pOvertakingSpeedMargin]))))

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

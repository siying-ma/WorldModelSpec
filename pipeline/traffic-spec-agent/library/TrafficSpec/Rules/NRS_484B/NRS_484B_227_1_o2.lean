/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): Every vehicle driven
    a2 (trigger): upon a divided highway
    a3 (sibling): must be driven only upon the right-hand roadway
    a4 (boilerplate): and
    a5 (obligation): must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn
    a7 (exception): except through an opening in the barrier or dividing section or space
    a8 (exception): or at a crossover or intersection
    a9 (exception): established by a public authority

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['st.highway', 'st.on_way', 'st.median_or_divider', 'st.roadway', 'rel.occupies'], derived []
    a5: atoms ['st.median_or_divider', 'rel.occupies', 'st.roadway', 'st.lane_direction', 'kin.velocity', 'kin.speed'], derived ['drv.motion.against_carrier_direction']
    a7: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    a8: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []
    a9: atoms ['st.median_or_divider', 'st.intersection'], derived []

  How each is written:
    a1: `ru_aggregate(x, DEF-NRS-484A-320::vehicle)` as the binder's class.
    a2: `selection h` — a highway region h on which some median_or_divider region lies
        (`st_on_way(d, h)`), and x occupies a roadway or a median_or_divider region lying on h.
        The applicability asks for some such h.
    a5: for every highway h of that same selection (the selection is written again in the
        obligation, whole): (a) x occupies no median_or_divider region lying on h, and (b) x
        occupies no roadway region w lying on h while moving against its designated direction
        (`drv_motion_against_carrier_direction(x, w)` with p.speed_resolution,
        p.opposed_direction_cosine).
    a7 / a8 / a9: the "unless" of the record's obligation, a disjunct beside (a)∧(b): x occupies a
        median_or_divider region lying on h that carries the opening attribute
        (`st_median_or_divider_opening`, the opening and the crossover alike), or an intersection
        region lying on h. Their presence on the road is the evidence of establishment (the
        record's observable reading of a9).

  Choice the record left to the writing: "Re-binding h with the same selection" is written as
  the duty at every selected highway (`forallRegion` over the selection); in a scene x lies on
  one highway's roadway or median, so this denotes the applicability's h.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOpposedDirectionCosine : Term := .param "p.opposed_direction_cosine"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- The highway variable, bound by the applicability's and the obligation's own quantifiers. -/
def vH : Arg := .var "h"

/-- x's footprint overlaps the region bound to `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- The region bound to `r` lies on the highway h. -/
def onWay (r : String) : Formula := .atom "st_on_way" [.var r, vH] []

/-- x occupies the region bound to `r`, lying on h. -/
def occOnWay (r : String) : Formula := .and (occ r) (onWay r)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- a2: h is divided — some dividing section lies on it. -/
def divided : Formula := .existsRegion (.lit "median_or_divider") "d" (onWay "d")

/-- a2: x is upon h — it occupies a roadway or a dividing section lying on h. -/
def upon : Formula :=
  .or (.existsRegion (.lit "roadway") "r" (occOnWay "r"))
      (.existsRegion (.lit "median_or_divider") "m" (occOnWay "m"))

/-- The record's whole selection of h. -/
def selection : Formula := .and divided upon

/-- Applicability: a2 (trigger): upon a divided highway -/
def applicability : Formula := .existsRegion (.lit "highway") "h" selection

/-- a7, a9: x is through an opening (crossover) of a dividing section lying on h. -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "o"
    (.and (occOnWay "o") (.atom "st_median_or_divider_opening" [.var "o"] []))

/-- a8, a9: x is at an intersection lying on h. -/
def atIntersection : Formula := .existsRegion (.lit "intersection") "i" (occOnWay "i")

/-- a5 (a): x is over, across or within a dividing section lying on h. -/
def overDivider : Formula := .existsRegion (.lit "median_or_divider") "s" (occOnWay "s")

/-- a5 (b): x occupies a roadway lying on h and moves against its designated direction. -/
def againstRoadway : Formula :=
  .existsRegion (.lit "roadway") "w"
    (.and (occOnWay "w")
      (.derived "drv_motion_against_carrier_direction" [vX, .var "w"]
        [pSpeedResolution, pOpposedDirectionCosine]))

/-- Obligation: a5 (obligation): must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn; unless a7, a8, a9 -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies selection
      (.or (.or throughOpening atIntersection)
           (.and (.not overDivider) (.not againstRoadway))))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2

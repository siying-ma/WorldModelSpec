/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): Every vehicle driven
    a2 (trigger): upon a divided highway
    a3 (obligation): must be driven only upon the right-hand roadway
    a4 (boilerplate): and
    a5 (sibling): must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn
    a7 (sibling): except through an opening in the barrier or dividing section or space
    a8 (sibling): or at a crossover or intersection
    a9 (sibling): established by a public authority

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['st.highway', 'st.on_way', 'st.median_or_divider', 'st.roadway', 'rel.occupies'], derived []
    a3: atoms ['st.roadway', 'rel.occupies', 'st.lane_direction', 'kin.velocity', 'kin.speed'], derived ['drv.motion.against_carrier_direction']

  How each element is written:
    a1: the binder class, ru_aggregate(x, "DEF-NRS-484A-320::vehicle"); 'driven' is the record's
        observable reading (controlled motion), carried by the concept's own motion test in a3.
    a2: some st.highway region h (quantifier kind `highway`) on which some median_or_divider lies
        (st_on_way m h), and x occupies (rel_occupies) a roadway or a median_or_divider lying on h.
    a3: re-binding h (a divided highway x is upon), for every roadway q on h that x occupies,
        not drv.motion.against_carrier_direction(x, q) with speed_floor p.speed_resolution and
        opposed_cosine p.opposed_direction_cosine. The re-selection writes the roadway limb of
        'x upon h' only: the duty's antecedent (x occupies a roadway q on h) entails it, so a
        highway x is upon through its dividing section alone leaves the duty empty either way,
        and the dividing-section limb would be a leaf no scene can move (the gate's VACUOUS).
        The re-bound h is the same set of highways on which the duty has content. The record's
        readings on a1 and a3 are its own; no further choice was left open, so `narrowings` is
        empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOpposedDirectionCosine : Term := .param "p.opposed_direction_cosine"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The highway `h` is divided: some st.median_or_divider region lies on it (st.on_way). -/
def divided (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "m" (.atom "st_on_way" [.var "m", .var h] [])

/-- `x` occupies an st.roadway region lying on `h`. -/
def uponRoadway (h : String) : Formula :=
  .existsRegion (.lit "roadway") "r" (.and (.atom "st_on_way" [.var "r", .var h] [])
                                           (.atom "rel_occupies" [vX, .var "r"] []))

/-- `x` occupies an st.median_or_divider region lying on `h`. -/
def uponDivider (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "d" (.and (.atom "st_on_way" [.var "d", .var h] [])
                                                     (.atom "rel_occupies" [vX, .var "d"] []))

/-- a2: `h` is divided and `x` is upon it (on a roadway or a dividing section lying on it). -/
def selectedHighway (h : String) : Formula := .and (divided h) (.or (uponRoadway h) (uponDivider h))

/-- Applicability: a2 (trigger): upon a divided highway -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (selectedHighway "h")

/-- a3: `x` moves against the designated direction of the roadway `r`. -/
def againstRoadway (r : String) : Formula :=
  .derived "drv_motion_against_carrier_direction" [vX, .var r] [pSpeedResolution, pOpposedDirectionCosine]

/-- Obligation: a3 (obligation): must be driven only upon the right-hand roadway -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.and (divided "h") (uponRoadway "h"))
      (.forallRegion (.lit "roadway") "q"
        (.implies (.and (.atom "st_on_way" [.var "q", .var "h"] [])
                        (.atom "rel_occupies" [vX, .var "q"] []))
                  (.not (againstRoadway "q")))))

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
    laws := ["NRS-484B-227-1"]
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

end TrafficSpec.Rules.NRS_484B_227_1_o1

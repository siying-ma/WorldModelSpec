/-
  NRS_484B_227_1_o3 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (sibling): must be driven only upon the right-hand roadway
    s4 (sibling): and must not be driven over, across or within any dividing space, barrier or section
    s5 (obligation): or make any left turn, semicircular turn or U-turn,
    s6 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms ['st.highway', 'st.roadway', 'st.median_or_divider', 'rel.occupies'], derived []
    s5: atoms [], derived ['drv.motion.left_turn', 'drv.motion.u_turn']
    s6: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each span is written.

    s1 — `clsV`: the aggregate word of the text, `ru_aggregate v "vehicle"`, the word and not the
    classes it covers.

    s2 — `uponDividedHighway`: the subject's footprint overlaps a highway and a roadway of it
    (`rel_occupies` against a region quantified at each kind), and the scene carries a physical
    barrier or dividing section — the structure that divides the way into its roadways — which the
    subject is not upon, it being upon a roadway. The vocabulary this node claims relates a region
    to the subject and never one region to another, so `rel.occupies` is what ties the dividing
    structure to the subject at all: it is the thing the subject drives beside, not upon, while it
    is upon the roadway. The trigger is read through the vehicle's own controlled motion upon that
    way (the node's `observable_reading` on s2), so nothing here reads who is driving.

    s2 is read `some_moment` of the occasion: `.not (.holdsFor .time p.turn_window "v"
    (.not (.and underWay uponDividedHighway)))` — the subject was upon a divided highway at some
    observation of the window behind at which the turning was under way.

    `underWay` — the occasion's `under_way` element: `kin.yaw_rate` standing clear of zero by
    `p.yaw_rate_floor`, the resolution of the source's yaw channel. It is read on the body and not
    on the road.

    s5 — `act`: `drv.motion.left_turn` over `p.turn_window` at `p.corner_heading_change`, and
    `drv.motion.u_turn` over `p.turn_window` within `p.turn_reversal_tolerance` of a half turn,
    which reads a turning about either way about and so carries the semicircular turn and the
    U-turn of the text. The duty is that the act is not made: `obligation := act → excused`.

    s6 — `throughOpeningOrIntersection`: the subject is within a dividing structure carrying the
    opening attribute (the opening or crossover of the text), or within an intersection. The
    presence of the feature is the observable evidence of its establishment by a public authority
    (the node's `observable_reading` on s6). It is read `throughout` the occasion:
    `.holdsFor .time p.turn_window "v" (.implies underWay throughOpeningOrIntersection)` — the
    excuse stands only where the subject was within the opening or the intersection at every
    observation of the window at which the turning was under way; a turning carried partly outside
    the opening is not excused.

    Where s6 is written. The exception qualifies the act the text forbids, not the occasion on
    which the text speaks: a vehicle that turns about wholly through an opening is a vehicle upon
    a divided highway that the section addresses and that complies with it. So the exception is a
    limb of the duty (`act → excused`) and not a conjunct of the applicability. This is the only
    reading on which the node's own `occasion_s6_outside` witness is `compliant`: as a conjunct of
    the applicability it would make that episode not applicable, the rule never being engaged.
    Nothing is narrowed by the choice — the same words, the same atoms, the same occasion — so no
    narrowing is declared for s6; the choice is reported in task_result.md.

    s3 and s4 are siblings of this node and are carried by no formula here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCornerHeadingChange : Term := .param "p.corner_heading_change"
def pTurnReversalTolerance : Term := .param "p.turn_reversal_tolerance"
def pTurnWindow : Term := .param "p.turn_window"
def pYawRateFloor : Term := .param "p.yaw_rate_floor"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- The occasion's `under_way`: the body's heading is changing, so the observation lies inside the
    turning and not before it began. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vV])) .ge pYawRateFloor

/-- s2 (trigger): the subject is upon a roadway of a highway divided into roadways by a physical
    barrier or dividing section — the dividing structure being the one it drives beside and not
    upon. -/
def uponDividedHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vV, .var "h"] [])
      (.existsRegion (.lit "roadway") "r"
        (.and (.atom "rel_occupies" [vV, .var "r"] [])
          (.existsRegion (.lit "median_or_divider") "d"
            (.not (.atom "rel_occupies" [vV, .var "d"] []))))))

/-- s6 (exception): the subject is within an opening of the dividing structure (the opening or the
    crossover) or within an intersection. -/
def throughOpeningOrIntersection : Formula :=
  .or
    (.existsRegion (.lit "median_or_divider") "o"
      (.and (.atom "st_median_or_divider_opening" [.var "o"] [])
        (.atom "rel_occupies" [vV, .var "o"] [])))
    (.existsRegion (.lit "intersection") "x"
      (.atom "rel_occupies" [vV, .var "x"] []))

/-- s5 (obligation): the act the text forbids — a turning to the left through the swing the
    reading sets, or a turning about so as to travel the way it came. -/
def act : Formula :=
  .or
    (.derived "drv_motion_left_turn" [vV] [pTurnWindow, pCornerHeadingChange])
    (.derived "drv_motion_u_turn" [vV] [pTurnWindow, pTurnReversalTolerance])

/-- s6 read `throughout` the occasion: the exception excuses only a turning made within the
    opening or the intersection at every observation of the window at which it was under way. -/
def excused : Formula :=
  .holdsFor .time pTurnWindow "v" (.implies underWay throughOpeningOrIntersection)

/-- Applicability: s2 (trigger): driven upon a divided highway; s6 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .not (.holdsFor .time pTurnWindow "v" (.not (.and underWay uponDividedHighway)))

/-- Obligation: s5 (obligation): or make any left turn, semicircular turn or U-turn, -/
def obligation : Formula := .implies act excused

def rule : Rule :=
  { id := "NRS_484B_227_1_o3"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "“any left turn” is read as a turning of the body through the swing the reading sets: a left turn is recognized from the heading the body passes through and not from the junction it is taken at, so a swing to the left below that figure — a bend taken on the roadway, a lane change — is not read as a turn. The reading is narrower than the words for a turn begun and abandoned."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o3

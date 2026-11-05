/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (sibling): must be driven only upon the right-hand roadway
    s4 (obligation): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn,
    s5 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.highway', 'st.roadway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived []
    s4: atoms ['st.median_or_divider', 'rel.occupies'], derived ['drv.motion.leftward_course_change', 'drv.motion.direction_reversal']
    s5: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each span is written:

    s1 — `clsSubject` is the admitted aggregate under its own id, `ru_aggregate` of the binder and
    `DEF-NRS-484A-320::vehicle`; the classes the definition covers are never spelled here.

    s2 — `drivenUponDividedHighway`: the subject's footprint overlaps a roadway (`rel_occupies`
    over the `roadway` quantifier), that roadway lies on a highway (`st_on_way`), and a dividing
    section or barrier lies on that same highway (`st_on_way` over the `median_or_divider`
    quantifier). Every variable is tied to the binder through that chain: `r` by occupancy, `h` by
    the roadway it carries, `d` by the way it lies on. The occasion reads the span
    `some_moment`, so it is `.not (.holdsFor .time p.turn_window … (.not (.and underWay s2)))`.

    s4 — two limbs under one `.not`. The first, `drivenWithinDivider`, re-states s2's whole
    selection of the way and its divider and adds the subject's footprint overlapping that
    divider: "driven over, across or within any dividing space, barrier or section". The second
    is the manoeuvre: `drv.motion.leftward_course_change` over p.turn_window with
    p.turn_min_course_change / p.turn_max_course_change, and `drv.motion.direction_reversal` over
    p.direction_reversal_window with p.direction_reversal_opposition_tolerance — each under
    `.rises`, so an act is judged once, at the observation at which it is recognized, as the
    record's obligation states.

    s5 — `throughOpeningOrAtJunction` re-states s2's selection of the way and its divider (the
    region a formula speaks of is selected again where it speaks of it) and reads, on that way,
    either a dividing section with an opening the subject's footprint overlaps
    (`st_median_or_divider_opening`, the crossover) or an intersection it overlaps
    (`st_intersection`). The occasion reads the span `throughout`, so it is
    `.holdsFor .time p.turn_window … (.implies underWay s5)`, negated into the applicability.

    occasion.under_way — `drv.motion.turning` of the subject with p.yaw_rate_tolerance, reading
    kin.yaw_rate: the observation at which the act is under way, told from one before it began by
    the subject's own change of heading.

  Narrowing declared on s4 (the duty's own span; see `narrowings`): the first limb reads the
  footprint overlapping the dividing section while the subject is also on a roadway of that way,
  because the divider is selected through the way the subject is driven upon, as the record
  selects it. A vehicle whose footprint has left every roadway of the way and lies wholly within
  the dividing section is therefore not read by that limb.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDirectionReversalOppositionTolerance : Term := .param "p.direction_reversal_opposition_tolerance"
def pDirectionReversalWindow : Term := .param "p.direction_reversal_window"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2 (trigger): the subject's footprint overlaps a roadway, that roadway lies on a highway, and
    a physical barrier or dividing section lies on that same highway — "driven upon a divided
    highway". -/
def drivenUponDividedHighway : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "r", .var "h"] [])
          (.existsRegion (.lit "median_or_divider") "d"
            (.atom "st_on_way" [.var "d", .var "h"] [])))))

/-- s4, first limb: s2's selection again, and the subject's footprint overlapping that dividing
    space, barrier or section — "driven over, across or within". -/
def drivenWithinDivider : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "r", .var "h"] [])
          (.existsRegion (.lit "median_or_divider") "d"
            (.and (.atom "st_on_way" [.var "d", .var "h"] [])
                  (.atom "rel_occupies" [vSubject, .var "d"] []))))))

/-- s5 (exception): s2's selection of the way and its divider again, and the subject's footprint
    within an opening or crossover of a dividing section of that way, or within an intersection on
    it. -/
def throughOpeningOrAtJunction : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "r", .var "h"] [])
          (.and
            (.existsRegion (.lit "median_or_divider") "d"
              (.atom "st_on_way" [.var "d", .var "h"] []))
            (.or
              (.existsRegion (.lit "median_or_divider") "o"
                (.and (.atom "st_on_way" [.var "o", .var "h"] [])
                  (.and (.atom "st_median_or_divider_opening" [.var "o"] [])
                        (.atom "rel_occupies" [vSubject, .var "o"] []))))
              (.existsRegion (.lit "intersection") "x"
                (.and (.atom "st_on_way" [.var "x", .var "h"] [])
                      (.atom "rel_occupies" [vSubject, .var "x"] []))))))))

/-- The occasion's `under_way`: the subject's heading is changing, so the act of turning is under
    way at this observation. -/
def underWay : Formula := .derived "drv_motion_turning" [vSubject] [pYawRateTolerance]

/-- A span read at some moment while the act is under way. -/
def atSomeMomentOfAct (φ : Formula) : Formula :=
  .not (.holdsFor .time pTurnWindow "subject" (.not (.and underWay φ)))

/-- A span read throughout the act. -/
def throughoutAct (φ : Formula) : Formula :=
  .holdsFor .time pTurnWindow "subject" (.implies underWay φ)

/-- "any left turn", at the observation at which it is recognized. -/
def leftTurn : Formula :=
  .derived "drv_motion_leftward_course_change" [vSubject]
    [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance]

/-- "any semicircular turn or U-turn", at the observation at which it is recognized. -/
def turnAbout : Formula :=
  .derived "drv_motion_direction_reversal" [vSubject]
    [pDirectionReversalWindow, pDirectionReversalOppositionTolerance, pMotionSpeedTolerance]

/-- Applicability: s2 (trigger): driven upon a divided highway; s5 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .and (atSomeMomentOfAct drivenUponDividedHighway)
       (.not (throughoutAct throughOpeningOrAtJunction))

/-- Obligation: s4 (obligation): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn, -/
def obligation : Formula :=
  .not (.or drivenWithinDivider (.or (.rises leftTurn) (.rises turnAbout)))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "The limb \"driven over, across or within any dividing space, barrier or section\" reads the footprint overlapping a dividing section of the way the subject is driven upon, the divider being selected through that way as the record selects it: a vehicle whose footprint has left every roadway of the way and lies wholly within the dividing section is not read by this limb."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2

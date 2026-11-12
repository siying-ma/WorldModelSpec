/-
  NRS_484B_227_1_o3 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (subject): Every vehicle
    d2 (trigger): driven upon a divided highway
    d3 (sibling): must be driven only upon the right-hand roadway
    d4 (boilerplate): and
    d5 (sibling): must not be driven over, across or within any dividing space, barrier or section
    d6 (obligation): or make any left turn, semicircular turn or U-turn,
    d7 (exception): except through an opening in the barrier or dividing section or space
    d8 (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'st.roadway', 'rel.occupies'], derived []
    d6: atoms [], derived ['drv.motion.left_turn', 'drv.motion.u_turn']
    d7: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    d8: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each is written:
    d1: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`, the binder's class.
    d6: the act, judged once at its recognition: `rises` of drv.motion.left_turn (p.turn_window,
        p.left_turn_min_angle, p.left_turn_max_angle) or `rises` of drv.motion.u_turn
        (p.turn_window, p.u_turn_min_angle, p.u_turn_max_angle). The two are alternative acts; each
        recognition is its own occasion ("semicircular turn" is read by drv.motion.u_turn, as the
        record maps it).
    Occasion (boundary window, p.turn_window): a span read `some_moment` is
        `¬ holdsFor time W ego ¬(U ∧ φ)`. U, the under_way element, is "the magnitude of ego's yaw
        rate (kin.yaw_rate) is at or above p.turn_yaw_tolerance at some observation in the window
        p.turn_window behind this one": the turn is under way from its first observation at that
        rate on, and stays under way through a pause of a multi-point turn. The record bounds that
        first observation by the window behind the recognition; the language has no reference to
        the recognition inside the inner window, so the onset is searched in the window of the same
        length behind each observation of the outer window (a past `since` would leave every
        observation before any yaw unknown, which the record does not intend).
    d2: a highway h (region quantifier of kind `highway`) on which a median or divider lies
        (`st_on_way md h`), and at some moment of the turn ego's footprint overlaps (`rel_occupies`)
        a roadway lying on h or a median or divider lying on h.
    d7: at some moment of the turn ego overlaps a median or divider lying on h with the opening
        attribute set (`st_median_or_divider_opening`).
    d8: at some moment of the turn ego overlaps an intersection lying on h (`st_on_way i h`); the
        crossover limb is the median with the opening attribute, already d7's formula.
    The obligation repeats the applicability's whole selection of h (divided, occupied during the
    turn) and keeps the choice among such highways; d7 and d8 are alternatives read at one
    `some_moment`, which is the disjunction of their own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLeftTurnMaxAngle : Term := .param "p.left_turn_max_angle"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pTurnWindow : Term := .param "p.turn_window"
def pTurnYawTolerance : Term := .param "p.turn_yaw_tolerance"
def pUTurnMaxAngle : Term := .param "p.u_turn_max_angle"
def pUTurnMinAngle : Term := .param "p.u_turn_min_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the highway, the regions ego overlaps on it, the median that divides it. -/
def vH : Arg := .var "h"
def vR : Arg := .var "r"
def vM : Arg := .var "m"
def vMd : Arg := .var "md"
def vO : Arg := .var "o"
def vI : Arg := .var "i"

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d6: the acts, each judged at its recognition (the concept rising). -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn" [vEgo] [pTurnWindow, pLeftTurnMinAngle, pLeftTurnMaxAngle]
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vEgo] [pTurnWindow, pUTurnMinAngle, pUTurnMaxAngle]
def recognized : Formula := .or (.rises leftTurn) (.rises uTurn)

/-- Under way: ego's heading changing at or above the tolerance at some observation of the turn
    window behind this one. -/
def yawing : Formula := .cmp (.abs (.measure "kin_yaw_rate" [vEgo])) .ge pTurnYawTolerance
def underWay : Formula := .not (.holdsFor .time pTurnWindow "ego" (.not yawing))

/-- A span read `some_moment` of the occasion: φ together with U at some observation of the window. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pTurnWindow "ego" (.not (.and underWay φ)))

/-- d2: h is divided — a median or divider lies on it. -/
def divided : Formula :=
  .existsRegion (.lit "median_or_divider") "md" (.atom "st_on_way" [vMd, vH] [])

/-- d2: ego's footprint overlaps a roadway or a median or divider lying on h. -/
def uponDivided : Formula :=
  .or (.existsRegion (.lit "roadway") "r"
        (.and (.atom "st_on_way" [vR, vH] []) (.atom "rel_occupies" [vEgo, vR] [])))
      (.existsRegion (.lit "median_or_divider") "m"
        (.and (.atom "st_on_way" [vM, vH] []) (.atom "rel_occupies" [vEgo, vM] [])))

/-- The selection of h: divided, and ego upon it at some moment of the turn. -/
def selection : Formula := .and divided (someMoment uponDivided)

/-- d7: ego overlaps a median or divider of h with the opening attribute set. -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "o"
    (.and (.atom "st_on_way" [vO, vH] [])
      (.and (.atom "st_median_or_divider_opening" [vO] []) (.atom "rel_occupies" [vEgo, vO] [])))

/-- d8: ego overlaps an intersection lying on h. -/
def atIntersection : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_on_way" [vI, vH] []) (.atom "rel_occupies" [vEgo, vI] []))

/-- Applicability: d2 (trigger): driven upon a divided highway; d7 (exception): except through an opening in the barrier or dividing section or space; d8 (exception): or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .and recognized (.existsRegion (.lit "highway") "h" selection)

/-- Obligation: d6 (obligation): or make any left turn, semicircular turn or U-turn, -/
def obligation : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and selection (someMoment (.or throughOpening atIntersection)))

def rule : Rule :=
  { id := "NRS_484B_227_1_o3"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o3

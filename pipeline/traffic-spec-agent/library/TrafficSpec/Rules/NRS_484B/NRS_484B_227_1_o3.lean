/-
  NRS_484B_227_1_o3 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): Every vehicle
    b (trigger): driven upon a divided highway
    c (sibling): must be driven only upon the right-hand roadway
    d (sibling): and must not be driven over, across or within any dividing space, barrier or section
    e (obligation): or make any left turn, semicircular turn or U-turn,
    f (exception): except through an opening in the barrier or dividing section or space
    g (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.median_or_divider'], derived []
    e: atoms [], derived ['drv.motion.left_turn', 'drv.motion.u_turn']
    f: atoms ['rel.occupies', 'st.median_or_divider'], derived []
    g: atoms ['rel.occupies', 'st.median_or_divider', 'st.intersection'], derived []

  How each is written.
    a: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    e (the act, the occasion's recognition): `drv_motion_left_turn subject` (window, turn_min,
       u_turn_min, yaw_tol) or `drv_motion_u_turn subject` (window, u_turn_min, yaw_tol). Each
       concept holds at its recognition only, so the rule engages at that observation.
    Occasion (boundary "window", window p.vehicle_turn_window): a span read `some_moment` is
       `.not (.holdsFor .time W subject (.not (.and U φ)))`. U, the under_way element ("its
       heading change over the window behind the observation", kin.yaw_rate through
       prim.heading_change), is written as: the subject's heading change over the window behind
       the observation (prim_heading_change, which integrates kin_yaw_rate) is non-zero, i.e. the
       turn has begun by that observation. Before the turn's first yawing sample it is zero; from
       that sample to the recognition it is not.
    b (some_moment): some highway h (region kind `highway`, st.highway) such that at some
       observation of the window, U holding, the subject occupies h (rel_occupies) and some
       `median_or_divider` region d lies on h (st_on_way d h).
    f, g (some_moment, one disjunction at a common observation): at some observation of the
       window, U holding, the subject occupies a `median_or_divider` region o lying on h that
       carries the opening attribute (st_median_or_divider_opening o) — an opening or a crossover —
       or an `intersection` region i lying on h (st_on_way i h).
    Rule 3c: the obligation restates the applicability's whole selection of h (the same
       some_moment of occupancy of a divided h, under U) inside its own highway quantifier, and
       asks the exception's overlap on that h.
  No narrowing is chosen: the trigger and the exceptions are carried as the node maps them, and
  span e is the node's two concepts with the node's own reading of "semicircular turn".

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroDegrees : Term := .lit Q.zero .degree

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e: the act — a left turn, or a semicircular turn / U-turn (a reversal of direction). -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn" [vSubject] [pVehicleTurnWindow, pTurnHeadingMin, pUTurnHeadingMin, pTurnYawRateTol]
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vSubject] [pVehicleTurnWindow, pUTurnHeadingMin, pTurnYawRateTol]
def act : Formula := .or leftTurn uTurn

/-- Occasion, under_way: the subject's heading change over the window behind the observation
    (prim.heading_change, integrated from kin.yaw_rate) is non-zero: the turn has begun. -/
def underWay : Formula :=
  .cmp (.abs (.quantity "prim_heading_change" [vSubject] [pVehicleTurnWindow])) .gt zeroDegrees

/-- A span read `some_moment` over the occasion's window behind the recognition. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pVehicleTurnWindow "subject" (.not (.and underWay φ)))

/-- b at one observation: the subject occupies highway `h`, on which a median_or_divider lies. -/
def onDividedHighway : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var "h"] [])
    (.existsRegion (.lit "median_or_divider") "d" (.atom "st_on_way" [.var "d", .var "h"] []))

/-- b: the selection of h — at some observation of the window, the turn under way, the subject
    occupied h, a divided highway. -/
def selectsH : Formula := someMoment onDividedHighway

/-- f, g at one observation: the subject overlaps a divider region of h carrying the opening
    attribute (an opening or crossover), or an intersection lying on h. -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "o"
    (.and (.atom "rel_occupies" [vSubject, .var "o"] [])
      (.and (.atom "st_on_way" [.var "o", .var "h"] [])
        (.atom "st_median_or_divider_opening" [.var "o"] [])))
def atIntersection : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "rel_occupies" [vSubject, .var "i"] [])
      (.atom "st_on_way" [.var "i", .var "h"] []))

/-- Applicability: e recognized, and b at some observation of the window, the turn under way. -/
def applicability : Formula :=
  .and act (.existsRegion (.lit "highway") "h" selectsH)

/-- Obligation: on the h the applicability selected (its whole selection restated), at some
    observation of the window, the turn under way, the subject overlapped an opening / crossover
    of h's divider or an intersection lying on h (f, g). -/
def obligation : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and selectsH (someMoment (.or throughOpening atIntersection)))

def rule : Rule :=
  { id := "NRS_484B_227_1_o3"
    laws := ["NRS-484B-227-1"]
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

end TrafficSpec.Rules.NRS_484B_227_1_o3

/-
  NRS_484B_307_4a_o1 — NRS-484B-307-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green turn arrow alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (obligation): may proceed only in the direction indicated by the arrow signal so long as the arrow is illuminated,
    s4 (sibling): but the traffic must yield the right-of-way to pedestrians lawfully within the adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived []
    s3: atoms ['rel.occupies', 'st.intersection', 'dev.traffic_signal'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region', 'drv.motion.u_turn_through_region']

  How each span is written.
    Binder class (s2, 'vehicular traffic'): `ru_aggregate subject DEF-NRS-484A-285::traffic` and
      `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    Occasion (event boundary): the recognition is the subject's exit from an intersection i
      (`existsRegion "intersection" i`), `rises (not (rel_occupies subject i))`. The onset is its
      entry, `rises (rel_occupies subject i)`; the act stretch from the onset to the exit is the
      stretch over which `not (rises (rel_occupies subject i))` holds back from the exit, so a
      `since` with that left operand ends exactly at the latest entry (an earlier passage is never
      reached: its entry is a rise the chain cannot cross).
    s2 'facing the signal': a carrier c (`existsRegion "travel_region" c`) with
      `st_lane_enters c i`, occupied by the subject at its entry
      (`rises (rel_occupies subject i) ∧ rel_occupies subject c`), governed by a traffic signal d
      (`existsDevice "traffic_signal" d`, `dev_governs d c`).
    s1 'a green turn arrow alone', read `some_moment` over the act stretch: for dir among left,
      right and u_turn, `dev_traffic_signal_shows d green_arrow(dir)` with every other displayable
      state not shown (`not (dev_traffic_signal_shows d X)` for each concrete state X of the
      enumeration: the circular and flashing states, dark, and every other arrow). The `unknown`
      state (a face the source could not read) does not decide 'alone' false: where it is shown,
      whether the arrow is displayed alone is unknown (`definedWhen (not shows unknown)` around the
      arrow). The observation lies in [entry, exit]:
      `since (¬ rises occ_i) (arrowAlone dir ∧ since (¬ rises occ_i) entry_c)`.
    s3 'proceed only in the direction indicated': at the exit, the concept of the arrow's
      direction holds over i: left → drv.motion.left_turn_through_region, right →
      drv.motion.right_turn_through_region, u_turn → drv.motion.u_turn_through_region, with
      p.heading_since_step_carla_scene_graph, p.turn_heading_min, p.u_turn_heading_min (the
      u-turn concept takes the step and p.u_turn_heading_min only).
    Obligation: the applicability's whole selection (i exited, c entering i and occupied at the
      entry, d governing c, an arrow of dir alone during the passage) is written again, and the
      passage matches the direction of that selection's arrow. As the record states ("matching any
      one of them complies"), any selection whose arrow the passage matches complies.
    s4 is a sibling, not carried by this node.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_4a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantified variables: the intersection exited, the approach carrier, the signal. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- A conjunction of a non-empty list. -/
def conjAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .and φ (conjAll rest)

/-- A disjunction of a non-empty list. -/
def disjAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (disjAll rest)

/-- The subject's footprint overlaps region `r`. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- Signal `d` displays state `ind`. -/
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit ind] []

/-- Every concrete state a signal head may display (the `unknown` state apart). -/
def concreteStates : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark"
  , "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)"
  , "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)"
  , "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)"
  , "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)", "flashing_yellow_arrow(straight)"
  , "flashing_yellow_arrow(u_turn)" ]

/-- The turn directions a green turn arrow indicates. -/
def turnDirs : List String := ["left", "right", "u_turn"]

def greenArrow (dir : String) : String := "green_arrow(" ++ dir ++ ")"

/-- s1: `d` displays green_arrow(dir) and no other state; unknown where an unreadable face is shown. -/
def arrowAlone (dir : String) : Formula :=
  .and (conjAll ((concreteStates.filter (· != greenArrow dir)).map fun s => .not (shows s)))
       (.definedWhen (.not (shows "unknown")) (shows (greenArrow dir)))

/-- The subject's entry into i (the onset), from carrier c it occupies there. -/
def entryFrom : Formula := .and (.rises (occupies vI)) (occupies vC)

/-- No entry into i since: the act stretch runs back to the latest entry and no further. -/
def noNewEntry : Formula := .not (.rises (occupies vI))

/-- The subject's exit from i (the recognition). -/
def exitNow : Formula := .rises (.not (occupies vI))

/-- s1 read `some_moment` over the act stretch: the arrow of `dir` alone at some observation from
    the entry from c to now. -/
def arrowDuringPassage (dir : String) : Formula :=
  .since noNewEntry (.and (arrowAlone dir) (.since noNewEntry entryFrom))

/-- s3: the passage through i matches the direction `dir`, recognized at the exit. -/
def turnMatches (dir : String) : Formula :=
  if dir == "left" then
    .derived "drv_motion_left_turn_through_region" [vSubject, vI]
      [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]
  else if dir == "right" then
    .derived "drv_motion_right_turn_through_region" [vSubject, vI]
      [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]
  else
    .derived "drv_motion_u_turn_through_region" [vSubject, vI]
      [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin]

/-- The whole selection (s2, the occasion): an intersection i the subject exits now, a carrier c
    entering i, a traffic signal d governing c; `body` reads i, c and d. -/
def selection (body : Formula) : Formula :=
  .existsRegion (.lit "intersection") "i" (.and exitNow
    (.existsRegion (.lit "travel_region") "c" (.and (.atom "st_lane_enters" [vC, vI] [])
      (.existsDevice (.lit "traffic_signal") "d" (.and (.atom "dev_governs" [vD, vC] []) body)))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger): Where the signal is a green turn arrow alone: -/
def applicability : Formula :=
  selection (disjAll (turnDirs.map arrowDuringPassage))

/-- Obligation: s3 (obligation): may proceed only in the direction indicated by the arrow signal so long as the arrow is illuminated, -/
def obligation : Formula :=
  selection (disjAll (turnDirs.map fun dir => .and (arrowDuringPassage dir) (turnMatches dir)))

def rule : Rule :=
  { id := "NRS_484B_307_4a_o1"
    laws := ["NRS-484B-307-4a"]
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

end TrafficSpec.Rules.NRS_484B_307_4a_o1

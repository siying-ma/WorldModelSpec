/-
  NRS_484B_307_7a_o1 — NRS-484B-307-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a flashing yellow turn arrow, displayed alone or in combination with another signal:
    s2 (subject): Vehicular traffic facing the signal
    s3 (standard): is permitted to cautiously
    s4 (obligation): enter the intersection only to make the movement indicated by the arrow signal,
    s5 (exception): or other such movement as is permitted by other signal indications displayed at the same time.
    s6 (sibling): Such vehicular traffic
    s7 (sibling): must yield
    s8 (sibling): the right-of-way
    s9 (sibling): to pedestrians lawfully within the intersection or an adjacent crosswalk
    s10 (sibling): and yield
    s11 (sibling): the right-of-way
    s12 (sibling): to other traffic lawfully within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['dev.traffic_signal', 'rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region', 'drv.motion.u_turn_through_region']
    s5: atoms ['dev.traffic_signal'], derived []

  How each is written.
    Class (s2, 'Vehicular traffic'): both admitted aggregates, conjoined, as `ru_aggregate` on the
      subject with the aggregate ids.
    Occasion (event boundary). Onset: the entry into intersection i, `rises (rel_occupies subject i)`.
      Recognition, the observation judged: the exit, `rises (not (rel_occupies subject i))`.
      The act stretch, from the observed onset to the recognition judged, is
      `passage φ := since (not entry) φ`: φ at some observation from the latest entry into i up to
      the judged one (`since` settles at the entry itself, so no earlier observation is read).
    s2 ('facing the signal'): an intersection i, a travel region c with `st_lane_enters c i`, a
      traffic-signal head s with `dev_governs s c`; the entry into i was from c: at the entry,
      `since inI (occupies c ∧ ¬inI)`, which there reads exactly the observation before the entry.
    s1 (some_moment): `passage (shows s fya(left) ∨ fya(right) ∨ fya(u_turn))`; whatever else the
      head displays with it is not read ('alone or in combination').
    s4: the movement, read at the exit from the three through-region concepts (step the reviewed
      `p.heading_since_step_carla_scene_graph`), straight where none holds; it must be indicated by
      a flashing yellow turn arrow displayed during the passage: left arrow → left turn or U-turn,
      right arrow → right turn, u_turn arrow → U-turn. A straight passage is indicated by none.
    s3 (operationalization): at the entry observation of the passage (`passage (entry ∧ …)`), where
      the subject's speed exceeds p.halt_speed_tolerance, every road user y of the scene has no
      closest approach to it within p.conflict_horizon at a centre distance below
      p.conflict_centre_clearance. The subject itself is not excluded by `same`: its closest
      approach to itself is never defined (zero relative velocity), so it never counts.
    s5 (some_moment, read at the same observation as the arrow): for the movement made, some
      observation of the passage at which s displays a flashing yellow turn arrow of direction d
      together with another state (any state other than that arrow) permitting the movement:
      circular_green, circular_yellow or flashing_yellow permit every movement; a green, yellow or
      flashing yellow arrow of direction left the left turn and the U-turn, right the right turn,
      u_turn the U-turn, straight the straight movement.
      Placement: the record states that the duty does not apply where the exception holds, and
      the plan's occasion_s5 witness expects `compliant` for such a passage. The exception is
      therefore written as the first alternative of the obligation (the duty — indicated movement
      and cautious entry — is not imposed where it holds, and the passage is compliant), not as a
      conjunct of the applicability, which would report not_applicable.
    Obligation scope (3c): the obligation re-selects i, c and s with the whole selection of the
      applicability (facing, entry from c, exit, the arrow during the passage) and imposes the duty
      for every selection.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_7a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the intersection, the approach carrier, the signal head, another road user. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vY : Arg := .var "y"

/-- A disjunction of a non-empty list. -/
def disj : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (disj rest)

/-- The subject's footprint overlaps intersection i / carrier c. -/
def inI : Formula := .atom "rel_occupies" [vSubject, vI] []
def inC : Formula := .atom "rel_occupies" [vSubject, vC] []

/-- Onset: the entry into i. Recognition: the exit from i. -/
def entryI : Formula := .rises inI
def exitI : Formula := .rises (.not inI)

/-- φ at some observation from the latest entry into i to the judged observation. -/
def passage (φ : Formula) : Formula := .since (.not entryI) φ

/-- The entry into i was from c: at the entry, the observation before had c occupied and i not. -/
def enteredFromC : Formula := .and entryI (.since inI (.and inC (.not inI)))

/-- s2: c enters i and head s governs c. -/
def facing : Formula :=
  .and (.atom "st_lane_enters" [vC, vI] []) (.atom "dev_governs" [vS, vC] [])

/-- The head displays an indication. -/
def shows (x : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit x] []
def fya (d : String) : String := s!"flashing_yellow_arrow({d})"
def turnArrowDirs : List String := ["left", "right", "u_turn"]

/-- s1: a flashing yellow turn arrow. -/
def fyaTurn : Formula := disj (turnArrowDirs.map (fun d => shows (fya d)))

/-- The whole selection of i, c, s at a judged exit. -/
def selection : Formula :=
  .and facing (.and exitI (.and (passage enteredFromC) (passage fyaTurn)))

/-- s4: the movement made through i, recognized at the exit. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vSubject, vI]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vSubject, vI]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]
def uTurn : Formula :=
  .derived "drv_motion_u_turn_through_region" [vSubject, vI]
    [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin]
def straight : Formula := .and (.not leftTurn) (.and (.not rightTurn) (.not uTurn))

/-- s5: the states that permit each movement. -/
def permitsAll : List String := ["circular_green", "circular_yellow", "flashing_yellow"]
def arrowsOf (d : String) : List String :=
  [s!"green_arrow({d})", s!"yellow_arrow({d})", s!"flashing_yellow_arrow({d})"]
def permitsLeft : List String := permitsAll ++ arrowsOf "left"
def permitsRight : List String := permitsAll ++ arrowsOf "right"
def permitsU : List String := permitsAll ++ arrowsOf "left" ++ arrowsOf "u_turn"
def permitsStraight : List String := permitsAll ++ arrowsOf "straight"

/-- s5 at one observation: a flashing yellow turn arrow of direction d with another state,
    displayed at the same observation, permitting the movement. -/
def otherPermits (perm : List String) : Formula :=
  disj (turnArrowDirs.map fun d =>
    .and (shows (fya d)) (disj ((perm.filter (fun x => x != fya d)).map shows)))

/-- s5: the movement made is permitted by another indication displayed with the arrow at some
    observation of the passage. -/
def excepted : Formula :=
  disj [ .and leftTurn (passage (otherPermits permitsLeft))
       , .and rightTurn (passage (otherPermits permitsRight))
       , .and uTurn (passage (otherPermits permitsU))
       , .and straight (passage (otherPermits permitsStraight)) ]

/-- s4: the movement made is the one a flashing yellow turn arrow displayed during the passage
    indicates. -/
def indicated : Formula :=
  disj [ .and leftTurn (passage (shows (fya "left")))
       , .and rightTurn (passage (shows (fya "right")))
       , .and uTurn (passage (.or (shows (fya "left")) (shows (fya "u_turn")))) ]

/-- s3 at one observation: no traffic conflict while the subject moves. -/
def cautiousNow : Formula :=
  .implies (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.forallUser "y"
      (.not (.and (.derived "prim_closest_approach_within" [vSubject, vY] [pConflictHorizon])
                  (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vY] [pConflictHorizon])
                        .lt pConflictCentreClearance))))

/-- s3: the entry was cautious. -/
def cautiousEntry : Formula := passage (.and entryI cautiousNow)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s2 facing; s1 (trigger) at some observation of the passage, judged at the exit. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s" selection))

/-- Obligation: for every selection, s5 (exception: the duty is not imposed) or s4 with s3. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "s"
        (.implies selection (.or excepted (.and indicated cautiousEntry)))))

def rule : Rule :=
  { id := "NRS_484B_307_7a_o1"
    laws := ["NRS-484B-307-7a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "cautiously (the manner of the permitted entry)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: an entry is cautious where, at the observation of the entry, while the subject's speed is above the halt tolerance, no other road user's centre has a closest approach to the subject's centre, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance)"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_7a_o1

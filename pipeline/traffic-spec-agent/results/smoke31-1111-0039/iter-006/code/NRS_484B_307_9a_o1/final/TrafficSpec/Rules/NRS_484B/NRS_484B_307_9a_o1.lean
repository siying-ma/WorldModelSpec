/-
  NRS_484B_307_9a_o1 — NRS-484B-307-9a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (reference): Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],
    b3 (subject): vehicular traffic
    b4 (trigger): facing the signal
    b5 (trigger): may enter the intersection
    b6 (obligation): only to make the movement indicated by the green turn arrow,
    b7 (sibling): but must yield the right-of-way
    b9 (sibling): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.
    b11 (definitional): Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    b4: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    b5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    b6: atoms ['kin.yaw_rate', 'rel.occupies', 'st.intersection'], derived ['drv.motion.heading_change_since_entry', 'drv.motion.leaving_region']

  Compositions (span → node, as, map):
    b2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}

  How each span is written:
    b3: the binder class is `ru_aggregate x "DEF-NRS-484A-285::traffic"`; the applicability adds
        `not (ru_aggregate x "DEF-NRS-484A-165::pedestrian")` ('vehicular').
    b5/b6: the observation judged is x's leaving of an intersection i (`drv_motion_leaving_region`);
        the entry is the latest `drv_motion_entering_region (x, i)` before it, reached by
        `since (not entering) (entering ∧ …)`: no entry lies between, so x occupied i from that
        entry to the observation before the leaving, and an entry before the recording is unknown.
    b1/b4: at that entry, some travel region c with `rel_occupies (x, c)` and `st_lane_enters (c, i)`,
        and some traffic signal s with `dev_governs (s, c)` or `dev_governs (s, i)` showing
        `circular_red` and `green_arrow(left)` or `green_arrow(right)` (the attribute accessor
        `dev_traffic_signal_shows` of the claimed `dev.traffic_signal`; the quantifier ranges over
        traffic signals).
    b6: at the leaving, the heading change since the entry
        (`drv_motion_heading_change_since_entry (x, i)` with the profile's step) is at least
        p.turn_recognition_angle where a left arrow was displayed at the entry, at most its negation
        where a right arrow was; either suffices where both were.
    b2: `not (ruleApplies NRS_484B_307_9b_o1 {x ↦ x})`.
  The obligation restates the whole selection of i (leaving, latest entry, carrier, signal) for
  every intersection i, so it speaks of the region the applicability selected.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] []

/-- b3: 'vehicular' — x is not a pedestrian. -/
def notPedestrian : Formula :=
  .not (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] [])

def entering : Formula := .derived "drv_motion_entering_region" [vX, vI] []
def leaving : Formula := .derived "drv_motion_leaving_region" [vX, vI] []

def showsLeftArrow : Formula := .atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(left)"] []
def showsRightArrow : Formula := .atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(right)"] []

/-- b1/b4 at one observation: x occupies a carrier c entering i, and a traffic signal s governing
    c or i shows a steady red together with the green arrow(s) `arrow`. -/
def facingRedWith (arrow : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.atom "rel_occupies" [vX, vC] [])
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.existsDevice (.lit "traffic_signal") "s"
          (.and (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] []))
            (.and (.atom "dev_traffic_signal_shows" [vS, .lit "circular_red"] []) arrow)))))

/-- b5: at x's latest entry into i (no entry since), the situation `φ` held. -/
def atLatestEntry (φ : Formula) : Formula :=
  .since (.not entering) (.and entering φ)

def underLeft : Formula := atLatestEntry (facingRedWith showsLeftArrow)
def underRight : Formula := atLatestEntry (facingRedWith showsRightArrow)
def underAny : Formula := atLatestEntry (facingRedWith (.or showsLeftArrow showsRightArrow))

/-- The selection of i: x leaves it now, having entered it under a red with a green turn arrow. -/
def selected : Formula := .and leaving underAny

/-- b6: the heading change of x through i, since its entry. -/
def headingThrough : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b4 (trigger): facing the signal; b5 (trigger): may enter the intersection -/
def applicability : Formula :=
  .and notPedestrian
    (.and (.existsRegion (.lit "intersection") "i" selected)
      (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")])))

/-- Obligation: b6 (obligation): only to make the movement indicated by the green turn arrow, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies selected
      (.or (.and underLeft (.cmp headingThrough .ge pTurnRecognitionAngle))
        (.and underRight (.cmp headingThrough .le (.neg pTurnRecognitionAngle)))))

def rule : Rule :=
  { id := "NRS_484B_307_9a_o1"
    laws := ["NRS-484B-307-9a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["An advisory to drivers turning with the arrow about what opposing traffic faces at the same time; it permits, requires and forbids nothing, and no rule reads it."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o1

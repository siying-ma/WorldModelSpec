/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The driver of a vehicle
    s2 (condition): within an intersection
    s3 (condition): intending to turn to the left
    s4 (sibling): shall yield the right-of-way
    s5 (sibling): to any vehicle approaching from the opposite direction
    s6 (sibling): which is within the intersection
    s7 (sibling): or so close thereto as to constitute an immediate hazard,
    s8 (condition): but such driver, having so yielded
    s9 (condition): and having given a signal
    s10 (reference): when and as required,
    s11 (condition): may make such left turn
    s12 (subject): and the drivers of all other vehicles
    s13 (trigger): approaching the intersection from the opposite direction
    s14 (obligation): shall yield the right-of-way
    s15 (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s9: atoms ['sig.turn_indicator', 'sig.hand_signal', 'rel.occupies', 'st.travel_region', 'st.intersection', 'st.lane_enters'], derived ['drv.motion.entering_region']
    s11: atoms ['kin.yaw_rate', 'kin.speed', 'rel.occupies'], derived ['drv.motion.turning_left', 'drv.motion.heading_change_since_entry']
    s12: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s13: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.entering_region', 'drv.road.opposed_directions']
    s14: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s15: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    s8: NRS_484B_253_o1 as compliance map {'x': 'y'}

  How each is written:
    s12 / class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    s13 (applicability): some intersection i (quantifier kind `intersection`) and some travel region
      c (quantifier kind `travel_region`, so every carrier kind) with `rel_occupies x c`,
      `st_lane_enters c i` and `drv_motion_entering_region x i`. The carrier is also written as
      not being i itself (`not (same c i)`): an intersection is never an approach carrier of
      itself, so this excludes nothing the record selects; it only keeps the intersection, whose
      own `st_lane_enters` the source never records, from leaving the selection undecided.
    s14 (obligation): for every (i, c) the applicability's whole selection picks (written again),
      no road user y other than x is the vehicle making the left turn (s15) as defined below.
    s1 / s15: y with `ru_aggregate y "DEF-NRS-484A-320::vehicle"`, `not (same x y)`.
    s2 + "latest entry" + carrier c2 (s13's "from the opposite direction"): some travel region c2
      (not i itself, for the same reason as c) with `drv_road_opposed_directions c c2` and
      `since (rel_occupies y i ∧ o1) (drv_motion_entering_region y i ∧ rel_occupies y c2 ∧
      st_lane_enters c2 i ∧ o1)`: y occupies i now and at every observation since its latest entry
      into i, at which entry it occupied c2, an approach carrier of i.
    s8: o1 is `.rule "NRS_484B_253_o1" [("x", "y")]` (compliance), carried in both operands of the
      same `since`, so it holds at every observation from y's latest entry into i to now.
    s3: `.intent "int.left_turn" y i`, read at the judged observation.
    s11: `drv_motion_turning_left y [p.speed_resolution, p.yaw_rate_resolution]` or
      `drv_motion_heading_change_since_entry y i [p.heading_since_step_carla_scene_graph]` at least
      `p.turn_recognition_angle`.
    s9: `since (occ y c2 ∨ occ y i) (signal ∧ since (occ y c2 ∨ occ y i) (entering y c2))`, signal
      being `sig_turn_indicator y left` or `sig_hand_signal y left`: a signal at some observation
      since y last came onto c2, y on c2 or in i at every observation since that arrival.
    s10: residue (the node's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantified variables: the intersection, x's carrier, the turning vehicle, its carrier. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vY : Arg := .var "y"
def vC2 : Arg := .var "c2"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

def occupies (who r : Arg) : Formula := .atom "rel_occupies" [who, r] []
def entering (who r : Arg) : Formula := .derived "drv_motion_entering_region" [who, r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, vehicleAggregate] []

/-- s13: x enters i at this observation from an approach carrier c of i that it occupies. -/
def selection : Formula :=
  .and (occupies vX vC)
    (.and (.atom "st_lane_enters" [vC, vI] [])
      (.and (.not (.same vC vI))
        (entering vX vI)))

/-- Applicability: s13 (trigger): approaching the intersection from the opposite direction (the
    opposition is read on the turning vehicle, in the obligation). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c" selection)

/-- s8: y has so yielded — NRS_484B_253_o1 with its x as y complied with. -/
def soYielded : Formula := .rule "NRS_484B_253_o1" [("x", "y")]

/-- s2, s13, s8: y occupies i at every observation since its latest entry into i, at which entry it
    occupied c2, an approach carrier of i, and o1 complied with throughout. -/
def inSinceEntry : Formula :=
  .since (.and (occupies vY vI) soYielded)
    (.and (entering vY vI)
      (.and (occupies vY vC2)
        (.and (.atom "st_lane_enters" [vC2, vI] [])
          soYielded)))

/-- s3: the declared left turn at i. -/
def intendsLeft : Formula := .intent "int.left_turn" vY vI

/-- s11: y is making the turn. -/
def makingTurn : Formula :=
  .or (.derived "drv_motion_turning_left" [vY] [pSpeedResolution, pYawRateResolution])
    (.cmp (.quantity "drv_motion_heading_change_since_entry" [vY, vI] [pHeadingSinceStepCarlaSceneGraph])
      .ge pTurnRecognitionAngle)

/-- s9: y on c2 or in i. -/
def onApproach : Formula := .or (occupies vY vC2) (occupies vY vI)

/-- s9: a left signal. -/
def leftSignal : Formula :=
  .or (.atom "sig_turn_indicator" [vY, .lit "left"] [])
    (.atom "sig_hand_signal" [vY, .lit "left"] [])

/-- s9: a signal at some observation since y last came onto c2, y on c2 or in i ever since. -/
def signalled : Formula :=
  .since onApproach (.and leftSignal (.since onApproach (entering vY vC2)))

/-- s15: y is the vehicle making the left turn, owed precedence by x entering through c. -/
def turningVehicle : Formula :=
  .and (.not (.same vX vY))
    (.and (.atom "ru_aggregate" [vY, vehicleAggregate] [])
      (.existsRegion (.lit "travel_region") "c2"
        (.and (.not (.same vC2 vI))
          (.and (.derived "drv_road_opposed_directions" [vC, vC2] [pOpposedCarriersCosine])
            (.and inSinceEntry
              (.and intendsLeft
                (.and makingTurn signalled)))))))

/-- Obligation: s14 (obligation): shall yield the right-of-way — at every entry the applicability
    selects, no vehicle is making the left turn in i under the words' conditions. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies selection (.not (.existsUser "y" turningVehicle))))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := ["'when and as required' refers to the signalling requirements of a law outside this corpus (no bracketed id resolves it); the signal itself is read on s9."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

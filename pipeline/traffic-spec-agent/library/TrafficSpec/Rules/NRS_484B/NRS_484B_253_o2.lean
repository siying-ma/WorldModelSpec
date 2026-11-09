/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    sib1 (sibling): The driver of a vehicle within an intersection intending to turn to the left shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection or so close thereto as to constitute an immediate hazard,
    c1 (condition): but such driver, having so yielded
    c2 (condition): and having given a signal when and as required,
    c3 (condition): may make such left turn
    s1 (subject): and the drivers of all other vehicles approaching the intersection from the opposite direction
    ob1 (obligation): shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    c2: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    c3: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn']
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'st.intersection'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'rel.surface_gap', 'rel.contact', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []

  Compositions (span → node, as, map):
    c1: NRS_484B_253_o1 as compliance map {'v': 't'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s1 (the subject, `v`): the class of `v` is the admitted aggregate, written as the atom
  `ru_aggregate` with the aggregate id. "all other vehicles" is `.not (.same t v)` against the
  road user the duty is owed to. "approaching the intersection from the opposite direction" is the
  ontology's own reading: a carrier `cv` of kind `st.travel_region` that `v` occupies
  (`rel_occupies`) whose entrance end is the junction `j` (`st_lane_enters`), with that carrier's
  designated direction (`st_lane_direction`, read by component) opposed to the direction of the
  carrier `ct` by which the turning vehicle reached `j` — their dot product at or below the
  negative of `p.same_direction_cosine_tolerance`. Both quantifiers range over `travel_region` as
  the record names it; the junction `j` is quantified over `st.intersection`. The one thing the
  carriers are held apart from is the junction itself (`.not (.same cv j)`, `.not (.same ct j)`):
  by `st.lane_enters` a carrier is an approach to an intersection and enters one intersection at
  most, so the region entered is not one of the regions entering it. That is the ontology's own
  distinction, not a narrowing of the words: a junction region records no approach of its own, so
  without it a source that leaves occupancy unobserved would report the junction's missing lane
  record rather than the missing occupancy.

  c3 (the manoeuvre): `drv.motion.left_turn` on the turning vehicle, with the reviewed step bound
  of the run's acquisition profile, `p.turn_onset_yaw_rate` and `p.left_turn_angle`, conjoined
  with `rel_occupies` of a region of kind `st.intersection`, so the turn read is the one made in
  the junction the subject approaches.

  c2 (the signal): a left indication — `sig_turn_indicator` at `left` or `sig_hand_signal` at
  `left` — at some observation in the window `p.turn_signal_advance_window` behind the recognition
  of the turn. The recognition is `.rises` of the concept; the span is therefore read at that
  recognition, through `atLast` over the same window, and the "some observation in the window
  behind it" is `.not (.holdsFor … (.not …))`. Consequence, stated here because the language
  offers no unbounded past that stays decided: `atLast` finds the recognition only while it lies
  within `p.turn_signal_advance_window` behind the judged observation, so the duty is read over
  that stretch after the turn is recognized; an unbounded search into the past (`since`) is
  unknown wherever the recorded trace holds no recognition, which would leave a scene with a
  signal-less turn undecided instead of unengaged.

  c1 (having so yielded): the composition, `.rule "NRS_484B_253_o1" [("v", "t")]`, in the
  applicability as the record's `compliance` directs. Nothing of that rule is inlined.

  ob1 (the duty): "shall yield the right-of-way" is DEF-NRS-484A-210's precedence, read as the
  record's narrowing states, in the two observable ways the span's atoms give: the subject's body
  does not come into contact with the turning vehicle (`rel_contact`), and the clearance between
  them is held at or above `p.yield_min_clearance` — measured at the observation between the
  nearest points of the two bodies (`rel_surface_gap`) and, where their centres approach within
  `p.yield_conflict_horizon` (`prim_closest_approach_within`), as the centre distance at that
  closest approach (`prim_closest_approach_distance`). The duty is owed to every road user the
  applicability's own selection picks out, so that selection — the junction, the turn, the
  signal, the composed compliance and the opposed carriers — is written again in the obligation:
  the two formulas bind their own regions.

  The two readings this file chose on ob1 are declared as narrowings below.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The road user the duty is owed to, and the regions the formulas quantify over. -/
def tV : Arg := .var "t"
def jV : Arg := .var "j"
def cvV : Arg := .var "cv"
def ctV : Arg := .var "ct"

/-- The admitted aggregate of the node's class element, by its id. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnAngle : Term := .param "p.left_turn_angle"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pTurnOnsetYawRate : Term := .param "p.turn_onset_yaw_rate"
def pTurnSignalAdvanceWindow : Term := .param "p.turn_signal_advance_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, aggVehicle] []

/-- c3: the turning vehicle has turned to the left, by the concept of the catalogue. -/
def leftTurnMade : Formula :=
  .derived "drv_motion_left_turn" [tV]
    [pHeadingSinceStepCarlaSceneGraph, pTurnOnsetYawRate, pLeftTurnAngle]

/-- c3: that turn is the one made in the junction `j`, whose region the vehicle's footprint
    overlaps. -/
def turnsLeftInJunction : Formula :=
  .and (.atom "st_intersection" [jV] [])
    (.and (.atom "rel_occupies" [tV, jV] []) leftTurnMade)

/-- c2: a left indication, by the turn indicator or by the arm. -/
def leftIndication : Formula :=
  .or (.atom "sig_turn_indicator" [tV, .lit "left"] [])
      (.atom "sig_hand_signal" [tV, .lit "left"] [])

/-- c2: the signal given when and as required — a left indication at some observation in the
    window `p.turn_signal_advance_window` behind the recognition of the turn. -/
def signalGivenForTurn : Formula :=
  .atLast .time pTurnSignalAdvanceWindow "t" (.rises leftTurnMade)
    (.not (.holdsFor .time pTurnSignalAdvanceWindow "t" (.not leftIndication)))

/-- s1: a carrier's designated direction, by component. -/
def laneDirX (c : Arg) : Term := .measure "st_lane_direction" [c, .lit "x"]
def laneDirY (c : Arg) : Term := .measure "st_lane_direction" [c, .lit "y"]

/-- s1: the two carriers' designated directions are opposed. -/
def opposedCarriers : Formula :=
  .cmp (.add (.mul (laneDirX cvV) (laneDirX ctV)) (.mul (laneDirY cvV) (laneDirY ctV)))
    .le (.neg pSameDirectionCosineTolerance)

/-- s1: the subject approaches `j` through a carrier of its own whose designated direction is
    opposed to that of the carrier by which the turning vehicle reached `j`. -/
def approachesFromOppositeDirection : Formula :=
  .existsRegion (.lit "travel_region") "cv"
    (.and (.atom "st_travel_region" [cvV] [])
      (.and (.not (.same cvV jV))
        (.and (.atom "rel_occupies" [vV, cvV] [])
          (.and (.atom "st_lane_enters" [cvV, jV] [])
            (.existsRegion (.lit "travel_region") "ct"
              (.and (.atom "st_travel_region" [ctV] [])
                (.and (.not (.same ctV jV))
                  (.and (.atom "rel_occupies" [tV, ctV] [])
                    (.and (.atom "st_lane_enters" [ctV, jV] []) opposedCarriers)))))))))

/-- The road user the duty is owed to: another vehicle of the aggregate making, in the junction
    `j` the subject approaches from the opposite direction, the signalled left turn it has
    yielded for (c1, c2, c3, s1). -/
def turningVehicle : Formula :=
  .and (.not (.same tV vV))
    (.and (.atom "ru_aggregate" [tV, aggVehicle] [])
      (.existsRegion (.lit "intersection") "j"
        (.and turnsLeftInJunction
          (.and signalGivenForTurn
            (.and (.rule "NRS_484B_253_o1" [("v", "t")])
                  approachesFromOppositeDirection)))))

/-- Applicability: c1 (condition): but such driver, having so yielded; c2 (condition): and having given a signal when and as required,; c3 (condition): may make such left turn -/
def applicability : Formula := .existsUser "t" turningVehicle

/-- ob1: the subject is itself proceeding. -/
def subjectProceeding : Formula := .cmp (.measure "kin_speed" [vV]) .gt zeroSpeed

/-- ob1: the gap between the nearest points of the two bodies at this observation. -/
def nearestPointGap : Term := .measure "rel_surface_gap" [vV, tV]

/-- ob1: the centres approach each other within the horizon. -/
def centresApproach : Formula :=
  .derived "prim_closest_approach_within" [vV, tV] [pYieldConflictHorizon]

/-- ob1: the centre distance at that closest approach. -/
def closestApproachDistance : Term :=
  .quantity "prim_closest_approach_distance" [vV, tV] [pYieldConflictHorizon]

/-- ob1: the subject grants precedence to the turning vehicle. -/
def grantsPrecedence : Formula :=
  .and (.not (.atom "rel_contact" [vV, tV] []))
    (.or (.not subjectProceeding)
      (.and (.cmp nearestPointGap .ge pYieldMinClearance)
        (.or (.not centresApproach)
             (.cmp closestApproachDistance .ge pYieldMinClearance))))

/-- Obligation: ob1 (obligation): shall yield the right-of-way to the vehicle making the left turn. -/
def obligation : Formula := .forallUser "t" (.implies turningVehicle grantsPrecedence)

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "Granting precedence is read as a duty on the subject's own proceeding: where the subject's speed is zero it grants precedence by standing, and the clearance bounds are read on a subject that is itself moving. Contact is forbidden whether or not the subject moves."
          kind := "reading" }
      , { span := "ob1"
          why := "The clearance the span's atoms measure is bounded in both of the ways they give, each at p.yield_min_clearance: the gap between the nearest points of the two bodies at the observation (rel.surface_gap), and, where the centres approach within p.yield_conflict_horizon, the centre distance at that closest approach (prim.closest_approach_distance), which is undefined where they do not approach and then bounds nothing."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

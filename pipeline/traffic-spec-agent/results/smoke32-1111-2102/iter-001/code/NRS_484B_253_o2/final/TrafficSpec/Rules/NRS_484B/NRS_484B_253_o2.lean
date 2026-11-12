/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (condition): The driver of a vehicle
    f2 (condition): within an intersection
    f3 (condition): intending to turn to the left
    f4 (sibling): shall yield
    f5 (sibling): the right-of-way
    f6 (sibling): to any vehicle approaching from the opposite direction
    f7 (sibling): which is within the intersection
    f8 (sibling): or so close thereto as to constitute an immediate hazard,
    f9 (boilerplate): but such driver,
    f10 (condition): having so yielded
    f11 (condition): and having given a signal when and as required,
    f12 (condition): may make such left turn
    f13 (subject): and the drivers of all other vehicles approaching the intersection from the opposite direction
    f14 (obligation): shall yield
    f15 (standard): the right-of-way
    f16 (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['st.intersection', 'rel.occupies'], derived []
    f11: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    f12: atoms [], derived ['drv.motion.turning_left']
    f13: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.lane_direction', 'st.travel_region', 'rel.occupies'], derived []
    f14: atoms [], derived ['drv.motion.at_rest']
    f16: atoms [], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    f10: NRS_484B_253_o1 as compliance map {'ego': 't'}

  How each is written:
    f1, f13 (class): ru_aggregate DEF-NRS-484A-320::vehicle, of ego (its binder class) and of t.
    f2: rel_occupies(t, i) for an `intersection` region i.
    f3: intent int.left_turn of t at i, read at the judged observation.
    f13 "approaching the intersection": ego occupies a `travel_region` ce with st_lane_enters(ce, i).
      The record's "does not overlap i, or enters i from it" splits that occupation into the case
      outside i and the case of entering i from ce; together they are the occupation itself, so
      no further leaf is written. "From the opposite direction": the st_lane_direction vectors of
      ce and of t's approach carrier ct have a dot product below -p.opposite_direction_tolerance.
    f2/f10 "entered i from c_t": `since (occupies t i ∧ o1) (occupies t ct ∧ ¬ occupies t i)`.
      t occupied ct outside i, and since then it has occupied i and complied with NRS_484B_253_o1
      (map ego ↦ t) at every observation, the judged observation included.
    f11: `since (¬ rises (occupies t ct)) (sig_turn_indicator t left ∨ sig_hand_signal t left)`.
      This is a left signal at some observation since t's latest stretch on ct began.
    f12, f16: drv_motion_turning_left(t) with p.turn_yaw_tolerance and p.rest_speed_tolerance.
    f14, f15: ego at rest (drv_motion_at_rest), or the record's whole selection again with the
      conflict conjoined: for no selected t do prim_closest_approach_within(ego, t) and
      prim_closest_approach_distance(ego, t) < p.conflict_clearance both hold, the horizon being
      p.conflict_horizon.
  No narrowing is chosen.

  Defect (see task_result.md): the f15 conflict test is symmetric, and NRS_484B_253_o1 judges
  t's yielding by the same kind of test. So at the observation where ego is in conflict with the
  turning t, t has not complied with o1, and f10 as composed (compliance at every observation
  since entry, the judged one included) makes the duty impossible to violate.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pTurnYawTolerance : Term := .param "p.turn_yaw_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The quantified variables: the intersection, ego's approach carrier, the left-turning vehicle
    and the carrier it entered the intersection from. -/
def vI : Arg := .var "i"
def vCe : Arg := .var "ce"
def vT : Arg := .var "t"
def vCt : Arg := .var "ct"

/-- f1, f13: a vehicle of the admitted aggregate. -/
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- f13: carrier `c`'s entrance end is the intersection `i`. -/
def entersI (c : Arg) : Formula := .atom "st_lane_enters" [c, vI] []

def dir (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]

/-- f13 "from the opposite direction": the designated directions of ego's carrier and of the
    carrier t entered from have a dot product below minus the tolerance. -/
def opposed : Formula :=
  .cmp (.add (.mul (dir vCe "x") (dir vCt "x")) (.mul (dir vCe "y") (dir vCt "y"))) .lt
    (.neg pOppositeDirectionTolerance)

/-- f12, f16: t is making the left turn. -/
def turningLeft : Formula :=
  .derived "drv_motion_turning_left" [vT] [pTurnYawTolerance, pRestSpeedTolerance]

/-- f11: a left signal, by indicator or by arm. -/
def signalledLeft : Formula :=
  .or (.atom "sig_turn_indicator" [vT, .lit "left"] []) (.atom "sig_hand_signal" [vT, .lit "left"] [])

/-- f11: a left signal at some observation since t's latest stretch on its approach carrier
    began (no new start of that occupation after the signal). -/
def signalSinceApproach : Formula :=
  .since (.not (.rises (occupies vT vCt))) signalledLeft

/-- f2, f10: t entered i from `ct` (it occupied `ct` outside i, and has occupied i at every
    observation since) and has complied with NRS_484B_253_o1, as its ego, at every one of them. -/
def enteredComplying : Formula :=
  .since (.and (occupies vT vI) (.rule "NRS_484B_253_o1" [("ego", "t")]))
    (.and (occupies vT vCt) (.not (occupies vT vI)))

/-- f15: ego and t in conflict: their centres approach within the horizon, to a closest-approach
    distance below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vT] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vT] [pConflictHorizon]) .lt pConflictClearance)

/-- f14: ego at rest. -/
def atRest : Formula := .derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance]

/-- f1, f2, f3, f10, f11, f12, f13, f16: t is a vehicle other than ego within i, intending to
    turn left there, turning left, having entered i from an approach carrier `ct` opposed to ego's,
    complied with NRS_484B_253_o1 since, and signalled. -/
def tSelected : Formula :=
  .and
    (.and (.and (.not (.same vT vEgo)) (vehicle vT))
      (.and (.and (occupies vT vI) (.intent "int.left_turn" vT vI)) turningLeft))
    (.existsRegion (.lit "travel_region") "ct"
      (.and (.and (entersI vCt) opposed) (.and enteredComplying signalSinceApproach)))

/-- The record's whole selection: an intersection i, ego approaching it on a carrier `ce` whose
    entrance end is i, and a road user t of which `body` holds. -/
def selection (body : Formula) : Formula :=
  .existsRegion (.lit "intersection") "i" <|
    .existsRegion (.lit "travel_region") "ce" <|
      .and (.and (occupies vEgo vCe) (entersI vCe)) <|
        .existsUser "t" body

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := vehicle vEgo

/-- Applicability: f1 (condition): The driver of a vehicle; f2 (condition): within an intersection; f3 (condition): intending to turn to the left; f10 (condition): having so yielded; f11 (condition): and having given a signal when and as required,; f12 (condition): may make such left turn; f16 (condition): to the vehicle making the left turn. -/
def applicability : Formula := selection tSelected

/-- Obligation: f14 (obligation): shall yield; f15 (standard): the right-of-way — ego at rest, or
    in conflict with no vehicle t the applicability selects. -/
def obligation : Formula := .or atRest (.not (selection (.and tSelected conflict)))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\""
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity enter by degree through the projected velocities and positions."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

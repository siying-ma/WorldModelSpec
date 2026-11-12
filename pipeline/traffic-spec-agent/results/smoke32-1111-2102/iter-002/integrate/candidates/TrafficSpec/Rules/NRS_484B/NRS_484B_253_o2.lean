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
    f1, f13 (vehicle): `ru_aggregate` with DEF-NRS-484A-320::vehicle, for ego (its class) and t.
    f2: t `rel_occupies` the intersection `i` (a region quantifier of kind `intersection`).
    f3: `intent int.left_turn` of t at `i`, at the judged observation.
    f13 (approach): ego `rel_occupies` a carrier `ce` (kind `travel_region`) with `st_lane_enters ce i`;
      "from the opposite direction": t entered `i` from a carrier `ct` (kind `travel_region`) with
      `st_lane_enters ct i`, and the dot product of the `st_lane_direction`s of `ct` and `ce` is
      below minus p.opposite_direction_tolerance.
    f12, f16: `drv.motion.turning_left` of t now, inside `since turningLeft (rises turningLeft ∧ f10)`:
      continuous since its latest rise, the onset at which f10 is read.
    f10 (compliance with NRS_484B_253_o1, ego ↦ t): at the onset,
      `since (occupies t i ∧ rule o1) (occupies t ct ∧ ¬ occupies t i)` — from t's last observation
      on `ct` outside `i` up to and including the onset; not read during the turn.
    f11: `sig_turn_indicator` left or `sig_hand_signal` left at some observation with no rise of
      t's occupancy of `ct` after it: `since (¬ rises (occupies t ct)) signal`.
    f14, f15: ego `drv.motion.at_rest`, or for every `i`, `ce`, `t` of the whole selection re-bound
      (the same `selection` formula), not both `prim_closest_approach_within` (p.conflict_horizon)
      and `prim_closest_approach_distance` below p.conflict_clearance.
  No choice beyond the record's was needed; no narrowing is declared.

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

/-- The quantified variables: the intersection `i`, ego's approach carrier `ce`, the left-turning
    vehicle `t`, and the carrier `ct` from which `t` entered `i`. -/
def vI : Arg := .var "i"
def vCe : Arg := .var "ce"
def vT : Arg := .var "t"
def vCt : Arg := .var "ct"

def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def entersAt (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []

/-- f1, f13: a vehicle of the admitted aggregate. -/
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- f12, f16: turning to the left. -/
def turningLeft (x : Arg) : Formula :=
  .derived "drv_motion_turning_left" [x] [pTurnYawTolerance, pRestSpeedTolerance]

/-- f14: at rest. -/
def atRest (x : Arg) : Formula := .derived "drv_motion_at_rest" [x] [pRestSpeedTolerance]

/-- f13 "from the opposite direction": the designated directions of the two carriers have a dot
    product below minus the tolerance (the directions, not the headings). -/
def dirComp (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]
def opposed (c d : Arg) : Formula :=
  .cmp (.add (.mul (dirComp c "x") (dirComp d "x")) (.mul (dirComp c "y") (dirComp d "y")))
    .lt (.neg pOppositeDirectionTolerance)

/-- f11: a left signal, by indicator or by arm. -/
def signalledLeft (x : Arg) : Formula :=
  .or (.atom "sig_turn_indicator" [x, .lit "left"] []) (.atom "sig_hand_signal" [x, .lit "left"] [])

/-- f10 "having so yielded", read at the turn's onset: since an observation at which `t` was on
    `ct` and not in `i`, `t` has been in `i` and complied with NRS_484B_253_o1 (t as its ego). -/
def soYielded : Formula :=
  .since (.and (occupies vT vI) (.rule "NRS_484B_253_o1" [("ego", "t")]))
    (.and (occupies vT vCt) (.not (occupies vT vI)))

/-- f12: the turn under way, continuous since its observed onset, at which f10 is read. -/
def turnSinceOnset : Formula :=
  .since (turningLeft vT) (.and (.rises (turningLeft vT)) soYielded)

/-- f11: a left signal at some observation since t's latest stretch on `ct` began (no rise of its
    occupancy of `ct` after the signal). -/
def signalSinceStretch : Formula :=
  .since (.not (.rises (occupies vT vCt))) (signalledLeft vT)

/-- f13: t entered `i` from a carrier `ct` entering `i`, opposed to ego's `ce`. -/
def fromOpposedCarrier : Formula :=
  .existsRegion (.lit "travel_region") "ct"
    (.and (entersAt vCt vI)
      (.and (opposed vCt vCe)
        (.and turnSinceOnset signalSinceStretch)))

/-- f13: ego on a carrier `ce` whose entrance end is `i`. -/
def egoApproach : Formula := .and (occupies vEgo vCe) (entersAt vCe vI)

/-- f1, f2, f3, f10, f11, f12, f16: t other than ego, a vehicle, within `i`, intending to turn left
    at `i`, turning left now within a continuous turn begun after having so yielded and signalled. -/
def leftTurner : Formula :=
  .and (.not (.same vT vEgo))
    (.and (vehicle vT)
      (.and (occupies vT vI)
        (.and (.intent "int.left_turn" vT vI)
          (.and (turningLeft vT) fromOpposedCarrier))))

/-- The whole selection of `i`, `ce` and `t`, written once and used in both formulas. -/
def selection : Formula := .and egoApproach leftTurner

/-- f15: in conflict — the projected closest approach within the horizon, below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vT] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vT] [pConflictHorizon]) .lt pConflictClearance)

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := vehicle vEgo

/-- Applicability: f1 (condition): The driver of a vehicle; f2 (condition): within an intersection; f3 (condition): intending to turn to the left; f10 (condition): having so yielded; f11 (condition): and having given a signal when and as required,; f12 (condition): may make such left turn; f16 (condition): to the vehicle making the left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "ce"
      (.existsUser "t" selection))

/-- Obligation: f14 (obligation): shall yield; f15 (standard): the right-of-way -/
def obligation : Formula :=
  .or (atRest vEgo)
    (.forallRegion (.lit "intersection") "i"
      (.forallRegion (.lit "travel_region") "ce"
        (.forallUser "t" (.implies selection (.not conflict)))))

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

/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The driver of a vehicle
    s2 (condition): within an intersection
    s3 (condition): intending to turn to the left
    s4 (sibling): shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection or so close thereto as to constitute an immediate hazard,
    s5 (boilerplate): but such driver,
    s6 (condition): having so yielded
    s7 (condition): and having given a signal when and as required,
    s8 (condition): may make such left turn
    s9 (subject): and the drivers of all other vehicles
    s10 (trigger): approaching the intersection from the opposite direction
    s11 (obligation): shall yield
    s12 (standard): the right-of-way
    s13 (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s7: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s10: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction', 'st.intersection'], derived []
    s11: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']
    s13: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    s6: NRS_484B_253_o1 as compliance map {'x': 'y'}

  How each is written:
    s9   the binder x, class `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s10  an intersection i (`existsRegion intersection`) and a carrier cx (`existsRegion
         travel_region`) that x occupies with `st_lane_enters cx i` (`approachCarrier`); a carrier
         is never the intersection it enters, so the region i itself is set aside by `same` before
         its (unrecorded) entry is read. "From the opposite direction" is `opposed cx cy`: the dot
         product of the two carriers' `st_lane_direction` below −p.opposed_approach_cos_tolerance.
    s1   y is another road user (`not (same x y)`) of the vehicle aggregate.
    s2   `rel_occupies y i`.
    s3   `intent int.turn_left y i`, the declaration current at the judged observation.
    s13  `drv_motion_turning_left y` (p.yaw_rate_tolerance) while y occupies i (s2).
    s6   y's approach carrier cy is the carrier (`approachCarrier cy i`) it occupied at the
         observation its current occupancy of i rose; from that observation to the judged one y
         occupied i and complied with NRS_484B_253_o1 (x ↦ y): `since (occ y i ∧ o1)
         (rises (occ y i) ∧ occ y cy ∧ o1)`.
    s7   a left signal (`sig_turn_indicator left` or `sig_hand_signal left`) at some observation
         since y last came onto cy: `since (¬ rises (occ y cy)) (signal ∧ once (rises (occ y cy)))`,
         `once` written `since tt`.
    s8   residue (the node's).
    s11  at an observation at which x occupies cx and i and is moving (`drv_motion_moving`,
         p.motion_speed_tolerance), for every such selection (i, cx) and every y meeting the whole
         applicability selection (`turner`, bound again) —
    s12  — the centres of x and y do not reach a predicted closest approach within
         p.conflict_time_horizon (`prim_closest_approach_within`) at a centre distance below
         p.conflict_centre_clearance (`prim_closest_approach_distance`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOpposedApproachCosTolerance : Term := .param "p.opposed_approach_cos_tolerance"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of the vehicle aggregate (DEF-NRS-484A-320). -/
def vehicle (v : String) : Formula := .atom "ru_aggregate" [.var v, .lit "DEF-NRS-484A-320::vehicle"] []

/-- A road user's footprint overlaps a region. -/
def occ (a r : String) : Formula := .atom "rel_occupies" [.var a, .var r] []

/-- `c` is a directed approach carrier of intersection `i` (never `i` itself). -/
def approachCarrier (c i : String) : Formula :=
  .and (.not (.same (.var c) (.var i))) (.atom "st_lane_enters" [.var c, .var i] [])

/-- A component of a carrier's designated direction. -/
def dir (c k : String) : Term := .measure "st_lane_direction" [.var c, .lit k]

/-- The two carriers' designated directions are opposite. -/
def opposed (c c' : String) : Formula :=
  .cmp (.add (.mul (dir c "x") (dir c' "x")) (.mul (dir c "y") (dir c' "y"))) .lt
    (.neg pOpposedApproachCosTolerance)

/-- A left signal shown by the road user: its turn indicator or its arm. -/
def leftSignal (v : String) : Formula :=
  .or (.atom "sig_turn_indicator" [.var v, .lit "left"] [])
    (.atom "sig_hand_signal" [.var v, .lit "left"] [])

/-- `y` complied with NRS_484B_253_o1. -/
def yielded : Formula := .rule "NRS_484B_253_o1" [("x", "y")]

/-- Since its current occupancy of `i` began, `y` has occupied `i` and complied with
    NRS_484B_253_o1; at that onset it occupied `cy`. -/
def enteredFrom : Formula :=
  .since (.and (occ "y" "i") yielded)
    (.and (.rises (occ "y" "i")) (.and (occ "y" "cy") yielded))

/-- `y` showed a left signal at some observation since it last came onto `cy`. -/
def signalledOn : Formula :=
  let cameOn := Formula.rises (occ "y" "cy")
  .since (.not cameOn) (.and (leftSignal "y") (.since .tt cameOn))

/-- `y`'s approach carrier `cy`: an approach to `i`, opposed to `cx`, the one it entered `i` from. -/
def approachOfTurner : Formula :=
  .existsRegion (.lit "travel_region") "cy"
    (.and (approachCarrier "cy" "i")
      (.and (opposed "cx" "cy")
        (.and enteredFrom signalledOn)))

/-- The vehicle `y` making the left turn within `i`, approached from carrier `cy` opposed to `cx`. -/
def turner : Formula :=
  .and (.not (.same vX (.var "y")))
    (.and (vehicle "y")
      (.and (occ "y" "i")
        (.and (.intent "int.turn_left" (.var "y") (.var "i"))
          (.and (.derived "drv_motion_turning_left" [.var "y"] [pYawRateTolerance])
            approachOfTurner))))

/-- A predicted closest approach of the centres of `x` and `y` within the horizon, below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var "y"] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var "y"] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle "x"

/-- Applicability: s1 (condition): The driver of a vehicle; s2 (condition): within an intersection; s3 (condition): intending to turn to the left; s6 (condition): having so yielded; s7 (condition): and having given a signal when and as required,; s8 (condition): may make such left turn; s10 (trigger): approaching the intersection from the opposite direction; s13 (condition): to the vehicle making the left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "cx"
      (.and (occ "x" "cx")
      (.and (approachCarrier "cx" "i")
        (.existsUser "y" turner))))

/-- Obligation: s11 (obligation): shall yield; s12 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "cx"
      (.implies
        (.and (occ "x" "cx")
        (.and (approachCarrier "cx" "i")
        (.and (occ "x" "i")
          (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]))))
        (.forallUser "y" (.implies turner (.not conflict)))))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn_left"]
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: 'circumstances of direction, speed and proximity as to give rise to the danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false } ]
    residues := ["The permission to make the turn adds nothing to the condition: the vehicle yielded to is the one 'making the left turn' (s13), which already requires the turn under way."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2

/-
  NRS_484B_250_1 — NRS-484B-250-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): approaching an intersection
    s3 (obligation): shall yield
    s4 (standard): the right-of-way
    s5 (condition): to a vehicle which has entered the intersection
    s6 (condition): from a different highway.
    s7 (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    s8 (exception): this section does not apply at intersections controlled by official traffic-control devices
    s9 (exception): or to vehicles approaching each other from opposite directions,
    s10 (exception): when the driver of one of the vehicles is intending to
    s11 (exception): or is making a left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s3: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s6: atoms ['st.highway', 'st.on_way'], derived []
    s8: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction'], derived []
    s11: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    s7: NRS_484B_250_4_o1 as unless map {'x': 'x'} scopes s8
    s7: NRS_484B_250_4_o2 as unless map {'x': 'x'} scopes s8

  How each is written:
    s1: the binder class `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: some carrier c (`existsRegion travel_region`) that x occupies (`rel_occupies x c`) and whose
        entrance end is an intersection i (`existsRegion intersection`, `st_lane_enters c i`). An
        intersection is no carrier (the st.lane_enters contract: a carrier is a lane or a roadway-like
        directed segment), so c is also held to `not (st_intersection c)`; this states the contract,
        not a narrower reading, and keeps the intersection region (whose entry topology no source
        records) from being taken as its own approach.
    s5: some road user y, not x (`same`), of the vehicle aggregate, whose footprint overlaps i, with
        some carrier cy (not an intersection, as for c) such that `since (rel_occupies y i)
        (rel_occupies y cy ∧ st_lane_enters cy i)`: y has overlapped i continuously since an
        observation at which it occupied cy, a carrier entering i.
    s6: some highway h (`existsRegion highway`) on which cy lies (`st_on_way cy h`) and c does not.
    s9–s11: y is not counted where the dot product of `st_lane_direction` of c and cy (components
        `x`, `y`) is below `-p.opposed_approach_cos_tolerance` and x or y declares `int.turn_left`
        at i (`intent`, at the judged observation) or is turning left (`drv_motion_turning_left`
        with `p.yaw_rate_tolerance`) while occupying i.
    s8: i is controlled where some travel region r that is i (`same r i`) or enters i
        (`st_lane_enters r i`) is governed (`dev_governs`) by a traffic signal, a stop sign or a yield
        sign (one device quantifier per kind).
    s7: the two `unless` compositions are conjoined into s8: `not (ruleApplies NRS_484B_250_4_o1)`
        and `not (ruleApplies NRS_484B_250_4_o2)`, x ↦ x; the applicability negates the whole s8.
    s3/s4: the obligation restates the whole selection of c, i and y (with s6, the s9–s11 exception
        and s8/s7), for every such c and i: where x also occupies i and is moving
        (`drv_motion_moving`, `p.motion_speed_tolerance`), no such y has its centre and x's approach
        within `p.conflict_time_horizon` (`prim_closest_approach_within`) to a centre distance below
        `p.conflict_centre_clearance` (`prim_closest_approach_distance`).

  No choice beyond the record's own narrowings was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOpposedApproachCosTolerance : Term := .param "p.opposed_approach_cos_tolerance"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vC : Arg := .var "c"
def vI : Arg := .var "i"
def vY : Arg := .var "y"
def vCy : Arg := .var "cy"

def andAll : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (andAll rest)

def orAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (orAll rest)

/-- s1, s5, s9: membership of the vehicle aggregate. -/
def vehicle (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []

def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []
def enters (r i : Arg) : Formula := .atom "st_lane_enters" [r, i] []
/-- A carrier is never an intersection (st.lane_enters contract). -/
def notIntersection (r : Arg) : Formula := .not (.atom "st_intersection" [r] [])

/-- s2: x occupies carrier c whose entrance end is intersection i. -/
def approaches : Formula := andAll [notIntersection vC, occupies vX vC, enters vC vI]

/-- s8: some travel region that is i or enters i is governed by a traffic signal, stop sign or yield sign. -/
def governedBy (kind : String) : Formula :=
  .existsDevice (.lit kind) "d" (.atom "dev_governs" [.var "d", .var "r"] [])

def controlled : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.or (.same (.var "r") vI) (enters (.var "r") vI))
      (orAll [governedBy "traffic_signal", governedBy "stop_sign", governedBy "yield_sign"]))

/-- s8 with s7's `unless` compositions conjoined. -/
def s8 : Formula :=
  andAll [ controlled
         , .not (.ruleApplies "NRS_484B_250_4_o1" [("x", "x")])
         , .not (.ruleApplies "NRS_484B_250_4_o2" [("x", "x")]) ]

def dir (r : Arg) (k : String) : Term := .measure "st_lane_direction" [r, .lit k]

/-- s9: the designated directions of c and cy are opposite. -/
def opposed : Formula :=
  .cmp (.add (.mul (dir vC "x") (dir vCy "x")) (.mul (dir vC "y") (dir vCy "y")))
    .lt (.neg pOpposedApproachCosTolerance)

def turningLeftIn (u : Arg) : Formula :=
  .and (.derived "drv_motion_turning_left" [u] [pYawRateTolerance]) (occupies u vI)

/-- s9–s11: opposite approaches with x or y intending or making a left turn at i. -/
def leftTurnException : Formula :=
  .and opposed
    (orAll [ .intent "int.turn_left" vX vI
           , .intent "int.turn_left" vY vI
           , turningLeftIn vX
           , turningLeftIn vY ])

/-- s6: cy lies on a highway c does not lie on. -/
def differentHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vCy, .var "h"] []) (.not (.atom "st_on_way" [vC, .var "h"] [])))

/-- s5, s6, s9–s11: y, not x, a vehicle that has entered i from a carrier on a different highway,
    not excepted. -/
def enteredVehicle : Formula :=
  andAll [ .not (.same vX vY)
         , vehicle vY
         , occupies vY vI
         , .existsRegion (.lit "travel_region") "cy"
             (andAll [ notIntersection vCy
                     , .since (occupies vY vI) (.and (occupies vY vCy) (enters vCy vI))
                     , differentHighway
                     , .not leftTurnException ]) ]

/-- s4: the danger of a crash between x and y. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- Applicability: s2 (trigger): approaching an intersection; s5 (condition): to a vehicle which has entered the intersection; s6 (condition): from a different highway.; s8 (exception): this section does not apply at intersections controlled by official traffic-control devices; s9 (exception): or to vehicles approaching each other from opposite directions,; s10 (exception): when the driver of one of the vehicles is intending to; s11 (exception): or is making a left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.existsRegion (.lit "intersection") "i"
      (andAll [approaches, .not s8, .existsUser "y" enteredVehicle]))

/-- Obligation: s3 (obligation): shall yield; s4 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (.forallRegion (.lit "intersection") "i"
      (.implies
        (andAll [ approaches, .not s8, occupies vX vI
                , .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance] ])
        (.forallUser "y" (.implies enteredVehicle (.not conflict)))))

def rule : Rule :=
  { id := "NRS_484B_250_1"
    laws := ["NRS-484B-250-1"]
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
          convention := "Traffic-conflict technique: the danger of a crash between x and y is a predicted closest approach of their centres, under constant velocities (which carry direction, speed and proximity), within the time-to-collision horizon (prim.closest_approach_within) at a centre distance below the clearance (prim.closest_approach_distance)."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_1

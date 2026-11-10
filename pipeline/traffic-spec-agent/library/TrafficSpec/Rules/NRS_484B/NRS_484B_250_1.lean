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
    s1: the binder class, `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: `approaches` — x occupies a travel region c with `st_lane_enters c i`, i an intersection
        (quantifier kinds `intersection`, `travel_region`).
    s5: `hasEntered` — y (the aggregate, `¬ same y x`) occupies i and has occupied it continuously
        `since` an observation at which it occupied cy, a travel region with `st_lane_enters cy i`.
        cy, and the carrier ca of s8, are held to be no intersection (`¬ st_intersection`): a
        carrier (st.lane_enters' contract: a lane, roadway, shoulder or bicycle lane or path) is
        never an intersection, and an intersection region records no entrance, so without it every
        y in i (through cy = i) and every device governing another intersection (through ca = that
        intersection) would leave the selection unknown. This states nothing the record does not.
    s6: `fromDifferentHighway` — some highway w with `st_on_way cy w` and not `st_on_way c w`.
    s8 + s7: `deviceException` — a traffic signal, stop sign or yield sign (three device quantifiers)
        governs i, or a travel region ca with `st_lane_enters ca i`; conjoined (unless) with
        `¬ ruleApplies NRS_484B_250_4_o1 {x ↦ x}` and `¬ ruleApplies NRS_484B_250_4_o2 {x ↦ x}`.
        The applicability carries `¬ deviceException`.
    s9–s11: `leftTurnException` — the dot product of the `st_lane_direction` components of c and cy
        below −p.opposed_approach_cos_tolerance, and x or y has `int.turn_left` at i, or x is
        turning left while overlapping i, or y is turning left (y's overlap with i is already
        required by s5, so it is not restated there). A y it holds for is not counted.
    s3/s4: the obligation re-selects i, c and every counted y with their whole selection
        (applicability's s2, s5, s6, s8 with suspension, s9–s11), for every selected i and c: where x
        overlaps i and is moving (`drv_motion_moving`), no counted y has
        `prim_closest_approach_within x y horizon` with `prim_closest_approach_distance` below the
        clearance.
  No narrowing of this session's own: the record's narrowings (s1, s8 observable readings; s3)
  are the plan's.

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

/-- The other variables: the intersection `i`, x's approach carrier `c`, the other vehicle `y` and
    the carrier `cy` it entered from. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vY : Arg := .var "y"
def vCy : Arg := .var "cy"

def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []
def enters (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
def onWay (r w : Arg) : Formula := .atom "st_on_way" [r, w] []
def isVehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []
def moving (u : Arg) : Formula := .derived "drv_motion_moving" [u] [pMotionSpeedTolerance]
def turningLeft (u : Arg) : Formula := .derived "drv_motion_turning_left" [u] [pYawRateTolerance]
def direction (r : Arg) (k : String) : Term := .measure "st_lane_direction" [r, .lit k]
/-- A carrier is no intersection: an intersection region records no entrance of its own. -/
def notJunction (r : Arg) : Formula := .not (.atom "st_intersection" [r] [])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := isVehicle vX

/-- s2: x approaches i through c — it occupies a carrier whose entrance end is i. -/
def approaches : Formula := .and (occupies vX vC) (enters vC vI)

/-- s8: device `d` controls i — it governs i, or a carrier `ca` whose entrance end is i. -/
def governsJunction (d ca : String) : Formula :=
  .or (.atom "dev_governs" [.var d, vI] [])
    (.existsRegion (.lit "travel_region") ca
      (.and (notJunction (.var ca))
        (.and (enters (.var ca) vI) (.atom "dev_governs" [.var d, .var ca] []))))

/-- s8: a traffic signal, stop sign or yield sign controls i. -/
def controlledByDevice : Formula :=
  .or (.existsDevice (.lit "traffic_signal") "dsig" (governsJunction "dsig" "csig"))
    (.or (.existsDevice (.lit "stop_sign") "dstop" (governsJunction "dstop" "cstop"))
      (.existsDevice (.lit "yield_sign") "dyield" (governsJunction "dyield" "cyield")))

/-- s8 with s7: the device exception, suspended where subsection 4 (either obligation) applies to x. -/
def deviceException : Formula :=
  .and controlledByDevice
    (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("x", "x")]))
      (.not (.ruleApplies "NRS_484B_250_4_o2" [("x", "x")])))

/-- s6: cy lies on a highway that c does not lie on. -/
def fromDifferentHighway : Formula :=
  .existsRegion (.lit "highway") "w" (.and (onWay vCy (.var "w")) (.not (onWay vC (.var "w"))))

/-- s9: the designated directions of c and cy are opposed. -/
def opposedApproaches : Formula :=
  .cmp (.add (.mul (direction vC "x") (direction vCy "x")) (.mul (direction vC "y") (direction vCy "y")))
    .lt (.neg pOpposedApproachCosTolerance)

/-- s9–s11: opposed approaches, and x or y intends a left turn at i or is turning left within i
    (y's overlap with i is already required by its selection). -/
def leftTurnException : Formula :=
  .and opposedApproaches
    (.or (.intent "int.turn_left" vX vI)
      (.or (.intent "int.turn_left" vY vI)
        (.or (.and (turningLeft vX) (occupies vX vI)) (turningLeft vY))))

/-- s5: y, a vehicle other than x, overlaps i and has overlapped it since it occupied cy. -/
def hasEntered : Formula :=
  .and (isVehicle vY)
    (.and (.not (.same vY vX))
      (.and (occupies vY vI) (.since (occupies vY vI) (occupies vY vCy))))

/-- A vehicle counted by the applicability: entered, and not excepted by s9–s11. -/
def counted : Formula := .and hasEntered (.not leftTurnException)

/-- s5/s6: some carrier cy (no intersection) entering i from a different highway, and a vehicle y
    entered from it satisfying `φ`. -/
def otherVehicle (φ : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "cy"
    (.and (notJunction vCy)
      (.and (enters vCy vI) (.and fromDifferentHighway (.existsUser "y" φ))))

/-- s4: the danger of a crash — the centres' closest approach within the horizon, below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Applicability: s2 (trigger): approaching an intersection; s5 (condition): to a vehicle which has entered the intersection; s6 (condition): from a different highway.; s8 (exception): this section does not apply at intersections controlled by official traffic-control devices; s9 (exception): or to vehicles approaching each other from opposite directions,; s10 (exception): when the driver of one of the vehicles is intending to; s11 (exception): or is making a left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.and approaches (.and (.not deviceException) (otherVehicle counted))))

/-- Obligation: s3 (obligation): shall yield; s4 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies
        (.and approaches (.and (.not deviceException) (.and (occupies vX vI) (moving vX))))
        (.not (otherVehicle (.and counted conflict)))))

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

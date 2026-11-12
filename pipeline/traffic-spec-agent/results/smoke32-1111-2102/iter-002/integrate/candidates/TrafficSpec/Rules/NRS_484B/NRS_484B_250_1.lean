/-
  NRS_484B_250_1 — NRS-484B-250-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The driver of a vehicle
    e2 (trigger): approaching an intersection
    e3 (obligation): shall yield
    e4 (standard): the right-of-way
    e5 (condition): to a vehicle which has entered the intersection from a different highway.
    e6 (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    e7 (exception): this section does not apply at intersections controlled by official traffic-control devices
    e8 (exception): or to vehicles approaching each other from opposite directions,
    e9 (exception): when the driver of one of the vehicles is intending to
    e10 (exception): or is making a left turn.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e2: atoms ['st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived []
    e3: atoms [], derived ['drv.motion.at_rest']
    e5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway'], derived []
    e7: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    e8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.lane_direction', 'st.travel_region'], derived []
    e10: atoms [], derived ['drv.motion.turning_left']

  Compositions (span → node, as, map):
    e6: NRS_484B_250_4_o1 as unless map {'ego': 'ego'} scopes e7
    e6: NRS_484B_250_4_o2 as unless map {'ego': 'ego'} scopes e7

  How each span is written:
    e1: the binder class, `ru_aggregate ego DEF-NRS-484A-320::vehicle` (agency reading is the plan's).
    e2: `approaches`: an intersection i and a travel region c with `st_lane_enters c i`, and either
        ego occupies c and not i, or ego's occupancy of i rises at the judged observation and has
        held since an observation at which ego occupied c (`since`), i.e. ego enters i from c now.
        c ranges over travel regions as the record names them. An intersection is a travel
        region but never a carrier (st.lane_enters: a carrier is a lane or a kind refining it, a
        roadway, one-way roadway, shoulder or bicycle lane or path), and an intersection region
        carries no entrance record, so `st_lane_enters` reads unknown on it; c, c_b and the
        carrier a device governs are therefore stated not to be intersections (`st_intersection`,
        claimed by e2, e5 and e7). Without it a crossing region — the one entered, or a second
        one a device governs — would leave the verdict unknown wherever it is reached.
    e7 + e6: `controlled`: some traffic signal, stop sign or yield sign governs i, or governs a
        carrier entering i. Per the `unless` composition it is conjoined with
        `¬ruleApplies NRS_484B_250_4_o1` and `¬ruleApplies NRS_484B_250_4_o2`, and the applicability
        excludes the intersection selected only where that conjunction holds.
    Applicability: some i and c with `approaches` and not the e7/e6 exception (`selected`).
    Obligation: the whole selection (`selected`) is written again, for every selected i and c
        (the record states the duty at the intersection approached through each such carrier).
    e5: for every road user b other than ego, of the vehicle aggregate, and every travel region
        c_b (not an intersection) entering i: b occupies i and has done so since an observation at which it occupied
        c_b (`since`, the past operator the record names), and some highway h has c_b on it and
        not c (`st_on_way`).
    e8/e9/e10: the duty is lifted where c and c_b carry opposed directions — the dot product of the
        two `st_lane_direction` vectors below minus p.opposite_direction_tolerance — and ego or b
        declares int.left_turn at i (`intent`, read at the judged observation) or is turning left
        (drv.motion.turning_left with p.turn_yaw_tolerance, p.rest_speed_tolerance).
    e3 + e4: ego is at rest (drv.motion.at_rest, p.rest_speed_tolerance) or not in conflict with
        b: not both prim.closest_approach_within(ego, b, p.conflict_horizon) and
        prim.closest_approach_distance(ego, b, p.conflict_horizon) below p.conflict_clearance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_1

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- Quantified variables: the intersection, ego's approach carrier, the other vehicle, its
    approach carrier, a highway, a device and a carrier the device governs. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vB : Arg := .var "b"
def vCb : Arg := .var "cb"
def vH : Arg := .var "h"
def vD : Arg := .var "d"
def vCd : Arg := .var "cd"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pTurnYawTolerance : Term := .param "p.turn_yaw_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def entersAt (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
/-- A carrier is never an intersection (st.lane_enters's contract); the intersection region is a
    travel region with no entrance record, on which `st_lane_enters` reads unknown. -/
def carrier (c : Arg) : Formula := .not (.atom "st_intersection" [c] [])

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := vehicle vEgo

/-- e2: ego approaches i through carrier c — on c and not in i, or entering i from c now. -/
def approaches : Formula :=
  .and (carrier vC)
    (.and (entersAt vC vI)
      (.or (.and (occupies vEgo vC) (.not (occupies vEgo vI)))
           (.and (.rises (occupies vEgo vI)) (.since (occupies vEgo vI) (occupies vEgo vC)))))

/-- e7: device d governs i or a carrier entering i. -/
def governsHere : Formula :=
  .or (.atom "dev_governs" [vD, vI] [])
      (.existsRegion (.lit "travel_region") "cd"
        (.and (carrier vCd) (.and (entersAt vCd vI) (.atom "dev_governs" [vD, vCd] []))))

/-- e7: i is controlled by a traffic signal, a stop sign or a yield sign. -/
def controlled : Formula :=
  .or (.existsDevice (.lit "traffic_signal") "d" governsHere)
    (.or (.existsDevice (.lit "stop_sign") "d" governsHere)
         (.existsDevice (.lit "yield_sign") "d" governsHere))

/-- e7 with e6 (`unless`, scoping e7): the exception, suspended where subsection 4 applies to ego. -/
def deviceException : Formula :=
  .and controlled
    (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("ego", "ego")]))
          (.not (.ruleApplies "NRS_484B_250_4_o2" [("ego", "ego")])))

/-- The selection of i and c: ego approaches i through c and i is not excepted. -/
def selected : Formula := .and approaches (.not deviceException)

/-- Applicability: e2 (trigger): approaching an intersection; e5 (condition): to a vehicle which has entered the intersection from a different highway.; e7 (exception): this section does not apply at intersections controlled by official traffic-control devices; e8 (exception): or to vehicles approaching each other from opposite directions,; e9 (exception): when the driver of one of the vehicles is intending to; e10 (exception): or is making a left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" selected)

/-- e5: b has entered i from c_b — it occupies i, and has since an observation on c_b. -/
def hasEntered : Formula :=
  .and (occupies vB vI) (.since (occupies vB vI) (occupies vB vCb))

/-- e5: c_b lies on a highway on which c does not lie. -/
def fromDifferentHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vCb, vH] []) (.not (.atom "st_on_way" [vC, vH] [])))

def dirX (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "x"]
def dirY (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "y"]

/-- e8: c and c_b carry opposed designated directions. -/
def opposed : Formula :=
  .cmp (.add (.mul (dirX vC) (dirX vCb)) (.mul (dirY vC) (dirY vCb))) .lt (.neg pOppositeDirectionTolerance)

/-- e9/e10: ego or b intends to turn left at i, or is turning left. -/
def leftTurn : Formula :=
  .or (.or (.intent "int.left_turn" vEgo vI) (.intent "int.left_turn" vB vI))
    (.or (.derived "drv_motion_turning_left" [vEgo] [pTurnYawTolerance, pRestSpeedTolerance])
         (.derived "drv_motion_turning_left" [vB] [pTurnYawTolerance, pRestSpeedTolerance]))

/-- e5 with e8–e10: b is owed the right-of-way, having entered from c_b. -/
def owed : Formula :=
  .and (.not (.same vB vEgo))
    (.and (vehicle vB)
      (.and (carrier vCb)
        (.and (entersAt vCb vI)
          (.and hasEntered
            (.and fromDifferentHighway (.not (.and opposed leftTurn)))))))

/-- e4: ego and b in conflict. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vB] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vB] [pConflictHorizon]) .lt pConflictClearance)

/-- e3: ego yields — at rest, or not in conflict with b. -/
def yields : Formula :=
  .or (.derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance]) (.not conflict)

/-- Obligation: e3 (obligation): shall yield; e4 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies selected
        (.forallUser "b"
          (.forallRegion (.lit "travel_region") "cb" (.implies owed yields)))))

def rule : Rule :=
  { id := "NRS_484B_250_1"
    laws := ["NRS-484B-250-1"]
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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_1

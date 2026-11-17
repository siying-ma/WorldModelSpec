/-
  NRS_484B_250_2 — NRS-484B-250-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): When two vehicles
    b (trigger): enter an intersection
    c (trigger): from different highways
    d (standard): at approximately the same time,
    e (subject): the driver of the vehicle on the left
    f (obligation): shall yield
    g (standard): the right-of-way
    h (condition): to the vehicle on the right.
    i (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    j (exception): this section does not apply at intersections controlled by official traffic-control devices
    k (exception): or to vehicles approaching each other from opposite directions,
    l (exception): when the driver of one of the vehicles is intending to
    m (exception): or is making a left turn.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.region_geometry'], derived []
    c: atoms ['st.highway', 'st.on_way', 'st.lane_enters', 'st.travel_region'], derived []
    e: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.bearing'], derived []
    f: atoms ['kin.speed', 'rel.contact'], derived []
    h: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.bearing'], derived []
    j: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    k: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction'], derived []
    m: atoms ['kin.yaw_rate', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    i: NRS_484B_250_4_o1 as exception map {'subject': 'subject'}
    i: NRS_484B_250_4_o2 as exception map {'subject': 'subject'}

  How each is written.
    a, e, h: the subject's class and the other vehicle v's class are `ru_aggregate` with the
       aggregate id; the subject is "the vehicle on the left" exactly when v lies on its right
       (`rel_bearing … "right"`, lateral component negative).
    b: the arrival of a road user x at intersection X through carrier c is
       `rel_occupies x c ∧ rises (st_region_geometry_distance x X ≤ p.stop_point_tolerance)`
       (`arrival`); "has occupied c or X at every observation since" is the `since` whose
       anchor is that arrival (`heldSince`). X ranges over `intersection`, c over
       `travel_region`, the carrier tied to X by `st_lane_enters c X`.
    c: some `highway` h with `st_on_way c2 h` and not `st_on_way c1 h`.
    d: the time since each arrival is `sinceRise` of the arrival event (the latest one); the two
       differ by at most p.same_time_arrival_window.
    h (at the later arrival): `since (¬(arrS ∨ arrV)) ((arrS ∨ arrV) ∧ v on the right)` — the
       last observation at which either arrival happened is the later of the two arrivals, and
       the bearing is read there.
    f, g: the subject is not in contact with v, and it is not the case that the subject moves
       (kin_speed > p.halt_speed_tolerance) while the centres approach within p.conflict_horizon
       to a closest-approach distance below p.conflict_centre_clearance.
    j: X is controlled when a traffic signal, stop sign or yield sign governs X, or governs a
       travel region c with `st_lane_enters c X`; written as one region quantifier over c with
       `same c X ∨ st_lane_enters c X`, so "X itself or a carrier entering X" is one selection.
    k: the designated directions of c1 and c2 (`st_lane_direction`, unit vectors) have a dot
       product below −p.oncoming_heading_cos.
    l: `intent int.left_turn` of the subject or of v at X, at the judged observation.
    m: v's heading change since its latest entry into X (`headingSince` with onset
       `rel_occupies v X`, step p.heading_since_step_carla_scene_graph) is at least
       p.turn_heading_min and below p.u_turn_heading_min (left positive).
    i: `¬ ruleApplies` of each of NRS_484B_250_4_o1 / _o2 with subject ↦ subject, conjoined into
       the applicability.
    The obligation re-selects X and c1 with the applicability's whole selection (carrier entering
    X, arrival held since, X not controlled) and states the duty for every such pair and every v.

  Choices the record left open: none beyond the writing above (no narrowing declared).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vX : Arg := .var "X"
def vC1 : Arg := .var "c1"
def vC2 : Arg := .var "c2"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vH : Arg := .var "h"
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"
def pSameTimeArrivalWindow : Term := .param "p.same_time_arrival_window"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- a, e, h: membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- b: carrier `c` is an approach to X. -/
def entersX (c : Arg) : Formula := .atom "st_lane_enters" [c, vX] []

/-- b: the body of `x` is within the stop-point tolerance of X. -/
def nearX (x : Arg) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [x, vX]) .le pStopPointTolerance

/-- b: the arrival of `x` at X on carrier `c`: occupying `c`, its body comes within the tolerance
    of X, having not been within it at the observation before. -/
def arrival (x c : Arg) : Formula := .and (occupies x c) (.rises (nearX x))

/-- b: `x` arrived at X on `c` and has occupied `c` or X at every observation since. -/
def heldSince (x c : Arg) : Formula :=
  .since (.or (occupies x c) (occupies x vX)) (arrival x c)

/-- j: a device of `kind` governs the region `c`. -/
def governedBy (kind : String) : Formula :=
  .existsDevice (.lit kind) "d" (.atom "dev_governs" [vD, vC] [])

/-- j: X is controlled — a traffic signal, stop sign or yield sign governs X or a carrier
    entering X. -/
def controlled : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.or (.same vC vX) (entersX vC))
      (.or (governedBy "traffic_signal") (.or (governedBy "stop_sign") (governedBy "yield_sign"))))

/-- b, j: the selection of X and c1 for the subject. -/
def selection : Formula :=
  .and (entersX vC1) (.and (heldSince vSubject vC1) (.not controlled))

/-- c: c2 lies on a highway on which c1 does not lie. -/
def differentHighways : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vC2, vH] []) (.not (.atom "st_on_way" [vC1, vH] [])))

/-- d: the two arrivals no more than the same-time window apart (time since each arrival). -/
def sameTime : Formula :=
  .cmp (.abs (.sub (.sinceRise (arrival vSubject vC1)) (.sinceRise (arrival vV vC2))))
    .le pSameTimeArrivalWindow

/-- e, h: v lies on the subject's right at the later of the two arrivals. -/
def rightAtLaterArrival : Formula :=
  let arr : Formula := .or (arrival vSubject vC1) (arrival vV vC2)
  .since (.not arr) (.and arr (.atom "rel_bearing" [vSubject, vV, .lit "right"] []))

/-- k: c1's and c2's designated directions opposed. -/
def directionDot : Term :=
  .add (.mul (.measure "st_lane_direction" [vC1, .lit "x"]) (.measure "st_lane_direction" [vC2, .lit "x"]))
       (.mul (.measure "st_lane_direction" [vC1, .lit "y"]) (.measure "st_lane_direction" [vC2, .lit "y"]))

def opposed : Formula := .cmp directionDot .lt (.neg pOncomingHeadingCos)

/-- m: v's heading change since its latest entry into X. -/
def turnSinceEntry : Term :=
  .headingSince "v" pHeadingSinceStepCarlaSceneGraph (occupies vV vX)

def makingLeftTurn : Formula :=
  .and (.cmp turnSinceEntry .ge pTurnHeadingMin) (.cmp turnSinceEntry .lt pUTurnHeadingMin)

/-- k, l, m: the excepted pair. -/
def leftTurnPair : Formula :=
  .and opposed
    (.or (.intent "int.left_turn" vSubject vX)
      (.or (.intent "int.left_turn" vV vX) makingLeftTurn))

/-- a–e, h, k–m: v is a vehicle on the subject's right that arrived at X with it. -/
def owedVehicle : Formula :=
  .and (isVehicle vV)
    (.and (.not (.same vV vSubject))
      (.existsRegion (.lit "travel_region") "c2"
        (.and (entersX vC2)
          (.and (heldSince vV vC2)
            (.and differentHighways
              (.and sameTime
                (.and rightAtLaterArrival
                  (.not leftTurnPair))))))))

/-- g: the subject proceeds into a danger of a crash with v. -/
def proceeds : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

def dangerOfCrash : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- f, g: yield the right-of-way to v. -/
def yieldsTo : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vV] [])) (.not (.and proceeds dangerOfCrash))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: b (arrival at X on c1, held since), j (X not controlled), i (subsection 4). -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "intersection") "X" (.existsRegion (.lit "travel_region") "c1" selection))
    (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("subject", "subject")]))
      (.not (.ruleApplies "NRS_484B_250_4_o2" [("subject", "subject")])))

/-- Obligation: for every selected X, c1 and every vehicle owed the right-of-way, d, f, g. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c1"
      (.implies selection
        (.forallUser "v" (.implies owedVehicle yieldsTo))))

def rule : Rule :=
  { id := "NRS_484B_250_2"
    laws := ["NRS-484B-250-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "approximately the same time: the two arrivals at the intersection's edge are close enough in time that neither vehicle can clear before the other arrives"
          concepts := ["kin.time", "st.region_geometry"]
          params := ["p.same_time_arrival_window", "p.stop_point_tolerance"]
          convention := "arrival of each vehicle is the observation (kin.time) at which its body first comes within p.stop_point_tolerance of X on a carrier entering X; the two arrivals are at approximately the same time where their times differ by no more than p.same_time_arrival_window, a two-second headway"
          surrogate := false }
      , { standard := "the right-of-way: precedence owed where 'circumstances of direction, speed and proximity ... give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a danger of a crash exists where, under constant velocities, the two centres approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance; the subject proceeds where its speed exceeds p.halt_speed_tolerance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_2

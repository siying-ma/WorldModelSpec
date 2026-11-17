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
    a, e (binder class, and v's class): `ru_aggregate` with the aggregate id DEF-NRS-484A-320::vehicle.
    b (arrival): a road user x has arrived at intersection X on carrier c when, since the latest rise
      of `rel_occupies(x, c) ∧ st_region_geometry_distance(x, X) ≤ p.stop_point_tolerance` (the
      observation its body first came within the tolerance of X while on c), it has occupied c or X
      at every observation (`since`), with `st_lane_enters(c, X)`. X ranges over intersections, c
      over travel regions (`existsRegion`/`forallRegion`).
    j (control): a traffic signal, stop sign or yield sign (one device quantifier per kind) governs X,
      or governs a travel region c with `st_lane_enters(c, X)`. Written in the applicability as an
      exception, and repeated in the obligation's re-selection of X so that the obligation's X is the
      applicability's X (rule 3c).
    i: `.not (.ruleApplies …)` for NRS_484B_250_4_o1 and _o2, subject ↦ subject.
    Obligation: for every intersection X and carrier c1 re-selected as in the applicability, for every
      other road user v (`same` excludes the subject) of the aggregate, for every carrier c2 entering X
      on which v has arrived in the same way:
    c: some highway h with `st_on_way(c2, h)` and not `st_on_way(c1, h)`.
    d: |sinceRise(subject's arrival) − sinceRise(v's arrival)| ≤ p.same_time_arrival_window (kin.time
      through `sinceRise`).
    e, h ("at the later of the two arrivals"): at the latest observation at which either arrival rose
      (`since (¬(rises A_s ∨ rises A_v)) ((rises A_s ∨ rises A_v) ∧ rel_bearing(subject, v, right))`).
      Since each arrival is the latest rise of its own formula, the latest rise of either is the later
      of the two arrivals; no window is needed.
    k, l, m (the excepted pair): dot product of `st_lane_direction` of c1 and c2 (x, y components)
      below −p.oncoming_heading_cos, and (`intent int.left_turn` of the subject at X, or of v at X, at
      this observation, or v's `headingSince` since its latest rise of `rel_occupies(v, X)`, step
      p.heading_since_step_carla_scene_graph, in [p.turn_heading_min, p.u_turn_heading_min)).
    f, g (duty): not `rel_contact(subject, v)`, and not (kin_speed(subject) > p.halt_speed_tolerance
      ∧ prim_closest_approach_within(subject, v; p.conflict_horizon) ∧
      prim_closest_approach_distance(subject, v; p.conflict_horizon) < p.conflict_centre_clearance).

  No choice beyond the record's own was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

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

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- `x` occupies region `r`. -/
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- b: the arrival edge of `x` on carrier `c` at intersection `X`: on `c`, its body within the
    stop-point tolerance of `X`. -/
def atEdge (x c X : String) : Formula :=
  .and (occ x c)
    (.cmp (.measure "st_region_geometry_distance" [.var x, .var X]) .le pStopPointTolerance)

/-- b: `x` has arrived at `X` on `c` (the latest rise of `atEdge`) and has occupied `c` or `X` at
    every observation since; `c` enters `X`. -/
def arrived (x c X : String) : Formula :=
  .and (.atom "st_lane_enters" [.var c, .var X] [])
    (.since (.or (occ x c) (occ x X)) (.rises (atEdge x c X)))

/-- j: a device of kind `k` governs X or a travel region entering X. -/
def controlledBy (k : String) : Formula :=
  .existsDevice (.lit k) "d"
    (.or (.atom "dev_governs" [.var "d", .var "X"] [])
      (.existsRegion (.lit "travel_region") "c"
        (.and (.atom "st_lane_enters" [.var "c", .var "X"] [])
          (.atom "dev_governs" [.var "d", .var "c"] []))))

/-- j: X is controlled by a traffic signal, a stop sign or a yield sign. -/
def controlled : Formula :=
  .or (controlledBy "traffic_signal") (.or (controlledBy "stop_sign") (controlledBy "yield_sign"))

/-- Applicability: b (trigger): enter an intersection; j (exception); i (reference) as exceptions. -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "intersection") "X"
      (.and (.existsRegion (.lit "travel_region") "c1" (arrived "subject" "c1" "X"))
        (.not controlled)))
    (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("subject", "subject")]))
      (.not (.ruleApplies "NRS_484B_250_4_o2" [("subject", "subject")])))

/-- c: c2 lies on a highway on which c1 does not lie. -/
def differentHighways : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [.var "c2", .var "h"] [])
      (.not (.atom "st_on_way" [.var "c1", .var "h"] [])))

/-- d: the two arrivals no more than the window apart. -/
def sameTime : Formula :=
  .cmp (.abs (.sub (.sinceRise (atEdge "subject" "c1" "X")) (.sinceRise (atEdge "v" "c2" "X"))))
    .le pSameTimeArrivalWindow

/-- Either arrival rising here. -/
def eitherArrives : Formula :=
  .or (.rises (atEdge "subject" "c1" "X")) (.rises (atEdge "v" "c2" "X"))

/-- e, h: v on the subject's right at the later of the two arrivals. -/
def onRightAtLaterArrival : Formula :=
  .since (.not eitherArrives)
    (.and eitherArrives (.atom "rel_bearing" [vSubject, .var "v", .lit "right"] []))

/-- k: c1's and c2's designated directions opposed within the cosine bound. -/
def opposedApproaches : Formula :=
  .cmp
    (.add
      (.mul (.measure "st_lane_direction" [.var "c1", .lit "x"]) (.measure "st_lane_direction" [.var "c2", .lit "x"]))
      (.mul (.measure "st_lane_direction" [.var "c1", .lit "y"]) (.measure "st_lane_direction" [.var "c2", .lit "y"])))
    .lt (.neg pOncomingHeadingCos)

/-- m: v's heading change since its latest entry into X. -/
def vHeadingInX : Term := .headingSince "v" pHeadingSinceStepCarlaSceneGraph (occ "v" "X")

/-- l, m: the subject or v intends a left turn at X, or v is making one. -/
def leftTurnDeclaredOrMade : Formula :=
  .or (.intent "int.left_turn" vSubject (.var "X"))
    (.or (.intent "int.left_turn" (.var "v") (.var "X"))
      (.and (.cmp vHeadingInX .ge pTurnHeadingMin) (.cmp vHeadingInX .lt pUTurnHeadingMin)))

/-- The pair excepted by k–m. -/
def exceptedPair : Formula := .and opposedApproaches leftTurnDeclaredOrMade

/-- v is owed the right-of-way at X: the obligation's selection of v and c2. -/
def owed : Formula :=
  .and (.not (.same (.var "v") vSubject))
    (.and (.atom "ru_aggregate" [.var "v", aggVehicle] [])
      (.and (arrived "v" "c2" "X")
        (.and differentHighways
          (.and sameTime
            (.and onRightAtLaterArrival (.not exceptedPair))))))

/-- f, g: the subject yields: no contact with v, and it does not proceed in conflict with v. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
    (.not
      (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
        (.and (.derived "prim_closest_approach_within" [vSubject, .var "v"] [pConflictHorizon])
          (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "v"] [pConflictHorizon])
            .lt pConflictCentreClearance))))

/-- Obligation: d (standard): at approximately the same time,; f (obligation): shall yield; g (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c1"
      (.implies (.and (arrived "subject" "c1" "X") (.not controlled))
        (.forallUser "v"
          (.forallRegion (.lit "travel_region") "c2"
            (.implies owed yields)))))

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

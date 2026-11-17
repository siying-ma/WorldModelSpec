/-
  NRS_484B_250_1 — NRS-484B-250-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): The driver of a vehicle
    b (trigger): approaching an intersection
    c (obligation): shall yield
    d (standard): the right-of-way
    e (condition): to a vehicle which has entered the intersection
    f (condition): from a different highway.
    g (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    h (exception): this section does not apply at intersections controlled by official traffic-control devices
    i (exception): or to vehicles approaching each other from opposite directions,
    j (exception): when the driver of one of the vehicles is intending to
    k (exception): or is making a left turn.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    c: atoms ['kin.speed', 'rel.contact'], derived []
    e: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []
    f: atoms ['st.highway', 'st.on_way', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived []
    h: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    i: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction'], derived []
    k: atoms ['kin.yaw_rate', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    g: NRS_484B_250_4_o1 as exception map {'subject': 'subject'}
    g: NRS_484B_250_4_o2 as exception map {'subject': 'subject'}

  How each span is written:
    a: the binder class, `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    b: some travel region c1 and some intersection X with `rel_occupies subject c1` and
       `st_lane_enters c1 X` (`approach`).
    h: X is controlled where a traffic signal, a stop sign or a yield sign (one device quantifier
       per kind) governs X, or governs a travel region c with `st_lane_enters c X` (`controlled`);
       the applicability requires X not controlled.
    g: `¬ ruleApplies NRS_484B_250_4_o1` and `¬ ruleApplies NRS_484B_250_4_o2`, subject ↦ subject.
    The obligation re-selects c1 and X exactly as the applicability does (approach and not
    controlled) and states the duty for every such pair.
    e: every road user v other than the subject, of the admitted aggregate, occupying X now and
       continuously since (`since`) an observation at which f held.
    f: at that observation v occupied a travel region c2 with `st_lane_enters c2 X` lying on some
       highway h2 (`st_on_way c2 h2`) on which c1 does not lie. c2 ranges over travel regions other
       than X itself (`¬ same c2 X`): X is the intersection the carrier enters, never a carrier
       entering itself; this reads no fact and narrows nothing.
    i, j, k: the pair is excepted where the designated directions of c1 and c2 (unit components of
       `st_lane_direction`) have a dot product below minus p.oncoming_heading_cos, and either the
       subject or v declares int.left_turn at X at this observation, or v's heading change since its
       latest entry into X (`headingSince v` with the reviewed step parameter, over `rel_occupies v X`)
       is at least p.turn_heading_min and below p.u_turn_heading_min.
    c, d: the subject is not in contact with v, and it is not the case that the subject's speed
       exceeds p.halt_speed_tolerance while the closest approach to v lies within p.conflict_horizon
       at a centre distance below p.conflict_centre_clearance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate the node claims. -/
def vehicleAggregate : String := "DEF-NRS-484A-320::vehicle"

def isVehicle (x : String) : Formula := .atom "ru_aggregate" [.var x, .lit vehicleAggregate] []
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def enters (c x : String) : Formula := .atom "st_lane_enters" [.var c, .var x] []
def onWay (c h : String) : Formula := .atom "st_on_way" [.var c, .var h] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit vehicleAggregate] []

/-- b: the subject occupies carrier c1, whose entrance end is intersection X. -/
def approach : Formula := .and (occ "subject" "c1") (enters "c1" "X")

/-- h: a device of kind `k` governs X or a travel region entering X. -/
def controlledBy (k : String) : Formula :=
  .existsDevice (.lit k) "d"
    (.or (governs "d" "X")
      (.existsRegion (.lit "travel_region") "c" (.and (enters "c" "X") (governs "d" "c"))))

/-- h: X is controlled by a traffic signal, a stop sign or a yield sign. -/
def controlled : Formula :=
  .or (controlledBy "traffic_signal") (.or (controlledBy "stop_sign") (controlledBy "yield_sign"))

/-- The selection of c1 and X (b, h), shared by the applicability and the obligation. -/
def selected : Formula := .and approach (.not controlled)

/-- Applicability: b (trigger): approaching an intersection; e (condition): to a vehicle which has entered the intersection; f (condition): from a different highway.; h (exception): this section does not apply at intersections controlled by official traffic-control devices; i (exception): or to vehicles approaching each other from opposite directions,; j (exception): when the driver of one of the vehicles is intending to; k (exception): or is making a left turn. -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "travel_region") "c1" (.existsRegion (.lit "intersection") "X" selected))
    (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("subject", "subject")]))
          (.not (.ruleApplies "NRS_484B_250_4_o2" [("subject", "subject")])))

/-- f: v occupies carrier c2 entering X, on a highway h2 on which c1 does not lie. -/
def fromDifferentHighway : Formula :=
  .and (occ "v" "c2")
    (.and (enters "c2" "X")
      (.existsRegion (.lit "highway") "h2" (.and (onWay "c2" "h2") (.not (onWay "c1" "h2")))))

/-- One component of a carrier's designated direction (unit vector). -/
def dir (c comp : String) : Term := .measure "st_lane_direction" [.var c, .lit comp]

/-- i: the designated directions of c1 and c2 are opposed within p.oncoming_heading_cos. -/
def opposed : Formula :=
  .cmp (.add (.mul (dir "c1" "x") (dir "c2" "x")) (.mul (dir "c1" "y") (dir "c2" "y")))
    .lt (.neg pOncomingHeadingCos)

/-- k: v's heading change since its latest entry into X. -/
def headingInX : Term := .headingSince "v" pHeadingSinceStepCarlaSceneGraph (occ "v" "X")

/-- k: v is making a left turn in X. -/
def makingLeftTurn : Formula :=
  .and (.cmp headingInX .ge pTurnHeadingMin) (.cmp headingInX .lt pUTurnHeadingMin)

/-- i, j, k: the pair is excepted. -/
def excepted : Formula :=
  .and opposed
    (.or (.intent "int.left_turn" vSubject (.var "X"))
      (.or (.intent "int.left_turn" (.var "v") (.var "X")) makingLeftTurn))

/-- e, f with the exception i–k: v is a vehicle the subject must yield to. -/
def isProtected : Formula :=
  .and (.not (.same (.var "v") vSubject))
    (.and (isVehicle "v")
      (.and (occ "v" "X")
        (.and (.not (.same (.var "c2") (.var "X")))
          (.and (.since (occ "v" "X") fromDifferentHighway)
            (.not excepted)))))

/-- c, d: no contact, and no proceeding into a conflict. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
    (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.and (.derived "prim_closest_approach_within" [vSubject, .var "v"] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "v"] [pConflictHorizon])
          .lt pConflictCentreClearance))))

/-- Obligation: c (obligation): shall yield; d (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "c1"
    (.forallRegion (.lit "intersection") "X"
      (.implies selected
        (.forallUser "v"
          (.forallRegion (.lit "travel_region") "c2"
            (.implies isProtected yields)))))

def rule : Rule :=
  { id := "NRS_484B_250_1"
    laws := ["NRS-484B-250-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: precedence owed where 'circumstances of direction, speed and proximity ... give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a danger of a crash exists where, under constant velocities, the two centres approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance; the subject proceeds where its speed exceeds p.halt_speed_tolerance"
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_1

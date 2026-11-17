/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (condition): The driver of a vehicle
    b (condition): within an intersection
    c (condition): intending to turn to the left
    d (sibling): shall yield
    e (sibling): the right-of-way
    f (sibling): to any vehicle approaching from the opposite direction
    g (sibling): which is within the intersection
    h (sibling): or so close thereto as to constitute an immediate hazard,
    i (condition): but such driver, having so yielded
    j (condition): and having given a signal when and as required,
    k (condition): may make such left turn
    l (subject): and the drivers of all other vehicles
    m (trigger): approaching the intersection from the opposite direction
    n (obligation): shall yield
    o (standard): the right-of-way
    p (condition): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.intersection'], derived []
    j: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []
    k: atoms ['kin.speed', 'rel.occupies', 'st.intersection'], derived []
    l: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    m: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'st.lane_direction'], derived []
    n: atoms ['kin.speed', 'rel.contact'], derived []
    p: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    i: NRS_484B_253_o1 as compliance map {'subject': 't'}

  How each is written:
    l   — the binder `subject`, of the aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    m   — `approach X c2`: the subject occupies a carrier c2 (a region of kind `travel_region`)
          whose entrance end is the intersection X (`st_lane_enters c2 X`) and does not occupy X.
          'From the opposite direction' is the dot product of c2's and c1's designated directions
          (`st_lane_direction`, x and y components) below minus p.oncoming_heading_cos.
    a,p — the other road user t: not the subject (`same`), of the same aggregate.
    b   — t occupies X.
    c   — `intent int.left_turn t X` at the judged observation.
    (entry) t entered X from c1: `since (occ t X) (occ t c1 ∧ ¬ occ t X)` — t was on c1 outside X
          at some observation and has overlapped X at every observation since.
    j   — `since (¬ rises (occ t c1)) (indicator left ∨ hand signal left)`: a left signal at some
          observation with no later arrival onto c1, i.e. since t (last) came onto c1.
    k,i — `since (moving t ∧ occ t X) (rises (moving t ∧ occ t X) ∧ rule NRS_484B_253_o1 {subject ↦ t})`:
          the current movement within X began at the latest rise of 'moving (kin.speed above
          p.halt_speed_tolerance) while in X' (an entry while moving, or a start while in X), t has
          been moving in X at every observation since, and t complied with NRS_484B_253_o1 at
          that onset ('having so yielded').
    n,o — for every X, c2 and t selected as in the applicability (the whole selection restated):
          the subject is not in contact with t (`rel_contact`), and not (the subject moves,
          `kin_speed` above p.halt_speed_tolerance, while `prim_closest_approach_within(subject,
          t; p.conflict_horizon)` holds with `prim_closest_approach_distance(subject, t;
          p.conflict_horizon)` below p.conflict_centre_clearance).

  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantified variables: the intersection, the subject's carrier, the turning vehicle, its carrier. -/
def vX : Arg := .var "X"
def vC2 : Arg := .var "c2"
def vT : Arg := .var "t"
def vC1 : Arg := .var "c1"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- A road user moving: kin.speed above the halt tolerance. -/
def moving (x : Arg) : Formula := .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- m: the subject on a carrier c2 whose entrance end is X, not yet overlapping X. -/
def approach : Formula :=
  .and (occ vSubject vC2) (.and (.atom "st_lane_enters" [vC2, vX] []) (.not (occ vSubject vX)))

/-- m: c1's designated direction opposed to c2's, within p.oncoming_heading_cos. -/
def opposed : Formula :=
  let dir (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]
  .cmp (.add (.mul (dir vC1 "x") (dir vC2 "x")) (.mul (dir vC1 "y") (dir vC2 "y"))) .lt
    (.neg pOncomingHeadingCos)

/-- j: a left signal, by indicator or by arm. -/
def leftSignal : Formula :=
  .or (.atom "sig_turn_indicator" [vT, .lit "left"] []) (.atom "sig_hand_signal" [vT, .lit "left"] [])

/-- The carrier c1 t entered X from, opposed to c2, with the left signal since t came onto it. -/
def fromCarrier : Formula :=
  .existsRegion (.lit "travel_region") "c1"
    (.and (.since (occ vT vX) (.and (occ vT vC1) (.not (occ vT vX))))
      (.and (.atom "st_lane_enters" [vC1, vX] [])
        (.and opposed
          (.since (.not (.rises (occ vT vC1))) leftSignal))))

/-- k, i: moving within X since its current movement began, having complied with o1 at that onset. -/
def movingInX : Formula := .and (moving vT) (occ vT vX)
def turning : Formula :=
  .since movingInX (.and (.rises movingInX) (.rule "NRS_484B_253_o1" [("subject", "t")]))

/-- a, b, c, p and the rest of the selection of t. -/
def turner : Formula :=
  .and (.not (.same vT vSubject))
    (.and (.atom "ru_aggregate" [vT, aggVehicle] [])
      (.and (occ vT vX)
        (.and (.intent "int.left_turn" vT vX)
          (.and fromCarrier turning))))

/-- Applicability: a (condition): The driver of a vehicle; b (condition): within an intersection; c (condition): intending to turn to the left; i (condition): but such driver, having so yielded; j (condition): and having given a signal when and as required,; k (condition): may make such left turn; m (trigger): approaching the intersection from the opposite direction; p (condition): to the vehicle making the left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X"
    (.existsRegion (.lit "travel_region") "c2"
      (.and approach (.existsUser "t" turner)))

/-- n, o: no contact with t, and no proceeding while in conflict with t. -/
def yieldTo : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vT] []))
    (.not (.and (moving vSubject)
      (.and (.derived "prim_closest_approach_within" [vSubject, vT] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vT] [pConflictHorizon]) .lt
          pConflictCentreClearance))))

/-- Obligation: n (obligation): shall yield; o (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c2"
      (.forallUser "t" (.implies (.and approach turner) yieldTo)))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
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

end TrafficSpec.Rules.NRS_484B_253_o2

/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    v (subject): When a vehicle
    t1 (trigger): enters an intersection
    t2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    t3 (condition): but is inoperative at the time the vehicle enters the intersection,
    dr (subject): the driver of the vehicle
    o (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    p1 (condition): After making such a stop,
    p2 (standard): the driver shall proceed cautiously,
    p3 (obligation): yielding
    p4 (condition): to vehicles which have previously completed a stop
    p5 (condition): or are within the intersection.

  Elements (span → atoms, derived):
    v: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t1: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    t2: atoms ['dev.traffic_signal', 'dev.governs'], derived []
    t3: atoms ['dev.inoperative'], derived []
    dr: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    p3: atoms ['kin.speed', 'rel.contact'], derived []
    p4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived ['drv.motion.complete_halt']
    p5: atoms ['rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    p1: NRS_484B_250_4_o1 as compliance map {'subject': 'subject'}

  How each span is written.
    v, dr: the binder `subject`'s class, `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    t1: an intersection X (region quantifier of kind `intersection`) and a carrier c (kind
      `travel_region`) with `st_lane_enters c X`; the entry is the observation at which
      `rel_occupies subject X` rises while, at the observation before, the subject occupied c and
      not X (`since (occupies X) (occupies c ∧ ¬occupies X)` evaluated at a rise of `occupies X`
      selects exactly the previous observation). "Within X since its latest entry" is
      `since (occupies X) (entry ∧ …)`.
    t2, t3: at the entry observation, a device of kind `traffic_signal` that governs c or X
      (`dev_governs`), is uncovered (`dev_traffic_signal_uncovered`, the installed-and-uncovered
      attribute of dev.traffic_signal) and is inoperative (`dev_inoperative`).
    p1: `.rule NRS_484B_250_4_o1 {subject ↦ subject}` read at the entry observation, inside the
      same `since`.
    p4, p5: the obligation re-binds X and c by the whole selection of the applicability (for every
      selected X and c), and for every road user v other than the subject (`same`) of the vehicle
      aggregate that either occupies X (p5), or occupies a carrier c2 with `st_lane_enters c2 X`
      on which it came to a complete halt without overlapping X (Hv = complete_halt v ∧ occupies
      v c2 ∧ ¬occupies v X, its onset `rises Hv`), having occupied c2 or X at every observation
      since (A = occupies v c2 ∨ occupies v X), with that onset strictly earlier than the onset
      of the subject's last halt on c before its entry (Hs = complete_halt subject ∧ occupies
      subject c ∧ ¬occupies subject X). "Strictly earlier than the last subject onset" is "some
      subject onset ts lies after the v onset": `since A (rises Hs ∧ A ∧ since Hs (¬Hs ∧
      since A (rises Hv)))` — at a rise of Hs, `since Hs (¬Hs ∧ φ)` is φ at the previous
      observation, so the v onset lies at or before ts−1. "Or the subject made none" is
      `count Hs (occupies subject c) = 0` — no halt onset during the subject's latest stay on c,
      the approach that ended at the entry — with v's halt onset on c2 and A since.
    p2, p3: the operationalization: not in contact (`rel_contact`), and not moving
      (`kin_speed` above p.halt_speed_tolerance) while `prim_closest_approach_within` over
      p.conflict_horizon holds with `prim_closest_approach_distance` below
      p.conflict_centre_clearance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def aggregateVehicle : String := "DEF-NRS-484A-320::vehicle"

def isVehicle (x : String) : Formula := .atom "ru_aggregate" [.var x, .lit aggregateVehicle] []
def occupies (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def entersX (c x : String) : Formula := .atom "st_lane_enters" [.var c, .var x] []
def halted (x : String) : Formula := .derived "drv_motion_complete_halt" [.var x] [pHaltSpeedTolerance]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle "subject"

/-- t1: the observation at which the subject comes to overlap X, having occupied c (and not X) at
    the observation before. -/
def entry : Formula :=
  .and (.rises (occupies "subject" "X"))
    (.since (occupies "subject" "X") (.and (occupies "subject" "c") (.not (occupies "subject" "X"))))

/-- t2, t3: a traffic signal governing c or X, installed and uncovered, inoperative. -/
def signalInoperative : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.or (.atom "dev_governs" [.var "d", .var "c"] []) (.atom "dev_governs" [.var "d", .var "X"] []))
      (.and (.atom "dev_traffic_signal_uncovered" [.var "d"] []) (.atom "dev_inoperative" [.var "d"] [])))

/-- p1: "after making such a stop" — NRS_484B_250_4_o1 complied with. -/
def afterSuchStop : Formula := .rule "NRS_484B_250_4_o1" [("subject", "subject")]

/-- The selection of X and c: c enters X, and the subject has occupied X continuously since an
    entry from c at which the signal was inoperative and the stop was made. -/
def selection : Formula :=
  .and (entersX "c" "X")
    (.since (occupies "subject" "X") (.and entry (.and signalInoperative afterSuchStop)))

/-- Applicability: t1, t2, t3, p1. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X" (.existsRegion (.lit "travel_region") "c" selection)

/-- The subject at rest on c, not overlapping X. -/
def subjectHaltOnC : Formula :=
  .and (halted "subject") (.and (occupies "subject" "c") (.not (occupies "subject" "X")))

/-- v at rest on c2, not overlapping X. -/
def otherHaltOnC2 : Formula :=
  .and (halted "v") (.and (occupies "v" "c2") (.not (occupies "v" "X")))

/-- v on c2 or within X. -/
def otherStayed : Formula := .or (occupies "v" "c2") (occupies "v" "X")

/-- p4: v's halt onset on c2 lies strictly before the onset of the subject's last halt on c (some
    subject onset follows it), or the subject made none on its approach; v on c2 or X since. -/
def stoppedEarlier : Formula :=
  .or
    (.since otherStayed
      (.and (.rises subjectHaltOnC)
        (.and otherStayed
          (.since subjectHaltOnC (.and (.not subjectHaltOnC) (.since otherStayed (.rises otherHaltOnC2)))))))
    (.and (.count subjectHaltOnC (occupies "subject" "c") .eq 0)
      (.since otherStayed (.rises otherHaltOnC2)))

/-- p4: v occupies an approach c2 of X on which it previously completed a stop. -/
def previouslyStopped : Formula :=
  .existsRegion (.lit "travel_region") "c2"
    (.and (entersX "c2" "X") (.and (occupies "v" "c2") stoppedEarlier))

/-- The vehicles the words name: p4 or p5. -/
def namedVehicle : Formula :=
  .and (.not (.same (.var "v") vSubject))
    (.and (isVehicle "v") (.or (occupies "v" "X") previouslyStopped))

/-- p2: proceeding into a present danger of a crash with v. -/
def proceedsIntoConflict : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.derived "prim_closest_approach_within" [vSubject, .var "v"] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "v"] [pConflictHorizon]) .lt
        pConflictCentreClearance))

/-- p3 with p2: yielding to v. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var "v"] [])) (.not proceedsIntoConflict)

/-- Obligation: p2 (standard): the driver shall proceed cautiously,; p3 (obligation): yielding -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c"
      (.implies selection (.forallUser "v" (.implies namedVehicle yields))))

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proceed cautiously: proceed without creating a danger of a crash with the vehicles the words name"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: the subject proceeds (kin.speed above p.halt_speed_tolerance) while, under constant velocities, its centre and the other vehicle's approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance — a present danger of a crash"
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o2

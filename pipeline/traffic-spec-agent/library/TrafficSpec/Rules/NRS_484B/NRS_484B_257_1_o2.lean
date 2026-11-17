/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (exception): Except when traffic is being controlled by a police officer
    b (exception): or a traffic-control signal:
    c (trigger): When proper signs have been erected,
    d (subject): the driver of a vehicle
    e (sibling): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    j (condition): After having stopped or, in the event of a yield sign, slowed or stopped,
    k (obligation): the driver shall yield
    l (standard): the right-of-way
    m (condition): to other vehicles which have entered the intersection from such through highway
    n (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard
    o (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.travel_region'], derived []
    b: atoms ['dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    c: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    d: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    k: atoms ['kin.speed', 'rel.contact'], derived []
    m: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway', 'dev.governs', 'dev.stop_sign', 'dev.yield_sign'], derived []
    o: atoms ['kin.speed', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    j: NRS_484B_257_1_o1 as compliance map {'subject': 'subject'}

  How each is written.
    o: X ranges over `intersection` regions, c over `travel_region` regions (the carriers). The
       subject occupies X and moves (kin_speed > p.halt_speed_tolerance), and has occupied X
       continuously (`since`, φ = occupies X) since its entry observation e.
    entry: e is the observation at which occupancy of X rises (`rises`) and at the observation
       before it the subject occupied c and not X: `since (occupies X) (occupies c ∧ ¬occupies X)`
       read at e, which, with the rise, pins the ψ-observation to the one just before e.
    c: at e, st_lane_enters(c, X) and a stop_sign or yield_sign device governs c or X.
    a: at e, not (the subject is of DEF-NRS-484A-285::traffic and a human_direction device of role
       police_officer governs c or X).
    b: at e, no traffic_signal device that is not dev_inoperative governs c or X.
    j: at e, `.rule NRS_484B_257_1_o1 {subject ↦ subject}` (compliance, as the node places it).
    m/n: the obligation re-states the whole selection of (X, c) above and, for every such pair,
       quantifies over every road user v of DEF-NRS-484A-320::vehicle other than the subject for
       which some `highway` h_t has st_on_way(X, h_t), not st_on_way(c, h_t), and every
       travel_region c3 other than X itself (`same`: X is no carrier entering itself, and its
       st_lane_enters is unobserved) with st_lane_enters(c3, X) and st_on_way(c3, h_t) governed by
       no stop or yield sign — the through highway — and some travel_region c2 with st_lane_enters(c2, X) and
       st_on_way(c2, h_t) such that (a) v occupies X and has occupied it continuously since an
       observation at which it occupied c2 (`since`), or (b) v occupies c2 and the closest approach
       (subject, v) lies within p.conflict_horizon below p.conflict_centre_clearance.
    The obligation's selection of (X, c) is the applicability's whole selection (exceptions, signs
       and the composed stop rule included), quantified for every selected pair: where the subject
       entered X through several carriers, the duty binds through each one selected.
    k/l: for each such v: not rel_contact(subject, v), and not (the subject moves and the closest
       approach (subject, v) lies within p.conflict_horizon at a centre distance below
       p.conflict_centre_clearance).
  No reading beyond the record's was chosen; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggTraffic : String := "DEF-NRS-484A-285::traffic"

/-- Road user `x` occupies region `r`. -/
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
/-- Device `d` governs region `r`. -/
def gov (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
/-- Carrier `c` is an approach entering intersection `x`. -/
def entersX (c x : String) : Formula := .atom "st_lane_enters" [.var c, .var x] []
/-- Region `r` lies on highway `h`. -/
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []

/-- The subject is moving: kin.speed above the halt tolerance. -/
def moving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- Danger of a crash (traffic-conflict technique): the centres of `a` and `b` approach within the
    horizon to a centre distance below the clearance. -/
def conflict (a b : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [.var a, .var b] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [.var a, .var b] [pConflictHorizon]) .lt
          pConflictCentreClearance)

/-- Device `d` governs the approach `c` or the intersection `X`. -/
def govCX (d : String) : Formula := .or (gov d "c") (gov d "X")

/-- c: proper signs — a stop sign or a yield sign governs c or X. -/
def properSigns : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" (govCX "d"))
      (.existsDevice (.lit "yield_sign") "d" (govCX "d"))

/-- a: traffic (of which the subject is a member) controlled by a police officer directing c or X. -/
def policeControl : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit aggTraffic] [])
       (.existsDevice (.lit "human_direction") "p"
          (.and (.atom "dev_human_direction_role" [.var "p", .lit "police_officer"] []) (govCX "p")))

/-- b: a traffic signal, not inoperative, governing c or X. -/
def signalControl : Formula :=
  .existsDevice (.lit "traffic_signal") "g" (.and (govCX "g") (.not (.atom "dev_inoperative" [.var "g"] [])))

/-- The entry observation into X: occupancy of X rises, and at the observation before the subject
    occupied c and not X. -/
def entry : Formula :=
  .and (.rises (occ "subject" "X"))
       (.since (occ "subject" "X") (.and (occ "subject" "c") (.not (occ "subject" "X"))))

/-- Everything read at the entry observation: c enters X; proper signs; neither exception; the
    stop rule complied with (j). -/
def atEntry : Formula :=
  .and entry
    (.and (entersX "c" "X")
      (.and properSigns
        (.and (.not policeControl)
          (.and (.not signalControl)
            (.rule "NRS_484B_257_1_o1" [("subject", "subject")])))))

/-- The selection of (X, c): the subject moves within X, continuously in X since an entry from c at
    which the conditions held. -/
def selection : Formula :=
  .and (occ "subject" "X") (.and moving (.since (occ "subject" "X") atEntry))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit aggVehicle] []

/-- Applicability: a (exception): Except when traffic is being controlled by a police officer; b (exception): or a traffic-control signal:; c (trigger): When proper signs have been erected,; j (condition): After having stopped or, in the event of a yield sign, slowed or stopped,; m (condition): to other vehicles which have entered the intersection from such through highway; o (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X" (.existsRegion (.lit "travel_region") "c" selection)

/-- A carrier `r` governed by a stop sign or a yield sign. -/
def signedCarrier (r : String) : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" (gov "d" r))
      (.existsDevice (.lit "yield_sign") "d" (gov "d" r))

/-- m/n: v is protected through a through highway h of X: X lies on h, c does not, no carrier of h
    entering X is governed by a stop or yield sign, and v either has entered X from a carrier c2 of
    h entering X, or occupies such a c2 and is an immediate hazard. -/
def protectedVehicle : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (onWay "X" "h")
      (.and (.not (onWay "c" "h"))
        (.and (.forallRegion (.lit "travel_region") "c3"
                 (.implies (.and (.not (.same (.var "c3") (.var "X"))) (.and (entersX "c3" "X") (onWay "c3" "h")))
                    (.not (signedCarrier "c3"))))
          (.existsRegion (.lit "travel_region") "c2"
            (.and (entersX "c2" "X")
              (.and (onWay "c2" "h")
                (.or (.and (occ "v" "X") (.since (occ "v" "X") (occ "v" "c2")))
                     (.and (occ "v" "c2") (conflict "subject" "v")))))))))

/-- k/l: the subject yields to v: no contact, and it does not proceed while in conflict with v. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
       (.not (.and moving (conflict "subject" "v")))

/-- Obligation: k (obligation): the driver shall yield; l (standard): the right-of-way; n (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c"
      (.implies selection
        (.forallUser "v"
          (.implies
            (.and (.atom "ru_aggregate" [.var "v", .lit aggVehicle] [])
              (.and (.not (.same (.var "v") vSubject)) protectedVehicle))
            yields))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: precedence owed where 'circumstances of direction, speed and proximity ... give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a danger of a crash exists where, under constant velocities, the two centres approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance; the subject proceeds where its speed exceeds p.halt_speed_tolerance"
          surrogate := false }
      , { standard := "approaching so closely on the through highway as to constitute an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.lane_enters", "st.on_way"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: v, occupying a carrier entering X that lies on the through highway, is an immediate hazard where, under constant velocities, its centre and the subject's approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2

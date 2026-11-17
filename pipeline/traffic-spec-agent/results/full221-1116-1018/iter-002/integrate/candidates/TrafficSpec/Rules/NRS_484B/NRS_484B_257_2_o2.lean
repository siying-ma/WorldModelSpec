/-
  NRS_484B_257_2_o2 — NRS-484B-257-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (exception): Except when traffic is being controlled by a police officer
    b (exception): or a traffic-control signal:
    c (subject): The driver of a vehicle
    d (sibling): shall stop in obedience to a stop sign or yield in compliance with a yield sign,
    f (sibling): in compliance with the manner prescribed in subsection 1 [NRS-484B-257-1],
    g (sibling): prior to entering an intersection
    h (condition): if a stop sign or a yield sign is erected at one or more entrances thereto
    i (condition): although not a part of a through highway
    j (standard): and shall proceed cautiously,
    k (obligation): yielding
    l (condition): to vehicles not so obligated to stop or yield
    m (condition): and which are within the intersection
    n (standard): or approaching so closely as to constitute an immediate hazard
    o (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.travel_region'], derived []
    b: atoms ['dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    c: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    h: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    k: atoms ['kin.speed', 'rel.contact'], derived []
    l: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived []
    m: atoms ['rel.occupies', 'st.intersection'], derived []
    o: atoms ['kin.speed', 'rel.occupies', 'st.intersection'], derived []

  How each span is written:
    c — the binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    h — the subject's entry into intersection X through carrier c: at the entry observation
        `rises (rel_occupies subject X)`, with `since (rel_occupies subject X) (rel_occupies subject c)`
        (the subject occupied c at the observation before, or overlaps both), c a `travel_region`
        with `st_lane_enters c X`; at that observation a `stop_sign` or a `yield_sign` device
        governs c or X (`dev_governs`). The entry is the latest one: the applicability holds where
        the subject overlaps X now and has overlapped it at every observation since that entry
        (`since (rel_occupies subject X) entry`); a rise of the occupancy cannot recur while it holds.
    a — exception: the subject is of `DEF-NRS-484A-285::traffic` and a `human_direction` device
        with role `police_officer` governs c or X at the entry observation.
    b — exception: a `traffic_signal` device that is not `dev_inoperative` governs c or X at the
        entry observation.
    o — the subject overlaps X (`rel_occupies`) and `kin_speed subject > p.halt_speed_tolerance`.
    l, m, n — the protected vehicles: every other road user v of `DEF-NRS-484A-320::vehicle` for
        which some carrier c2 (`travel_region`, `st_lane_enters c2 X`) governed (`dev_governs`) by no
        `stop_sign` and no `yield_sign`, nor X itself, has v on it now or v overlapping X at every
        observation since it was on it (`since (rel_occupies v X) (rel_occupies v c2)`), and either
        v overlaps X (m), or v is on c2 and its closest approach to the subject lies within
        p.conflict_horizon at a centre distance below p.conflict_centre_clearance (n).
    k, j — towards each protected v: no `rel_contact`, and not (the subject moving and
        `prim_closest_approach_within` with `prim_closest_approach_distance` below the clearance).
  The obligation re-selects X and c exactly as the applicability selects them (every relation of
  the entry, the device conditions included) and states the duty for every such pair. One
  conjunct is not repeated there: the subject's membership of DEF-NRS-484A-285::traffic in span
  a's exception. Every class DEF-NRS-484A-320::vehicle includes or leaves unresolved is included
  in that aggregate, so wherever the rule is engaged the conjunct is true and the re-selection
  denotes the same (X, c). Repeated, it is a leaf no scene can move (the gate's VACUOUS, run 1).
  A carrier is never the intersection it enters: `.not (.same c X)` (and for c2) keeps the
  intersection, itself a travel region, out of the carrier quantifiers, where `st_lane_enters X X`
  would only be unobserved (an intersection records no entry). This adds no condition the record
  does not state.
  i is the node's residue. No narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_2_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def gov (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def entersX (c x : String) : Formula := .atom "st_lane_enters" [.var c, .var x] []
def vehicle (x : String) : Formula := .atom "ru_aggregate" [.var x, .lit "DEF-NRS-484A-320::vehicle"] []
def traffic (x : String) : Formula := .atom "ru_aggregate" [.var x, .lit "DEF-NRS-484A-285::traffic"] []

/-- o: the subject is moving (speed above the halt tolerance). -/
def moving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- A device `d` governs carrier `c` or intersection `x`. -/
def govCOrX (d c x : String) : Formula := .or (gov d c) (gov d x)

/-- h / l: a stop sign or a yield sign governs `c` or `x`. -/
def signGoverns (c x : String) : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" (govCOrX "d" c x))
      (.existsDevice (.lit "yield_sign") "d" (govCOrX "d" c x))

/-- a: a police officer's direction governs `c` or `x`. -/
def policeDirects (c x : String) : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] []) (govCOrX "d" c x))

/-- a: traffic (the subject) is controlled by a police officer's direction governing `c` or `x`.
    `withTraffic := false` is the obligation's re-selection: there the subject's membership of
    traffic is entailed by its class (every class `DEF-NRS-484A-320::vehicle` includes or leaves
    unresolved is included in `DEF-NRS-484A-285::traffic`), so it selects the same (X, c). -/
def policeGoverns (c x : String) (withTraffic : Bool := true) : Formula :=
  if withTraffic then .and (traffic "subject") (policeDirects c x) else policeDirects c x

/-- b: a traffic signal that is not inoperative governs `c` or `x`. -/
def signalGoverns (c x : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.not (.atom "dev_inoperative" [.var "d"] [])) (govCOrX "d" c x))

/-- h, a, b: the observation at which the subject enters `x` from carrier `c`, with the devices
    read there. -/
def entry (x c : String) (withTraffic : Bool := true) : Formula :=
  .and (.rises (occ "subject" x))
  (.and (.not (.same (.var c) (.var x)))
  (.and (entersX c x)
  (.and (.since (occ "subject" x) (occ "subject" c))
  (.and (signGoverns c x)
  (.and (.not (policeGoverns c x withTraffic))
        (.not (signalGoverns c x)))))))

/-- The subject overlaps `x` and has overlapped it at every observation since its latest entry,
    made through `c` under the conditions of `entry`. -/
def selection (x c : String) (withTraffic : Bool := true) : Formula :=
  .and (occ "subject" x) (.since (occ "subject" x) (entry x c withTraffic))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := vehicle "subject"

/-- Applicability: a (exception): Except when traffic is being controlled by a police officer; b (exception): or a traffic-control signal:; h (condition): if a stop sign or a yield sign is erected at one or more entrances thereto; i (condition): although not a part of a through highway; l (condition): to vehicles not so obligated to stop or yield; m (condition): and which are within the intersection; o (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "X"
          (.existsRegion (.lit "travel_region") "c" (selection "X" "c")))
       moving

/-- n / j: under constant velocities the centres of the subject and `v` approach within the
    horizon to a centre distance below the clearance. -/
def conflict (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- l, m, n: `v` is not so obligated (its approach carrier c2 into `x` is governed by no stop sign
    and no yield sign, nor is `x`) and is within `x`, or on c2 approaching as an immediate hazard. -/
def protectedUser (v x : String) : Formula :=
  .existsRegion (.lit "travel_region") "c2"
    (.and (.not (.same (.var "c2") (.var x)))
    (.and (entersX "c2" x)
    (.and (.not (signGoverns "c2" x))
    (.and (.since (occ v x) (occ v "c2"))
          (.or (occ v x) (.and (occ v "c2") (conflict v)))))))

/-- k, j: yielding to `v` — no contact, and no proceeding into a present danger of a crash. -/
def yields (v : String) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var v] []))
       (.not (.and moving (conflict v)))

/-- Obligation: j (standard): and shall proceed cautiously,; k (obligation): yielding; n (standard): or approaching so closely as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (selection "X" "c" (withTraffic := false))
        (.forallUser "v"
          (.implies
            (.and (.not (.same (.var "v") vSubject))
            (.and (vehicle "v") (protectedUser "v" "X")))
            (yields "v")))))

def rule : Rule :=
  { id := "NRS_484B_257_2_o2"
    laws := ["NRS-484B-257-2"]
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
          surrogate := false }
      , { standard := "approaching so closely as to constitute an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: v approaching on its carrier is an immediate hazard where, under constant velocities, its centre and the subject's approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance"
          surrogate := false } ]
    residues := ["'although' is concessive: the duty reaches signed entrances whether or not the intersection is part of a through highway, and the yielding owed by a driver entering through a signed entrance is the same in both cases; the words withhold the duty nowhere."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_2_o2

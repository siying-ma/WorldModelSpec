/-
  NRS_484B_307_2a — NRS-484B-307-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When the signal is circular green alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (trigger): may proceed straight through or turn right or left
    s4 (exception): unless another device at the place prohibits either or both such turns.
    s5 (subject): Such vehicular traffic, including vehicles turning right or left,
    s6 (obligation): must yield
    s7 (standard): the right-of-way
    s8 (condition): to other vehicles
    s9 (condition): and to pedestrians
    s10 (condition): lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived []
    s3: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['kin.speed', 'rel.contact'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s10: atoms ['rel.occupies', 'st.intersection', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'dev.traffic_signal'], derived []

  How each is written:
    s2/s5 (class): the subject is a member of both admitted aggregates, `ru_aggregate` with the
      aggregate ids as literals, never expanded.
    s1: some traffic signal d (`existsDevice traffic_signal`) shows circular_green
      (`dev_traffic_signal_shows`) and shows no other state of the enumeration: every other
      spelling (the circular, flashing, dark and unknown states, and each arrow state in each
      direction) is tested in one disjunction and negated. A head reporting `unknown` beside the
      green is a head showing another state: the green is then not alone.
    s2/s3 (facing, proceeding): an intersection i (`existsRegion intersection`), a carrier c
      (`existsRegion travel_region`) with `st_lane_enters c i`, d governing c (`dev_governs d c`),
      and the subject occupying c, or occupying i continuously since it occupied c. The latter
      disjunction is Core's `since (rel_occupies subject i) (rel_occupies subject c)`, which holds
      exactly where the subject occupies c now, or occupies i now and has done so at every
      observation since one at which it occupied c — the record's two limbs in one operator.
    s8/s9/s10 (parties): the obligation re-binds i, c and d with the whole selection of the
      applicability (`forallRegion`/`forallDevice`, implication from the selection) so the duty
      holds at every selected intersection; for every road user u not the subject (`same`), a
      vehicle or a pedestrian (`ru_aggregate`), occupying i, or occupying a crosswalk x
      (`existsRegion crosswalk`) that marks the entrance (`st_entrance_of x c2`) of a carrier c2
      (`existsRegion travel_region`) entering i (`st_lane_enters c2 i`). The party's presence is
      read at the judged observation, the same at which the green is read alone.
    s6/s7 (yield): not (subject moves — `kin_speed` above `p.halt_speed_tolerance` — and either
      the centres approach within `p.conflict_horizon` (`prim_closest_approach_within`) to a
      closest centre distance below `p.conflict_centre_clearance`
      (`prim_closest_approach_distance`), or the bodies are in contact (`rel_contact`)).
    s4: residue (the node's).

  No choice beyond the record's own narrowings was needed: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def aggTraffic : String := "DEF-NRS-484A-285::traffic"
def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggPedestrian : String := "DEF-NRS-484A-165::pedestrian"

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vU : Arg := .var "u"
def vX : Arg := .var "x"
def vC2 : Arg := .var "c2"

def andAll : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (andAll rest)

def orAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (orAll rest)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit aggTraffic] [])
       (.atom "ru_aggregate" [vSubject, .lit aggVehicle] [])

/-- Every state of a signal head other than circular_green, as spelled by the ontology. -/
def otherStates : List String :=
  let dirs := ["left", "right", "straight", "u_turn"]
  ["circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown"]
    ++ dirs.map (fun d => s!"green_arrow({d})")
    ++ dirs.map (fun d => s!"yellow_arrow({d})")
    ++ dirs.map (fun d => s!"red_arrow({d})")
    ++ dirs.map (fun d => s!"flashing_yellow_arrow({d})")

/-- s1: signal `d` displays circular_green and no other state. -/
def greenAlone : Formula :=
  .and (.atom "dev_traffic_signal_shows" [vD, .lit "circular_green"] [])
       (.not (orAll (otherStates.map fun st => .atom "dev_traffic_signal_shows" [vD, .lit st] [])))

/-- s2/s3: the subject occupies carrier `c`, or occupies intersection `i` continuously since it
    occupied `c`. -/
def facing : Formula :=
  .since (.atom "rel_occupies" [vSubject, vI] []) (.atom "rel_occupies" [vSubject, vC] [])

/-- The whole selection of i, c and d (s1, s2, s3), stated over the bound variables. -/
def selection : Formula :=
  andAll
    [ .atom "st_lane_enters" [vC, vI] []
    , .atom "dev_governs" [vD, vC] []
    , greenAlone
    , facing ]

/-- Applicability: s1 (trigger): When the signal is circular green alone:; s3 (trigger): may proceed straight through or turn right or left; s4 (exception): unless another device at the place prohibits either or both such turns.; s8 (condition): to other vehicles; s9 (condition): and to pedestrians; s10 (condition): lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "d" selection))

/-- s8/s9/s10: road user `u`, other than the subject, a vehicle or a pedestrian, within
    intersection `i` or a crosswalk marking the entrance of a carrier into `i`. -/
def party : Formula :=
  andAll
    [ .not (.same vU vSubject)
    , .or (.atom "ru_aggregate" [vU, .lit aggVehicle] [])
          (.atom "ru_aggregate" [vU, .lit aggPedestrian] [])
    , .or (.atom "rel_occupies" [vU, vI] [])
          (.existsRegion (.lit "crosswalk") "x"
            (.existsRegion (.lit "travel_region") "c2"
              (andAll
                [ .atom "rel_occupies" [vU, vX] []
                , .atom "st_entrance_of" [vX, vC2] []
                , .atom "st_lane_enters" [vC2, vI] [] ]))) ]

/-- s7: the danger of a crash with `u` (traffic-conflict technique). -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- s6: the subject does not move while a crash with `u` is in danger, nor moves into contact. -/
def yields : Formula :=
  .not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
             (.or conflict (.atom "rel_contact" [vSubject, vU] [])))

/-- Obligation: s6 (obligation): must yield; s7 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "d"
        (.implies selection
          (.forallUser "u" (.implies party yields)))))

def rule : Rule :=
  { id := "NRS_484B_307_2a"
    laws := ["NRS-484B-307-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: the danger of a crash with a party exists where, under constant velocities, the centres of the subject and the party approach within the conflict horizon (prim.closest_approach_within) to a centre distance below the conflict clearance (prim.closest_approach_distance), which reads the direction, the speed and the proximity of both together"
          surrogate := false } ]
    residues := ["The words limit the permission to turn, not the duty to yield: traffic facing the circular green must yield whether or not another device prohibits a turn, and whether it makes the turn or not; the duty is the same either way."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_2a

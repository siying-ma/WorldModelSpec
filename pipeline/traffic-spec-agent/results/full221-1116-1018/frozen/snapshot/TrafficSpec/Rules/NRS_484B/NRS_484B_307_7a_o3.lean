/-
  NRS_484B_307_7a_o3 — NRS-484B-307-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a flashing yellow turn arrow, displayed alone or in combination with another signal:
    s2 (subject): Vehicular traffic facing the signal
    s3 (sibling): is permitted to cautiously
    s4 (sibling): enter the intersection only to make the movement indicated by the arrow signal,
    s5 (sibling): or other such movement as is permitted by other signal indications displayed at the same time.
    s6 (subject): Such vehicular traffic
    s7 (sibling): must yield
    s8 (sibling): the right-of-way
    s9 (sibling): to pedestrians lawfully within the intersection or an adjacent crosswalk
    s10 (obligation): and yield
    s11 (standard): the right-of-way
    s12 (condition): to other traffic lawfully within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s10: atoms ['kin.speed', 'rel.contact'], derived []
    s12: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.intersection'], derived []

  How each is written.
    s2/s6 (class): the subject is a member of both admitted aggregates, `ru_aggregate` with the
      aggregate id as its literal.
    s1 (trigger): a device `s` of kind traffic_signal (`dev.traffic_signal`) displaying
      flashing_yellow_arrow(left), (right) or (u_turn) — one disjunct per direction, whatever else
      it displays (`dev_traffic_signal_shows` tests membership in the displayed set, so "alone or in
      combination" is carried by not restricting the other states).
    s2 (facing): `approach s i` — some travel region `c` (kind travel_region, `st.travel_region`)
      the subject occupies (`rel.occupies`), whose entrance end is intersection `i`
      (`st.lane_enters`; `i` bound over kind intersection, `st.intersection`) and which `s` governs
      (`dev.governs`).
    Applicability (the record's): some signal `s` and intersection `i` with either
      (A) approach s i ∧ arrow s at the judged observation, or
      (B) the subject occupies `i` and `since (occupies i) (approach s i ∧ arrow s)`: it has occupied
          `i` at every observation after the last one at which it faced `s` through such a `c`
          while `s` displayed the arrow (its entry into `i`).
    Obligation (3c): for every signal `s` and intersection `i` selected as in the applicability
      (the whole selection restated), every road user `p` of the aggregate DEF-NRS-484A-285::traffic
      (s12), not the subject (`same`), whose footprint overlaps `i` (`rel.occupies`, s12), satisfies:
      not (subject speed > p.halt_speed_tolerance ∧ prim_closest_approach_within(subject, p,
      p.conflict_horizon) ∧ prim_closest_approach_distance(subject, p, p.conflict_horizon) <
      p.conflict_centre_clearance) — s11's operationalization with kin.speed of s10 — and not
      rel_contact(subject, p) (s10).
    Choices the record left open: none beyond the above; the record's narrowing on s10 (presence
    within the intersection read without judging lawfulness) is the plan's and is not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_7a_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the signal head, the intersection, the approach carrier, the other road user. -/
def vS : Arg := .var "s"
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vP : Arg := .var "p"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, aggTraffic] [])
       (.atom "ru_aggregate" [vSubject, aggVehicle] [])

/-- s1: head `s` displays a flashing yellow turn arrow (left, right or u-turn), alone or with other states. -/
def arrowShown : Formula :=
  .or (.atom "dev_traffic_signal_shows" [vS, .lit "flashing_yellow_arrow(left)"] [])
    (.or (.atom "dev_traffic_signal_shows" [vS, .lit "flashing_yellow_arrow(right)"] [])
         (.atom "dev_traffic_signal_shows" [vS, .lit "flashing_yellow_arrow(u_turn)"] []))

/-- s2: the subject occupies a travel region `c` that enters intersection `i` and that `s` governs. -/
def approach : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.atom "rel_occupies" [vSubject, vC] [])
      (.and (.atom "st_lane_enters" [vC, vI] [])
            (.atom "dev_governs" [vS, vC] [])))

/-- The subject occupies intersection `i`. -/
def inI : Formula := .atom "rel_occupies" [vSubject, vI] []

/-- The record's selection of head `s` and intersection `i`: facing it now while it shows the arrow,
    or inside `i` without a break since entering it from such an approach while it showed the arrow. -/
def selection : Formula :=
  .or (.and approach arrowShown)
      (.and inI (.since inI (.and approach arrowShown)))

/-- Applicability: s1 (trigger), s2 (subject facing the signal). -/
def applicability : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.existsRegion (.lit "intersection") "i" selection)

/-- s11 (standard): a danger of a crash with `p` while the subject moves on. -/
def conflict : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
          (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon])
                .lt pConflictCentreClearance))

/-- s12: other traffic within the intersection `i`. -/
def otherTrafficInI : Formula :=
  .and (.atom "ru_aggregate" [vP, aggTraffic] [])
    (.and (.not (.same vP vSubject))
          (.atom "rel_occupies" [vP, vI] []))

/-- Obligation: s10 (obligation): and yield; s11 (standard): the right-of-way — to every other road
    user of the class traffic within the intersection selected as in the applicability. -/
def obligation : Formula :=
  .forallDevice (.lit "traffic_signal") "s"
    (.forallRegion (.lit "intersection") "i"
      (.implies selection
        (.forallUser "p"
          (.implies otherTrafficInI
            (.and (.not conflict)
                  (.not (.atom "rel_contact" [vSubject, vP] [])))))))

def rule : Rule :=
  { id := "NRS_484B_307_7a_o3"
    laws := ["NRS-484B-307-7a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the subject grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_7a_o3

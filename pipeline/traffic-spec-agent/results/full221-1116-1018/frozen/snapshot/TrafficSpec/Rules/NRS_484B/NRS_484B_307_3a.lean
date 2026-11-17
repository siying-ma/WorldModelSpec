/-
  NRS_484B_307_3a — NRS-484B-307-3a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is circular green with a green turn arrow:
    s2 (subject): Vehicular traffic facing the signal
    s3 (trigger): may proceed
    s4 (condition): to make the movement indicated by the green turn arrow or such other movement as is permitted by the circular green signal,
    s5 (subject): but the traffic
    s6 (obligation): must yield
    s7 (standard): the right-of-way
    s9 (condition): to pedestrians
    s10 (condition): lawfully within an adjacent crosswalk
    s11 (condition): and to other traffic
    s12 (condition): lawfully using the intersection
    s13 (condition): at the time the signal is exhibited.
    s8 (condition): Drivers turning in the direction of the arrow when displayed with the circular green are thereby advised that so long as a turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived []
    s3: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s6: atoms ['kin.speed', 'rel.contact'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s10: atoms ['rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region'], derived []
    s11: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s12: atoms ['rel.occupies', 'st.intersection'], derived []
    s13: atoms ['dev.traffic_signal'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_3a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  HOW EACH SPAN IS WRITTEN

  s2/s5 (subject): the binder's class is membership of both admitted aggregates,
    `ru_aggregate subject DEF-NRS-484A-285::traffic` and `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
  s2 ("facing the signal"): an intersection `i` (quantifier kind `intersection`), a carrier `c`
    (quantifier kind `travel_region`, abstract, so every lane/roadway kind refining it is covered)
    with `st_lane_enters c i`, and a traffic signal `d` (quantifier kind `traffic_signal`) with
    `dev_governs d c`.
  s1/s13: `d` shows `circular_green` together with `green_arrow(left)`, `green_arrow(right)` or
    `green_arrow(u_turn)` at the judged observation (a straight arrow is no turn arrow).
  s3 ("may proceed"): the subject occupies `c`, or occupies `i` and has occupied `i` continuously
    since an observation at which it occupied `c`: `rel_occupies subject c ∨
    (rel_occupies subject i) since (rel_occupies subject c)` (where `c` is not occupied now, the
    strong `since` already requires `i` occupied now).
  s9/s10: a party `u` that is a pedestrian (`ru_aggregate u DEF-NRS-484A-165::pedestrian`)
    occupying a crosswalk `x` that marks the entrance (`st_entrance_of x c2`) of a carrier `c2`
    (`travel_region`) entering the same `i` (`st_lane_enters c2 i`).
  s11/s12: a party `u` that is a member of traffic (`ru_aggregate u DEF-NRS-484A-285::traffic`)
    occupying `i`. Both limbs exclude the subject itself (`¬ same u subject`).
  s6/s7: for every party, not (the subject moves — `kin_speed subject > p.halt_speed_tolerance` —
    while either the danger of a crash exists — `prim_closest_approach_within(subject, u;
    p.conflict_horizon)` with `prim_closest_approach_distance(subject, u; p.conflict_horizon) <
    p.conflict_centre_clearance` — or the bodies are in contact, `rel_contact subject u`).
  Obligation scope (3c): the obligation re-binds `i`, `c` and `d` with the applicability's whole
    selection (entry, governance, signal state, the subject's approach) and states the duty for
    every such selection (∀ i c d, selection → duty).
  s4, s8: residues (the node's).
  No choice beyond the record's wording was needed; no narrowing is declared.
-/

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vU : Arg := .var "u"
def vX : Arg := .var "x"
def vC2 : Arg := .var "c2"

def aggTraffic : String := "DEF-NRS-484A-285::traffic"
def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggPedestrian : String := "DEF-NRS-484A-165::pedestrian"

def occ (who r : Arg) : Formula := .atom "rel_occupies" [who, r] []
def member (who : Arg) (agg : String) : Formula := .atom "ru_aggregate" [who, .lit agg] []
def shows (k : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit k] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .and (member vSubject aggTraffic) (member vSubject aggVehicle)

/-- s1/s13: circular green displayed together with a green turn arrow. -/
def greenWithTurnArrow : Formula :=
  .and (shows "circular_green")
    (.or (shows "green_arrow(left)") (.or (shows "green_arrow(right)") (shows "green_arrow(u_turn)")))

/-- s2/s3: the subject on the approach carrier `c`, or in `i` continuously since it was on `c`. -/
def onApproach : Formula :=
  .or (occ vSubject vC) (.since (occ vSubject vI) (occ vSubject vC))

/-- The whole selection of `i`, `c`, `d` (s1, s2, s3, s13), given `i`, `c`, `d` bound. -/
def selection : Formula :=
  .and (.atom "st_lane_enters" [vC, vI] [])
    (.and (.atom "dev_governs" [vD, vC] []) (.and greenWithTurnArrow onApproach))

/-- Applicability: s1 (trigger): Where the signal is circular green with a green turn arrow:; s3 (trigger): may proceed; s4 (condition): to make the movement indicated by the green turn arrow or such other movement as is permitted by the circular green signal,; s9 (condition): to pedestrians; s10 (condition): lawfully within an adjacent crosswalk; s11 (condition): and to other traffic; s12 (condition): lawfully using the intersection; s13 (condition): at the time the signal is exhibited.; s8 (condition): Drivers turning in the direction of the arrow when displayed with the circular green are thereby advised that so long as a turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.existsDevice (.lit "traffic_signal") "d"
          (.and (.atom "dev_governs" [vD, vC] []) (.and greenWithTurnArrow onApproach)))))

/-- s9/s10: a pedestrian within a crosswalk marking the entrance of a carrier into `i`. -/
def pedestrianInAdjacentCrosswalk : Formula :=
  .and (member vU aggPedestrian)
    (.existsRegion (.lit "crosswalk") "x"
      (.and (occ vU vX)
        (.existsRegion (.lit "travel_region") "c2"
          (.and (.atom "st_entrance_of" [vX, vC2] []) (.atom "st_lane_enters" [vC2, vI] [])))))

/-- s11/s12: other traffic using the intersection `i`. -/
def trafficInIntersection : Formula :=
  .and (member vU aggTraffic) (occ vU vI)

/-- The parties owed the right-of-way (s9–s12), the subject excluded. -/
def party : Formula :=
  .and (.not (.same vU vSubject)) (.or pedestrianInAdjacentCrosswalk trafficInIntersection)

/-- s6: the subject moves. -/
def moving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- s7: the danger of a crash with `u` (traffic-conflict technique). -/
def danger : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- s6/s7: yield the right-of-way to `u`. -/
def yields : Formula :=
  .not (.and moving (.or danger (.atom "rel_contact" [vSubject, vU] [])))

/-- Obligation: s6 (obligation): must yield; s7 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "d"
        (.implies selection
          (.forallUser "u" (.implies party yields)))))

def rule : Rule :=
  { id := "NRS_484B_307_3a"
    laws := ["NRS-484B-307-3a"]
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
    residues := ["The words describe which movements the traffic may make (the arrow's movement or one the circular green permits); the duty to yield binds the traffic facing the signal whichever movement it makes, so the duty is the same whether or not the movement is one of those.", "An advisory statement of the signal phasing for the driver's information (opposing traffic faces a steady red while the arrow is lit); it requires, permits or forbids nothing, and the duty to yield is the same whether or not it holds."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_3a

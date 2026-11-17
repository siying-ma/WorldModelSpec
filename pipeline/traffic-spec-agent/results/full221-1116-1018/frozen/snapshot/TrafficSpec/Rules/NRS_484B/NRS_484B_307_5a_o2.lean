/-
  NRS_484B_307_5a_o2 — NRS-484B-307-5a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green straight-through arrow alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (sibling): may proceed straight through, but must not turn right or left.
    s4 (subject): Such vehicular traffic
    s5 (obligation): must yield
    s6 (standard): the right-of-way
    s7 (condition): to other vehicles
    s8 (condition): and to pedestrians
    s9 (condition): lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['kin.speed', 'rel.contact'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s9: atoms ['dev.traffic_signal', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []

  How each is written:
    s2/s4 (class): `ru_aggregate subject "DEF-NRS-484A-285::traffic"` and
      `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, conjoined.
    s1: a head `s` (`existsDevice "traffic_signal"`) showing `green_arrow(straight)` and none of the
      other display states of the enumeration (`arrowAlone`). The state `unknown` (the source could
      not read a lamp) is not counted as "another state": where the head shows it, whether the arrow
      is shown alone is left unknown (`definedWhen`), never decided.
    s2 (facing): `facing s i` = the subject occupies a travel region `c` (existsRegion
      "travel_region") that enters intersection `i` (`st_lane_enters c i`) and that `s` governs
      (`dev_governs s c`); or, through `since`, it occupies `i` at every observation after one at
      which that held (it entered `i` from such a `c` and has stayed in it).
    s7/s8: `p` is another road user (`not (same p subject)`) of the vehicle aggregate or of the
      pedestrian aggregate.
    s9: `inZone p i` = `p` occupies `i`, or occupies a crosswalk `w` recorded as marking the
      entrance (`st_entrance_of w c2`) of a travel region `c2` that enters `i`. "At the time the
      signal is exhibited": `since (arrowAlone s) (rises (arrowAlone s) ∧ inZone p i)` — at the latest
      rise of the arrow-alone display, which has held at every observation since, `p` was in the
      zone; `p` is also in the zone at the judged observation.
    s5/s6: for every such `p`: not (speed of subject > p.halt_speed_tolerance and
      prim_closest_approach_within subject p p.conflict_horizon and
      prim_closest_approach_distance subject p p.conflict_horizon < p.conflict_centre_clearance),
      and not rel_contact subject p.
    Carriers: the travel regions `c`, `c2` are quantified as the record names them
      ("travel_region"), and the intersection `i` itself is set aside (`not (same c i)`): by the
      st.lane_enters / st.entrance_of contracts an intersection is no carrier and never enters
      itself, but Core reads `st_lane_enters i i` as unknown (an intersection has no lane record),
      which would otherwise leave every verdict through the quantifier unknown. No carrier the
      contracts admit is excluded.
    Obligation scope (3c): the obligation restates the whole selection of `s` and `i` (facing and
      the arrow alone) and states the duty for every head and intersection so selected.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_5a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vS : Arg := .var "s"
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vP : Arg := .var "p"
def vW : Arg := .var "w"
def vC2 : Arg := .var "c2"

def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []

/-- Every display state of a head other than the straight-through green arrow and `unknown`. -/
def otherStates : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)", "flashing_yellow_arrow(straight)",
    "flashing_yellow_arrow(u_turn)" ]

def anyOther : Formula :=
  match otherStates with
  | [] => .ff
  | x :: xs => xs.foldl (fun acc y => .or acc (shows y)) (shows x)

/-- s1: head `s` displays the green straight-through arrow and no other state; unknown where the
    head reports a state the source could not read. -/
def arrowAlone : Formula :=
  .and (shows "green_arrow(straight)")
    (.and (.not anyOther) (.definedWhen (.not (shows "unknown")) .tt))

/-- s2: the subject occupies a travel region `c` entering `i` that `s` governs. -/
def onGovernedApproach : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.not (.same vC vI))
      (.and (.atom "rel_occupies" [vSubject, vC] [])
        (.and (.atom "st_lane_enters" [vC, vI] [])
          (.atom "dev_governs" [vS, vC] []))))

/-- s2: facing `s` — on such an approach, or in `i` at every observation since it was on one. -/
def facing : Formula :=
  .since (.atom "rel_occupies" [vSubject, vI] []) onGovernedApproach

/-- s9: `p` within `i` or a crosswalk marking the entrance of a travel region that enters `i`. -/
def inZone : Formula :=
  .or (.atom "rel_occupies" [vP, vI] [])
    (.existsRegion (.lit "crosswalk") "w"
      (.and (.atom "rel_occupies" [vP, vW] [])
        (.existsRegion (.lit "travel_region") "c2"
          (.and (.not (.same vC2 vI))
            (.and (.atom "st_entrance_of" [vW, vC2] [])
              (.atom "st_lane_enters" [vC2, vI] []))))))

/-- s7, s8: another road user of the vehicle or the pedestrian aggregate. -/
def otherVehicleOrPedestrian : Formula :=
  .and (.not (.same vP vSubject))
    (.or (.atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] []))

/-- s9: in the zone now, and in it at the latest observation at which the arrow alone came on. -/
def owedYield : Formula :=
  .and otherVehicleOrPedestrian
    (.and inZone
      (.since arrowAlone (.and (.rises arrowAlone) inZone)))

/-- s5, s6: no closest approach within the horizon below the clearance while moving; no contact. -/
def yields : Formula :=
  .and
    (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon])
          .lt pConflictCentreClearance))))
    (.not (.atom "rel_contact" [vSubject, vP] []))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger): Where the signal is a green straight-through arrow alone:; s7 (condition): to other vehicles; s8 (condition): and to pedestrians; s9 (condition): lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited. -/
def applicability : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.existsRegion (.lit "intersection") "i"
      (.and facing arrowAlone))

/-- Obligation: s5 (obligation): must yield; s6 (standard): the right-of-way -/
def obligation : Formula :=
  .forallDevice (.lit "traffic_signal") "s"
    (.forallRegion (.lit "intersection") "i"
      (.implies (.and facing arrowAlone)
        (.forallUser "p" (.implies owedYield yields))))

def rule : Rule :=
  { id := "NRS_484B_307_5a_o2"
    laws := ["NRS-484B-307-5a"]
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
          convention := "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the subject grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity, the factors the definition names, enter by degree through the constant-velocity extrapolation of both road users."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_5a_o2

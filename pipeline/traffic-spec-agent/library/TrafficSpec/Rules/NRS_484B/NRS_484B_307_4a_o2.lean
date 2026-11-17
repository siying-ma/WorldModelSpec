/-
  NRS_484B_307_4a_o2 — NRS-484B-307-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green turn arrow alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (sibling): may proceed only in the direction indicated by the arrow signal so long as the arrow is illuminated,
    s4 (subject): but the traffic
    s5 (obligation): must yield
    s6 (standard): the right-of-way
    s7 (condition): to pedestrians
    s8 (condition): lawfully within the adjacent crosswalk
    s9 (condition): and to other traffic
    s10 (condition): lawfully using the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['kin.speed', 'rel.contact'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s8: atoms ['rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s10: atoms ['rel.occupies', 'st.intersection'], derived []

  How each is written:
    binder `subject` (s2, s4): `ru_aggregate` on DEF-NRS-484A-285::traffic and on
      DEF-NRS-484A-320::vehicle, conjoined.
    s1: a device d of kind `traffic_signal` (dev.traffic_signal) shows `green_arrow(dir)` for one dir
      among left, right, u_turn, and shows none of the other indications of the enumeration
      (`dev_traffic_signal_shows`, negated for each of them): "alone" as the record states it.
    s2: an intersection i (region kind `intersection`), a carrier c (region kind `travel_region`)
      with `st_lane_enters c i`, `dev_governs d c`; the subject occupies c, or occupies i and has
      occupied i at every observation since one at which it occupied c (`since`).
    s5 + s6: for every road user u other than the subject (`same`) that is protected (s7–s10), not
      (kin.speed of the subject above p.halt_speed_tolerance and (prim.closest_approach_within over
      p.conflict_horizon with prim.closest_approach_distance below p.conflict_centre_clearance, or
      rel.contact)).
    s7 + s8: u a member of DEF-NRS-484A-165::pedestrian occupying a crosswalk x (region kind
      `crosswalk`) with `st_entrance_of x c2` for a carrier c2 (`travel_region`) with
      `st_lane_enters c2 i`.
    s9 + s10: u a member of DEF-NRS-484A-285::traffic occupying i.
    The obligation re-binds i, c and d with the applicability's whole selection (rule 3c) and
    states the duty for every selection (`forallRegion`/`forallDevice` … `implies`), as the record's
    "re-binding … for every road user" requires.

  Choices the record left open: none beyond the record's own narrowing on s6.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_4a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Aggregate ids the node claims. -/
def aggTraffic : String := "DEF-NRS-484A-285::traffic"
def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggPedestrian : String := "DEF-NRS-484A-165::pedestrian"

/-- Conjunction and disjunction of a non-empty list. -/
def fAll : List Formula → Formula
  | [] => Formula.tt
  | [φ] => φ
  | φ :: rest => Formula.and φ (fAll rest)

def fAny : List Formula → Formula
  | [] => Formula.ff
  | [φ] => φ
  | φ :: rest => Formula.or φ (fAny rest)

-- Leaves.
def fMember (who agg : String) : Formula := .atom "ru_aggregate" [.var who, .lit agg] []
def fOcc (who r : String) : Formula := .atom "rel_occupies" [.var who, .var r] []
def fLaneEnters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def fGoverns (d c : String) : Formula := .atom "dev_governs" [.var d, .var c] []
def fMarksEntrance (x c : String) : Formula := .atom "st_entrance_of" [.var x, .var c] []
def fShows (d ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit ind] []

/-- Every indication of `dev.traffic_signal`'s state enumeration, spelled as the ontology spells it. -/
def arrowDirs : List String := ["left", "right", "straight", "u_turn"]
def signalStates : List String :=
  ["circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown"]
  ++ (["green_arrow", "yellow_arrow", "red_arrow", "flashing_yellow_arrow"].flatMap fun (k : String) =>
        arrowDirs.map fun (dir : String) => k ++ "(" ++ dir ++ ")")

/-- s1: the signal displays a green turn arrow (left, right or u_turn) and no other state. -/
def fGreenTurnArrowAlone (d : String) : Formula :=
  fAny (["left", "right", "u_turn"].map fun (dir : String) =>
    let g : String := "green_arrow(" ++ dir ++ ")"
    Formula.and (fShows d g)
      (fAll ((signalStates.filter (fun j => j != g)).map fun (j : String) => Formula.not (fShows d j))))

/-- s2: the subject faces the signal through carrier c entering intersection i: it occupies c, or it
    occupies i and has done so at every observation since one at which it occupied c. -/
def fFacing (c i : String) : Formula :=
  .or (fOcc "subject" c)
    (.and (fOcc "subject" i) (.since (fOcc "subject" i) (fOcc "subject" c)))

/-- The whole selection of i, c and d (s1, s2). -/
def fSelection (i c d : String) : Formula :=
  fAll [fLaneEnters c i, fGoverns d c, fGreenTurnArrowAlone d, fFacing c i]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .and (fMember "subject" aggTraffic) (fMember "subject" aggVehicle)

/-- Applicability: s1 (trigger) and s2 (subject facing the signal). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "d" (fSelection "i" "c" "d")))

/-- s7 + s8: a pedestrian within a crosswalk marking the entrance of a carrier into intersection i;
    s9 + s10: other traffic occupying i. -/
def fProtected (u i : String) : Formula :=
  .and (.not (.same (.var u) vSubject))
    (.or
      (.and (fMember u aggPedestrian)
        (.existsRegion (.lit "crosswalk") "x"
          (.and (fOcc u "x")
            (.existsRegion (.lit "travel_region") "c2"
              (.and (fMarksEntrance "x" "c2") (fLaneEnters "c2" i))))))
      (.and (fMember u aggTraffic) (fOcc u i)))

/-- s6: the danger of a crash with u (traffic-conflict technique). -/
def fDanger (u : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var u] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var u] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- s5: what yielding forbids — moving while the danger exists, or moving into contact. -/
def fFailsToYield (u : String) : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.or (fDanger u) (.atom "rel_contact" [vSubject, .var u] []))

/-- Obligation: s5 (obligation): must yield; s6 (standard): the right-of-way — at every selection
    of the applicability, re-bound whole. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "d"
        (.implies (fSelection "i" "c" "d")
          (.forallUser "u" (.implies (fProtected "u" "i") (.not (fFailsToYield "u")))))))

def rule : Rule :=
  { id := "NRS_484B_307_4a_o2"
    laws := ["NRS-484B-307-4a"]
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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_4a_o2

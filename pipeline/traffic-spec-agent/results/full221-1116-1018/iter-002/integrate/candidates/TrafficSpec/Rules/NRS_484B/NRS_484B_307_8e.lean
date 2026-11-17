/-
  NRS_484B_307_8e — NRS-484B-307-8e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (obligation): may not proceed on or through any private or public property to enter the intersecting
    s4 (condition): street
    s5 (condition): where traffic is not facing a red signal
    s6 (condition): to avoid the red signal.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s3: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.intersection'], derived []
    s5: atoms ['dev.traffic_signal', 'dev.governs', 'st.lane_enters', 'st.on_way', 'st.travel_region'], derived []
    s6: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.parked']

  How each span is written.
    Selection (s2, s3): an intersection `i` (kind `intersection`), a carrier `c` (kind
      `travel_region`) with `st_lane_enters c i`, and a highway `h2` (kind `highway`) with
      `st_on_way i h2` and not `st_on_way c h2`.
    s1 + s2 (`facedRed`): the subject occupies `c` while some traffic-signal head `d` governing `c`
      or `i` (`dev_governs`) shows `circular_red` and none of the other state values of the
      enumeration (`unknown` included, being a state value other than circular_red): the record's
      "circular_red and no other state". The disjunction of the other values is one atom over its
      enumeration.
    s6 + (d) (`passingAround`): `since (¬ occupies i ∧ ¬ parked) facedRed` — at some observation
      up to the judged one `facedRed` held, and at every later one up to and including the judged
      one the subject neither occupied `i` nor was parked (drv.motion.parked with
      p.halt_speed_tolerance, p.parking_min_duration). Core's `since` takes the latest such
      observation implicitly: any earlier witness implies the latest one.
    s5 (`crossNotRed`): at the judged observation some carrier `k` of kind `travel_region` on `h2`
      entering `i` is governed by a traffic-signal head that does not show `circular_red` (the
      record's "a state other than circular_red": a head always displays some state value, so not
      showing circular_red is displaying another).
    s4: the assumption `asm.within_incorporated_city`.
    s3 (obligation): the selection is written again in full (sel ∧ passingAround, as the record's
      obligation lists it; the s5 condition is not part of its re-binding); for every such `i`, `c`,
      `h2` it is not the case that the subject occupies `h2`, does not occupy `i`, and "at the
      previous observation occupied no st.highway region". The last is `rises (∃ hw : highway,
      occupies hw)`: since the subject occupies the highway `h2` at the judged observation, "on some
      highway here and on none at the previous observation" is exactly the record's clause.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8e

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vH2 : Arg := .var "h2"
def vK : Arg := .var "k"
def vD : Arg := .var "d"
def vE : Arg := .var "e"
def vHw : Arg := .var "hw"

def occ (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []
def shows (d : Arg) (s : String) : Formula := .atom "dev_traffic_signal_shows" [d, .lit s] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []
def enters (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
def onWay (r w : Arg) : Formula := .atom "st_on_way" [r, w] []

def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

/-- Every state value of a signal head other than circular_red. -/
def otherStates : List String :=
  [ "circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- s1: head `d` displays a steady red signal alone. -/
def redAlone (d : Arg) : Formula :=
  .and (shows d "circular_red") (.not (anyOf (otherStates.map (shows d ·))))

/-- s1 + s2: the subject occupies approach `c` while a head governing `c` or `i` shows red alone. -/
def facedRed : Formula :=
  .and (occ vC)
    (.existsDevice (.lit "traffic_signal") "d"
      (.and (.or (governs vD vC) (governs vD vI)) (redAlone vD)))

/-- s6: parked, by the catalogue concept. -/
def parked : Formula := .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- (a) + (d): faced the red on `c`, and since then neither occupied `i` nor parked. -/
def passingAround : Formula := .since (.and (.not (occ vI)) (.not parked)) facedRed

/-- The selection of `i`, `c`, `h2`. -/
def selection : Formula := .and (enters vC vI) (.and (onWay vI vH2) (.not (onWay vC vH2)))

/-- s5: some approach `k` of `h2` into `i` is governed by a head not showing circular_red. -/
def crossNotRed : Formula :=
  .existsRegion (.lit "travel_region") "k"
    (.and (onWay vK vH2)
      (.and (enters vK vI)
        (.existsDevice (.lit "traffic_signal") "e"
          (.and (governs vE vK) (.not (shows vE "circular_red"))))))

/-- s3: on some highway region now and on none at the previous observation. -/
def ontoWay : Formula := .rises (.existsRegion (.lit "highway") "hw" (occ vHw))

/-- s3: comes onto `h2` outside `i` from off every public way. -/
def comesOnto : Formula := .and (occ vH2) (.and (.not (occ vI)) ontoWay)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger): Where the signal is a steady red signal alone:; s4 (condition): street; s5 (condition): where traffic is not facing a red signal; s6 (condition): to avoid the red signal. -/
def applicability : Formula :=
  .and (.asm "asm.within_incorporated_city")
    (.existsRegion (.lit "intersection") "i"
      (.existsRegion (.lit "travel_region") "c"
        (.existsRegion (.lit "highway") "h2"
          (.and selection (.and crossNotRed passingAround)))))

/-- Obligation: s3 (obligation): may not proceed on or through any private or public property to enter the intersecting -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallRegion (.lit "highway") "h2"
        (.implies (.and selection passingAround) (.not comesOnto))))

def rule : Rule :=
  { id := "NRS_484B_307_8e"
    laws := ["NRS-484B-307-8e"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_incorporated_city"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8e

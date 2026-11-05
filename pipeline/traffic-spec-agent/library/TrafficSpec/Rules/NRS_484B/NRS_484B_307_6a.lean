/-
  NRS_484B_307_6a — NRS-484B-307-6a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady yellow signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (definitional): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,
    s4 (obligation): and such vehicular traffic must not enter the intersection
    s5 (condition): when the red signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.highway', 'rel.occupies', 'kin.velocity', 'dev.traffic_signal', 'dev.governs', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived ['drv.position.approaching_intersection']
    s4: atoms ['st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']
    s5: atoms ['dev.traffic_signal', 'dev.governs'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  s2 (the binder) — `clsSubject` is the two aggregates the node claims, by their ids and nothing
  else: a vehicular member of traffic is one of which both `ru_aggregate` atoms hold. The rest of
  the subject span — using a highway, facing the signal — is a condition of the scene and stands in
  the applicability (`usesHighway`, `facesHead`), as the ontology directs: the footprint overlaps a
  region of kind highway (`rel_occupies` on an `existsRegion "highway"`), and the head governs a
  travel region the subject occupies whose entrance end is the junction, or governs the junction
  itself. `kin.velocity` carries the definition's `using any highway for purposes of travel` under
  the plan's own observable reading of that purpose: the subject's own motion is read
  (`|v_x| ≥ 0` holds exactly where the velocity is observed and is unknown where it is not), so a
  body whose motion no source reads is not decidedly a member of traffic using the way, while a
  halted vehicle at the signal still is. No speed threshold is stated and none is read.

  s1 — `steadyYellowAlone` is `dev_traffic_signal_shows d circular_yellow` conjoined with the
  denial of every other state of the head's enumeration: that conjunction is the word `alone`,
  which the atom's contract (`several states may be displayed at once`) makes necessary. `Steady`
  is the enumerated value itself, told from `flashing_yellow` and from `yellow_arrow(dir)`.

  s5 — `displays d circular_red` is read at the observation at which the entry is judged, with
  `dev_governs` tying that head to this subject's carrier or junction, as the element directs.

  s4 — the duty is `.not (drv_lane_enters_region subject i)`: no observation at which the junction
  is newly overlapped. The junction is selected again in the obligation by the whole selection that
  fixed it in the applicability (`selection`), for every head and every junction so selected.

  Choices the node left open, all recorded in task_result.md:
  (a) The judged observation. Core evaluates an obligation at an instant and sweeps the instants
      ("the sweep over instants is the always"), and a formula that looks ahead on a finite trace is
      never true. The duty is therefore judged at each observation at which the red is exhibited,
      with the warning — the steady yellow alone while this subject was approaching that junction —
      read behind it (`.since .tt (warned …)`), which is the record's "from that observation onward,
      at no later observation at which d displays circular_red".
  (b) Where the standing facing relation is read. `drv.position.approaching_intersection` (the
      subject on a carrier that runs into the junction, not yet overlapping it) is read at the
      warned observation, where the record places it; the governance of the head over that carrier
      or junction (`dev_governs`), which s5 itself reads at the condition's observation, is read at
      the judged one. The two together are the record's "facing the signal".
  (c) A carrier is not the junction it enters (`.not (.same c i)`): an intersection is no approach
      to itself, and the quantifier over travel regions would otherwise ask a carrier's entrance of
      the junction the subject stands in.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_6a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The signal head, the junction, the carrier and the way, as the quantifiers bind them. -/
def vHead : Arg := .var "d"
def vJunction : Arg := .var "i"
def vCarrier : Arg := .var "c"
def vWay : Arg := .var "w"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- The head `d` displays the state, spelled as the ontology spells it. -/
def displays (d : Arg) (state : String) : Formula :=
  .atom "dev_traffic_signal_shows" [d, .lit state] []

/-- Every state of a signal head other than the steady circular yellow: what `alone` denies. -/
def statesBesidesCircularYellow : List String :=
  [ "circular_green", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- s1: the head displays the steady circular yellow and no other state. -/
def steadyYellowAlone (d : Arg) : Formula :=
  statesBesidesCircularYellow.foldl (fun acc s => .and acc (.not (displays d s)))
    (displays d "circular_yellow")

/-- s2: the subject is using a highway — its footprint overlaps the way, and its own motion is
    read (the plan's observable reading of `for purposes of travel`). -/
def usesHighway : Formula :=
  .and (.existsRegion (.lit "highway") "w" (.atom "rel_occupies" [vSubject, vWay] []))
       (.cmp (.abs (.measure "kin_velocity" [vSubject, .lit "x"])) .ge zeroSpeed)

/-- s2, s5: the head `d` governs the junction `i` this subject faces — the travel region the
    subject occupies whose entrance end is `i`, or `i` itself. -/
def facesHead (d i : Arg) : Formula :=
  .or
    (.existsRegion (.lit "travel_region") "c"
      (.and (.not (.same vCarrier i))
        (.and (.atom "rel_occupies" [vSubject, vCarrier] [])
          (.and (.atom "st_lane_enters" [vCarrier, i] [])
                (.atom "dev_governs" [d, vCarrier] [])))))
    (.atom "dev_governs" [d, i] [])

/-- s1 with s2: at this observation the head shows the steady yellow alone while the subject is
    approaching the junction — the observation the words warn at. -/
def warned (d i : Arg) : Formula :=
  .and (steadyYellowAlone d)
       (.derived "drv_position_approaching_intersection" [vSubject, i] [])

/-- s5 with s2 and s1: the head this subject faces at the junction `i` displays the steady red
    here, and warned this subject at this or an earlier observation. -/
def selection (d i : Arg) : Formula :=
  .and (displays d "circular_red")
    (.and (facesHead d i)
      (.and usesHighway
            (.since .tt (warned d i))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger): Where the signal is a steady yellow signal alone:; s5 (condition): when the red signal is exhibited. -/
def applicability : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.existsRegion (.lit "intersection") "i"
      (selection vHead vJunction))

/-- Obligation: s4 (obligation): and such vehicular traffic must not enter the intersection -/
def obligation : Formula :=
  .forallDevice (.lit "traffic_signal") "d"
    (.forallRegion (.lit "intersection") "i"
      (.implies (selection vHead vJunction)
                (.not (.derived "drv_lane_enters_region" [vSubject, vJunction] []))))

def rule : Rule :=
  { id := "NRS_484B_307_6a"
    laws := ["NRS-484B-307-6a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["the words state the notice the steady yellow conveys — that the related green movement is being terminated, or that a steady red will follow immediately — and impose no condition on any road user's conduct and no duty of their own. The vocabulary carries no notice given to a driver, and the duty this subsection states is the following prohibition, whose verdict is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_6a

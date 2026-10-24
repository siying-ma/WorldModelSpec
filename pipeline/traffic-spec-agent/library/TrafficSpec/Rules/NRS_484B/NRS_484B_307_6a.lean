/-
  NRS_484B_307_6a — NRS-484B-307-6a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    y1 (trigger): Where the signal is a steady yellow signal alone:
    y2 (subject): Vehicular traffic facing the signal
    y3 (definitional): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,
    y4 (obligation): and such vehicular traffic must not enter the intersection
    y5 (condition): when the red signal is exhibited.

  Elements (span → atoms, derived):
    y1: atoms ['dev.traffic_signal', 'dev.governs', 'st.lane', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived []
    y2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.traffic_signal', 'dev.governs', 'st.lane', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived []
    y4: atoms ['rel.occupies', 'st.intersection', 'st.lane', 'st.lane_enters'], derived []
    y5: atoms ['dev.traffic_signal', 'dev.governs'], derived []

  y2 is the binder's class and, with y1, the applicability. "traffic" and "vehicular" are the two
  aggregates the run admitted, claimed whole and conjoined: `ru_aggregate v
  "DEF-NRS-484A-285::traffic"` and `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, each the id and
  never the classes it covers. "facing the signal" is the device's own relation, `dev_governs d l`
  on the lane `l` the subject's footprint overlaps (`rel_occupies v l`, which is also what anchors
  `l`), and that lane is an approach to the junction: `st_lane_enters l i` anchors the
  intersection `i`. `rel_bearing` is not read: which traffic a head faces is a property of the
  device, not a direction between two road users.

  y1 is the state of that head at the observation. "a steady yellow signal" is the enumeration
  value `circular_yellow`, which the ontology keeps apart from `flashing_yellow` and from
  `yellow_arrow(dir)`, so "steady" and "signal rather than arrow" are both carried by the value.
  "alone" is that no other state of that head is displayed at the same observation, and the
  contract's "several states may be displayed at once" is what makes that readable: it is written
  as the negation of `dev_traffic_signal_shows` at every other value of the enumeration — the
  three circular colours left, the two flashing ones, `dark`, `unknown`, and each of the four
  arrow families at each of the four directions (one leaf: the values of one atom's enumeration).
  A head that displays `unknown` beside the yellow is therefore not displaying the yellow alone,
  and the rule does not engage on it.

  y4 is the obligation. "enter the intersection" is the edge at which the subject's footprint
  comes to overlap the junction region — `rises (rel_occupies v i)` — and not the first overlap of
  some longer run: `rel_occupies` carries the overlap and the language's own edge operator reads
  the change, so no further atom is claimed. A vehicle that stays inside the region does not enter
  it afresh; one that withdraws and crosses in again does.

  y5 is the condition on that entry, not on the observation that engages the rule: the head shows
  `circular_red` at the entry. The enumeration keeps `circular_red` apart from `flashing_red` and
  `red_arrow(dir)`, so neither of those is this state; `dev.inoperative` is not read, a head
  showing a valid red being operative.

  The two are tied by the display this yellow opened, as the record's narrowing on y4 directs:
  from the engaging observation the duty runs while the head still shows a steady circular yellow
  or a steady circular red (`display`), and it is broken where, at an observation of that run, the
  head shows the red and the subject's footprint comes to overlap the junction. Written with the
  language's strong until: `not (until display (display ∧ red ∧ rises occupies))` — an entry after
  the head has shown any other state in between lies outside the run, and the until's φ is what
  carries "immediately thereafter". The obligation re-quantifies the head, the approach and the
  junction and repeats y1+y2 as the antecedent of an implication, so that the duty is the duty of
  the head that gave the warning and of the junction that head's approach runs into, and not of
  any other head in the scene.

  y3 is the record's residue: what a road user is warned of is a state of mind no trace carries.

  Every reading above is the record's own (its narrowings on y1, y2 and y4 included); this file
  chose none beyond them, so `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_6a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified entities: the head, the approach lane, the junction it runs into. -/
def dD : Arg := .var "d"
def lL : Arg := .var "l"
def iI : Arg := .var "i"

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula :=
  .and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- y1/y5: a state the head `d` displays at this observation. -/
def showsD (state : String) : Formula := .atom "dev_traffic_signal_shows" [dD, .lit state] []

/-- y1/y5: a state the head `d` does not display at this observation. -/
def notShowingD (state : String) : Formula := .not (showsD state)

/-- y1: "a steady yellow signal" — the circular yellow, not the flashing one and not an arrow. -/
def steadyYellow : Formula := showsD "circular_yellow"

/-- y5: "the red signal" — the circular red, not the flashing one and not an arrow. -/
def steadyRed : Formula := showsD "circular_red"

/-- y1 ("alone"): no other circular or flashing state of the head is displayed. -/
def noOtherCircular : Formula :=
  .and (notShowingD "circular_green")
    (.and (notShowingD "circular_red")
      (.and (notShowingD "flashing_red")
        (.and (notShowingD "flashing_yellow")
          (.and (notShowingD "dark") (notShowingD "unknown")))))

/-- y1 ("alone"): no green arrow of the head is displayed, in any direction. -/
def noGreenArrow : Formula :=
  .and (notShowingD "green_arrow(left)")
    (.and (notShowingD "green_arrow(right)")
      (.and (notShowingD "green_arrow(straight)") (notShowingD "green_arrow(u_turn)")))

/-- y1 ("alone"): no yellow arrow of the head is displayed, in any direction. -/
def noYellowArrow : Formula :=
  .and (notShowingD "yellow_arrow(left)")
    (.and (notShowingD "yellow_arrow(right)")
      (.and (notShowingD "yellow_arrow(straight)") (notShowingD "yellow_arrow(u_turn)")))

/-- y1 ("alone"): no red arrow of the head is displayed, in any direction. -/
def noRedArrow : Formula :=
  .and (notShowingD "red_arrow(left)")
    (.and (notShowingD "red_arrow(right)")
      (.and (notShowingD "red_arrow(straight)") (notShowingD "red_arrow(u_turn)")))

/-- y1 ("alone"): no flashing yellow arrow of the head is displayed, in any direction. -/
def noFlashingYellowArrow : Formula :=
  .and (notShowingD "flashing_yellow_arrow(left)")
    (.and (notShowingD "flashing_yellow_arrow(right)")
      (.and (notShowingD "flashing_yellow_arrow(straight)")
        (notShowingD "flashing_yellow_arrow(u_turn)")))

/-- y1 ("alone"): no state of the head other than the steady yellow is displayed. -/
def noOtherIndication : Formula :=
  .and noOtherCircular
    (.and noGreenArrow (.and noYellowArrow (.and noRedArrow noFlashingYellowArrow)))

/-- y1: the head displays a steady circular yellow and nothing else. -/
def yellowAlone : Formula := .and steadyYellow noOtherIndication

/-- y2: the head `d` faces the lane `l` whose end runs into the junction `i`, and `v`'s footprint
    overlaps that lane — the traffic facing the signal, on the approach the signal governs. -/
def facesApproach : Formula :=
  .and (.atom "rel_occupies" [vV, lL] [])
    (.and (.atom "st_lane_enters" [lL, iI] [])
      (.atom "dev_governs" [dD, lL] []))

/-- y1 + y2: the warning this head gives to `v` at this observation. -/
def warned : Formula := .and facesApproach yellowAlone

/-- Applicability: y1 (trigger): Where the signal is a steady yellow signal alone:; y2 (subject): Vehicular traffic facing the signal -/
def applicability : Formula :=
  .existsRegion (.lit "lane") "l"
    (.existsRegion (.lit "intersection") "i"
      (.existsDevice (.lit "traffic_signal") "d" warned))

/-- y4: `v` enters the junction — its footprint overlaps that region now and did not at the
    observation before. -/
def entersJunction : Formula := .rises (.atom "rel_occupies" [vV, iI] [])

/-- y1 + y5: the display this yellow opened — the head still shows the steady yellow or the
    steady red it warned of. -/
def display : Formula := .or steadyYellow steadyRed

/-- y4 + y5: at an observation of that display the head shows the red and `v` enters. -/
def entryOnRed : Formula := .and display (.and steadyRed entersJunction)

/-- y4 + y5: no such entry is made while the display runs. -/
def noEntryOnRed : Formula := .not (.until display entryOnRed)

/-- Obligation: y4 (obligation): and such vehicular traffic must not enter the intersection; y5 (condition): when the red signal is exhibited. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "l"
    (.forallRegion (.lit "intersection") "i"
      (.forallDevice (.lit "traffic_signal") "d"
        (.implies warned noEntryOnRed)))

def rule : Rule :=
  { id := "NRS_484B_307_6a"
    laws := ["NRS-484B-307-6a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := ["The words state what the yellow indication tells the driver - that the green movement is ending or that red will follow immediately. What a road user is warned of, knows or is to infer is a state of mind, which no trace carries, and these words impose no condition on the scene and no duty of their own: the duty the sentence goes on to state is the obligation span, and the timing the words describe (red exhibited immediately thereafter) is read there from the head's own state. Nothing of the subsection's duty is dropped with them."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_6a

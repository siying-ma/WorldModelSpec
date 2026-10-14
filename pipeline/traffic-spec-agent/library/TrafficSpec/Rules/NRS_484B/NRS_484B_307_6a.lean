/-
  NRS_484B_307_6a — NRS-484B-307-6a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady yellow signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (definitional): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,
    s4 (boilerplate): and
    s5 (obligation): such vehicular traffic must not enter the intersection
    s6 (condition): when the red signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=vehicle', 'rel.occupies', 'st.lane', 'st.highway', 'dev.traffic_signal', 'dev.governs'], derived []
    s5: atoms ['ru.aggregate=vehicle', 'rel.occupies', 'st.intersection', 'st.lane', 'st.lane_enters'], derived []
    s6: atoms ['dev.traffic_signal', 'dev.governs'], derived []

  How each span is written:

  s2 (subject, in `clsV` and `occupiesLaneOfHighway`). 'Vehicular traffic' is the aggregate word
  of the run's reading, written as the atom `ru_aggregate` with the binder and the literal word
  `vehicle`: the word, never the classes the reading gives it. 'using any highway for purposes of
  travel' of the definition the plan cites is the subject's footprint overlapping a lane of a
  highway: `rel_occupies` of a region the scene calls a lane (`st_lane`) and of a region it calls
  a highway (`st_highway`). The lane is the quantified `ln`, and every later span reads that same
  lane, so the rule reads the subject's own lane and not any lane of the scene. 'facing the
  signal' is `dev_governs` from the head `g` to that lane: the traffic a head faces is the traffic
  on the lane the device applies to. The head is reached by a quantifier over the scene's devices
  of kind `traffic_signal`, which is how `dev.traffic_signal` enters the subject span.

  s1 (trigger, in `steadyYellowAlone`). A steady yellow is the enumeration value
  `circular_yellow` on that head, which the enumeration keeps distinct from `flashing_yellow`;
  'alone' is that no other indication of the enumeration is displayed at the same observation,
  written as the negation of each of the other indications a signal head displays
  (`circular_green`, `circular_red`, `flashing_yellow`, `flashing_red`, `dark`). The value
  `unknown` of the same enumeration is not negated: it is the source saying it could not tell
  what was displayed, not a second indication the head displays, and a scene that carries it
  decides nothing either way. The trigger is sought at some observation in the window behind the
  instant judged (see the narrowing on s5), written `not (holdsFor .time p (not …))`: the yellow
  held at some observation of the window, which is unknown wherever the window is not covered.

  s6 (condition, in `steadyRed`). 'the red signal is exhibited' is the value `circular_red` on a
  head, which the enumeration keeps distinct from `flashing_red` and leaves the definite article
  to the governance relation: the head read is one that governs the lane the subject occupies, the
  same tie span s2 makes, so `dev_governs` is read once more here and no position atom is read.
  The node's `obligation` reads this condition at the instant of the entry ('at no observation at
  which that head displays a steady circular red'), so it is written into the obligation and not
  into the applicability: a subject that was warned by a yellow and never meets a red is engaged
  and compliant, not unengaged.

  s5 (obligation, in `noEntryWhileRed`). To enter the intersection is `rises` of
  `rel_occupies` between the subject and the intersection region: the footprint comes to overlap
  it, having not overlapped it at the previous observation. The region is the one the subject's
  own lane runs into, `st_lane_enters` from that lane to a region the scene calls an intersection
  (`st_intersection`); no crossing and no stop line is read.

  Choices the text left open, beyond the two declared narrowings:
  - the lane, the head and the intersection are quantified again in the obligation rather than
    carried from the applicability, because the two formulas bind nothing in common: the
    obligation quantifies universally over every lane the subject occupies, every head that
    governs such a lane and every intersection such a lane runs into, so a subject that enters on
    any of them is violated and the reading does not depend on which witness the applicability
    happened to find;
  - the subject's footprint must overlap a lane at the instant of the entry too (the obligation
    reads the lane it is still in while its body comes to overlap the intersection it runs into),
    which is how a body astride a stop line is read.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_6a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pYellowPhaseWindow : Term := .param "p.yellow_phase_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The quantified entities: the subject's lane, the highway it is a lane of, the head that
    governs that lane, and the intersection the lane runs into. -/
def lnV : Arg := .var "ln"
def hwV : Arg := .var "hw"
def gV : Arg := .var "g"
def ixV : Arg := .var "ix"

/-- An indication displayed on the head `g`. -/
def shows (indication : String) : Formula :=
  .atom "dev_traffic_signal_shows" [gV, .lit indication] []

/-- s1: a steady yellow and no other indication displayed on `g`. -/
def steadyYellowAlone : Formula :=
  .and (shows "circular_yellow")
    (.and (.not (shows "circular_green"))
      (.and (.not (shows "circular_red"))
        (.and (.not (shows "flashing_yellow"))
          (.and (.not (shows "flashing_red"))
                (.not (shows "dark"))))))

/-- s6: a steady red displayed on `g`. -/
def steadyRed : Formula := shows "circular_red"

/-- s2: the head `g` applies to the lane `ln` — the traffic on `ln` is the traffic facing `g`. -/
def governsThisLane : Formula := .atom "dev_governs" [gV, lnV] []

/-- s2: `v`'s footprint overlaps the lane `ln`, and a highway. -/
def occupiesLaneOfHighway : Formula :=
  .and (.atom "st_lane" [lnV] [])
    (.and (.atom "rel_occupies" [vV, lnV] [])
      (.existsRegion (.lit "highway") "hw"
        (.and (.atom "st_highway" [hwV] [])
              (.atom "rel_occupies" [vV, hwV] []))))

/-- s1: a steady yellow alone on `g` at some observation in the window behind. -/
def yellowAloneInWindow : Formula :=
  .not (.holdsFor .time pYellowPhaseWindow "v" (.not steadyYellowAlone))

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- Applicability: s1 (trigger): Where the signal is a steady yellow signal alone:; s6 (condition): when the red signal is exhibited. -/
def applicability : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and occupiesLaneOfHighway
      (.existsDevice (.lit "traffic_signal") "g"
        (.and governsThisLane yellowAloneInWindow)))

/-- Obligation: s5 (obligation): such vehicular traffic must not enter the intersection -/
def noEntryWhileRed : Formula :=
  .forallRegion (.lit "lane") "ln"
    (.implies (.and (.atom "st_lane" [lnV] []) (.atom "rel_occupies" [vV, lnV] []))
      (.forallDevice (.lit "traffic_signal") "g"
        (.implies (.and governsThisLane steadyRed)
          (.forallRegion (.lit "intersection") "ix"
            (.implies (.and (.atom "st_intersection" [ixV] [])
                            (.atom "st_lane_enters" [lnV, ixV] []))
              (.not (.rises (.atom "rel_occupies" [vV, ixV] []))))))))

def obligation : Formula := noEntryWhileRed

def rule : Rule :=
  { id := "NRS_484B_307_6a"
    laws := ["NRS-484B-307-6a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := ["The clause states what a steady yellow alone means to the traffic facing it - that the green movement is ending, or that a steady red will follow at once. It is the signal's meaning and not a duty: it puts no conduct on the road user, and what a road user was warned of, or understood, is a state of mind no trace carries. The conduct the warning leads to is stated by the obligation span that follows, which this rule carries in full, so the duty loses nothing with these words."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "'the signal' is, in the section this paragraph belongs to, an official traffic-control device: one 'placed or erected by a public authority or railroad' [DEF-NRS-484A-145]. Nothing in a scene shows who placed a head. The head's presence on the road, with its faces uncovered and an indication displayed, is the observable evidence of that status, and the rule reads the head and presumes the status."
          kind := "observable_reading" }
      , { span := "s5"
          why := "The paragraph gives the duty no horizon: on its bare words a steady yellow displayed at any earlier time would leave the traffic that saw it bound at every later red. The rule reads the yellow within a window behind the observation, so that the red the subject enters against is the red that followed the yellow this paragraph speaks of. A red exhibited longer after a yellow than the window - a head that has run through a whole phase in between - leaves the rule not applicable, which is narrower than the words."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_6a

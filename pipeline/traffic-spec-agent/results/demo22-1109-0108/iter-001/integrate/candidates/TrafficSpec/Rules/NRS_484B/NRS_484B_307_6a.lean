/-
  NRS_484B_307_6a — NRS-484B-307-6a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (trigger): Where the signal is a steady yellow signal alone:
    s1 (subject): Vehicular traffic facing the signal
    c1 (condition): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,
    ob1 (obligation): and such vehicular traffic must not enter the intersection
    c2 (condition): when the red signal is exhibited.

  Elements (span → atoms, derived):
    t1: atoms ['dev.traffic_signal'], derived []
    s1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    ob1: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.region_entry']
    c2: atoms ['dev.traffic_signal', 'dev.governs'], derived []

  How each span is written.

  s1 (subject, the binder's class): the two admitted aggregates the record claims, each as one
  `ru_aggregate` atom on the binder with the aggregate's id as its literal argument, conjoined:
  a road user of the traffic aggregate that is also of the vehicle aggregate. Neither is expanded
  into the classes it covers.

  s1 (the approach, in `applicability` and again in `obligation`): the ontology's reading of
  "facing the signal" — the subject occupies (`rel_occupies`) a carrier `c` of kind
  `st_travel_region` whose entrance end is an intersection `i` (`st_lane_enters`, `st_intersection`)
  and which a signal head `d` governs (`dev_traffic_signal`, `dev_governs`). Nothing is read from
  the subject's heading or velocity. The carrier quantifier is written over the kind the record
  names, `travel_region`, and so ranges over every kind refining it; a region of that kind which is
  no approach of the subject's is decided out by the conjunction itself (a head that governs the
  subject's carrier does not govern the junction region, so the conjunct is false there), never by
  an exclusion the record does not state.

  t1 (trigger): `dev_traffic_signal_shows d circular_yellow` on that head, "alone" being that
  state displayed and no other state of the head displayed at the observation: the conjunction of
  the negated `dev_traffic_signal_shows` of every other spelling of the indication enumeration
  (`otherIndications`), the enumeration's `unknown` among them — a head one of whose faces the
  source cannot read does not show the steady yellow alone.

  t1 with s1, in `applicability`: the record's applicability reads the trigger "at the judged
  observation or at an earlier observation while the subject was on that carrier", which is
  `.since (rel_occupies v c) (yellowAlone d)`: the yellow alone held at this or an earlier
  observation and the subject occupied that carrier at every observation after it.

  ob1 with c2 (obligation): `drv.motion.region_entry` of the subject at the junction region the
  subject's carrier enters — the footprint coming to overlap it, not lying within it — forbidden at
  an observation at which a head governing that carrier shows `circular_red`. The whole selection of
  the carrier, the junction and the head is written again here, since the applicability's bindings
  do not reach this formula. The duty is read at each selected carrier, junction and head
  (`forallRegion`, `forallDevice`): where the subject occupies several carriers entering a junction,
  the rule picks none of them, and a red face governing another approach of the junction does not
  forbid the entry, because `dev_governs` relates the head to the subject's own carrier.

  c1: the record's residue; it adds no observable condition and is written nowhere.

  Narrowings: none of this session's own. The record's narrowing on ob1 (the yellow face and the
  red face are read at different observations of the same approach) and its applicability and
  obligation statements are the plan's reading, carried here as written and not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
  This rule states no magnitude at all: it has no parameter and no quantity.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_6a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The carrier the subject occupies, the junction it enters, and the head that governs it. -/
def cV : Arg := .var "c"
def iV : Arg := .var "i"
def dV : Arg := .var "d"

/-- A road user's footprint overlaps a region. -/
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- A signal head displays an indication. -/
def shows (d : Arg) (state : String) : Formula := .atom "dev_traffic_signal_shows" [d, .lit state] []

/-- Every spelling of the signal-indication enumeration other than a steady circular yellow. -/
def otherIndications : List String :=
  [ "circular_green", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- t1: the head displays a steady circular yellow and no other state. -/
def yellowAlone (d : Arg) : Formula :=
  otherIndications.foldl (fun acc s => Formula.and acc (Formula.not (shows d s)))
    (shows d "circular_yellow")

/-- s1: the junction a carrier runs into at its entrance end. -/
def carrierEnters (c i : Arg) : Formula :=
  Formula.and (.atom "st_intersection" [i] []) (.atom "st_lane_enters" [c, i] [])

/-- s1 and t1: the head governs the subject's carrier and showed the steady yellow alone at this or
    an earlier observation while the subject was on that carrier. -/
def headWarned (d c : Arg) : Formula :=
  Formula.and (.atom "dev_traffic_signal" [d] [])
    (Formula.and (.atom "dev_governs" [d, c] [])
      (.since (occupies vV c) (yellowAlone d)))

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula :=
  Formula.and
    (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] [])
    (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: t1 (trigger): Where the signal is a steady yellow signal alone:; c1 (condition): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,; c2 (condition): when the red signal is exhibited. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (Formula.and (.atom "st_travel_region" [cV] [])
      (Formula.and (occupies vV cV)
        (Formula.and (.existsRegion (.lit "intersection") "i" (carrierEnters cV iV))
          (.existsDevice (.lit "traffic_signal") "d" (headWarned dV cV)))))

/-- Obligation: ob1 (obligation): and such vehicular traffic must not enter the intersection -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (.implies (Formula.and (.atom "st_travel_region" [cV] []) (occupies vV cV))
      (.forallRegion (.lit "intersection") "i"
        (.implies (carrierEnters cV iV)
          (.forallDevice (.lit "traffic_signal") "d"
            (.implies
              (Formula.and (.atom "dev_traffic_signal" [dV] []) (.atom "dev_governs" [dV, cV] []))
              (.implies (shows dV "circular_red")
                (.not (.derived "drv_motion_region_entry" [vV, iV] []))))))))

def rule : Rule :=
  { id := "NRS_484B_307_6a"
    laws := ["NRS-484B-307-6a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter' adds no observable condition to the prohibition: it states what the yellow face tells the driver, and the duty that follows is the same whether or not the green movement is in fact being terminated or the red in fact follows immediately. What a driver was warned of is a state of mind no trace carries, and reading the clause as a condition would make the rule apply only where the signal's programme is known, which is narrower than the words."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_6a

/-
  NRS_484B_307_6a — NRS-484B-307-6a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady yellow signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (definitional): is thereby warned that the related green movement is being terminated or that a steady red indication will be exhibited immediately thereafter,
    s4 (boilerplate): and
    s5 (subject): such vehicular traffic
    s6 (obligation): must not enter the intersection
    s7 (condition): when the red signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['rel.occupies', 'st.intersection'], derived []
    s7: atoms ['dev.governs', 'dev.traffic_signal'], derived []

  How each span is written.
    s2/s5 (class): "vehicular traffic" — the subject is a member of both admitted aggregates,
      DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle (`ru_aggregate`, conjoined: traffic
      that is vehicular). s5 refers back to s2: the same binder, the same class.
    s1 (yellow alone): head s (`existsDevice traffic_signal`) shows circular_yellow
      (`dev_traffic_signal_shows`) and no other state of the enumeration (every other spelling,
      the arrows of every direction, flashing_red, flashing_yellow, dark and unknown included).
    s2 (facing the signal): intersection i (`existsRegion intersection`), travel region c
      (`existsRegion travel_region`) with `st_lane_enters c i`, `dev_governs s c`, and the subject
      occupying c (`rel_occupies`). "Faced the yellow on this approach" is
        A(c, s) := since (occupies c) (occupies c ∧ yellowAlone s)
      — s displayed the yellow alone at some observation since the subject has occupied c without
      interruption — and the record's "at the judged observation, or at the previous one" is
        A ∨ rises (¬A)
      (where A is false now, `rises (¬A)` is exactly A at the previous observation).
    s6 + s7 (obligation): for every (i, c, s) of the same whole selection (repeated: the
      applicability's variables are not in scope in the obligation), it is not the case that the
      subject's occupancy of i rises at the judged observation (`rises (rel_occupies subject i)`:
      overlaps i now, did not at the previous observation) while s shows circular_red with no
      green arrow and no flashing yellow arrow of any direction (the record's narrowing on s6).
  No choice beyond the record's was needed; no narrowing of my own is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_6a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- A disjunction of a list of formulas (false when empty). -/
def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

def arrowDirs : List String := ["left", "right", "straight", "u_turn"]

/-- Head `d` displays the indication spelled `ind`. -/
def shows (d : String) (ind : String) : Formula :=
  .atom "dev_traffic_signal_shows" [.var d, .lit ind] []

/-- Head `d` displays any of the spellings listed. -/
def showsAny (d : String) (inds : List String) : Formula := anyOf (inds.map (shows d))

/-- Every state of the head other than circular_yellow. -/
def otherThanYellow : List String :=
  ["circular_green", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown"] ++
  arrowDirs.map (fun a => s!"green_arrow({a})") ++
  arrowDirs.map (fun a => s!"yellow_arrow({a})") ++
  arrowDirs.map (fun a => s!"red_arrow({a})") ++
  arrowDirs.map (fun a => s!"flashing_yellow_arrow({a})")

/-- The arrows whose presence beside the red takes an entry out of this duty (s6 narrowing). -/
def arrowsBesideRed : List String :=
  arrowDirs.map (fun a => s!"green_arrow({a})") ++
  arrowDirs.map (fun a => s!"flashing_yellow_arrow({a})")

/-- s1: a steady yellow signal alone. -/
def yellowAlone (d : String) : Formula :=
  .and (shows d "circular_yellow") (.not (showsAny d otherThanYellow))

/-- s7: the steady red indication, with no green arrow and no flashing yellow arrow beside it. -/
def redExhibited (d : String) : Formula :=
  .and (shows d "circular_red") (.not (showsAny d arrowsBesideRed))

/-- The subject's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- s2: the subject has occupied c without interruption since an observation at which s showed
    the yellow alone (that observation included). -/
def facedYellowNow (c d : String) : Formula :=
  .since (occ c) (.and (occ c) (yellowAlone d))

/-- s2: the above at the judged observation, or at the previous one. -/
def facedYellow (c d : String) : Formula :=
  .or (facedYellowNow c d) (.rises (.not (facedYellowNow c d)))

/-- s2: the whole selection of (i, c, s): c enters i, s governs c, and the subject faced the
    yellow alone of s on c. -/
def selection (i c d : String) : Formula :=
  .and (.atom "st_lane_enters" [.var c, .var i] [])
    (.and (.atom "dev_governs" [.var d, .var c] [])
      (facedYellow c d))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger), s2 (subject facing the signal). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s"
        (selection "i" "c" "s")))

/-- Obligation: s6 (must not enter the intersection), s7 (when the red signal is exhibited). -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "s"
        (.implies (selection "i" "c" "s")
          (.not (.and (.rises (occ "i")) (redExhibited "s"))))))

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
    residues := ["The words state what the steady yellow indication tells the traffic facing it. They impose no duty and set no condition of the duty in s6, which the rule carries in full."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_6a

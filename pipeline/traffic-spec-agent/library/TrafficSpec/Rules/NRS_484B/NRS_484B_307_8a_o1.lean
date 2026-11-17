/-
  NRS_484B_307_8a_o1 — NRS-484B-307-8a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (obligation): must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,
    s4 (boilerplate): and,
    s5 (sibling): except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],
    s6 (sibling): must remain stopped or standing until the green signal is shown.
    s7 (sibling): After complying with the requirement to stop,
    s8 (sibling): vehicular traffic facing such a signal and situated on the extreme right of the highway
    s9 (sibling): may proceed into the intersection
    s10 (sibling): for a right turn
    s11 (sibling): only when the intersecting highway is two-directional or one-way to the right,
    s12 (sibling): or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway
    s13 (sibling): may proceed into the intersection
    s14 (sibling): for a left turn
    s15 (sibling): only when the intersecting highway is one-way to the left,
    s16 (sibling): but must yield
    s17 (sibling): the right-of-way
    s18 (sibling): to pedestrians and other traffic proceeding as directed by the signal at the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s3: atoms ['prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.region_geometry', 'st.stop_line'], derived ['drv.motion.complete_halt']

  How each span is written:
    subject class (s2): ru_aggregate traffic AND ru_aggregate vehicle ("vehicular traffic": traffic
      that is a vehicle), the aggregate ids as literal arguments.
    s2 + applicability: an intersection i, a travel region c and a traffic-signal head s such that
      the subject occupies i now and, at the previous observation, did not occupy i while it
      occupied c with st_lane_enters c i and dev_governs s c. "At the previous observation" is
      written with `rises`: with occ i true now, rises (occ i ∨ ¬F) is exactly "F ∧ ¬occ i at the
      previous observation" (unknown at the first observation, as the record requires).
    s1: dev_traffic_signal_shows s circular_red and not shows s of every other state spelling
      (circular green/yellow, flashing red/yellow, dark, unknown, every arrow in every direction):
      "steady red alone".
    s3 (obligation), re-selecting i, c, s with the applicability's whole selection (rule 3c), for
      every selected triple: the place is, in order, every stop line recorded as marking c
      (st_entrance_of); where none is (every line's list observed and excluding c), every crosswalk
      recorded as marking c; where none is, the intersection i itself (its edge). For a place r:
        zone(r)  = occ c ∧ ¬occ i ∧ (every crosswalk marking c not occupied) ∧
                   prim_region_offset_along(subject, r, c) ≥ 0 (place ahead or on it, along c's
                   direction) ∧ st_region_geometry_distance(subject, r) ≤ p.stop_point_tolerance
        halt(r)  = drv_motion_complete_halt(subject, p.halt_speed_tolerance) ∧ zone(r)
        start(r) = occ c ∧ ¬occ r ∧ offset > 0 ∧ distance > p.stop_point_tolerance (approach start)
        prior    = occ i ∧ rises(occ i ∨ ¬occ c) (an entry into i from c)
        search(r)= since (¬start(r) ∧ ¬prior) halt(r)
      read at the observation before the entry (the same `rises` device as above), so the current
      entry is not itself an end of the search. A halt found: true; an end reached first: false;
      the trace start reached first: unknown (`since` truncated), the history-boundary case.
  No choice beyond the record's own obligation text was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the intersection entered, the approach carrier, the signal head, a stop
    line, a crosswalk, and a crosswalk read inside the stopping zone. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vL : Arg := .var "l"
def vX : Arg := .var "x"
def vXz : Arg := .var "xz"

def occ (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []
def marks (mark carrier : Arg) : Formula := .atom "st_entrance_of" [mark, carrier] []
def shows (sig : Arg) (ind : String) : Formula := .atom "dev_traffic_signal_shows" [sig, .lit ind] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- s2: on c, whose entrance end is i and which s governs. -/
def facing : Formula :=
  .and (occ vC) (.and (.atom "st_lane_enters" [vC, vI] []) (.atom "dev_governs" [vS, vC] []))

/-- The entry: in i now; at the previous observation not in i and facing s on c. -/
def entry : Formula :=
  .and (occ vI) (.rises (.or (occ vI) (.not facing)))

/-- Every state a head may display other than circular_red. -/
def otherStates : List String :=
  [ "circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- s1: a steady red alone. -/
def redAlone : Formula :=
  otherStates.foldl (fun acc st => .and acc (.not (shows vS st))) (shows vS "circular_red")

/-- The whole selection of i, c and s, shared by the applicability and the obligation. -/
def selection : Formula := .and entry redAlone

def overSelection (body : Formula → Formula) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s" (body selection)))

/-- Applicability: s1 (trigger): Where the signal is a steady red signal alone: -/
def applicability : Formula := overSelection id

-- s3: the stopping zone, the halt, the approach start and the prior entry, for a place r.
def offsetAlong (r : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, r, vC] []
def gapTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, r]

def clearOfCrosswalk : Formula :=
  .forallRegion (.lit "crosswalk") "xz" (.implies (marks vXz vC) (.not (occ vXz)))

def inZone (r : Arg) : Formula :=
  .and (occ vC)
    (.and (.not (occ vI))
      (.and clearOfCrosswalk
        (.and (.cmp (offsetAlong r) .ge zeroMetres)
              (.cmp (gapTo r) .le pStopPointTolerance))))

def haltAt (r : Arg) : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]) (inZone r)

def approachStart (r : Arg) : Formula :=
  .and (occ vC)
    (.and (.not (occ r))
      (.and (.cmp (offsetAlong r) .gt zeroMetres)
            (.cmp (gapTo r) .gt pStopPointTolerance)))

def priorEntry : Formula :=
  .and (occ vI) (.rises (.or (occ vI) (.not (occ vC))))

def search (r : Arg) : Formula :=
  .since (.and (.not (approachStart r)) (.not priorEntry)) (haltAt r)

/-- The search read at the observation before the entry (the subject is in i now, not then). -/
def stoppedBefore (r : Arg) : Formula :=
  .rises (.or (occ vI) (.not (search r)))

def duty : Formula :=
  .and (.forallRegion (.lit "stop_line") "l" (.implies (marks vL vC) (stoppedBefore vL)))
    (.implies (.not (.existsRegion (.lit "stop_line") "l" (marks vL vC)))
      (.and (.forallRegion (.lit "crosswalk") "x" (.implies (marks vX vC) (stoppedBefore vX)))
        (.implies (.not (.existsRegion (.lit "crosswalk") "x" (marks vX vC)))
          (stoppedBefore vI))))

/-- Obligation: s3 (obligation): must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "s" (.implies selection duty)))

def rule : Rule :=
  { id := "NRS_484B_307_8a_o1"
    laws := ["NRS-484B-307-8a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8a_o1

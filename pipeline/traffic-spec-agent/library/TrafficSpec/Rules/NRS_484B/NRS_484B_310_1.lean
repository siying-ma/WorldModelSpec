/-
  NRS_484B_310_1 — NRS-484B-310-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Whenever an illuminated flashing red or yellow signal is used in conjunction with an official traffic-control device,
    s2 (subject): it shall require obedience by vehicular traffic as follows:
    s3 (trigger): When a red lens is illuminated with rapid intermittent flashes,
    s4 (subject): drivers of vehicles
    s5 (obligation): shall stop before entering the nearest crosswalk in an intersection or at a limit line when marked, or, if none, then before entering the intersection,
    s6 (reference): and the right to proceed shall be subject to the rules applicable after making a required stop.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['drv.motion.complete_halt', 'prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.lane_enters', 'st.region_geometry', 'st.stop_line'], derived ['drv.motion.complete_halt']

  How each span is written.
    s2, s4 (class): `ru_aggregate` of the subject under both admitted aggregates, conjoined
      (vehicular traffic = traffic limited to its vehicle members).
    s1, s3 (applicability): some intersection `i` and some travel region `c` such that
      - the subject enters `i` through `c`: it occupies `i` here, and at the previous observation it
        occupied `c` and not `i`. "At the previous observation" is written with `rises`:
        `occ i ∧ rises (occ i ∨ ¬ occ c)` is exactly "occ i here, and (¬occ i ∧ occ c) before"; it is
        unknown where the previous observation is missing (the trace start) or undecided;
      - `c` enters `i` (`st_lane_enters c i`);
      - some traffic-signal head governing `c` or `i` (`dev_governs`) shows `flashing_red`
        (`dev_traffic_signal_shows`); its official status is its presence (the record's s1 reading).
    s5 (obligation): for every intersection `i` and travel region `c` selected exactly as in the
      applicability (rule 3c: the whole selection, signal included, is restated), a stop made:
      - halt at a mark `m` (a stop line or a crosswalk, two alternatives, each its own quantifier)
        recorded as marking `c` (`st_entrance_of m c`): `drv_motion_complete_halt` (speed tolerance
        p.halt_speed_tolerance), body-to-mark distance (`st_region_geometry_distance`) within
        p.stop_point_tolerance, short of `m` along `c`'s direction (`prim_region_offset_along` > 0,
        which reads `st.lane_direction`), not overlapping `m` nor `i` (`rel_occupies`);
      - "if none": where no stop line and no crosswalk is recorded as marking `c` (decided only
        where the marks' entrance lists are observed), the same halt short of `i`'s edge.
      History bound: `since searchGoesOn haltFound`, where the search goes on while the subject is
      not at the approach start and does not occupy `i` (an earlier occupancy of `i` is the
      previous entry: the observation before the judged entry never occupies `i`). The approach
      start for marks: at least one mark marks `c`, and for each mark marking `c` the subject is on a
      carrier that mark marks (`∃ c2, occ c2 ∧ st_entrance_of m c2`), off it, short of it along
      `c` and farther from it than p.stop_point_tolerance. `since` fails on the end reached without a
      halt, holds on a halt found, and is unknown (`windowTruncated "since"`) where the search
      reaches the recording's start: never a verdict from the recording's start.
      The search runs back from the observation before the entry: at the entry the subject occupies
      `i`, so `since` is definitely false there (no halt can be made while overlapping `i`, and the
      search does not go on through `i`); `rises (¬ since …)` at the entry is therefore exactly the
      value of `since …` at the previous observation.
      Several carriers: by the `st.lane_enters` contract, where the subject occupies several
      carriers entering the same intersection and the verdict differs between them, which governs is
      unknown. Per intersection, the duty over every selected carrier is read where all selected
      carriers agree (`definedWhen` (all comply ∨ all fail)), unknown where they differ; the rule
      never picks the carrier that favours the road user.
    s6 (reference): residue, as the record states.

  Choice the record left open (declared in `narrowings`):
    s5: the record's approach start is written for marks; for the "if none" alternative the
      approach start is read the same way against `i`'s edge: the subject on a carrier entering `i`,
      not overlapping `i`, short of it along `c` and farther from it than p.stop_point_tolerance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_310_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the intersection entered, the approach carrier, a signal head, a mark,
    and the carrier the subject is on during the search back. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vM : Arg := .var "m"
def vC2 : Arg := .var "c2"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------
/-- The subject's footprint overlaps region `r` (`rel.occupies`). -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- Ground distance from the subject's body to region `r` (`st.region_geometry`). -/
def dist (r : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, r]

/-- Signed distance to `r` along the approach carrier `c`'s direction (`prim.region_offset_along`,
    reading `st.lane_direction`): positive where `r` lies ahead. -/
def offsetAlong (r : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, r, vC] []

/-- The subject at rest (`drv.motion.complete_halt`). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- Carrier `x` enters the intersection `i` (`st.lane_enters`). -/
def entersI (x : Arg) : Formula := .atom "st_lane_enters" [x, vI] []

/-- Mark `mk` is recorded as marking carrier `x`'s entrance (`st.entrance_of`). -/
def marks (mk x : Arg) : Formula := .atom "st_entrance_of" [mk, x] []

-- ---------------------------------------------------------------------------------------------
-- Class (s2, s4)
-- ---------------------------------------------------------------------------------------------
/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

-- ---------------------------------------------------------------------------------------------
-- Selection of i and c (s1, s3), shared by applicability and obligation
-- ---------------------------------------------------------------------------------------------
/-- s1, s3: a traffic-signal head governing `c` or `i` displays flashing red. -/
def flashingRed : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.or (.atom "dev_governs" [vD, vC] []) (.atom "dev_governs" [vD, vI] []))
          (.atom "dev_traffic_signal_shows" [vD, .lit "flashing_red"] []))

/-- The subject enters `i` here from `c`, which it occupied (and `i` not) at the previous
    observation; `c` enters `i`. -/
def entryThrough : Formula :=
  .and (occ vI) (.and (.rises (.or (occ vI) (.not (occ vC)))) (entersI vC))

/-- The record's whole selection of `i` and `c`. -/
def selection : Formula := .and entryThrough flashingRed

/-- Applicability: s1 (trigger): Whenever an illuminated flashing red or yellow signal is used in conjunction with an official traffic-control device,; s3 (trigger): When a red lens is illuminated with rapid intermittent flashes, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" selection)

-- ---------------------------------------------------------------------------------------------
-- Obligation (s5)
-- ---------------------------------------------------------------------------------------------
/-- A halt with the body within the stop-point tolerance of `r`, short of it along `c`, not
    overlapping it. -/
def haltShortOf (r : Arg) : Formula :=
  .and halted
    (.and (.cmp (dist r) .le pStopPointTolerance)
      (.and (.cmp (offsetAlong r) .gt zeroMetres) (.not (occ r))))

/-- A halt short of a mark of kind `k` recorded as marking `c`, not overlapping `i`. -/
def haltAtMark (k : String) : Formula :=
  .existsRegion (.lit k) "m" (.and (marks vM vC) (.and (haltShortOf vM) (.not (occ vI))))

/-- A mark of kind `k` is recorded as marking `c`. -/
def hasMark (k : String) : Formula := .existsRegion (.lit k) "m" (marks vM vC)

/-- A stop line or a crosswalk marks `c`; its negation is "if none" (decided only where the
    entrance lists are observed). -/
def anyMark : Formula := .or (hasMark "stop_line") (hasMark "crosswalk")

/-- The halt the words require: at either mark marking `c`, or, if none, short of `i`'s edge. -/
def haltFound : Formula :=
  .or (.or (haltAtMark "stop_line") (haltAtMark "crosswalk"))
      (.and (.not anyMark) (haltShortOf vI))

/-- Outside the stopping zone of `r`, upstream: off it, short of it along `c`, farther from it than
    the stop-point tolerance. -/
def outsideZone (r : Arg) : Formula :=
  .and (.not (occ r))
    (.and (.cmp (offsetAlong r) .gt zeroMetres) (.cmp (dist r) .gt pStopPointTolerance))

/-- For every mark of kind `k` marking `c`: the subject is on a carrier that mark marks and
    outside its stopping zone upstream. -/
def outsideMarks (k : String) : Formula :=
  .forallRegion (.lit k) "m"
    (.implies (marks vM vC)
      (.and (.existsRegion (.lit "travel_region") "c2" (.and (occ vC2) (marks vM vC2)))
            (outsideZone vM)))

/-- The subject is on a carrier entering `i`. -/
def onApproachToI : Formula :=
  .existsRegion (.lit "travel_region") "c2" (.and (occ vC2) (entersI vC2))

/-- The approach start: outside the zone of each mark marking `c` (where some mark does), or, if
    none, outside `i`'s zone at `c`'s entrance end. -/
def approachStart : Formula :=
  .or (.and anyMark (.and (outsideMarks "stop_line") (outsideMarks "crosswalk")))
      (.and (.not anyMark) (.and onApproachToI (outsideZone vI)))

/-- The search back goes on: neither the approach start nor the previous entry into `i`. -/
def searchGoesOn : Formula := .and (.not approachStart) (.not (occ vI))

/-- A halt found, searching back, before either end of the search. -/
def haltSinceBound : Formula := .since searchGoesOn haltFound

/-- At the entry `haltSinceBound` is definitely false (the subject occupies `i`); its rise to
    false is therefore its value at the previous observation: the search runs back from there. -/
def stopMade : Formula := .rises (.not haltSinceBound)

/-- The duty for every carrier selected for `i`. -/
def everySelected (duty : Formula) : Formula :=
  .forallRegion (.lit "travel_region") "c" (.implies selection duty)

/-- Obligation: s5 (obligation): shall stop before entering the nearest crosswalk in an intersection or at a limit line when marked, or, if none, then before entering the intersection, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.definedWhen (.or (everySelected stopMade) (everySelected (.not stopMade)))
      (everySelected stopMade))

def rule : Rule :=
  { id := "NRS_484B_310_1"
    laws := ["NRS-484B-310-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["The words subject the right to proceed after the stop to 'the rules applicable after making a required stop' without naming any rule of the corpus; this node judges the stop, and the proceeding is judged by those rules on their own terms."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "The record states the approach start that ends the search back only for marks; for the 'if none' alternative it is read the same way against the intersection's edge: the subject on a carrier entering the intersection, not overlapping it, short of it along the approach carrier's direction and farther from it than the stop-point tolerance."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_310_1

/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (exception): Except when traffic is being controlled by a police officer
    b (exception): or a traffic-control signal:
    c (trigger): When proper signs have been erected,
    d (subject): the driver of a vehicle
    e (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    j (sibling): After having stopped or, in the event of a yield sign, slowed or stopped,
    k (sibling): the driver shall yield
    l (sibling): the right-of-way
    m (sibling): to other vehicles which have entered the intersection from such through highway
    n (sibling): or which are approaching so closely on such through highway as to constitute an immediate hazard
    o (sibling): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.travel_region'], derived []
    b: atoms ['dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    c: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    d: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e: atoms ['kin.speed', 'st.stop_line', 'st.entrance_of', 'prim.region_offset_along', 'st.lane_direction', 'st.region_geometry', 'st.crosswalk', 'rel.occupies', 'st.intersection', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.complete_halt']

  How each span is written:
    d  — the subject's class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    c  — the entry (`entry X c`): the subject's footprint overlaps the intersection X now and not at
         the previous observation (`rises (rel_occupies subject X)`), and at that previous
         observation it occupied the carrier c and not X (`since (occ X) (occ c ∧ ¬occ X)`, which at
         a rise of `occ X` reads exactly the previous observation); `st_lane_enters c X`; a stop
         sign or a yield sign governs c or X (`dev_governs`). X ranges over `intersection`, c over
         `travel_region` (the kind `dev.governs` and the entry topology admit).
    a  — the subject is a member of DEF-NRS-484A-285::traffic and a `human_direction` device of role
         `police_officer` governs c or X: an exception, negated in the applicability.
    b  — a `traffic_signal` governing c or X that is not `dev_inoperative`: an exception.
    e  — the obligation re-selects X and c by the whole selection of the applicability (entry,
         lane_enters, a stop or yield sign governing c or X) and owes the act for every pair so
         selected (`forallRegion … implies`): no carrier is picked in the subject's favour.
         The act (`act X c`): occupying c, within the stopping zone of the place for c, and either
         a complete halt (`drv_motion_complete_halt`, p.halt_speed_tolerance) where a stop sign
         governs c or X, or, where none does (so only a yield sign does), `kin_speed` at or below
         p.yield_line_speed_max. The place, in the words' order: (1) a stop line L with
         `st_entrance_of L c`, `prim_region_offset_along subject L c ≥ 0` and the body within
         p.stop_point_tolerance of L (`st_region_geometry_distance`); (2) where no stop line marks
         c, a crosswalk W with `st_entrance_of W c`, the footprint not overlapping W, W ahead
         (offset ≥ 0) and the body within the tolerance; (3) where neither marks c, the footprint
         not overlapping X and the body within the tolerance of X.
         The approach start (`approachStart X c`): occupying c, and short of the place's stopping
         zone — every stop line marking c ahead (offset > 0) and farther than the tolerance; where
         none, every crosswalk marking c so; where neither, X ahead and farther than the tolerance.
         The search is `since (¬ end) act`: from the entry back to the latest end, the end
         observation included (no act is possible at an approach start, which lies outside the
         zone). At the entry itself the end does not hold (the subject is in X, so off c and past
         every mark), so the act may also be the entry observation.
         Truncation at the recording's start leaves the verdict unknown (`since`), never decided.

  Choices the record left open (declared as narrowings below):
    e  — the bound "the subject's previous entry into X" is written as the subject's observed exit
         from X following it (`rises (¬ rel_occupies subject X)`): one `since` cannot tell the judged
         entry from an earlier one at the same intersection, so the search stops at the first
         observation off X after the earlier entry. An act performed while the footprint still
         overlaps X after an earlier entry does not count for the next entry.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldLineSpeedMax : Term := .param "p.yield_line_speed_max"

def zeroMetres : Term := .lit Q.zero .metre

/-- The subject's footprint overlaps region `r` (rel.occupies). -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Device `d` governs region `r` (dev.governs). -/
def gov (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- Device `d` governs carrier `c` or intersection `x`. -/
def govEither (d c x : String) : Formula := .or (gov d c) (gov d x)

/-- Mark `l` (a stop line or a crosswalk) marks carrier `c`'s entrance (st.entrance_of). -/
def marks (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []

/-- Signed distance from the subject's reference point to region `r` along `c`'s direction. -/
def along (r c : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var r, .var c] []

/-- Ground distance from the subject's body to region `r` (st.region_geometry). -/
def dist (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]

/-- A stop sign governs c or X. -/
def stopGoverns (c x : String) : Formula :=
  .existsDevice (.lit "stop_sign") "D" (govEither "D" c x)

/-- A yield sign governs c or X. -/
def yieldGoverns (c x : String) : Formula :=
  .existsDevice (.lit "yield_sign") "Y" (govEither "Y" c x)

/-- Span c: the subject's entry into X from carrier c, c an approach to X, under a stop or a
    yield sign governing c or X. -/
def selection (x c : String) : Formula :=
  .and (.rises (occ x))
    (.and (.since (occ x) (.and (occ c) (.not (occ x))))
      (.and (.atom "st_lane_enters" [.var c, .var x] [])
        (.or (stopGoverns c x) (yieldGoverns c x))))

/-- Span a: traffic, the subject among it, controlled by a police officer governing c or X. -/
def officerControls (c x : String) : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.existsDevice (.lit "human_direction") "H"
      (.and (.atom "dev_human_direction_role" [.var "H", .lit "police_officer"] [])
        (govEither "H" c x)))

/-- Span b: a traffic signal that is not inoperative governs c or X. -/
def signalControls (c x : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "S"
    (.and (govEither "S" c x) (.not (.atom "dev_inoperative" [.var "S"] [])))

/-- A stop line marks c. -/
def hasLine (c : String) : Formula := .existsRegion (.lit "stop_line") "L" (marks "L" c)

/-- A crosswalk marks c. -/
def hasCrosswalk (c : String) : Formula := .existsRegion (.lit "crosswalk") "W" (marks "W" c)

/-- Within the stopping zone of the place for c, in the words' order. -/
def inZone (x c : String) : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "L"
      (.and (marks "L" c)
        (.and (.cmp (along "L" c) .ge zeroMetres) (.cmp (dist "L") .le pStopPointTolerance))))
    (.and (.not (hasLine c))
      (.or
        (.existsRegion (.lit "crosswalk") "W"
          (.and (marks "W" c)
            (.and (.not (occ "W"))
              (.and (.cmp (along "W" c) .ge zeroMetres) (.cmp (dist "W") .le pStopPointTolerance)))))
        (.and (.not (hasCrosswalk c))
          (.and (.not (occ x)) (.cmp (dist x) .le pStopPointTolerance)))))

/-- The act: on c within the zone, halted where a stop sign governs, else (a yield sign) at or
    below the yield speed. -/
def act (x c : String) : Formula :=
  .and (occ c)
    (.and
      (.or (.and (stopGoverns c x) (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))
           (.and (.not (stopGoverns c x)) (.cmp (.measure "kin_speed" [vSubject]) .le pYieldLineSpeedMax)))
      (inZone x c))

/-- The approach start: on c, short of the place's stopping zone (ahead of the subject along c's
    direction and farther than the tolerance; of every mark of that kind marking c). -/
def approachStart (x c : String) : Formula :=
  .and (occ c)
    (.or
      (.and (hasLine c)
        (.forallRegion (.lit "stop_line") "L"
          (.implies (marks "L" c)
            (.and (.cmp (along "L" c) .gt zeroMetres) (.cmp (dist "L") .gt pStopPointTolerance)))))
      (.and (.not (hasLine c))
        (.or
          (.and (hasCrosswalk c)
            (.forallRegion (.lit "crosswalk") "W"
              (.implies (marks "W" c)
                (.and (.cmp (along "W" c) .gt zeroMetres) (.cmp (dist "W") .gt pStopPointTolerance)))))
          (.and (.not (hasCrosswalk c))
            (.and (.cmp (along x c) .gt zeroMetres) (.cmp (dist x) .gt pStopPointTolerance))))))

/-- The end of the search: the approach start, or the subject's exit from X after an earlier
    entry (narrowing on e). -/
def searchEnd (x c : String) : Formula :=
  .or (approachStart x c) (.rises (.not (occ x)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: a (exception): Except when traffic is being controlled by a police officer; b (exception): or a traffic-control signal:; c (trigger): When proper signs have been erected, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X"
    (.existsRegion (.lit "travel_region") "c"
      (.and (selection "X" "c")
        (.and (.not (officerControls "c" "X")) (.not (signalControls "c" "X")))))

/-- Obligation: e (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (selection "X" "c")
        (.since (.not (searchEnd "X" "c")) (act "X" "c"))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "e"
          why := "The history bound 'the subject's previous entry into X' is written as the subject's observed exit from X following that entry (rises of not rel_occupies(subject, X)): a single since cannot tell the judged entry from an earlier one at the same intersection, so the search stops at the first observation off X after the earlier entry, and an act performed while the footprint still overlaps X after an earlier entry does not count toward the next entry."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1

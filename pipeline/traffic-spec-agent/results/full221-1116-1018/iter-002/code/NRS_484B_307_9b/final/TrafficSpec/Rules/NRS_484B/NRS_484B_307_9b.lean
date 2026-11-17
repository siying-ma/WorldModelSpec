/-
  NRS_484B_307_9b — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red with a green turn arrow:
    s2 (subject): A person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter
    s3 (trigger): facing the signal
    s4 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow
    s5 (boilerplate): if:
    s6 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields
    s7 (standard): the right-of-way
    s8 (condition): to pedestrians lawfully within an adjacent crosswalk
    s9 (condition): and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s3: atoms ['dev.governs', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s4: atoms ['dev.traffic_signal', 'rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region', 'drv.motion.u_turn_through_region']
    s6: atoms ['drv.motion.complete_halt', 'prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.lane_enters', 'st.region_geometry', 'st.stop_line', 'dev.governs', 'dev.traffic_signal', 'st.travel_region', 'dev.regulatory_sign', 'kin.speed', 'rel.contact', 'ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived ['drv.motion.complete_halt', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']
    s8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.intersection'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 2 count — two. The only operator that counts cycles is `Formula.count`, whose bound is a
      natural number (`twoCycles`); `Formula.literals` does not read that bound, so the gate sees no
      formula literal for it (reported in task_result.md).

  How each span is written.
    s2 — the binder class: the five admitted aggregates by id, and ru_motorcycle for the undefined
      word "trimobile", in one disjunction.
    Occasion (event act; onset = entry into i, recognition = exit from i). The rule is judged at
      the exit, `exitI` = rises (not occupies(subject, i)). The entry is `entryI` = rises
      (occupies(subject, i)); the latest entry is reached from the exit by
      `since (not entryI) (entryI ∧ …)`, so what is read there is read at the onset of the passage
      being recognised and never at an earlier one.
    s1 + s3 (some_moment, read at that entry): some travel region c the subject occupies with
      st_lane_enters(c, i), and some traffic-signal head d governing c or i that shows circular_red
      and green_arrow(dir) and not circular_green; dir is left or right, one disjunct each, so the
      arrow read at the entry is the one whose direction the passage is held against.
    s4 (at_recognition): at the exit, for dir left not drv_motion_left_turn_through_region, for dir
      right not drv_motion_right_turn_through_region, and not drv_motion_u_turn_through_region.
    Obligation: for every intersection i, at the exit, the duties for every carrier c and head d of
      the selection (occupied carrier entering i; head governing c or i, showing steady red with a
      green turn arrow and no circular_green), read at the latest entry.
    (1) Halt. Per kind of mark (stop line, crosswalk): some mark m with st_entrance_of(m, c) and,
      searching back with `since`, a halt (drv_motion_complete_halt, p.halt_speed_tolerance) with
      st_region_geometry_distance(subject, m) ≤ p.stop_point_tolerance,
      prim_region_offset_along(subject, m, c) > 0 (m ahead along c's direction), not occupying m nor
      i; or, where every stop line and crosswalk is decided not to mark c, a halt within the
      tolerance of i, i ahead along c, not occupying i. The search ends (its left operand fails) at
      the approach start — occupying c, off the mark, the mark ahead and farther than the tolerance —
      or at the subject's previous passage through i, which the search meets at that passage's exit
      (rises (not occupies(subject, i))): from the previous entry to that exit the subject occupies
      i, where no halt counts, so ending at the exit ends where ending at the previous entry does,
      and the current entry is no exit, so the search does not stop at its own start.
    (2) + (3) Wait. At the place (the same place test as (1), any of its three forms), searching back
      to the previous passage: the last observation j at rest at the place before the entry (from
      j to the entry the subject is not at rest there) has
      count(circular_red ∧ green turn arrow, drv_motion_complete_halt, ge, 2) — the rises of the
      display since the start of the subject's run at rest, which is its run at rest at the place,
      since a road user at rest does not change place — and, from the observation before that run
      to j, the subject is at rest at the place and the head shows no circular_green.
    (4) At the entry, for the selected c: where the passage's exit (the first exit from the entry,
      reached with `until`) is a right turn, no regulatory sign with code no_right_turn governs c or
      i; where a left turn, none with no_left_turn. The turn is read at its recognition, the sign at
      the entry.
    (5) s7/s8/s9: at no observation from the entry to the exit (`¬ since (¬entryI) (¬Y)`) does Y fail,
      Y: where kin_speed(subject) > p.halt_speed_tolerance, for every road user u other than the
      subject that is a pedestrian (DEF-NRS-484A-165::pedestrian) occupying a crosswalk recorded
      (st_entrance_of) as marking a travel region that enters i, or a member of
      DEF-NRS-484A-285::traffic occupying i: not (prim_closest_approach_within(subject, u,
      p.conflict_horizon) ∧ prim_closest_approach_distance(subject, u, p.conflict_horizon) <
      p.conflict_centre_clearance) and not rel_contact(subject, u).

  Choices the record left open (declared as narrowings on s6 below):
    - The wait of (2) and the no-change of (3) are read in the subject's latest run at rest at the
      place before the entry.
    - In the duties the head is re-bound as a head showing steady red with a green turn arrow, left
      or right, and a cycle is a rise of that display: the arrow's direction is not told apart in
      the duties (it is in the applicability, where the passage is held against it).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- s6 (2): "two" complete cycles — the text's literal, a count, as `Formula.count` takes it. -/
def twoCycles : Nat := 2

-- ---------------------------------------------------------------------------------------------
-- Building blocks
-- ---------------------------------------------------------------------------------------------
def andAll : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (andAll rest)

def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def occS (r : String) : Formula := occ "subject" r

/-- Onset: the subject's footprint comes to overlap i. -/
def entryI : Formula := .rises (occS "i")
/-- Recognition: the subject's footprint ceases to overlap i. -/
def exitI : Formula := .rises (.not (occS "i"))

def turnParams : List Term := [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]
def leftTurn : Formula := .derived "drv_motion_left_turn_through_region" [vSubject, .var "i"] turnParams
def rightTurn : Formula := .derived "drv_motion_right_turn_through_region" [vSubject, .var "i"] turnParams
def uTurn : Formula :=
  .derived "drv_motion_u_turn_through_region" [vSubject, .var "i"] [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin]

def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var "d", .lit ind] []
def red : Formula := shows "circular_red"
def green : Formula := shows "circular_green"
def arrow (dir : String) : Formula := shows s!"green_arrow({dir})"
def anyArrow : Formula := .or (arrow "left") (arrow "right")

/-- s3: the carrier c the subject occupies runs into i. -/
def carrierSel : Formula :=
  .and (occS "c") (.atom "st_lane_enters" [.var "c", .var "i"] [])
/-- s1 + s3: the head d governs c or i and shows steady red with the green arrow, no green. -/
def headSel (arr : Formula) : Formula :=
  andAll [.or (governs "d" "c") (governs "d" "i"), red, arr, .not green]

/-- s1 + s3 + s4 at the exit, for one arrow direction: the latest entry had the selection, and the
    passage is neither a turn in the arrow's direction nor a reversal. -/
def occasionAt (dir : String) : Formula :=
  andAll
    [ .not (if dir == "left" then leftTurn else rightTurn)
    , .not uTurn
    , .since (.not entryI)
        (.and entryI
          (.existsRegion (.lit "travel_region") "c"
            (.and carrierSel (.existsDevice (.lit "traffic_signal") "d" (headSel (arrow dir)))))) ]

-- (1) Halt and the place ------------------------------------------------------------------------
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]
def offsetAlong (r : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var r, .var "c"] []
def marks (m : String) : Formula := .atom "st_entrance_of" [.var m, .var "c"] []

/-- At the mark: within the tolerance, short of it along c, not on it nor in i. -/
def nearMark : Formula :=
  andAll [.cmp (distTo "m") .le pStopPointTolerance, .cmp (offsetAlong "m") .gt zeroMetres,
          .not (occS "m"), .not (occS "i")]
/-- Approach start for a mark: on c, off the mark, short of it and farther than the tolerance. -/
def approachStartMark : Formula :=
  andAll [occS "c", .not (occS "m"), .cmp (offsetAlong "m") .gt zeroMetres,
          .cmp (distTo "m") .gt pStopPointTolerance]
/-- At i's edge at c's entrance end, not in i. -/
def nearEdge : Formula :=
  andAll [.cmp (distTo "i") .le pStopPointTolerance, .cmp (offsetAlong "i") .gt zeroMetres, .not (occS "i")]
def approachStartEdge : Formula :=
  andAll [occS "c", .not (occS "i"), .cmp (offsetAlong "i") .gt zeroMetres,
          .cmp (distTo "i") .gt pStopPointTolerance]

/-- The marks' lists are observed and no stop line or crosswalk marks c. -/
def noMark : Formula :=
  .and (.forallRegion (.lit "stop_line") "m" (.not (marks "m")))
       (.forallRegion (.lit "crosswalk") "m" (.not (marks "m")))

/-- The place: at a stop line or crosswalk marking c, or at i's edge where none marks c. -/
def atPlace : Formula :=
  .or (.existsRegion (.lit "stop_line") "m" (.and (marks "m") nearMark))
    (.or (.existsRegion (.lit "crosswalk") "m" (.and (marks "m") nearMark))
         (.and noMark nearEdge))
def atRestThere : Formula := .and halted atPlace

/-- (1) at the entry: a halt at the place, searched back to the approach start or the previous
    passage through i. -/
def haltAtMark (kind : String) : Formula :=
  .existsRegion (.lit kind) "m"
    (.and (marks "m") (.since (.not (.or approachStartMark exitI)) (.and halted nearMark)))
def haltDuty : Formula :=
  .or (haltAtMark "stop_line")
    (.or (haltAtMark "crosswalk")
      (.and noMark (.since (.not (.or approachStartEdge exitI)) (.and halted nearEdge))))

-- (2) + (3) Wait ---------------------------------------------------------------------------------
/-- At the entry: the last observation at rest at the place since the previous passage closes a
    run at rest in which the display rose at least twice and no circular_green was shown. -/
def waitDuty : Formula :=
  .since (.and (.not atRestThere) (.not exitI))
    (andAll [ atRestThere
            , .count (.and red anyArrow) halted .ge twoCycles
            , .since (.and atRestThere (.not green)) (.not halted) ])

-- (4) Another device prohibiting the turn ------------------------------------------------------
/-- At the entry: where this passage's exit is the turn, no sign with the code governs c or i. -/
def signDuty (turn : Formula) (code : String) : Formula :=
  .implies (.until (.not exitI) (.and exitI turn))
    (.not (.existsDevice (.lit "regulatory_sign") "g"
      (.and (.atom "dev_regulatory_sign_code" [.var "g", .lit code] [])
            (.or (governs "g" "c") (governs "g" "i")))))

-- (5) Yield --------------------------------------------------------------------------------------
def moving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance
def pedTarget : Formula :=
  .and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-165::pedestrian"] [])
    (.existsRegion (.lit "crosswalk") "w"
      (.and (occ "u" "w")
        (.existsRegion (.lit "travel_region") "a"
          (.and (.atom "st_entrance_of" [.var "w", .var "a"] [])
                (.atom "st_lane_enters" [.var "a", .var "i"] [])))))
def trafficTarget : Formula :=
  .and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-285::traffic"] []) (occ "u" "i")
def conflict : Formula :=
  .or (.and (.derived "prim_closest_approach_within" [vSubject, .var "u"] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "u"] [pConflictHorizon])
                  .lt pConflictCentreClearance))
      (.atom "rel_contact" [vSubject, .var "u"] [])
def yieldsHere : Formula :=
  .implies moving
    (.forallUser "u"
      (.implies (.and (.not (.same vSubject (.var "u"))) (.or pedTarget trafficTarget))
        (.not conflict)))

/-- Every duty, judged at the exit. -/
def duties : Formula :=
  .and
    (.since (.not entryI)
      (.and entryI
        (.forallRegion (.lit "travel_region") "c"
          (.forallDevice (.lit "traffic_signal") "d"
            (.implies (.and carrierSel (headSel anyArrow))
              (andAll [ haltDuty, waitDuty
                      , signDuty rightTurn "no_right_turn", signDuty leftTurn "no_left_turn" ]))))))
    (.not (.since (.not entryI) (.not yieldsHere)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-135::motorcycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-125::moped"] [])
      (.or (.atom "ru_motorcycle" [vSubject] [])
        (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
          (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
               (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-018::electric_scooter"] [])))))

/-- Applicability: s1 (trigger): Where the signal is a steady red with a green turn arrow:; s3 (trigger): facing the signal; s4 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow; s8 (condition): to pedestrians lawfully within an adjacent crosswalk; s9 (condition): and to other traffic lawfully using the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and exitI (.or (occasionAt "left") (occasionAt "right")))

/-- Obligation: s6 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields; s7 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.implies exitI duties)

def rule : Rule :=
  { id := "NRS_484B_307_9b"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "Traffic-conflict technique: the right-of-way (DEF-NRS-484A-210: precedence where 'direction, speed and proximity' give 'danger of a crash') is not yielded where the subject, moving (kin.speed above p.halt_speed_tolerance) within the intersection, is on a closest approach to a road user it must yield to within the horizon p.conflict_horizon at a centre distance below p.conflict_centre_clearance, or touches it (rel.contact)."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s6"
          why := "The wait of (2) and the no-change of (3) are read in the subject's latest run at rest at the place before the entry: at the last observation at rest there (after which the subject is not at rest there before the entry), the red-with-arrow display has risen at least twice since that run began, and no circular_green was shown at any observation of that run; an earlier run at rest there, left and returned to, is not the wait the entry follows."
          kind := "reading" }
      , { span := "s6"
          why := "In the duties the applicable device is re-bound as the head governing c or i that shows steady red with a green turn arrow (left or right) and no circular_green at the entry, and a complete cycle is a rise of its display of steady red together with a green turn arrow; the arrow's direction is told apart in the applicability (where the passage is held against it), not in the cycle count."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b

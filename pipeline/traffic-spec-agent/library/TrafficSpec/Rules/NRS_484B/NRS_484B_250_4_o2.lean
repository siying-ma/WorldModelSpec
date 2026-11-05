/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When a vehicle enters an intersection
    s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    s3 (subject): the driver of the vehicle
    s4 (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    s5 (condition): After making such a stop,
    s6 (standard): the driver shall proceed cautiously,
    s7 (obligation): yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'rel.occupies', 'st.region_geometry', 'prim.region_offset_along', 'st.sight_along_way', 'st.highway'], derived ['drv.motion.halted']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived ['drv.motion.halted', 'drv.position.approaching_intersection', 'drv.lane.enters_region']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  s3 / subject. The class formula is the one admitted aggregate, `ru_aggregate subject
  "DEF-NRS-484A-320::vehicle"`. The driver is read through the vehicle's controlled motion (the
  record's own observable reading); nothing else stands for the role.

  s1 / trigger (`entersJunction`). The junction is bound by `existsRegion (.lit "intersection")
  "i"`, and the entry is the event `drv.lane.enters_region subject i` at this observation, with
  `rel_occupies subject i` written beside it: the concept's own anchor, stated so the junction
  variable is tied to the binder in the formula that binds it.

  s2 / condition (`signalInoperative`). One device quantifier over the traffic signals of the
  scene: the head governs the junction itself (`dev_governs d i`, read as the contract reads it —
  control of the junction, never the device's position), its faces are uncovered
  (`dev_traffic_signal_uncovered`) and it is inoperative (`dev_inoperative`). The three are read at
  the judged observation, which the words fix to the entry, so the conjunction sits beside s1 in
  the same formula.

  s5 / condition (`madeTheOrderedStop`). "Such a stop" is carried in full, as the record states it:
  the subject itself, at an observation earlier than this one, halted (`drv.motion.halted`) at the
  place the first sentence orders, on a carrier whose entrance end is this junction
  (`existsRegion (.lit "travel_region") "l"` with `st_lane_enters l i`). The place is the text's
  own order of preference, not a free disjunction: the stop line the source records as marking that
  carrier's entrance (`st_entrance_of`); else — only where no stop line marks it — the crosswalk so
  recorded; else — only where neither does — the point nearest the junction with a view along a
  through highway. Choices this writing makes that the words did not dictate, all within the atoms
  the record maps to the span (s5 decides when the rule applies, so they are documented here and
  are not narrowings):
    * "at" a mark is read as the body standing at it: the body-to-mark distance
      (`st.region_geometry`) at or below p.stop_point_tolerance, and the mark at or ahead of the
      reference point along the carrier's designated direction
      (`prim.region_offset_along` at or above zero) — a halt that has already passed the mark is
      not a halt at it.
    * "the point nearest the intersection where the driver has a view of approaching traffic on the
      through highway" is read as: the body within p.stop_point_tolerance of the junction itself
      (the nearest point reading, with the same stop-point convention) and the view along a highway
      (`st.sight_along_way` on `st.highway`) at or above p.intersection_view_sight_distance.
    * "earlier" is strict: `onceBefore φ` is φ at some observation strictly before this one
      (`since .tt φ` at the previous observation, written as its conjunction with the negation of
      its own rising edge, the language having no previous-observation operator).
    * the halt is tied to the carrier by the mark the source records for that carrier and by the
      carrier's direction, not by occupancy at the judged observation: at the observation the entry
      event fires the subject's footprint lies in the junction, and `rel.occupies` of the carrier
      there would deny the very halt the words presuppose. The claim `rel.occupies` is carried by
      s1 and s7, where the span reads it at the observation it speaks about.
  The rule that states the halt (s4) is not composed: a composed rule counts as complied with where
  it is not engaged, which would not show that the halt occurred.

  s6 / standard (`proceedsCautiously`, and the conflict bound of `noPredictedConflict`). The
  operationalization declared below: the subject's speed (`kin.speed`) at or below
  p.cautious_entry_speed_max, and a course free of a predicted conflict —
  `prim.closest_approach_within` over p.yield_conflict_horizon and
  `prim.closest_approach_distance` at or above p.yield_min_clearance. The conflict bound is written
  where the node's obligation puts the duty: against the road users s7 gives precedence to, not
  against every body in the scene (declared as a narrowing on s6).

  s7 / obligation (`yields`). At the observation of the entry, for every other road user
  (`forallUser`, the subject excluded by `same`) that is a member of the aggregate and has
  precedence — it occupies the junction now (`rel.occupies`), or it halted
  (`drv.motion.halted`) while approaching this junction
  (`drv.position.approaching_intersection`) earlier than the subject's own halt on its approach —
  the predicted closest approach must clear the bound. The two halts are ordered by their onsets:
  the subject's halt on its approach rose at an observation strictly after the other road user's
  halt on its approach began (`count … ≥ 1`), which is false where the other road user halted only
  at or after the subject did, and unknown where its halt was already under way when the recording
  began — the question the words ask of a past the trace does not reach. The junction is
  selected again by the record's own selection for this span, the subject's entry into it
  (`rel.occupies` and `drv.lane.enters_region`), so the duty is read at the junction entered and at
  no other. The subject's own halt is carried here by this span's atoms (halted while approaching
  i), which fixes the instant the other road user's halt must precede; the place-qualified halt is
  the applicability's business (declared as a narrowing on s7). The outer search for the subject's
  halt is `since .tt`, which includes the judged observation; at that observation the subject
  occupies the junction and `drv.position.approaching_intersection` is therefore false by its own
  contract, so the reading is the strict one the record states.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantifier variables: the junction, the approach carrier, the two kinds of mark, the
    through highway, the signal head, the other road user. -/
def vJunction : Arg := .var "i"
def vCarrier : Arg := .var "l"
def vWay : Arg := .var "w"
def vSignal : Arg := .var "d"
def vOther : Arg := .var "other"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCautiousEntrySpeedMax : Term := .param "p.cautious_entry_speed_max"
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate of the subsection. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Membership of the admitted vehicle aggregate. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, aggVehicle] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- φ at some observation strictly earlier than this one: `since .tt φ` read at the previous
    observation. `since .tt φ` is monotone, so its value one observation back is itself
    conjoined with the negation of its own rising edge. -/
def onceBefore (φ : Formula) : Formula :=
  .and (.since .tt φ) (.not (.rises (.since .tt φ)))

/-- The subject's body stands still at this observation. -/
def haltedSubject : Formula := .derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance]

/-- The subject's body stands at the mark on the carrier `l`: within the stop-point tolerance of
    it, and the mark at or ahead of its reference point along the carrier's direction. -/
def standsAtMark (mark : Arg) : Formula :=
  .and (.cmp (.measure "st_region_geometry_distance" [vSubject, mark]) .le pStopPointTolerance)
       (.cmp (.quantity "prim_region_offset_along" [vSubject, mark, vCarrier] []) .ge zeroMetres)

/-- A region of `kind` the source records as marking the carrier `l`'s entrance. -/
def markOf (kind var : String) : Formula :=
  .existsRegion (.lit kind) var (.atom "st_entrance_of" [.var var, vCarrier] [])

/-- The subject halted, earlier, at a mark of `kind` recorded for the carrier `l`'s entrance. -/
def haltedAtMarkOf (kind var : String) : Formula :=
  .existsRegion (.lit kind) var
    (.and (.atom "st_entrance_of" [.var var, vCarrier] [])
          (onceBefore (.and haltedSubject (standsAtMark (.var var)))))

/-- The third place: the subject halted, earlier, at the point nearest the junction at which its
    view along a through highway reaches the reading's sight distance. -/
def haltedWithViewOfWay : Formula :=
  .existsRegion (.lit "highway") "w"
    (onceBefore
      (.and haltedSubject
        (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, vJunction]) .le pStopPointTolerance)
              (.cmp (.measure "st_sight_along_way" [vSubject, vWay]) .ge pIntersectionViewSightDistance))))

/-- s5: the halt the first sentence orders, at the place it orders, on this approach to this
    junction, at an observation earlier than this one. -/
def madeTheOrderedStop : Formula :=
  .existsRegion (.lit "travel_region") "l"
    (.and (.atom "st_lane_enters" [vCarrier, vJunction] [])
      (.or (haltedAtMarkOf "stop_line" "sl")
        (.and (.not (markOf "stop_line" "sl"))
          (.or (haltedAtMarkOf "crosswalk" "cw")
            (.and (.not (markOf "crosswalk" "cw")) haltedWithViewOfWay)))))

/-- s1: the subject enters the junction at this observation. -/
def entersJunction : Formula :=
  .and (.atom "rel_occupies" [vSubject, vJunction] [])
       (.derived "drv_lane_enters_region" [vSubject, vJunction] [])

/-- s2: a traffic signal, installed and uncovered but inoperative, controls the junction. -/
def signalInoperative : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_governs" [vSignal, vJunction] [])
      (.and (.atom "dev_traffic_signal_uncovered" [vSignal] [])
            (.atom "dev_inoperative" [vSignal] [])))

/-- Applicability: s1 (trigger): When a vehicle enters an intersection; s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,; s5 (condition): After making such a stop, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and entersJunction (.and signalInoperative madeTheOrderedStop))

/-- The other road user's body stands still at this observation. -/
def haltedOther : Formula := .derived "drv_motion_halted" [vOther] [pMotionSpeedTolerance]

/-- The road user is on a stretch that leads into this junction and has not reached it. -/
def approaching (x : Arg) : Formula := .derived "drv_position_approaching_intersection" [x, vJunction] []

/-- s7: the other road user completed a halt on its approach to this junction earlier than the
    subject's own halt on its approach — the subject's halt on its approach began (rose) at an
    observation strictly after the other road user's halt on its approach began. -/
def stoppedBeforeTheSubject : Formula :=
  .count (.and haltedSubject (approaching vSubject))
         (.and haltedOther (approaching vOther)) .ge 1

/-- s7: the road users the subject must yield to — within the junction now, or having previously
    completed a stop. -/
def hasPrecedence : Formula :=
  .or (.atom "rel_occupies" [vOther, vJunction] []) stoppedBeforeTheSubject

/-- s6/s7: no predicted conflict with the other road user under the velocities observed. -/
def noPredictedConflict : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
            .ge pYieldMinClearance)

/-- s6: the operationalized crawl of a cautious entry. -/
def proceedsCautiously : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le pCautiousEntrySpeedMax

/-- s7: the yielding duty, for every other member of the aggregate with precedence. -/
def yields : Formula :=
  .forallUser "other"
    (.implies
      (.and (.not (.same vOther vSubject)) (.and (isVehicle vOther) hasPrecedence))
      noPredictedConflict)

/-- Obligation: s6 (standard): the driver shall proceed cautiously,; s7 (obligation): yielding to vehicles which have previously completed a stop or are within the intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies entersJunction (.and proceedsCautiously yields))

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the driver shall proceed cautiously"
          concepts := ["drv.motion.halted", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.intersection", "st.sight_along_way"]
          params := ["p.cautious_entry_speed_max", "p.yield_conflict_horizon", "p.yield_min_clearance", "p.motion_speed_tolerance"]
          convention := "intersection-entry speed convention together with the conflict-prediction convention of surrogate safety measures: proceeding cautiously is read as moving off at a crawl and under a predicted-conflict-free course — the subject's speed (kin.speed) at or below p.cautious_entry_speed_max, the speed at which a driver entering an uncontrolled junction can halt within the length of road it can see (st.sight_along_way), and, for every other road user, either no approach of the centres within p.yield_conflict_horizon (prim.closest_approach_within) or a centre distance at the closest approach of at least p.yield_min_clearance (prim.closest_approach_distance). The bound on speed therefore moves with nothing the words leave open but the reading's crawl speed, while the conflict bound moves with the measured velocities of both bodies."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s6"
          why := "the operationalization's conflict bound is written against the road users s7 gives precedence to — those within the junction, and those that halted earlier on their approach — and not against every road user in the scene, because that is where the node's obligation places the duty; the speed bound is read against the subject alone."
          kind := "reading" }
      , { span := "s7"
          why := "the subject's own halt, which fixes the observation another road user's halt must precede, is carried in the obligation by this span's own atoms — the subject halted (drv.motion.halted) while approaching this junction (drv.position.approaching_intersection) — and not by the place-qualified halt of s5, which the applicability establishes; the ordering is read between the onsets of the two halts, each seen on its own approach, so that a road user whose halt began only at or after the subject's gives no precedence, and whether the other road user's halt was at a lawful place is not read."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o2

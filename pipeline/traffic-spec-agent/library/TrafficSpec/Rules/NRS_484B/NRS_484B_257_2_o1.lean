/-
  NRS_484B_257_2_o1 — NRS-484B-257-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    f2 (subject): The driver of a vehicle
    f3 (obligation): shall stop in obedience to a stop sign or yield in compliance with a yield sign,
    f4 (reference): in compliance with the manner prescribed in subsection 1 [NRS-484B-257-1],
    f5 (condition): prior to entering an intersection
    f6 (trigger): if a stop sign or a yield sign is erected at one or more entrances thereto
    f7 (condition): although not a part of a through highway
    f8 (sibling): and shall proceed cautiously,
    f9 (sibling): yielding to vehicles not so obligated to stop or yield and which are within the intersection or approaching so closely as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'st.intersection', 'rel.occupies'], derived []
    f2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f3: atoms ['prim.region_offset_along', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.highway', 'st.sight_along_way', 'st.lane_direction', 'kin.speed', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.halted', 'drv.lane.enters_region']
    f5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.lane.enters_region']
    f6: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    f4: NRS_484B_257_1_o1 as compliance map {'subject': 'subject'}

  How each span is written:

    f2 (subject) — `clsSubject`: the binder's class is the admitted aggregate, `ru_aggregate` of the
      subject with `DEF-NRS-484A-320::vehicle`, never the classes it covers. "The driver of" is the
      vehicle's own controlled motion, the record's observable reading.

    f5 (condition) and f6 (trigger) — `applicability`: the duty is engaged at the observation at
      which the subject enters an intersection (`entersRegion`, with `occupies` as the footprint
      anchor there) at whose entrances a stop sign or a yield sign is erected: a travel region the
      subject occupies whose entrance end is that intersection (`st_lane_enters`) and which a stop
      sign or a yield sign is recorded as governing (`dev_governs`). The junction and the approach
      are bound here and bound again, by the same relations, in the obligation, so that both
      formulas speak of the same regions. f7 adds no condition and is the record's residue: nothing
      in the applicability reads the status of the ways at the junction, so the duty holds at such
      an entrance whether or not they are a through highway.

    f1 (exception) — `controlledException`, negated into the applicability: the subject is traffic
      (`ru_aggregate` with `DEF-NRS-484A-285::traffic`) and either a police officer
      (`dev_human_direction_role`) with an indication given (`dev_human_direction_indication`, any
      value the ontology admits) or a traffic signal (the `traffic_signal` kind) is recorded as
      governing that same intersection (`dev_governs`).

    f3 (obligation) — `obligation`: at the entry, the act is searched for back from it.
      * The place is the chain of `atThePlace`, in the order of the words: the stop line recorded
        as marking that same carrier; where no line's record marks it, the crosswalk so recorded;
        where neither does, the point on the carrier with the view along the through highway the
        reading requires. `st_entrance_of` carries the record's three values itself: unknown where a
        line's entrances are unobserved (so which place governs is unknown), false where they are
        observed and exclude the carrier (so the next place in the order governs).
      * The act (`actDone`) is a halt (`drv_motion_halted` at the motion-speed tolerance) or, where
        a yield sign governs the approach, a speed no greater than the yield-approach speed
        (`kin_speed`). The record states the act as a halt under a stop sign and a halt or the
        slowing under a yield sign; written this way the halt stands for both signs, which is what
        the record says of each, and the slowing is the yield sign's own alternative. No limb of the
        act is stated twice.
      * The act counts as made at a mark (`actAtMark`) where the subject is on the carrier, off the
        mark, short of it along the carrier's designated direction (the sign of
        `prim_region_offset_along`, which reads `st_lane_direction`), within the stop-point
        tolerance of it by the body-to-region distance of `st_region_geometry`, and with its
        footprint off the intersection.
      * The search (`actSearched`) counts the act's rising edges since the last end of the search:
        the approach start (`startAtMark`: on the carrier, off the mark, short of it and farther
        from it than the stop-point tolerance — the observed exit from the mark's stopping zone
        upstream) or the subject's entry into that same intersection. Where the search finds the act
        the duty is met, where it reaches an end without it the duty is violated, and where it
        reaches neither end — the recording does not reach back to either — it is unknown, which is
        the only history bound the formula has: no clock, no distance travelled and no other
        junction or mark ends it. The act is read at the observation before the one judged
        (`prevObs`), since the observation judged is the entry itself, which is an end of the search.

    f4 (reference) — the composition, as the record's `as: compliance`: `NRS_484B_257_1_o1` must be
      complied with where the duty is owed; a rule that is not engaged counts as complied with, so
      the composition cannot carry the act, which f3 states in full.

  Narrowings declared below (my readings on f3, the duty's own span):
    * the last of the places subsection 1 prescribes, the point with a view of approaching traffic,
      is written as any observation on the carrier at which the view along the through highway
      (`st_sight_along_way`) reaches the intersection view sight distance, not as the one such point
      nearest the intersection: the language has no operator that singles out the nearest point of a
      region, and the halt the record asks for is made with that view of the way.
    * the approach start under that place, which the record states for a mark (off it, short of it
      and farther from it than the stop-point tolerance), is written as the subject on the carrier
      whose view along the through highway is short of that distance: the place is a point no region
      carries, so the zone it ends is the stretch upstream from which the way cannot be seen.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_2_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldApproachSpeedMax : Term := .param "p.yield_approach_speed_max"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- The leaves, each by its contract.
-- ---------------------------------------------------------------------------------------------

/-- The subject's footprint overlaps region `r` (`rel.occupies`). -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- The subject enters region `r` at this observation: the event, not the stay after it. -/
def entersRegion (r : String) : Formula := .derived "drv_lane_enters_region" [vSubject, .var r] []

/-- The subject's body is not moving at this observation. -/
def halted : Formula := .derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance]

/-- The magnitude of the subject's velocity. -/
def subjectSpeed : Term := .measure "kin_speed" [vSubject]

/-- The signed distance from the subject's reference point to region `p` along carrier `l`'s
    designated direction: positive where `p` lies ahead, so a positive value is short of it. -/
def offsetAlong (p l : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var p, .var l] []

/-- The distance from the subject's body outline to region `p`. -/
def bodyDistance (p : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var p]

/-- Region `p` is recorded as marking carrier `l`'s entrance into the intersection it enters. -/
def marksEntrance (p l : String) : Formula := .atom "st_entrance_of" [.var p, .var l] []

/-- Device `d` is recorded as governing region `r`. -/
def devGoverns (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- Carrier `l` is an approach whose entrance end is intersection `j`. -/
def entranceEnd (l j : String) : Formula := .atom "st_lane_enters" [.var l, .var j] []

/-- A stop sign is recorded as governing carrier `l`. -/
def stopSignGoverns (l : String) : Formula :=
  .existsDevice (.lit "stop_sign") "stop_mark" (devGoverns "stop_mark" l)

/-- A yield sign is recorded as governing carrier `l`. -/
def yieldSignGoverns (l : String) : Formula :=
  .existsDevice (.lit "yield_sign") "yield_mark" (devGoverns "yield_mark" l)

/-- The view along the through highway, from where the subject is, reaches the intersection view
    sight distance. -/
def viewReaches : Formula :=
  .existsRegion (.lit "highway") "way"
    (.cmp (.measure "st_sight_along_way" [vSubject, .var "way"]) .ge pIntersectionViewSightDistance)

-- ---------------------------------------------------------------------------------------------
-- f2 — the subject
-- ---------------------------------------------------------------------------------------------

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- f6 — the approach the signs govern; f1 — the exception
-- ---------------------------------------------------------------------------------------------

/-- The subject's approach to junction `j`: a travel region it occupies whose entrance end is that
    junction, with a stop sign or a yield sign recorded as governing it. -/
def approachGoverned (j l : String) : Formula :=
  .and (occupies l)
    (.and (entranceEnd l j)
      (.or (stopSignGoverns l) (yieldSignGoverns l)))

/-- An indication is given: any value the ontology admits for a person directing traffic. -/
def indicationGiven (d : String) : Formula :=
  let ind (s : String) : Formula := .atom "dev_human_direction_indication" [.var d, .lit s] []
  .or (ind "stop")
    (.or (ind "proceed")
      (.or (ind "slow")
        (.or (ind "turn(left)")
          (.or (ind "turn(right)")
            (.or (ind "turn(straight)") (ind "turn(u_turn)"))))))

/-- A police officer is directing traffic at junction `j`. -/
def officerDirecting (j : String) : Formula :=
  .existsDevice (.lit "human_direction") "officer"
    (.and (.atom "dev_human_direction_role" [.var "officer", .lit "police_officer"] [])
      (.and (indicationGiven "officer") (devGoverns "officer" j)))

/-- A traffic-control signal is recorded as governing junction `j`. -/
def signalControlling (j : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "head" (devGoverns "head" j)

/-- f1: the traffic the subject is part of is being controlled at that junction by a police officer
    or by a traffic-control signal. -/
def controlledException (j : String) : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.or (officerDirecting j) (signalControlling j))

/-- Applicability: f1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; f5 (condition): prior to entering an intersection; f6 (trigger): if a stop sign or a yield sign is erected at one or more entrances thereto; f7 (condition): although not a part of a through highway -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and (entersRegion "junction")
      (.and (occupies "junction")
        (.and (.existsRegion (.lit "travel_region") "carrier" (approachGoverned "junction" "carrier"))
          (.not (controlledException "junction")))))

-- ---------------------------------------------------------------------------------------------
-- f3 — the place, the act and the search
-- ---------------------------------------------------------------------------------------------

/-- The place the act is owed at, in the order of the words: the stop line recorded as marking
    carrier `l`; where no line's record marks it, the crosswalk so recorded; where neither does, the
    point on the carrier with the view along the through highway. `atMark` states what holds at a
    mark, `atView` what holds at that point. -/
def atThePlace (l : String) (atMark : String → Formula) (atView : Formula) : Formula :=
  let markedBy (kind v : String) : Formula := .existsRegion (.lit kind) v (marksEntrance v l)
  let limb (kind v : String) (rest : Formula) : Formula :=
    .or (.existsRegion (.lit kind) v (.and (marksEntrance v l) (atMark v)))
        (.and (.not (markedBy kind v)) rest)
  limb "stop_line" "line" (limb "crosswalk" "crossing" atView)

/-- The act owed on the approach: a halt, and where a yield sign governs the approach, a speed no
    greater than the yield-approach speed. -/
def actDone (l : String) : Formula :=
  .or halted (.and (yieldSignGoverns l) (.cmp subjectSpeed .le pYieldApproachSpeedMax))

/-- The act made at mark `p` on carrier `l`, short of junction `j`: the subject on the carrier, off
    the mark, short of it along the carrier's designated direction, within the stop-point tolerance
    of it, and with its footprint off the intersection. -/
def actAtMark (j l p : String) : Formula :=
  .and (occupies l)
    (.and (.not (occupies j))
      (.and (.not (occupies p))
        (.and (.cmp (offsetAlong p l) .gt zeroMetres)
          (.and (.cmp (bodyDistance p) .le pStopPointTolerance) (actDone l)))))

/-- The act made at the point on carrier `l` with the view along the through highway. -/
def actAtView (j l : String) : Formula :=
  .and (occupies l) (.and (.not (occupies j)) (.and viewReaches (actDone l)))

/-- The approach start at mark `p`: the subject on carrier `l`, off the mark, short of it and
    farther from it than the stop-point tolerance — the exit from the mark's stopping zone
    upstream. -/
def startAtMark (l p : String) : Formula :=
  .and (occupies l)
    (.and (.not (occupies p))
      (.and (.cmp (offsetAlong p l) .gt zeroMetres)
        (.cmp (bodyDistance p) .gt pStopPointTolerance)))

/-- The approach start where the place is the point with a view: the subject on carrier `l` whose
    view along the through highway is short of the intersection view sight distance. -/
def startAtView (l : String) : Formula := .and (occupies l) (.not viewReaches)

/-- Where the search back from the entry ends: the approach start at the place, or an entry of the
    subject into that same intersection. -/
def searchEnd (j l : String) : Formula :=
  .or (atThePlace l (fun p => startAtMark l p) (startAtView l)) (entersRegion j)

/-- The value of `φ` at the previous observation; unknown at the first observation of the trace. -/
def prevObs (φ : Formula) : Formula := .or (.rises (.not φ)) (.and φ (.not (.rises φ)))

/-- The act, searched for back from the entry: an act at an observation after the last end of the
    search. False where the search reaches an end without the act, unknown where it reaches
    neither. -/
def actSearched (j l : String) : Formula :=
  .count (prevObs (atThePlace l (fun p => actAtMark j l p) (actAtView j l)))
    (.not (searchEnd j l)) .ge 1

/-- Obligation: f3 (obligation): shall stop in obedience to a stop sign or yield in compliance with a yield sign, -/
def obligation : Formula :=
  .and (.rule "NRS_484B_257_1_o1" [("subject", "subject")])
    (.existsRegion (.lit "intersection") "junction"
      (.and (entersRegion "junction")
        (.and (occupies "junction")
          (.existsRegion (.lit "travel_region") "carrier"
            (.and (approachGoverned "junction" "carrier") (actSearched "junction" "carrier"))))))

def rule : Rule :=
  { id := "NRS_484B_257_2_o1"
    laws := ["NRS-484B-257-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["\"although not a part of a through highway\" adds no condition to the duty: it says the duty holds at such an entrance even where the junction is no part of a through highway, so the obligation is the same whether or not the ways at the junction have that status. Nothing is read from it and nothing is dropped from the duty by leaving it unread."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "f3"
          why := "the last of the places subsection 1 prescribes, the point with a view of approaching traffic, is written as any observation on the carrier at which the view along the through highway (st.sight_along_way) reaches the intersection view sight distance, not as the one such point nearest the intersection: no operator of the language singles out the nearest point of a region, and a halt made anywhere with that view of the way is a halt made with the view the place secures."
          kind := "reading" }
      , { span := "f3"
          why := "the approach start under that place — which the record states for a mark as being off it, short of it and farther from it than the stop-point tolerance — is written as the subject on the carrier whose view along the through highway is short of the intersection view sight distance: the place is a point no region of the scene carries, so the stopping zone it ends is read as the stretch of the carrier from which the way cannot yet be seen that far."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_2_o1

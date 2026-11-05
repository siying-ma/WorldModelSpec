/-
  NRS_484B_250_1 — NRS-484B-250-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): approaching an intersection
    s3 (obligation): shall yield
    s4 (standard): the right-of-way
    s5 (condition): to a vehicle which has entered the intersection from a different highway.
    s6 (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    s7 (exception): this section does not apply at intersections controlled by official traffic-control devices or to vehicles approaching each other from opposite directions, when the driver of one of the vehicles
    s8 (exception): is intending to
    s9 (exception): or is making a left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity'], derived []
    s2: atoms ['st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived ['drv.position.approaching_intersection']
    s3: atoms ['st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.on_way', 'st.highway'], derived ['drv.lane.enters_region']
    s7: atoms ['st.intersection', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.regulatory_sign', 'dev.lane_control_signal', 'dev.governs', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'rel.occupies'], derived ['drv.position.approaching_intersection']
    s9: atoms ['kin.speed'], derived ['drv.motion.leftward_course_change']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:

    s1 — `clsSubject` is the admitted aggregate, `ru_aggregate` of the binder with the id
      DEF-NRS-484A-320::vehicle and nothing else; the classes it covers are never spelled. The
      element's second atom, kin.velocity, carries the record's reading of ‘the driver of a
      vehicle’ (who is at the controls is not observable, so the duty binds the vehicle's
      conduct): `inMotion` says the subject's velocity vector is not the zero vector — the sum of
      the magnitudes of its two components is above zero — and stands in the applicability beside
      the approach. Zero is the only magnitude it names.

    s2 — ‘approaching an intersection’ is `drv.position.approaching_intersection` of the subject
      at a region of kind st.intersection: the concept is exactly the ontology's configuration —
      the road user occupies a travel region whose entrance end the source records as that
      intersection (st.travel_region, rel.occupies, st.lane_enters) and its own footprint does not
      overlap the intersection. The carrier that fixes the approach is bound beside it
      (`approachCarrier`), because the exception of s7 reads that carrier's designated direction
      and the condition of s5 reads the highway it lies on. No distance and no heading stands in
      for the approach.

    s3/s4 — the act the duty governs is the subject's own entry into the junction,
      `drv.lane.enters_region` of the subject on the region of kind st.intersection the
      applicability selected (the concept is anchored on rel.occupies). Because the duty is judged
      at an observation at which the subject is still approaching — its footprint not overlapping
      the junction — that entry cannot be read at the judged observation: it is read, as the
      record's narrowing on s3 discloses, in the window ahead of it, of the operationalization's
      own length p.yield_conflict_horizon (`entersAgainst`, a `.within` window). The standard of
      s4 is the operationalization and nothing else: at the entry observation the two centres
      approach under the velocities then observed (prim.closest_approach_within over
      p.yield_conflict_horizon) and the centre distance at that closest approach
      (prim.closest_approach_distance) is below p.yield_min_clearance. Granting precedence is the
      negation: at no observation of that window does the subject enter the junction while that
      prediction holds of the selected vehicle.

    s5 — ‘a vehicle which has entered the intersection from a different highway’ is quantified
      inside the obligation (`.forallUser "v"`), since the duty exists whether or not such a
      vehicle is present: v is the admitted aggregate (ru_aggregate, the same id), it occupies the
      junction at the judged observation (rel.occupies), and that occupancy has held since an
      earlier observation at which it entered (`.since` of rel.occupies over
      drv.lane.enters_region). At that entry observation v occupied a carrier c2 — a travel region
      whose entrance end is the junction, and not the junction itself — lying (st.on_way) on a
      highway region (st.highway) that is no highway the subject's own carrier lies on
      (`differentHighway`, `same` over the two way variables). No distance is read and no bearing:
      the words name the way entered from.

    s7 — two grounds, both inside the applicability's selection of the junction, and the section
      does not apply where either holds. (a) `controlledByDevice`: a device of a
      junction-controlling kind — dev.traffic_signal, dev.stop_sign, dev.yield_sign,
      dev.regulatory_sign or dev.lane_control_signal — whose dev.governs names the junction
      itself, or the carrier the subject occupies that enters it; the region governed is bound
      once (`ctl`) and is either the junction (`same`) or such a carrier, so no closure from one
      to the other is added and no distance to a head is read. (b) `opposedLeftTurn`: another road
      user approaches the same junction (drv.position.approaching_intersection) through a carrier
      of its own (st.travel_region, rel.occupies, st.lane_enters) whose designated direction
      (st.lane_direction, read normalised) is opposed to the direction of the subject's carrier —
      their dot product below the negative of p.opposite_direction_tolerance — and one of the two
      is declared to intend a left turn there (s8) or is making one (s9). rel.oncoming is not
      read, as its own contract directs.

    s8 — the declared intention `int.left_turn`, read of the subject or of the other vehicle at
      the junction region the applicability binds, at the judged observation: int.left_turn is
      ‘the source's current plan for this road user at the named region’, and the words ‘is
      intending to’ are that current plan. It is never read ahead of the judged observation.

    s9 — ‘is making a left turn’ is `drv.motion.leftward_course_change`, called with the reading's
      window and bounds (p.turn_window, p.turn_min_course_change, p.turn_max_course_change,
      p.motion_speed_tolerance); the concept reads kin.speed over that window, so the element's
      atom is the call's. It is read of either of the two vehicles, as ‘one of the vehicles’
      requires. The indicator (sig.turn_indicator) is not read.

    The quantifiers — the obligation binds the junction again with the whole selection that fixed
    it in the applicability (st.intersection, drv.position.approaching_intersection, a travel
    region the subject occupies whose entrance end is the junction), so that it denotes the same
    region, and it is read for every such junction and every such carrier of the subject, never
    for the one that would favour the subject.

  Narrowings: none. Every span is written with the atoms the record maps it to; the window ahead
  in which the entry of s3 is read is the record's own narrowing on that span, not a further one,
  and it adds no parameter and no magnitude of this file's own.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the formulas quantify over. -/
def vI : Arg := .var "i"
def vC1 : Arg := .var "c1"
def vC2 : Arg := .var "c2"
def vC3 : Arg := .var "c3"
def vCtl : Arg := .var "ctl"
def vU : Arg := .var "u"
def vV : Arg := .var "v"
def vW1 : Arg := .var "w1"
def vW2 : Arg := .var "w2"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

/-- No speed at all: the only magnitude the motion reading names. -/
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- The aggregate the run admits for ‘vehicle’, of any road user. -/
def isVehicle (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- s1: the vehicle's own controlled motion — its velocity is not the zero vector. -/
def inMotion : Formula :=
  .cmp (.add (.abs (.measure "kin_velocity" [vSubject, .lit "x"]))
             (.abs (.measure "kin_velocity" [vSubject, .lit "y"])))
       .gt zeroSpeed

/-- s2: the road user is on a stretch of road that leads into the junction and has not reached it. -/
def approaching (u i : Arg) : Formula :=
  .derived "drv_position_approaching_intersection" [u, i] []

/-- The carrier a road user approaches the junction through: a travel region it occupies whose
    entrance end the source records as that junction. -/
def approachCarrier (u c i : Arg) : Formula :=
  .and (.atom "st_travel_region" [c] [])
    (.and (.atom "rel_occupies" [u, c] [])
          (.atom "st_lane_enters" [c, i] []))

/-- A device of one junction-controlling kind governing the region `r`. -/
def governedBy (kind name var : String) (r : Arg) : Formula :=
  .existsDevice (.lit kind) var
    (.and (.atom name [.var var] []) (.atom "dev_governs" [.var var, r] []))

/-- s7 (a): the junction is controlled by an official traffic-control device — one of the kinds
    that regulate a junction, governing the junction itself or the subject's approach to it. -/
def controlledByDevice (i : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "ctl"
    (.and (.or (.same vCtl i) (approachCarrier vSubject vCtl i))
      (.or (governedBy "traffic_signal" "dev_traffic_signal" "dSignal" vCtl)
        (.or (governedBy "stop_sign" "dev_stop_sign" "dStop" vCtl)
          (.or (governedBy "yield_sign" "dev_yield_sign" "dYield" vCtl)
            (.or (governedBy "regulatory_sign" "dev_regulatory_sign" "dRegulatory" vCtl)
                 (governedBy "lane_control_signal" "dev_lane_control_signal" "dLaneControl" vCtl))))))

/-- The parameters of the manoeuvre concept, in the concept's order. -/
def turnParams : List Term :=
  [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance]

/-- s8 and s9: one of the two vehicles is declared to intend a left turn at the junction, or is
    making a change of course to the left. -/
def leftTurnOfOne (u i : Arg) : Formula :=
  .or (.intent "int.left_turn" vSubject i)
    (.or (.intent "int.left_turn" u i)
      (.or (.derived "drv_motion_leftward_course_change" [vSubject] turnParams)
           (.derived "drv_motion_leftward_course_change" [u] turnParams)))

/-- The designated directions of two carriers are opposed: their normalised dot product is below
    the negative of the reading's tolerance. -/
def directionsOpposed (c c' : Arg) : Formula :=
  .cmp (.add (.mul (.measure "st_lane_direction" [c, .lit "x"])
                   (.measure "st_lane_direction" [c', .lit "x"]))
             (.mul (.measure "st_lane_direction" [c, .lit "y"])
                   (.measure "st_lane_direction" [c', .lit "y"])))
       .lt (.neg pOppositeDirectionTolerance)

/-- s7 (b): the subject and another road user approach the junction through carriers whose
    designated directions are opposed, and one of them intends or is making a left turn. -/
def opposedLeftTurn (i c1 : Arg) : Formula :=
  .existsUser "u"
    (.and (approaching vU i)
      (.existsRegion (.lit "travel_region") "c3"
        (.and (approachCarrier vU vC3 i)
          (.and (directionsOpposed c1 vC3)
                (leftTurnOfOne vU i)))))

/-- s4: under the velocities observed at the instant the two centres approach within the horizon,
    and the centre distance at that closest approach is below the clearance. -/
def conflictPredicted (v : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, v] [pYieldConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, v] [pYieldConflictHorizon])
             .lt pYieldMinClearance)

/-- s3 with s4: at some observation of the window ahead the subject enters the junction while the
    conflict is predicted of `v`. -/
def entersAgainst (i v : Arg) : Formula :=
  .within .time pYieldConflictHorizon "subject"
    (.and (.derived "drv_lane_enters_region" [vSubject, i] []) (conflictPredicted v))

/-- s5: the way `c2` lies on is no way the subject's carrier `c1` lies on. -/
def differentHighway (c2 c1 : Arg) : Formula :=
  .existsRegion (.lit "highway") "w2"
    (.and (.atom "st_highway" [vW2] [])
      (.and (.atom "st_on_way" [c2, vW2] [])
        (.forallRegion (.lit "highway") "w1"
          (.implies (.and (.atom "st_highway" [vW1] []) (.atom "st_on_way" [c1, vW1] []))
                    (.not (.same vW2 vW1))))))

/-- s5: `v`'s occupancy of the junction has held since an observation at which it entered the
    junction from a carrier lying on a different highway. -/
def enteredFromDifferentHighway (v i c1 : Arg) : Formula :=
  .since (.atom "rel_occupies" [v, i] [])
    (.and (.derived "drv_lane_enters_region" [v, i] [])
      (.existsRegion (.lit "travel_region") "c2"
        (.and (.not (.same vC2 i))
          (.and (approachCarrier v vC2 i)
                (differentHighway vC2 c1)))))

/-- Applicability: s2 (trigger): approaching an intersection; s5 (condition): to a vehicle which has entered the intersection from a different highway.; s7 (exception): this section does not apply at intersections controlled by official traffic-control devices or to vehicles approaching each other from opposite directions, when the driver of one of the vehicles; s8 (exception): is intending to; s9 (exception): or is making a left turn. -/
def applicability : Formula :=
  .and inMotion
    (.existsRegion (.lit "intersection") "i"
      (.and (.atom "st_intersection" [vI] [])
        (.and (approaching vSubject vI)
          (.existsRegion (.lit "travel_region") "c1"
            (.and (approachCarrier vSubject vC1 vI)
              (.and (.not (controlledByDevice vI))
                    (.not (opposedLeftTurn vI vC1))))))))

/-- Obligation: s3 (obligation): shall yield; s4 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (.and (.atom "st_intersection" [vI] []) (approaching vSubject vI))
      (.forallRegion (.lit "travel_region") "c1"
        (.implies (approachCarrier vSubject vC1 vI)
          (.forallUser "v"
            (.implies
              (.and (isVehicle vV)
                (.and (.atom "rel_occupies" [vV, vI] [])
                      (enteredFromDifferentHighway vV vI vC1)))
              (.not (entersAgainst vI vV)))))))

def rule : Rule :=
  { id := "NRS_484B_250_1"
    laws := ["NRS-484B-250-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way"
          concepts := ["drv.lane.enters_region", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.intersection"]
          params := ["p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "Conflict-prediction (surrogate-safety) convention. DEF-NRS-484A-210 bounds the right-of-way by ‘such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other’; the danger of a crash is read as a predicted conflict between the two bodies, and direction, speed and proximity enter it as the magnitudes they are: under the velocities observed at the instant, the two centres approach (prim.closest_approach_within, over p.yield_conflict_horizon) and the centre distance at that closest approach (prim.closest_approach_distance) is below p.yield_min_clearance. Granting precedence is then not making the entry (drv.lane.enters_region on the junction, st.intersection, anchored on rel.occupies) at an observation at which that prediction holds of a vehicle occupying the junction; the bound moves with the other vehicle's speed and proximity, so a distant or slow vehicle leaves the subject free and a near, fast one does not. The horizon comes from time-to-collision practice and the clearance from the centre-to-centre distance at which two passenger-car bodies would be in conflict, rel.centre_distance overstating a body clearance ‘by about the two half-extents’."
          surrogate := false } ]
    residues := ["‘Except as otherwise provided in subsection 4’ carves subsection 4's own duty out of the non-application that this sentence states: it preserves the left-turn yielding duty of NRS-484B-250-4 at intersections controlled by official traffic-control devices and in the opposed-direction case. That duty is a separate line of the corpus with a node of its own, and this node states the duty of subsection 1 alone, on which these words lay no condition: whether or not subsection 4 applies, subsection 1 does not apply in either situation s7 names, so the verdict of this rule is the same whether or not these words are read. The words are not dropped because the corpus cannot carry them — they are a composition for the node of subsection 4 — but because they restrict nothing in this node."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- every span is written with the atoms the record maps it to; no reading narrower than the words was chosen
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_1

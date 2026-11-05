/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle within an intersection
    s2 (condition): intending to turn to the left
    s3 (obligation): shall yield the right-of-way to any vehicle
    s4 (condition): approaching from the opposite direction
    s5 (condition): which is within the intersection
    s6 (standard): or so close thereto as to constitute an immediate hazard,
    s7 (sibling): but such driver, having so yielded and having given a signal when and as required, may make such left turn and
    s8 (sibling): the drivers of all other vehicles approaching the intersection from the opposite direction shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []
    s3: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []
    s4: atoms ['st.lane_enters', 'st.travel_region', 'st.lane_direction', 'rel.occupies', 'st.intersection', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.road.opposed_approach_directions']
    s5: atoms ['rel.occupies', 'st.intersection'], derived []

  How each span is written:

  s1  `clsSubject` is the admitted aggregate alone (`ru_aggregate` with the aggregate id). "within
      an intersection" is `withinJunction vSubject`: the junction is the region a single
      `existsRegion (.lit "intersection") "junction"` selects in the applicability, read with
      `st_intersection` and `rel_occupies`. That one region is the target of the declared
      intention (s2) and the junction every later condition reads, so the whole selection is
      written again in the obligation (the two formulas have separate scopes), there over every
      selected junction, so the duty is not escaped by a second junction that happens to carry no
      conflict.

  s2  the declared intention `int.left_turn` of the subject at that junction, read at the judged
      observation.

  s3  the duty: for every road user the applicability's conditions select — "any vehicle" in a
      duty is each such vehicle, so the obligation is `forallUser` over them with the selection as
      its antecedent — the subject brings about no predicted conflict: under the velocities
      observed either the centres do not approach within `p.yield_conflict_horizon`
      (`prim_closest_approach_within`) or the centre distance at their closest approach
      (`prim_closest_approach_distance`) is at least `p.yield_min_clearance`. The disjunction is
      written in this order because the distance is undefined where the centres do not approach.

  s4  "approaching from the opposite direction" is written through the two approach carriers, not
      through current headings: the other vehicle's carrier is a `st_travel_region` it occupies
      whose `st_lane_enters` entrance end is that junction; the subject's own is the carrier it
      occupied at the last observation in the window `p.turn_window` behind at which it occupied
      such a carrier of that junction (`atLast`), the subject being now within the junction
      itself. `drv.road.opposed_approach_directions` relates the two regions' designated
      directions, with `p.opposite_direction_tolerance`. A carrier is required to be a region
      other than the junction (`same`): the junction is no approach to itself, and `st.lane_enters`
      records no entrance for it, so without that the junction region would stand among the
      carriers the quantifier ranges over and leave the condition undecided wherever a body
      overlaps it. This is an identity test among the regions the record already selects, not a
      further fact about them.

  s5  the other vehicle's footprint overlapping the same junction region (`rel_occupies`,
      `st_intersection`), one limb of the condition s5/s6 joins.

  s6  the operationalization: `drv.position.approaching_intersection` of that vehicle at that
      junction, and the distance from its body to the junction region
      (`st.region_geometry`, read as the body-to-region distance) at most its observed speed
      (`kin.speed`) times `p.immediate_hazard_arrival_time`. The bound is written as a product, so
      no quantity is divided.

  s7, s8  siblings: the record carries no element for them and this rule says nothing about them.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the rule's own quantifiers bind. -/
def vOther : Arg := .var "other"
def vJunction : Arg := .var "junction"
def vOtherApproach : Arg := .var "other_approach"
def vSubjectApproach : Arg := .var "subject_approach"

/-- The admitted aggregate of DEF-NRS-484A-320, carried as one atom and never expanded. -/
def aVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardArrivalTime : Term := .param "p.immediate_hazard_arrival_time"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pTurnWindow : Term := .param "p.turn_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aVehicle] []

/-- s1 (for the subject) and s5 (for the other vehicle): the road user's footprint overlaps the
    junction region the words single out. -/
def withinJunction (who : Arg) : Formula :=
  .and (.atom "st_intersection" [vJunction] [])
       (.atom "rel_occupies" [who, vJunction] [])

/-- s2: the source's declaration current here is that the subject turns left at that junction. -/
def intendsLeftTurn : Formula := .intent "int.left_turn" vSubject vJunction

/-- s1 + s2: the subject within that junction, with the declared left turn there. -/
def junctionSelection : Formula := .and (withinJunction vSubject) intendsLeftTurn

/-- A carrier of the junction: a travel region, other than the junction itself, whose entrance end
    the source records as that junction, occupied by `who`. -/
def approachCarrier (who carrier : Arg) : Formula :=
  .and (.atom "st_travel_region" [carrier] [])
  (.and (.not (.same carrier vJunction))
  (.and (.atom "rel_occupies" [who, carrier] [])
        (.atom "st_lane_enters" [carrier, vJunction] [])))

/-- s4: the carrier the other vehicle approaches through and the carrier the subject last occupied
    before it was within the junction carry opposed designated directions. -/
def opposedApproach : Formula :=
  .existsRegion (.lit "travel_region") "other_approach"
    (.and (approachCarrier vOther vOtherApproach)
          (.existsRegion (.lit "travel_region") "subject_approach"
            (.atLast .time pTurnWindow "subject"
              (approachCarrier vSubject vSubjectApproach)
              (.derived "drv_road_opposed_approach_directions" [vSubjectApproach, vOtherApproach]
                [pOppositeDirectionTolerance]))))

/-- s6: the standard, as the operationalization bounds it — the vehicle is approaching that
    junction and the distance from its body to it is at most its speed times the arrival time. -/
def immediateHazard : Formula :=
  .and (.derived "drv_position_approaching_intersection" [vOther, vJunction] [])
       (.cmp (.measure "st_region_geometry_distance" [vOther, vJunction]) .le
             (.mul (.measure "kin_speed" [vOther]) pImmediateHazardArrivalTime))

/-- s3 + s4 + s5 + s6: a vehicle other than the subject, approaching that junction from the
    opposite direction, which is within the junction or so close thereto as to constitute an
    immediate hazard. -/
def opposingVehicle : Formula :=
  .and (.not (.same vOther vSubject))
  (.and (.atom "ru_aggregate" [vOther, aVehicle] [])
  (.and (.or (withinJunction vOther) immediateHazard)
        opposedApproach))

/-- Applicability: s2 (condition): intending to turn to the left; s4 (condition): approaching from the opposite direction; s5 (condition): which is within the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and junctionSelection (.existsUser "other" opposingVehicle))

/-- s3: the subject brings about no predicted conflict with that vehicle — under the velocities
    observed the centres either do not approach within the horizon, or are no closer than the
    minimum clearance at their closest approach. -/
def yieldsTo : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
            .ge pYieldMinClearance)

/-- Obligation: s3 (obligation): shall yield the right-of-way to any vehicle; s6 (standard): or so close thereto as to constitute an immediate hazard, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies junctionSelection
      (.forallUser "other" (.implies opposingVehicle yieldsTo)))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "so close thereto as to constitute an immediate hazard"
          concepts := ["drv.position.approaching_intersection", "kin.speed", "rel.occupies", "st.intersection", "st.lane_enters", "st.region_geometry", "st.travel_region"]
          params := ["p.immediate_hazard_arrival_time"]
          convention := "gap-acceptance convention for a left turn across opposing traffic: an approaching vehicle is so close to the junction as to constitute an immediate hazard where the distance from its body to the junction region (st.region_geometry) is at most its observed speed times the arrival time, that is where it would reach the junction within the time a passenger car needs to complete a left turn through it. The bound moves with the approaching vehicle's own speed and its own distance, so a fast distant vehicle and a slow near one are judged by the degree of each"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1

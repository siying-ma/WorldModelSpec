/-
  NRS 484B.223(2), second obligation — upon a highway which has been divided into three clearly
  marked lanes, a vehicle on such a highway must not be driven in the center lane except (a) when
  overtaking and passing another vehicle where the highway is clearly visible and the center lane
  is clear of traffic for a safe distance, (b) in preparation for a left turn, or (c) when the
  center lane is allocated exclusively to traffic moving in the direction in which the vehicle is
  proceeding and a sign is posted to give notice of such allocation.

  THE READING (the blueprint's, not this file's):
  - s5 subject    — the binder `a`: the subject track, of one of the classes the node lists for
                    the corpus's word "vehicle". The binder `b` is the vehicle of s9, overtaken
                    and passed; it carries the same classes without `ru.subject`.
  - s1 trigger    — the applicability: a is upon a roadway, and the carriageway a is on has been
                    divided into the stated number of clearly marked lanes.
  - s6 obligation — a's footprint does not overlap the centre lane of that carriageway.
  - s9…s11        — exception (a): overtaking and passing b, with the two standards of s10 and
                    s11 operationalized as the node's two operationalizations declare.
  - s13           — exception (b): in preparation for a left turn.
  - s16, s17      — exception (c): the centre lane allocated to a's direction, and signed so.
  - s2, s3        — the siblings of the first obligation (the extreme left lane); they are another
                    node's, and nothing here reads them.
  - s4, s7, s8, s12, s14, s15 — boilerplate; they carry no element and appear nowhere below.

  CHOICES THE TEXT DID NOT DICTATE (each one is a reading of a span, not an invention):

  1. WHERE THE EXCEPTIONS SIT. The three exceptions are written into the OBLIGATION, not the
     applicability: the rule demands that a's footprint overlap the centre lane only while one of
     them holds. The node's prose says the duty is "lifted" while an exception holds, but its own
     witness table requires `permit` — a in the centre lane while overtaking — to be COMPLIANT,
     and a rule whose applicability carried the exception would report `not_applicable` there.
     Compliance is also the better reading: the subsection governs every vehicle on such a
     highway, and (a), (b), (c) say what it may then do, not that it is outside the subsection.
     See task_result.md.
  2. "divided into three clearly marked lanes" (s1) is read exactly as the first obligation reads
     it: on the lane the subject occupies, through the census `st.lane_adjacency` records on it,
     with a recorded marking on each side whose type is not `none`. The same consequence follows:
     ATOMS.md gives that count as the count of lanes IN THAT DIRECTION while the statute's is a
     census of the carriageway; the rule takes the recorded count at face value.
  3. "the center lane" (s6) is the lane of the division that has a recorded neighbour on EACH
     side, on a carriageway that carries a centre line. Of three lanes only the middle one is
     bounded by two others, so no ordinal — and so no undeclared magnitude — is needed to name it;
     `st.centre_line` says the carriageway is undivided, which is what makes that middle lane the
     shared one the three exceptions are about. The obligation quantifies over every lane, so it
     speaks of a's FOOTPRINT as the node's `obligation` field does: a body lying across the centre
     lane and its neighbour engages it.
  4. "at any time" (s4) carries no `always`. The obligation is written for an instant and
     `Grounding` applies it at every instant of the episode.
  5. "where the highway is clearly visible" (s10) is the node's operationalization: the concept
     `drv.sight_distance_adequate` compares the recorded sight distance with the distance the
     model gives for a's speed under `p.stopping_decel` and `p.reaction_time`. The second conjunct
     states that the centre lane itself records a sight distance and that it is a real distance:
     the concept is undefined where nothing is recorded, and `st.sight_distance`, which the
     operationalization names beside the concept, is read there and nowhere else. It is a
     presence test, not a second threshold — its only magnitude is zero.
  6. "clear of traffic for a safe distance" (s11) is the node's gap-acceptance convention, read
     on the centre lane the obligation has bound: the lateral component of `rel.surface_gap` to b
     at or above `p.lateral_clearance`, `drv.time_gap` to b at or above `p.headway`, and
     `drv.time_to_conflict` with EVERY user the centre lane holds at or above `p.ttc_bound`. The
     projection horizon of `drv.time_to_conflict` is `p.ttc_bound` itself — the node names no
     other parameter for it, and the concept returns its horizon exactly when it predicts no
     conflict inside it, so "stays above the bound" is the comparison `≥` against that horizon.
     The quantifier needs no "other than a" guard: a's time to conflict with itself is the
     horizon, so a satisfies its own test.
  7. "In preparation for a left turn" (s13) is the left indicator showing AND a left turn
     following within `p.turn_window`. Preparation is not observable on its own: the node claims
     `sig.turn_indicator` and `drv.turning` on the span, and the conjunction is what makes the
     exception the preparation of a turn that happens rather than either a bare signal or the
     turn itself, which `drv.turning` alone would report only once it was under way.
  8. "allocated exclusively to traffic moving in the direction in which the vehicle is
     proceeding" (s16) is the recorded direction of the centre lane agreeing with a's heading:
     their dot product is positive. `kin.heading` is the node's atom for a direction of travel;
     the node claims it on s13, and this is the one span whose words name the direction in which
     the vehicle is proceeding. See task_result.md.
  9. "a sign is posted to give notice of such allocation" (s17) is a regulatory sign of the scene
     that governs that lane: `dev.regulatory_sign` with `dev.governs`. The ontology has no sign
     code for a lane allocation, so no legend is required beyond the device's kind.

  The only magnitude in this file is the statute's own "three", declared on s1 and written once;
  the comparisons of 5 and 8 are against zero. Every other quantity is a named parameter.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_223_2_o2

/-- The binders, as arguments. -/
private def subj : Arg := .var "a"
private def passed : Arg := .var "b"

/-- s1's figure: the statute's "three", a dimensionless count. -/
private def threeLanes : Term := .lit (Q.ofInt 3) .count

private def noDistance : Term := .lit Q.zero .metre
private def noProjection : Term := .lit Q.zero .ratio

/-- The classes the node's s5 element lists for the corpus's word "vehicle". -/
private def vehicleClasses : List String :=
  ["ru_motor_vehicle", "ru_motorcycle", "ru_moped", "ru_bus", "ru_transit_bus", "ru_taxicab",
   "ru_tour_bus_or_limousine", "ru_truck", "ru_commercial_motor_vehicle",
   "ru_trailer_or_combination", "ru_bicycle", "ru_animal_or_animal_drawn",
   "ru_emergency_vehicle", "ru_official_vehicle", "ru_procession_vehicle"]

/-- One of the classes the word "vehicle" covers. -/
private def isVehicle (x : Arg) : Formula :=
  vehicleClasses.foldr (fun n acc => .or (.atom n [x] []) acc) .ff

-- ---------------------------------------------------------------------------------------------
-- s1: the trigger — a roadway divided into three clearly marked lanes
-- ---------------------------------------------------------------------------------------------

/-- The census `st.lane_adjacency` records on a lane: how many lanes the division has. -/
private def laneCount (l : String) : Term := .measure "st_lane_adjacency" [.var l, .lit "count"]

/-- Marked off on both sides: a recorded marking whose type is not `none`. -/
private def clearlyMarked (l : String) : Formula :=
  .and (.not (.atom "st_lane_marking" [.var l, .lit "left", .lit "none"] []))
       (.not (.atom "st_lane_marking" [.var l, .lit "right", .lit "none"] []))

/-- s1: a is upon a roadway. -/
private def uponRoadway : Formula :=
  .existsRegion .roadway "r"
    (.and (.atom "st_roadway" [.var "r"] [])
          (.atom "rel_occupies" [subj, .var "r"] []))

/-- s1: the division a is driving in has the stated number of clearly marked lanes. -/
private def dividedIntoThree : Formula :=
  .existsRegion .lane "l"
    (.and (.atom "st_lane" [.var "l"] [])
      (.and (.atom "rel_occupies" [subj, .var "l"] [])
        (.and (.cmp (laneCount "l") .eq threeLanes) (clearlyMarked "l"))))

-- ---------------------------------------------------------------------------------------------
-- s6: the centre lane, and a's footprint in it
-- ---------------------------------------------------------------------------------------------

/-- A recorded neighbouring lane on the given side. -/
private def hasNeighbour (l side v : String) : Formula :=
  .existsRegion .lane v (.atom "st_lane_adjacency" [.var l, .lit side, .var v] [])

/-- The carriageway carries a centre line: it is undivided, and its middle lane is the shared one. -/
private def carriesCentreLine : Formula :=
  .existsRegion .centreLine "c" (.atom "st_centre_line" [.var "c"] [])

/-- s6: a's footprint overlaps `l`, and `l` is the centre lane of the division. -/
private def inCentreLane (l : String) : Formula :=
  .and (.atom "rel_occupies" [subj, .var l] [])
    (.and (hasNeighbour l "left" "nl")
      (.and (hasNeighbour l "right" "nr") carriesCentreLine))

-- ---------------------------------------------------------------------------------------------
-- s9…s11: exception (a) — overtaking and passing, clearly visible, the lane clear
-- ---------------------------------------------------------------------------------------------

/-- s10's standard: the model finds the recorded sight distance adequate for a's speed, and the
    lane records a sight distance at all. -/
private def clearlyVisible (l : String) : Formula :=
  .and (.derived "drv_sight_distance_adequate" [subj]
          [.param "p.stopping_decel", .param "p.reaction_time"])
       (.cmp (.measure "st_sight_distance" [.var l]) .gt noDistance)

/-- s11's standard: the lateral clearance to b, the time gap to b, and the time to conflict with
    every user the centre lane holds. -/
private def clearOfTraffic (l : String) : Formula :=
  .and (.cmp (.measure "rel_surface_gap" [subj, passed, .lit "lateral"]) .ge
             (.param "p.lateral_clearance"))
    (.and (.cmp (.quantity "drv_time_gap" [subj, passed] []) .ge (.param "p.headway"))
      (.forallUser "u"
        (.implies (.atom "rel_occupies" [.var "u", .var l] [])
          (.cmp (.quantity "drv_time_to_conflict" [subj, .var "u"] [.param "p.ttc_bound"]) .ge
                (.param "p.ttc_bound")))))

/-- s9 with s10 and s11: a is overtaking and passing b, a vehicle travelling the same way. -/
private def overtakingException (l : String) : Formula :=
  .and (.derived "drv_overtaking" [subj, passed] [.param "p.same_direction_cos"])
    (.and (.atom "rel_same_direction" [subj, passed] [.param "p.same_direction_cos"])
      (.and (clearlyVisible l) (clearOfTraffic l)))

-- ---------------------------------------------------------------------------------------------
-- s13: exception (b) — in preparation for a left turn
-- ---------------------------------------------------------------------------------------------

private def leftTurnException : Formula :=
  .and (.atom "sig_turn_indicator" [subj, .lit "left"] [])
       (.within .time (.param "p.turn_window") "a"
          (.derived "drv_turning" [subj, .lit "left"]
             [.param "p.turn_angle", .param "p.turn_window"]))

-- ---------------------------------------------------------------------------------------------
-- s16, s17: exception (c) — the centre lane allocated to a's direction, and signed
-- ---------------------------------------------------------------------------------------------

/-- The recorded direction of the lane, projected on the direction a is proceeding in. -/
private def alongLane (l : String) : Term :=
  .add (.mul (.measure "st_lane_direction" [.var l, .lit "x"]) (.measure "kin_heading" [subj, .lit "x"]))
       (.mul (.measure "st_lane_direction" [.var l, .lit "y"]) (.measure "kin_heading" [subj, .lit "y"]))

private def allocatedException (l : String) : Formula :=
  .and (.cmp (alongLane l) .gt noProjection)
       (.existsDevice .regulatorySign "d"
          (.and (.atom "dev_regulatory_sign" [.var "d"] [])
                (.atom "dev_governs" [.var "d", .var l] [])))

-- ---------------------------------------------------------------------------------------------

private def exceptions (l : String) : Formula :=
  .or (overtakingException l) (.or leftTurnException (allocatedException l))

private def visibility : Operationalization :=
  { standard := "where the highway is clearly visible"
    concepts := ["drv.sight_distance_adequate", "st.sight_distance"]
    params := ["p.reaction_time", "p.stopping_decel"]
    convention :=
      "Stopping-/passing-sight-distance model of the ontology's ‘clearly visible for a sufficient distance; view obstructed’ row: `st.sight_distance` at the subject's position is compared, by `drv.sight_distance_adequate`, with the distance the model gives for the subject's speed under design deceleration `p.stopping_decel` and design perception-reaction time `p.reaction_time`."
    surrogate := false }

private def gapAcceptance : Operationalization :=
  { standard := "the center lane is clear of traffic for a safe distance"
    concepts := ["rel.surface_gap", "drv.time_gap", "drv.time_to_conflict"]
    params := ["p.lateral_clearance", "p.headway", "p.ttc_bound"]
    convention :=
      "Gap-acceptance convention paired with the ontology's safe-distance row: the lateral component of `rel.surface_gap` to the other user stays at or above `p.lateral_clearance`, `drv.time_gap` after the manoeuvre stays at or above `p.headway`, and `drv.time_to_conflict` with every affected user stays above `p.ttc_bound`. The affected users are those in the centre lane ahead of a; ‘clear of traffic’ is their absence within the bounded gap."
    surrogate := false }

def rule : Rule :=
  { id := "NRS_484B_223_2_o2"
    laws := ["NRS-484B-223-2"]
    binders :=
      [ { name := "a", cls := .and (.atom "ru_subject" [subj] []) (isVehicle subj) }
      , { name := "b", cls := isVehicle passed } ]
    applicability := .and uponRoadway dividedIntoThree
    obligation := .forallRegion .lane "l" (.implies (inCentreLane "l") (exceptions "l"))
    assumptions := []
    operationalizations := [visibility, gapAcceptance]
    residues := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_2_o2

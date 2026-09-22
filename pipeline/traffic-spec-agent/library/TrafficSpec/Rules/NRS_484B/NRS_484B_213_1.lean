/-
  NRS 484B.213(1) — a vehicle must not be driven to the left side of the centre of a two-lane,
  two-directional highway when overtaking and passing another vehicle proceeding in the same
  direction, unless the left side is clearly visible and free of oncoming traffic for a
  sufficient distance ahead to permit the pass to be completed without interfering with the safe
  operation of any vehicle approaching from the opposite direction or any vehicle overtaken.

  THE READING (the blueprint's, not this file's):
  - s1 subject    — the binder `a`: the subject track, of one of the classes the node lists for
                    the corpus's word "vehicle". `b` is the vehicle overtaken, `c` the vehicle
                    approaching from the opposite direction; both are vehicles, neither is the
                    subject.
  - s3 condition  — the applicability: the carriageway is a two-lane, two-directional roadway.
  - s4 trigger    — the applicability: a is overtaking and passing b, which proceeds the same way.
  - s2 obligation — the antecedent: a is driven to the left of the centre.
  - s5, s7, s8    — the consequent: the three operationalized standards, exactly as the node
                    declares them.
  - s6 condition  — the consequent: the left side is free of oncoming traffic.

  CHOICES THE TEXT DID NOT DICTATE (each one is a reading of a span, not an invention):

  1. "a two-lane, two-directional highway" (s3) is read on the lanes, not on a count: there are
     two lanes `l` and `n`, each the other's LEFT neighbour (`st.lane_adjacency`), whose
     directions oppose (`st.lane_direction`, a negative dot product — the only comparison this
     needs is against zero). Mutual left-adjacency IS "two-lane, two-directional": on any wider
     carriageway the lane left of `n` is a third lane, not `l` again. The count fields of
     `st.lane_adjacency` are not used, because comparing a count to one or to two would put a
     bare magnitude in the rule and the node declares no literal; and "`l` has no neighbour to
     its right" is not stated, because an unset neighbour in the ontology is an UNOBSERVED
     neighbour, not the absence of one — that reading made the applicability unknown wherever a
     source did not publish the field.
  2. "highway" is further required to be undivided: no region of kind `st.median_or_divider` is
     present. A divided carriageway has no "centre" of the kind s2 speaks about.
  3. "driven to the left side of the center" (s2) has two limbs, and their disjunction is the
     antecedent:
       (a) a's body lies across the dividing line — `drv.straddles_marking`, a occupying two
           lanes at once. Under the applicability the only line to straddle is the centre line,
           and the scene must carry a `st.centre_line` region for the limb to speak at all.
       (b) a's body has passed wholly beyond it: a is clear of b to the LEFT by more than their
           two half-widths — twice the signed lateral offset of a from b is at least the sum of
           the two full widths (`kin.position`, `kin.extent`). On a road that is two lanes wide
           the only place left of the overtaken vehicle's lane is left of the centre.
     "Left" is the left of the centre line's own recorded direction (`st.lane_direction` on the
     `st.centre_line` region), because the node's elements claim no atom that reports the
     subject's own direction of travel. CONSEQUENCE, stated plainly: for a subject travelling
     against the line's recorded direction the rule's "left" is that subject's right. The
     alternative — the footprint against the line itself — needs the line's POSITION, and neither
     `rel.occupies` nor `st.region_geometry` is claimed on s2; see task_result.md.
  4. s5 and s7 are one and the same test in the node: both name `drv.sight_distance_adequate`
     with `p.stopping_decel` and `p.reaction_time`, and nothing else. That test is written once.
     What distinguishes s7 — the node's "the distance required is the distance a needs to
     complete the pass and return" — is carried by the second conjunct, which is the node's other
     s7 concept, `st.sight_distance`, held against the length of the pass: the longitudinal
     clearance to b plus b's length plus a's length. No parameter and no magnitude enters there;
     the length of the pass is measured, not chosen.
  5. s6 is written as two conjuncts because the node claims two concepts on the span: c is not
     oncoming (`rel.oncoming`), and a is not meeting c (`drv.meeting`). The second is entailed by
     the first under the ontology's semantics (meeting is oncoming and a conflict within the
     horizon); it is written because the node claims it, and it narrows nothing.
  6. s8's three bounds are read exactly as the node's convention states them, over the two
     affected users the node names — the overtaken b and the oncoming c: the lateral component of
     `rel.surface_gap` to b is at least `p.lateral_clearance`; `drv.time_gap` to b reaches
     `p.headway` AFTER the manoeuvre, which is `eventually`, since during the pass the two bodies
     overlap longitudinally and no headway exists; and `drv.time_to_conflict` with b and with c
     is at least `p.ttc_bound`. The projection horizon of `drv.time_to_conflict` is `p.ttc_bound`
     itself — the node declares no horizon parameter — so the concept returns the horizon when no
     conflict is predicted inside it, and the comparison is `≥`: "no conflict predicted within
     `p.ttc_bound`". With `>` the no-conflict case would read as a violation. `drv.meeting` takes
     the same horizon for the same reason.
  7. "any vehicle approaching from the opposite direction or any vehicle overtaken" is read over
     the node's binders c and b, not over a quantifier: the node gives a binder for each, so the
     rule is evaluated once per candidate pair and the episode aggregates.

  No number below is a value this file chose: every magnitude is a parameter of the run's reading
  or a measured quantity, and the only literals are zero.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_213_1

/-- The binders, as arguments. -/
private def subj : Arg := .var "a"
private def over : Arg := .var "b"
private def onc : Arg := .var "c"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pReaction : Term := .param "p.reaction_time"
private def pDecel : Term := .param "p.stopping_decel"
private def pLateral : Term := .param "p.lateral_clearance"
private def pHeadway : Term := .param "p.headway"
private def pTtc : Term := .param "p.ttc_bound"
private def pOncomingCos : Term := .param "p.oncoming_cos"
private def pSameDirCos : Term := .param "p.same_direction_cos"

private def zeroMetres : Term := .lit Q.zero .metre
private def zeroRatio : Term := .lit Q.zero .ratio

/-- The classes the node's s1 element lists for the corpus's word "vehicle". -/
private def vehicleClasses : List String :=
  ["ru_motor_vehicle", "ru_motorcycle", "ru_moped", "ru_bus", "ru_transit_bus", "ru_taxicab",
   "ru_tour_bus_or_limousine", "ru_truck", "ru_commercial_motor_vehicle",
   "ru_trailer_or_combination", "ru_bicycle", "ru_animal_or_animal_drawn",
   "ru_emergency_vehicle", "ru_official_vehicle", "ru_procession_vehicle"]

/-- One of the classes the word "vehicle" covers. -/
private def isVehicle (x : Arg) : Formula :=
  vehicleClasses.foldr (fun n acc => .or (.atom n [x] []) acc) .ff

-- ---------------------------------------------------------------------------------------------
-- s3, s4: when the duty is engaged
-- ---------------------------------------------------------------------------------------------

/-- The dot product of two lane directions. -/
private def directionsDot (l n : String) : Term :=
  .add (.mul (.measure "st_lane_direction" [.var l, .lit "x"])
             (.measure "st_lane_direction" [.var n, .lit "x"]))
       (.mul (.measure "st_lane_direction" [.var l, .lit "y"])
             (.measure "st_lane_direction" [.var n, .lit "y"]))

/-- s3: two lanes, each the other's LEFT neighbour, running opposite ways. Mutual left-adjacency
    is exactly the two-lane two-directional topology: on any wider carriageway the lane to the
    left of `n` is a third lane, not `l` again. -/
private def twoLaneTwoDirectional : Formula :=
  .existsRegion .lane "l"
    (.and (.atom "st_lane" [.var "l"] [])
      (.existsRegion .lane "n"
        (.and (.atom "st_lane_adjacency" [.var "l", .lit "left", .var "n"] [])
          (.and (.atom "st_lane_adjacency" [.var "n", .lit "left", .var "l"] [])
                (.cmp (directionsDot "l" "n") .lt zeroRatio)))))

/-- s3: the place the duty speaks about is a roadway, and it is not divided. -/
private def undividedRoadway : Formula :=
  .and (.existsRegion .roadway "rw" (.atom "st_roadway" [.var "rw"] []))
       (.not (.existsRegion .medianOrDivider "md" (.atom "st_median_or_divider" [.var "md"] [])))

/-- s4: a is overtaking and passing b, which proceeds in the same direction. -/
private def overtakingSameDirection : Formula :=
  .and (.atom "rel_same_direction" [subj, over] [pSameDirCos])
       (.derived "drv_overtaking" [subj, over] [pSameDirCos])

-- ---------------------------------------------------------------------------------------------
-- s2: driven to the left side of the centre
-- ---------------------------------------------------------------------------------------------

/-- The signed lateral offset of a from b about the centre line `cl`'s own direction, positive to
    the left of that direction: the 2-D cross product of the direction with `p_a − p_b`. -/
private def leftOffsetFromOvertaken : Term :=
  .sub (.mul (.measure "st_lane_direction" [.var "cl", .lit "x"])
             (.sub (.measure "kin_position" [subj, .lit "y"])
                   (.measure "kin_position" [over, .lit "y"])))
       (.mul (.measure "st_lane_direction" [.var "cl", .lit "y"])
             (.sub (.measure "kin_position" [subj, .lit "x"])
                   (.measure "kin_position" [over, .lit "x"])))

/-- s2: across the dividing line, or wholly clear of the overtaken vehicle to its left. -/
private def leftOfTheCentre : Formula :=
  .existsRegion .centreLine "cl"
    (.and (.atom "st_centre_line" [.var "cl"] [])
      (.or (.derived "drv_straddles_marking" [subj] [])
           (.cmp (.add leftOffsetFromOvertaken leftOffsetFromOvertaken) .ge
                 (.add (.measure "kin_extent" [subj, .lit "width"])
                       (.measure "kin_extent" [over, .lit "width"])))))

-- ---------------------------------------------------------------------------------------------
-- s5, s6, s7, s8: what makes the left side lawful
-- ---------------------------------------------------------------------------------------------

/-- s5, first half of s7: the sight distance where a is covers a's stopping distance under the
    design deceleration and perception-reaction time of the node's convention. -/
private def clearlyVisible : Formula :=
  .derived "drv_sight_distance_adequate" [subj] [pDecel, pReaction]

/-- s7: the distance the pass needs — the longitudinal clearance to b, plus b's length, plus a's
    own length: the road a must cover to draw level, clear b and return. -/
private def passingLength : Term :=
  .add (.add (.measure "rel_surface_gap" [subj, over, .lit "longitudinal"])
             (.measure "kin_extent" [over, .lit "length"]))
       (.measure "kin_extent" [subj, .lit "length"])

/-- s7: the sight distance ahead covers the length of the pass. -/
private def visibleForThePass : Formula :=
  .forallRegion .roadway "rw" (.cmp (.measure "st_sight_distance" [.var "rw"]) .ge passingLength)

/-- s6: the left side is free of oncoming traffic — c does not approach from the opposite
    direction, and a is not meeting it. -/
private def freeOfOncoming : Formula :=
  .and (.not (.atom "rel_oncoming" [subj, onc] [pOncomingCos]))
       (.not (.derived "drv_meeting" [subj, onc] [pTtc, pOncomingCos]))

/-- s8: the lateral clearance to the vehicle overtaken. -/
private def lateralClearanceKept : Formula :=
  .cmp (.measure "rel_surface_gap" [subj, over, .lit "lateral"]) .ge pLateral

/-- s8: the headway to the vehicle overtaken is restored once the manoeuvre is over. -/
private def headwayRestored : Formula :=
  .eventually (.cmp (.quantity "drv_time_gap" [subj, over] []) .ge pHeadway)

/-- s8: no conflict with the party within the horizon the node's bound sets. -/
private def noConflictWith (x : Arg) : Formula :=
  .cmp (.quantity "drv_time_to_conflict" [subj, x] [pTtc]) .ge pTtc

/-- s5, s6, s7, s8 together: what the statute's "unless" requires of the left side. -/
private def leftSideLawful : Formula :=
  .and clearlyVisible
  (.and visibleForThePass
  (.and freeOfOncoming
  (.and lateralClearanceKept
  (.and headwayRestored
  (.and (noConflictWith over) (noConflictWith onc))))))

-- ---------------------------------------------------------------------------------------------

def rule : Rule :=
  { id := "NRS_484B_213_1"
    laws := ["NRS-484B-213-1"]
    binders :=
      [ { name := "a", cls := .and (.atom "ru_subject" [subj] []) (isVehicle subj) }
      , { name := "b", cls := isVehicle over }
      , { name := "c", cls := isVehicle onc } ]
    applicability := .and undividedRoadway (.and twoLaneTwoDirectional overtakingSameDirection)
    obligation := .implies leftOfTheCentre leftSideLawful
    assumptions := []
    operationalizations :=
      [ { standard := "such left side is clearly visible"
          concepts := ["drv.sight_distance_adequate", "st.sight_distance"]
          params := ["p.reaction_time", "p.stopping_decel"]
          convention := "Stopping-/passing-sight-distance model of the ontology's ‘clearly visible for a sufficient distance; view obstructed’ row: `st.sight_distance` at the subject's position is compared, by `drv.sight_distance_adequate`, with the distance the model gives for the subject's speed under design deceleration `p.stopping_decel` and design perception-reaction time `p.reaction_time`."
          surrogate := false }
      , { standard := "for a sufficient distance ahead to permit such overtaking and passing to be completely made"
          concepts := ["drv.sight_distance_adequate", "st.sight_distance"]
          params := ["p.reaction_time", "p.stopping_decel"]
          convention := "Stopping-/passing-sight-distance model of the ontology's ‘clearly visible for a sufficient distance; view obstructed’ row: `st.sight_distance` at the subject's position is compared, by `drv.sight_distance_adequate`, with the distance the model gives for the subject's speed under design deceleration `p.stopping_decel` and design perception-reaction time `p.reaction_time`. The model is run in its passing form: the distance required is the distance a needs to complete the pass and return, so the sight distance must cover it at a's speed."
          surrogate := false }
      , { standard := "without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken"
          concepts := ["rel.surface_gap", "drv.time_gap", "drv.time_to_conflict"]
          params := ["p.lateral_clearance", "p.headway", "p.ttc_bound"]
          convention := "Gap-acceptance convention paired with the ontology's safe-distance row: the lateral component of `rel.surface_gap` to the other user stays at or above `p.lateral_clearance`, `drv.time_gap` after the manoeuvre stays at or above `p.headway`, and `drv.time_to_conflict` with every affected user stays above `p.ttc_bound`. The affected users are every oncoming vehicle c and the overtaken vehicle b."
          surrogate := false } ]
    residues := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_1

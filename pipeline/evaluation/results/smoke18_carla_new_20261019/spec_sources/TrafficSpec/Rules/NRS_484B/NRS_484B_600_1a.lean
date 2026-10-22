/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (boilerplate): It is unlawful for
    t2 (trigger): any person to drive or operate
    t3 (subject): a vehicle of any kind or character
    t4 (boilerplate): at:
    t5 (obligation): A rate of speed
    t6 (standard): greater than is reasonable or proper,
    t7 (definitional): having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    t2: atoms ['kin.speed'], derived []
    t3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t5: atoms ['kin.speed'], derived []
    t7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.highway', 'st.lane', 'rel.ahead_behind_in_lane', 'rel.longitudinal_overlap', 'rel.surface_gap', 'env.wet_road', 'env.ice_or_snow', 'env.precipitation', 'env.visibility', 'env.darkness', 'st.lane_width', 'st.sight_distance']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
  The text states no figure, so the only literal here is zero, the mark against which a signed
  overlap is read.

  How each span is written.

  t3 — `clsV`: the binder's class is the aggregate atom with the posted definition's id as its
  literal argument; which classes count under `DEF-NRS-484A-320::vehicle` stays with the reading.
  "of any kind or character" adds no class of its own, so nothing is conjoined to it.

  t2 — `applicability`: the node reads "to drive or operate" through the vehicle's own controlled
  motion (its `observable_reading` narrowing on t2, the plan's and not restated below), so the
  span is the subject's speed standing clear of `p.motion_speed_resolution`, the resolution below
  which a trajectory source reads a road user as at rest rather than moving.

  t5, t6, t7 — the obligation. The standard of t6 is the node's one operationalization, declared
  `surrogate`, and the whole duty is its bound: the stopping-sight-distance model, written as the
  requirement that the distance in which the subject could stop not exceed the distance clear
  ahead of it. The distance clear ahead is "the least of" the magnitudes the conditions supply,
  which is written as a conjunction of one bound per magnitude — a quantity is below the least of
  several exactly where it is below each of them — so each condition moves its own bound and no
  minimum has to be formed over sources of different arity.

    `stopping` (t5, and the model's left-hand side) is `drv.motion.stopping_distance` of a road
    user at `p.reaction_time` and at the deceleration the surface affords, the concept's two
    parameters in the catalogue's order. The surface selects the deceleration with `Term.cond`,
    which is how a condition that selects among bounds is written: `p.decel_ice` where
    `env.ice_or_snow` holds, else `p.decel_wet` where `env.wet_road` or `env.precipitation` holds,
    else `p.decel_dry`. The concept reads `kin.speed`, which is how t5's "rate of speed" enters
    the bound; the same term is taken of a member of the traffic ahead, at the same reaction time
    and the same surface deceleration, as the convention directs.

    `onNarrowLane` and `requiredDistance` (the width factor of t7): where a lane the subject
    occupies — `st.lane` anchored to the subject by `rel.occupies` — is narrower than
    `p.narrow_lane_width`, the distance that must fit is the stopping distance raised by
    `p.narrow_lane_margin`; elsewhere it is the stopping distance itself. Again a `Term.cond`,
    and the raised distance is used in every one of the bounds below, as the convention states.

    `withinSightDistance` (t7, "other highway conditions", and the alignment of the way): over the
    lanes the subject occupies, `st.sight_distance` of that lane bounds the required distance. The
    quantifier is anchored to the subject by `rel.occupies`, and `st.lane` holds the region to the
    kind the node claims.

    `withinVisibility` (t7, "the weather"): `env.visibility`, the visibility distance, bounds it.

    `withinHeadlampReach` (t7, "other highway conditions"): where `env.darkness` holds, the
    headlamp reach `p.seeing_distance_darkness` bounds it; where it does not, this bound is silent.

    `withinTrafficClearance` (t7, "the traffic"): over the road users of the scene, a member of
    the traffic that stands in the path the subject sweeps bounds the required distance by what it
    leaves — the longitudinal surface gap to it raised by its own stopping distance. A road user
    is such a member where it is not the subject (`same`), carries the admitted aggregate
    `DEF-NRS-484A-285::traffic`, occupies a highway region (`st.highway` with `rel.occupies`, the
    definition's "using any highway for purposes of travel" read through presence, which is the
    node's own narrowing on t5), is ahead of the subject in the subject's lane
    (`rel.ahead_behind_in_lane`, whose contract already holds the two to one lane), does not
    overlap the subject along the lane axis (`rel.longitudinal_overlap`, positive when side by
    side, so "does not overlap" is at most zero), and stands within `p.path_lateral_clearance` of
    the subject's path (the lateral component of `rel.surface_gap`, in the subject's frame). The
    region variable of the highway test is anchored to that road user by `rel.occupies`, and the
    road user to the subject by the relations that follow.

  The reading of this session, declared in `narrowings`.

    t6 — the lane of the width factor and of the sight distance is read as *every* lane the
    subject occupies, not one. The node's words are singular ("the lane the subject occupies"),
    and a body that straddles two lanes occupies both: the file bounds the required distance by
    the sight distance of each of them and raises it where any of them is narrow, which is the
    stricter of the readings the singular leaves open. Where the subject occupies no lane region
    at all, the sight-distance bound and the width factor are both silent and the duty rests on
    the visibility, the darkness and the traffic.

  Every other choice is the node's and is written as the node maps it; the node's own narrowings —
  the observable readings on t2 and t5, the lane-width reading of "width of the highway", the
  choice among the factors the catch-all covers, the sight distance read on the subject's lane,
  the path the subject sweeps, and the clear distance a leading road user leaves — are the plan's
  and are not restated here.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The road user the traffic bound quantifies over. -/
def uU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDecelDry : Term := .param "p.decel_dry"
def pDecelIce : Term := .param "p.decel_ice"
def pDecelWet : Term := .param "p.decel_wet"
def pMotionSpeedResolution : Term := .param "p.motion_speed_resolution"
def pNarrowLaneMargin : Term := .param "p.narrow_lane_margin"
def pNarrowLaneWidth : Term := .param "p.narrow_lane_width"
def pPathLateralClearance : Term := .param "p.path_lateral_clearance"
def pReactionTime : Term := .param "p.reaction_time"
def pSeeingDistanceDarkness : Term := .param "p.seeing_distance_darkness"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: t2 (trigger): any person to drive or operate — the subject is being driven,
    its speed standing clear of the resolution below which a source reads it as at rest. -/
def applicability : Formula :=
  .cmp (.measure "kin_speed" [vV]) .gt pMotionSpeedResolution

/-- t7, the surface of the highway: icy or snow-covered. -/
def icySurface : Formula := .atom "env_ice_or_snow" [] []

/-- t7, the surface of the highway and the weather: wet, or precipitation falling. -/
def wetSurface : Formula :=
  .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

/-- The distance in which a road user could come to rest, at the reaction time and at the stated
    deceleration. -/
def stoppingAt (x : Arg) (deceleration : Term) : Term :=
  .quantity "drv_motion_stopping_distance" [x] [pReactionTime, deceleration]

/-- t5 and the model's left-hand side: the distance in which a road user could come to rest, at
    the deceleration the surface affords. -/
def stopping (x : Arg) : Term :=
  .cond icySurface (stoppingAt x pDecelIce)
    (.cond wetSurface (stoppingAt x pDecelWet) (stoppingAt x pDecelDry))

/-- t7, the width of the highway: a lane the subject occupies is narrower than the design width. -/
def onNarrowLane : Formula :=
  .existsRegion (.lit "lane") "nl"
    (.and (.atom "st_lane" [.var "nl"] [])
      (.and (.atom "rel_occupies" [vV, .var "nl"] [])
        (.cmp (.measure "st_lane_width" [.var "nl"]) .lt pNarrowLaneWidth)))

/-- The distance that must fit within the distance clear ahead: the subject's stopping distance,
    raised by the narrow-lane margin where the lane it occupies is below the design width. -/
def requiredDistance : Term :=
  .cond onNarrowLane (.mul (stopping vV) pNarrowLaneMargin) (stopping vV)

/-- t7, the alignment of the way and what stands beside it: the required distance fits within the
    sight distance of every lane the subject occupies. -/
def withinSightDistance : Formula :=
  .forallRegion (.lit "lane") "r"
    (.implies (.and (.atom "st_lane" [.var "r"] []) (.atom "rel_occupies" [vV, .var "r"] []))
      (.cmp requiredDistance .le (.measure "st_sight_distance" [.var "r"])))

/-- t7, the weather: the required distance fits within the visibility distance. -/
def withinVisibility : Formula :=
  .cmp requiredDistance .le (.measure "env_visibility" [])

/-- t7, an other highway condition: where it is dark, the required distance fits within the reach
    of the headlamps. -/
def withinHeadlampReach : Formula :=
  .implies (.atom "env_darkness" [] [])
    (.cmp requiredDistance .le pSeeingDistanceDarkness)

/-- t7, the traffic: `u` is a member of the traffic standing in the path the subject sweeps —
    not the subject itself, of the admitted aggregate, occupying a highway region, ahead of the
    subject in the subject's lane, not overlapping it along the lane axis, and within the lateral
    clearance of its path. -/
def inSubjectPath : Formula :=
  .and (.not (.same uU vV))
    (.and (.atom "ru_aggregate" [uU, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and
        (.existsRegion (.lit "highway") "h"
          (.and (.atom "st_highway" [.var "h"] [])
            (.atom "rel_occupies" [uU, .var "h"] [])))
        (.and (.atom "rel_ahead_behind_in_lane" [uU, vV] [])
          (.and (.cmp (.measure "rel_longitudinal_overlap" [uU, vV]) .le zeroMetres)
            (.cmp (.measure "rel_surface_gap" [vV, uU, .lit "lateral"]) .lt
              pPathLateralClearance)))))

/-- t7, the traffic: against such a member the distance clear ahead is what it leaves — the
    longitudinal surface gap to it, raised by the distance in which it would itself come to rest
    at the same reaction time and the same surface deceleration. -/
def withinTrafficClearance : Formula :=
  .forallUser "u"
    (.implies inSubjectPath
      (.cmp requiredDistance .le
        (.add (.measure "rel_surface_gap" [vV, uU, .lit "longitudinal"]) (stopping uU))))

/-- Obligation: t5 (obligation): A rate of speed; t6 (standard): greater than is reasonable or proper, -/
def obligation : Formula :=
  .and withinSightDistance
    (.and withinVisibility
      (.and withinHeadlampReach withinTrafficClearance))

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.motion.stopping_distance", "env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "rel.ahead_behind_in_lane", "rel.longitudinal_overlap", "rel.occupies", "rel.surface_gap", "st.highway", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.reaction_time", "p.decel_dry", "p.decel_wet", "p.decel_ice", "p.seeing_distance_darkness", "p.path_lateral_clearance", "p.narrow_lane_width", "p.narrow_lane_margin"]
          convention := "The stopping-sight-distance model of highway geometric design: a speed is bounded by the requirement that the vehicle be able to stop within the distance it can see to be clear ahead of it. The stopping distance is the distance covered during the driver's perception-reaction time (`p.reaction_time`) plus the braking distance at the deceleration the surface affords, which the surface condition selects among the design guide's surface-friction classes (`p.decel_dry` on a dry surface, `p.decel_wet` where the surface is wet or precipitation is falling, `p.decel_ice` where it is icy or snow-covered). The distance clear ahead is the least of the magnitudes the conditions supply, so the bound moves with each as it moves: the sight distance of the subject's place (which carries the alignment of the road and what stands beside it, and so the catch-all 'other highway conditions'), the visibility distance (the weather), the headlamp reach `p.seeing_distance_darkness` where it is dark (an other highway condition), and the clearance the traffic leaves. The traffic enters by the same model and not by a different one: a member of the traffic — a road user the atom `ru.aggregate` carries under the admitted id `DEF-NRS-484A-285::traffic`, occupying a highway region — truncates the distance clear ahead only where it stands in the path the subject sweeps, that is where it is ahead of the subject in the subject's lane, its body does not overlap the subject's along the lane axis (a road user abreast of the subject leaves no distance along the lane and is a road user being passed, which the passing standards govern), and its lateral surface gap to the subject is less than the path clearance `p.path_lateral_clearance`. Against such a road user the clear distance is what that road user leaves: the longitudinal surface gap to it, plus the distance in which that road user would itself come to rest at the same reaction time and the same surface deceleration — the leading road user becomes an obstruction only where it has stopped, and a vehicle that keeps its speed carries the point of collision forward with it. Width enters as a condition selecting among bounds: where the lane the subject occupies is narrower than the design width `p.narrow_lane_width`, the stopping distance must fit within each of those distances with the margin `p.narrow_lane_margin` by which a narrow-lane design raises the required clear distance. The parameter values come from the design guide's stopping-sight-distance tables, its surface-friction classes, headlamp-reach practice for night driving, safe-passing lateral-clearance standards, and its lane-width standards."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "t6"
          why := "the width factor and the sight distance are read on every lane the subject occupies, not on one: the node's words are singular, and a body that straddles two lanes occupies both, so the file bounds the required distance by the sight distance of each and raises it by the narrow-lane margin where any of them is below the design width — the stricter of the readings the singular leaves open. Where the subject occupies no lane region, both are silent and the duty rests on the visibility, the darkness and the traffic."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

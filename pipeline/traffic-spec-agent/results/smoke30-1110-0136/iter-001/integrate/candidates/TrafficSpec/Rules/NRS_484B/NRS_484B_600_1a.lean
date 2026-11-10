/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (obligation): It is unlawful for any person to drive or operate
    b2 (subject): a vehicle of any kind or character at:
    b3 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    b1: atoms [], derived ['drv.motion.moving']
    b2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  How each is written:
    b2 → the class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    b1 → the applicability: x in motion, `drv_motion_moving x [p.motion_speed_tolerance]`.
    b3 → the obligation, the surrogate standard, a conjunction of four bounds on x's speed:
      the surface deceleration `a` is a `Term.cond` selecting p.…_ice_or_snow where env_ice_or_snow
      holds, else p.…_wet where env_wet_road or env_precipitation holds, else p.…_dry; the stopping
      distance SD is the same selection over three calls of drv_motion_stopping_distance, each with
      p.perception_reaction_time and its own constant deceleration.
      (1) SD ≤ env_visibility; and, at each lane x occupies, SD ≤ st_sight_distance of that lane.
      (2) for every road user y, not x, ahead of x in the same lane (rel_ahead_behind_in_lane y x):
          speed·p.following_min_time_headway ≤ rel_surface_gap x y (the distance between the bodies).
      (3) at each lane x occupies: speed²·st_curvature ≤ a.
      (4) at each lane l x occupies: speed·p.lane_keeping_margin_per_speed ≤ (st_lane_width l −
          kin_extent x width)/2, written without the literal 2 as
          speed·m + speed·m ≤ st_lane_width l − kin_extent x width.

  Choice the record left open (declared as a narrowing on b3):
    "the sight distance at x's place" and "the curvature at x's place" are read on the lanes x
    occupies (st.lane, rel.occupies), the same regions the width bound reads; where x occupies no
    mapped lane neither sets a bound.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFollowingMinTimeHeadway : Term := .param "p.following_min_time_headway"
def pLaneKeepingMarginPerSpeed : Term := .param "p.lane_keeping_margin_per_speed"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pPerceptionReactionTime : Term := .param "p.perception_reaction_time"
def pSurfaceFrictionAccelDry : Term := .param "p.surface_friction_accel_dry"
def pSurfaceFrictionAccelIceOrSnow : Term := .param "p.surface_friction_accel_ice_or_snow"
def pSurfaceFrictionAccelWet : Term := .param "p.surface_friction_accel_wet"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: b1, x is being driven — in motion. -/
def applicability : Formula := .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]

/-- x's speed. -/
def speed : Term := .measure "kin_speed" [vX]

/-- The surface: icy or snow-covered; else wet (a wet road or falling precipitation). -/
def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
def wet : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

/-- The deceleration the surface sustains, selected by the surface. -/
def surfaceAccel : Term :=
  .cond iceOrSnow pSurfaceFrictionAccelIceOrSnow
    (.cond wet pSurfaceFrictionAccelWet pSurfaceFrictionAccelDry)

/-- The stopping distance at a constant deceleration. -/
def stoppingDistanceAt (decel : Term) : Term :=
  .quantity "drv_motion_stopping_distance" [vX] [pPerceptionReactionTime, decel]

/-- The stopping distance at the deceleration the surface selects, one call per surface. -/
def stoppingDistance : Term :=
  .cond iceOrSnow (stoppingDistanceAt pSurfaceFrictionAccelIceOrSnow)
    (.cond wet (stoppingDistanceAt pSurfaceFrictionAccelWet) (stoppingDistanceAt pSurfaceFrictionAccelDry))

/-- (1) through the air: the stopping distance within the visibility distance. -/
def visibilityBound : Formula :=
  .cmp stoppingDistance .le (.measure "env_visibility" [])

/-- (2) traffic: the speed times the minimum time headway within the gap to each road user ahead
    of x in its lane. -/
def trafficBound : Formula :=
  .forallUser "y"
    (.implies
      (.and (.not (.same (.var "y") vX)) (.atom "rel_ahead_behind_in_lane" [.var "y", vX] []))
      (.cmp (.mul speed pFollowingMinTimeHeadway) .le (.measure "rel_surface_gap" [vX, .var "y"])))

/-- (1) along the road, (3) the bend and (4) the width, at every lane x occupies. -/
def laneBounds : Formula :=
  let l : Arg := .var "l"
  let margin : Term := .mul speed pLaneKeepingMarginPerSpeed
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vX, l] [])
      (.and (.cmp stoppingDistance .le (.measure "st_sight_distance" [l]))
        (.and (.cmp (.mul (.mul speed speed) (.measure "st_curvature" [l])) .le surfaceAccel)
          (.cmp (.add margin margin) .le
            (.sub (.measure "st_lane_width" [l]) (.measure "kin_extent" [vX, .lit "width"]))))))

/-- Obligation: b1 (obligation): It is unlawful for any person to drive or operate; b3 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .and visibilityBound (.and trafficBound laneBounds)

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.motion.stopping_distance", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.extent", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.curvature", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.perception_reaction_time", "p.surface_friction_accel_dry", "p.surface_friction_accel_wet", "p.surface_friction_accel_ice_or_snow", "p.following_min_time_headway", "p.lane_keeping_margin_per_speed"]
          convention := "Stopping-sight-distance model (AASHTO Green Book): a speed is reasonable only where the vehicle can halt, after a perception-reaction time and at the deceleration the surface sustains, within the distance it can see along the road (st.sight_distance) and through the air (env.visibility); the surface selects that deceleration (ice or snow, else a wet road or falling precipitation, else dry). Traffic: time-headway convention, the speed times the minimum time headway within the gap to each road user of the traffic ahead in the lane. Other highway conditions: the lateral acceleration in a bend (speed squared times st.curvature) within the acceleration the surface sustains. Width: time-to-line-crossing convention, the speed times the lateral margin needed per unit of speed within the free lateral margin, half of the lane width less the vehicle width. Each measured magnitude enters its bound, so the bound moves with the speed, the gap, the distances, the curvature and the width; the surface condition selects among bounds."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "b3"
          why := "'the sight distance at x's place' and 'the curvature at x's place' are read on each lane x occupies (st.lane, rel.occupies), the regions the width bound reads; where x occupies no mapped lane, sight distance and curvature set no bound."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

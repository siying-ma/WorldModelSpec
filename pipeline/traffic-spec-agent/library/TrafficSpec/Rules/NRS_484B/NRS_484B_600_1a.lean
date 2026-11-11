/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character
    s2 (obligation): at: A rate of speed
    s3 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived ['drv.motion.moving']
    s2: atoms ['kin.speed'], derived []

  How each is written:
    s1: the class of x is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`; "drive or operate" is the
        plan's observable reading, `drv_motion_moving x` with speed_floor p.speed_resolution, the
        whole applicability.
    s2: the rate of speed is `kin_speed x`.
    s3 (surrogate): every bound of the record holds at the observation.
        Stopping distance S: `drv_motion_stopping_distance x` with p.perception_reaction_time and a
        deceleration chosen by `Term.cond` over three calls (a call's parameters are constant terms,
        so the condition selects among the calls, not inside one): ice where env_ice_or_snow, else
        wet where env_wet_road or env_precipitation, else dry.
        (1) S ≤ st_sight_distance, (3) v·v·st_curvature ≤ p.curve_lateral_accel and
        (4) p.lateral_margin_time·v ≤ st_lane_width − kin_extent(x, width) are stated for every
        lane x occupies (rel_occupies).
        (2) S ≤ env_visibility.
        (5) for every road user y not x (same) that is ahead of x in its lane
        (rel_ahead_behind_in_lane y x: y ahead of x), p.traffic_time_headway·v ≤ rel_surface_gap x y
        (the distance read, no component).

  Choice the record left open (declared as a narrowing on s3):
    "the sight distance at x's place" and "the curvature at x's place" name no region; the place
    is read as every lane x's footprint overlaps (the region the lane-width bound already reads),
    so where x occupies no lane, sight distance and curvature set no bound.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: a lane x occupies, a road user ahead of x. -/
def vL : Arg := .var "l"
def vY : Arg := .var "y"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBrakingDecelDry : Term := .param "p.braking_decel_dry"
def pBrakingDecelIce : Term := .param "p.braking_decel_ice"
def pBrakingDecelWet : Term := .param "p.braking_decel_wet"
def pCurveLateralAccel : Term := .param "p.curve_lateral_accel"
def pLateralMarginTime : Term := .param "p.lateral_margin_time"
def pPerceptionReactionTime : Term := .param "p.perception_reaction_time"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTrafficTimeHeadway : Term := .param "p.traffic_time_headway"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1, a vehicle driven or operated, read as moving (drv.motion.moving). -/
def applicability : Formula := .derived "drv_motion_moving" [vX] [pSpeedResolution]

/-- s2: x's rate of speed. -/
def speed : Term := .measure "kin_speed" [vX]

/-- x's stopping distance at a deceleration. -/
def stoppingAt (decel : Term) : Term :=
  .quantity "drv_motion_stopping_distance" [vX] [pPerceptionReactionTime, decel]

/-- The surface conditions that select the deceleration. -/
def icy : Formula := .atom "env_ice_or_snow" [] []
def wet : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

/-- S: the stopping distance under the deceleration the surface selects. -/
def stoppingDistance : Term :=
  .cond icy (stoppingAt pBrakingDecelIce)
    (.cond wet (stoppingAt pBrakingDecelWet) (stoppingAt pBrakingDecelDry))

/-- (1), (3), (4): at every lane x occupies, the sight distance, curvature and width bounds. -/
def laneBounds : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vX, vL] [])
      (.and (.cmp stoppingDistance .le (.measure "st_sight_distance" [vL]))
        (.and (.cmp (.mul (.mul speed speed) (.measure "st_curvature" [vL])) .le pCurveLateralAccel)
          (.cmp (.mul pLateralMarginTime speed) .le
            (.sub (.measure "st_lane_width" [vL]) (.measure "kin_extent" [vX, .lit "width"]))))))

/-- (2): the stopping distance within the visibility distance. -/
def visibilityBound : Formula :=
  .cmp stoppingDistance .le (.measure "env_visibility" [])

/-- (5): the time headway to every road user ahead of x in its lane. -/
def trafficBound : Formula :=
  .forallUser "y"
    (.implies (.and (.not (.same vX vY)) (.atom "rel_ahead_behind_in_lane" [vY, vX] []))
      (.cmp (.mul pTrafficTimeHeadway speed) .le (.measure "rel_surface_gap" [vX, vY])))

/-- Obligation: s2 (obligation): at: A rate of speed; s3 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .and laneBounds (.and visibilityBound trafficBound)

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
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.motion.stopping_distance", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.extent", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.curvature", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.perception_reaction_time", "p.braking_decel_dry", "p.braking_decel_wet", "p.braking_decel_ice", "p.curve_lateral_accel", "p.lateral_margin_time", "p.traffic_time_headway"]
          convention := "Assured clear distance and design-speed conventions: the stopping sight distance model (a perception-reaction time and a braking deceleration selected by the surface: dry, wet, icy) bounds speed by the sight distance along the road and by the visibility distance; the side-friction convention bounds the speed on a curve by a lateral acceleration; a speed-proportional lateral margin bounds the speed by the room the lane leaves beside the vehicle; a minimum time headway bounds the speed by the gap to traffic ahead in the lane. Each factor's magnitude enters its bound with the speed, so the bound moves with the factor's degree."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The sight distance and the curvature \"at x's place\" are read at every lane x's footprint overlaps (rel.occupies over st.lane), the region the lane-width bound reads; where x occupies no lane, these two factors set no bound."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

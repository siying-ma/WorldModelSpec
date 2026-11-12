/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (subject): It is unlawful for any person to drive or operate
    u2 (subject): a vehicle of any kind or character
    u3 (obligation): at: A rate of speed
    u4 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    u1: atoms ['kin.speed'], derived []
    u2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u3: atoms ['kin.speed'], derived []

  How each is written:
    u2: the class of `ego` is `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
    u1, u3: ego's speed `kin_speed ego`, read in every bound of the standard (the stopping
      distance reads it through drv.motion.stopping_distance). The duty is judged at every
      observation, so the applicability is `tt`.
    u4 (surrogate standard): the stopping distance D is a `Term.cond` over three calls of
      drv_motion_stopping_distance with p.perception_reaction_time: p.stopping_decel_ice where
      env_ice_or_snow, else p.stopping_decel_wet where env_wet_road or env_precipitation, else
      p.stopping_decel_dry. D ≤ env_visibility. For every lane l ego occupies (st.lane as the
      quantifier's kind, rel_occupies ego l): D ≤ st_sight_distance l, speed² · st_curvature l ≤
      p.curve_lateral_accel, speed · p.lane_width_speed_time ≤ st_lane_width l. For every road user
      u other than ego that is ahead of ego in its lane (rel_ahead_behind_in_lane u ego): the gap
      (rel_surface_gap ego u, its distance) ≥ speed · p.perception_reaction_time.

  Choice the record left open (declared as a narrowing on u4):
    "st.sight_distance at ego's place" and "st.curvature at its place" are read at each lane ego
    occupies — the same regions the width clause selects — since both atoms are region-valued and
    the record names no other region of ego's place.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- Quantifier variables: a lane ego occupies, a road user ahead of ego. -/
def vLane : Arg := .var "l"
def vAhead : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurveLateralAccel : Term := .param "p.curve_lateral_accel"
def pLaneWidthSpeedTime : Term := .param "p.lane_width_speed_time"
def pPerceptionReactionTime : Term := .param "p.perception_reaction_time"
def pStoppingDecelDry : Term := .param "p.stopping_decel_dry"
def pStoppingDecelIce : Term := .param "p.stopping_decel_ice"
def pStoppingDecelWet : Term := .param "p.stopping_decel_wet"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: (no trigger/condition span) — the duty is judged at every observation. -/
def applicability : Formula := .tt

/-- u1, u3: ego's rate of speed. -/
def egoSpeed : Term := .measure "kin_speed" [vEgo]

/-- u4: ego's stopping distance under a deceleration. -/
def stoppingDistanceAt (decel : Term) : Term :=
  .quantity "drv_motion_stopping_distance" [vEgo] [pPerceptionReactionTime, decel]

/-- u4 (surface, weather): the deceleration selected by the road surface and the weather. -/
def stoppingDistance : Term :=
  .cond (.atom "env_ice_or_snow" [] [])
    (stoppingDistanceAt pStoppingDecelIce)
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      (stoppingDistanceAt pStoppingDecelWet)
      (stoppingDistanceAt pStoppingDecelDry))

/-- u4 (weather): the stopping distance within the visibility distance. -/
def withinVisibility : Formula :=
  .cmp stoppingDistance .le (.measure "env_visibility" [])

/-- u4 (width, other highway conditions): at every lane ego occupies, the stopping distance within
    its sight distance, the lateral acceleration of its curvature within the side-friction limit, and
    the speed fitted to its width. -/
def withinLane : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vEgo, vLane] [])
      (.and (.cmp stoppingDistance .le (.measure "st_sight_distance" [vLane]))
        (.and (.cmp (.mul (.mul egoSpeed egoSpeed) (.measure "st_curvature" [vLane])) .le pCurveLateralAccel)
          (.cmp (.mul egoSpeed pLaneWidthSpeedTime) .le (.measure "st_lane_width" [vLane])))))

/-- u4 (traffic): every road user ahead of ego in its lane at least a reaction time's travel away. -/
def gapAhead : Formula :=
  .forallUser "u"
    (.implies (.and (.not (.same vAhead vEgo)) (.atom "rel_ahead_behind_in_lane" [vAhead, vEgo] []))
      (.cmp (.measure "rel_surface_gap" [vEgo, vAhead]) .ge (.mul egoSpeed pPerceptionReactionTime)))

/-- Obligation: u3 (obligation): at: A rate of speed; u4 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .and withinVisibility (.and withinLane gapAhead)

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.motion.stopping_distance", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.curvature", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.perception_reaction_time", "p.stopping_decel_dry", "p.stopping_decel_wet", "p.stopping_decel_ice", "p.curve_lateral_accel", "p.lane_width_speed_time"]
          convention := "Stopping-sight-distance model of highway design (AASHTO Green Book), with the curve side-friction and lane-width relations of the same guides. Surface and weather select the deceleration: p.stopping_decel_ice where env.ice_or_snow holds, else p.stopping_decel_wet where env.wet_road or env.precipitation holds, else p.stopping_decel_dry (Term.cond over drv.motion.stopping_distance calls with p.perception_reaction_time). The stopping distance may not exceed the sight distance of the place (st.sight_distance) nor the visibility distance (env.visibility); for every road user ahead of ego in its lane (rel.ahead_behind_in_lane), the traffic, the gap (rel.surface_gap) may not fall below the speed times p.perception_reaction_time; the speed squared times the curvature (st.curvature) may not exceed p.curve_lateral_accel; the speed times p.lane_width_speed_time may not exceed the width (st.lane_width) of the lane ego occupies (st.lane, rel.occupies). Each measured magnitude enters its bound. The standard is the whole duty: the rule is a surrogate."
          surrogate := true } ]
    residues := []
    narrowings :=
      [ { span := "u4"
          why := "The place at which st.sight_distance and st.curvature are read is each lane ego occupies (st.lane, rel.occupies), the regions the width clause selects; no other region of ego's place is read."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    p1 (obligation): It is unlawful for any person to drive or operate
    p2 (subject): a vehicle of any kind or character
    p3 (boilerplate): at:
    p4 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    p1: atoms ['kin.speed'], derived []
    p2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  How each is written.
    p2: the binder `subject` is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    p1: the applicability is the subject moving: `kin_speed subject > p.halt_speed_tolerance`.
    p4 (surrogate operationalization): with v = kin_speed subject and a the surface's braking
      deceleration (`Term.cond`: ice where env.ice_or_snow; else wet where env.wet_road or
      env.precipitation; else dry), the stopping distance S = v·tr + v²/(2a) is never divided:
      every bound `S ≤ D` is written as `2a·v·tr + v² − 2a·D ≤ 0` (a > 0), and `2a` as `a + a`,
      so no division and no bare literal enters. The `Term.cond` selects the whole difference by
      surface, once per comparison (Core splits each `cond` of a comparison by cases, so one
      selection per comparison keeps the expansion small).
      (i)  S within env.visibility; where env.darkness, within p.low_beam_sight_reach; and, for
           every lane the subject's footprint overlaps (rel.occupies, st.lane), within that
           lane's st.sight_distance.
      (ii) for every road user u other than the subject that is ahead of it in its lane
           (rel_ahead_behind_in_lane u subject), whatever its class:
           2a·S ≤ 2a·rel.surface_gap(subject,u) + v_u².
      (iii) for every lane the subject occupies: v·v·st.curvature ≤ (ice ? p.following_decel_ice
           : p.curve_lateral_accel_max).
      (iv) for every lane the subject occupies: 2·v·err·tmin ≤ st.lane_width − width(subject)
           (kin.extent "width", the full width), the "half of" moved across as a doubling.

  Choices the record left open (declared as narrowings on p4):
    - "at the subject's place" (sight distance, curvature) is read at each lane the subject's
      footprint overlaps, every one of them (not some one).
    - the surface gap to the road user ahead is read as the distance between the nearest points
      (no component selector).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurveLateralAccelMax : Term := .param "p.curve_lateral_accel_max"
def pDriverReactionTime : Term := .param "p.driver_reaction_time"
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pLaneDepartureTimeMin : Term := .param "p.lane_departure_time_min"
def pLaneKeepingHeadingError : Term := .param "p.lane_keeping_heading_error"
def pLowBeamSightReach : Term := .param "p.low_beam_sight_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Zero in m²/s² (the unit of a stopping distance scaled by twice a deceleration). -/
def zeroSpeedSq : Term := .mul (.lit Q.zero .metrePerSecond) (.lit Q.zero .metrePerSecond)

/-- Quantifier variables. -/
def vLane : Arg := .var "l"
def vAhead : Arg := .var "u"

/-- Surface conditions. -/
def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
def wetSurface : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

/-- The subject's speed. -/
def vSpeed : Term := .measure "kin_speed" [vSubject]

/-- The braking deceleration the surface allows, as one `Term.cond` selection over the whole
    quantity `f a` that depends on it (one selection per comparison, so the case split stays small). -/
def bySurface (f : Term → Term) : Term :=
  .cond iceOrSnow (f pFollowingDecelIce) (.cond wetSurface (f pFollowingDecelWet) (f pFollowingDecelDry))

/-- 2a·S = 2a·v·tr + v², the stopping distance scaled by 2a (2a written `a + a`). -/
def scaledStopping (a : Term) : Term :=
  .add (.mul (.add a a) (.mul vSpeed pDriverReactionTime)) (.mul vSpeed vSpeed)

/-- S ≤ D, written as 2a·S − 2a·D ≤ 0 under the surface's deceleration a. -/
def stopsWithin (d : Term) : Formula :=
  .cmp (bySurface fun a => .sub (scaledStopping a) (.mul (.add a a) d)) .le zeroSpeedSq

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: the subject is moving (p1, kin.speed above the halt tolerance). -/
def applicability : Formula := .cmp vSpeed .gt pHaltSpeedTolerance

/-- (i) the distance available ahead: visibility and, in darkness, the low-beam reach. -/
def withinAir : Formula :=
  .and (stopsWithin (.measure "env_visibility" []))
    (.implies (.atom "env_darkness" [] []) (stopsWithin pLowBeamSightReach))

/-- (i), (iii), (iv) at every lane the subject's footprint overlaps. -/
def atEveryLane : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vSubject, vLane] [])
      (.and (stopsWithin (.measure "st_sight_distance" [vLane]))
        (.and
          (.cmp (.mul (.mul vSpeed vSpeed) (.measure "st_curvature" [vLane])) .le
            (.cond iceOrSnow pFollowingDecelIce pCurveLateralAccelMax))
          (.cmp
            (.add (.mul (.mul vSpeed pLaneKeepingHeadingError) pLaneDepartureTimeMin)
                  (.mul (.mul vSpeed pLaneKeepingHeadingError) pLaneDepartureTimeMin))
            .le
            (.sub (.measure "st_lane_width" [vLane]) (.measure "kin_extent" [vSubject, .lit "width"]))))))

/-- (ii) the assured clear distance to every road user ahead in the subject's lane. -/
def behindTraffic : Formula :=
  .forallUser "u"
    (.implies (.and (.not (.same vAhead vSubject)) (.atom "rel_ahead_behind_in_lane" [vAhead, vSubject] []))
      (.cmp
        (bySurface fun a =>
          .sub (scaledStopping a)
            (.add (.mul (.add a a) (.measure "rel_surface_gap" [vSubject, vAhead]))
                  (.mul (.measure "kin_speed" [vAhead]) (.measure "kin_speed" [vAhead]))))
        .le zeroSpeedSq))

/-- Obligation: p1 (obligation): It is unlawful for any person to drive or operate; p4 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula := .and withinAir (.and atEveryLane behindTraffic)

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.extent", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.curvature", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.halt_speed_tolerance", "p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice", "p.curve_lateral_accel_max", "p.lane_keeping_heading_error", "p.lane_departure_time_min", "p.low_beam_sight_reach"]
          convention := "stopping-sight-distance model (perception-reaction distance plus braking distance at the friction-limited deceleration of the surface) held within the distance available ahead: the sight distance of the place, the visibility of the air and, in darkness, the low-beam reach; for traffic, the assured-clear-distance model against the road user ahead in the lane, whose own braking distance is credited; for curves, the side-friction model (speed squared times curvature within the lateral acceleration the surface allows); for width, the time-to-line-crossing model (lateral drift at the uncorrected heading error times the speed, within the lateral margin the lane leaves the vehicle, for at least the minimum time to line crossing)"
          surrogate := true } ]
    residues := []
    narrowings :=
      [ { span := "p4"
          why := "'at the subject's place' (st.sight_distance and st.curvature) is read at every lane the subject's footprint overlaps (rel.occupies), each of them bounding the speed"
          kind := "reading" }
      , { span := "p4"
          why := "the surface gap to the road user ahead in the lane is read as the distance between the nearest points of the two bodies, not one of its components"
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

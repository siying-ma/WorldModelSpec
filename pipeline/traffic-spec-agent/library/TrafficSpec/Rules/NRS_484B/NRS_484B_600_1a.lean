/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (obligation): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    c2 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed', 'rel.occupies', 'st.highway'], derived []

  How each span is written.

    c1 (obligation), the subject and the occasion: the class of `v` is the single atom
      `ru_aggregate` with the admitted aggregate id `DEF-NRS-484A-320::vehicle` as its literal
      argument; the classes that definition covers are never written here. 'any person to drive or
      operate' is the record's observable reading through the vehicle's controlled motion, written
      as `kin_speed v > 0` (zero is the only magnitude of this file). 'of any kind or character'
      adds no class of its own. The duty binds on a public way, so the applicability also selects a
      highway region the subject occupies: `st_highway w` with `rel_occupies v w`, one region
      quantifier over the kind the element names. `st.highway` is the whole way between its
      boundary lines, not the roadway: no part of the way is named by the span.

    c2 (standard), the surrogate bound on `kin_speed v`: the operationalization's factors, each a
      separate comparison, so that the conjunction of them is the smallest of the bounds.

      Baseline, surface and weather, which select among bounds: `Term.cond` selects the scaled
      baseline where the condition holds and the bare baseline where it does not, so each of
      `env_wet_road` (p.wet_speed_factor), `env_ice_or_snow` (p.ice_speed_factor),
      `env_precipitation` (p.precipitation_speed_factor) and `env_darkness`
      (p.darkness_speed_factor) carries the baseline p.reasonable_speed_base as its false branch.

      Width: `st_lane_width l` of a lane the subject occupies, the baseline scaled by the ratio of
      that width to p.lane_width_reference.

      Weather and sight: the assured-clear-distance bound is the smaller of `env_visibility` and
      `st_sight_along_way v w` divided by p.sight_time; the smaller of two bounds is the two
      comparisons conjoined, one on each quantity.

      Traffic: `forallUser u`, the duty owed to each road user clear ahead of the subject in its
      own lane — one other than the subject itself (`same`), standing in
      `rel_ahead_behind_in_lane` with it (written with `u` first, since that atom reads 'a ahead of
      b in the same lane' and the record reads the direction separately), whose `rel_bearing` in
      the subject's frame is `ahead` (positive along the subject's heading), and whose longitudinal
      `rel_surface_gap` to the subject is strictly above zero. For such a road user the speed does
      not exceed that gap divided by p.traffic_headway_time. A road user abeam of the subject, one
      behind it and one whose body overlaps the subject's along the lane axis leave the antecedent
      false and bound the speed not at all.

      Other highway conditions: the curve bound is written as a product —
      `kin_speed v · kin_speed v · st_curvature d ≤ p.lateral_accel_max` — because the way runs
      straight where `st_curvature` is zero and a division by it would report unknown instead of a
      verdict; the product says the same thing wherever the quotient is defined. The grade bound is
      the baseline less the baseline times the downgrade times p.grade_speed_sensitivity.

      Regions: the lane whose width is read, the roadway whose curvature and grade are read and the
      way along which sight is read are each selected again in the obligation by the whole
      selection — the kind atom (`st_lane`, `st_roadway`, `st_highway`) and `rel_occupies` of the
      subject — and the duty is stated at every region so selected.

  Narrowings declared below, both on c2, the standard's span:
    - the downgrade: `st.grade` is signed, and the convention names only the descent, so the
      downgrade is the negative of the grade where the grade is below zero and zero elsewhere; an
      ascent therefore leaves the baseline untouched rather than raising it.
    - the regional factors are stated at every region of the named kind the subject occupies, so
      where it occupies more than one lane or roadway the lowest of those bounds governs; the
      convention names 'the lane the subject occupies' and 'the roadway' in the singular.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDarknessSpeedFactor : Term := .param "p.darkness_speed_factor"
def pGradeSpeedSensitivity : Term := .param "p.grade_speed_sensitivity"
def pIceSpeedFactor : Term := .param "p.ice_speed_factor"
def pLaneWidthReference : Term := .param "p.lane_width_reference"
def pLateralAccelMax : Term := .param "p.lateral_accel_max"
def pPrecipitationSpeedFactor : Term := .param "p.precipitation_speed_factor"
def pReasonableSpeedBase : Term := .param "p.reasonable_speed_base"
def pSightTime : Term := .param "p.sight_time"
def pTrafficHeadwayTime : Term := .param "p.traffic_headway_time"
def pWetSpeedFactor : Term := .param "p.wet_speed_factor"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond
def zeroRatio : Term := .lit Q.zero .ratio

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula :=
  .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- c1/c2: the quantity the standard bounds. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- c1: the vehicle is in controlled motion. -/
def inMotion : Formula := .cmp speedV .gt zeroSpeed

/-- c1: `w` is a highway the subject occupies (the whole way between its boundary lines). -/
def onWay (w : String) : Formula :=
  .and (.atom "st_highway" [.var w] [])
       (.atom "rel_occupies" [vV, .var w] [])

/-- Applicability: c1 — a vehicle in controlled motion on a highway. -/
def applicability : Formula :=
  .and inMotion (.existsRegion (.lit "highway") "w" (onWay "w"))

/-- c2: the baseline, scaled by `factor` where `φ` holds and bare where it does not. -/
def baseUnder (φ : Formula) (factor : Term) : Term :=
  .cond φ (.mul pReasonableSpeedBase factor) pReasonableSpeedBase

/-- c2 (surface): a wet surface leaves p.wet_speed_factor of the baseline. -/
def wetBound : Formula :=
  .cmp speedV .le (baseUnder (.atom "env_wet_road" [] []) pWetSpeedFactor)

/-- c2 (surface): an icy or snow-covered surface leaves p.ice_speed_factor of the baseline. -/
def iceBound : Formula :=
  .cmp speedV .le (baseUnder (.atom "env_ice_or_snow" [] []) pIceSpeedFactor)

/-- c2 (the weather): falling precipitation leaves p.precipitation_speed_factor of the baseline. -/
def precipitationBound : Formula :=
  .cmp speedV .le (baseUnder (.atom "env_precipitation" [] []) pPrecipitationSpeedFactor)

/-- c2 (other highway conditions): darkness leaves p.darkness_speed_factor of the baseline. -/
def darknessBound : Formula :=
  .cmp speedV .le (baseUnder (.atom "env_darkness" [] []) pDarknessSpeedFactor)

/-- c2 (the weather): the assured clear distance within the visibility. -/
def visibilityBound : Formula :=
  .cmp speedV .le (.div (.measure "env_visibility" []) pSightTime)

/-- c2 (other highway conditions): the assured clear distance along the way `w`. -/
def sightBoundAt (w : String) : Formula :=
  .cmp speedV .le (.div (.measure "st_sight_along_way" [vV, .var w]) pSightTime)

/-- c2 (width of the highway): the width of the lane `l` the subject occupies, against the
    reference lane width. -/
def widthBoundAt (l : String) : Formula :=
  .cmp speedV .le
    (.mul pReasonableSpeedBase (.div (.measure "st_lane_width" [.var l]) pLaneWidthReference))

/-- c2 (other highway conditions): the square of the speed times the curvature of the roadway `d`
    does not exceed the lateral acceleration (a product, since a straight way has zero curvature). -/
def curveBoundAt (d : String) : Formula :=
  .cmp (.mul (.mul speedV speedV) (.measure "st_curvature" [.var d])) .le pLateralAccelMax

/-- c2: the downgrade at the subject's place: the grade of `d` negated where it descends, zero
    where it is level or ascends. -/
def downgradeAt (d : String) : Term :=
  .cond (.cmp (.measure "st_grade" [.var d]) .lt zeroRatio)
    (.neg (.measure "st_grade" [.var d])) zeroRatio

/-- c2 (other highway conditions): the baseline less the downgrade's share of it. -/
def gradeBoundAt (d : String) : Formula :=
  .cmp speedV .le
    (.sub pReasonableSpeedBase
      (.mul (.mul pReasonableSpeedBase (downgradeAt d)) pGradeSpeedSensitivity))

/-- c2 (the traffic): `u` is a road user clear ahead of the subject in its own lane. -/
def clearAhead (u : String) : Formula :=
  .and (.not (.same (.var u) vV))
    (.and (.atom "rel_ahead_behind_in_lane" [.var u, vV] [])
      (.and (.atom "rel_bearing" [vV, .var u, .lit "ahead"] [])
            (.cmp (.measure "rel_surface_gap" [vV, .var u, .lit "longitudinal"]) .gt zeroMetres)))

/-- c2 (the traffic): the headway owed to each road user clear ahead in the subject's own lane. -/
def headwayDuty : Formula :=
  .forallUser "u"
    (.implies (clearAhead "u")
      (.cmp speedV .le
        (.div (.measure "rel_surface_gap" [vV, .var "u", .lit "longitudinal"])
              pTrafficHeadwayTime)))

/-- c2: `l` is a lane the subject occupies. -/
def occupiedLane (l : String) : Formula :=
  .and (.atom "st_lane" [.var l] [])
       (.atom "rel_occupies" [vV, .var l] [])

/-- c2: `d` is a roadway the subject occupies. -/
def occupiedRoadway (d : String) : Formula :=
  .and (.atom "st_roadway" [.var d] [])
       (.atom "rel_occupies" [vV, .var d] [])

/-- c2: the factors that read no region: the surface, the weather, the light and the sight. -/
def conditionBounds : Formula :=
  .and wetBound
    (.and iceBound
      (.and precipitationBound
        (.and darknessBound visibilityBound)))

/-- c2: the factors read at a region the subject occupies. -/
def regionBounds : Formula :=
  .and (.forallRegion (.lit "lane") "l" (.implies (occupiedLane "l") (widthBoundAt "l")))
    (.and (.forallRegion (.lit "roadway") "d"
            (.implies (occupiedRoadway "d") (.and (curveBoundAt "d") (gradeBoundAt "d"))))
          (.forallRegion (.lit "highway") "w" (.implies (onWay "w") (sightBoundAt "w"))))

/-- Obligation: c1 (obligation): It is unlawful for any person to drive or operate a vehicle of any kind or character at:; c2 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .and conditionBounds (.and headwayDuty regionBounds)

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.ahead_behind_in_lane", "rel.bearing", "rel.occupies", "rel.surface_gap", "st.curvature", "st.grade", "st.highway", "st.lane", "st.lane_width", "st.roadway", "st.sight_along_way"]
          params := ["p.reasonable_speed_base", "p.lane_width_reference", "p.lateral_accel_max", "p.sight_time", "p.traffic_headway_time", "p.wet_speed_factor", "p.ice_speed_factor", "p.precipitation_speed_factor", "p.darkness_speed_factor", "p.grade_speed_sensitivity"]
          convention := "A bound on `kin.speed` built factor by factor from engineering conventions, each factor of the standard read by the degree to which it holds, the smallest of the bounds governing. The defined term 'the traffic' (the admitted aggregate DEF-NRS-484A-285::traffic) is read through the road users wholly ahead of the subject in its own lane, every member of that aggregate being capable of being such a road user, so the bound reads the factor without a membership test. Baseline: p.reasonable_speed_base, the design-speed convention for a dry, clear, straight way of full lane width free of other traffic. Width (st.lane_width, the width of the lane the subject occupies): the baseline scaled by the ratio of that width to p.lane_width_reference, a lane-width convention, so the bound falls as the lane narrows. Traffic: a headway convention, which measures the clear length of lane ahead in which the subject must be able to come to rest, so it reads only a road user that is clear ahead of the subject - one other than the subject itself, standing in rel.ahead_behind_in_lane with it (an atom whose contract covers ahead and behind alike, so the direction is read separately), whose rel.bearing in the subject's frame is positive along the subject's heading, and whose longitudinal component of rel.surface_gap to the subject is strictly greater than zero. For such a road user the bound is that gap divided by p.traffic_headway_time, so the bound falls as the gap closes; a road user abeam of the subject, one behind it, and one whose body overlaps the subject's along the lane axis (a gap of zero or less) leave no clear length to measure and bound the speed not at all. Weather and sight: the smaller of env.visibility and st.sight_along_way divided by p.sight_time, an assured-clear-distance convention, so the bound falls as what can be seen shortens; falling precipitation selects the baseline scaled by p.precipitation_speed_factor and env.darkness selects a scaling by p.darkness_speed_factor. Surface: env.wet_road selects a scaling by p.wet_speed_factor and env.ice_or_snow by p.ice_speed_factor, a pavement-friction convention. Other highway conditions: a curve-speed convention bounds the square of the speed by p.lateral_accel_max divided by st.curvature, so the bound falls as the bend tightens, and a grade convention scales the bound by the downgrade at the subject's place times p.grade_speed_sensitivity, so the bound falls as the descent steepens."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "c2"
          why := "'the downgrade at the subject's place' is written as the negative of `st.grade` where that grade is below zero and as zero where the way is level or ascends, the bound being the baseline less that downgrade times p.grade_speed_sensitivity. The convention names only the descent and the atom's value is signed, so an ascent leaves the baseline untouched rather than raising the bound; how much an ascent would permit the words do not say."
          kind := "reading" }
      , { span := "c2"
          why := "each factor read at a region - the lane whose width is read, the roadway whose curvature and grade are read, the way along which sight is read - is stated at every region of that kind the subject occupies, so where its footprint occupies more than one lane or more than one roadway the lowest of those bounds governs. The convention names 'the lane the subject occupies' and 'the roadway' in the singular and does not say which bound governs where the subject straddles two."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

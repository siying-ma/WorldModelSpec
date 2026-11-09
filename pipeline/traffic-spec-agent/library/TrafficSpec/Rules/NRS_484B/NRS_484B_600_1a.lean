/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (obligation): A rate of speed greater than
    s3 (standard): is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.standstill']
    s2: atoms ['kin.speed'], derived []

  How each span is written.

  s1 — the class of the binder `v` is the aggregate atom `ru_aggregate v "DEF-NRS-484A-320::vehicle"`,
  the admitted aggregate the table resolves 'a vehicle of any kind or character' to; the id is
  written, never the classes the reading files under it. 'to drive or operate' is the record's
  observable reading through the vehicle's controlled motion: the applicability is
  `not drv.motion.standstill(v, p.standstill_speed_tolerance)` — a vehicle whose speed exceeds the
  standstill tolerance is taken to be driven, whoever or whatever is at the controls. That reading
  is the plan's narrowing (`observable_reading` on s1) and is not restated below.

  s2 — 'a rate of speed' is `kin.speed` of `v`; 'greater than' is the comparison of that magnitude
  with the bound s3 sets, written as `speed ≤ bound` for the duty (its negation is the offence).

  s3 — the operationalization's convention, as the record states it, with the subject's place read
  through the regions it occupies:
    * one highway region `h` the subject occupies ('the highway' of the standard);
    * the roadway region `r` the subject occupies that lies on `h` (`st.on_way`): the subject's
      place, whose longitudinal slope (`st.grade`) and sight distance (`st.sight_distance`) the
      standard's 'other highway conditions' are read through;
    * the lane region `l` the subject occupies that lies on `h`, whose `st.lane_width` is the
      'width of the highway' the record narrows to the lane the vehicle runs in.
  The bound is `p.reasonable_speed_base_limit` lowered by `p.reasonable_speed_wet_decrement` where
  `env.wet_road` or `env.precipitation` holds, by `p.reasonable_speed_ice_decrement` where
  `env.ice_or_snow` holds, by `p.reasonable_speed_traffic_decrement_per_user` for each road user of
  the scene whose footprint lies on `h` ('the traffic'), and by
  `p.reasonable_speed_grade_decrement_per_unit_grade` times the magnitude of `st.grade` at `r`. The
  speed is bounded in addition by the lane's width over `p.reasonable_speed_lane_width_time`, by the
  place's sight distance over `p.reasonable_speed_sight_time` and by `env.visibility` over the same
  time. Each of these three is written as a bound on a product (speed times the time at most the
  distance), the form the language requires of a ratio whose divisor could be zero, and the form
  that reads the same sense as the convention's division.

  Readings chosen here on s3, declared as narrowings below:
    * 'the surface and width of the highway … and other highway conditions' are read at the regions
      the subject occupies: the slope and the sight distance at the roadway region it occupies and
      lies on the way, the width at the lane region it occupies and lies on the way. The record
      names `st.roadway`, `st.lane`, `st.highway` and `st.on_way` without saying which region
      carries which figure; this is the assignment chosen.
    * 'the highway' and 'the lane' are definite in the words, so where several occupied regions of a
      kind qualify the duty is written for every one of them (a universal over the selected
      regions), not for one of them.
  The count of 'the traffic' is every road user of the scene whose footprint lies on `h`, the
  subject included, which is the record's wording ('each road user of the scene whose footprint
  overlaps the st.highway region v occupies') read as it stands.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The regions and the road users the obligation quantifies over. -/
def hH : Arg := .var "h"
def rR : Arg := .var "r"
def lL : Arg := .var "l"
def uU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pReasonableSpeedBaseLimit : Term := .param "p.reasonable_speed_base_limit"
def pReasonableSpeedGradeDecrementPerUnitGrade : Term := .param "p.reasonable_speed_grade_decrement_per_unit_grade"
def pReasonableSpeedIceDecrement : Term := .param "p.reasonable_speed_ice_decrement"
def pReasonableSpeedLaneWidthTime : Term := .param "p.reasonable_speed_lane_width_time"
def pReasonableSpeedSightTime : Term := .param "p.reasonable_speed_sight_time"
def pReasonableSpeedTrafficDecrementPerUser : Term := .param "p.reasonable_speed_traffic_decrement_per_user"
def pReasonableSpeedWetDecrement : Term := .param "p.reasonable_speed_wet_decrement"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
/-- No decrement: the zero of a speed. -/
def zeroSpeed : Term := .lit Q.zero .metrePerSecond
/-- No road user: the zero of a count. -/
def zeroCount : Term := .lit Q.zero .count

/-- s2: the subject's rate of speed. -/
def speedOfV : Term := .measure "kin_speed" [vV]

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1, read through the vehicle's controlled motion — the subject is in motion at
    the observation, so it is driven or operated. -/
def applicability : Formula :=
  .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- s3 'the traffic': the road users of the scene whose footprint lies on the highway `h`. -/
def trafficOnWay : Term :=
  .aggregate .count "u" (.atom "rel_occupies" [uU, hH] []) zeroCount

/-- s3 'surface … the weather': the wet-pavement decrement where the surface is wet or
    precipitation falls, nothing where neither holds. -/
def surfaceDecrement : Term :=
  .cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
    pReasonableSpeedWetDecrement zeroSpeed

/-- s3 'surface … the weather': the winter-surface decrement where the surface is icy or
    snow-covered. -/
def winterDecrement : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pReasonableSpeedIceDecrement zeroSpeed

/-- s3 'the traffic': the per-user decrement for each road user on the way. -/
def trafficDecrement : Term :=
  .mul pReasonableSpeedTrafficDecrementPerUser trafficOnWay

/-- s3 'other highway conditions': the grade correction at the subject's place. -/
def gradeDecrement : Term :=
  .mul pReasonableSpeedGradeDecrementPerUnitGrade (.abs (.measure "st_grade" [rR]))

/-- s3: the base design speed lowered by surface, weather, stream and slope. -/
def reasonableSpeedBound : Term :=
  .sub (.sub (.sub (.sub pReasonableSpeedBaseLimit surfaceDecrement) winterDecrement)
      trafficDecrement)
    gradeDecrement

/-- s2 with s3: the speed does not exceed the lowered design speed. -/
def withinLoweredLimit : Formula := .cmp speedOfV .le reasonableSpeedBound

/-- s3 'width of the highway': the speed times the lateral-recovery time is at most the width of
    the lane the subject runs in. -/
def withinLaneWidthBound : Formula :=
  .cmp (.mul speedOfV pReasonableSpeedLaneWidthTime) .le (.measure "st_lane_width" [lL])

/-- s3 'other highway conditions': the speed times the stopping time is at most the sight distance
    of the subject's place. -/
def withinSightDistanceBound : Formula :=
  .cmp (.mul speedOfV pReasonableSpeedSightTime) .le (.measure "st_sight_distance" [rR])

/-- s3 'the weather': the speed times the stopping time is at most the visibility distance. -/
def withinVisibilityBound : Formula :=
  .cmp (.mul speedOfV pReasonableSpeedSightTime) .le (.measure "env_visibility" [])

/-- s3: the whole reasonable-speed bound at the subject's place. -/
def withinReasonableSpeed : Formula :=
  .and (.and withinLoweredLimit withinLaneWidthBound)
    (.and withinSightDistanceBound withinVisibilityBound)

/-- Obligation: s2 (obligation): A rate of speed greater than; s3 (standard): is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vV, hH] [])
      (.forallRegion (.lit "roadway") "r"
        (.implies (.and (.atom "rel_occupies" [vV, rR] []) (.atom "st_on_way" [rR, hH] []))
          (.forallRegion (.lit "lane") "l"
            (.implies (.and (.atom "rel_occupies" [vV, lL] []) (.atom "st_on_way" [lL, hH] []))
              withinReasonableSpeed)))))

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
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.occupies", "st.grade", "st.highway", "st.lane", "st.lane_width", "st.on_way", "st.roadway", "st.sight_distance"]
          params := ["p.reasonable_speed_base_limit", "p.reasonable_speed_wet_decrement", "p.reasonable_speed_ice_decrement", "p.reasonable_speed_traffic_decrement_per_user", "p.reasonable_speed_grade_decrement_per_unit_grade", "p.reasonable_speed_lane_width_time", "p.reasonable_speed_sight_time"]
          convention := "A stopping-sight-distance and surface-friction reading of a reasonable speed. A base design speed stands for a dry, wide, level and unobstructed stretch; it is lowered by the wet-pavement decrement where the surface is wet or precipitation falls and by the larger winter-surface decrement where the surface is icy or snow-covered; by the per-user traffic decrement for each road user of the scene whose footprint lies on the highway the subject occupies, so the bound falls as the stream thickens; and by the grade decrement times the magnitude of the longitudinal slope at the subject's place, the braking-distance model's grade correction. The speed is bounded in addition by the shortest available sight: the sight distance of the subject's place and the visibility distance, each divided by the perception-reaction-plus-braking time of the stopping-distance model, and by the width of the lane the subject occupies divided by the lateral-recovery time of the lane-keeping convention, so that a narrower lane bounds the speed in proportion to its width. Values come from the AASHTO Green Book's design-speed, stopping-sight-distance and grade-correction tables and from the wet- and winter-surface practice of the same standard."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The standard's conditions are read at the regions the subject occupies and that lie on the highway it occupies: the longitudinal slope (st.grade) and the sight distance (st.sight_distance) at the roadway region, read as 'the subject's place', and the width (st.lane_width) at the lane region, read as the 'width of the highway' the record narrows to the lane the vehicle runs in. The record names st.highway, st.roadway, st.lane and st.on_way without saying which region carries which figure; this is the assignment chosen."
          kind := "reading" }
      , { span := "s3"
          why := "'the highway' and 'the lane' are definite in the words; where more than one occupied region of a kind qualifies, the bound is required at every one of them (a universal over the selected regions) rather than at one of them, which is the stricter of the readings the words allow."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

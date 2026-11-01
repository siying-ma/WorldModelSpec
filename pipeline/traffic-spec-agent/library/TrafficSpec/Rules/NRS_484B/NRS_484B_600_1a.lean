/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (obligation): A rate of speed
    s3 (standard): greater than is reasonable or proper, having due regard for
    s4 (definitional): the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['ru.subject', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['kin.speed'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'rel.centre_distance', 'st.highway', 'st.lane', 'st.lane_width', 'st.roadway', 'st.curvature', 'st.sight_along_way', 'env.wet_road', 'env.ice_or_snow', 'env.precipitation', 'env.visibility', 'env.darkness'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
  The text states no figure, so the only literals here are zero (the nil reduction a condition that
  does not hold contributes, and the nil quantity the count aggregate carries).

  How each span is written.

    s1 — the subject. Both of its atoms are the binder's class: `ru_subject veh` (the road user
    whose conduct the rule judges) and `ru_aggregate veh "DEF-NRS-484A-320::vehicle"` (membership
    of the admitted aggregate, written with the aggregate's id and never with the classes the
    reading puts under it). The record's own narrowing on this span — 'any person to drive or
    operate' read through the vehicle's controlled motion, an observable_reading of category
    agency — is the plan's and is not restated in `narrowings`; the element claims no motion atom,
    so the span is written from its two class atoms alone. The clause states no place, time or
    condition of its own, so the applicability is `.tt`: the prohibition engages at every
    observation of such a vehicle, on or off a marked lane or roadway, moving or at a halt.

    s2 — the quantity bounded: `kin_speed veh`, the subject's own speed, the magnitude of its
    velocity. It is read of the subject at the judged observation and compared with each of the
    three bounds of the standard; no actuation, no acceleration and no posted figure enters.

    s3 / s4 — the standard and the factors it has due regard for. The node is a surrogate: the
    standard is the whole duty, and the operationalization's three bounds, each computed from
    magnitudes the atoms of s4 observe, together are the obligation. Each bound is written as the
    convention states it, and in particular each is stated once with the scene-level or default
    value, which always applies, and once at every region of its kind the subject's footprint
    overlaps (`rel_occupies`), so that the least favourable region the subject occupies governs and
    a subject occupying no region of a kind is judged by the factors that remain:

      (1) The condition bound. `conditionBound` conjoins the comparison at the default width
      factor — the base speed itself, which is the bound where the subject overlaps no lane — with
      the comparison at every `st.lane` the subject occupies, whose scaled base is
      `p.reasonable_speed_base · st_lane_width(L) / p.reasonable_speed_reference_lane_width`,
      capped at the base by the `.cond` on `st_lane_width(L) ≤ p.reasonable_speed_reference_lane_width`
      (the ratio capped at one: a wider lane does not raise the bound). The divisor is the
      reference-width parameter, never a measured quantity. From that scaled base
      `rawBound` subtracts `p.reasonable_speed_wet_reduction` where `env_wet_road` or
      `env_precipitation` holds, `p.reasonable_speed_ice_reduction` where `env_ice_or_snow` holds,
      `p.reasonable_speed_darkness_reduction` where `env_darkness` holds — each as a `.cond`
      selecting the parameter or nil, the boolean atoms carrying no magnitude — and
      `p.reasonable_speed_per_road_user` times the traffic count. `flooredBound` is the greater of
      that raw bound and `p.reasonable_speed_floor`, written as the `.cond` on
      `rawBound ≥ p.reasonable_speed_floor`.

      The traffic count is `trafficCount`, the `count` aggregate over the scene's road users of
      those which are not the subject (`.not (.same other veh)` — the subject is not counted among
      the traffic it must have regard for), which carry a class the reading includes in
      `DEF-NRS-484A-285::traffic` (`ru_aggregate other "DEF-NRS-484A-285::traffic"`), whose
      footprint overlaps some `st.highway` the subject also overlaps (the highway quantified inside
      the count, so that a subject overlapping no highway reads a nil count rather than no bound),
      and whose `rel_centre_distance` to the subject is at most `p.reasonable_speed_traffic_reach`.

      (2) The sight bound. `stoppingDistance` is the ground covered at the observed speed during
      `p.reasonable_speed_reaction_time` plus the braking distance at
      `p.reasonable_speed_deceleration`, the stopping-distance model's `v·t + v²/(2a)`, the
      doubled deceleration written as `a + a` so that no figure of this file's own appears and the
      divisor reads parameters only. It must not exceed `env_visibility`, which is read of every
      subject wherever it stands, and must not exceed `st_sight_along_way(veh, W)` at every
      `st.highway` W the subject occupies, so the shortest of the air's clarity and the views along
      the ways under the subject governs. No floor is needed: from rest the distance is nil.

      (3) The curve bound. At every `st.roadway` R the subject occupies, the lateral acceleration
      the observed speed develops on `st_curvature(R)` — `v²·κ`, written as a product, never a
      ratio, since a curvature is a measured quantity and is nil where the way runs straight —
      must not exceed `p.reasonable_speed_lateral_acceleration`. No floor is needed: from rest the
      lateral acceleration is nil.

    The duty is the conjunction of the three: a speed that exceeds any one of them is not
    reasonable or proper. Every comparison is `≤`, since the text forbids a rate *greater than*
    what is reasonable: a speed equal to a bound complies.

  Choices and `narrowings`. Every reading this file rests on — the crawl-speed floor, the traffic
  read as a count within reach, the surface read through the two surface atoms, the width read
  through the lane widths under the subject, the weather read through precipitation and visibility,
  the catch-all read through curvature, darkness and the view along the way, and the view bounding
  the stopping distance twice over — is the record's own narrowing on s3, already on the plan's
  record, and is therefore not restated in `narrowings`. This session chose nothing the record's
  words left open: the bounds, their factors, their order and their capping are the
  operationalization's convention, and the applicability, the binder's class and the comparison
  sense follow the record's `applicability` and `obligation` verbatim. `narrowings` is accordingly
  empty.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vVeh : Arg := .var "veh"

/-- The quantifier variables: a lane, a highway and a roadway under the subject, and another road
    user of the traffic. -/
def vLane : Arg := .var "lane"
def vWay : Arg := .var "way"
def vRoadway : Arg := .var "roadway"
def vOther : Arg := .var "other"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pReasonableSpeedBase : Term := .param "p.reasonable_speed_base"
def pReasonableSpeedDarknessReduction : Term := .param "p.reasonable_speed_darkness_reduction"
def pReasonableSpeedDeceleration : Term := .param "p.reasonable_speed_deceleration"
def pReasonableSpeedFloor : Term := .param "p.reasonable_speed_floor"
def pReasonableSpeedIceReduction : Term := .param "p.reasonable_speed_ice_reduction"
def pReasonableSpeedLateralAcceleration : Term := .param "p.reasonable_speed_lateral_acceleration"
def pReasonableSpeedPerRoadUser : Term := .param "p.reasonable_speed_per_road_user"
def pReasonableSpeedReactionTime : Term := .param "p.reasonable_speed_reaction_time"
def pReasonableSpeedReferenceLaneWidth : Term := .param "p.reasonable_speed_reference_lane_width"
def pReasonableSpeedTrafficReach : Term := .param "p.reasonable_speed_traffic_reach"
def pReasonableSpeedWetReduction : Term := .param "p.reasonable_speed_wet_reduction"

/-- The nil reduction a condition that does not hold contributes. -/
def zeroSpeed : Term := .lit Q.zero .metrePerSecond
/-- The nil quantity the count aggregate carries; a count reads no summand. -/
def zeroCount : Term := .lit Q.zero .count

/-- s2: the rate of speed the clause bounds. -/
def speedVeh : Term := .measure "kin_speed" [vVeh]

/-- Class of `veh`: ru.subject, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsVeh : Formula :=
  .and (.atom "ru_subject" [vVeh] [])
       (.atom "ru_aggregate" [vVeh, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: (no trigger/condition span) — the clause states no place, time or condition, so
    the prohibition engages at every observation of such a vehicle. -/
def applicability : Formula := .tt

-- -------------------------------------------------------------------------------------------
-- (1) The condition bound: the base reasonable speed, scaled by the width and reduced by the
-- surface, the weather, the light and the stream, floored at the crawl speed.
-- -------------------------------------------------------------------------------------------

/-- The width of a lane under the subject. -/
def laneWidth (l : Arg) : Term := .measure "st_lane_width" [l]

/-- The base speed scaled by the ratio of a lane's width to the standard lane width, the ratio
    capped at one: a narrower lane lowers the bound in proportion, a wider one does not raise it. -/
def widthScaledBase (l : Arg) : Term :=
  .cond (.cmp (laneWidth l) .le pReasonableSpeedReferenceLaneWidth)
        (.div (.mul pReasonableSpeedBase (laneWidth l)) pReasonableSpeedReferenceLaneWidth)
        pReasonableSpeedBase

/-- The wet-pavement reduction: taken where the surface is wet or rain or snow is falling. -/
def wetReduction : Term :=
  .cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
        pReasonableSpeedWetReduction zeroSpeed

/-- The winter-surface reduction: taken where the surface is icy or snow-covered. -/
def iceReduction : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pReasonableSpeedIceReduction zeroSpeed

/-- The night-driving reduction: taken where there is insufficient natural light. -/
def darknessReduction : Term :=
  .cond (.atom "env_darkness" [] []) pReasonableSpeedDarknessReduction zeroSpeed

/-- Another road user of the traffic within reach of the subject on a way the subject is on: not
    the subject itself, a class the reading includes in DEF-NRS-484A-285::traffic, a footprint
    overlapping some highway the subject's footprint also overlaps, and a centre distance to the
    subject within the interaction reach. -/
def trafficWithinReach : Formula :=
  .and (.not (.same vOther vVeh))
    (.and (.atom "ru_aggregate" [vOther, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.existsRegion (.lit "highway") "way"
               (.and (.atom "rel_occupies" [vVeh, vWay] [])
                     (.atom "rel_occupies" [vOther, vWay] [])))
            (.cmp (.measure "rel_centre_distance" [vVeh, vOther]) .le
                  pReasonableSpeedTrafficReach)))

/-- How many road users of the traffic are within reach: nil where the subject overlaps no highway
    and where it is alone on the way. -/
def trafficCount : Term := .aggregate .count "other" trafficWithinReach zeroCount

/-- The speed-flow reduction: taken for each further road user of the traffic within reach. -/
def trafficReduction : Term := .mul pReasonableSpeedPerRoadUser trafficCount

/-- The raw condition bound: a width-scaled base less the surface, weather, light and stream
    reductions. -/
def rawBound (b : Term) : Term :=
  .sub (.sub (.sub (.sub b wetReduction) iceReduction) darknessReduction) trafficReduction

/-- The condition bound the duty uses: the greater of the raw bound and the crawl-speed floor. -/
def flooredBound (b : Term) : Term :=
  .cond (.cmp (rawBound b) .ge pReasonableSpeedFloor) (rawBound b) pReasonableSpeedFloor

/-- The observed speed is within the condition bound computed from a width-scaled base. -/
def speedWithin (b : Term) : Formula := .cmp speedVeh .le (flooredBound b)

/-- The condition bound: at the default width factor, which always applies, and at the width of
    every lane the subject occupies, so the narrowest lane under the subject governs. -/
def conditionBound : Formula :=
  .and (speedWithin pReasonableSpeedBase)
       (.forallRegion (.lit "lane") "lane"
          (.implies (.atom "rel_occupies" [vVeh, vLane] [])
                    (speedWithin (widthScaledBase vLane))))

-- -------------------------------------------------------------------------------------------
-- (2) The sight bound: the distance needed to stop fits within what can be seen.
-- -------------------------------------------------------------------------------------------

/-- The stopping-distance model: the ground covered at the observed speed during the
    perception-reaction time, plus the braking distance at the comfortable deceleration. The
    doubled deceleration is written as the parameter added to itself; the divisor reads parameters
    only, never a measurement. -/
def stoppingDistance : Term :=
  .add (.mul speedVeh pReasonableSpeedReactionTime)
       (.div (.mul speedVeh speedVeh)
             (.add pReasonableSpeedDeceleration pReasonableSpeedDeceleration))

/-- The sight bound: the stopping distance fits within the air's clarity, which always applies, and
    within the view along every highway the subject occupies, so the shortest governs. -/
def sightBound : Formula :=
  .and (.cmp stoppingDistance .le (.measure "env_visibility" []))
       (.forallRegion (.lit "highway") "way"
          (.implies (.atom "rel_occupies" [vVeh, vWay] [])
                    (.cmp stoppingDistance .le (.measure "st_sight_along_way" [vVeh, vWay]))))

-- -------------------------------------------------------------------------------------------
-- (3) The curve bound: the lateral acceleration the speed develops on the bend under the subject.
-- -------------------------------------------------------------------------------------------

/-- The curve bound: at every roadway the subject occupies, the lateral acceleration the observed
    speed develops on that roadway's curvature stays within the side-friction bound. Written as a
    product: a curvature is measured and is nil where the way runs straight. -/
def curveBound : Formula :=
  .forallRegion (.lit "roadway") "roadway"
    (.implies (.atom "rel_occupies" [vVeh, vRoadway] [])
              (.cmp (.mul (.mul speedVeh speedVeh) (.measure "st_curvature" [vRoadway])) .le
                    pReasonableSpeedLateralAcceleration))

/-- Obligation: s2 (obligation): A rate of speed; s3 (standard): greater than is reasonable or proper, having due regard for -/
def obligation : Formula :=
  .and conditionBound (.and sightBound curveBound)

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "veh", cls := clsVeh } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.centre_distance", "rel.occupies", "st.curvature", "st.highway", "st.lane", "st.lane_width", "st.roadway", "st.sight_along_way"]
          params := ["p.reasonable_speed_base", "p.reasonable_speed_reference_lane_width", "p.reasonable_speed_wet_reduction", "p.reasonable_speed_ice_reduction", "p.reasonable_speed_darkness_reduction", "p.reasonable_speed_per_road_user", "p.reasonable_speed_traffic_reach", "p.reasonable_speed_floor", "p.reasonable_speed_reaction_time", "p.reasonable_speed_deceleration", "p.reasonable_speed_lateral_acceleration"]
          convention := "Three bounds of the engineering literature, each computed from magnitudes the atoms observe, together bound the standard; since the standard is the whole duty the node is a surrogate. Every bound is written so that no occupancy gates the duty: each is stated once with the scene-level or default value, which always applies, and once at every region of its kind the subject's footprint overlaps (rel.occupies), which applies in addition, so that the least favourable region the subject occupies governs and a vehicle on a shoulder, in an alley or on a surface the map carries no lane or roadway for is judged by the factors that remain rather than condemned or left unjudged for occupying none. (1) A speed-flow and road-condition bound, from the basic-speed-rule convention. The raw bound is the base reasonable speed of a dry, clear, wide, straight and uncongested highway (p.reasonable_speed_base), scaled by the ratio of a lane width to the standard lane width of geometric design (p.reasonable_speed_reference_lane_width), the ratio capped at one, and then reduced by p.reasonable_speed_wet_reduction where env.wet_road or env.precipitation holds, by p.reasonable_speed_ice_reduction where env.ice_or_snow holds, by p.reasonable_speed_darkness_reduction where env.darkness holds, and by p.reasonable_speed_per_road_user for each road user other than the subject carrying a class the reading includes in DEF-NRS-484A-285::traffic whose footprint overlaps some st.highway the subject also occupies and whose rel.centre_distance to the subject is at most p.reasonable_speed_traffic_reach — the highway being quantified inside the count, so that a subject overlapping no highway reads a nil traffic term rather than no bound. The bound the duty uses is the greater of that raw bound and p.reasonable_speed_floor: no rate of speed at or below the slowest speed the jurisdiction's own speed law posts is greater than is reasonable or proper, whatever the surface, the weather, the light, the width and the stream, so the summed reductions never fall to or below nothing and never condemn a vehicle standing still or creeping. The observed kin.speed must not exceed that bound computed with the ratio at one (the width factor where the subject overlaps no lane), and must not exceed it computed with the st.lane_width of each st.lane the subject occupies, so the narrowest lane under the subject governs and a wide way laid out in narrow lanes reads as narrow. Each factor moves the bound by the degree to which it holds: the measured lane width and the count of the traffic enter the bound itself, so the bound falls as the way narrows and as the stream thickens, and the surface and light conditions, which the ontology carries as boolean atoms with no magnitude, select among bounds. (2) The stopping-distance model of geometric design: the distance covered at the observed kin.speed during p.reasonable_speed_reaction_time plus the braking distance at p.reasonable_speed_deceleration must not exceed env.visibility, and must not exceed the st.sight_along_way of each st.highway the subject occupies, so the shortest of the air's clarity and the views along the ways under the subject governs, and a subject on no mapped way is still bounded by the air. This bound needs no floor: at a standstill the distance needed to stop is nil and the bound holds of itself. (3) The curve-speed model: for each st.roadway the subject occupies, the lateral acceleration the observed kin.speed develops on the st.curvature at that roadway's point must not exceed p.reasonable_speed_lateral_acceleration, the side-friction convention for horizontal curves, so the bound tightens as the sharpest bend under the subject sharpens; where the subject occupies no roadway no curvature is read and the bend bounds nothing, and at a standstill the lateral acceleration is nil, so this bound too needs no floor. A speed that exceeds any of the three is not reasonable or proper."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- no reading of this session's own: every narrowing this rule rests on is the record's, on s1 and s3
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

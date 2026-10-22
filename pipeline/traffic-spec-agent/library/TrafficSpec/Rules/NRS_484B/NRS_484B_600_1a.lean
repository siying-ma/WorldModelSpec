/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (obligation): A rate of speed
    s3 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.highway'], derived []
    s2: atoms ['kin.speed'], derived []

  s1 is the binder's class and the applicability. "a vehicle of any kind or character" is the
  aggregate claimed whole: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the id and never the
  classes it covers. "for any person to drive or operate" is read through the vehicle's controlled
  motion (the node's own observable reading, not restated in `narrowings`): the body is upon the
  public way — `rel_occupies v h` for a region `h` of kind highway, which is also what anchors the
  quantifier — and its `kin_speed` stands clear of the source's resolution, `p.speed_resolution`.
  A vehicle at rest is not engaged; a vehicle off the way is not engaged.

  s2 is the quantity the standard bounds: `kin_speed v`, read on the subject itself.

  s3 is the operationalization, written as four bounds conjoined. "the lowest of them binding" and
  "the speed is under each of them" are the same statement, and the conjunction is the one that
  states each bound as its own leaf:
    (i)   the surface-and-light baseline `baseSpeed`: p.speed_ice where env_ice_or_snow, else
          p.speed_wet where env_wet_road or env_precipitation, else p.speed_dark where
          env_darkness, else p.speed_dry — a `Term.cond` ladder, so the comparison over it is
          decided wherever the branches decide it alike;
    (ii)  the stopping-sight-distance bound: the speed at which the subject covers env_visibility
          in p.sight_clearance_time. Written as a product, `speed · T ≤ visibility`, rather than
          `speed ≤ visibility / T`: the rule divides nowhere;
    (iii) the lane-width bound, over every lane the subject occupies (`rel_occupies v l`, which is
          what anchors `l`): the baseline less the deficit of st_lane_width under
          p.reference_lane_width at p.width_penalty_time, and not raised where the lane is wider
          than the reference (the deficit is a `cond` whose other branch is zero). Written through
          p.width_penalty_time as a product on both sides: `speed · W + deficit ≤ baseSpeed · W`;
    (iv)  the traffic-density bound: the baseline less p.traffic_speed_decrement for each other
          road user (`not (same u v)`) whose rel_centre_distance from the subject is within
          p.traffic_reach and whose footprint overlaps a lane lying on a highway the subject
          occupies (st_on_way, which with rel_centre_distance anchors `u`, `l2` and `h2`).
          `Term.aggregate .count` over the road users of the scene; the count of an empty set is
          zero, so a scene with no other road user decides the bound at the baseline.

  The whole duty is the standard, so the rule is a surrogate: its verdicts are evidence, not a
  legal conclusion.

  Narrowing declared on s3 (below, in `narrowings`): the order of severity among the four
  surface-and-light baselines, and that they do not compound.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pReferenceLaneWidth : Term := .param "p.reference_lane_width"
def pSightClearanceTime : Term := .param "p.sight_clearance_time"
def pSpeedDark : Term := .param "p.speed_dark"
def pSpeedDry : Term := .param "p.speed_dry"
def pSpeedIce : Term := .param "p.speed_ice"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pSpeedWet : Term := .param "p.speed_wet"
def pTrafficReach : Term := .param "p.traffic_reach"
def pTrafficSpeedDecrement : Term := .param "p.traffic_speed_decrement"
def pWidthPenaltyTime : Term := .param "p.width_penalty_time"

def zeroMetres : Term := .lit Q.zero .metre
def zeroCount : Term := .lit Q.zero .count

/-- s2: the rate of speed the standard bounds, read on the subject. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject's footprint overlaps a public way. -/
def uponTheWay : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vV, .var "h"] [])

/-- s1: the vehicle is in motion — its speed stands clear of the source's resolution. -/
def inMotion : Formula := .cmp speedV .gt pSpeedResolution

/-- Applicability: s1 — a vehicle of the admitted aggregate, in motion upon a highway. -/
def applicability : Formula := .and uponTheWay inMotion

/-- s3 (i): the surface-and-light baseline, the conditions selecting in order of severity. -/
def baseSpeed : Term :=
  .cond (.atom "env_ice_or_snow" [] [])
    pSpeedIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pSpeedWet
      (.cond (.atom "env_darkness" [] []) pSpeedDark pSpeedDry))

/-- s3 (i): the speed is under the surface-and-light baseline. -/
def underSurfaceBound : Formula := .cmp speedV .le baseSpeed

/-- s3 (ii): the subject covers no more than the visible distance in p.sight_clearance_time. -/
def underSightBound : Formula :=
  .cmp (.mul speedV pSightClearanceTime) .le (.measure "env_visibility" [])

/-- s3 (iii): the deficit of a lane's width under the reference width, zero where it is wider. -/
def laneDeficit : Term :=
  .cond (.cmp (.measure "st_lane_width" [.var "l"]) .lt pReferenceLaneWidth)
    (.sub pReferenceLaneWidth (.measure "st_lane_width" [.var "l"]))
    zeroMetres

/-- s3 (iii): in every lane the subject occupies, the speed is under the baseline less the
    width deficit converted at p.width_penalty_time (stated as a product on both sides). -/
def underWidthBound : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vV, .var "l"] [])
      (.cmp (.add (.mul speedV pWidthPenaltyTime) laneDeficit) .le
            (.mul baseSpeed pWidthPenaltyTime)))

/-- s3 (iv): another road user of the traffic about the subject — within p.traffic_reach, its
    footprint overlapping a lane that lies on a highway the subject occupies. -/
def inTraffic : Formula :=
  .and (.not (.same (.var "u") vV))
    (.and (.cmp (.measure "rel_centre_distance" [.var "u", vV]) .le pTrafficReach)
      (.existsRegion (.lit "highway") "h2"
        (.and (.atom "rel_occupies" [vV, .var "h2"] [])
          (.existsRegion (.lit "lane") "l2"
            (.and (.atom "rel_occupies" [.var "u", .var "l2"] [])
              (.atom "st_on_way" [.var "l2", .var "h2"] []))))))

/-- s3 (iv): how thick the stream about the subject is. -/
def trafficCount : Term := .aggregate .count "u" inTraffic zeroCount

/-- s3 (iv): the speed is under the baseline less a decrement for each such road user. -/
def underTrafficBound : Formula :=
  .cmp speedV .le (.sub baseSpeed (.mul pTrafficSpeedDecrement trafficCount))

/-- Obligation: s2 (obligation): A rate of speed; s3 (standard): greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .and underSurfaceBound
    (.and underSightBound
      (.and underWidthBound underTrafficBound))

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
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.centre_distance", "rel.occupies", "st.highway", "st.lane", "st.lane_width", "st.on_way"]
          params := ["p.speed_dry", "p.speed_wet", "p.speed_ice", "p.speed_dark", "p.sight_clearance_time", "p.reference_lane_width", "p.width_penalty_time", "p.traffic_reach", "p.traffic_speed_decrement"]
          convention := "Four engineering conventions bound the standard together, each giving a speed and the lowest of them binding; the subject's kin.speed is compared with that bound, and each factor the words name is read by the degree to which it holds. (i) A surface-and-light braking convention: a baseline free-flow speed for a dry surface in daylight, p.speed_dry, replaced by p.speed_wet where the surface is wet or rain or snow is falling (env.wet_road, env.precipitation), by p.speed_ice where it is icy or snow-covered (env.ice_or_snow) and by p.speed_dark in darkness (env.darkness), the conditions selecting among the bounds in order of severity, so that a mild surface and a severe one are not held to one bound. (ii) A stopping-sight-distance convention: the bound is env.visibility divided by p.sight_clearance_time, the speed at which the vehicle covers in that time the distance it can see, so the bound falls continuously as the visible distance falls. (iii) A lane-width convention: the bound is the surface-and-light baseline less the deficit of st.lane_width under p.reference_lane_width converted at p.width_penalty_time, and is not raised where the lane is wider than the reference, so the bound falls as the lane narrows. (iv) A traffic-density convention: the bound is the surface-and-light baseline less p.traffic_speed_decrement for each other road user whose footprint overlaps a lane lying on the same highway as the subject's and whose rel.centre_distance from the subject is within p.traffic_reach — the traffic about the subject, read by the presence of road users upon the way — so the bound falls as the stream thickens. Values from highway design practice (design speeds and lane widths), the stopping-sight-distance model, and the wet-surface and icy braking factors of ordinary driver training."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The surface-and-light baselines are ordered by severity and do not compound: an icy or snow-covered surface selects p.speed_ice; failing that, a wet surface or falling precipitation selects p.speed_wet; failing that, darkness selects p.speed_dark; failing that, p.speed_dry. The convention calls for an order of severity but fixes neither the order nor what a vehicle in darkness on a wet surface is held to; it is held here to the one lower baseline, not to the sum of two reductions, and darkness is read only where the surface is otherwise clear."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

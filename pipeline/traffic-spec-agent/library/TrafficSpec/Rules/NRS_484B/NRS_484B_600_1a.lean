/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character
    s2 (boilerplate): at:
    s3 (obligation): A rate of speed
    s4 (standard): greater than is reasonable or proper
    s5 (condition): having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['kin.speed'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.highway', 'rel.centre_distance', 'env.wet_road', 'env.ice_or_snow', 'env.precipitation', 'env.visibility', 'env.darkness', 'st.lane', 'st.lane_width', 'st.sight_distance'], derived []

  How each span is written.

  s1 — the binder's class `clsV`: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the aggregate id
  whole, never the classes it covers. The record's observable reading of agency (a vehicle upon the
  road is taken to be driven, whoever controls it) is the plan's and is not restated below: the
  formulas judge the road user `v`, and nothing here asks who is at the controls.

  s5 — the engagement condition, in `applicability`: `existsRegion "highway" h, rel_occupies v h`.
  Where no public way `v` is upon is in the scene, there is no highway whose traffic, surface,
  width, weather and other conditions the rate could be weighed against, and the rule does not
  engage. The factors s5 names are not conditions of engagement: they enter the bound of s4.

  s3 + s4 — the `obligation`: `v`'s rate of speed does not exceed the least of the four bounds, that
  least floored at none. The floor is written as the disjunct `kin.speed v ≤ 0`: since a rate of
  speed is a magnitude, `speed ≤ max(min bᵢ, 0)` is exactly `speed ≤ 0 ∨ ⋀ᵢ speed ≤ bᵢ`, so a
  vehicle at rest is within the duty however adverse its circumstances, and any moving vehicle is
  held to every bound. The four bounds, as the operationalization sets them out:
    (a) `surfaceTrafficWidthBound`, required of every lane `v` occupies: the free-flow speed the
        surface selects (`env.ice_or_snow` → p.speed_ice, else `env.wet_road` or
        `env.precipitation` → p.speed_wet, else p.speed_dry), less p.traffic_speed_decrement for
        each road user of DEF-NRS-484A-285::traffic other than `v` that occupies a public way `v`
        occupies and whose `rel.centre_distance` from `v` is at most p.traffic_reach, less the
        speed covered in p.width_penalty_time over the width by which `st.lane_width` falls short
        of p.reference_lane_width (a surplus counts as no deficit).
    (b) `nightBound`: where `env.darkness` holds, p.speed_dark.
    (c) `weatherBound`: `env.visibility` covered in p.sight_clearance_time.
    (d) `viewBound`, required of every lane `v` occupies: `st.sight_distance` of that lane covered
        in p.sight_clearance_time.
  Bounds (a) and (d) are written under `forallRegion "lane" l, rel_occupies v l → …`, so that where
  `v` straddles two lanes the stricter governs and where it occupies none they say nothing — the
  reading the record already declares on s4.

  Arithmetic. Bounds (a), (c) and (d) are stated as products rather than quotients: a rate below
  `d / t` is written `rate · t ≤ d`, and bound (a) multiplied through by p.width_penalty_time. The
  two forms are the same comparison for a positive time, and no division appears, so no measured
  quantity can be a divisor.

  Narrowings: none of this coder's own. Every reading the formulas stand on — the floor at none,
  the lane width for the width of the highway, the two surface contracts, the weather read through
  precipitation and visibility, the catch-all read through sight distance and darkness, the traffic
  counted within a reach and excluding `v` itself, the per-lane requirement, the deficit floored —
  is declared by the record and is not restated here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified variables: a lane `v` occupies, a public way `v` occupies, a road user of the
    traffic about `v`, and the way that road user shares with `v`. -/
def lL : Arg := .var "l"
def hH : Arg := .var "h"
def uU : Arg := .var "u"
def wW : Arg := .var "w"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pReferenceLaneWidth : Term := .param "p.reference_lane_width"
def pSightClearanceTime : Term := .param "p.sight_clearance_time"
def pSpeedDark : Term := .param "p.speed_dark"
def pSpeedDry : Term := .param "p.speed_dry"
def pSpeedIce : Term := .param "p.speed_ice"
def pSpeedWet : Term := .param "p.speed_wet"
def pTrafficReach : Term := .param "p.traffic_reach"
def pTrafficSpeedDecrement : Term := .param "p.traffic_speed_decrement"
def pWidthPenaltyTime : Term := .param "p.width_penalty_time"

def zeroMetres : Term := .lit Q.zero .metre
def zeroSpeed : Term := .lit Q.zero .metrePerSecond
def zeroCount : Term := .lit Q.zero .count

/-- s3: `v`'s rate of speed, the magnitude of its velocity. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- s4(a), the surface: the free-flow speed the surface allows. Ice or snow selects the icy speed;
    a wet surface, standing water or falling rain or snow the wet one; otherwise the dry one. -/
def surfaceSpeed : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pSpeedIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pSpeedWet pSpeedDry)

/-- s5: a road user of the traffic about `v` — one of DEF-NRS-484A-285::traffic other than `v`
    itself, whose footprint overlaps a public way `v`'s footprint overlaps, within the reach. -/
def trafficAbout : Formula :=
  .and (.not (.same uU vV))
    (.and (.atom "ru_aggregate" [uU, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.existsRegion (.lit "highway") "w"
              (.and (.atom "rel_occupies" [vV, wW] [])
                    (.atom "rel_occupies" [uU, wW] [])))
            (.cmp (.measure "rel_centre_distance" [vV, uU]) .le pTrafficReach)))

/-- s4(a), the traffic: how many road users of the traffic are about `v`. -/
def trafficCount : Term := .aggregate .count "u" trafficAbout zeroCount

/-- s4(a): the free-flow speed the surface allows, less the allowance for the traffic about `v`. -/
def freeFlowSpeed : Term := .sub surfaceSpeed (.mul pTrafficSpeedDecrement trafficCount)

/-- s4(a), the width: the width by which the lane `l` falls short of the reference, floored at
    none, so that a lane wider than the reference adds nothing. -/
def widthDeficit : Term :=
  .cond (.cmp (.measure "st_lane_width" [lL]) .lt pReferenceLaneWidth)
    (.sub pReferenceLaneWidth (.measure "st_lane_width" [lL]))
    zeroMetres

/-- s4(a): the surface, traffic and width bound on the lane `l`, multiplied through by
    p.width_penalty_time: `speed ≤ freeFlow − deficit / t` written `speed · t ≤ freeFlow · t − deficit`. -/
def surfaceTrafficWidthBound : Formula :=
  .cmp (.mul speedV pWidthPenaltyTime) .le
       (.sub (.mul freeFlowSpeed pWidthPenaltyTime) widthDeficit)

/-- s4(d): the view bound on the lane `l` — `v` can halt within the sight distance at its place,
    written `speed · t ≤ sight distance`. -/
def viewBound : Formula :=
  .cmp (.mul speedV pSightClearanceTime) .le (.measure "st_sight_distance" [lL])

/-- s4(b): the night bound — where the natural light is insufficient, the speed its lamps allow. -/
def nightBound : Formula :=
  .implies (.atom "env_darkness" [] []) (.cmp speedV .le pSpeedDark)

/-- s4(c): the weather bound — `v` can halt within the distance the air lets it see, written
    `speed · t ≤ visibility distance`. -/
def weatherBound : Formula :=
  .cmp (.mul speedV pSightClearanceTime) .le (.measure "env_visibility" [])

/-- s4(a) and s4(d) of every lane `v` occupies: where it straddles two, the stricter governs. -/
def laneBounds : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vV, lL] [])
      (.and surfaceTrafficWidthBound viewBound))

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s5 (condition): having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vV, hH] [])

/-- Obligation: s3 (obligation): A rate of speed; s4 (standard): greater than is reasonable or proper -/
def obligation : Formula :=
  .or (.cmp speedV .le zeroSpeed)
      (.and laneBounds (.and nightBound weatherBound))

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.centre_distance", "rel.occupies", "st.highway", "st.lane", "st.lane_width", "st.sight_distance"]
          params := ["p.speed_dry", "p.speed_wet", "p.speed_ice", "p.speed_dark", "p.reference_lane_width", "p.width_penalty_time", "p.sight_clearance_time", "p.traffic_reach", "p.traffic_speed_decrement"]
          convention := "A surface-braking convention for the free-flow speed, combined with a stopping-within-the-view convention and a density allowance: the reasonable and proper rate is the least of four bounds, and every factor the clause names enters a bound by the degree to which it holds. (a) The surface, traffic and width bound: the free-flow speed the surface allows - p.speed_ice where the roadway carries ice or snow (env.ice_or_snow), p.speed_wet where it is wet or carries standing water or rain or snow is falling (env.wet_road, env.precipitation), p.speed_dry otherwise - reduced by p.traffic_speed_decrement for each road user of the traffic (the aggregate claimed on s5) whose footprint overlaps (rel.occupies) a public way (st.highway) the vehicle's own footprint overlaps and whose centre distance from the vehicle (rel.centre_distance) is at most p.traffic_reach, and reduced further by the speed covered in p.width_penalty_time over the width by which the lane the vehicle occupies (st.lane, rel.occupies, st.lane_width) falls short of p.reference_lane_width, so that each metre of missing width costs the speed covered in that time. (b) The night bound: p.speed_dark where the natural light is insufficient (env.darkness), the speed from which a vehicle can halt within the length of road its own lamps show. (c) The weather bound: the visibility distance (env.visibility) divided by p.sight_clearance_time, the time within which the vehicle must be able to come to a halt inside the distance it can see. (d) The view bound: the sight distance at the vehicle's place (st.sight_distance) divided by the same p.sight_clearance_time. No bound is a negative rate and the reasonable and proper rate is never less than none: where the allowances for the traffic and for the missing width together exceed the free-flow speed the surface allows, bound (a) is zero, and the least of the four, if it ever fell below zero, is zero. A rate of speed is a magnitude, so a vehicle at rest reads zero and is within every bound: a composition of allowances may carry the reasonable rate down to a standstill but never past it, and no accumulation of adverse circumstances makes standing still a rate of speed greater than is reasonable or proper. The vehicle's rate of speed (kin.speed) is compared with the least of the four as so floored; exceeding it is the violation. Every magnitude in the bound is a reading parameter and no figure is stated here: more traffic, less lane width, a shorter view and a thicker air each lower the bound continuously, while the surface and the light select among bounds."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- every reading these formulas stand on is the record's own; none is this coder's
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

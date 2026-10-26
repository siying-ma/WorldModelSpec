/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): It is unlawful for any person to drive or operate
    s2 (subject): a vehicle
    s3 (subject): of any kind or character
    s4 (boilerplate): at:
    s5 (standard): A rate of speed greater than is reasonable or proper, having due regard for
    s6 (condition): the traffic
    s7 (condition): surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.highway', 'rel.centre_distance'], derived []
    s7: atoms ['env.wet_road', 'env.ice_or_snow', 'env.precipitation', 'env.darkness', 'env.visibility', 'rel.occupies', 'st.lane', 'st.lane_width', 'st.sight_distance'], derived []

  How each span is written:

    s2 — `clsV`, the binder's class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the admitted
      aggregate id and nothing else; which classes the reading includes under it is the reading's.
    s3 — the node's residue; nothing here.
    s1 — `applicability`: the vehicle's own controlled motion, `kin.speed` standing clear of
      p.speed_resolution. This is the node's own `observable_reading` narrowing on s1 and is not
      restated in `narrowings`.
    s5 — `obligation`, the surrogate standard, written as the conjunction of the bounds the
      operationalization composes, since `kin.speed` is at most the least of several bounds exactly
      where it is at most each of them (the language has no minimum, and a conjunction of
      comparisons is that minimum):
        · the surface-and-weather baseline `surfaceBaseline` (p.speed_ice where env.ice_or_snow,
          p.speed_wet where env.wet_road or env.precipitation, p.speed_dry otherwise), with the
          traffic allowance added back to the subject's speed rather than subtracted from the
          baseline (the same comparison);
        · the night cap p.speed_dark wherever env.darkness holds;
        · the air the weather gives: speed × p.sight_clearance_time ≤ env.visibility;
        · and, for every lane the subject's footprint overlaps (`rel.occupies`, st.lane), the same
          two speed bounds with the lane's width deficit owed, and the view the road affords there:
          speed × p.sight_clearance_time ≤ st.sight_distance.
      The width allowance is written multiplied through p.width_penalty_time rather than divided by
      it — `speed·t + (reference − width) ≤ bound·t` is `speed + (reference − width)/t ≤ bound` —
      so that no division appears in the rule at all.
    s6 — inside the standard, as the traffic allowance: `Term.aggregate .count` over the road users
      of the scene that are not the subject (`same`), are members of DEF-NRS-484A-285::traffic,
      overlap a highway region (st.highway) the subject's own footprint overlaps (`rel.occupies`),
      and lie within p.traffic_reach of the subject by `rel.centre_distance`; the count times
      p.traffic_speed_decrement is what the bound falls by.
    s7 — inside the standard, as above: env.wet_road, env.ice_or_snow, env.precipitation select the
      baseline, env.darkness caps it, env.visibility and st.sight_distance cap the bound, and
      st.lane_width at the subject's place (st.lane, rel.occupies) sets the width deficit.

  Readings I chose, declared in `narrowings` (the record's own narrowings are the plan's and are
  not restated here):
    1. s5 — 'the width of the highway' and 'other highway conditions' are read at the subject's
       place as the mapped width and the sight distance of a lane region its footprint overlaps.
       Where the subject overlaps no lane neither bound is read at all; where it overlaps several,
       each must be satisfied.
    2. s5 — the width and traffic allowances are owed against the night cap as well as against the
       surface baseline: in darkness the bound is p.speed_dark less those allowances.

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
/-- The term a `count` aggregate carries and never reads. -/
def zeroCount : Term := .lit Q.zero .count

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the vehicle's own motion — its speed, the magnitude the conduct is read through. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- Applicability: s1 (obligation): driving or operating, read as the subject's own motion —
    its speed stands clear of the source's resolution. Nothing else conditions the duty. -/
def applicability : Formula := .cmp speedV .gt pSpeedResolution

-- s7: the surface, the weather and the light.
def wetF : Formula := .atom "env_wet_road" [] []
def iceF : Formula := .atom "env_ice_or_snow" [] []
def precipF : Formula := .atom "env_precipitation" [] []
def darkF : Formula := .atom "env_darkness" [] []

/-- The baseline the surface and the weather select by their braking factor. -/
def surfaceBaseline : Term :=
  .cond iceF pSpeedIce (.cond (.or wetF precipF) pSpeedWet pSpeedDry)

/-- s6: a road user other than the subject, of the traffic upon a highway the subject's own
    footprint overlaps, within the reach about the subject. -/
def trafficAbout : Formula :=
  .and (.not (.same (.var "u") vV))
    (.and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.existsRegion (.lit "highway") "h"
              (.and (.atom "rel_occupies" [vV, .var "h"] [])
                    (.atom "rel_occupies" [.var "u", .var "h"] [])))
        (.cmp (.measure "rel_centre_distance" [vV, .var "u"]) .le pTrafficReach)))

/-- How many of them there are. -/
def trafficCount : Term := .aggregate .count "u" trafficAbout zeroCount

/-- What the bound falls by for the traffic about the subject. -/
def trafficAllowance : Term := .mul pTrafficSpeedDecrement trafficCount

/-- The subject's speed with the traffic allowance added back, so that the comparison against a
    baseline is the baseline less that allowance. -/
def speedWithTraffic : Term := .add speedV trafficAllowance

/-- s7: the width by which the lane `l` falls short of the reference; no deficit where it does not. -/
def widthDeficit : Term :=
  .cond (.cmp (.measure "st_lane_width" [.var "l"]) .lt pReferenceLaneWidth)
    (.sub pReferenceLaneWidth (.measure "st_lane_width" [.var "l"]))
    zeroMetres

/-- The surface baseline, less the traffic allowance and the width deficit of the lane `l`
    (multiplied through p.width_penalty_time, so that nothing is divided). -/
def withinSurfaceBound : Formula :=
  .cmp (.add (.mul speedWithTraffic pWidthPenaltyTime) widthDeficit)
    .le (.mul surfaceBaseline pWidthPenaltyTime)

/-- The night cap, less the same two allowances. -/
def withinDarkBound : Formula :=
  .cmp (.add (.mul speedWithTraffic pWidthPenaltyTime) widthDeficit)
    .le (.mul pSpeedDark pWidthPenaltyTime)

/-- The stopping-sight-distance cap on the air the weather gives. -/
def withinVisibility : Formula :=
  .cmp (.mul speedV pSightClearanceTime) .le (.measure "env_visibility" [])

/-- The same cap on the view the road affords at the subject's place. -/
def withinSightDistance : Formula :=
  .cmp (.mul speedV pSightClearanceTime) .le (.measure "st_sight_distance" [.var "l"])

/-- The bounds that are owed at the subject's place in a lane its footprint overlaps. -/
def laneBounds : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "rel_occupies" [vV, .var "l"] [])
      (.and withinSurfaceBound (.and (.implies darkF withinDarkBound) withinSightDistance)))

/-- Obligation: s1 (obligation): It is unlawful for any person to drive or operate; s5 (standard): A rate of speed greater than is reasonable or proper, having due regard for -/
def obligation : Formula :=
  .and (.cmp speedWithTraffic .le surfaceBaseline)
    (.and (.implies darkF (.cmp speedWithTraffic .le pSpeedDark))
      (.and withinVisibility laneBounds))

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
          params := ["p.speed_dry", "p.speed_wet", "p.speed_ice", "p.speed_dark", "p.reference_lane_width", "p.width_penalty_time", "p.traffic_reach", "p.traffic_speed_decrement", "p.sight_clearance_time"]
          convention := "A surface-braking convention and a stopping-sight-distance convention, with a lane-width allowance and a traffic-density allowance, composed into one upper bound on the subject's own speed, so that every factor the standard names moves the bound by the degree to which it holds. The baseline is the free-flow speed that is reasonable on a dry surface in daylight on an ordinary two-lane highway (p.speed_dry); the surface and the weather select among baselines by the braking factor of what is observed - p.speed_ice where env.ice_or_snow holds, p.speed_wet where env.wet_road or env.precipitation holds, p.speed_dry otherwise - and darkness caps the baseline at the night allowance p.speed_dark, the speed from which a vehicle can halt within the length of road its own lamps show. The width of the way enters as a magnitude: each metre by which st.lane_width at the subject's place falls short of p.reference_lane_width costs the speed the vehicle covers in p.width_penalty_time, and that deficit is subtracted from the baseline; where the subject's footprint overlaps no lane no deficit is owed, and where a lane is overlapped but its width is not observed the bound is unknown. The traffic enters as a magnitude too: the bound falls by p.traffic_speed_decrement for each road user other than the subject that is a member of the traffic aggregate claimed on span s6, overlaps a highway region the subject's own footprint overlaps, and lies within p.traffic_reach of the subject by rel.centre_distance, so the bound falls as the stream thickens. Finally the stopping-sight-distance convention caps the bound at the distance that can be seen divided by p.sight_clearance_time, applied to env.visibility, the clarity of the air the weather gives, and to st.sight_distance, the view the road itself affords at the subject's place, which is also what this operationalization reads for 'other highway conditions'. The speed is reasonable and proper where kin.speed is at most the least of these bounds, and greater than is reasonable or proper where it exceeds that least bound. Every value is the reading's; the node names the parameters and carries no figure."
          surrogate := true } ]
    residues := ["The words add no restriction and impose no observable condition: they emphasise that the duty reaches every member of the aggregate rather than naming a kind, a character or a state a vehicle must be in, so the duty is the same whether or not they are read. Which devices count is the admitted aggregate DEF-NRS-484A-320::vehicle, claimed on the subject span; these words neither widen nor narrow it in any way a scene could show."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "'the width of the highway' and 'other highway conditions' are read at the subject's place as the mapped width (st.lane_width) and the sight distance (st.sight_distance) of a lane region the subject's footprint overlaps (st.lane, rel.occupies). The operationalization says 'at the subject's place' without saying which region of the scene carries the width and the view, and the ontology maps a width to a lane only; so where the subject's footprint overlaps no lane neither the width allowance nor the sight-distance cap is read at all, and where it overlaps several lanes the bound is owed on each of them. A width or a view mapped to the highway region rather than to the lane the subject is in is not read."
          kind := "reading" }
      , { span := "s5"
          why := "The width allowance and the traffic allowance are owed against the night cap as well as against the surface baseline: in darkness the bound is p.speed_dark less both allowances. The convention says that darkness caps the baseline and that the deficits are subtracted from 'the baseline', which leaves open whether the capped night figure is itself reduced by them; it is read as reduced, so a narrow lane or a thick stream of traffic lowers the bound by night as it does by day."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

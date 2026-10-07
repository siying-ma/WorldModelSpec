/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s_lead (boilerplate): It is unlawful for any person
    s_drive (trigger): to drive or operate
    s_vehicle (subject): a vehicle of any kind or character
    s_at (boilerplate): at:
    s_rate (obligation): A rate of speed greater than
    s_std (standard): is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    s_drive: atoms [], derived ['drv.motion.in_motion']
    s_vehicle: atoms ['ru.aggregate=vehicle'], derived []
    s_rate: atoms ['kin.speed'], derived []

  How each span is written.

  s_vehicle — the binder's class: `ru_aggregate veh "vehicle"`, the aggregate word itself and never
  the classes the reading lists under it. 'of any kind or character' adds no condition: it says the
  word is not narrowed by the type of the device, which is how the aggregate already reads.

  s_drive — the applicability: `drv.motion.in_motion` of the subject at `p.motion_speed_min`. The
  road user proceeding over the ground is what a source observes of a person driving; see the
  narrowing on s_rate for what this leaves out.

  s_rate — the obligation is the comparison `greater than`, whose right-hand side s_std sets. It is
  written as the negation of the four bounds: the subject complies where its rate passes none of
  them. `kin.speed` of the subject enters the width and the curvature bounds directly, and the two
  stopping distances through the concepts.

  s_std — the four bounds of the operationalization, joined by `or` under the negation:
    (1) the traffic: some other road user of the aggregate 'traffic' ahead of the subject in its
        lane, with the subject's stopping distance at `p.brake_response_time` exceeding the
        longitudinal surface gap plus that road user's braking distance;
    (2) the weather: the subject's stopping distance at `p.reaction_time` exceeding `env.visibility`;
    (3) the width: the subject's speed, less `p.speed_tolerance`, above the free-flow speed reduced
        in the proportion the lane's width deficit bears to the base width;
    (4) other highway conditions: the square of the subject's speed less `p.speed_tolerance`,
        against `p.lateral_accel_max` and the curvature of the roadway it occupies.
  The deceleration of (1) and (2) is selected by the surface with `Term.cond`: `p.decel_ice` under
  ice or snow, else `p.decel_wet` under a wet road or precipitation, else `p.decel_dry`. A
  comparison over a `cond` is decided by cases, so an unobserved surface leaves the verdict open
  only where the choice of deceleration would change it.

  Narrowings declared below, beyond the three the record carries on s_std and the one on s_rate:
  the curvature bound is stated as `(speed − tolerance)² · |curvature| > p.lateral_accel_max`
  rather than against the radius `1/curvature`. The two are the same wherever the roadway bends;
  they part where `st.curvature` is zero, that is where the way runs straight and the radius is not
  a quantity: there the bound as written is passed by no speed, which is the reading the convention
  intends (a bend bounds the speed, a straight way does not). The magnitude of the curvature is
  taken, so a bend reads the same whichever way it turns. The width bound is likewise stated
  without dividing by the base width, by multiplying both sides of the convention's comparison by
  it: the same bound, with no division in the rule.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
private def vVeh : Arg := .var "veh"

/-- The variables the obligation quantifies over, each tied to `veh` by a relation. -/
private def vOth : Arg := .var "oth"
private def vLn : Arg := .var "ln"
private def vRd : Arg := .var "rd"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pBrakeResponseTime : Term := .param "p.brake_response_time"
private def pDecelDry : Term := .param "p.decel_dry"
private def pDecelIce : Term := .param "p.decel_ice"
private def pDecelWet : Term := .param "p.decel_wet"
private def pFreeFlowSpeedBase : Term := .param "p.free_flow_speed_base"
private def pLaneWidthNominal : Term := .param "p.lane_width_nominal"
private def pLateralAccelMax : Term := .param "p.lateral_accel_max"
private def pMotionSpeedMin : Term := .param "p.motion_speed_min"
private def pNarrowLaneSpeedDrop : Term := .param "p.narrow_lane_speed_drop"
private def pReactionTime : Term := .param "p.reaction_time"
private def pSpeedTolerance : Term := .param "p.speed_tolerance"

-- The surface of the highway, as the ontology carries it.
private def icyOrSnowy : Formula := .atom "env_ice_or_snow" [] []
private def wetSurface : Formula := .atom "env_wet_road" [] []
private def rainOrSnowFalling : Formula := .atom "env_precipitation" [] []

/-- A quantity computed at the deceleration the surface allows: `p.decel_ice` under ice or snow,
    else `p.decel_wet` under a wet road or falling precipitation, else `p.decel_dry`. -/
private def atSurfaceDecel (f : Term → Term) : Term :=
  .cond icyOrSnowy (f pDecelIce)
    (.cond (.or wetSurface rainOrSnowFalling) (f pDecelWet) (f pDecelDry))

private def stoppingDistance (x : Arg) (react decel : Term) : Term :=
  .quantity "drv_motion_stopping_distance" [x] [react, decel]

private def brakingDistance (x : Arg) (decel : Term) : Term :=
  .quantity "drv_motion_braking_distance" [x] [decel]

private def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

/-- The subject's speed less the margin by which a measured speed must exceed a bound. -/
private def speedOverTolerance : Term := .sub (speedOf vVeh) pSpeedTolerance

/-- (1) The traffic: the subject cannot halt behind a road user of the aggregate 'traffic' that is
    ahead of it in its lane and brakes to a stand. -/
private def trafficBoundPassed : Formula :=
  .existsUser "oth"
    (.and (.not (.same vOth vVeh))
      (.and (.atom "ru_aggregate" [vOth, .lit "traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [vOth, vVeh] [])
          (.cmp (atSurfaceDecel fun d => stoppingDistance vVeh pBrakeResponseTime d) .gt
                (.add (.measure "rel_surface_gap" [vVeh, vOth, .lit "longitudinal"])
                      (atSurfaceDecel fun d => brakingDistance vOth d))))))

/-- (2) The weather: the subject cannot halt within what can be seen through the air. -/
private def visibilityBoundPassed : Formula :=
  .cmp (atSurfaceDecel fun d => stoppingDistance vVeh pReactionTime d) .gt
       (.measure "env_visibility" [])

/-- (3) The width of the highway: the subject's speed is above the free-flow speed the width of the
    lane it occupies leaves, by more than the speed tolerance. The convention's bound is
    `base − drop · (nominal − width) / nominal`; both sides are multiplied by the base width, so
    the rule divides by nothing. -/
private def widthBoundPassed : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and (.atom "st_lane" [vLn] [])
      (.and (.atom "rel_occupies" [vVeh, vLn] [])
        (.cmp (.mul speedOverTolerance pLaneWidthNominal) .gt
              (.sub (.mul pFreeFlowSpeedBase pLaneWidthNominal)
                    (.mul pNarrowLaneSpeedDrop
                          (.sub pLaneWidthNominal (.measure "st_lane_width" [vLn])))))))

/-- (4) Other highway conditions: the bend of the roadway the subject occupies at its place
    exhausts the side friction a driver may comfortably call on. `v² > a · r` with `r = 1 / κ` is
    written `v² · |κ| > a`, which is the same bound wherever the way bends and is passed by no
    speed where it runs straight. -/
private def curvatureBoundPassed : Formula :=
  .existsRegion (.lit "roadway") "rd"
    (.and (.atom "st_roadway" [vRd] [])
      (.and (.atom "rel_occupies" [vVeh, vRd] [])
        (.cmp (.mul (.mul speedOverTolerance speedOverTolerance)
                    (.abs (.measure "st_curvature" [vRd]))) .gt
              pLateralAccelMax)))

/-- Class of `veh`: ru.aggregate=vehicle -/
private def clsVeh : Formula := .atom "ru_aggregate" [vVeh, .lit "vehicle"] []

/-- Applicability: s_drive (trigger): to drive or operate -/
private def applicability : Formula := .derived "drv_motion_in_motion" [vVeh] [pMotionSpeedMin]

/-- Obligation: s_rate (obligation): A rate of speed greater than; s_std (standard): is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
private def obligation : Formula :=
  .not (.or (.or trafficBoundPassed visibilityBoundPassed)
            (.or widthBoundPassed curvatureBoundPassed))

def rule : Rule :=
  { id := "NRS_484B_600_1a"
    laws := ["NRS-484B-600-1a"]
    binders :=
      [ { name := "veh", cls := clsVeh } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.motion.braking_distance", "drv.motion.stopping_distance", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "ru.aggregate", "st.curvature", "st.lane", "st.lane_width", "st.roadway"]
          params := ["p.reaction_time", "p.brake_response_time", "p.decel_dry", "p.decel_wet", "p.decel_ice", "p.lateral_accel_max", "p.lane_width_nominal", "p.narrow_lane_speed_drop", "p.free_flow_speed_base", "p.speed_tolerance"]
          convention := "A reasonable and proper rate of speed is bounded by four bounds, one for each factor the clause names, and the subject's rate is greater than is reasonable when it passes any of them; each bound moves with the magnitude of the factor that sets it, so a milder condition leaves a higher speed reasonable than a severer one does. The surface of the highway selects the deceleration a stop may be computed at, by the stopping-sight-distance convention of the AASHTO Green Book taken at the surface conditions the ontology carries: p.decel_ice where env.ice_or_snow holds, else p.decel_wet where env.wet_road or env.precipitation holds, else p.decel_dry. (1) The traffic. By the following-distance convention of responsibility-sensitive safety, the subject must be able to halt behind a road user ahead of it that brakes to a stand: the bound is passed where some road user of the aggregate 'traffic' is ahead of the subject in the lane the subject occupies (rel.ahead_behind_in_lane) and drv.motion.stopping_distance of the subject, at p.brake_response_time and the surface's deceleration, exceeds the longitudinal component of rel.surface_gap between the two bodies plus drv.motion.braking_distance of that road user at the same deceleration. The gap, the subject's speed and the other's speed all enter, so the bound tightens as the gap shortens and as the user ahead is slower. (2) The weather. By the stopping-sight-distance convention, the subject must be able to halt within what can be seen through the air: the bound is passed where drv.motion.stopping_distance of the subject, at the design brake-reaction time p.reaction_time and the surface's deceleration, exceeds env.visibility, the visibility distance of fog, dust or smoke. The visibility distance enters as a magnitude, so the bound falls as the air thickens. (3) The width of the highway. By the free-flow-speed adjustment for lane width of the Highway Capacity Manual, the speed drivers may reasonably hold falls as the lane narrows below the base width: the bound is p.free_flow_speed_base reduced by p.narrow_lane_speed_drop taken in the proportion that the lane's width deficit bears to the base width - the deficit being the amount by which st.lane_width of the lane the subject occupies (rel.occupies on st.lane) falls short of p.lane_width_nominal, and the drop being what the adjustment takes off for a deficit as large as the base width itself - and the bound is passed where kin.speed of the subject exceeds it by more than p.speed_tolerance. The width enters as a magnitude, so the bound falls as the lane narrows. (4) Other highway conditions. By the point-mass curve model of the AASHTO Green Book at zero superelevation, a bend bounds the speed at which the side friction a driver may comfortably call on is exhausted: the bound is passed where the square of kin.speed of the subject, less p.speed_tolerance, exceeds p.lateral_accel_max multiplied by the radius of st.curvature of the roadway the subject occupies (rel.occupies on st.roadway) at its place. The radius enters as a magnitude, so the bound falls as the bend tightens. Values for every parameter are the reading's and are proposed in param_proposals; the rule names the parameters and carries no figure."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s_std"
          why := "'width of the highway' is read as the width of the lane the subject occupies (st.lane_width on the lane it is in), not as the width between the boundary lines of the way that DEF-NRS-484A-095 defines. st.highway carries no width, and the ontology has no atom for the width of a way or of a roadway; the lane is the width the subject's speed is actually constrained by, so a way that is wide in total but laid out in narrow lanes is read as narrow, and a narrow way laid out as one wide lane is read as wide."
          kind := "reading" }
      , { span := "s_std"
          why := "'surface ... of the highway' is read only as whether the surface is wet (env.wet_road), icy or snow-covered (env.ice_or_snow), with falling rain or snow (env.precipitation) read with the wet surface. The ontology carries no atom for the surface's material, its texture, its state of repair, its looseness or its measured friction, so a gravel, broken or oily surface is not read at all; what is carried is read by the deceleration each condition selects, and that deceleration moves the first two bounds."
          kind := "reading" }
      , { span := "s_std"
          why := "'the traffic' is read as the road users of the aggregate 'traffic' that are ahead of the subject in the lane it occupies, through the gap within which the subject must be able to halt. Traffic behind it, beside it, crossing it, or ahead of it in another lane is not read, although the ontology carries those relations: a speed bound for them would be a model of how the duty is performed rather than a reading of the clause's words."
          kind := "reading" }
      , { span := "s_std"
          why := "the curvature bound is stated as the square of the subject's speed, less p.speed_tolerance, times the magnitude of st.curvature, against p.lateral_accel_max, rather than against p.lateral_accel_max times the radius 1/st.curvature. The two comparisons are the same wherever the roadway bends; they part where the curvature is zero, where the radius is not a quantity and a division by it would leave the bound undecided: there the bound as written is passed by no speed, which is what the convention intends, a bend bounding the speed and a straight way not. The magnitude is taken, so a bend reads the same whichever way it turns. The width bound is in the same way multiplied through by p.lane_width_nominal instead of dividing by it."
          kind := "reading" }
      , { span := "s_rate"
          why := "the obligation is read only of a vehicle proceeding over the ground. The words 'drive or operate' reach a vehicle operated while standing - engine running, a gear selected, no motion - and this reading leaves such a vehicle outside the rule. It removes no case the obligation side decides: a standing vehicle's rate of speed passes none of the four bounds, so the narrowing changes which observations the rule is applicable to and never which of them it would have found violated."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

/-
  NRS_484B_600_1a — NRS-484B-600-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    k1 (obligation): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    k2 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions.

  Elements (span → atoms, derived):
    k1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.highway', 'kin.speed'], derived []

  Operationalization (k2): the reasonable-speed bound — the lower of the stopping bound and the
  curvature bound, each reduced by the width available; surrogate, so its verdicts are evidence.

  How each span is written.

  k1 — `clsSubject`: the admitted aggregate, as the one atom `ru_aggregate` of the binder with the
  aggregate's id as its literal argument; "of any kind or character" adds no class of its own.
  "for any person to drive or operate" is read through the vehicle's controlled motion, as the
  record's observable reading directs (the plan's narrowing, not restated below): the subject's
  speed above the motion tolerance (`inMotion`) while its footprint overlaps a highway region
  (`occupiesWay` under a quantifier whose kind is `st.highway`, the whole extent the kind gives the
  word). Those two are the applicability: at an observation at which either fails, the vehicle is
  not being driven on a highway and the subsection lays no duty on it.

  k2 — the obligation. The duty is owed at each way the subject is on, so the obligation re-states
  the applicability's whole selection of that way (`occupiesWay`) under a `forallRegion` of the
  same kind, and reads the standard there; the sight distance along the way (`st.sight_along_way`)
  is read of the subject on that way.

  The bound itself (`reasonableSpeedThere`) is the operationalization's, read by the degree of each
  factor:

  - the clear distance ahead. The subject must be able to halt within it: after the reaction time
    (`p.speed_reaction_time`), at the deceleration the surface and the weather allow, the distance
    it needs is its reaction distance plus its braking distance. `couldHaltWithin d` states that
    bound for a distance `d` as one comparison between products, `v²·W² ≤ 2a·wEff·(d·wEff − v·T·W)`:
    the stopping requirement cleared of its denominators, so that nothing is divided by a measured
    quantity, with twice the deceleration written as each selected parameter added to itself, since
    no magnitude of this file's own, not even a factor of two, may enter a formula, and with the
    reaction term carried to the other side, so that each selection among bounds is made once.
  - the deceleration available (`deceleration`): `p.speed_stopping_deceleration_adverse` where the
    surface is wet, icy or snow-covered or precipitation is falling, else
    `p.speed_stopping_deceleration_dry` — a condition selecting among bounds, written with
    `Term.cond`, so that where the source declares no surface state at all the comparison is
    decided only where both selections decide it alike.
  - the width available (`widthAvailable`): the width of the lane the subject occupies where that
    is narrower than `p.reference_lane_width`, else the reference width; both bounds are reduced in
    the ratio of the one to the other, which the comparisons carry as the factors `wEff` and
    `wEff²` against `W` and `W²`.
  - the curvature bound (`withinCurvatureBound`): speed squared times the curvature of the way at
    the subject's place is at most `p.lateral_acceleration_max`, reduced by the same ratio.

  Narrowings declared below, all on k2, the standard's span:
  - the curvature and the width are read on the lane the subject occupies on that way (the atoms
    the node claims for them are `st.lane`, `st.lane_width`, `st.curvature` with `rel.occupies` and
    `st.on_way`; it claims no roadway), the duty is read at each such lane, and where the source
    maps no lane under the subject the standard's width and curvature cannot be read and the bound
    is not stated at that observation;
  - "the least of" the three clear distances is written as the bound taken at each of them in turn
    (the longitudinal body gap, the sight distance along the way and the visibility distance),
    which is the bound at their least, and which stays decided by the others where one of them is
    unobserved;
  - "the nearest road user it follows in its own line of travel" is written as every road user the
    subject follows, by `drv.interaction.following_vehicle_ahead` over the road users of the scene
    with the alignment and motion tolerances, each with the longitudinal gap to it: the bound at
    the nearest is the strictest, so the bound at every one of them is the same requirement.

  No magnitude below is this file's own: parameters name the reading, and the only literals are the
  aggregate's id and the enumeration spellings of the quantifiers and of the gap's component.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The way the subject is on, the lane it occupies on that way, and another road user of the
    scene: each anchored to the subject by `rel.occupies` or by the relations read of the pair. -/
def vWay : Arg := .var "way"
def vLane : Arg := .var "lane"
def vOther : Arg := .var "other"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLateralAccelerationMax : Term := .param "p.lateral_acceleration_max"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pReferenceLaneWidth : Term := .param "p.reference_lane_width"
def pSameDirectionTolerance : Term := .param "p.same_direction_tolerance"
def pSpeedReactionTime : Term := .param "p.speed_reaction_time"
def pSpeedStoppingDecelerationAdverse : Term := .param "p.speed_stopping_deceleration_adverse"
def pSpeedStoppingDecelerationDry : Term := .param "p.speed_stopping_deceleration_dry"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- The quantities the standard reads
-- ---------------------------------------------------------------------------------------------
/-- k1, k2: the magnitude of the subject's velocity. -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- k2: the width of the lane the subject occupies. -/
def laneWidth : Term := .measure "st_lane_width" [vLane]

/-- k2: the horizontal curvature of that lane at the subject's place, as a magnitude. -/
def curvature : Term := .measure "st_curvature" [vLane]

/-- k2: the sight distance along the way the subject is on. -/
def sightAlongWay : Term := .measure "st_sight_along_way" [vSubject, vWay]

/-- k2: the visibility distance. -/
def visibility : Term := .measure "env_visibility" []

/-- k2: the longitudinal gap between the subject's body and another's. -/
def gapAhead : Term := .measure "rel_surface_gap" [vSubject, vOther, .lit "longitudinal"]

/-- k1: the subject's footprint overlaps that way. -/
def occupiesWay : Formula := .atom "rel_occupies" [vSubject, vWay] []

/-- k2: that lane is a lane of that way which the subject's footprint overlaps. -/
def occupiesLaneOfWay : Formula :=
  .and (.atom "rel_occupies" [vSubject, vLane] [])
       (.atom "st_on_way" [vLane, vWay] [])

/-- k1: the vehicle is in motion — its speed above the reading's motion tolerance, which is how
    the record reads its being driven or operated. -/
def inMotion : Formula := .cmp speed .gt pMotionSpeedTolerance

-- ---------------------------------------------------------------------------------------------
-- The reasonable-speed bound (k2)
-- ---------------------------------------------------------------------------------------------
/-- k2: the surface is wet, icy or snow-covered, or precipitation is falling. -/
def adverseSurface : Formula :=
  .or (.atom "env_wet_road" [] [])
      (.or (.atom "env_ice_or_snow" [] []) (.atom "env_precipitation" [] []))

/-- k2: twice the deceleration available, the condition selecting among the two bounds; each
    selection is the parameter added to itself, so the stopping model's `2a` carries no magnitude
    of this file's own, and the selection is made once in a comparison. -/
def twiceDeceleration : Term :=
  .cond adverseSurface
    (.add pSpeedStoppingDecelerationAdverse pSpeedStoppingDecelerationAdverse)
    (.add pSpeedStoppingDecelerationDry pSpeedStoppingDecelerationDry)

/-- k2: the width available — the lane's where it is narrower than the reference width, else the
    reference width. -/
def widthAvailable : Term :=
  .cond (.cmp laneWidth .lt pReferenceLaneWidth) laneWidth pReferenceLaneWidth

/-- k2: the subject could halt within the clear distance `d`, at the available deceleration and
    after the reaction time, the bound reduced in the ratio of the width available to the reference
    width. The requirement `v·T·k + v²/(2a) ≤ d·k²` with `k` that ratio, multiplied by `2a·W²` and
    the reaction term carried over to the other side — `v²·W² ≤ 2a·wEff·(d·wEff − v·T·W)` — so that
    no measured quantity stands in a divisor, no factor of two stands as a literal, and each
    selection among bounds is made once in the comparison. -/
def couldHaltWithin (d : Term) : Formula :=
  .cmp (.mul (.mul speed speed) (.mul pReferenceLaneWidth pReferenceLaneWidth))
       .le
       (.mul (.mul twiceDeceleration widthAvailable)
             (.sub (.mul d widthAvailable)
                   (.mul (.mul speed pSpeedReactionTime) pReferenceLaneWidth)))

/-- k2: the curvature of the way at the subject's place imposes no more than the admissible
    lateral acceleration at the subject's speed, that bound reduced in the same ratio:
    `v²·κ ≤ A·k²`, multiplied by `W²`. -/
def withinCurvatureBound : Formula :=
  .cmp (.mul (.mul (.mul speed speed) curvature) (.mul pReferenceLaneWidth pReferenceLaneWidth))
       .le
       (.mul pLateralAccelerationMax (.mul widthAvailable widthAvailable))

/-- k2: the subject could halt within the gap to every road user it follows in its own line of
    travel — the bound at the nearest of them, stated at each. -/
def couldHaltBehindTraffic : Formula :=
  .forallUser "other"
    (.implies
      (.and (.not (.same vOther vSubject))
            (.derived "drv_interaction_following_vehicle_ahead" [vSubject, vOther]
              [pSameDirectionTolerance, pMotionSpeedTolerance]))
      (couldHaltWithin gapAhead))

/-- k2: the subject's speed is at or below the reasonable-speed bound on that lane of that way: it
    could halt within the clear distance ahead — the least of the sight distance along the way, the
    visibility distance and the gap to the traffic it follows — and the bend imposes no more than
    the admissible lateral acceleration. -/
def reasonableSpeedThere : Formula :=
  .and (couldHaltWithin sightAlongWay)
    (.and (couldHaltWithin visibility)
      (.and couldHaltBehindTraffic withinCurvatureBound))

/-- Applicability: the subject is a vehicle in motion on a highway. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "highway") "way" occupiesWay) inMotion

/-- Obligation: k1 (obligation): It is unlawful for any person to drive or operate a vehicle of any kind or character at:; k2 (standard): A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "way"
    (.implies occupiesWay
      (.forallRegion (.lit "lane") "lane"
        (.implies occupiesLaneOfWay reasonableSpeedThere)))

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
      [ { standard := "A rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions"
          concepts := ["drv.interaction.following_vehicle_ahead", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.occupies", "rel.surface_gap", "st.curvature", "st.highway", "st.lane", "st.lane_width", "st.on_way", "st.sight_along_way"]
          params := ["p.speed_reaction_time", "p.speed_stopping_deceleration_dry", "p.speed_stopping_deceleration_adverse", "p.reference_lane_width", "p.lateral_acceleration_max", "p.same_direction_tolerance", "p.motion_speed_tolerance"]
          convention := "stopping-distance model with a side-friction bound, each factor read by its degree: the speed is unreasonable where it exceeds the lower of two bounds. The first is the speed from which the vehicle could halt within the clear distance ahead: that distance is the least of the longitudinal surface gap (rel.surface_gap) to the nearest road user it follows in its own line of travel (drv.interaction.following_vehicle_ahead over the road users present in the scene, whatever their class, with the alignment tolerance), the sight distance along the way it is on (st.sight_along_way) and the visibility distance (env.visibility), and the bound is the speed whose reaction distance over the reaction time (p.speed_reaction_time) plus braking distance at the available deceleration equals it; the available deceleration is p.speed_stopping_deceleration_dry, or p.speed_stopping_deceleration_adverse where the surface is wet, icy or snow-covered or precipitation is falling (env.wet_road, env.ice_or_snow, env.precipitation), a condition selecting among bounds. The second is the speed at which the roadway's curvature (st.curvature) would impose more than the admissible lateral acceleration (p.lateral_acceleration_max), speed squared times curvature being that acceleration. Both bounds are reduced in the ratio of the width available to the reference width where the lane the vehicle occupies (st.lane, st.lane_width) is narrower than p.reference_lane_width. Every magnitude - the gap, the sight distance, the visibility, the curvature and the width - enters the bound itself, so the bound moves as the magnitude moves"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "k2"
          why := "the curvature of the way and the width available are read on the lane the subject occupies on that way (`st.lane`, `st.lane_width`, `st.curvature`, with `rel.occupies` and `st.on_way`, the atoms the node claims for them; it claims no roadway region), and the bound is stated at each such lane: where the source maps no lane under the subject, the standard's width and curvature cannot be read and the bound is not stated at that observation."
          kind := "reading" }
      , { span := "k2"
          why := "\"the least of\" the three clear distances ahead is written as the halting bound taken at each of them in turn - the longitudinal body gap to the traffic followed, the sight distance along the way and the visibility distance - which is the bound at their least, and which stays decided by the others where one of them is unobserved."
          kind := "reading" }
      , { span := "k2"
          why := "\"the nearest road user it follows in its own line of travel\" is written as every road user the subject follows (`drv.interaction.following_vehicle_ahead` over the road users of the scene, whatever their class, with the alignment and motion tolerances), each with the longitudinal gap to it: the bound at the nearest of them is the strictest, so the bound at every one of them is that same requirement."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_600_1a

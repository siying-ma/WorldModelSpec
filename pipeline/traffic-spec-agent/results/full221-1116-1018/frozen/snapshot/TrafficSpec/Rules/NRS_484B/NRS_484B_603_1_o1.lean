/-
  NRS_484B_603_1_o1 — NRS-484B-603-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The fact that the speed of a vehicle is lower than the prescribed limits
    s2 (obligation): does not relieve
    s3 (subject): a driver
    s4 (standard): from the duty to decrease speed
    s5 (trigger): when approaching and crossing an intersection,
    s6 (trigger): when approaching and going around a curve,
    s7 (trigger): when approaching a hill crest,
    s8 (trigger): when traveling upon any narrow or winding highway,
    s9 (standard): or when special hazards exist or may exist
    s10 (condition): with respect to pedestrians or other traffic,
    s11 (condition): or by reason of weather
    s12 (standard): or other highway conditions,
    s13 (sibling): and speed must be decreased
    s14 (sibling): as may be necessary to avoid colliding
    s15 (sibling): with any person, vehicle or other conveyance
    s16 (sibling): on or entering a highway
    s17 (sibling): in compliance with legal requirements and the duty of all persons to use due care.

  Elements (span → atoms, derived):
    s2: atoms ['kin.speed'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s6: atoms ['rel.occupies', 'st.roadway', 'st.curvature', 'kin.path_length'], derived []
    s7: atoms ['kin.position', 'kin.velocity', 'st.crest', 'st.region_geometry'], derived []
    s8: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.lane', 'st.lane_width', 'st.curvature'], derived []
    s10: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.roadway', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []
    s11: atoms ['env.precipitation', 'env.wet_road', 'env.ice_or_snow', 'env.visibility', 'st.sight_distance'], derived []

  How each is written:
    s3: binder class `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s5: (a) the subject occupies an intersection, or occupies a travel region whose `st_lane_enters`
        is an intersection.
    s6: (b) `within .path p.curve_approach_reach subject` of "the subject occupies a roadway whose
        curvature exceeds p.curvature_resolution"; the window ahead includes the judged observation,
        so going around the curve and approaching it are one window.
    s7: (c) a crest within p.crest_near_reach of the subject's body (st_region_geometry_distance)
        whose reference point lies ahead of the velocity: (crest − position)·velocity > 0.
    s8: (d) the subject occupies a lane on a highway (st_on_way) whose width is at or below
        p.narrow_lane_width, or the roadway it occupies has curvature above the resolution.
    s10/s9: (e) a pedestrian (aggregate DEF-NRS-484A-165::pedestrian) occupies the roadway the
        subject occupies [narrowing on s9: the roadway is the subject's, which anchors the
        pedestrian]; or a traffic road user (DEF-NRS-484A-285::traffic) other than the subject
        approaches within p.conflict_horizon to a centre distance at or below
        p.conflict_centre_clearance.
    s11: (f) precipitation, wet road, ice or snow, or visibility below the sight distance of the
        roadway the subject occupies.
    s12: (g) an obstruction whose ground distance from the body is at or below D, or a temporary
        traffic-control device governing a travel region the subject occupies.
    s4/s2: the obligation. D = v·T + v²/(2a), 2a chosen by `Term.cond` among the reading's
        decelerations (ice/snow, else wet or precipitation, else dry), so the divisor is a reading
        parameter and reads no measured atom. D ≤ sight distance of each roadway
        occupied [narrowing on s4: the subject's place is the roadway it occupies], D ≤ visibility,
        v²·κ ≤ p.curve_lateral_accel_max where κ > p.curvature_resolution, D ≤ surface gap to each
        road user in predicted conflict.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_603_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pCrestNearReach : Term := .param "p.crest_near_reach"
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pCurveApproachReach : Term := .param "p.curve_approach_reach"
def pCurveLateralAccelMax : Term := .param "p.curve_lateral_accel_max"
def pDriverReactionTime : Term := .param "p.driver_reaction_time"
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pNarrowLaneWidth : Term := .param "p.narrow_lane_width"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Shared pieces
-- ---------------------------------------------------------------------------------------------

/-- `x` occupies the region bound to `r` (rel.occupies). -/
def occ (x : Arg) (r : String) : Formula := .atom "rel_occupies" [x, .var r] []

/-- s2: the subject's speed (kin.speed). -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- s4 / s11: the surface the deceleration is chosen by. -/
def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
def wetOrFalling : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

/-- s4: twice the surface deceleration, 2a — ice/snow, else wet or precipitation, else dry. Only
    reading parameters are selected, so the divisor below reads no measured atom. -/
def twiceDecel : Term :=
  .cond iceOrSnow (.add pFollowingDecelIce pFollowingDecelIce)
    (.cond wetOrFalling (.add pFollowingDecelWet pFollowingDecelWet)
      (.add pFollowingDecelDry pFollowingDecelDry))

/-- s4: the stopping distance D = v·T + v²/(2a). -/
def stopDist : Term :=
  .add (.mul speed pDriverReactionTime) (.div (.mul speed speed) twiceDecel)

/-- s4: the stopping distance D is at or below the length `L`. -/
def stopsWithin (L : Term) : Formula := .cmp stopDist .le L

/-- s6 / s8: the subject occupies a roadway (bound to `rd`) whose curvature exceeds the map's
    resolution. -/
def curveHere (rd : String) : Formula :=
  .existsRegion (.lit "roadway") rd
    (.and (occ vSubject rd) (.cmp (.measure "st_curvature" [.var rd]) .gt pCurvatureResolution))

/-- s10 / s9: road user `o` (other than the subject, of the traffic aggregate) is in predicted
    conflict: its centre comes within p.conflict_centre_clearance of the subject's within
    p.conflict_horizon under constant velocities. -/
def conflict (o : String) : Formula :=
  .and (.not (.same (.var o) vSubject))
    (.and (.atom "ru_aggregate" [.var o, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.derived "prim_closest_approach_within" [vSubject, .var o] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var o] [pConflictHorizon])
          .le pConflictCentreClearance)))

-- ---------------------------------------------------------------------------------------------
-- Class
-- ---------------------------------------------------------------------------------------------

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- Applicability: conditions (a)–(g) of the record
-- ---------------------------------------------------------------------------------------------

/-- (a) s5 crossing: the subject occupies an intersection. -/
def inIntersection : Formula :=
  .existsRegion (.lit "intersection") "ixIn" (occ vSubject "ixIn")

/-- (a) s5 approaching: the subject occupies a travel region whose entrance end is an intersection. -/
def approachingIntersection : Formula :=
  .existsRegion (.lit "travel_region") "trApp"
    (.and (occ vSubject "trApp")
      (.existsRegion (.lit "intersection") "ixApp" (.atom "st_lane_enters" [.var "trApp", .var "ixApp"] [])))

/-- (b) s6: going around a curve here or reaching one within p.curve_approach_reach of path ahead
    (the window ahead includes the judged observation). -/
def curve : Formula := .within .path pCurveApproachReach "subject" (curveHere "rdCurve")

/-- (c) s7: a crest whose reference point lies ahead of the subject's velocity, its ground distance
    from the subject's body within p.crest_near_reach. -/
def crestAhead : Formula :=
  .existsRegion (.lit "crest") "crest"
    (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "crest"]) .le pCrestNearReach)
      -- (crest − position)·velocity > 0, written Δx·vx > −(Δy·vy) so both sides carry one unit
      (.cmp
        (.mul (.sub (.measure "st_region_geometry" [.var "crest", .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"]))
              (.measure "kin_velocity" [vSubject, .lit "x"]))
        .gt
        (.neg (.mul (.sub (.measure "st_region_geometry" [.var "crest", .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"]))
                    (.measure "kin_velocity" [vSubject, .lit "y"])))))

/-- (d) s8: the subject occupies a lane lying on a highway, and the lane is narrow or the roadway
    at its place winds. -/
def narrowOrWindingHighway : Formula :=
  .existsRegion (.lit "lane") "laneHw"
    (.and (occ vSubject "laneHw")
      (.and (.existsRegion (.lit "highway") "hw" (.atom "st_on_way" [.var "laneHw", .var "hw"] []))
        (.or (.cmp (.measure "st_lane_width" [.var "laneHw"]) .le pNarrowLaneWidth)
             (curveHere "rdWind"))))

/-- (e) s10 / s9: a pedestrian occupies the roadway the subject occupies. -/
def pedestrianOnRoadway : Formula :=
  .existsRegion (.lit "roadway") "rdPed"
    (.and (occ vSubject "rdPed")
      (.existsUser "ped"
        (.and (.atom "ru_aggregate" [.var "ped", .lit "DEF-NRS-484A-165::pedestrian"] [])
              (occ (.var "ped") "rdPed"))))

/-- (e) s10 / s9: some traffic road user in predicted conflict with the subject. -/
def conflictExists : Formula := .existsUser "other" (conflict "other")

/-- (f) s11: rain or snow falls, the road is wet, icy or snow-covered, or the visibility is below
    the sight distance at the subject's place. -/
def weather : Formula :=
  .or (.atom "env_precipitation" [] [])
    (.or (.atom "env_wet_road" [] [])
      (.or iceOrSnow
        (.existsRegion (.lit "roadway") "rdVis"
          (.and (occ vSubject "rdVis")
            (.cmp (.measure "env_visibility" []) .lt (.measure "st_sight_distance" [.var "rdVis"]))))))

/-- (g) s12: an obstruction within the stopping distance D of the subject's body. -/
def obstructionNear : Formula :=
  .existsRegion (.lit "obstruction") "obst"
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "obst"]) .le stopDist)

/-- (g) s12: a temporary traffic-control device governs a travel region the subject occupies. -/
def temporaryControl : Formula :=
  .existsDevice (.lit "temporary_traffic_control") "ttc"
    (.existsRegion (.lit "travel_region") "trTtc"
      (.and (occ vSubject "trTtc") (.atom "dev_governs" [.var "ttc", .var "trTtc"] [])))

/-- Applicability: s1 (condition): The fact that the speed of a vehicle is lower than the prescribed limits; s5 (trigger): when approaching and crossing an intersection,; s6 (trigger): when approaching and going around a curve,; s7 (trigger): when approaching a hill crest,; s8 (trigger): when traveling upon any narrow or winding highway,; s10 (condition): with respect to pedestrians or other traffic,; s11 (condition): or by reason of weather -/
def applicability : Formula :=
  .or inIntersection
    (.or approachingIntersection
      (.or curve
        (.or crestAhead
          (.or narrowOrWindingHighway
            (.or pedestrianOnRoadway
              (.or conflictExists
                (.or weather
                  (.or obstructionNear temporaryControl))))))))

-- ---------------------------------------------------------------------------------------------
-- Obligation
-- ---------------------------------------------------------------------------------------------

/-- s4: D at or below the sight distance of every roadway the subject occupies. -/
def withinSight : Formula :=
  .forallRegion (.lit "roadway") "rdSight"
    (.implies (occ vSubject "rdSight") (stopsWithin (.measure "st_sight_distance" [.var "rdSight"])))

/-- s4: D at or below the visibility. -/
def withinVisibility : Formula := stopsWithin (.measure "env_visibility" [])

/-- s4: on a bend (curvature above the resolution) v²·curvature at or below
    p.curve_lateral_accel_max, for every roadway the subject occupies. -/
def curveSpeed : Formula :=
  .forallRegion (.lit "roadway") "rdBend"
    (.implies (occ vSubject "rdBend")
      (.implies (.cmp (.measure "st_curvature" [.var "rdBend"]) .gt pCurvatureResolution)
        (.cmp (.mul (.mul speed speed) (.measure "st_curvature" [.var "rdBend"])) .le pCurveLateralAccelMax)))

/-- s4: for every road user in predicted conflict, D at or below the surface gap to it. -/
def withinGap : Formula :=
  .forallUser "conf"
    (.implies (conflict "conf")
      (stopsWithin (.measure "rel_surface_gap" [vSubject, .var "conf"])))

/-- Obligation: s2 (obligation): does not relieve; s4 (standard): from the duty to decrease speed; s9 (standard): or when special hazards exist or may exist; s12 (standard): or other highway conditions, -/
def obligation : Formula :=
  .and withinSight (.and withinVisibility (.and curveSpeed withinGap))

def rule : Rule :=
  { id := "NRS_484B_603_1_o1"
    laws := ["NRS-484B-603-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "special hazards by reason of other highway conditions (the catch-all of the standard)"
          concepts := ["dev.governs", "dev.temporary_traffic_control", "kin.speed", "rel.occupies", "st.obstruction", "st.region_geometry", "st.travel_region"]
          params := ["p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "AASHTO stopping-distance model: a highway condition is a special hazard where an obstruction (st.obstruction, 'a physical object on or beside the roadway that is not a road user') lies within the subject's stopping distance D (the s4 model) of its body, the ground distance read through st.region_geometry, or where works or a closure are marked by dev.temporary_traffic_control ('cones, barricades, temporary signs and flashers marking works, a closure or an obstruction') governing (dev.governs) a travel region the subject occupies (rel.occupies, st.travel_region)."
          surrogate := true }
      , { standard := "the duty to decrease speed: the speed to which the driver must come where a condition of the line holds"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed", "rel.surface_gap", "st.curvature", "st.sight_distance"]
          params := ["p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice", "p.curve_lateral_accel_max"]
          convention := "AASHTO stopping-sight-distance model and curve side-friction model: the stopping distance D = v times p.driver_reaction_time plus v squared over twice the surface deceleration (p.following_decel_ice on ice or snow, else p.following_decel_wet on a wet road or in precipitation, else p.following_decel_dry) must not exceed the sight distance at the subject's place, nor the visibility where it is shorter, nor the surface gap to a road user in predicted conflict; on a bend v squared times the curvature must not exceed p.curve_lateral_accel_max. The bound moves with the speed, the surface, the sight, the visibility, the curvature and the gap."
          surrogate := true }
      , { standard := "special hazards exist or may exist"
          concepts := ["env.visibility", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.region_geometry", "st.roadway", "st.sight_distance"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "Traffic-conflict technique: a hazard exists with respect to a road user whose centre comes within p.conflict_centre_clearance of the subject's within p.conflict_horizon under constant velocities; a hazard may exist where a pedestrian occupies a roadway; by reason of weather where rain or snow falls, the road is wet, icy or snow-covered, or the visibility is below the sight distance at the subject's place; by reason of highway conditions where an obstruction lies within the subject's stopping distance (the s4 model) or a temporary traffic-control device governs the subject's region."
          surrogate := true } ]
    residues := ["The words say a speed below the posted limits does not relieve the duty; the duty is the same whether the speed is below or above the limits, so the clause imposes no observable condition."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s9"
          why := "The pedestrian whose presence on a roadway is a hazard that may exist is read on the roadway the subject occupies, the region that ties the pedestrian to the subject."
          kind := "reading" }
      , { span := "s4"
          why := "The sight distance at the subject's place is read from every roadway the subject occupies; the stopping distance must be within each."
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_603_1_o1

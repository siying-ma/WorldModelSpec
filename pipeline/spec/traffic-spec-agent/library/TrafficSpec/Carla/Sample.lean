/-
  TrafficSpec.Carla.Sample
  A CARLA-shaped smoke trace.

  Hand-authored (not captured), but built with `Core/Builders.lean` so it is
  structurally indistinguishable from adapter output: the same entity types,
  the same `{base_class}_{n}` naming, the same two-hop
  entity → lane → road → junction structure, one proximity band per pair, the
  direct/side angular split, and ego dynamics as decimal strings.

  Every rule is evaluated against this trace by `tools/check_spec.py`. The
  verdict is informational; the **grounding count** is what matters — zero means
  the rule cannot fire on realistic scene graphs, which is nearly always a bug
  in the specification rather than a property of the world.

  Scenario: ego follows `car_0` along a lane that leads into a junction, closes
  to within 2–4 m, brakes, then both proceed into the junction. `car_1` travels
  the opposing lane for part of the run.
-/
import TrafficSpec.Core.Builders

namespace TrafficSpec.Carla

open TrafficSpec

-- Entity ids: actors 1–4, lanes 10–12, off road 13, roads 20–21, junction 30,
-- traffic control 40–42.
private def laneEgo    : Nat := 10   -- "Lane 9_-1"
private def laneOpp    : Nat := 11   -- "Lane 9_+1", opposes laneEgo
private def laneJunc   : Nat := 12   -- "Lane 12_-1", inside the junction
private def offRoad    : Nat := 13   -- "Off Road", where the pedestrian sits
private def roadMain   : Nat := 20   -- "Road 9"
private def roadJunc   : Nat := 21   -- "Road 12"
private def junction   : Nat := 30   -- "Junction 5"
private def signal     : Nat := 40   -- traffic light governing the approach
private def limitSign  : Nat := 41   -- "traffic.speed_limit.50" sign actor
private def limitMark  : Nat := 42   -- OpenDRIVE speed-limit landmark, 50 km/h

/-- Road structure and traffic control. Static across the run, exactly as the
    adapter re-emits it every frame.

    The junction is signal-controlled: the traffic light carries `controls` edges
    to both lanes it governs, which is the only association the generator emits
    for a signal — note the deliberate absence of any proximity band to entity
    `signal`, `limitSign` or `limitMark`, because the generator never produces
    one for a sign or a signal. The posted limit appears twice, as the map's
    OpenDRIVE landmark (`mayAffect`, authoritative) and as the sign actor whose
    bounding box overlaps the lane (`isIn`, weak).

    There is no stop sign here, so a stop-sign rule will report `CARLA 0`
    groundings and must rely on its own scenarios. -/
private def structureEntities : List Entity :=
  [ mkLane laneEgo  "Lane 9_-1"
  , mkLane laneOpp  "Lane 9_+1"
  , mkLane laneJunc "Lane 12_-1"
  , mkOffRoad offRoad
  , mkRoad roadMain "Road 9"
  , mkRoad roadJunc "Road 12"
  , mkJunction junction "Junction 5"
  , mkSpeedLimitSign limitSign "speed_limit_0" "50"
  , mkSpeedLimitLandmark limitMark "landmark_OpenDRIVE_274_0" "50" ]

private def structureRels : List Relation :=
  [ mkRel laneEgo  .isIn roadMain
  , mkRel laneOpp  .isIn roadMain
  , mkRel laneJunc .isIn roadJunc
  , mkRel roadJunc .isIn junction
  , mkRel laneEgo  .opposes laneOpp
  , mkRel laneOpp  .opposes laneEgo
  , mkRel laneOpp  .toLeftOf laneEgo
  , mkRel laneEgo  .toRightOf laneOpp
  , mkRel laneEgo  .travelsTo laneJunc
  , mkRel signal   .controls laneEgo
  , mkRel signal   .controls laneJunc
  , mkRel limitMark .mayAffect laneEgo
  , mkRel limitSign .isIn laneEgo ]

/-- One frame of the run. `band` is the single proximity label the generator
    emits for the ego/lead pair at this distance; both orientations of each
    angular edge are present, as in a capture that enumerates ordered pairs.

    `lightState` is the signal's colour this frame, and `atLight` mirrors
    `ego.is_at_traffic_light()`. `car_1` in the opposing lane is *mutually* in
    front of the ego, which is how the generator renders an oncoming pair.
    `walker_0` stands off the roadway, so it is `isIn` the `Off Road` node —
    the abstraction drops sidewalk nodes, so that is where a pedestrian lands. -/
private def mkFrame (egoSpeed egoAccel egoThrottle egoBrake : String)
    (band : RelLabel) (egoLane leadLane : Nat) (oncoming : Bool)
    (lightState : String) (atLight : String) (pedestrian : Bool) : Scene :=
  frame
    ( [ mkEgo 1 .car egoSpeed egoAccel egoThrottle egoBrake "0.0" "0.0" atLight
      , mkActor 2 "car_0" .car none (some "vehicle.tesla.model3")
      , mkTrafficLight signal "traffic_light_0" lightState ]
      ++ (if oncoming then [mkActor 3 "car_1" .car] else [])
      ++ (if pedestrian then [mkActor 4 "walker_0" .pedestrian] else [])
      ++ structureEntities )
    ( structureRels
      ++ [ mkRel 1 .isIn egoLane, mkRel 2 .isIn leadLane ]
      ++ [ mkRel 1 band 2, mkRel 2 .inDFrontOf 1, mkRel 1 .atDRearOf 2 ]
      ++ (if oncoming then
            [ mkRel 3 .isIn laneOpp
            , mkRel 3 .visible 1
            , mkRel 3 .inSFrontOf 1
            , mkRel 1 .inSFrontOf 3 ]
          else [])
      ++ (if pedestrian then
            [ mkRel 4 .isIn offRoad
            , mkRel 4 .veryNear 1
            , mkRel 4 .inSFrontOf 1 ]
          else []) )

/-- The bundled smoke trace: 8 frames.

    * f0–f1 ego approaches `car_0` (16 m → 10 m)
    * f2–f4 ego closes to 4–7 m then 2–4 m and brakes
    * f5     gap reopens as `car_0` enters the junction lane
    * f6–f7 ego follows into the junction
    * f2–f5 `car_1` is oncoming in the opposing lane
    * f0–f4 `walker_0` stands off the roadway beside the approach
    * f0–f6 the signal is green; it turns amber at f7, with the ego already
             inside the junction, so the run is lawful throughout
    * f4–f7 the ego is inside the signal's trigger volume
             (`at_traffic_light`) -/
def sampleTrace : Trace :=
  [ mkFrame "8.0"  "0.5"  "0.4" "0.0" .near          laneEgo  laneEgo  false "Green"  "false" true
  , mkFrame "8.52" "0.34" "0.4" "0.0" .veryNear      laneEgo  laneEgo  false "Green"  "false" true
  , mkFrame "9.04" "0.2"  "0.3" "0.0" .superNear     laneEgo  laneEgo  true  "Green"  "false" true
  , mkFrame "9.21" "-1.5" "0.0" "0.6" .nearCollision laneEgo  laneEgo  true  "Green"  "false" true
  , mkFrame "5.03" "-4.2" "0.0" "0.8" .nearCollision laneEgo  laneEgo  true  "Green"  "true"  true
  , mkFrame "4.11" "-0.9" "0.1" "0.3" .superNear     laneEgo  laneJunc true  "Green"  "true"  false
  , mkFrame "6.02" "1.9"  "0.5" "0.0" .veryNear      laneEgo  laneJunc false "Green"  "true"  false
  , mkFrame "7.48" "1.46" "0.5" "0.0" .visible       laneJunc laneJunc false "Yellow" "true"  false ]

end TrafficSpec.Carla

/-
  TrafficSpec.Core.Builders
  Constructors for writing scenario traces by hand.

  Scenario traces must look like adapter output, or a rule can pass its
  acceptance tests and still never fire on real data. These builders emit the
  attribute sets the CARLA adapter emits — `name`/`sem_class` on everything,
  `special_class` and the five dynamics channels on the ego vehicle — so a
  hand-written trace and a captured one are indistinguishable to a predicate.
-/
import TrafficSpec.Core.Scene

namespace TrafficSpec

/-- Entity id from a raw number. -/
def eid (n : Nat) : EntityId := ⟨n⟩

/-- Fully explicit entity. Prefer the specific builders below. -/
def mkEntity (id : Nat) (ty : EntityType)
    (attrs : List (String × String) := []) : Entity :=
  { id := ⟨id⟩, type := ty, attrs := attrs }

/-- Attach or override one attribute. Prepends, and `Scene.getAttr` /
    `Scene.hasAttr` read the first match, so this shadows any existing value.

    Use it for the optional per-actor channels a builder does not take as a
    parameter — the vehicle light states, for instance:
    `(mkActor 2 "car_0" .car).withAttr "light_brake" "true"`. -/
def Entity.withAttr (e : Entity) (k v : String) : Entity :=
  { e with attrs := (k, v) :: e.attrs }

/-- Attach or override several attributes. -/
def Entity.withAttrs (e : Entity) (kvs : List (String × String)) : Entity :=
  { e with attrs := kvs ++ e.attrs }

/-- The `base_class` pair for a type, empty when the generator reports none. -/
private def baseClassAttr (ty : EntityType) : List (String × String) :=
  match ty.baseClass with
  | some c => [("base_class", c)]
  | none   => []

/-- A relation. Reads "`src` is `lbl` `tgt`" — see `Core/Vocab.lean` §5. -/
def mkRel (src : Nat) (lbl : RelLabel) (tgt : Nat) : Relation :=
  { src := ⟨src⟩, label := lbl, tgt := ⟨tgt⟩ }

/-- The ego vehicle, with the channels only the ego carries.

    `speed`/`accel`/`throttle`/`brake`/`steer` are decimal strings exactly as
    `str(float)` produces them: speed m/s, accel m/s², throttle and brake 0..1,
    steer -1..1. The trailing channels come from the same source — `yawRate` is
    `carla_ang_vel_z` in deg/s, `atTrafficLight` is
    `carla_affected_by_traffic_light` (`ego.is_at_traffic_light()`), and
    `handBrake`/`reverse` are the control flags, all rendered `"true"`/`"false"`.

    No other actor carries any of these: `copy_carla_actor_state` and
    `copy_carla_control` are called for the ego node only. -/
def mkEgo (id : Nat) (ty : EntityType := .car)
    (speed : String := "0.0") (accel : String := "0.0")
    (throttle : String := "0.0") (brake : String := "0.0")
    (steer : String := "0.0") (yawRate : String := "0.0")
    (atTrafficLight : String := "false") (handBrake : String := "false")
    (reverse : String := "false") : Entity :=
  { id := ⟨id⟩, type := ty,
    attrs := [ ("name", "ego"), ("sem_class", "ego"), ("special_class", "ego")
             , ("base_class", "ego")
             , ("speed", speed), ("accel", accel), ("throttle", throttle)
             , ("brake", brake), ("steer", steer), ("yaw_rate", yawRate)
             , ("at_traffic_light", atTrafficLight)
             , ("hand_brake", handBrake), ("reverse", reverse) ] }

/-- A non-ego actor. `name` follows the generator's `{base_class}_{n}` scheme,
    e.g. `"car_0"`; `semClass` is the CARLA blueprint id the generator copies
    into `sem_class` (e.g. `"vehicle.tesla.model3"`), and defaults to the name
    when a scenario does not care which blueprint it was.

    Non-ego actors carry no dynamics channels — that is a property of the data
    source, not an omission here. Their light states *are* available: add them
    with `Entity.withAttr` (`light_brake`, `light_left_blinker`,
    `light_right_blinker`, …), which is the only evidence a specification can
    have that another vehicle is braking or signalling. -/
def mkActor (id : Nat) (name : String) (ty : EntityType := .car)
    (special : Option String := none) (semClass : Option String := none) : Entity :=
  { id := ⟨id⟩, type := ty,
    attrs := [("name", name), ("sem_class", semClass.getD name)]
             ++ baseClassAttr ty
             ++ (match special with
                 | some c => [("special_class", c)]
                 | none   => []) }

/-- An emergency vehicle (police, fire, ambulance).

    Mind the base class: CARLA's ambulance is `vehicle.ford.ambulance`, whose
    base type is **van**, and no proximity or angular edge is ever emitted for a
    van (see `Core/Scene.lean`, `RelLabel`). A rule that needs a distance to an
    emergency vehicle can only ground on the police car (`car`) and the
    firetruck (`truck`). -/
def mkEmergency (id : Nat) (name : String) (ty : EntityType := .car) : Entity :=
  mkActor id name ty (some "emergency")

/-- A lane node, named `Lane <road>_<±lane>`. The OpenDRIVE road and lane ids
    are re-derived from the name so a hand-written lane exposes the same
    `road_id` / `lane_id` attributes as a captured one. -/
def mkLane (id : Nat) (name : String) : Entity :=
  { id := ⟨id⟩, type := .lane,
    attrs := [("name", name), ("sem_class", "Driving")]
             ++ (match parseLaneName name with
                 | some (road, lane) => [("road_id", road), ("lane_id", lane)]
                 | none              => []) }

/-- A road node, named `Road <n>`. -/
def mkRoad (id : Nat) (name : String) : Entity :=
  { id := ⟨id⟩, type := .road,
    attrs := [("name", name)]
             ++ (match parseNodeId "Road" name with
                 | some r => [("road_id", r)]
                 | none   => []) }

/-- A junction node, named `Junction <n>`. -/
def mkJunction (id : Nat) (name : String) : Entity :=
  { id := ⟨id⟩, type := .junction,
    attrs := [("name", name)]
             ++ (match parseNodeId "Junction" name with
                 | some j => [("junction_id", j)]
                 | none   => []) }

/-- The singleton `Off Road` node the adapter creates for entities in no lane. -/
def mkOffRoad (id : Nat) : Entity :=
  { id := ⟨id⟩, type := .offRoad, attrs := [("name", "Off Road")] }

----------------------------------------------------------------------
-- Traffic-control devices and signs
----------------------------------------------------------------------

/-- A traffic light. `state` is `str(carla.TrafficLightState)`, so one of
    `"Red"`, `"Yellow"`, `"Green"`, `"Off"`, `"Unknown"`.

    Associate it with the lanes it governs using `.controls` edges — that is the
    `controlsTrafficOf` relation the generator builds from the light's affected
    waypoints. There is never a proximity edge to a signal, so `controls` is the
    only way to say "the signal facing this vehicle". -/
def mkTrafficLight (id : Nat) (name : String) (state : String := "Red") : Entity :=
  { id := ⟨id⟩, type := .trafficLight,
    attrs := [ ("name", name), ("sem_class", "traffic.traffic_light")
             , ("base_class", "traffic_light"), ("light_state", state) ] }

/-- A stop sign. Also carries `.controls` edges, built from its trigger volume. -/
def mkStopSign (id : Nat) (name : String) : Entity :=
  { id := ⟨id⟩, type := .stopSign,
    attrs := [ ("name", name), ("sem_class", "traffic.stop")
             , ("base_class", "stop_sign") ] }

/-- A posted speed-limit sign. CARLA spells the value in the blueprint id
    (`traffic.speed_limit.30`), which the adapter also lifts into
    `posted_limit_kph`.

    Unlike a light or a stop sign it gets **no** `controls` edge; it is attached
    to lanes only by bounding-box overlap (`isIn`), which is a weak association.
    For the authoritative posted limit prefer the OpenDRIVE landmark. -/
def mkSpeedLimitSign (id : Nat) (name : String) (kph : String) : Entity :=
  { id := ⟨id⟩, type := .speedLimitSign,
    attrs := [ ("name", name), ("sem_class", "traffic.speed_limit." ++ kph)
             , ("base_class", "speed_limit"), ("posted_limit_kph", kph) ] }

/-- An OpenDRIVE landmark: the map's own record of a regulatory sign, linked to
    the lanes it applies to by `.mayAffect`.

    `landmarkType` is the OpenDRIVE type code as a string — `"274"` is a speed
    limit (with the value in km/h in `landmarkValue`), `"206"` a stop, `"205"` a
    give way. `country` is usually `"OpenDRIVE"` in the shipped towns. -/
def mkLandmark (id : Nat) (name : String) (landmarkType : String)
    (value : String := "") (unit : String := "") (subType : String := "")
    (country : String := "OpenDRIVE") (text : String := "") : Entity :=
  { id := ⟨id⟩, type := .landmark,
    attrs := [ ("name", name)
             , ("sem_class", "landmark_" ++ country ++ "_" ++ landmarkType
                             ++ "_" ++ subType)
             , ("base_class", "landmark_" ++ country ++ "_" ++ landmarkType
                              ++ "_" ++ subType)
             , ("landmark_country", country)
             , ("landmark_type", landmarkType)
             , ("landmark_sub_type", subType)
             , ("landmark_value", value)
             , ("landmark_unit", unit)
             , ("landmark_text", text) ] }

/-- A speed-limit landmark: OpenDRIVE type `274`, value in km/h. -/
def mkSpeedLimitLandmark (id : Nat) (name : String) (kph : String) : Entity :=
  mkLandmark id name "274" kph "km/h"

/-- A frame. -/
def frame (entities : List Entity) (relations : List Relation) : Scene :=
  { entities := entities, relations := relations }

end TrafficSpec

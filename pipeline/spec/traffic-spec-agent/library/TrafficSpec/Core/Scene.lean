/-
  TrafficSpec.Core.Scene
  CARLA scene graphs: entities, relations, scenes, finite traces.

  Structure follows scene-flow-spec-lean (`SceneFlowSpec/Scene.lean`).
  The *vocabulary* is transcribed from the CARLA scene-graph generator itself —
  `carla_sgg/sgg.py` (the base graph) and `carla_sgg/sgg_abstractor.py`
  (`process_to_junction_rsv`, the abstraction this repository consumes) — not
  from the reference Lean project's lossy adapter. Every constructor here
  corresponds to something the generator can emit.

  See `carla/schema.json` for the full contract, including the attribute keys,
  the pairs proximity edges are emitted for, and what is genuinely absent.
-/

namespace TrafficSpec

/-! ## Time base

The trace carries no clock: `Scene` is one saved scene-graph frame and nothing
records when it was captured. The reference capture (`capture_sensor_data.py`)
runs the simulator with `fixed_delta_seconds = 1/20`, so consecutive frames of a
capture that saved every tick are 50 ms apart. A statutory duration therefore
becomes a **frame count** — state the assumed rate whenever you do that. -/

/-- Frames per second of the reference capture (`capture_sensor_data.py`,
    `FPS = 20`). -/
def captureHz : Nat := 20

/-- Whole seconds as a frame count at the reference capture rate:
    `secondsToFrames 1 = 20`. Use this instead of writing a bare number, so the
    assumed rate is visible in the rule. -/
def secondsToFrames (secs : Nat) : Nat := secs * captureHz

/-- Entity types in the RSV abstraction.

    Actor types are the SGG *base classes* returned by
    `carla_sgg/actors.py::get_base_type`; road structure comes from CARLA's
    waypoint/OpenDRIVE model. Ego-ness is **not** a type — the ego vehicle
    carries `special_class = "ego"` (use `Pred.isEgo`), which is how the
    generator marks it.

    Do not extend this list: a type the generator never emits produces a
    specification that can never fire on real data. Conversely, two base classes
    the generator *does* emit are deliberately absent, because
    `process_to_junction_rsv` drops them: `Sidewalk` nodes (filtered out with
    the non-`Driving` semantic classes) and anything whose blueprint makes
    `get_base_type` return `none` (`traffic.unknown`, `static.prop`, and the
    `CityObjectLabel.*` background props). -/
inductive EntityType where
  -- actors (SGG base classes)
  | car
  | truck
  | van
  | bus
  | motorcycle
  | vehicle           -- `Vehicles` / unlabelled background vehicle, base class `vehicle`
  | bicycle
  | pedestrian        -- base class `person` (walkers)
  | trafficLight
  | stopSign
  | speedLimitSign    -- `traffic.speed_limit.*`, base class `speed_limit`
  | landmark          -- OpenDRIVE landmark, base class `landmark_<country>_<type>_<sub>`
  | junctionBoundary  -- only when the map was parsed with `parse_junction_boundaries`
  -- road structure
  | lane
  | road
  | junction
  | offRoad
  -- anything the adapter could not classify
  | other
  deriving DecidableEq, Repr, BEq, Inhabited

/-- Motorised road users. Quantify over this rather than a single type when a
    law says "vehicle"; the generator splits vehicles into six base classes plus
    a generic one for unlabelled background traffic.

    **Coverage trap.** Proximity and angular edges are emitted only for the
    ordered pairs listed in `DEFAULT_PROXIMITY_RELATIONS`, which names the base
    classes `person`, `bicycle`, `car`, `motorcycle`, `bus`, `truck` — and
    **not** `van` or `vehicle`. A rule whose antecedent needs a distance to a
    van (which is what CARLA calls its ambulance) never fires. See
    `carla/schema.json` → `relation_coverage`. -/
def vehicleTypes : List EntityType :=
  [.car, .truck, .van, .bus, .motorcycle, .vehicle]

/-- Every base class the generator actually emits a proximity or angular edge
    for, transcribed from `sgg_abstractor.py::DEFAULT_PROXIMITY_RELATIONS`
    intersected with the range of `actors.py::get_base_type`.

    The table pairs `ego` with `person`, `bicycle`, `car`, `motorcycle`, `bus`,
    `truck` and a number of classes `get_base_type` never returns; `van`,
    `vehicle`, `speed_limit` and `landmark` are absent, and `traffic_light` /
    `stop_sign` are present only under names the equality test never matches
    (`traffic light` / `stop sign`, with a space). A binder that admits a type
    outside this list grounds on entities that can never carry a distance edge:
    the binding is trivially satisfied, cannot report a violation, and inflates
    the grounding count that says whether the law was engaged at all. -/
def proximityTypes : List EntityType :=
  [.pedestrian, .bicycle, .car, .motorcycle, .bus, .truck]

/-- The vehicle subset of `proximityTypes`.

    `bicycle` belongs here: the generator emits proximity edges for it, and a
    traffic code that says "vehicle" generally includes a cycle. Omitting it
    made a following-distance rule unable to convict a driver tailgating a
    cyclist — a missed violation, which is the failure direction that matters.
    `van` and `vehicle` are deliberately absent even though they are vehicles,
    because no distance to them exists; use `vehicleTypes` when the rule needs
    no distance. -/
def proximityVehicleTypes : List EntityType :=
  [.bicycle, .car, .truck, .bus, .motorcycle]

/-- Everything a traffic law is likely to call a "road user". -/
def roadUserTypes : List EntityType :=
  [.car, .truck, .van, .bus, .motorcycle, .vehicle, .bicycle, .pedestrian]

/-- Traffic-control devices that carry a `controls` edge to the lanes they
    govern: traffic lights and stop signs. Speed-limit signs and landmarks are
    *not* here — they associate to lanes by `mayAffect` or by bounding-box
    `isIn` overlap instead. -/
def controlDeviceTypes : List EntityType :=
  [.trafficLight, .stopSign]

/-- Every kind of roadside sign or signal the abstraction carries. -/
def signTypes : List EntityType :=
  [.trafficLight, .stopSign, .speedLimitSign, .landmark]

/-- Road-structure nodes, as opposed to actors. -/
def structureTypes : List EntityType :=
  [.lane, .road, .junction, .offRoad]

/-- The SGG base class the generator would report for this type — the inverse of
    the adapter's `classify`, so builders can stamp the `base_class` attribute
    without the caller repeating it.

    `none` for structure nodes (the abstraction builds those as `Node`s with no
    base class) and for landmarks, whose real base class is the composite
    `landmark_<country>_<type>_<sub_type>` and must be passed explicitly. -/
def EntityType.baseClass : EntityType → Option String
  | .car             => some "car"
  | .truck           => some "truck"
  | .van             => some "van"
  | .bus             => some "bus"
  | .motorcycle      => some "motorcycle"
  | .vehicle         => some "vehicle"
  | .bicycle         => some "bicycle"
  | .pedestrian      => some "person"
  | .trafficLight    => some "traffic_light"
  | .stopSign        => some "stop_sign"
  | .speedLimitSign  => some "speed_limit"
  | .landmark        => none
  | .junctionBoundary => some "junction_boundary"
  | .lane | .road | .junction | .offRoad | .other => none

/-- Unique identity of an entity within a trace. -/
structure EntityId where
  val : Nat
  deriving DecidableEq, Repr, BEq, Hashable, Inhabited

instance : ToString EntityId where
  toString eid := s!"e{eid.val}"

/-- An entity node in the scene graph. Attribute values are strings because
    that is how they arrive from the adapter; decimal-valued attributes are
    compared with `Pred.attrMilli*`, never by string equality. -/
structure Entity where
  id    : EntityId
  type  : EntityType
  attrs : List (String × String) := []
  deriving DecidableEq, Repr, BEq, Inhabited

/-- Edge labels in the RSV abstraction.

    Four groups, all emitted by `process_to_junction_rsv` (the labels come
    either from its own `label=` arguments or from the base graph's
    `dist_relationship`, which takes exactly the values `isIn`,
    `controlsTrafficOf` and `mayAffect`):

    * **semantic** — `isIn` (entity→lane, lane→road, road→junction),
      `opposes`, `travelsTo`, `laneChange` (all lane→lane).
    * **control** — `controls` (`controlsTrafficOf`: traffic light or stop sign
      → each lane it governs) and `mayAffect` (OpenDRIVE landmark → each lane it
      applies to). These are the *authoritative* sign-to-lane associations;
      `isIn` from a sign means only that its bounding box overlapped that lane.
    * **distance** — mutually exclusive proximity bands, listed here from
      *closest* to *farthest*. `safetyHazard` is the CLOSEST band (< 2 m) and
      `near` is the second-farthest (10–16 m): do not read these names as
      English. Prefer `Pred.withinMetres`.
    * **angular** — left/right, and direct/side × front/rear.

    **Coverage of the distance and angular edges.** They are emitted only for
    ordered pairs matching `DEFAULT_PROXIMITY_RELATIONS` /
    `DEFAULT_DIRECTIONAL_RELATIONS`, every entry of which pairs `ego` with
    another base class. Consequences a specification must respect:

    * there is **never** a proximity or angular edge between two non-ego actors,
      so a two-vehicle rule must bind the ego vehicle as one of the two;
    * the listed classes are `person`, `bicycle`, `car`, `motorcycle`, `bus`,
      `truck` — `van` and `vehicle` are absent, so distances to those never
      appear;
    * the list spells signals `traffic light` / `stop sign` while base classes
      are `traffic_light` / `stop_sign`, so the match always fails and there is
      **no proximity edge to any signal or sign at all**. Associate a sign with
      a lane through `controls` / `mayAffect`, never through distance.

    Between *lanes*, `opposes`, `toLeftOf` and `toRightOf` are emitted only for
    **adjacent lane ids of the same road** (`zip(sorted_lanes, sorted_lanes[1:])`),
    so two lanes separated by a third are unrelated by these labels. -/
inductive RelLabel where
  -- semantic
  | isIn
  | opposes
  | travelsTo
  | laneChange
  -- traffic control
  | controls        -- `controlsTrafficOf`: signal/stop sign → governed lane
  | mayAffect       -- OpenDRIVE landmark → lane it applies to
  -- distance bands, closest first
  | safetyHazard    -- < 2 m
  | nearCollision   -- 2–4 m
  | superNear       -- 4–7 m
  | veryNear        -- 7–10 m
  | near            -- 10–16 m
  | visible         -- 16–25 m
  -- angular
  | toLeftOf
  | toRightOf
  | inDFrontOf      -- direct front
  | inSFrontOf      -- side front
  | atDRearOf       -- direct rear
  | atSRearOf       -- side rear
  deriving DecidableEq, Repr, BEq, Inhabited

/-- Proximity bands, closest first, with their upper bound in metres. -/
def distanceBands : List (RelLabel × Nat) :=
  [(.safetyHazard, 2), (.nearCollision, 4), (.superNear, 7),
   (.veryNear, 10), (.near, 16), (.visible, 25)]

----------------------------------------------------------------------
-- Structural node naming
--
-- `process_to_junction_rsv` names structure nodes, and only the name carries
-- the OpenDRIVE identifiers — the abstraction drops the waypoint attributes
-- the ids came from:
--
--   lane      `Lane {road_id}_{'+' if lane_id > 0 else '-'}{|lane_id|}`
--   road      `Road {road_id}`
--   junction  `Junction {junction_id}`
--   off road  `Off Road`   (the single node for actors in no driving lane)
--
-- The helpers below recover those ids, and `Core/Builders.lean` uses them so a
-- hand-written scenario lane and a captured one expose the same attributes.
--
-- The lane-id **sign** is the OpenDRIVE convention: negative to the right of the
-- road's reference line, positive to the left, and all lanes carrying one
-- direction of travel share a sign.
--
-- It identifies which side of the *reference line* a lane was authored on, and
-- nothing more. It is NOT a side of the road in the sense a traffic statute
-- means: the lawful carriageway of a divided road, or a one-way street the map
-- numbers positively, is entirely positive-signed. A rule that reads "the right
-- half of the roadway" off this sign reports a violation on every frame of
-- lawful driving on such a road. Use `Pred.inRightmostLane`, which is relative
-- to the vehicle's own direction of travel — see `carla/schema.json` →
-- `partially_available.which_half_of_the_roadway`.
----------------------------------------------------------------------

/-- The road and lane id substrings of a lane node name:
    `parseLaneName "Lane 9_-1" = some ("9", "-1")`. Values are returned as
    written, so compare them with `Pred.attrMilli*` (which accepts a leading
    `+` or `-`) rather than by string equality. -/
def parseLaneName (n : String) : Option (String × String) :=
  match n.splitOn " " with
  | [kind, rest] =>
      if kind == "Lane" then
        match rest.splitOn "_" with
        | [road, lane] => some (road, lane)
        | _            => none
      else none
  | _ => none

/-- The id substring of a `"<kind> <id>"` structure node name:
    `parseNodeId "Road" "Road 9" = some "9"`. -/
def parseNodeId (kind : String) (n : String) : Option String :=
  match n.splitOn " " with
  | [k, v] => if k == kind then some v else none
  | _      => none

/-- A directed, labelled edge in the scene graph. -/
structure Relation where
  src   : EntityId
  label : RelLabel
  tgt   : EntityId
  deriving DecidableEq, Repr, BEq

/-- A scene graph: one frame of the driving world. -/
structure Scene where
  entities  : List Entity
  relations : List Relation
  deriving Repr

instance : Inhabited Scene where
  default := ⟨[], []⟩

/-- A finite trace of scenes (index 0 = earliest frame). -/
abbrev Trace := List Scene

----------------------------------------------------------------------
-- Scene queries
----------------------------------------------------------------------

namespace Scene

/-- Look up an entity by id. -/
def getEntity (s : Scene) (eid : EntityId) : Option Entity :=
  s.entities.find? (fun e => decide (e.id = eid))

/-- Does the scene contain an entity with this id? -/
def hasEntity (s : Scene) (eid : EntityId) : Bool :=
  s.entities.any (fun e => decide (e.id = eid))

/-- The type of an entity, if it is present. -/
def typeOf (s : Scene) (eid : EntityId) : Option EntityType :=
  (s.getEntity eid).map Entity.type

/-- All entities whose type matches `t`. -/
def entitiesOfType (s : Scene) (t : EntityType) : List Entity :=
  s.entities.filter (fun e => decide (e.type = t))

/-- All entities whose type is one of `ts`. -/
def entitiesOfTypes (s : Scene) (ts : List EntityType) : List Entity :=
  s.entities.filter (fun e => ts.contains e.type)

/-- Does entity `eid` have attribute key `k` with exactly value `v`? -/
def hasAttr (s : Scene) (eid : EntityId) (k v : String) : Bool :=
  match s.getEntity eid with
  | some e => e.attrs.any (fun p => decide (p.1 = k) && decide (p.2 = v))
  | none   => false

/-- The raw value of attribute `k` on entity `eid`, if present. -/
def getAttr (s : Scene) (eid : EntityId) (k : String) : Option String :=
  match s.getEntity eid with
  | some e => (e.attrs.find? (fun p => decide (p.1 = k))).map (fun p => p.2)
  | none   => none

/-- All targets reachable from `src` along edges labelled `lbl`. -/
def relatedTo (s : Scene) (src : EntityId) (lbl : RelLabel) : List EntityId :=
  (s.relations.filter (fun r =>
    decide (r.src = src) && decide (r.label = lbl))).map Relation.tgt

/-- All sources with an edge labelled `lbl` into `tgt`. -/
def relatedFrom (s : Scene) (tgt : EntityId) (lbl : RelLabel) : List EntityId :=
  (s.relations.filter (fun r =>
    decide (r.tgt = tgt) && decide (r.label = lbl))).map Relation.src

/-- Does the relation `src --lbl--> tgt` exist? -/
def hasRelation (s : Scene) (src : EntityId) (lbl : RelLabel) (tgt : EntityId) : Bool :=
  s.relations.any (fun r =>
    decide (r.src = src) && decide (r.label = lbl) && decide (r.tgt = tgt))

/-- Targets of `src` along `lbl` that additionally have one of the types `ts`.
    Use this instead of `relatedTo` when the intended target is a specific
    kind of node — `isIn` is overloaded across entity→lane, lane→road and
    road→junction, so an unfiltered query mixes the three. -/
def relatedToTyped (s : Scene) (src : EntityId) (lbl : RelLabel)
    (ts : List EntityType) : List EntityId :=
  (s.relatedTo src lbl).filter (fun eid =>
    match s.typeOf eid with
    | some t => ts.contains t
    | none   => false)

end Scene

----------------------------------------------------------------------
-- Trace helpers
----------------------------------------------------------------------

/-- The scene at position `i`, or the empty scene when out of bounds. -/
def Trace.getScene (τ : Trace) (i : Nat) : Scene :=
  τ.getD i default

end TrafficSpec

/-
  Rule R0005 — clear the intersection for an approaching emergency vehicle.

  Law text (laws/example/laws.jsonl, id EX-EMERGENCY-001):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  SCOPE — this node is a PARTIAL formalization
  -------------------------------------------
  Only the "clear of any intersection" element is formalized here.

  * "drive to the right-hand edge of the roadway" is NOT formalizable against
    this schema: the CARLA scene graph carries no lane side and no lane heading
    (the missing field is `lane_geometry` in `carla/schema.json` — no positions,
    no headings, no lane offsets relative to the roadway edge). Lane names such
    as `Lane 9_-1` encode an OpenDRIVE lane id whose sign is not a reliable
    left/right indicator, so reading a side out of the name would be an
    invention, not a formalization.
  * "shall yield the right of way" is NOT formalizable either: the schema
    carries no right-of-way annotation (`right_of_way`), and the yielding
    vehicle is generally not ego, so its speed/brake channels do not exist
    (`non_ego_dynamics`).

  EX-EMERGENCY-001 therefore remains `partial`.

  Formalization notes
  -------------------
  * "an authorised emergency vehicle" is `Pred.isEmergency w`, i.e. the
    generator's `special_class = "emergency"` (police / fire / ambulance).
  * "the driver of every other vehicle" is read as *every vehicle that is not
    itself an emergency vehicle*: the `¬ₛ isEmergency v` conjunct. An ambulance
    following another ambulance is not obliged to clear the junction for it.
  * "Upon the approach of" is read as proximity, not as closing speed: the
    schema has no non-ego speed, so "approaching" cannot be distinguished from
    "nearby". `Pred.inProximity v w` = within 25 m, i.e. the two vehicles share
    some distance band in either direction. 25 m is the outermost band the
    generator emits (`visible`), so this is the widest "nearby" the data can
    express; a tighter reading would need a distance the graph does not carry.
  * "clear of any intersection" is `¬ₛ Pred.inAnyJunction v`, which follows the
    graph's entity → lane → road → junction structure.
  * A driver already inside the intersection when the emergency vehicle appears
    must be given time to clear it — the statute cannot demand teleportation.
    So the obligation is violated only when the vehicle *remains* inside the
    junction for three consecutive frames while the emergency vehicle is
    nearby. That three-frame persistence window is a formalization choice, not
    something the text states; it is recorded here so a reviewer can challenge
    it. Read literally ("clear of any intersection", no grace period) the
    window would be 1, and `clears_junction_for_ambulance` would then be a
    violation.
  * `□ (α ⟹ ¬ₛ (bounded 3 β))` reads: at no position where the emergency
    vehicle is nearby does the vehicle stay inside a junction for three
    consecutive frames. `bounded` has strong-next semantics, so the last two
    frames of a trace can never start a window.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0005

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The obligation fires: `w` is an authorised emergency vehicle within 25 m of
    `v`, and `v` is one of the "other" (non-emergency) vehicles. -/
def emergencyNearby (v w : EntityId) : SFProp :=
  isEmergency w ⋀ ¬ₛ (isEmergency v) ⋀ inProximity v w

/-- The rule, quantified over ordered pairs of vehicles. -/
def schema : PropertySchema where
  name    := "clear_junction_for_emergency"
  binders := [vehicleBinder "v", vehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (emergencyNearby v w ⟹ ¬ₛ (.bounded 3 (inAnyJunction v)))

def entry : RuleEntry where
  nodeId  := "Emergency/R0005_clear_junction_for_emergency"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

-- Entity ids: actors 1–2, lanes 10–12, roads 20–22, junction 30.
private def laneJunc : Nat := 10   -- "Lane 12_-1", inside the junction
private def laneExit : Nat := 11   -- "Lane 13_-1", the exit road, no junction
private def laneFar  : Nat := 12   -- "Lane 40_-1", a distant road, no junction
private def roadJunc : Nat := 20
private def roadExit : Nat := 21
private def roadFar  : Nat := 22
private def junction : Nat := 30

/-- Road structure, re-emitted every frame as the adapter does: the junction
    lane sits on a road that is inside a junction; the exit and far lanes sit
    on roads that are not. -/
private def structureEntities : List Entity :=
  [ mkLane laneJunc "Lane 12_-1"
  , mkLane laneExit "Lane 13_-1"
  , mkLane laneFar  "Lane 40_-1"
  , mkRoad roadJunc "Road 12"
  , mkRoad roadExit "Road 13"
  , mkRoad roadFar  "Road 40"
  , mkJunction junction "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel laneJunc .isIn roadJunc
  , mkRel roadJunc .isIn junction
  , mkRel laneExit .isIn roadExit
  , mkRel laneFar  .isIn roadFar
  , mkRel laneJunc .travelsTo laneExit ]

/-- The other vehicle closes from behind, as an emergency vehicle overtaking
    does; the generator emits both orientations of each angular edge. -/
private def fromRear : List Relation :=
  [ mkRel 2 .atSRearOf 1, mkRel 1 .inSFrontOf 2 ]

/-- The other vehicle sits alongside. -/
private def alongside : List Relation :=
  [ mkRel 2 .toLeftOf 1, mkRel 1 .toRightOf 2 ]

/-- One frame. Ego is entity 1 and occupies `egoLane`; `other` must be built
    with id 2 and occupies `otherLane`. `band` is the single proximity label the
    generator emits for the pair — `none` means the pair is beyond 25 m and so
    carries no distance edge at all. -/
private def sceneOf (egoLane : Nat) (other : Entity) (otherLane : Nat)
    (band : Option RelLabel) (angular : List Relation) : Scene :=
  frame
    ([mkEgo 1 .car "6.0" "0.0" "0.3" "0.0", other] ++ structureEntities)
    (structureRels
      ++ [mkRel 1 .isIn egoLane, mkRel 2 .isIn otherLane]
      ++ (match band with
          | some b => mkRel 1 b 2 :: angular
          | none   => []))

private def ambulance : Entity := mkEmergency 2 "ambulance_0" .car
private def ordinaryCar : Entity := mkActor 2 "car_0" .car

/-- Ego is inside the junction when the ambulance appears 10–16 m away, and is
    out of the junction two frames later — the statute's grace period. -/
def traceClears : Trace :=
  [ sceneOf laneJunc ambulance laneJunc (some .near) fromRear
  , sceneOf laneJunc ambulance laneJunc (some .near) fromRear
  , sceneOf laneExit ambulance laneJunc (some .near) fromRear
  , sceneOf laneExit ambulance laneJunc (some .near) fromRear
  , sceneOf laneExit ambulance laneJunc (some .near) fromRear
  , sceneOf laneExit ambulance laneJunc (some .near) fromRear ]

/-- Ego sits in the junction throughout, but the vehicle beside it at 7–10 m is
    an ordinary car with no `special_class`. Nothing obliges ego to clear. -/
def traceNoEmergency : Trace :=
  List.replicate 6 (sceneOf laneJunc ordinaryCar laneJunc (some .veryNear) alongside)

/-- Ego sits in the junction throughout while an ambulance is in the trace but
    shares no distance band with it in either direction — beyond 25 m. -/
def traceAmbulanceFar : Trace :=
  List.replicate 6 (sceneOf laneJunc ambulance laneFar none [])

/-- Ego never leaves the junction while the ambulance is 7–10 m away — the
    forbidden conduct. -/
def traceRemains : Trace :=
  List.replicate 6 (sceneOf laneJunc ambulance laneJunc (some .veryNear) fromRear)

def scenarios : List Scenario :=
  [ { name := "clears_junction_for_ambulance",      trace := traceClears,       expected := true }
  , { name := "no_emergency_nearby",                trace := traceNoEmergency,  expected := true }
  , { name := "ambulance_far_away",                 trace := traceAmbulanceFar, expected := true }
  , { name := "remains_in_junction_with_ambulance", trace := traceRemains,      expected := false } ]

end TrafficSpec.Rules.Emergency.R0005

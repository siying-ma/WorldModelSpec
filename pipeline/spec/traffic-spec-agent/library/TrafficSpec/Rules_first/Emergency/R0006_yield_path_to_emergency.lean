/-
  Rule R0006 — yield the travel path to an approaching emergency vehicle.

  Law text (laws/example/laws.jsonl, id EX-EMERGENCY-001):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  SCOPE — this node is a PARTIAL formalization of one of three elements
  ---------------------------------------------------------------------
  EX-EMERGENCY-001 states three obligations. This node formalizes exactly one:

  * "shall yield the right of way" — read here as *do not remain in the
    approaching emergency vehicle's travel path*. That is what this file
    encodes.
  * "clear of any intersection" is ALREADY formalized by
    `Emergency/R0005_clear_junction_for_emergency` and is deliberately NOT
    re-encoded here; duplicating it would double-count a single violation.
  * "shall drive to the right-hand edge of the roadway" remains UNSUPPORTED.
    The CARLA scene graph carries no lane side and no lane heading — the
    missing field is `lane_geometry` in `carla/schema.json` (no positions, no
    headings, no lane offsets relative to the roadway edge). Lane names such as
    `Lane 20_-1` encode an OpenDRIVE lane id whose sign is not a reliable
    left/right indicator, so reading a roadway side out of the name would be an
    invention rather than a formalization. EX-EMERGENCY-001 therefore stays
    `partial` even with R0005 and R0006 together.

  Formalization notes
  -------------------
  * "an authorised emergency vehicle" is `Pred.isEmergency w`, i.e. the
    generator's `special_class = "emergency"` (police / fire / ambulance).
  * "the driver of every other vehicle" is read as *every vehicle that is not
    itself an emergency vehicle*: the `¬ₛ isEmergency v` conjunct. An ambulance
    is not obliged to pull out of another ambulance's path.
  * "in that vehicle's travel path" is same-lane occupancy with the emergency
    vehicle astern: `Pred.following w v` = `sameLane w v ⋀ behind w v`. Note the
    argument order — `Pred.following a b` means *a is behind b in the same
    lane*, so the emergency vehicle closing from the rear is `following w v`.
    Writing `following v w` would invert the rule and let `blocks_ambulance`
    pass.
  * "Upon the approach of" is read as proximity, not as closing speed: the
    schema has no non-ego speed (`non_ego_dynamics`), so "approaching" cannot be
    distinguished from "nearby". It is `Pred.withinMetres 16 w v`, which admits
    the `near` band (10–16 m) and every closer band. 16 m is a FORMALIZATION
    CHOICE the statute does not state; a reviewer may reasonably argue for 25 m
    (the outermost band the generator emits, as R0005 uses) or for 10 m.
    Writing `rel w .near v` instead would be the classic band bug: that is the
    10–16 m band *alone* and would excuse a vehicle blocking an ambulance at
    5 m.
  * The rule is NOT gated on `Pred.isEgo`. None of its conjuncts read the
    ego-only dynamics channels, so it applies to every ordered pair of
    vehicles — which is what "the driver of every other vehicle" says.
  * A driver cannot vacate a lane instantaneously, so one frame of obstruction
    is not yet a refusal to yield. The obligation is violated only when the
    obstruction *persists* for three consecutive frames. That three-frame
    persistence window is the second FORMALIZATION CHOICE, mirroring the
    threshold R0001 and R0005 already use; read literally (no grace period) the
    window would be 1, and `changes_lane_for_ambulance` would then be a
    violation.
  * `□ ¬ₛ (bounded 3 φ)` reads: at no position does φ hold for three
    consecutive frames. `bounded` has strong-next semantics, so the last two
    frames of a trace can never start a window.

  KNOWN OVER-PERMISSIVENESS
  -------------------------
  The obligation is discharged as soon as the same-lane relation ends. A trace
  could achieve that by the vehicle simply accelerating away down the same lane
  until it leaves the 16 m band, rather than by moving over — which is not
  yielding in the statute's sense. Distinguishing "moved aside" from "outran
  it" needs the vehicle's lane side, i.e. `lane_geometry` again, so it is out of
  reach against this schema. The gap is recorded here rather than papered over.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0006

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- `v` is obstructing the path of an approaching authorised emergency vehicle
    `w`: `w` is an emergency vehicle, `v` is not, and `w` is behind `v` in the
    same lane within 16 metres. -/
def obstructsEmergency (v w : EntityId) : SFProp :=
  isEmergency w ⋀ ¬ₛ (isEmergency v) ⋀ following w v ⋀ withinMetres 16 w v

/-- The rule, quantified over ordered pairs of vehicles. -/
def schema : PropertySchema where
  name    := "yield_path_to_emergency"
  binders := [vehicleBinder "v", vehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded 3 (obstructsEmergency v w)))

def entry : RuleEntry where
  nodeId  := "Emergency/R0006_yield_path_to_emergency"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

-- Entity ids: actors 1–2, lanes 10–11, road 20.
private def laneA : Nat := 10   -- "Lane 20_-1", the lane the ambulance is in
private def laneB : Nat := 11   -- "Lane 20_-2", the adjacent lane to move into
private def road  : Nat := 20

/-- Road structure, re-emitted every frame as the adapter does: two driving
    lanes on one road, mutually reachable by a lane change. -/
private def structureEntities : List Entity :=
  [ mkLane laneA "Lane 20_-1"
  , mkLane laneB "Lane 20_-2"
  , mkRoad road  "Road 20" ]

private def structureRels : List Relation :=
  [ mkRel laneA .isIn road
  , mkRel laneB .isIn road
  , mkRel laneA .laneChange laneB
  , mkRel laneB .laneChange laneA ]

/-- The follower sits directly astern of ego; the generator emits both
    orientations of each angular edge. -/
private def fromRear : List Relation :=
  [ mkRel 2 .atDRearOf 1, mkRel 1 .inDFrontOf 2 ]

/-- One frame. Ego is entity 1 in `egoLane`; `follower` must be built with id 2
    and occupies `followerLane`. `band` is the single proximity label the
    generator emits for the pair — `none` means the pair is beyond 25 m and so
    carries no distance edge at all, in which case no angular edge is emitted
    either. -/
private def sceneOf (egoLane : Nat) (follower : Entity) (followerLane : Nat)
    (band : Option RelLabel) : Scene :=
  frame
    ([mkEgo 1 .car "12.0" "0.0" "0.4" "0.0", follower] ++ structureEntities)
    (structureRels
      ++ [mkRel 1 .isIn egoLane, mkRel 2 .isIn followerLane]
      ++ (match band with
          | some b => mkRel 1 b 2 :: fromRear
          | none   => [mkRel 2 .atDRearOf 1, mkRel 1 .inDFrontOf 2]))

private def ambulance : Entity := mkEmergency 2 "ambulance_0" .car
private def ordinaryCar : Entity := mkActor 2 "car_0" .car

/-- Ego is in the ambulance's lane at 7–10 m for two frames, then moves into
    the adjacent lane while the ambulance stays put — the path is cleared
    before the three-frame window closes. -/
def traceChangesLane : Trace :=
  [ sceneOf laneA ambulance laneA (some .veryNear)
  , sceneOf laneA ambulance laneA (some .veryNear)
  , sceneOf laneB ambulance laneA (some .veryNear)
  , sceneOf laneB ambulance laneA (some .veryNear)
  , sceneOf laneB ambulance laneA (some .veryNear)
  , sceneOf laneB ambulance laneA (some .veryNear) ]

/-- Ego holds its lane throughout with a vehicle 4–7 m astern, but that vehicle
    is an ordinary car with no `special_class`. Nothing obliges ego to move
    over. Minimal pair against `traceBlocks`: the only difference is the
    follower's `special_class`. -/
def traceOrdinaryCar : Trace :=
  List.replicate 6 (sceneOf laneA ordinaryCar laneA (some .superNear))

/-- Ego holds the ambulance's lane throughout, but the two share no distance
    band in either direction — beyond 25 m, so the ambulance has not yet
    "approached". -/
def traceAmbulanceFar : Trace :=
  List.replicate 6 (sceneOf laneA ambulance laneA none)

/-- Ego never leaves the ambulance's lane while the ambulance is 7–10 m astern
    — the forbidden conduct. -/
def traceBlocks : Trace :=
  List.replicate 6 (sceneOf laneA ambulance laneA (some .veryNear))

def scenarios : List Scenario :=
  [ { name := "changes_lane_for_ambulance", trace := traceChangesLane,  expected := true }
  , { name := "ordinary_car_behind",        trace := traceOrdinaryCar,  expected := true }
  , { name := "ambulance_far_behind",       trace := traceAmbulanceFar, expected := true }
  , { name := "blocks_ambulance",           trace := traceBlocks,       expected := false } ]

end TrafficSpec.Rules.Emergency.R0006

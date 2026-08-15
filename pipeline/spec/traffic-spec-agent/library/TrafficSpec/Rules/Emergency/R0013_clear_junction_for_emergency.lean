/-
  Rule R0013 — clear of any intersection for an approaching emergency vehicle.

  Law text (laws/example/laws.jsonl, id EX-EMERGENCY-001):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  SCOPE — THE JUNCTION-CLEARANCE OBLIGATION ONLY
  ----------------------------------------------
  The sentence states three things. This node formalizes exactly one of them:
  **"clear of any intersection"**.

    * "shall drive to the right-hand edge of the roadway" is the sibling node
      `Emergency/R0012_pull_right_for_emergency` and is deliberately NOT folded
      in. The two consequents degrade differently: R0012's reading of "the
      right-hand edge" has to survive the missing kerb and the missing
      carriageway width (`carla/schema.json` → `unavailable.lane_width_and_markings`),
      whereas junction occupancy is read straight off the graph's
      lane → road → junction structure and involves no map convention and no
      degradation at all. The withdrawn `Emergency/R0007` bundled both, so when
      its lateral conjunct turned out to be defective the whole rule was
      withdrawn and this sound obligation was destroyed along with the broken
      one. Split, the next withdrawal is surgical.
    * "shall yield the right of way" is NOT a conjunct here either, and is not
      formalized anywhere. The abstraction carries no priority or right-of-way
      annotation of any kind (`carla/schema.json` → `unavailable.right_of_way`),
      so there is nothing to test; a conjunct that is unmeasurable would only
      weaken the antecedent. See residue 3.

  No overlap with `Junction/R0006_yield_in_occupied_junction`, which polices
  *entering* a junction another vehicle already occupies and has no emergency
  antecedent, nor with `Speed/R0002_junction_speed`, which is about pace rather
  than presence. This rule is the only one that asks whether the ego is standing
  in the way of an emergency vehicle.

  Formalization notes — every choice the text did not dictate
  ----------------------------------------------------------
  * **"Clear of any intersection" is read as `¬ Pred.inAnyJunction v`.** The
    forbidden state is occupancy of *some* junction, not of a named one. The
    junction is deliberately NOT bound: the statute says "any intersection", the
    identity of the junction plays no part in the obligation, and a third binder
    would multiply the grounding count without testing anything further. The
    predicate walks the generator's own entity → lane → road → junction chain
    (`Core/Vocab.lean` § 3), which is the same structure `process_to_junction_rsv`
    builds, so no convention is being imposed on the map.
  * **"Upon the approach of" is read as presence within 25 m**
    (`Pred.withinMetres 25`), not as a sequence of tightening proximity bands.
    This matches the sibling R0012 deliberately: the two nodes share one
    antecedent and must not drift apart. Proximity is quantised into six bands
    and nothing in the graph distinguishes an emergency vehicle closing on the
    ego from one holding station beside it, so a "closing" test would be a guess
    dressed as a measurement. 25 m is the outermost band boundary the generator
    emits (`visible`, 16–25 m), i.e. the widest reading of "approach" the data
    supports; it is named once, in `approachMetres`.
  * **The forbidden state must be SUSTAINED for `clearanceFrames` =
    `secondsToFrames 2` = 40 frames = 2 s at the reference 20 Hz capture rate,
    rather than being prohibited per frame. This is the largest single choice in
    the rule and the text does not make it.** Read per-frame, "clear of any
    intersection" convicts a driver who is already halfway across the box when
    the siren comes into range — and getting clear is precisely what the statute
    demands of that driver. An allowance is therefore not a weakening of the
    clause but a condition of its being satisfiable at all. 2 s is long enough
    to cross a junction at junction speeds and short enough that a driver who
    simply sits there is caught; it is a round figure, not a measurement, and
    frames carry no clock (`carla/schema.json` → `unavailable.timestamps`) so it
    has to be a frame count. `clearanceFrames` is the whole change a reviewer who
    disagrees has to make. `promptly_clears_the_junction` and
    `remains_within_the_junction` differ in exactly this one respect.
  * **`w` is bound with `proximityVehicleBinder`, not `vehicleBinder`.**
    Proximity edges exist only for the base classes `person`, `bicycle`, `car`,
    `motorcycle`, `bus`, `truck` (`carla/schema.json` → `relation_coverage`), so
    a `vehicleBinder` would manufacture groundings whose antecedent can never
    fire and inflate the grounding count without testing anything.
  * **The obligation is gated on `Pred.isEgo v`**, as every rule in this library
    is: it is a monitor on the conduct of the driver being observed and takes no
    position on third parties. Every scenario below carries a second vehicle that
    also grounds `v`, so that gate is exercised rather than assumed.
  * **`v = w` needs no explicit exclusion.** `PropertySchema.bindings` already
    filters bindings that repeat an entity, and the ego carries
    `special_class = "ego"` rather than `"emergency"`, so `isEgo v ⋀ isEmergency w`
    could not hold of one entity in any case.

  Residues — what this rule does not measure
  ------------------------------------------
  1. **`special_class = "emergency"` is a CARLA blueprint attribute, not a siren
     and not a light bar.** The graph records what the vehicle *is*, never
     whether it is *responding*. An off-duty police car parked at the kerb fires
     the antecedent exactly as a responding one does, so the rule over-reports
     against the statute's "upon the approach of an authorised emergency
     vehicle". There is no channel that would fix this: the emergency light bar
     is not among the lifted per-vehicle light booleans.
  2. **This rule can only ever ground on the police car and the firetruck.**
     CARLA's ambulance is `vehicle.ford.ambulance`, whose base type is `van`, and
     **no** proximity or angular edge is emitted for a van
     (`carla/schema.json` → `relation_coverage`; `Core/Builders.lean`, the note on
     `mkEmergency`). An approaching ambulance is invisible to this rule — a
     silent under-report, and the single largest gap in its coverage.
  3. **"Shall yield the right of way" is not formalized at all** — see SCOPE. A
     driver who clears the junction and then cuts the emergency vehicle up
     elsewhere is reported compliant here.
  4. **Junction extent is membership, not geometry.** No coordinates survive for
     structure nodes (`carla/schema.json` → `unavailable.stop_line_and_junction_geometry`),
     so "within the intersection" is exactly "occupying a lane whose road is
     `isIn` a junction node". A vehicle stopped with its nose over an unmarked
     junction mouth but still `isIn` the approach lane reads as clear.
  5. **An occupancy shorter than 2 s is not reported**, and by strong-next
     semantics (`Core/Semantics.lean`, `loopBounded`) neither is one that begins
     within the last 39 frames of a trace. Under-reporting, chosen so the
     clearance allowance is honoured.
  6. **Check the grounding count and the verdict on a real capture before
     believing this rule.** The scenarios below were written by the same reading
     that wrote the formula, which is precisely how R0007 and R0009 passed their
     gates; only `run_spec monitor` against a human-labelled capture is
     independent of it.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0013

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How close an emergency vehicle must be before "upon the approach of" is
    taken to hold. 25 m is the outermost proximity band boundary the generator
    emits (`visible`, 16–25 m), so this is the widest reading the data supports.
    A formalization choice, shared verbatim with the sibling
    `Emergency/R0012_pull_right_for_emergency` — see the header. -/
def approachMetres : Nat := 25

/-- The driver's clearance allowance: 2 s = 40 frames at the reference 20 Hz
    capture rate. Occupying the intersection is an offence only once it has
    persisted this long, so a driver already inside when the emergency vehicle
    comes into range is permitted the time it takes to get out. A formalization
    choice, not something the text states; this `def` is the whole change a
    reviewer who wants a different allowance has to make. -/
def clearanceFrames : Nat := TrafficSpec.secondsToFrames 2

/-- The forbidden state: the monitored driver is within `approachMetres` of an
    emergency vehicle and is *still* occupying some junction, i.e. has not got
    clear of the intersection. -/
def blockingTheIntersection (v w : EntityId) : SFProp :=
  isEgo v ⋀ isEmergency w ⋀ withinMetres approachMetres v w ⋀ inAnyJunction v

/-- At no position does the ego occupy a junction while an emergency vehicle is
    within 25 m, for `clearanceFrames` consecutive frames. -/
def schema : PropertySchema where
  name    := "clear_junction_for_emergency_vehicle"
  binders := [vehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded clearanceFrames (blockingTheIntersection v w)))

def entry : RuleEntry where
  nodeId  := "Emergency/R0013_clear_junction_for_emergency"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One junction, laid out as the generator lays one out: an approach road and an
-- exit road that are plain roads, and one road that `isIn Junction 5`, so only
-- `Lane 20_-1` satisfies `inAnyJunction`. `travelsTo` wires approach → junction
-- → exit. The junction node and its lane are present in EVERY frame of EVERY
-- trace, so a structure a scenario does not use is never the reason a verdict
-- changes; only which lane the ego occupies, and whether the proximity edges
-- are present, ever varies.
--
-- Every trace carries exactly two vehicles: the ego and one other car. The
-- other car grounds `v` a second time — and must always come out compliant,
-- since it is not the ego — and grounds `w` once.
--
-- Trace lengths are all 100 frames, comfortably longer than the 40-frame
-- window: the window is stated in seconds and the traces were built to fit the
-- window rather than the window shrunk to fit the traces.
----------------------------------------------------------------------

private def ego          : Nat := 1
private def other        : Nat := 2
private def approachLane : Nat := 10
private def junctionLane : Nat := 11
private def exitLane     : Nat := 12
private def approachRoad : Nat := 20
private def junctionRoad : Nat := 21
private def exitRoad     : Nat := 22
private def junction     : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1"
  , mkLane junctionLane "Lane 20_-1"
  , mkLane exitLane     "Lane 9_-1"
  , mkRoad approachRoad "Road 7"
  , mkRoad junctionRoad "Road 20"
  , mkRoad exitRoad     "Road 9"
  , mkJunction junction "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel junctionRoad .isIn junction
  , mkRel approachLane .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- The ego (id 1), rolling through at junction speed under light throttle. -/
private def egoCar : Entity := mkEgo 1 .car "6.0" "0.0" "0.3" "0.0"

/-- An emergency police car (id 2): base class `car`, `special_class`
    `"emergency"`. `car` and not `van`, because a van carries no proximity edge
    and the antecedent could never fire — residue 2 in the header. -/
private def policeCar : Entity := mkEmergency 2 "car_0" .car

/-- The same car without `special_class`, for the scenario that isolates the
    `isEmergency` conjunct. -/
private def ordinaryCar : Entity := mkActor 2 "car_0" .car

/-- The other car is within the `near` band (10–16 m, so inside 25 m) at the
    ego's rear. Distance is stored as one directed edge per ordered pair, and
    `withinMetres` checks both orientations. -/
private def proximityRels : List Relation :=
  [ mkRel other .near ego
  , mkRel other .atDRearOf ego
  , mkRel ego .inDFrontOf other ]

/-- One frame: the ego `isIn` `egoNode`, the other car `isIn` `otherNode`, with
    the proximity and angular edges present only when `closeBehind`. -/
private def sceneOf (o : Entity) (egoNode otherNode : Nat)
    (closeBehind : Bool) : Scene :=
  frame
    ([egoCar, o] ++ structureEntities)
    (structureRels
      ++ [ mkRel ego .isIn egoNode, mkRel other .isIn otherNode ]
      ++ (if closeBehind then proximityRels else []))

/-- The emergency police car is within the `near` band behind the ego for all
    100 frames, and the ego holds the ordinary approach lane `Lane 7_-1`
    throughout, never a junction lane. The junction node and its lane are
    present in every frame, so the structure is not the reason the verdict
    comes out the way it does — only the ego's lane is. The driver is clear of
    the intersection. Compliant. -/
def traceClearOfTheJunctionThroughout : Trace :=
  List.replicate 100 (sceneOf policeCar approachLane approachLane true)

/-- The clearance allowance. 100 frames: for the first 10 the ego is already
    inside the junction with no vehicle within 25 m; at frame 10 the emergency
    police car comes within the `near` band while the ego is still in the
    junction lane, and the ego stays there for 30 more frames — FEWER than the
    40-frame window — before reaching the exit lane for the remaining 60 and
    staying out.

    The longest run of the forbidden state is 30 frames, so `.bounded 40` never
    closes and the driver's prompt clearance is lawful. The statute requires the
    driver to *get* clear, which takes time. Differs from
    `remains_within_the_junction` only in how long the junction occupancy lasts
    once the emergency vehicle is in range. -/
def tracePromptlyClearsTheJunction : Trace :=
  List.replicate 10 (sceneOf policeCar junctionLane approachLane false)
    ++ List.replicate 30 (sceneOf policeCar junctionLane approachLane true)
    ++ List.replicate 60 (sceneOf policeCar exitLane     approachLane true)

/-- The same geometry and the same 100-frame duration as
    `traceRemainsWithinTheJunction` — the ego sits in the junction lane for the
    whole trace with a car within the `near` band behind it — but that car
    carries no `special_class = "emergency"`.

    The antecedent never fires, so the rule is satisfied. This isolates the
    `isEmergency` conjunct: it is the ONLY respect in which this trace differs
    from the negative one. Sitting in a junction is policed by other clauses,
    not by this one. -/
def traceOrdinaryCarNotAnEmergencyVehicle : Trace :=
  List.replicate 100 (sceneOf ordinaryCar junctionLane approachLane true)

/-- The offence. The emergency police car is within the `near` band for all 100
    frames while the ego stays in the junction lane `Lane 20_-1` throughout —
    comfortably longer than the 40-frame allowance — blocking the intersection
    the emergency vehicle must cross. Violated.

    `car_0` is not the ego, so its own grounding of `v` is compliant and the
    failing grounding is the ego's alone. -/
def traceRemainsWithinTheJunction : Trace :=
  List.replicate 100 (sceneOf policeCar junctionLane approachLane true)

def scenarios : List Scenario :=
  [ { name := "clear_of_the_junction_throughout",    trace := traceClearOfTheJunctionThroughout,     expected := true }
  , { name := "promptly_clears_the_junction",        trace := tracePromptlyClearsTheJunction,        expected := true }
  , { name := "ordinary_car_not_an_emergency_vehicle", trace := traceOrdinaryCarNotAnEmergencyVehicle, expected := true }
  , { name := "remains_within_the_junction",         trace := traceRemainsWithinTheJunction,         expected := false } ]

end TrafficSpec.Rules.Emergency.R0013

/-
  Rule R0006 — yielding within an intersection another vehicle already occupies.

  Law text (EX-JUNCTION-001, "Yielding within an intersection"):
    "A driver entering an intersection already occupied by another vehicle shall
     yield, and shall not remain within the intersection until the other vehicle
     has cleared it."

  SCOPE — ONE OPERATIVE SHAPE, NOT TWO
  ------------------------------------
  The clause reads as a single forbidden pattern rather than as two independent
  duties: *entering* an intersection that another vehicle already occupies **and
  then** *remaining* there alongside that vehicle. The "shall yield" and the
  "shall not remain" halves describe the same course of conduct from two angles,
  and only the conjunction is decidable from the graph — see the first
  formalization note. A trace this rule reports as compliant may still involve a
  driver who failed to yield in some other way (below).

  Formalization notes
  -------------------
  * **"Shall yield" is derived purely from occupancy ORDER, because the graph
    carries no priority annotation.** `carla/schema.json` →
    `unavailable.right_of_way` records that no explicit right-of-way or priority
    field exists anywhere in the scene graph, and names occupancy order as the
    route to derive it. So the formalized wrong is not "failed to defer to a
    vehicle with priority" but "was second into the intersection and stayed".
    The statute's own phrasing licenses this: the vehicle that was *already*
    occupying the intersection is the one to be yielded to.

    The reading is deliberately temporal, and that matters. Plain co-occupancy —
    `inJunction v j ⋀ inJunction w j` — would convict **both** vehicles,
    including the one that arrived first and is entitled to clear the junction.
    The scenario `ego_entered_first` exists to fail if this rule is ever
    rewritten as co-occupancy.

  * **"Remain" is given a persistence window of 4 frames, and that number is
    ours, not the statute's.** The text says "shall not remain within the
    intersection" without saying for how long, so a single-frame reading would
    convict a driver whose lane assignment merely overlapped the other
    vehicle's for one frame as the two crossed — which "remain" plainly does not
    cover. `persistFrames := 4` is 0.2 s at the reference 20 Hz capture rate
    (`Core/Scene.lean`, `captureHz := 20`), chosen as the shortest window that
    still separates a momentary overlap from a held one while keeping the
    required trace length small. It is open to challenge in both directions:
    raise it and a driver who blocks the junction for a fifth of a second
    escapes; set it to 1 and the crossing-overlap case is convicted. Nothing in
    the law text settles it. `momentary_overlap_allowed` pins the window: it is
    a two-frame overlap and must report compliant.

    The window inherits the capture-rate residue in `carla/schema.json` →
    `capture_preconditions.capture_rate`: frames carry no timestamp, so 4 frames
    is 0.2 s only if the capture really ran at 20 Hz, which no capture records.
    At 40 Hz the same formula demands only 0.1 s.

  * **"Within the intersection" can only mean lane occupancy, so the moment of
    entry is quantised to a lane-assignment flip.** `Pred.inJunction e j` walks
    the graph's `e --isIn--> lane --isIn--> road --isIn--> junction` chain,
    because `carla/schema.json` → `unavailable.stop_line_and_junction_geometry`
    records that no coordinates survive for structure nodes: a junction has no
    boundary and there is no stop line to test a position against. "Entering"
    therefore becomes "was not mapped into the junction at frame i and is at
    frame i+1", with the transition placed wherever the abstraction moves the
    vehicle between lane nodes (`SGG(segment_length=1.0)`). A vehicle whose nose
    is physically over the line while the map still holds it on the approach
    reads as outside, so the detected entry can be slightly late.

    The same walk is available for **non-ego** actors: `isIn` lane membership is
    emitted for every actor, unlike the dynamics channels. That is why the other
    vehicle's occupancy is observable at all, and why this rule needs no
    proximity edge — see the binder note.

  * **The formula is gated on `Pred.isEgo v`, and here that is a choice about
    whose duty is specified, not only a data restriction.** The obligation is
    placed on the driver this specification speaks about. Ungated, the rule would
    also read the mirrored grounding (v = the other car, w = the ego) and convict
    a non-ego vehicle for entering a junction the ego already occupied — a claim
    this rule does not make. **This rule says nothing either way about a non-ego
    vehicle's duty to yield.** Unlike `Following/R0003`, the gate is not forced by
    missing data: both vehicles' occupancy is fully observable, so a sibling node
    convicting non-ego vehicles could be written on the same predicates.

  * **Binders are `vehicleBinder`, not `proximityVehicleBinder`, and there is no
    distance conjunct at all.** Occupancy of a shared junction is a structural
    fact read off `isIn` edges, so the rule never needs a proximity band — which
    is fortunate, since no proximity edge is ever emitted between two non-ego
    actors and none is emitted for a `van` or a bare `vehicle`
    (`carla/schema.json` → `relation_coverage`). Using the wider
    `vehicleBinder` therefore costs nothing and lets the rule fire on vehicle
    classes a proximity-based rule cannot see. `j` is a `junctionBinder`, so a
    capture with no junction node grounds *zero* times — loudly vacuous and
    caught by the gate — rather than quietly reporting compliance.

    `PropertySchema.bindings` already filters to distinct, co-present entities,
    so `v` and `w` cannot collapse onto the same car.

  * **Shape, span and the blind zone.** `□ (¬ₛ badEntry)`, where `badEntry` at a
    position is `isEgo v ⋀ inJunction w j ⋀ ¬ₛ inJunction v j ⋀
    ◯ (bounded persistFrames (inJunction v j ⋀ inJunction w j))`. `.bounded` sits
    under a `◯` because the *entry* frame is the one where the ego is still
    outside; the co-occupancy window is counted from the frame after it.
    `SFProp.frameSpan` is therefore `1 + persistFrames = 5`, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false — so the last 4 frames of any trace are a blind zone in which
    a violation cannot be reported, and a trace shorter than 5 frames reports
    compliant whatever it contains. Every scenario below is 12 frames, and the
    violating one places its entry at position 3 with the window fully inside
    the trace, well clear of the tail.

  * **What this rule does not credit.** The statute's yield duty can also be
    discharged by slowing or stopping short of the intersection, and a driver
    might fail to yield in ways that never produce the entry-and-remain pattern
    — cutting across in front of the occupying vehicle and clearing the junction
    quickly, for instance. This formalization forbids the entry-and-remain
    pattern only, so it under-enforces the clause; it does not over-enforce it
    on the vehicle that arrived first.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading. Until `run_spec monitor` has compared this rule against a
    human-labelled capture, treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Junction.R0006

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the ego must share the junction with the vehicle that was already
    there before it counts as "remaining". 4 frames = 0.2 s at the reference
    20 Hz capture rate. A formalization choice — the statute states no
    duration. -/
def persistFrames : Nat := 4

/-- Quantified over vehicles and junctions; effective on the ego vehicle, the
    driver whose duty this specification states. No proximity edge is used, so
    the wider `vehicleBinder` is safe for both vehicles. -/
def schema : PropertySchema where
  name    := "yield_in_occupied_junction"
  binders := [vehicleBinder "v", vehicleBinder "w", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    let j := arg env 2
    -- The forbidden pattern: at this frame the ego is still outside a junction
    -- that `w` already occupies, and from the next frame on the two share it
    -- for `persistFrames` consecutive frames.
    □ (¬ₛ ( isEgo v
          ⋀ inJunction w j
          ⋀ ¬ₛ (inJunction v j)
          ⋀ ◯ (SFProp.bounded persistFrames
                 (inJunction v j ⋀ inJunction w j))))

def entry : RuleEntry where
  nodeId  := "Junction/R0006_yield_in_occupied_junction"
  lawRefs := ["EX-JUNCTION-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId         : Nat := 1
private def carId         : Nat := 2
private def junctionLane  : Nat := 10
private def junctionRoad  : Nat := 20
private def junctionId    : Nat := 30
private def egoApproach   : Nat := 11
private def egoApprRoad   : Nat := 21
private def carApproach   : Nat := 12
private def carApprRoad   : Nat := 22
private def exitLane      : Nat := 13
private def exitRoad      : Nat := 23

/-- Road structure shared by every trace: one lane inside a road inside the
    junction, two approach lanes on ordinary roads that `travelsTo` it — one per
    vehicle, from different roads, as two vehicles meeting at an intersection
    would — and one exit lane on a road *outside* the junction, which the
    junction lane `travelsTo`. Only the junction road carries an `isIn` edge to
    the junction node, so `Pred.inJunction` is true exactly for a vehicle in
    `junctionLane`.

    The junction node is present in every frame of every trace, so `j` always
    binds and no scenario can pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkLane egoApproach "Lane 7_-1",  mkRoad egoApprRoad "Road 7"
  , mkLane carApproach "Lane 8_-1",  mkRoad carApprRoad "Road 8"
  , mkLane exitLane    "Lane 9_-1",  mkRoad exitRoad    "Road 9" ]

private def structureRels : List Relation :=
  [ mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel egoApproach .isIn egoApprRoad
  , mkRel carApproach .isIn carApprRoad
  , mkRel exitLane    .isIn exitRoad
  , mkRel egoApproach  .travelsTo junctionLane
  , mkRel carApproach  .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- One frame: the ego in lane `egoLane` at `egoSpeed` m/s, `car_0` in lane
    `carLane`. Both vehicles and the whole road structure are present in every
    frame, so both vehicle binders and the junction binder always bind.

    No proximity or angular edge is emitted: this rule reads none, and the
    generator emits none between the two non-ego-to-non-ego pairs a real
    intersection would involve. -/
private def occFrame (egoLane carLane : Nat) (egoSpeed : String) : Scene :=
  frame
    (mkEgo egoId .car egoSpeed :: mkActor carId "car_0" .car :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn egoLane, mkRel carId .isIn carLane])

/-- Twelve frames. Frames 1–6 (positions 0–5): `car_0` occupies the junction
    lane while the ego waits, stopped, in its approach lane. Frames 7–12
    (positions 6–11): `car_0` has cleared to the exit lane on `Road 9`, outside
    the junction, and only then does the ego move in. No co-occupancy at any
    frame — the ego yielded exactly as the clause requires. -/
def traceEgoWaits : Trace :=
  [ occFrame egoApproach junctionLane "0.000"
  , occFrame egoApproach junctionLane "0.000"
  , occFrame egoApproach junctionLane "0.000"
  , occFrame egoApproach junctionLane "0.000"
  , occFrame egoApproach junctionLane "0.000"
  , occFrame egoApproach junctionLane "0.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000" ]

/-- Twelve frames. Frames 1–4 (positions 0–3): the ego is already inside the
    junction; `car_0` is on its approach, outside. Frames 5–12 (positions 4–11):
    `car_0` enters too, so both occupy the junction together for eight
    consecutive frames.

    The ego never entered an *already occupied* intersection — it was there
    first — so it breaks nothing, and the vehicle that must yield here is
    `car_0`, whose duty this rule does not state. **This is the discriminating
    scenario for occupancy order:** rewrite the formula as plain co-occupancy,
    or drop the `¬ₛ (inJunction v j)` entry conjunct, and it convicts. -/
def traceEgoEnteredFirst : Trace :=
  [ occFrame junctionLane carApproach "3.000"
  , occFrame junctionLane carApproach "3.000"
  , occFrame junctionLane carApproach "3.000"
  , occFrame junctionLane carApproach "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000" ]

/-- Twelve frames. Frames 1–5 (positions 0–4): `car_0` inside the junction, ego
    on its approach. Frames 6–7 (positions 5–6): the ego enters while `car_0` is
    still inside — co-occupancy for exactly two frames. Frames 8–12 (positions
    7–11): `car_0` has cleared to the exit lane outside the junction and the ego
    is inside alone.

    The ego did enter an occupied intersection, but it did not *remain* there
    alongside the other vehicle: two frames is short of the four-frame window.
    Set `persistFrames := 2` and this scenario convicts. -/
def traceMomentaryOverlap : Trace :=
  [ occFrame egoApproach junctionLane "2.000"
  , occFrame egoApproach junctionLane "2.000"
  , occFrame egoApproach junctionLane "2.000"
  , occFrame egoApproach junctionLane "2.000"
  , occFrame egoApproach junctionLane "2.000"
  , occFrame junctionLane junctionLane "2.000"
  , occFrame junctionLane junctionLane "2.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000"
  , occFrame junctionLane exitLane "4.000" ]

/-- Twelve frames. Frames 1–4 (positions 0–3): `car_0` inside the junction, ego
    on its approach. Frame 5 (position 4): the ego enters while `car_0` is still
    inside. Frames 5–12 (positions 4–11): both occupy the junction together for
    eight consecutive frames — the ego entered an already occupied intersection
    and remained there.

    The forbidden pattern is detected at position 3, the last frame on which the
    ego is still outside; its four-frame co-occupancy window covers positions
    4–7, fully inside the trace and clear of the trailing four-frame blind
    zone. -/
def traceEntersAndRemains : Trace :=
  [ occFrame egoApproach junctionLane "3.000"
  , occFrame egoApproach junctionLane "3.000"
  , occFrame egoApproach junctionLane "3.000"
  , occFrame egoApproach junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000"
  , occFrame junctionLane junctionLane "3.000" ]

def scenarios : List Scenario :=
  [ { name := "ego_waits_for_occupied_junction"
    , trace := traceEgoWaits
    , expected := true }
  , { name := "ego_entered_first"
    , trace := traceEgoEnteredFirst
    , expected := true }
  , { name := "momentary_overlap_allowed"
    , trace := traceMomentaryOverlap
    , expected := true }
  , { name := "enters_and_remains_in_occupied_junction"
    , trace := traceEntersAndRemains
    , expected := false } ]

end TrafficSpec.Rules.Junction.R0006

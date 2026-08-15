/-
  Rule R0006 — yielding on entry to an occupied intersection.

  Law text (id EX-JUNCTION-001, "Yielding within an intersection"):
    "A driver entering an intersection already occupied by another vehicle
     shall yield, and shall not remain within the intersection until the other
     vehicle has cleared it."

  Formalization notes
  -------------------
  * **Only the first sentence is formalized. The second is deliberately
    dropped, and that is the largest residue in this rule.** "Shall not remain
    within the intersection until the other vehicle has cleared it", read
    literally, convicts a driver who entered lawfully and is then boxed in by
    cross traffic or by a queue ahead. The abstraction carries no evidence of
    *why* a vehicle is stationary — `non_ego_dynamics` is unavailable for the
    obstructing vehicle, and there is no route, no intent and no blocking
    relation — so staying put under compulsion is indistinguishable from
    staying put out of stubbornness. Formalizing it would manufacture
    violations against lawful drivers. The operative and decidable half is the
    entry prohibition, and that is all this node claims to check. A reviewer who
    wants the second half needs new data, not a different formula.
  * **"Shall yield" is identified with "shall not be the late entrant."** CARLA
    scene graphs carry no priority annotation at all
    (`carla/schema.json` → `not_available.right_of_way`), but this clause is one
    of the few that does not need one: it *defines* the priority it asserts, by
    order of occupancy. The vehicle that was already inside has priority; the
    obligation falls on whoever arrives second.
  * **"Entering" is the frame-to-frame transition into junction-lane
    occupancy**, not occupancy itself:
        □ ( (isEgo v ⋀ isVehicle w ⋀ ¬ inJunction v j ⋀ inJunction w j)
              ⟹ ¬ ◯ (inJunction v j) ).
    Occupancy is emphatically *not* made the forbidden state. A CARLA junction
    spans several roads and lanes, so two vehicles crossing it legally from
    different directions are both `inJunction j`; a blanket
    `□ ¬(inJunction v j ⋀ inJunction w j)` would flag almost every real
    capture, and would also convict a driver who was inside first — the exact
    opposite of what the clause says. `ego_already_inside_when_other_enters` is
    the regression test for this: co-presence is not the offence.
  * **One frame is the granularity of "the moment of entry."** A coarser
    reading — entry within k frames of the other vehicle being inside — would
    also be defensible, but the text states no window, so the finest the trace
    offers is used. The residue is that a vehicle which enters *between* two
    captured frames at the 20 Hz reference rate is unobservable
    (`carla/schema.json` → `time_base`).
  * **No proximity conjunct.** The pair here is ego-to-other, so a distance edge
    would in fact exist for the six covered base classes — but distance is not
    what the clause is about, and requiring one would silently narrow the rule
    away from vans and the generic `vehicle` class for no legal reason.
    "Already occupying the intersection" is a structural fact, not a spatial
    one.
  * **The formula is gated on `Pred.isEgo v`, and this is a scope restriction,
    not a reading of the law.** The statute binds every driver, and junction
    occupancy is readable for every actor, so an ungated rule would not be
    vacuous — the ordered-pair binding would also accuse cross traffic. It is
    gated anyway because only the monitored vehicle has a trajectory this
    specification is accountable for; a non-ego entry is an observation about
    the simulated traffic manager, not about the driver under test. `w` is left
    ungated, so any vehicle can be the prior occupant.
  * **`isVehicle w` is redundant against `vehicleBinder "w"`** and is kept
    anyway: the binder is a grounding-level restriction on which entities are
    tried, whereas "another vehicle" is a condition the clause states, and the
    formula should be readable as the clause without consulting the binder list.
  * **`v = w` needs no explicit exclusion.** `PropertySchema.bindings` already
    filters bindings that repeat an entity, and even without that filter the
    antecedent contains both `¬ inJunction v j` and `inJunction w j`, which
    cannot both hold of one entity.
  * **The other vehicle's occupancy comes from its own `isIn` lane edge**, which
    `process_to_junction_rsv` does emit for non-ego actors, so `inJunction w j`
    is genuinely readable. It should still be checked on a real capture: a rule
    whose antecedent never fires is indistinguishable from a satisfied one, so
    the `monitor` report's antecedent-firing count is the evidence that matters,
    not the scenario verdicts below.
  * **This rule can only ever under-report.** Render distance and occlusion
    filtering both drop actors from the graph, and absence of a vehicle from the
    graph is not evidence that the intersection was clear. An entry into a
    junction occupied by an unseen vehicle reads as compliant.
  * Not covered, and outside what the text forbids: *simultaneous* entry, both
    vehicles outside `j` at frame i and both inside at frame i+1. Neither
    junction was "already occupied by another vehicle" at the moment of entry.
    Recorded so a reviewer can disagree.
  * Finite-trace caveat: `◯` has strong-next semantics and atoms are false past
    the end of the trace (`Core/Semantics.lean`, `evalAtom`), so the consequent
    `¬ ◯ (inJunction v j)` is trivially true at the last frame. The end of a
    trace can never manufacture a violation, but an entry on the frame after the
    capture ends is invisible.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Junction.R0006

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- `v` does not cross into junction `j` on a frame at which vehicle `w` is
    already inside `j`. -/
def yieldsOnEntry (v w j : EntityId) : SFProp :=
  (isEgo v ⋀ isVehicle w ⋀ (¬ₛ inJunction v j) ⋀ inJunction w j)
    ⟹ ¬ₛ ◯ (inJunction v j)

/-- The rule, quantified over ordered pairs of vehicles and junctions,
    effective on the ego vehicle. -/
def schema : PropertySchema where
  name    := "yield_in_occupied_junction"
  binders := [vehicleBinder "v", vehicleBinder "w", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    let j := arg env 2
    □ (yieldsOnEntry v w j)

def entry : RuleEntry where
  nodeId  := "Junction/R0006_yield_in_occupied_junction"
  lawRefs := ["EX-JUNCTION-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One four-way junction, laid out as the generator lays one out: three roads
-- that are plain roads (the ego's approach, the cross-street approach, the
-- exit) and one road that `isIn Junction 5`, so only the junction lane
-- satisfies `inJunction _ j`. `travelsTo` wires approach → junction → exit and
-- cross approach → junction, so `Pred.approachingJunction` also holds for a
-- vehicle waiting on either approach.
--
-- Every trace runs six frames with both vehicles present throughout. Only the
-- lane each vehicle occupies varies; that is the only thing the formula reads.
----------------------------------------------------------------------

private def ego          : Nat := 1
private def other        : Nat := 2
private def approachLane : Nat := 10
private def crossLane    : Nat := 11
private def junctionLane : Nat := 12
private def exitLane     : Nat := 13
private def approachRoad : Nat := 20
private def crossRoad    : Nat := 21
private def junctionRoad : Nat := 22
private def exitRoad     : Nat := 23
private def junction     : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1"
  , mkLane crossLane    "Lane 8_-1"
  , mkLane junctionLane "Lane 20_-1"
  , mkLane exitLane     "Lane 9_-1"
  , mkRoad approachRoad "Road 7"
  , mkRoad crossRoad    "Road 8"
  , mkRoad junctionRoad "Road 20"
  , mkRoad exitRoad     "Road 9"
  , mkJunction junction "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel crossLane    .isIn crossRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel junctionRoad .isIn junction
  , mkRel approachLane .travelsTo junctionLane
  , mkRel crossLane    .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- One frame: the ego (id 1) in `egoLane` with its dynamics channels, and
    `car_0` (id 2) in `otherLane`.

    The ego↔other proximity and angular edges are the ones the generator emits
    between the ego and every covered actor; this rule does not read them, but a
    hand-written trace should look like adapter output, so a cross-street car is
    placed in the `near` band (10–16 m) to the ego's left. Non-ego dynamics are
    absent by construction — `mkActor` emits none, because
    `copy_carla_actor_state` runs for the ego node alone. -/
private def sceneAt (egoLane otherLane : Nat) (speed : String)
    (accel : String := "0.0") (throttle : String := "0.0")
    (brake : String := "0.0") : Scene :=
  frame
    ([ mkEgo ego .car speed accel throttle brake
     , mkActor other "car_0" .car ] ++ structureEntities)
    (structureRels
      ++ [ mkRel ego .isIn egoLane, mkRel other .isIn otherLane
         , mkRel ego .near other, mkRel other .toLeftOf ego ])

/-- The junction is clear throughout: `car_0` sits on the cross-street approach
    for all six frames and never occupies the junction. The ego crosses from the
    approach lane into the junction lane at frame 3. `inJunction w j` is false at
    every frame, so the antecedent never fires and the entry is unpoliced by this
    clause. Compliant. -/
def traceEntersClearJunction : Trace :=
  [ sceneAt approachLane crossLane "6.0" "0.0"  "0.4"
  , sceneAt approachLane crossLane "6.0" "0.0"  "0.4"
  , sceneAt junctionLane crossLane "6.0" "0.0"  "0.4"
  , sceneAt junctionLane crossLane "6.0" "0.0"  "0.4"
  , sceneAt junctionLane crossLane "6.5" "0.5"  "0.4"
  , sceneAt exitLane     crossLane "7.0" "0.5"  "0.4" ]

/-- `car_0` holds the junction for frames 1–3 and has cleared into the exit lane
    from frame 4. The ego waits stopped on the approach lane through frame 4 and
    enters at frame 5, once the junction is clear. The antecedent fires at frames
    1–3, and at each of those the ego is still outside at the next frame, so the
    obligation is discharged. Compliant, and the exact positive counterpart of
    `enters_one_frame_before_clearing`. -/
def traceWaitsForOccupantToClear : Trace :=
  [ sceneAt approachLane junctionLane "0.0" "0.0" "0.0" "1.0"
  , sceneAt approachLane junctionLane "0.0" "0.0" "0.0" "1.0"
  , sceneAt approachLane junctionLane "0.0" "0.0" "0.0" "1.0"
  , sceneAt approachLane exitLane     "0.0" "0.0" "0.0" "1.0"
  , sceneAt junctionLane exitLane     "2.0" "2.0" "0.5" "0.0"
  , sceneAt junctionLane exitLane     "4.0" "2.0" "0.5" "0.0" ]

/-- The ego is inside the junction from frame 1; `car_0` is on the cross
    approach for frames 1–2 and enters the junction at frame 3, so both occupy
    it together for frames 3–6. The ego did not enter an occupied intersection —
    it was there first — and co-presence is not the offence. The ego is never at
    a frame satisfying `¬ inJunction v j`, so its obligation is discharged
    vacuously everywhere. Compliant. This is the scenario that fails if
    occupancy rather than the entry transition is made the forbidden state; the
    late entrant here is `car_0`, whose grounding is gated out by `isEgo v`. -/
def traceEgoAlreadyInside : Trace :=
  [ sceneAt junctionLane crossLane    "5.0" "0.0" "0.3"
  , sceneAt junctionLane crossLane    "5.0" "0.0" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0" "0.3" ]

/-- The violation. `car_0` occupies the junction for all six frames. The ego is
    on the approach lane at frames 1–2 and inside the junction from frame 3. At
    frame 2 the antecedent holds — ego outside, `car_0` inside — and the ego is
    inside at frame 3. Violated. -/
def traceEntersOccupiedJunction : Trace :=
  [ sceneAt approachLane junctionLane "6.0" "0.0"  "0.4"
  , sceneAt approachLane junctionLane "5.5" "-0.5" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "-0.5" "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0"  "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0"  "0.3"
  , sceneAt junctionLane junctionLane "5.0" "0.0"  "0.3" ]

/-- The tight negative counterpart of `waits_for_occupant_to_clear`: the two
    traces differ by one frame of patience. `car_0` is in the junction through
    frame 3 and in the exit lane from frame 4; the ego is outside at frame 3 and
    inside at frame 4, so it committed to the entry while the junction was still
    occupied. At frame 3 the antecedent holds and the ego is inside at frame 4.
    Violated. -/
def traceEntersOneFrameBeforeClearing : Trace :=
  [ sceneAt approachLane junctionLane "1.0" "0.0" "0.2"
  , sceneAt approachLane junctionLane "1.5" "0.5" "0.3"
  , sceneAt approachLane junctionLane "2.0" "0.5" "0.3"
  , sceneAt junctionLane exitLane     "2.5" "0.5" "0.4"
  , sceneAt junctionLane exitLane     "3.0" "0.5" "0.4"
  , sceneAt junctionLane exitLane     "3.5" "0.5" "0.4" ]

def scenarios : List Scenario :=
  [ { name := "enters_clear_junction",             trace := traceEntersClearJunction,          expected := true }
  , { name := "waits_for_occupant_to_clear",       trace := traceWaitsForOccupantToClear,      expected := true }
  , { name := "ego_already_inside_when_other_enters", trace := traceEgoAlreadyInside,          expected := true }
  , { name := "enters_occupied_junction",          trace := traceEntersOccupiedJunction,       expected := false }
  , { name := "enters_one_frame_before_clearing",  trace := traceEntersOneFrameBeforeClearing, expected := false } ]

end TrafficSpec.Rules.Junction.R0006

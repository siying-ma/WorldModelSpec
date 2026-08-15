/-
  Rule R0004 — yielding within an intersection.

  Law text (id EX-JUNCTION-001, "Yielding within an intersection"):
    "A driver entering an intersection already occupied by another vehicle
     shall yield, and shall not remain within the intersection until the other
     vehicle has cleared it."

  Formalization notes
  -------------------
  * "occupies the intersection" is `Pred.inJunction e j`, which walks the
    graph's entity → lane → road → junction chain. This reads structure only,
    so it is available for every vehicle, not just ego. The rule is therefore
    NOT gated on `Pred.isEgo`: it quantifies over every ordered pair of
    distinct vehicles and every junction in the trace.
  * "entering an intersection already occupied" is read as a *transition*:
    at some frame `v` is outside `j` while `w` is inside `j`, and at the very
    next frame `v` is inside `j`. Formally
        □ ( ((¬ inJunction v j) ⋀ inJunction w j) ⟹ ¬ ◯ (inJunction v j) ).
    One frame is the finest granularity the trace offers, so "the moment of
    entry" is the step between consecutive frames. This is a choice: a coarser
    reading (entry within k frames of the other vehicle being inside) would
    also be defensible, but the text gives no window.
  * Who must yield is decided *only* by who arrives second. CARLA scene graphs
    carry no `right_of_way` field, so priority cannot be read off the data;
    "shall yield" is therefore identified with "shall not be the late entrant".
    Because the binders range over ordered pairs, the same formula is applied
    with the roles swapped, and whichever vehicle entered second is the one
    whose grounding fails. That symmetry is what makes a single formula do the
    work of the clause without a priority annotation.
  * The second half — "shall not remain within the intersection until the
    other vehicle has cleared it" — is treated as a *consequence* of the
    first, not as a separate conjunct. If no vehicle ever enters an occupied
    junction, co-occupancy cannot arise at all (barring simultaneous entry,
    below), so there is no state in which a vehicle could "remain alongside"
    another. The alternative — a blanket `□ ¬(inJunction v j ⋀ inJunction w j)`
    — was rejected deliberately: a CARLA junction spans several roads and
    lanes, so two vehicles crossing it legally in different directions are
    both `inJunction`, and that conjunct would flag almost every real capture.
    The clause is about the act of entering, not about co-presence as such.
  * Not covered, and outside what the text forbids: *simultaneous* entry, where
    both vehicles are outside `j` at frame i and both inside at frame i+1.
    Neither was "already occupied by another vehicle" at the moment of entry,
    so the clause as written does not speak to it. Recorded so a reviewer can
    disagree.
  * Finite-trace caveat: `◯` uses strong-next semantics, and atoms evaluate to
    false past the end of the trace (`Core/Semantics.lean`, `evalAtom`). So the
    consequent `¬ ◯ (inJunction v j)` is trivially true at the last frame — the
    end of a trace can never manufacture a spurious violation, but an entry
    that happens on the frame after the capture ends is invisible. This was
    checked against `Core/Semantics.lean` rather than assumed.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Junction.R0004

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- `v` does not cross into junction `j` on a frame at which `w` is already
    inside `j`. -/
def yieldsToOccupant (v w j : EntityId) : SFProp :=
  (((¬ₛ (inJunction v j)) ⋀ (inJunction w j)) ⟹ (¬ₛ (◯ (inJunction v j))))

/-- The rule, quantified over ordered pairs of vehicles and junctions. -/
def schema : PropertySchema where
  name    := "yield_occupied_junction"
  binders := [vehicleBinder "v", vehicleBinder "w", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    let j := arg env 2
    □ (yieldsToOccupant v w j)

def entry : RuleEntry where
  nodeId  := "Junction/R0004_yield_occupied_junction"
  lawRefs := ["EX-JUNCTION-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One junction with three lanes: an approach lane whose road is outside the
-- junction, a junction lane whose road is inside it, and an exit lane whose
-- road is outside it again. `travelsTo` chains them, as the generator does, so
-- `Pred.approachingJunction` also holds for a vehicle on the approach lane.
----------------------------------------------------------------------

private def approachLane : Nat := 10
private def junctionLane : Nat := 11
private def exitLane     : Nat := 12
private def approachRoad : Nat := 20
private def junctionRoad : Nat := 21
private def exitRoad     : Nat := 22
private def junctionNode : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1"
  , mkLane junctionLane "Lane 20_-1"
  , mkLane exitLane     "Lane 8_-1"
  , mkRoad approachRoad "Road 7"
  , mkRoad junctionRoad "Road 20"
  , mkRoad exitRoad     "Road 8"
  , mkJunction junctionNode "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel junctionRoad .isIn junctionNode
  , mkRel approachLane .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- One frame: ego (id 1) in lane `egoLane`, `car_0` (id 2) in lane
    `otherLane`. The ego↔other distance and angular edges are the ones the
    generator emits between ego and every other actor; the formula does not
    read them, but a hand-written trace should look like adapter output. -/
private def sceneAt (egoLane otherLane : Nat) : Scene :=
  frame
    ([mkEgo 1 .car "5.0" "0.0" "0.4" "0.0", mkActor 2 "car_0" .car]
      ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn egoLane, mkRel 2 .isIn otherLane
         , mkRel 1 .near 2, mkRel 2 .inSFrontOf 1 ])

/-- `car_0` holds the junction for three frames, ego waits on the approach lane
    and enters only once the junction is clear. -/
def traceWaitsForClear : Trace :=
  [ sceneAt approachLane junctionLane
  , sceneAt approachLane junctionLane
  , sceneAt approachLane junctionLane
  , sceneAt approachLane exitLane
  , sceneAt junctionLane exitLane
  , sceneAt junctionLane exitLane ]

/-- The mirror image: ego holds the junction, `car_0` waits and enters only
    after ego has cleared. Checks that the ordered-pair binding treats the two
    vehicles alike. -/
def traceEgoFirst : Trace :=
  [ sceneAt junctionLane approachLane
  , sceneAt junctionLane approachLane
  , sceneAt junctionLane approachLane
  , sceneAt exitLane     approachLane
  , sceneAt exitLane     junctionLane
  , sceneAt exitLane     junctionLane ]

/-- Ego enters the junction at frame 3 while `car_0` is still inside it — the
    forbidden conduct. Differs from `traceWaitsForClear` only in when ego
    leaves the approach lane. -/
def traceEntersOccupied : Trace :=
  [ sceneAt approachLane junctionLane
  , sceneAt approachLane junctionLane
  , sceneAt junctionLane junctionLane
  , sceneAt junctionLane junctionLane
  , sceneAt junctionLane exitLane
  , sceneAt exitLane     exitLane ]

/-- Here the late entrant is `car_0`, not ego: ego is inside the junction from
    frame 1 and `car_0` joins it at frame 3. Fails only if the formula is
    genuinely symmetric over the two vehicle binders. -/
def traceBothInside : Trace :=
  [ sceneAt junctionLane approachLane
  , sceneAt junctionLane approachLane
  , sceneAt junctionLane junctionLane
  , sceneAt exitLane     junctionLane
  , sceneAt exitLane     junctionLane
  , sceneAt exitLane     junctionLane ]

def scenarios : List Scenario :=
  [ { name := "waits_for_junction_to_clear",   trace := traceWaitsForClear,  expected := true }
  , { name := "ego_first_other_waits",         trace := traceEgoFirst,       expected := true }
  , { name := "enters_occupied_junction",      trace := traceEntersOccupied, expected := false }
  , { name := "both_enter_while_other_inside", trace := traceBothInside,     expected := false } ]

end TrafficSpec.Rules.Junction.R0004

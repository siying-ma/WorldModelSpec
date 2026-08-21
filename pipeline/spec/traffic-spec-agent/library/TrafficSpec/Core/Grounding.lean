/-
  TrafficSpec.Core.Grounding
  Symbolic grounding: quantified property schemas, and the machine-readable
  report that `tools/check_spec.py` consumes.

  Traffic law is quantified ("a vehicle approaching a junction shall …"), but a
  formula is evaluated over concrete entity ids. A `PropertySchema` is a formula
  parameterised by a list of bound entities; grounding instantiates it at every
  distinct assignment of trace entities to binders — the "all-vehicle" mode of
  SceneFlowLang. A schema holds on a trace iff **every** grounding holds.

  This is the layer the reference repository refers to as `SceneFlowSpec.Symbolic`
  but does not ship.
-/
import TrafficSpec.Core.Monitor

namespace TrafficSpec

/-- One quantified variable of a schema: a display label plus the entity types
    it may range over. Use `vehicleTypes` / `roadUserTypes` rather than a single
    type when the law says "vehicle" or "road user". -/
structure Binder where
  label : String
  types : List EntityType

/-- Convenience binders for the common cases.

    Pick the narrowest one that matches the law: a binder that admits types the
    rule cannot say anything about produces groundings that are trivially
    satisfied, which inflates the grounding count without testing anything.

    `proximityVehicleBinder` is the one to use when the rule needs a *distance*
    to the bound vehicle — it is restricted to the base classes the generator
    actually emits proximity edges for (see `Core/Scene.lean`, `RelLabel`). -/
def vehicleBinder (label : String) : Binder := ⟨label, vehicleTypes⟩
def proximityVehicleBinder (label : String) : Binder := ⟨label, proximityVehicleTypes⟩
/-- Any road user a distance to which actually exists — vehicles plus
    pedestrians and cycles. Use this, not `roadUserBinder`, whenever the rule
    needs `withinMetres` / `following` / an angular relation: `roadUserTypes`
    admits `van` and `vehicle`, which carry no proximity edge at all. -/
def proximityRoadUserBinder (label : String) : Binder := ⟨label, proximityTypes⟩
def roadUserBinder (label : String) : Binder := ⟨label, roadUserTypes⟩
def pedestrianBinder (label : String) : Binder := ⟨label, [.pedestrian]⟩
def laneBinder (label : String) : Binder := ⟨label, [.lane]⟩
def roadBinder (label : String) : Binder := ⟨label, [.road]⟩
def junctionBinder (label : String) : Binder := ⟨label, [.junction]⟩
def trafficLightBinder (label : String) : Binder := ⟨label, [.trafficLight]⟩
def stopSignBinder (label : String) : Binder := ⟨label, [.stopSign]⟩
def controlDeviceBinder (label : String) : Binder := ⟨label, controlDeviceTypes⟩
def landmarkBinder (label : String) : Binder := ⟨label, [.landmark]⟩

/-- A quantified property. `formula` receives the bound entity ids positionally;
    read them with `arg env 0`, `arg env 1`, … -/
structure PropertySchema where
  name    : String
  binders : List Binder
  formula : List EntityId → SFProp

/-- Positional access to a binding. Out-of-range indices yield entity `0`,
    which is not present in any well-formed trace, so a mis-indexed schema
    grounds to `false` rather than silently reading a neighbour. -/
def arg (env : List EntityId) (i : Nat) : EntityId := env.getD i ⟨0⟩

/-- One formalized rule: a schema plus its provenance. -/
structure RuleEntry where
  nodeId  : String
  lawRefs : List String
  schema  : PropertySchema

/-- A declared acceptance test: a trace and whether the rule should hold on it. -/
structure Scenario where
  name     : String
  trace    : Trace
  expected : Bool

----------------------------------------------------------------------
-- Grounding
----------------------------------------------------------------------

private def addNew (xs : List EntityId) (e : EntityId) : List EntityId :=
  if xs.contains e then xs else xs ++ [e]

/-- Every entity of one of the types `ts` appearing anywhere in the trace, in
    order of first appearance. Entities may enter and leave the graph, so
    candidates are collected across all frames, not just frame 0. -/
def traceEntityIds (τ : Trace) (ts : List EntityType) : List EntityId :=
  τ.foldl (fun acc s => (s.entitiesOfTypes ts).foldl (fun a e => addNew a e.id) acc) []

/-- Are all ids in a binding distinct? Two binders must never bind the same
    entity: a rule about a vehicle behind another vehicle is meaningless when
    both are the same car. -/
def distinctIds : List EntityId → Bool
  | []      => true
  | x :: xs => !xs.contains x && distinctIds xs

private def extend (τ : Trace) (b : Binder) (rest : List (List EntityId)) :
    List (List EntityId) :=
  (traceEntityIds τ b.types).foldr
    (fun e acc => (rest.map (fun r => e :: r)) ++ acc) []

private def rawBindings (τ : Trace) : List Binder → List (List EntityId)
  | []      => [[]]
  | b :: bs => extend τ b (rawBindings τ bs)

/-- Do all the bound entities appear together in at least one frame?

    `traceEntityIds` collects candidates across the whole trace, because
    entities enter and leave the graph. Without this filter the cross product
    also pairs entities that were never present at the same time — a car that
    left before another arrived. Such a binding cannot make any relation true,
    so it is trivially satisfied and cannot change `check`, but it *does* inflate
    the grounding count, and the grounding count is what `capture_eval` reads to
    decide whether a law was engaged at all. Measured on a real capture:
    `EX-FOLLOW-001` reported 12 groundings on footage where the ego never
    followed anything, which scores as an engaged, agreeing result. -/
def coPresent (τ : Trace) (env : List EntityId) : Bool :=
  τ.any (fun s => env.all (fun e => (s.getEntity e).isSome))

/-- All distinct groundings of a schema against a trace.

    Filtered to bindings whose entities are distinct *and* co-present in some
    frame. Dropping a non-co-present binding never hides a violation: every
    atom over an absent entity is false, so the binding was vacuously satisfied
    and contributed nothing to `check`. -/
def PropertySchema.bindings (sch : PropertySchema) (τ : Trace) : List (List EntityId) :=
  ((rawBindings τ sch.binders).filter distinctIds).filter (coPresent τ)

/-- Render a binding as `v=e9, w=e12`. -/
def describeBinding (bs : List Binder) (env : List EntityId) : String :=
  String.intercalate ", " ((bs.zip env).map (fun p => s!"{p.1.label}={p.2}"))

/-- Every grounding with its verdict. -/
def RuleEntry.groundings (r : RuleEntry) (τ : Trace) : List (String × Bool) :=
  (r.schema.bindings τ).map fun env =>
    (describeBinding r.schema.binders env, satisfies τ (r.schema.formula env))

/-- How many groundings the schema has on this trace. **Zero means the rule is
    vacuously satisfied** — the usual cause of a spec that looks correct and
    tests nothing. -/
def RuleEntry.groundingCount (r : RuleEntry) (τ : Trace) : Nat :=
  (r.schema.bindings τ).length

/-- The rule holds on a trace iff every grounding holds. -/
def RuleEntry.check (r : RuleEntry) (τ : Trace) : Bool :=
  (r.groundings τ).all (fun p => p.2)

/-- Frames the rule's formula needs before its bounded operators can complete.

    Independent of which entities are bound — binders only reach atoms, and every
    atom spans one frame — so it is computed on a placeholder environment. A
    trace shorter than this **cannot clear the rule**: see `SFProp.frameSpan`. -/
def RuleEntry.frameSpan (r : RuleEntry) : Nat :=
  (r.schema.formula (List.replicate r.schema.binders.length ⟨0⟩)).frameSpan

/-- Is `τ` long enough for this rule's verdict to mean anything? -/
def RuleEntry.traceLongEnough (r : RuleEntry) (τ : Trace) : Bool :=
  decide (r.frameSpan ≤ τ.length)

/-- Instantiate to closed named properties, for `checkAll`-style reporting. -/
def RuleEntry.instantiate (r : RuleEntry) (τ : Trace) : List NamedProperty :=
  (r.schema.bindings τ).map fun env =>
    { name    := r.schema.name ++ " [" ++ describeBinding r.schema.binders env ++ "]"
      formula := r.schema.formula env }

----------------------------------------------------------------------
-- Machine-readable report (parsed by tools/check_spec.py)
----------------------------------------------------------------------

private def scenarioLine (r : RuleEntry) (s : Scenario) : String :=
  let n      := r.groundingCount s.trace
  let actual := r.check s.trace
  let status :=
    if !r.traceLongEnough s.trace then "SHORT"
    else if n == 0 then "VACUOUS"
    else if actual == s.expected then "PASS"
    else "FAIL"
  s!"SCEN\t{s.name}\t{s.expected}\t{actual}\t{n}\t{status}"

private def groundingLines (r : RuleEntry) (s : Scenario) : List String :=
  (r.groundings s.trace).map fun p => s!"GROUND\t{s.name}\t{p.1}\t{p.2}"

/-- Per-frame truth bitmap for each grounding, so a failing scenario says
    *where* it went wrong instead of just that it did. -/
private def frameLines (r : RuleEntry) (s : Scenario) : List String :=
  (r.schema.bindings s.trace).map fun env =>
    let φ    := r.schema.formula env
    let bits := String.intercalate "" ((List.range s.trace.length).map
                  (fun i => if eval s.trace i φ then "1" else "0"))
    let desc := describeBinding r.schema.binders env
    s!"FRAMES\t{s.name}\t{desc}\t{bits}"

/-- A scenario counts only if the trace is long enough for the rule's bounded
    operators, grounds at least once, and matches the declared expectation.
    The length test comes first: a trace shorter than `frameSpan` reports
    `compliant` whatever it contains, so a positive scenario would "pass" for
    the wrong reason. -/
private def scenarioOk (r : RuleEntry) (s : Scenario) : Bool :=
  r.traceLongEnough s.trace
    && !(r.groundingCount s.trace == 0)
    && (r.check s.trace == s.expected)

/-- Full report for one node. `carla` is the bundled CARLA-shaped smoke trace:
    its grounding count tells us whether the rule can fire on realistic scene
    graphs at all. -/
def report (r : RuleEntry) (ss : List Scenario) (carla : Trace) : String :=
  let ok   := !ss.isEmpty && ss.all (scenarioOk r)
  let refs := String.intercalate "," r.lawRefs
  let header :=
    [ s!"NODE\t{r.nodeId}"
    , s!"NAME\t{r.schema.name}"
    , s!"LAWREFS\t{refs}"
    , s!"BINDERS\t{r.schema.binders.length}"
    , s!"SPAN\t{r.frameSpan}"
    , s!"SCENARIOS\t{ss.length}" ]
  let body := ss.foldr
    (fun s acc => (scenarioLine r s :: (groundingLines r s ++ frameLines r s)) ++ acc) []
  let carlaCount := r.groundingCount carla
  let carlaVal   :=
    if !r.traceLongEnough carla then "short"
    else if carlaCount == 0 then "none"
    else toString (r.check carla)
  let footer :=
    [ s!"CARLA\t{carlaCount}\t{carlaVal}"
    , if ok then "RESULT\tOK" else "RESULT\tFAIL" ]
  String.intercalate "\n" (header ++ body ++ footer)

/-- `#eval` entry point used by the generated gate harness. -/
def reportIO (r : RuleEntry) (ss : List Scenario) (carla : Trace) : IO Unit :=
  IO.println (report r ss carla)

end TrafficSpec

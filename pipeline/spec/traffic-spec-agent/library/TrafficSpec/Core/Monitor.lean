/-
  TrafficSpec.Core.Monitor
  Runtime monitor: check a property against a finite trace.
  Ported from scene-flow-spec-lean (`SceneFlowSpec/Monitor.lean`).
-/
import TrafficSpec.Core.Semantics

namespace TrafficSpec

/-- Verdict of monitoring one property against one trace. -/
inductive Verdict where
  | satisfied
  | violated
  deriving DecidableEq, Repr, BEq

instance : ToString Verdict where
  toString
    | .satisfied => "SATISFIED"
    | .violated  => "VIOLATED"

/-- Evaluate `φ` from position 0 of `τ`. -/
def monitor (τ : Trace) (φ : SFProp) : Verdict :=
  if satisfies τ φ then .satisfied else .violated

/-- A closed (fully grounded) property with a name, for reporting. -/
structure NamedProperty where
  name    : String
  formula : SFProp

/-- Check a named property and render a one-line report. -/
def checkProperty (τ : Trace) (p : NamedProperty) : String :=
  s!"[{monitor τ p.formula}] {p.name} (trace length = {τ.length})"

/-- Check several named properties against one trace. -/
def checkAll (τ : Trace) (ps : List NamedProperty) : List String :=
  ps.map (checkProperty τ)

/-- Per-frame truth of `φ`: which positions it holds at. Indispensable for
    diagnosing why a scenario failed. -/
def monitorFrames (τ : Trace) (φ : SFProp) : List (Nat × Bool) :=
  (List.range τ.length).map (fun i => (i, eval τ i φ))

end TrafficSpec

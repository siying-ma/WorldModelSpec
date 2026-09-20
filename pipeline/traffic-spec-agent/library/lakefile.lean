import Lake
open Lake DSL

package «traffic-spec» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

-- The specification library: the frozen Core, the generated rule index and the rules.
@[default_target]
lean_lib «TrafficSpec» where
  srcDir := "."

-- Build-time checks for the Core arithmetic and semantics. A separate root so that the
-- concrete values they need stay out of the frozen Core modules while still failing
-- `lake build` if anything regresses.
@[default_target]
lean_lib «TrafficSpecTests» where
  srcDir := "."
  roots := #[`TrafficSpec.Tests]

-- Acceptance witnesses: evidence ABOUT a rule, never read by anything that runs the library.
-- Depends on `TrafficSpec`; the dependency never runs the other way.
@[default_target]
lean_lib «TrafficSpecWitness» where
  srcDir := "."
  roots := #[`TrafficSpecWitness]

-- The monitor: decodes traces at run time and evaluates the registered rules.
lean_exe «monitor» where
  root := `Main

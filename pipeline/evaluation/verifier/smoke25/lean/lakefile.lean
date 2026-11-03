import Lake
open Lake DSL

package «traffic-verifier» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

-- The frozen Core of the full split, the registered rules and concepts, and the index.
@[default_target]
lean_lib «TrafficSpec» where
  srcDir := "."

-- The monitor: decodes a trace at run time and evaluates the registered rules.
lean_exe «monitor» where
  root := `Main

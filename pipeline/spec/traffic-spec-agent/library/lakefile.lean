import Lake
open Lake DSL

package «traffic-spec» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib «TrafficSpec» where
  srcDir := "."

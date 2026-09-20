/-
  TrafficSpec.Index — generated registry of formalized rules. Empty until the first run.
  `run_spec index` regenerates it from `Rules/**`; do not edit.
-/
import TrafficSpec.Core
namespace TrafficSpec
/-- Every registered rule, in file order. -/
def allRules : List Rule := []
end TrafficSpec

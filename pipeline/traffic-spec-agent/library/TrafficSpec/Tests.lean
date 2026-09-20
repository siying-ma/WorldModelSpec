/-
  TrafficSpec.Tests
  Build-time checks. Core carries no concrete values; the values that pin down its arithmetic
  and semantics live here and fail `lake build` when anything regresses.
-/
import TrafficSpec.Tests.Tri
import TrafficSpec.Tests.Units
import TrafficSpec.Tests.Time
import TrafficSpec.Tests.Atoms
import TrafficSpec.Tests.Semantics
import TrafficSpec.Tests.Grounding
import TrafficSpec.Tests.Decode

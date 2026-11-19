/-
  TrafficSpec.Tests
  Build-time checks. Core carries no concrete values; the values that pin down its arithmetic
  and semantics live here and fail `lake build` when anything regresses.
-/
import TrafficSpec.Tests.Tri
import TrafficSpec.Tests.Units
import TrafficSpec.Tests.Time
import TrafficSpec.Tests.Temporal
import TrafficSpec.Tests.Atoms
import TrafficSpec.Tests.SurfaceGap
import TrafficSpec.Tests.Semantics
import TrafficSpec.Tests.Grounding
import TrafficSpec.Tests.Decode
import TrafficSpec.Tests.Adequacy
import TrafficSpec.Tests.Concept
import TrafficSpec.Tests.Rewrites
import TrafficSpec.Tests.TraceLint
import TrafficSpec.Tests.Certificate
import TrafficSpec.Tests.Intentions
import TrafficSpec.Tests.Facts
import TrafficSpec.Tests.Refinement
import TrafficSpec.Tests.TravelRegion
import TrafficSpec.Tests.Entrance
import TrafficSpec.Tests.EntranceCarrier
import TrafficSpec.Tests.Chains
import TrafficSpec.Tests.PathSearch
import TrafficSpec.Tests.HistoryBoundary
import TrafficSpec.Tests.RegionOffsetAlong
import TrafficSpec.Tests.ApproachChain
import TrafficSpec.Tests.EvalFast
import TrafficSpec.Tests.HeadingSince
import TrafficSpec.Tests.Attributes
import TrafficSpec.Tests.SignedPlaces
import TrafficSpec.Tests.RuleSets
import TrafficSpec.Tests.SampledDuration
import TrafficSpec.Tests.RoadProfile

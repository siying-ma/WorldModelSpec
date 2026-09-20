import TrafficSpec.Core.Tri
namespace TrafficSpec.Tests
open TrafficSpec Tri

#guard and .f .u = .f
#guard and .u .f = .f
#guard and .t .u = .u
#guard and .u .t = .u
#guard and .t .t = .t
#guard or .t .u = .t
#guard or .u .f = .u
#guard or .f .f = .f
#guard not .u = .u
#guard implies .f .u = .t      -- a false antecedent discharges an unreadable consequent
#guard implies .t .u = .u
#guard implies .u .t = .t
#guard ofOption none = .u
#guard ofOption (some true) = .t
#guard all [] = .t
#guard all [.t, .u] = .u
#guard all [.f, .u] = .f
#guard any [] = .f
#guard any [.u, .t] = .t
#guard any [.u, .f] = .u
example : ∀ a b : Tri, and a b = and b a := fun a b => Tri.and_comm a b
end TrafficSpec.Tests

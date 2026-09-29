import TrafficSpec.Core.Foundations.Time
namespace TrafficSpec.Tests
open TrafficSpec Time Units

-- adequacy: gaps of 0.5 s are adequate for a 1 s window, gaps of 0.6 s are not
#guard adequate (seconds 1) [seconds 0, milliseconds 500, seconds 1, milliseconds 1500]
#guard !(adequate (seconds 1) [seconds 0, milliseconds 600, milliseconds 1200])
#guard adequate (seconds 1) [seconds 7]                    -- a single observation
#guard adequate (seconds 1) []
#guard adequate (seconds 2) [seconds 0, seconds 1, seconds 2]   -- a gap of exactly d/2 is adequate

-- windows over a 0.5 s-sampled trace: positions 0, 0.5, 1.0, 1.5, 2.0 s
def pos5 : Array (Option Q) := #[some (seconds 0), some (milliseconds 500), some (seconds 1),
                                 some (milliseconds 1500), some (seconds 2)]
def back := backWindows pos5 (seconds 1)
#guard back.size = 5
#guard (back[4]!).map (·.j0) = some 2
#guard (back[4]!).map (·.covered) = some true       -- an observation precedes the window
#guard (back[4]!).map (·.adequate) = some true
#guard (back[1]!).map (·.covered) = some false      -- the window runs off the start
#guard (back[1]!).map (·.j0) = some 0
#guard (back[2]!).map (·.covered) = some true       -- exactly d behind: the boundary is observed
#guard ((backWindows pos5 (milliseconds 500))[4]!).map (·.adequate) = some false   -- gaps 0.5 > d/2
def fwd := forwardWindows pos5 (seconds 1)
#guard (fwd[0]!).map (·.jl) = some 2
#guard (fwd[0]!).map (·.covered) = some true
#guard (fwd[3]!).map (·.covered) = some false       -- runs off the end
#guard (fwd[3]!).map (·.jl) = some 4
-- a missing position inside the window makes the window undefined, a missing own position too
def posGap : Array (Option Q) := #[some (seconds 0), none, some (seconds 1), some (milliseconds 1500)]
#guard (backWindows posGap (seconds 2))[2]! = none
#guard (backWindows posGap (seconds 2))[1]! = none
#guard ((backWindows posGap (milliseconds 500))[3]!).map (·.j0) = some 2   -- the gap lies outside
#guard (forwardWindows posGap (seconds 2))[0]! = none
-- irregular sampling: the range maximum over the gaps decides adequacy
def posIrr : Array (Option Q) := #[some (seconds 0), some (milliseconds 400), some (milliseconds 1500), some (seconds 2)]
#guard ((backWindows posIrr (seconds 2))[3]!).map (·.adequate) = some false   -- a 1.1 s gap in a 2 s window
#guard ((backWindows posIrr (seconds 2))[1]!).map (·.adequate) = some true
-- path measure behaves identically (metres)
#guard adequate (metres 30) [metres 0, metres 15, metres 30, metres 45]
#guard Q.eq (ofTimestamp 2500) (Q.mk' 5 2)
#guard (Q.mk' 15 10).num = 3 && (Q.mk' 15 10).den = 2         -- rationals are kept in lowest terms
#guard (Q.add (Q.mk' 1 3) (Q.mk' 2 3)).den = 1
end TrafficSpec.Tests

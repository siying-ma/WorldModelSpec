import TrafficSpec.Core.Time
namespace TrafficSpec.Tests
open TrafficSpec Time Units

-- adequacy: gaps of 0.5 s are adequate for a 1 s window, gaps of 0.6 s are not
#guard adequate (seconds 1) [seconds 0, milliseconds 500, seconds 1, milliseconds 1500]
#guard !(adequate (seconds 1) [seconds 0, milliseconds 600, milliseconds 1200])
#guard adequate (seconds 1) [seconds 7]                    -- a single observation
#guard adequate (seconds 1) []
-- a gap of exactly d/2 is adequate
#guard adequate (seconds 2) [seconds 0, seconds 1, seconds 2]

-- windows over a 0.5 s-sampled trace: positions 0, 0.5, 1.0, 1.5, 2.0 s
def pos5 : List (Option Q) := [some (seconds 0), some (milliseconds 500), some (seconds 1),
                               some (milliseconds 1500), some (seconds 2)]
#guard (windowBack pos5 4 (seconds 1)).map (·.1) = some [2, 3, 4]
#guard (windowBack pos5 4 (seconds 1)).map (·.2) = some true      -- an observation precedes the window
#guard (windowBack pos5 1 (seconds 1)).map (·.2) = some false     -- the window runs off the start
#guard (windowBack pos5 1 (seconds 1)).map (·.1) = some [0, 1]
#guard windowBack pos5 9 (seconds 1) = none                        -- out of range
#guard (windowForward pos5 0 (seconds 1)).map (·.1) = some [0, 1, 2]
#guard (windowForward pos5 0 (seconds 1)).map (·.2) = some true
#guard (windowForward pos5 3 (seconds 1)).map (·.2) = some false   -- runs off the end
-- a missing position inside the window makes the window undefined
def posGap : List (Option Q) := [some (seconds 0), none, some (seconds 1)]
#guard windowBack posGap 2 (seconds 2) = none
-- path measure behaves identically (metres)
#guard adequate (metres 30) [metres 0, metres 15, metres 30, metres 45]
#guard !(adequate (metres 30) [metres 0, metres 16])
#guard Q.eq (ofTimestamp 2500) (Q.mk' 5 2)
end TrafficSpec.Tests

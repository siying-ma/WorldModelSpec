import TrafficSpec.Core.Units
namespace TrafficSpec.Tests
open TrafficSpec Units

#guard Q.eq (feet 1) (inches 12)
#guard Q.eq (feet 3) (Q.mk' 9144 10000)           -- 0.9144 m exactly
#guard Q.eq (miles 1) (feet 5280)
#guard Q.eq (yards 1) (feet 3)
#guard Q.eq (kmh 36) (metresPerSecond 10)         -- exact, which an integer mm/s unit could not do
#guard Q.eq (mph 60) (Q.mk' 268224 10000)         -- 26.8224 m/s exactly
#guard Q.lt (mph 15) (kmh 25)                     -- 6.7056 < 6.9444…
#guard Q.gt (mph 25) (kmh 40)                     -- 11.176 > 11.111…
#guard Q.eq (minutes 1) (seconds 60)
#guard Q.eq (hours 1) (minutes 60)
#guard Q.eq (milliseconds 1500) (Q.mk' 3 2)
#guard Q.eq (micrometres 1000000) (metres 1)
#guard Q.eq (Q.add (feet 1) (inches 6)) (inches 18)
#guard Q.eq (Q.sub (metres 5) (centimetres 50)) (Q.mk' 45 10)
#guard Q.eq (Q.div (metres 20) (metresPerSecond 4)) (seconds 5)   -- distance ÷ speed = time
#guard Q.isZero (Q.div (metres 1) Q.zero)                        -- division by zero is guarded
#guard Q.eq (Q.half (seconds 3)) (Q.mk' 3 2)
#guard Q.eq (Q.abs (Q.neg (feet 2))) (feet 2)
#guard Q.le (Q.min (mph 30) (kmh 50)) (kmh 50)
#guard Q.eq (percent 50) (Q.mk' 1 2)
#guard isqrt 1000000 = 1000
#guard isqrt 2 = 1
#guard isqrt 15 = 3
#guard isqrt 16 = 4
#guard isqrt 999999999999 = 999999
#guard isqrt (10^24) = 10^12
end TrafficSpec.Tests

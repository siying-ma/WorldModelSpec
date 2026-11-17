/-
  Witnesses for LVMC_11_12_070_B.

  Geometry (the witness's own figures; none appears in the rule):
    - intersection j (region 10): the square x, y ∈ [-5, 5] m;
    - through lane c (region 11): x ∈ [-30, -5], y ∈ [-5, 0], eastbound, enters j; no device
      governs it (a stop sign in branch_1, a flashing-yellow signal in branch_5/6/11);
    - cross lane c2 (region 12): x ∈ [0, 5], y ∈ [-10, -5] (y ∈ [-20, -5] in branch_9–11),
      northbound, enters j; stop sign 20 governs it (a yield sign in branch_4/10, a flashing-red
      signal in branch_5/6/11, a yield sign and a flashing-yellow signal in branch_16);
    - branch_15 adds an exit lane north of j entering a second intersection; branch_16 a
      southbound north approach governed by a stop sign and a flashing-red signal.
    - subject (track 1): a car eastbound along y = -2.5 m; the entering vehicle o (track 2): a car
      northbound along x = 2.5 m; w (track 3, branch_7): a car eastbound along y = -2.5 m.
      Cars are 4.6 m by 2.0 m (half-extents 2.3, 1.0, 0.75 m).
    - one observation per second from t = 0; the first scene is repeated 2 s before and the last
      4 s after, so the look-ahead of p.conflict_horizon (3 s) is covered; each witness judges the
      instants of its own timeline (`window`).
  Against the reading (horizon 3 s, centre clearance 3 m, halt tolerance 0.1 m/s):
    - forbid at 7 s: subject at x = -21 m, 10 m/s; o in j at (2.5, -2.5), 0.5 m/s: closest approach
      after 2.34 s at 1.17 m (< 3 m), subject speed 10 m/s (> 0.1);
    - o halts (0 m/s) on c2 at 2 s and 3 s, starts at 4 s while the subject is still 53 m back,
      off the through lane (no through vehicle in danger with it).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_12_070_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_12_070_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Decimetres, for positions. -/
def dm (n : Int) : Q := Units.centimetres (n * 10)
/-- Tenths of a metre per second, for speeds. -/
def tenthMps (n : Int) : Q := Units.micrometresPerSecond (n * 100000)

def carHalfExtent : Q × Q × Q := (cm 230, cm 100, cm 75)

def car (track : TrackId) (pos : Vec) (heading : Vec) (v : Int) : RoadUser :=
  Build.user track [.motorVehicle] pos heading (tenthMps v) carHalfExtent

def intersectionJ : Structure := Build.rect 10 .intersection (m (-5)) (m (-5)) (m 5) (m 5)
def throughLane : Structure :=
  Build.lane 11 [(m (-30), m (-5)), (m (-5), m (-5)), (m (-5), m 0), (m (-30), m 0)] Build.east
    (enters := some 10)
def crossLane : Structure :=
  Build.lane 12 [(m 0, m (-10)), (m 5, m (-10)), (m 5, m (-5)), (m 0, m (-5))] Build.north
    (enters := some 10)
def layout : List Structure := [intersectionJ, throughLane, crossLane]

def stopOnCross : Device := Build.sign 20 .stopSign [12]

/-- An episode: per second, the subject's (x in dm, speed in 0.1 m/s) on y = -2.5 m eastbound,
    o's (y in dm, speed in 0.1 m/s) on x = 2.5 m northbound (absent where the list ends), and any
    further users. -/
def episode (subj : List (Int × Int)) (oth : List (Int × Int)) (devs : List Device)
    (extra : Nat → List RoadUser := fun _ => []) (structs : List Structure := layout)
    (subjY : Int := -25) : Trace :=
  Build.pad
    (Build.trace subj.length 0 (Units.seconds 1) fun k t =>
      let s := subj.getD k (0, 0)
      let subjU := car 1 (dm s.1, dm subjY) Build.east s.2
      let others :=
        if k < oth.length then
          let o := oth.getD k (0, 0)
          [car 2 (dm 25, dm o.1) Build.north o.2]
        else []
      Build.scene t (some 1) (subjU :: others ++ extra k) structs devs)
    (Units.seconds 2) (Units.seconds 4) (Units.seconds 1)

/-- The cross lane c2 lengthened to y ∈ [-20, -5] m, so a follower can queue on it behind o. -/
def crossLaneLong : Structure :=
  Build.lane 12 [(m 0, m (-20)), (m 5, m (-20)), (m 5, m (-5)), (m 0, m (-5))] Build.north
    (enters := some 10)
def layoutLong : List Structure := [intersectionJ, throughLane, crossLaneLong]

/-- An exit lane north of j (x ∈ [0, 5], y ∈ [5, 30], northbound), an approach to the next
    intersection (region 14, y ∈ [30, 40]), not to j. -/
def exitLane : Structure :=
  Build.lane 13 [(m 0, m 5), (m 5, m 5), (m 5, m 30), (m 0, m 30)] Build.north (enters := some 14)
def nextJunction : Structure := Build.rect 14 .intersection (m (-5)) (m 30) (m 5) (m 40)
def layoutExit : List Structure := layout ++ [exitLane, nextJunction]

/-- A southbound approach to j from the north (x ∈ [-5, 0], y ∈ [5, 20]). -/
def northApproach : Structure :=
  Build.lane 15 [(m (-5), m 5), (m 0, m 5), (m 0, m 20), (m (-5), m 20)] Build.south
    (enters := some 10)
def layoutNorth : List Structure := layout ++ [northApproach]

/-- The instants 0 … n−1 s. -/
def upTo (n : Int) : Option (Timestamp × Timestamp) := some (0, (n - 1) * 1000)

/-- The subject keeps 10 m/s, on the through lane only at 7 s (x = -21 m). -/
def subjForbid : List (Int × Int) :=
  [(-910, 100), (-810, 100), (-710, 100), (-610, 100), (-510, 100), (-410, 100), (-310, 100), (-210, 100)]

/-- o: off c2 at 0 s, on c2 at 1 s, at rest on c2 at 2–3 s, moving on c2 at 4 s, in j from 5 s. -/
def oHalts : List (Int × Int) :=
  [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-65, 10), (-45, 15), (-35, 10), (-25, 5)]

/-- o slows on c2 but never below 0.8 m/s, in j from 5 s. -/
def oRolls : List (Int × Int) :=
  [(-120, 30), (-95, 20), (-80, 15), (-70, 10), (-62, 8), (-45, 15), (-35, 10), (-25, 5)]

/-- `forbid` (violated): Subject vehicle on a lane entering j with no device; o halts at the stop sign on the cross approach and starts into j when no through vehicle is within the conflict bound; the subject then arrives and the subject keeps its speed and the constant-velocity closest approach of centres is below p.conflict_centre_clearance within p.conflict_horizon. -/
def forbidTrace : Trace := episode subjForbid oHalts [stopOnCross]

/-- `permit` (compliant): Same scene; the subject brakes to a halt short of j while o crosses; while the closest approach is below the clearance the subject's speed is at or below p.halt_speed_tolerance, and no contact occurs. -/
def permitTrace : Trace :=
  episode
    [(-910, 100), (-810, 100), (-710, 100), (-610, 100), (-510, 100), (-410, 80), (-340, 60), (-290, 40),
     (-260, 20), (-250, 0), (-250, 0), (-250, 0)]
    (oHalts ++ [(-10, 20), (15, 30), (45, 30), (80, 30)])
    [stopOnCross]

/-- `idle` (not_applicable): The subject approaches j on the through approach, but no vehicle is on or entering from a stop-sign or yield-sign approach of j. -/
def idleTrace : Trace :=
  episode [(-280, 80), (-200, 80), (-130, 60), (-80, 40)] [] [stopOnCross]

/-- `blind` (unknown): As forbid, but the source does not observe which carriers the stop sign governs, so whether o's approach is an entrance to a through highway is unknown. -/
def blindTrace : Trace :=
  episode subjForbid oHalts [{ Build.sign 20 .stopSign [] with governsObserved := false }]

/-- `branch_1` (not_applicable): All-way stop: the subject's own carrier is governed by a stop sign, so it is not on a through highway. -/
def branch_1Trace : Trace :=
  episode subjForbid oHalts [stopOnCross, Build.sign 21 .stopSign [11]]

/-- `branch_2` (not_applicable): As forbid, except that o never comes to rest at its stop sign before entering j: it has not so yielded, and the duty does not arise. -/
def branch_2Trace : Trace := episode subjForbid oRolls [stopOnCross]

/-- `branch_3` (not_applicable): As forbid, except that o halts and then pulls into j while the subject is already within the conflict bound of it: o has not so yielded.
    At 4 s o starts from rest at (2.5, -6) at 2 m/s while the subject is on the through lane at
    x = -25 m, 10 m/s: closest approach after 2.71 s at 1.96 m. -/
def branch_3Trace : Trace :=
  episode [(-650, 100), (-550, 100), (-450, 100), (-350, 100), (-250, 100), (-150, 100)]
    [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-60, 20), (-40, 20)]
    [stopOnCross]

/-- `branch_4` (violated): o's approach is governed by a yield sign; o slows without halting (no
    halt is required there) and enters j; the subject arrives as in forbid. -/
def branch_4Trace : Trace := episode subjForbid oRolls [Build.sign 20 .yieldSign [12]]

/-- Flashing-red operation: red flashes on the cross approach, yellow on the through approach. -/
def flashingOps : List Device :=
  [Build.signal 30 [12] [.flashingRed], Build.signal 31 [11] [.flashingYellow]]

/-- `branch_5` (violated): o's approach is governed by a signal showing flashing red (the
    subject's by one showing flashing yellow); o halts and enters; the subject arrives as in forbid. -/
def branch_5Trace : Trace := episode subjForbid oHalts flashingOps

/-- `branch_6` (not_applicable): as branch_5, but o never comes to rest at the flashing red. -/
def branch_6Trace : Trace := episode subjForbid oRolls flashingOps

/-- w, eastbound at 10 m/s: through lane at 2–3 s, in j at 4 s (x = -2 m), past j after. -/
def wCrossing (k : Nat) : List RoadUser :=
  let xs : List Int := [-420, -320, -220, -120, -20, 80, 180, 280]
  [car 3 (dm (xs.getD k 380), dm (-25)) Build.east 100]

/-- `branch_7` (not_applicable): o halts, then pulls out at 4 s from (2.5, -5.5) at 2 m/s while w
    crosses j at (-2, -2.5), 10 m/s (closest approach after 0.49 s at 2.06 m): o has not so
    yielded; the subject later arrives as in forbid. -/
def branch_7Trace : Trace :=
  episode subjForbid
    [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-55, 20), (-40, 10), (-32, 8), (-25, 5)]
    [stopOnCross] wCrossing

/-- `branch_8` (compliant): o waits at rest on c2 at the stop sign and enters j at 6 s; at 3–5 s it is
    about to enter (within the horizon) and the subject, creeping at 1 m/s on the through lane
    far back, is in no danger of a crash with it. -/
def branch_8Trace : Trace :=
  episode [(-290, 10), (-280, 10), (-270, 10), (-260, 10), (-250, 10), (-240, 10), (-230, 10)]
    [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-75, 0), (-75, 0), (-45, 20)]
    [stopOnCross]

/-- o starting off the lengthened c2 (y = -22 m), then as `oHalts` / `oRolls`. -/
def oHaltsLong : List (Int × Int) := (-220, 30) :: oHalts.drop 1
def oRollsLong : List (Int × Int) := (-220, 30) :: oRolls.drop 1

/-- A follower f (track 4) on the lengthened c2 behind o, closing on it at 3 m/s and stopping at
    y = -11 m: at 4 s, 5.5–5.8 m behind o and 2–2.2 m/s faster, its closest approach to o is 0 m
    within 2.6–2.8 s. f is on a carrier with an entrance device, so it is no through vehicle. -/
def follower (k : Nat) : List RoadUser :=
  let xs : List (Int × Int) :=
    [(-270, 30), (-210, 30), (-180, 30), (-150, 30), (-120, 30), (-110, 0), (-110, 0), (-110, 0)]
  let p := xs.getD k (-110, 0)
  [car 4 (dm 25, dm p.1) Build.north p.2]

/-- `branch_9` (violated): as forbid on the lengthened c2, with a follower closing on o behind it
    under the same stop sign when o starts at 4 s; the follower is not on the through highway, so o
    has still so yielded. -/
def branch_9Trace : Trace :=
  episode subjForbid oHaltsLong [stopOnCross] follower (structs := layoutLong)

/-- `branch_10` (violated): as branch_4 (yield sign, o rolls) with the follower under the yield sign. -/
def branch_10Trace : Trace :=
  episode subjForbid oRollsLong [Build.sign 20 .yieldSign [12]] follower (structs := layoutLong)

/-- `branch_11` (violated): as branch_5 (flashing red on c2, flashing yellow on c) with the
    follower under the flashing red. -/
def branch_11Trace : Trace :=
  episode subjForbid oHaltsLong flashingOps follower (structs := layoutLong)

/-- A cyclist (track 6, a bicycle, no vehicle of DEF-NRS-484A-320) on the through lane at 5 m/s:
    at 4 s at (-8, -2.5), closest approach to o (starting at 1 m/s) 1.87 m after 2.17 s; it stops
    at x = -6 m. -/
def cyclist (k : Nat) : List RoadUser :=
  let xs : List (Int × Int) :=
    [(-280, 50), (-230, 50), (-180, 50), (-130, 50), (-80, 50), (-60, 10), (-60, 0), (-60, 0)]
  let p := xs.getD k (-60, 0)
  [Build.user 6 [.bicycle] (dm p.1, dm (-25)) Build.east (tenthMps p.2) (cm 90, cm 30, cm 80)]

/-- `branch_12` (violated): as forbid, but o starts while a cyclist on the through lane is in
    danger of a crash with it; a bicycle is no vehicle, so o has still so yielded to the vehicles. -/
def branch_12Trace : Trace := episode subjForbid oHalts [stopOnCross] cyclist

/-- `branch_13` (violated): o halts, creeps at 0.2 m/s at 4 s while the subject, on the through lane
    at x = -25 m and 10 m/s, would pass 3.95 m from it after 2.76 s (above the clearance); the
    subject slows to 2 m/s (closest approach 8.8 s ahead, beyond the horizon) while o moves up at
    1 m/s, then at 7 s, with o in j, closes at 8 m/s: closest approach 0.53 m after 2.06 s. -/
def branch_13Trace : Trace :=
  episode
    [(-650, 100), (-550, 100), (-450, 100), (-350, 100), (-250, 100), (-180, 20), (-160, 20), (-140, 80)]
    [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-70, 2), (-55, 10), (-40, 10), (-30, 5)]
    [stopOnCross]

/-- `branch_14` (violated): o has halted and waits at rest at (2.5, -6) to enter j at 5 s; the
    subject, on the through lane along y = -4 m at 10 m/s, at 4 s would pass 2.0 m from o's centre
    after 2.75 s: the subject does not give way to the vehicle about to enter. -/
def branch_14Trace : Trace :=
  episode [(-650, 100), (-550, 100), (-450, 100), (-350, 100), (-250, 100), (-150, 100)]
    [(-120, 30), (-95, 20), (-60, 0), (-60, 0), (-60, 0), (-45, 15)]
    [stopOnCross] (subjY := -40)

/-- A car (track 5) at rest in the exit lane north of j at (2.5, 6). -/
def parkedAhead (_k : Nat) : List RoadUser := [car 5 (dm 25, dm 60) Build.north 0]

/-- `branch_15` (violated): o halts, then at 4 s starts from (2.5, -6) at 5 m/s toward a car at rest
    in the exit lane 12 m ahead (closest approach 0 m after 2.4 s); that lane enters the next
    intersection, not j, so the car is not on the through highway at j and o has still so yielded;
    o stops in j and the subject arrives at 10 m/s (closest approach 0 m after 2.35 s). -/
def branch_15Trace : Trace :=
  episode subjForbid
    [(-120, 30), (-95, 20), (-75, 0), (-75, 0), (-60, 50), (-35, 10), (-25, 0), (-25, 0)]
    [stopOnCross] parkedAhead (structs := layoutExit)

/-- `branch_16` (violated): o's approach is governed by a yield sign and a signal showing flashing
    yellow; the stop sign and the flashing-red signal govern the north approach, not o's; no halt
    is required of o, which rolls in; the subject arrives as in forbid. -/
def branch_16Trace : Trace :=
  episode subjForbid oRolls
    [Build.sign 20 .yieldSign [12], Build.signal 33 [12] [.flashingYellow],
     Build.sign 22 .stopSign [15], Build.signal 32 [15] [.flashingRed]]
    (structs := layoutNorth)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_12_070_B"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := upTo 8)
  , witness "permit" permitTrace .compliant (window := upTo 12)
  , witness "idle" idleTrace .notApplicable (window := upTo 4)
  , witness "blind" blindTrace (.unknown []) ["dev.governs"] (window := upTo 8)
  , witness "branch_1" branch_1Trace .notApplicable (window := upTo 8)
  , witness "branch_2" branch_2Trace .notApplicable (window := upTo 8)
  , witness "branch_3" branch_3Trace .notApplicable (window := upTo 6)
  , witness "branch_4" branch_4Trace .violated (window := upTo 8)
  , witness "branch_5" branch_5Trace .violated (window := upTo 8)
  , witness "branch_6" branch_6Trace .notApplicable (window := upTo 8)
  , witness "branch_7" branch_7Trace .notApplicable (window := upTo 8)
  , witness "branch_8" branch_8Trace .compliant (window := some (3000, 5000))
  , witness "branch_9" branch_9Trace .violated (window := upTo 8)
  , witness "branch_10" branch_10Trace .violated (window := upTo 8)
  , witness "branch_11" branch_11Trace .violated (window := upTo 8)
  , witness "branch_12" branch_12Trace .violated (window := upTo 8)
  , witness "branch_13" branch_13Trace .violated (window := upTo 8)
  , witness "branch_14" branch_14Trace .violated (window := upTo 6)
  , witness "branch_15" branch_15Trace .violated (window := upTo 8)
  , witness "branch_16" branch_16Trace .violated (window := upTo 8) ]

end TrafficSpecWitness.LVMC_11_12_070_B

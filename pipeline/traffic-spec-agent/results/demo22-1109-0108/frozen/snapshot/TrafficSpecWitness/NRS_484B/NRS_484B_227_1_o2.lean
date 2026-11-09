/-
  Witnesses for NRS_484B_227_1_o2.

  The geometry. One divided highway running east–west, every figure this file's own:
    region 1  the way itself, a `highway` from x = −200 m to x = 200 m, y ∈ [−20, 20] m
    region 2  the nearside (southern) `roadway`, y ∈ [−12, −2] m
    region 3  the offside (northern) `roadway`, y ∈ [2, 12] m
    region 4  the kerbed central `median_or_divider`, y ∈ [−2, 2] m, opening recorded as absent
  and, where a scene needs them,
    region 5  a crossover: a `median_or_divider` at x ∈ [20, 40] m with its opening recorded
    region 6  either the dividing section east of the crossover, or an `intersection` established
              on the way at x ∈ [62, 82] m
    region 7  a painted `centre_line` (the undivided way of `idle`)
  Every region records the way it lies on (region 1). Occupancy is stated scene by scene rather
  than derived from the reference point, because a body straddles the roadway it runs on and the
  region it strays onto or enters.

  The bodies. One motor vehicle, track 1, 4.4 m long and 1.8 m wide, its yaw rate recorded at
  every observation. Each track is generated rather than written out: the heading at an
  observation is the heading before it turned by that scene's yaw rate over the interval before
  it (`states`, with the cosine and sine of the interval's heading change to seven places), and
  the position is the position before it advanced by the distance the recorded speed covers in
  that interval, along that heading. A car at 12 m/s yawing 30 deg/s therefore runs an arc of
  radius 22.9 m and reaches the left-turn angle 30 observations after its onset; one at 2 m/s
  yawing 60 deg/s runs an arc of radius 1.9 m and reaches the reversal angle 50 observations
  after its onset.

  The instants. The scenes are 50 ms apart, the acquisition standard of the run, so that the
  heading change since an onset is integrated at a spacing within the step bound. The duty reads
  that heading change, so at an observation before any onset is recorded the turn concepts are
  unknown and so is the duty: a witness that speaks of decided observations names the instants it
  speaks about (`window`). `permit` and `branch_3` therefore begin at their first recorded onset,
  `occasion_s4_outside` at the onset of the turn it is about, and `blind` at the second
  observation, the first at which the recognition of a turn reads an observation before it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The spacing of the scenes: one every 50 ms. -/
def step : Q := Units.milliseconds 50

/-- Half-length, half-width and half-height of the car. -/
def halfCar : Q × Q × Q := (m 2, cm 90, cm 75)

/-- A rotation to the left by the angle whose cosine is `c` and sine is `s`. -/
def rotBy (c s : Q) (v : Vec) : Vec :=
  (Q.sub (Q.mul c v.1) (Q.mul s v.2), Q.add (Q.mul s v.1) (Q.mul c v.2))

-- cosine and sine, to seven places, of the heading change an interval of 50 ms carries at the
-- yaw rates the scenes below record: 30 deg/s turns the body 1.5°, 60 deg/s turns it 3°, and the
-- correction of 6 deg/s turns it 0.3°.
def cos1p5 : Q := Q.mk' 9996573 10000000
def sin1p5 : Q := Q.mk' 261769 10000000
def cos3 : Q := Q.mk' 9986295 10000000
def sin3 : Q := Q.mk' 523360 10000000
def cos0p3 : Q := Q.mk' 9999863 10000000
def sin0p3 : Q := Q.mk' 52360 10000000

def cos0p5 : Q := Q.mk' 9999619 10000000
def sin0p5 : Q := Q.mk' 87265 10000000

def left1p5 (v : Vec) : Vec := rotBy cos1p5 sin1p5 v
def left0p5 (v : Vec) : Vec := rotBy cos0p5 sin0p5 v
def left3 (v : Vec) : Vec := rotBy cos3 sin3 v
def left0p3 (v : Vec) : Vec := rotBy cos0p3 sin0p3 v
def right0p3 (v : Vec) : Vec := rotBy cos0p3 (Q.neg sin0p3) v

/-- The position and heading of the body at the first `n` observations: the heading at each
    observation is the one before it turned by that scene's yaw rate over the interval before it
    (`turn`), and the position is the one before it advanced by `d`, the distance the recorded
    speed covers in that interval, along that heading. -/
def states (n : Nat) (p0 h0 : Vec) (d : Q) (turn : Nat → Vec → Vec) : List (Vec × Vec) :=
  (List.range n).foldl (fun acc k =>
    match acc.getLast? with
    | none => [(p0, h0)]
    | some (p, h) =>
      let h' := turn k h
      acc ++ [((Q.add p.1 (Q.mul h'.1 d), Q.add p.2 (Q.mul h'.2 d)), h')]) []

def stateAt (ss : List (Vec × Vec)) (k : Nat) : Vec × Vec :=
  ss[k]?.getD ((Q.zero, Q.zero), Build.east)

/-- The bound vehicle, with its yaw rate recorded. -/
def car (st : Vec × Vec) (speed yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] st.1 st.2 speed halfCar)
    (fun kin => { kin with yawRate := some yaw })

/-- The yaw rate of a body held on its course: a correction to the left at the second and third
    observations, taken out again at the fifth and sixth — no more than a degree of heading
    either way, and far short of the left-turn angle. -/
def holdingCourseYaw (k : Nat) : Q :=
  if k == 1 || k == 2 then Units.degrees 6
  else if k == 4 || k == 5 then Units.degrees (-6)
  else Q.zero

def holdingCourseTurn (k : Nat) (h : Vec) : Vec :=
  if k ≤ 2 then left0p3 h else if k ≤ 3 then h else if k ≤ 5 then right0p3 h else h

-- the divided highway
def highwayR : Structure :=
  { Build.rect 1 .highway (m (-200)) (m (-20)) (m 200) (m 20) with ways := some [1] }
def southRoadwayR : Structure :=
  { Build.rect 2 .roadway (m (-200)) (m (-12)) (m 200) (m (-2)) with ways := some [1] }
def northRoadwayR : Structure :=
  { Build.rect 3 .roadway (m (-200)) (m 2) (m 200) (m 12) with ways := some [1] }
def medianR : Structure :=
  { Build.rect 4 .medianOrDivider (m (-200)) (m (-2)) (m 200) (m 2) with
      ways := some [1], opening := some false }
def dividedHighway : List Structure := [highwayR, southRoadwayR, northRoadwayR, medianR]

-- the same way with a crossover through the dividing section
def medianWestR : Structure :=
  { Build.rect 4 .medianOrDivider (m (-200)) (m (-2)) (m 20) (m 2) with
      ways := some [1], opening := some false }
def crossoverR : Structure :=
  { Build.rect 5 .medianOrDivider (m 20) (m (-2)) (m 40) (m 2) with
      ways := some [1], opening := some true }
def medianEastR : Structure :=
  { Build.rect 6 .medianOrDivider (m 40) (m (-2)) (m 200) (m 2) with
      ways := some [1], opening := some false }
def crossoverHighway : List Structure :=
  [highwayR, southRoadwayR, northRoadwayR, medianWestR, crossoverR, medianEastR]

-- the same way ending at an intersection established on it
def southApproachR : Structure :=
  { Build.rect 2 .roadway (m (-200)) (m (-12)) (m 62) (m (-2)) with ways := some [1] }
def northApproachR : Structure :=
  { Build.rect 3 .roadway (m (-200)) (m 2) (m 62) (m 12) with ways := some [1] }
def medianToJunctionR : Structure :=
  { Build.rect 4 .medianOrDivider (m (-200)) (m (-2)) (m 62) (m 2) with
      ways := some [1], opening := some false }
def junctionR : Structure :=
  { Build.rect 6 .intersection (m 62) (m (-12)) (m 82) (m 12) with ways := some [1] }
def junctionHighway : List Structure :=
  [highwayR, southApproachR, northApproachR, medianToJunctionR, junctionR]

-- an undivided way: one roadway and a painted centre line, no barrier or dividing section
def undividedRoadwayR : Structure :=
  { Build.rect 2 .roadway (m (-200)) (m (-8)) (m 200) (m 8) with ways := some [1] }
def centreLineR : Structure :=
  { Build.rect 7 .centreLine (m (-200)) (cm (-10)) (m 200) (cm 10) with ways := some [1] }
def undividedHighway : List Structure := [highwayR, undividedRoadwayR, centreLineR]

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): On a divided highway with a kerbed central dividing section, a car running at 12 m/s swings to the left: its yaw rate rises well above the onset rate, and about two seconds later the heading change accumulated since that onset passes the left-turn angle while its footprint overlaps the dividing section. No opening, crossover or junction covers any observation of the turn. -/
def forbidStates : List (Vec × Vec) :=
  states 36 (m 0, m (-7)) Build.east (cm 60) (fun _ h => left1p5 h)

def forbidTrace : Trace :=
  Build.trace 36 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt forbidStates k) (Units.metresPerSecond 12)
            (if k == 0 then Q.zero else Units.degrees 30) ]
      dividedHighway
      []
      (some (if k ≤ 24 then [(1, 1), (1, 2)] else [(1, 1), (1, 2), (1, 4)]))

/-- `permit` (compliant): The same car runs straight along the nearside roadway of the divided highway for the whole recording: its footprint never overlaps the central dividing section, and the only turning recorded is a correction of under a degree of heading, far short of the left-turn angle. -/
def permitStates : List (Vec × Vec) :=
  states 20 (m 0, m (-7)) Build.east (cm 60) holdingCourseTurn

def permitTrace : Trace :=
  Build.trace 20 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt permitStates k) (Units.metresPerSecond 12) (holdingCourseYaw k) ]
      dividedHighway
      []
      (some [(1, 1), (1, 2)])

/-- `idle` (not_applicable): A car makes a U-turn on a two-lane undivided highway with a painted centre line and no physical barrier or dividing section. The way is not a divided highway and the rule does not engage. -/
def idleStates : List (Vec × Vec) :=
  states 52 (m 0, m (-4)) Build.east (cm 10) (fun _ h => left3 h)

def idleTrace : Trace :=
  Build.trace 52 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt idleStates k) (Units.metresPerSecond 2)
            (if k == 0 then Q.zero else Units.degrees 60) ]
      undividedHighway
      []
      (some [(1, 1), (1, 2)])

/-- `blind` (unknown) and `branch_2` (violated): the car swings to the left on the nearside roadway of the divided highway, its body clear of the dividing section at every observation, and the heading change accumulated since the onset reaches the left-turn angle at the last of them. With the yaw rate of road users declared absent no heading change can be integrated, so whether a left turn or a reversal was made is unknown and the duty is unknown. -/
def blindStates : List (Vec × Vec) :=
  states 32 (m 0, cm (-1150)) Build.east (cm 60) (fun _ h => left1p5 h)

def blindTrace : Trace :=
  Build.trace 32 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt blindStates k) (Units.metresPerSecond 12)
            (if k == 0 then Q.zero else Units.degrees 30) ]
      dividedHighway
      []
      (some [(1, 1), (1, 2)])

/-- `occasion_s4` (violated): The car begins a U-turn inside a crossover recorded as an opening in the central dividing section: at the onset and for the first second and a half its footprint overlaps the opening, but it swings wide and completes the reversal with its body on the travelled roadway beyond the opening, where the heading change reaches the reversal angle. The exception holds for part of the act only, and a part-covered act is not excused. -/
def occasion_s4States : List (Vec × Vec) :=
  states 56 (m 30, m 0) Build.east (cm 10) (fun _ h => left3 h)

def occasion_s4Trace : Trace :=
  Build.trace 56 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt occasion_s4States k) (Units.metresPerSecond 2)
            (if k == 0 then Q.zero else Units.degrees 60) ]
      crossoverHighway
      []
      (some (if k ≤ 30 then [(1, 1), (1, 5)] else [(1, 1), (1, 3)]))

/-- `occasion_s4_outside` (not_applicable): The car runs along the nearside roadway, its body clear of any opening, and then turns left into a junction established on that way: from the onset of the turn to the observation at which the heading change reaches the turn angle its footprint overlaps that junction region throughout, although it did not before the turn began. The exception covers the whole act and the duty does not bite on it. -/
def occasion_s4_outsideStates : List (Vec × Vec) :=
  states 46 (cm 5760, m (-7)) Build.east (cm 25)
    (fun k h => if k < 10 then h else left1p5 h)

def occasion_s4_outsideTrace : Trace :=
  Build.trace 46 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt occasion_s4_outsideStates k) (Units.metresPerSecond 5)
            (if k < 10 then Q.zero else Units.degrees 30) ]
      junctionHighway
      []
      (some (if k < 10 then [(1, 1), (1, 2)]
             else if k < 30 then [(1, 1), (1, 2), (1, 6)]
             else [(1, 1), (1, 6)]))

/-- `branch_1` (violated): the car runs along the kerbed dividing section itself, its body on it at
    every observation, and no turning of any size is recorded — the yaw rate stays at zero, so
    whether a turn was made is unknown. The overlap of the footprint with the dividing section
    decides the duty on its own. -/
def branch_1States : List (Vec × Vec) :=
  states 12 (m 0, m (-1)) Build.east (cm 60) (fun _ h => h)

def branch_1Trace : Trace :=
  Build.trace 12 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt branch_1States k) (Units.metresPerSecond 12) Q.zero ]
      dividedHighway
      []
      (some [(1, 1), (1, 4)])

/-- `branch_3` (not_applicable): the car crosses the dividing section at the crossover, its body
    within the recorded opening at every observation and no turn of any size made: the exception
    covers the crossing and the duty does not bite on it. -/
def branch_3States : List (Vec × Vec) :=
  states 10 (m 30, m (-1)) Build.north (cm 10) holdingCourseTurn

def branch_3Trace : Trace :=
  Build.trace 10 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt branch_3States k) (Units.metresPerSecond 2) (holdingCourseYaw k) ]
      crossoverHighway
      []
      (some [(1, 1), (1, 2), (1, 5)])

/-- `branch_4` (violated): the mirror of `occasion_s4_outside` — the turn begins on the nearside
    roadway, outside the junction, and the heading change reaches the turn angle only after the
    body has entered the junction. The exception covers the end of the act and not its onset, so
    the act is not excused; nothing but the turn decides, the body never touching the dividing
    section. -/
def branch_4States : List (Vec × Vec) :=
  states 40 (m 56, m (-7)) Build.east (cm 25)
    (fun k h => if k < 5 then h else left1p5 h)

def branch_4Trace : Trace :=
  Build.trace 40 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt branch_4States k) (Units.metresPerSecond 5)
            (if k < 5 then Q.zero else Units.degrees 30) ]
      junctionHighway
      []
      (some (if k ≤ 16 then [(1, 1), (1, 2)]
             else if k ≤ 32 then [(1, 1), (1, 2), (1, 6)]
             else [(1, 1), (1, 6)]))

/-- `branch_5` (not_applicable): a kerbed barrier lies on the way, but only one roadway is
    recorded there: the way is not divided into two or more roadways and the rule does not
    engage. -/
def branch_5States : List (Vec × Vec) :=
  states 10 (m 0, m (-7)) Build.east (cm 60) (fun _ h => h)

def branch_5Trace : Trace :=
  Build.trace 10 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt branch_5States k) (Units.metresPerSecond 12) Q.zero ]
      [ highwayR, southRoadwayR, medianR ]
      []
      (some [(1, 1), (1, 2)])

/-- `branch_7` (compliant): the car curves a degree to the left on the nearside roadway — above
    the onset rate, so a manoeuvre is under way — straightens again, and runs into the junction
    established on the way, where it stays. Inside the junction the manoeuvre is still under way
    (the heading change accumulated since its onset stands clear of zero, though the yaw rate has
    returned to nothing), and the exception did not cover its onset, so the duty bites — and it is
    kept: the body is clear of the dividing section and no turn of the recognized size was made. -/
def branch_7States : List (Vec × Vec) :=
  states 30 (m 56, m (-7)) Build.east (cm 25) (fun k h => if k ≤ 3 then left0p5 h else h)

def branch_7Trace : Trace :=
  Build.trace 30 0 step fun k t =>
    Build.scene t (some 1)
      [ car (stateAt branch_7States k) (Units.metresPerSecond 5)
            (if k == 1 || k == 2 || k == 3 then Units.degrees 10 else Q.zero) ]
      junctionHighway
      []
      (some (if k ≤ 15 then [(1, 1), (1, 2)] else [(1, 1), (1, 2), (1, 6)]))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant [] "" (some (50, 950))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] "" (some (50, 1550))
  , witness "occasion_s4" occasion_s4Trace .violated
  , witness "occasion_s4_outside" occasion_s4_outsideTrace .notApplicable [] "" (some (500, 2250))
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" blindTrace .violated
  , witness "branch_3" branch_3Trace .notApplicable [] "" (some (50, 450))
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_7" branch_7Trace .compliant [] "" (some (800, 1450)) ]

end TrafficSpecWitness.NRS_484B_227_1_o2

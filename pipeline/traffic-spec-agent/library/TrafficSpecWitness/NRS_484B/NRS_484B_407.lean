/-
  Witnesses for NRS_484B_407.

  The scene every witness builds is one straight-running carriageway in the world frame: a highway
  region (id 1) from x = −400 m to x = 800 m, 24 m wide about the x axis, and inside it one or two
  roadway regions (ids 2 and 3), 12 m wide, each carrying its own curvature; a crest region (id 4)
  is a 20 m stretch of that roadway where a witness needs one. Track 1 is the subject, a motor
  vehicle 5 m long and 1.8 m wide, driving east along y = 0 and reading the sight along the highway
  at its place (`sight_along_way`, keyed to region 1, the only way of the scene).

  Every trace is 29 observations one second apart, t = 0 … 28 000 ms. The vehicle runs straight to
  t = 9 s and then turns to the left for nineteen seconds: the heading change over the
  20 s window behind t = 28 s is a half turn exactly, inside the band about a half turn, and it was
  144° one second earlier, so the reversal is recognized at t = 28 s and nowhere else; the car
  heads due west there, travelling back the way it came. Each witness is
  judged at that instant alone (`window`), the one at which the rule is engaged; the twenty seconds
  behind it are the moments of the act, and the vehicle is turning at every one of them from
  t = 10 s on. The `idle` witness turns 2 °/s for ten seconds instead — 20° over the window, no
  reversal.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_407
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_407

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- A curvature in 1/m, as an exact fraction (0.02 is `curv 2 100`). -/
def curv (a : Int) (b : Nat) : Q := Units.ratio a b
/-- A direction in the world frame; only its direction is read. -/
def dir (a b : Int) : Vec := (Q.ofInt a, Q.ofInt b)

-- Binders ↦ tracks: subject ↦ 1

def wayId : RegionId := 1
def roadId : RegionId := 2
def road2Id : RegionId := 3
def crestId : RegionId := 4

/-- Half-length, half-width, half-height of the car (m). -/
def carExtent : Q × Q × Q := (cm 250, cm 90, cm 75)

/-- The heading through the reversal: east until the turn begins at t = 10 s, then nineteen steps
    of about 8° to the left, then held. -/
def turnHeadings : List Vec :=
  [dir 1 0, dir 7 1, dir 7 2, dir 9 4, dir 8 5, dir 6 5, dir 9 10, dir 2 3, dir 1 2, dir 1 3,
   dir 1 6, dir 1 20, dir (-1) 10, dir (-1) 4, dir (-2) 5, dir (-4) 7, dir (-4) 5, dir (-1) 1,
   dir (-4) 3, dir (-1) 0]

def headingAt (k : Nat) : Vec := (turnHeadings[min (k - 9) 19]?).getD (dir 1 0)
/-- Eight degrees a second through the sweep, and thirty-six in the last second, as the car comes
    round: 144° of heading change over the window behind t = 27 s, and a half turn exactly over the
    window behind t = 28 s, where the car heads due west, back the way it came. -/
def yawAt (k : Nat) : Q :=
  if 10 ≤ k && k ≤ 27 then Units.degrees 8
  else if k == 28 then Units.degrees 36
  else Q.zero

/-- The heading of the car that only drifts through the bend: twenty degrees over ten seconds. -/
def idleHeadings : List Vec :=
  [dir 1 0, dir 30 1, dir 15 1, dir 10 1, dir 8 1, dir 6 1, dir 5 1, dir 4 1, dir 7 2, dir 3 1,
   dir 11 4]

def idleHeadingAt (k : Nat) : Vec := (idleHeadings[min (k - 9) 10]?).getD (dir 1 0)
def idleYawAt (k : Nat) : Q := if 10 ≤ k && k ≤ 19 then Units.degrees 2 else Q.zero

/-- The car at one observation: its place on the carriageway, its heading, its speed, its rate of
    turn, and the sight along the highway at its place. -/
def carAt (classes : List RoadUserClass) (x : Q) (hdg : Vec) (speed : Q) (yaw : Q) (sight : Q) : RoadUser :=
  { Build.withKin (Build.user 1 classes (x, m 0) hdg speed carExtent)
      (fun kin => { kin with yawRate := some yaw }) with
    sightAlongWay := some [(wayId, sight)] }

def highway : Structure := Build.rect wayId .highway (m (-400)) (m (-12)) (m 800) (m 12)

/-- A stretch of roadway with its horizontal curvature. -/
def roadway (id : RegionId) (x0 x1 : Int) (c : Q) : Structure :=
  { Build.rect id .roadway (m x0) (m (-6)) (m x1) (m 6) with curvature := some c }

/-- A crest of the grade, carried as a twenty-metre region of the carriageway. -/
def crest (x0 x1 : Int) : Structure :=
  Build.rect crestId .crest (m x0) (m (-6)) (m x1) (m 6)

/-- A trace of 29 observations, one second apart, from the car's place, speed and sight at each. -/
def runTrace (classes : List RoadUserClass) (xOf speedOf sightOf : Nat → Q)
    (hdgOf : Nat → Vec) (yawOf : Nat → Q) (sts : List Structure) : Trace :=
  Build.trace 29 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [carAt classes (xOf k) (hdgOf k) (speedOf k) (yawOf k) (sightOf k)] sts []

/-- Six metres a second, east, from the origin. -/
def xSteady (k : Nat) : Q := m (6 * (k : Int))
def speedSteady (_ : Nat) : Q := mps 6
def car : List RoadUserClass := [.motorVehicle]

/-- `forbid` (violated): On a bending two-lane highway a car travelling at 6 m/s turns through a half turn of heading within 19 s and goes back the way it came; at every moment of the manoeuvre the curvature of the roadway it occupies is 0.02 1/m and the sight along the way at its place is 90 m in the shorter direction. No other road user is in the scene. -/
def forbidTrace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 90) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- `permit` (compliant): The same manoeuvre on a straight, level highway: the curvature at the car's place is 0.0002 1/m throughout, no crest region lies within the reach, and the sight along the way is 400 m in both directions. -/
def permitTrace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 400) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 10000)]

/-- `idle` (not_applicable): A car drives through the same bend without reversing: its heading changes by 20 degrees over the window and it goes on in the same direction, with the sight along the way 90 m throughout. -/
def idleTrace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 90) idleHeadingAt idleYawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- `blind` (unknown): A car reverses its direction on a bend of curvature 0.02 1/m; the source declares st.sight_along_way absent, so whether it could be seen within 500 feet cannot be read. -/
def blindTrace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 90) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- `occasion_s3` (violated): The car begins its reversal on a straight stretch, where the curvature at its place is 0.0003 1/m, and completes it on the bend (the roadway from x = 130 m, curvature 0.03 1/m), which it occupies from t = 22 s: at some observations while it is turning the curvature at its place is above the resolution. The sight along the way is 80 m throughout and no crest lies within the reach. -/
def occasion_s3Trace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 80) headingAt yawAt
    [highway, roadway roadId (-400) 120 (curv 3 10000), roadway road2Id 130 800 (curv 3 100)]

/-- `occasion_s3_outside` (compliant): The car is on the bend (the roadway to x = 40 m, curvature 0.03 1/m) at the observations before it begins to turn and has reached the straight stretch beyond it at every observation while it is turning, where the curvature at its place stays at 0.0003 1/m; no crest lies within the reach, and the sight along the way is 80 m throughout. -/
def occasion_s3_outsideTrace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 80) headingAt yawAt
    [highway, roadway road2Id (-400) 40 (curv 3 100), roadway roadId 50 800 (curv 3 10000)]

/-- `branch_1` (violated): The car begins its reversal more than 200 m short of a crest region, outside the reach, and while it is turning its body comes within 170 m of that region and closes to 109 m; the curvature at its place is under the resolution throughout and the sight along the way is 100 m. -/
def branch_1Trace : Trace :=
  runTrace car xSteady speedSteady (fun _ => m 100) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 3 10000), crest 280 300]

/-- `branch_2` (compliant): The car's body is within 60 m of the crest region at the observations before it begins to turn; it drives on past the crest at 30 m/s and, almost 200 m beyond it, turns through a half turn at 6 m/s, the crest region being more than 190 m from its body at every observation while it is turning. The curvature at its place is under the resolution and the sight along the way is 100 m. -/
def branch_2Trace : Trace :=
  runTrace car
    (fun k => if k ≤ 9 then m (-60 + 30 * (k : Int)) else m (210 + 6 * ((k : Int) - 9)))
    (fun k => if k ≤ 9 then mps 30 else mps 6)
    (fun _ => m 100) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 3 10000), crest 0 20]

/-- `occasion_s5` (violated): The car begins its reversal where the sight along the way is 400 m and, while it is turning, reaches a point where the sight along the way falls to 60 m; it is upon the same bend of curvature 0.02 1/m throughout. -/
def occasion_s5Trace : Trace :=
  runTrace car xSteady speedSteady (fun k => if k ≤ 15 then m 400 else m 60) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- `occasion_s5_outside` (compliant): The sight along the way at the car's place is 60 m at the observations before it begins to turn and 400 m in both directions at every observation while it is turning; it is upon the same bend of curvature 0.02 1/m throughout. -/
def occasion_s5_outsideTrace : Trace :=
  runTrace car xSteady speedSteady (fun k => if k ≤ 9 then m 60 else m 400) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- `branch_3` (not_applicable): the same reversal on the same bend, made by a bicycle, which the
    admitted aggregate DEF-NRS-484A-320::vehicle leaves out: the section is not engaged. -/
def branch_3Trace : Trace :=
  runTrace [.bicycle] xSteady speedSteady (fun _ => m 90) headingAt yawAt
    [highway, roadway roadId (-400) 800 (curv 2 100)]

/-- The instant every witness speaks about: the observation at which the reversal is recognized.
    The rule looks back a window from it, and the twenty seconds behind it are recorded. -/
def judged : Timestamp × Timestamp := (28000, 28000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_407"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_along_way"]
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .compliant
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .compliant
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_407

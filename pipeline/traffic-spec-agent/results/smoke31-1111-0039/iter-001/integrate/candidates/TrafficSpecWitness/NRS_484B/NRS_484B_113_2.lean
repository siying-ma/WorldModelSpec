/-
  Witnesses for NRS_484B_113_2.

  Geometry (every figure is the witness's own and appears nowhere in the rule): a four-way
  intersection, region 10, the square (-10,-10)–(10,10) m; a crosswalk on its south leg, region 11,
  (-10,-14)–(10,-10) m; a stop line south of that, region 12, (-10,-16)–(0,-15) m; in `permit` a
  parking bay mid-block, region 13, (48,-10)–(52,-4) m. Road user 1 is a car (motor vehicle) of
  half-extents 2.25 × 0.9 × 0.75 m, or in `idle` a bicycle. Instants are one second apart; a
  reversing body moves at 2 m/s against its heading (10 × the speed resolution of 0.2 m/s), a yawing
  one at 90 deg/s (a quarter turn over one second, 45 × the yaw-rate resolution of 2 deg/s), a
  straight one at 0 deg/s. Occupancy
  follows the reference point. Each witness names the instants after the first, so the entry edge
  (`rises`) always has a previous observation.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Road user 1 moving backwards relative to its heading at `speed`, with yaw rate `yaw`. -/
def backing (classes : List RoadUserClass) (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 classes pos heading speed carExtent) fun k =>
    { k with velocity := some (Build.scale heading (Q.neg speed)), yawRate := some yaw }

def reverseSpeed : Q := Units.metresPerSecond 2
def swing : Q := Units.degrees 90
def straight : Q := Units.degrees 0

def intersection : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def crosswalkSouth : Structure := { Build.rect 11 .crosswalk (m (-10)) (m (-14)) (m 10) (m (-10)) with marked := some true }
def stopLineSouth : Structure := Build.rect 12 .stopLine (m (-10)) (m (-16)) (m 0) (m (-15))
def bay : Structure := Build.rect 13 .parkingSpace (m 48) (m (-10)) (m 52) (m (-4))

def junction : List Structure := [intersection, crosswalkSouth, stopLineSouth]

def inCity : List (AsmId × Bool) := [("asm.within_city_limits", true)]
def outOfCity : List (AsmId × Bool) := [("asm.within_city_limits", false)]

/-- `forbid` (violated): A car reverses along a street and its rear footprint begins to overlap the intersection region at the end of the block.
    Heading east on the east leg, backing west: x = 17, 15, 13, 11, 9 m; it enters the intersection at 4 s. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing [.motorVehicle] (m (17 - 2 * (k : Int)), m (-5)) Build.east reverseSpeed straight ]
      junction
      []
      (assumptions := inCity)

/-- `permit` (compliant): A car reverses into a parking bay mid-block, overlapping no intersection and no crosswalk.
    Heading north at x = 50 m, backing south into the bay: y = -1, -3, -5, -7 m. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing [.motorVehicle] (m 50, m (-1 - 2 * (k : Int))) Build.north reverseSpeed straight ]
      (junction ++ [bay])
      []
      (assumptions := inCity)

/-- `idle` (not_applicable): A bicycle, a device moved by human power and so no vehicle, is walked backwards across a crosswalk.
    Heading north, moving south over the crosswalk: y = -11, -12, -13 m at 1 m/s. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing [.bicycle] (m 2, m (-11 - (k : Int))) Build.north (Units.metresPerSecond 1) straight ]
      junction
      []
      (assumptions := inCity)

/-- `blind` (unknown): A car's footprint overlaps a crosswalk; the source declares kin.velocity absent, so whether it is reversing is not observed.
    Heading north on the crosswalk: y = -11, -12, -13 m; its velocity is masked by the manifest. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing [.motorVehicle] (m 2, m (-11 - (k : Int))) Build.north (Units.metresPerSecond 1) straight ]
      junction
      []
      (assumptions := inCity)

/-- `branch_1` (violated): A car stopped past the stop line reverses so that its footprint overlaps the marked crosswalk behind it.
    Heading north inside the intersection, backing south: y = -5, -7, -9, -11, -13 m; on the crosswalk from 3 s. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing [.motorVehicle] (m 2, m (-5 - 2 * (k : Int))) Build.north reverseSpeed straight ]
      junction
      []
      (assumptions := inCity)

/-- Backing around the corner inside the intersection: at 0 s heading east at (6, -4) m; over the
    next second the heading swings a quarter turn left (90 deg/s) to north at (4, -6) m; at 2 s it
    backs straight south at (4, -8) m. -/
def aroundCorner (k : Nat) : RoadUser :=
  match k with
  | 0 => backing [.motorVehicle] (m 6, m (-4)) Build.east reverseSpeed straight
  | 1 => backing [.motorVehicle] (m 4, m (-6)) Build.north reverseSpeed swing
  | _ => backing [.motorVehicle] (m 4, m (-8)) Build.north reverseSpeed straight

/-- `branch_2` (violated): Inside declared city limits, a car already within an intersection reverses while its heading swings to the side, backing around the corner into the cross street.
    `aroundCorner`, inside city limits: the swing at 1 s is the violation. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ aroundCorner k ] junction [] (assumptions := inCity)

/-- `branch_3` (compliant): Outside declared city limits, a car already within an intersection and clear of every crosswalk reverses while its heading swings: no street corner is involved and no entry into the intersection occurs.
    `aroundCorner`, outside city limits. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ aroundCorner k ] junction [] (assumptions := outOfCity)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (1000, 4000))
  , witness "permit" permitTrace .compliant (window := some (1000, 3000))
  , witness "idle" idleTrace .notApplicable (window := some (1000, 2000))
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] (window := some (1000, 2000))
  , witness "branch_1" branch_1Trace .violated (window := some (1000, 4000))
  , witness "branch_2" branch_2Trace .violated (window := some (1000, 2000))
  , witness "branch_3" branch_3Trace .compliant (window := some (1000, 2000)) ]

end TrafficSpecWitness.NRS_484B_113_2

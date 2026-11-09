/-
  Witnesses for drv.motion.turning.

  The instance reads a window of 2 s behind the observation and a heading change tolerance of 5°:
  a window long enough for a junction turn to show at a 0.5 s sampling, a tolerance at the order
  of a yaw-rate source's resolution and well under any turn of a road.

  Every trace is nine scenes 0.5 s apart, t = 0 … 4000 ms, one road user (track 1, a truck-classed
  van, half-extents 2.5 m × 1.0 m × 1.2 m) and one region whose polygon holds its positions.
  The 2 s window is covered from t = 2000 ms on (four 0.5 s intervals behind, each gap 0.5 s ≤
  half the window), so the `holds` and `fails` witnesses name the range [2000, 4000] ms: before it
  the window reaches past the start of the recording and the primitive is truncated, which is the
  reading, not a defect. `blind` names that range too, so that what leaves it unknown there is the
  yaw rate its manifest masks and not the truncation at the start of the recording.

  - `holds`: the van swings left round the corner of intersection region 10 at 5 m/s with a steady
    yaw rate of 20 °/s, its heading turning 10° per scene along an arc of radius ≈ 14.3 m. Over
    every covered window the integrated heading change is 20 °/s × 2 s = 40°, well above the 5°
    tolerance, so the body holds at every named instant.
  - `fails`: the same van reverses straight back west along roadway region 20 (gear −1, velocity
    opposite its heading) with a yaw rate of 0.4 °/s. Over the window that integrates to 0.8°,
    under a degree and below the tolerance, so the body is false at every named instant.
  - `blind`: the corner manoeuvre of `holds` with `kin.yaw_rate` absent from the manifest. The
    primitive integrates the yaw rate, so it is unknown at every instant — unobserved, not false.
-/
import TrafficSpec.Concepts.motion.turning
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A heading from its cosine and sine in hundred-thousandths. -/
def hdg (c s : Int) : Vec := (Units.ratio c 100000, Units.ratio s 100000)

/-- The van: half-length 2.5 m, half-width 1.0 m, half-height 1.2 m. -/
def vanExtent : Q × Q × Q := (cm 250, cm 100, cm 120)

/-- 5 m/s, the speed through the corner and back along the roadway. -/
def vanSpeed : Q := Units.metresPerSecond 5

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 2 s window behind the observation and a 5° heading
    change tolerance, both of this witness's own choosing. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning@w"
    concept := "drv.motion.turning"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 2) .second),
               ("heading_change_tolerance", .lit (Units.degrees 5) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The heading of the turning van at scene `k`: 10° to the left per 0.5 s scene. -/
def turnHeading : Nat → Vec
  | 0 => hdg 100000 0
  | 1 => hdg 98481 17365
  | 2 => hdg 93969 34202
  | 3 => hdg 86603 50000
  | 4 => hdg 76604 64279
  | 5 => hdg 64279 76604
  | 6 => hdg 50000 86603
  | 7 => hdg 34202 93969
  | _ => hdg 17365 98481

/-- Its position at scene `k`: an arc of radius ≈ 14.3 m from (0, 0) heading east. -/
def turnPos : Nat → Vec
  | 0 => (cm 0, cm 0)
  | 1 => (cm 249, cm 22)
  | 2 => (cm 490, cm 86)
  | 3 => (cm 715, cm 192)
  | 4 => (cm 920, cm 335)
  | 5 => (cm 1096, cm 511)
  | 6 => (cm 1239, cm 715)
  | 7 => (cm 1344, cm 941)
  | _ => (cm 1409, cm 1182)

/-- The yaw rate through the corner: 20 °/s to the left. -/
def turnYawRate : Q := Units.degrees 20

/-- The corner of the junction the van swings round. -/
def junction : Structure :=
  Build.rect 10 .intersection (m (-6)) (m (-6)) (m 20) (m 20)

/-- The van at scene `k` of the corner manoeuvre, with its yaw rate. -/
def turningVan (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle, .truck] (turnPos k) (turnHeading k) vanSpeed vanExtent)
    (fun kin => { kin with yawRate := some turnYawRate })

/-- `holds` (compliant): A van swings round the corner of a junction: over the window behind the observation its integrated heading change is about forty degrees, well above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ turningVan k ]
      [ junction ]
      [ ]

/-- The heading of the reversing van at scene `k`: 0.2° to the left per 0.5 s scene. -/
def backHeading (k : Nat) : Vec := hdg 100000 (349 * (k : Int))

/-- Its position at scene `k`: 2.5 m further west each scene. -/
def backPos (k : Nat) : Vec := (cm (-250 * (k : Int)), cm 0)

/-- The yaw rate while reversing: 0.4 °/s. -/
def backYawRate : Q := Units.millidegrees 400

/-- The roadway the van reverses back along. -/
def roadway : Structure :=
  Build.rect 20 .roadway (m (-30)) (m (-4)) (m 10) (m 4)

/-- The van at scene `k` of the reversing run: reverse gear, velocity opposite its heading. -/
def reversingVan (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle, .truck] (backPos k) (backHeading k) vanSpeed vanExtent)
    (fun kin =>
      { kin with yawRate := some backYawRate
                 gear := some (-1)
                 velocity := some (Build.scale Build.west vanSpeed) })

/-- `fails` (violated): The same van reverses straight back along a roadway: its integrated heading change over the window is under a degree, below the tolerance. -/
def failsTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ reversingVan k ]
      [ roadway ]
      [ ]

/-- `blind` (unknown): The corner manoeuvre at the start of the recording, where the window behind the observation is truncated, so the primitive's integration is unknown. -/
def blindTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ turningVan k ]
      [ junction ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (2000, 4000))
  , witness "fails" failsTrace .violated [] (some (2000, 4000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (2000, 4000)) ]

end TrafficSpecWitness.Concepts.motion.turning

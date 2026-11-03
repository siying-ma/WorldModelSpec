/-
  Witnesses for drv.motion.rearward_motion.

  One van (track 1, a motor vehicle, half-extents 2 m × 0.9 m × 1 m, so a body 4 m long) on open
  ground, three
  instants one second apart (t = 0, 1000, 2000 ms); no region and no device is needed, since the
  concept reads only the van's own kinematics. The instance gives `speed_floor` the value
  0.2 m/s — a plausible source resolution, this witness's own figure, not the concept's.

  `holds`: the van points east and its velocity points west at 1.2 m/s, so it rolls backwards; its
  position moves 1.2 m west per second, consistent with that velocity, and its speed 1.2 m/s is
  well above the 0.2 m/s floor. The component along the heading is −1.2 m/s < 0: compliant at every
  instant.

  `fails`: the van points east and travels east at 3 m/s (velocity along the heading, as
  `Build.user` builds it), so the component along the heading is +3 m/s: violated.

  `blind`: the van points east and travels at 1.2 m/s, but the manifest declares `kin.velocity`
  absent, so the direction of its motion cannot be read and the first conjunct is unknown while the
  second (speed 1.2 m/s ≥ 0.2 m/s) is true: unknown. The narrative's van is given a speed above the
  floor on purpose — with a speed below the resolution the speed conjunct alone would decide the
  concept false, and the scene would witness nothing about the unreadable velocity.
-/
import TrafficSpec.Concepts.motion.rearward_motion
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.rearward_motion

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.micrometresPerSecond n

/-- The resolution this witness's source has: 0.2 m/s. -/
def floorSpeed : Q := mps 200000
/-- The van's speed in the `holds` and `blind` scenes: 1.2 m/s. -/
def slow : Q := mps 1200000
/-- The van's speed in the `fails` scene: 3 m/s. -/
def fast : Q := mps 3000000

/-- The distance (m) covered in `k` seconds at `v` m/s: the instants are one second apart. -/
def covered (k : Nat) (v : Q) : Q := Q.mul (Q.ofInt (Int.ofNat k)) v

/-- The van's half-extents: half-length, half-width, half-height. -/
def vanExtent : Q × Q × Q := (m 2, cm 90, m 1)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.rearward_motion@w"
    concept := "drv.motion.rearward_motion"
    literals := []
    nats := []
    params := [("speed_floor", .lit floorSpeed .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A van points east and its velocity points west at 1.2 m/s: the projection on its heading is negative and the speed is above the floor. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (Q.neg (covered k slow), m 0) Build.east slow vanExtent
            (some (covered k slow)))
          (fun kin => { kin with velocity := some (Build.scale Build.west slow) }) ]
      [ ]  -- structures: none; the concept reads the van's kinematics only
      [ ]  -- devices

/-- `fails` (violated): A van points east and travels east at 3 m/s: the projection on its heading is positive, so it is in no rearward motion. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (covered k fast, m 0) Build.east fast vanExtent
          (some (covered k fast)) ]
      [ ]  -- structures
      [ ]  -- devices

/-- `blind` (unknown): A van stands in a scene whose source declares velocity absent, so the direction of its motion cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (covered k slow, m 0) Build.east slow vanExtent
          (some (covered k slow)) ]
      [ ]  -- structures
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.rearward_motion

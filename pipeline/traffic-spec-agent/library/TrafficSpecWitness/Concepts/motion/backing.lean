/-
  Witnesses for drv.motion.backing.

  The geometry, built once for all three scenes. One body, track 1, a delivery van 4 m long, 2 m
  wide and 1.8 m high (half-extents 2 m, 1 m, 90 cm), classed motor vehicle and truck. Its heading
  is the unit vector (3/5, 4/5) — three parts east to four parts north, out of the bay — and it
  never turns: the heading is the same at every observation of every scene, so the only thing the
  three scenes differ in is the velocity.

  No structures and no devices: the body reads kinematics alone.

  The instants. Each scene is three observations one second apart, at 10.0 s, 11.0 s and 12.0 s,
  padded three seconds before (7.0 s, 8.0 s, 9.0 s, the first observation repeated) so that the
  two-second window behind 10.0 s is covered rather than truncated; the witnesses speak about
  10.0 s to 12.0 s, which is what `window` names. One second between observations is exactly half
  the window, which is the adequacy the lookback asks for.

  The figures, all the witness's own: the window 2 s and the floor 1 m/s (the instance's values for
  the formal parameters), the van's speed 2 m/s. 2 m/s is above the 1 m/s floor, so `holds` turns
  on the direction of travel and not on the magnitude; the van covers 2 m between observations.

  `holds`: the velocity is the heading scaled by −2 m/s, so the component along the heading is
  −2 m/s at every observation — negative, magnitude 2 m/s ≥ the floor.
  `fails`: the velocity is the heading scaled by +2 m/s, so the component is +2 m/s, not negative,
  at every observation of the window.
  `blind`: the source reports the position, the heading and the extent, and no velocity at all
  (`kin.velocity` is `none` in the scene and absent from the manifest); the position is the same at
  every observation, so there is no displacement to read a direction of travel from either.
-/
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.backing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- The van's heading: the unit vector three parts east to four parts north. -/
def hdg : Vec := (Units.ratio 3 5, Units.ratio 4 5)

/-- Half-length, half-width, half-height of the van. -/
def vanExtent : Q × Q × Q := (m 2, m 1, cm 90)

/-- The bay the van starts from. -/
def bay : Vec := (m 0, m 0)

/-- The van's speed over the ground. -/
def vanSpeed : Q := Units.metresPerSecond 2

/-- The first and the last observation the witnesses speak about (milliseconds). -/
def tFirst : Timestamp := 10000
def tLast : Timestamp := 12000

/-- One second between observations, three seconds of padding behind the first. -/
def dt : Q := Units.seconds 1
def padBehind : Q := Units.seconds 3

/-- The van at a position, with the velocity the scene reports (`none` where the source has none)
    and its speed field alongside; the heading is `hdg` at every observation. -/
def van (pos : Vec) (vel : Option Vec) (spd : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle, .truck] pos hdg vanSpeed vanExtent)
    fun k => { k with velocity := vel, speed := spd }

/-- A scene of one van and nothing else. -/
def vanScene (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [] []

/-- The instance every scenario speaks about: the window 2 s, the floor 1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.backing@w"
    concept := "drv.motion.backing"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 2) .second),
               ("speed_floor", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A delivery van reverses steadily out of a bay: over the whole window its velocity points opposite to its heading, at a magnitude above the floor. -/
def holdsTrace : Trace :=
  Build.pad
    (Build.trace 3 tFirst dt fun k t =>
      vanScene t (van (Build.scale hdg (Units.metres (-(2 * Int.ofNat k))))
                      (some (Build.scale hdg (Units.metresPerSecond (-2)))) (some vanSpeed)))
    padBehind Q.zero dt

/-- `fails` (violated): The van creeps forward out of the bay; its velocity points along its heading at every observation of the window. -/
def failsTrace : Trace :=
  Build.pad
    (Build.trace 3 tFirst dt fun k t =>
      vanScene t (van (Build.scale hdg (Units.metres (2 * Int.ofNat k)))
                      (some (Build.scale hdg vanSpeed)) (some vanSpeed)))
    padBehind Q.zero dt

/-- `blind` (unknown): The source tracks the van's footprint and heading on the map but declares kin.velocity absent, reporting no velocity and no displacement between observations, so the direction of travel cannot be decided. -/
def blindTrace : Trace :=
  Build.pad
    (Build.trace 3 tFirst dt fun _k t => vanScene t (van bay none none))
    padBehind Q.zero dt

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected
    window := some (tFirst, tLast) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.backing

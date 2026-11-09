/-
  Witnesses for drv.motion.reverse_travel.

  One car, track 1, on an east–west aisle, its body pointing east throughout (heading `Build.east`,
  yaw rate unobserved, so nothing is claimed about turning). The scenes carry no structures: the
  concept reads none, and the bay the narratives mention plays no part in the comparison. Three
  instants, one second apart, at t = 0, 1000, 2000 ms; the body is judged at each of them.

  The figures, all the witness's own:
    half-extents  2.25 m × 0.90 m × 0.75 m (a passenger car)
    speed         1.5 m/s in every scenario (written as 1 500 000 µm/s, exact)
    `holds`       velocity 1.5 m/s due west while the body points east: the component along the
                  heading is exactly −1.5 m/s; the car's position moves west by 1.5 m per second
                  (x = 10.00, 8.50, 7.00 m), as backing out of the bay does.
    `fails`       velocity 1.5 m/s due east, the direction the body points: the component is
                  exactly +1.5 m/s and the position moves east (x = 10.00, 11.50, 13.00 m).
    `blind`       the `holds` manoeuvre with `kin.velocity` declared absent by the manifest: the
                  heading is read but the velocity is not, so the component cannot be formed.
    instance      reverse_speed_tolerance = 0.2 m/s (200 000 µm/s), a plausible resolution floor
                  for a source's velocity estimate; both ±1.5 m/s lie well clear of it, so neither
                  decided scenario sits on the boundary.
-/
import TrafficSpec.Concepts.motion.reverse_travel
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.reverse_travel

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- 1.5 m/s, the speed of the manoeuvre in every scenario. -/
def crawl : Q := Units.micrometresPerSecond 1500000
/-- 0.2 m/s, the tolerance the instance gives the formal parameter. -/
def tolerance : Q := Units.micrometresPerSecond 200000
/-- The car's half-length, half-width, half-height. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.reverse_travel@w"
    concept := "drv.motion.reverse_travel"
    literals := []
    nats := []
    params := [("reverse_speed_tolerance", .lit tolerance .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car at `x` metres east of the origin, body pointing east, moving at 1.5 m/s in `dir`. -/
def car (x : Q) (dir : Vec) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (x, Q.zero) Build.east crawl carExtent)
    fun k => { k with velocity := some (Build.scale dir crawl) }

/-- `holds` (compliant): A car reverses out of a parking bay at about 1.5 m/s: its velocity points opposite to its heading, so the component along the heading is about minus 1.5 m/s. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (cm (1000 - 150 * Int.ofNat k)) Build.west ]
      [ ]  -- no structures: the concept reads none
      [ ]  -- devices

/-- `fails` (violated): The same car drives forward out of the bay at 1.5 m/s: the component along its heading is about plus 1.5 m/s. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (cm (1000 + 150 * Int.ofNat k)) Build.east ]
      [ ]  -- no structures: the concept reads none
      [ ]  -- devices

/-- `blind` (unknown): The same manoeuvre with the source declaring road-user velocity absent: the direction of the motion relative to the body cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (cm (1000 - 150 * Int.ofNat k)) Build.west ]
      [ ]  -- no structures: the concept reads none
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

end TrafficSpecWitness.Concepts.motion.reverse_travel

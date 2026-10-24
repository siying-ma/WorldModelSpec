/-
  Witnesses for drv.motion.at_rest.

  An open stretch with nothing on it: no structure region, no device and no second road user, since
  the concept reads the road user's own speed and nothing else. Every figure below is the witness's
  own, including the one the instance gives the formal parameter.

  The tolerance the instance sets is 0.1 m/s (100 000 µm/s): the magnitude at or below which a
  measured speed counts, for this witness's source, as no movement at all.

  The subject is a car, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), track 1, the formal
  `u`, heading north. Three instants one second apart from t = 0, so t = 0 s … 2 s. The body is
  read at the instant and looks neither behind nor ahead, so no padding and no window are needed
  and the scenario speaks about every instant of its trace.

  holds:  the car has come to rest on the stretch and stands at the origin at each of the three
          instants, its reported speed 0.02 m/s — a sampled measurement of a standing body, well
          below the tolerance of 0.1 m/s. Its position does not change and its path length stands
          at the 40 m it ran before stopping. The concept holds at each of the three instants.
  fails:  the same car rolls north at 1.4 m/s, an ordinary walking pace, fourteen times the
          tolerance; it is 1.4 m further on at each instant and its path length grows with it. The
          measured speed is above the tolerance at every instant, so the concept fails — at the
          first of them already, which is enough for the verdict.
  blind:  the holds scene on a source whose manifest declares kin.speed absent. The car is in the
          scene, its position, heading and extents observed, but no speed is reported for it at any
          observation, so whether it is moving cannot be told and the concept is unknown for that
          atom alone.
-/
import TrafficSpec.Concepts.motion.at_rest
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.at_rest

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n

/-- A speed in micrometres per second, the witness's way of writing a fraction of a metre per
    second exactly. -/
def mps (n : Int) : Q := Units.micrometresPerSecond n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor. The tolerance is 0.1 m/s — the witness's own figure for
    the magnitude at or below which this source's measured speed counts as no movement at all. -/
def inst : Concept.Instance :=
  { name := "drv.motion.at_rest@w"
    concept := "drv.motion.at_rest"
    literals := []
    nats := []
    params := [("halt_speed_tolerance", .lit (mps 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of the witness at a place on the stretch, with the speed the source reports for it and
    the distance it has run since the start of the recording. -/
def car (y : Q) (speed : Q) (path : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, y) Build.north speed (m 2, m 1, m 1) (some path)

/-- The speed the source reports for a car standing still: 0.02 m/s, a sampled measurement of a
    body at rest, below the tolerance of the instance. -/
def restingSpeed : Q := mps 20000

/-- An ordinary walking pace: 1.4 m/s, well above the tolerance of the instance. -/
def walkingSpeed : Q := mps 1400000

/-- `holds` (compliant): A single road user runs along an open stretch and comes to rest. At the observation the source reports its speed below the tolerance the caller sets. No structure region and no other road user is in the scene. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0) restingSpeed (m 40) ]
      [ ]  -- no structure region: the concept reads none
      [ ]  -- devices

/-- The northing of the rolling car at the observation at second `k`: 1.4 m further on each
    second. -/
def rollingNorthing (k : Nat) : Q := mm (1400 * Int.ofNat k)

/-- `fails` (violated): The same single road user rolls forward at an ordinary walking pace at the observation, its reported speed well above the tolerance the caller sets. No structure region and no other road user is in the scene. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (rollingNorthing k) walkingSpeed (Q.add (m 40) (rollingNorthing k)) ]
      [ ]  -- no structure region: the concept reads none
      [ ]  -- devices

/-- `blind` (unknown): The single road user is in the scene but the source reports no speed for it at the observation, so whether it is moving cannot be told. No structure region and no other road user is in the scene. -/
def blindTrace : Trace := holdsTrace

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.at_rest

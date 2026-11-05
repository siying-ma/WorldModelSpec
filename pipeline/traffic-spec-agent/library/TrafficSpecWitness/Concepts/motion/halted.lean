/-
  Witnesses for drv.motion.halted.

  One body, track 1, a car 5 m long and 2 m wide, in an empty world: no region and no device is
  built, because the concept reads the body's own speed alone — not the place it stands, not the
  reason it is at rest, not a lamp, a brake input or a gear. Each trace is three instants one
  second apart (t = 0, 1000, 2000 ms); the concept reads the observation itself, with no window
  behind or ahead, so every instant decides on its own and no scenario needs a `window`.

  The instance's own figure: a halt tolerance of 0.1 m/s, the speed at or below which a reading
  counts as no travel — the bound a caller sets because a body at rest reads as a small positive
  speed over sampled measurements.

    holds — the car stands at the kerb, facing east at (0, 0), with a speed reading of 0.02 m/s at
            each instant, below the 0.1 m/s tolerance: the body is read as standing still.
    fails — the same car rolls forward at 2.5 m/s, well above the tolerance, covering 2.5 m
            between instants: it is travelling, not standing still.
    blind — the car stands at the kerb as in `holds`, but the source supplies no speed for it
            (`kin.speed` is `none` and the manifest declares the atom absent), so whether the body
            stands still is unknown.
-/
import TrafficSpec.Concepts.motion.halted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.halted

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.halted@w"
    concept := "drv.motion.halted"
    literals := []
    nats := []
    params :=
      [ ("halt_speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car at an instant: 5 m long, 2 m wide, facing east at the position given, travelling at
    the speed given; where `observed` is false the source supplies no speed reading for it and the
    field is `none`. -/
def car (pos : Vec) (speed : Q) (observed : Bool) : RoadUser :=
  let u := Build.user 1 [.motorVehicle] pos Build.east speed (cm 250, cm 100, cm 100)
  if observed then u else Build.withKin u fun k => { k with speed := none }

/-- Three instants a second apart, the car at the position and with the speed reading given. -/
def haltTrace (pos : Nat → Vec) (speed : Q) (observed : Bool := true) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (pos k) speed observed ]
      [ ]  -- no structure is read
      [ ]  -- devices

/-- The car standing at the kerb: 2 cm further east at each instant, the 0.02 m/s reading. -/
def kerbPos (k : Nat) : Vec := (cm (2 * Int.ofNat k), m 0)

/-- The car rolling forward at 2.5 m/s: 2.5 m further east at each instant. -/
def rollingPos (k : Nat) : Vec := (cm (250 * Int.ofNat k), m 0)

/-- `holds` (compliant): A car stands at the kerb with a speed reading of 0.02 m/s, below the tolerance the caller sets: the body is read as standing still. -/
def holdsTrace : Trace := haltTrace kerbPos (Units.micrometresPerSecond 20000)

/-- `fails` (violated): The same car rolls forward at 2.5 m/s, well above the tolerance: it is travelling, not standing still. -/
def failsTrace : Trace := haltTrace rollingPos (Units.micrometresPerSecond 2500000)

/-- `blind` (unknown): The car is in the scene but the source supplies no speed for it: kin.speed is absent, so whether the body stands still is unknown. -/
def blindTrace : Trace := haltTrace kerbPos (Units.micrometresPerSecond 20000) false

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

end TrafficSpecWitness.Concepts.motion.halted

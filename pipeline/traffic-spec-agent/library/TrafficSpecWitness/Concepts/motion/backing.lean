/-
  Witnesses for drv.motion.backing.

  One instance, `drv.motion.backing@w`, with speed_tolerance = 0.1 m/s (a tenth of a metre per
  second: sampling noise on a standing vehicle, nothing a reversing car approaches).

  The bodies are cars of half-extents 2 m × 0.9 m × 0.75 m, track 1, ground truth for the formal
  `u`; three instants a second apart.

  `holds`: a car points north out of a parking bay (a 2.6 m × 5 m parking space region) and its
  velocity is south at 1.5 m/s — the component along the heading is −1.5 m/s, below −0.1, at every
  instant.

  `fails`: a car points east on a flat road with velocity zero and reverse gear selected for the
  first two instants (component 0, not below −0.1: the gear is not read), then pulls away forwards
  at 2 m/s (component +2).

  `blind`: a car points east beside an intersection region and creeps east at 0.5 m/s, but the
  manifest declares `kin.heading` absent, so the component along the heading — and with it the
  direction of motion relative to the way it points — is undecided at every instant.
-/
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.backing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- 0.1 m/s, the instance's tolerance. -/
def tol : Q := Units.micrometresPerSecond 100000
/-- 1.5 m/s, the reversing speed of `holds` (and the metres it covers in a second). -/
def reverseSpeed : Q := Units.micrometresPerSecond 1500000
/-- 0.5 m/s, the creeping speed of `blind`. -/
def creepSpeed : Q := Units.micrometresPerSecond 500000

/-- The half-extents of a car: half-length, half-width, half-height. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.backing@w"
    concept := "drv.motion.backing"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit tol .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car reverses out of a parking bay at one and a half metres per second, its velocity opposed to the direction it points. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle]
            (m 0, Q.sub (m 6) (Q.mul reverseSpeed (Q.ofInt (Int.ofNat k)))) Build.north
            reverseSpeed carExtent)
          (fun kin => { kin with velocity := some (Build.scale Build.south reverseSpeed) }) ]
      [ Build.rect 1 .parkingSpace (cm (-130)) (m 5) (cm 130) (m 10) ]
      [ ]  -- devices

/-- `fails` (violated): A car in reverse gear stands still on a flat road, its velocity zero, and then pulls away forwards. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ if k < 2 then
          Build.withKin
            (Build.user 1 [.motorVehicle] (m 0, m 0) Build.east Q.zero carExtent)
            (fun kin => { kin with gear := some (-1) })
        else
          Build.withKin
            (Build.user 1 [.motorVehicle] (m 1, m 0) Build.east (Units.metresPerSecond 2) carExtent)
            (fun kin => { kin with gear := some 1 }) ]
      [ Build.lane 1 [(m (-20), cm (-180)), (m 40, cm (-180)), (m 40, cm 180), (m (-20), cm 180)]
          Build.east ]
      [ ]  -- devices

/-- `blind` (unknown): A car moves slowly near a junction but the source declares headings absent, so whether its motion is opposed to its heading cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle]
          (Q.add (m 0) (Q.mul creepSpeed (Q.ofInt (Int.ofNat k))), m 0) Build.east
          creepSpeed carExtent ]
      [ Build.rect 1 .intersection (m 10) (cm (-900)) (m 28) (m 9) ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"] ]

end TrafficSpecWitness.Concepts.motion.backing

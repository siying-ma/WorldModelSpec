/-
  Witnesses for drv.motion.u_turn.

  One road user, track 1, a motor vehicle 4.5 m × 1.8 m × 1.5 m (half-extents 225 cm, 90 cm, 75 cm);
  no regions, no devices. Twenty observations at t = 0, 1, …, 19 s. Observations 0–4: it drives
  east along y = 0 at 5 m/s, yaw rate 0 deg/s. The scenarios are judged over t = 10 … 14 s, where
  the 10 s back window reaches the start of the trace (covered) and contains the whole turning.
  - holds: at observations 5–8 it swings left at 45 deg/s across the centre line (yaw rate 45 deg/s
    over four 1 s intervals: +180 deg), then drives west along y = 12 m at 5 m/s, yaw rate 0. Over
    t = 10 … 14 s the heading change in the window is +180 deg: |180 − 180| = 0 ≤ 10 deg.
  - fails: at observations 5–6 it turns right at a junction at −45 deg/s (−90 deg), then drives south
    along x = 26 m at 5 m/s, yaw rate 0. Over the window the heading change is −90 deg:
    |90 − 180| = 90 > 10 deg.
  - blind: the holds motion, but its yaw rate is unobserved at every observation (field unset, and
    `kin.yaw_rate` absent from the manifest).
  The instance gives window 10 s and reversal_tolerance 10 deg, figures of the witness's own.
  Headings at the turning's intermediate instants are rational approximations; the concept reads
  the yaw rate only.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: window = 10 s, reversal_tolerance = 10 deg. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 10) .second),
               ("reversal_tolerance", .lit (Units.degrees 10) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def halfExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The judged instants: the 10 s back window is covered and holds the whole turning. -/
def judged : Option (Timestamp × Timestamp) := some (10000, 14000)

/-- The left half turn: position, heading and yaw rate (deg/s) at observation k. -/
def leftTurn (k : Nat) : Vec × Vec × Q :=
  if k ≤ 4 then ((m (5 * k), m 0), Build.east, Units.degrees 0)
  else if k = 5 then ((m 24, m 2), (Units.ratio 4 5, Units.ratio 3 5), Units.degrees 45)
  else if k = 6 then ((m 26, m 6), Build.north, Units.degrees 45)
  else if k = 7 then ((m 24, m 10), (Units.ratio (-3) 5, Units.ratio 4 5), Units.degrees 45)
  else if k = 8 then ((m 20, m 12), Build.west, Units.degrees 45)
  else ((m (20 - 5 * (k - 8 : Nat)), m 12), Build.west, Units.degrees 0)

/-- The right quarter turn: position, heading and yaw rate (deg/s) at observation k. -/
def rightTurn (k : Nat) : Vec × Vec × Q :=
  if k ≤ 4 then ((m (5 * k), m 0), Build.east, Units.degrees 0)
  else if k = 5 then ((m 24, m (-2)), (Units.ratio 4 5, Units.ratio (-3) 5), Units.degrees (-45))
  else if k = 6 then ((m 26, m (-6)), Build.south, Units.degrees (-45))
  else ((m 26, m (-6 - 5 * (k - 6 : Nat))), Build.south, Units.degrees 0)

def mover (k : Nat) (motion : Nat → Vec × Vec × Q) (yawSeen : Bool) : RoadUser :=
  let (pos, hd, ω) := motion k
  Build.withKin (Build.user 1 [.motorVehicle] pos hd (Units.metresPerSecond 5) halfExtent)
    (fun kn => { kn with yawRate := if yawSeen then some ω else none })

/-- `holds` (compliant): x drives along a street, swings left across the centre line and completes the turning heading the opposite way within the window; the size of prim.heading_change differs from the half turn by less than reversal_tolerance. -/
def holdsTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover k leftTurn true ]
      [ ]
      [ ]

/-- `fails` (violated): x turns right at a junction; the size of prim.heading_change over the window is about a quarter turn. -/
def failsTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover k rightTurn true ]
      [ ]
      [ ]

/-- `blind` (unknown): x reverses its heading, but its yaw rate is missing during the window. -/
def blindTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover k leftTurn false ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn

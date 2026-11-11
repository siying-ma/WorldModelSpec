/-
  Witnesses for drv.position.within_clearance_since_entry.

  Geometry: region 100 is a lane, the rectangle x ∈ [10, 20] m, y ∈ [-2, 2] m. Road user 1 is a
  motor vehicle heading east along y = 0, half-extents 2 m × 1 m × 1 m, so its footprint spans
  [px − 2, px + 2] in x. Occupancy is derived from geometry (its reference point inside the lane).
  The instance gives clearance = 3 m. Observations every 1 s from t = 0 ms.
  - holds: seven observations; px = −10, 0 (footprint 18 m and 8 m from r), 12, 15, 18 (on r;
    the entry at the third, t = 2000), 23.5, 23.5 (left r, rear at 21.5: 1.5 m from r). Judged at
    the sixth observation (t = 5000).
  - fails: ten observations; px = −10, 0, 12 (entry, t = 2000), 15, 23.5 (left r, 1.5 m), 24.5,
    24.5 (2.5 m), 26 (rear at 24: 4 m ≥ clearance, t = 7000), 24, 24 (back to 2 m, no new entry).
    Judged from the eighth observation to the last (t ∈ [7000, 9000]): false at each.
  - blind: the holds trace with `st.region_geometry` unobserved; judged at t = 5000, where x no
    longer overlaps r and the distance is unknown.
-/
import TrafficSpec.Concepts.position.within_clearance_since_entry
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.within_clearance_since_entry

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: clearance = 3 m. -/
def inst : Concept.Instance :=
  { name := "drv.position.within_clearance_since_entry@w"
    concept := "drv.position.within_clearance_since_entry"
    literals := []
    nats := []
    params := [("clearance", .lit (Units.metres 3) .metre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The region r: a lane x ∈ [10, 20] m, y ∈ [-2, 2] m. -/
def laneR : Structure := Build.rect 100 .lane (m 10) (m (-2)) (m 20) (m 2)

/-- Road user x with its reference point at abscissa `pxCm` (cm), heading east. -/
def userX (pxCm : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm pxCm, m 0) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- x's abscissa (cm) at each observation of the holds and blind traces. -/
def holdsPos (k : Nat) : Int :=
  match k with
  | 0 => -1000
  | 1 => 0
  | 2 => 1200
  | 3 => 1500
  | 4 => 1800
  | _ => 2350

/-- x's abscissa (cm) at each observation of the fails trace. -/
def failsPos (k : Nat) : Int :=
  match k with
  | 0 => -1000
  | 1 => 0
  | 2 => 1200
  | 3 => 1500
  | 4 => 2350
  | 5 => 2450
  | 6 => 2450
  | 7 => 2600
  | _ => 2400

/-- `holds` (compliant): x does not overlap r at its first observations and stands farther than clearance from it; its footprint overlaps r from the third observation; at the sixth it has left r and its body outline stands at a distance below clearance from r. At the sixth observation the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (holdsPos k) ]
      [ laneR ]
      [ ]

/-- `fails` (violated): x enters r at the third observation, leaves it at the fifth, and at the eighth its body outline stands at clearance or more from r. At the eighth observation the concept fails, and it stays false at the later observations at which x does not enter r again. -/
def failsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (failsPos k) ]
      [ laneR ]
      [ ]

/-- `blind` (unknown): As holds, but the source maps r without its outline, so the distance from x's body to r is unobserved at the sixth observation, where x no longer overlaps r. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (holdsPos k) ]
      [ laneR ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict) (window : Timestamp × Timestamp)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (5000, 5000)
  , witness "fails" failsTrace .violated (7000, 9000)
  , witness "blind" blindTrace (.unknown []) (5000, 5000) ["st.region_geometry"] ]

end TrafficSpecWitness.Concepts.position.within_clearance_since_entry

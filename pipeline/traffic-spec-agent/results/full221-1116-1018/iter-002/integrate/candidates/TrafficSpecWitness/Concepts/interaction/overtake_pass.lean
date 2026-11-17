/-
  Witnesses for drv.interaction.overtake_pass.

  Geometry (every figure here is the witness's own):
    - lane 10, the strip y ∈ [-2, 2] m, and lane 11, the adjacent strip y ∈ [2, 6] m, both
      running east from x = 0 to x = 200 m (not read by the concept; the narrative's lanes).
    - road user b = track 2, a motor vehicle of half-extent 2 m × 1 m × 1 m, halted at (100, 0)
      heading east in every scene.
    - road user a = track 1, a motor vehicle of the same half-extent, heading east in every scene:
      the headings are aligned (cosine 1).
    - ten scenes, one per second (t = 0 … 9000 ms); a's position at scene k:
        k0 (40,0)  k1 (52,0)  k2 (64,0)  k3 (76,0)   following b in lane 10 at 12 m/s, b ahead
        k4 (88,4)  in lane 11, b still ahead: a's projection [86,90], b's [98,102], gap 8 m
        k5 (97,4)  k6 (100,4)  k7 (103,4)   alongside: the projections share 1, 4, 1 m
      holds/blind:
        k8 (107,4) b behind: projections [105,109] and [98,102], gap 3 m; component along a's
                   heading of b − a is −7 m. b comes to be behind here, 4 s after b was last
                   ahead (k4): the recognition, t = 8000 ms.
        k9 (119,4) b still behind.
      fails:
        k7, k8, k9 a halts at (100,4): the bodies stay side by side (shared length 4 m); b is
                   never behind a.
    - holds and blind judge the recognition instant only (window 8000–8000 ms); fails judges
      the last instant (9000–9000 ms), where b has not come to be behind a.
  Instance: window = 6 s (it reaches back from 8000 ms to 2000 ms, so k4 lies inside it and the
  window is covered by the trace), same_dir_cos = 9/10.
  blind masks kin.position: the component of b's bearing along a's heading is unknown, so whether
  b is ahead of or behind a cannot be told. The source of blind does not observe the bodies'
  extents, so Core cannot compute their footprints (nor their occupancy, which that source does
  not observe); it measures the longitudinal overlap of the
  bodies instead (a measured `longitudinalOverlap` on the relation a → b, the same figures as the
  geometry above): the unknown is the masked position's alone.
-/
import TrafficSpec.Concepts.interaction.overtake_pass
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtake_pass

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtake_pass@w"
    concept := "drv.interaction.overtake_pass"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 6) .second), ("same_dir_cos", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The two lanes of the narrative (not read by the concept). -/
def laneOwn : Structure := Build.lane 10 [(m 0, m (-2)), (m 200, m (-2)), (m 200, m 2), (m 0, m 2)] Build.east
def laneAdj : Structure := Build.lane 11 [(m 0, m 2), (m 200, m 2), (m 200, m 6), (m 0, m 6)] Build.east
def lanes : List Structure := [laneOwn, laneAdj]

def half : Q × Q × Q := (m 2, m 1, m 1)

/-- b, halted at (100, 0) heading east. -/
def userB : RoadUser := Build.user 2 [.motorVehicle] (m 100, m 0) Build.east (Units.metresPerSecond 0) half

/-- a at a position, heading east, at a speed (m/s). -/
def userA (x y : Int) (v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond v) half

/-- a's approach, common to every scenario: following, changing lane, drawing alongside. -/
def approach (k : Nat) : RoadUser :=
  match k with
  | 0 => userA 40 0 12
  | 1 => userA 52 0 12
  | 2 => userA 64 0 12
  | 3 => userA 76 0 12
  | 4 => userA 88 4 12
  | 5 => userA 97 4 3
  | _ => userA 100 4 3

/-- a passing b: alongside, then clear ahead of it. -/
def passing (k : Nat) : RoadUser :=
  match k with
  | 7 => userA 103 4 3
  | 8 => userA 107 4 12
  | 9 => userA 119 4 12
  | _ => approach k

/-- a halting alongside b. -/
def halting (k : Nat) : RoadUser :=
  match k with
  | 7 | 8 | 9 => userA 100 4 0
  | _ => approach k

/-- The shared length of the projections on a's heading in the passing scenes (m). -/
def overlapPassing (k : Nat) : Int :=
  match k with
  | 0 => -56
  | 1 => -44
  | 2 => -32
  | 3 => -20
  | 4 => -8
  | 5 => 1
  | 6 => 4
  | 7 => 1
  | 8 => -3
  | _ => -15

/-- `holds` (compliant): a follows b in the same lane 15 m behind at 12 m/s while b is halted; a moves to the adjacent lane, draws alongside and, 4 s after b was last ahead of it, has b 3 m behind it: at that observation the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [passing k, userB] lanes []

/-- `fails` (violated): a follows b, moves to the adjacent lane and draws alongside b, then halts with the two bodies still side by side; b never comes to be behind a within the window. -/
def failsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [halting k, userB] lanes []

/-- `blind` (unknown): a draws past b in the adjacent lane as in holds, but the positions of the road users are not observed, so whether b is ahead of or behind a cannot be told. -/
def noExtent (u : RoadUser) : RoadUser := Build.withKin u fun k => { k with extent := none }

def blindTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1) [noExtent (passing k), noExtent userB] lanes [] with
          occupancyObserved := [], occupies := [] }
      [Build.relation 1 2 fun r => { r with longitudinalOverlap := some (m (overlapPassing k)) }]

def witness (name : String) (τ : Trace) (expected : Verdict) (at_ : Timestamp)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := some (at_, at_) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 8000
  , witness "fails" failsTrace .violated 9000
  , witness "blind" blindTrace (.unknown []) 8000 ["kin.position"] ]

end TrafficSpecWitness.Concepts.interaction.overtake_pass

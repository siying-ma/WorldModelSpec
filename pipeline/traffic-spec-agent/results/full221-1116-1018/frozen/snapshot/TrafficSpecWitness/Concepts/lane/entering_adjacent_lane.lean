/-
  Witnesses for drv.lane.entering_adjacent_lane.

  Geometry (every figure here is the witness's own):
    - two eastbound lanes, 4 m wide, from x = 0 to x = 200 m:
      r1 = 100, the strip 0 ≤ y ≤ 4 m (ordinal 2 of 2; its left neighbour is 101);
      r2 = 101, the strip 4 ≤ y ≤ 8 m (ordinal 1 of 2; its right neighbour is 100).
      Looking east, north is left: r2 is r1's left neighbour, so s = left.
    - road user a = track 1, a motor vehicle heading east at 10 m/s, half-extent 2 m × 1 m × 1 m,
      so its footprint spans y ± 1 m about its centre.
    - three scenes, one per second (t = 0, 1000, 2000 ms); the judged observation is t = 1000 ms
      (window 1000–1000), which has the observation at t = 0 before it.
      holds/blind: k0 (10, 2): footprint y ∈ [1, 3], inside r1 only;
                   k1 (20, 4): footprint y ∈ [3, 5], straddling the line y = 4, overlapping both;
                   k2 (30, 6): footprint y ∈ [5, 7], inside r2 only.
      fails:       k0 (10, 2), k1 (20, 2), k2 (30, 2): footprint inside r1 only throughout.
    - occupancy is given per scene from the footprints above (the builder's default reads only the
      centre point, which for k1 lies on the shared line).
  Instance: s = left.
  blind masks rel.occupies: a's overlap with either lane is unknown, and so is the concept.
-/
import TrafficSpec.Concepts.lane.entering_adjacent_lane
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.entering_adjacent_lane

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r1 ↦ 100, r2 ↦ 101 (two eastbound lanes, in every scene)

def inst : Concept.Instance :=
  { name := "drv.lane.entering_adjacent_lane@w"
    concept := "drv.lane.entering_adjacent_lane"
    literals := [("s", "left")]
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane r1: the southern eastbound lane, r2 on its left. -/
def laneR1 : Structure :=
  Build.lane 100 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east
    (some 101) none (some 2) (some 2)

/-- Lane r2: the northern eastbound lane, r1 on its right. -/
def laneR2 : Structure :=
  Build.lane 101 [(m 0, m 4), (m 200, m 4), (m 200, m 8), (m 0, m 8)] Build.east
    none (some 100) (some 1) (some 2)
-- (left neighbour of r2: none observed beyond the two lanes; ordinal 1 is the leftmost)

def lanes : List Structure := [laneR1, laneR2]

/-- Road user a, heading east at 10 m/s. -/
def userA (x y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- The lane change: inside r1, straddling r1/r2, inside r2. -/
def changeScene (k : Nat) (t : Timestamp) : Scene :=
  match k with
  | 0 => Build.scene t (some 1) [userA 10 2] lanes [] (some [(1, 100)])
  | 1 => Build.scene t (some 1) [userA 20 4] lanes [] (some [(1, 100), (1, 101)])
  | _ => Build.scene t (some 1) [userA 30 6] lanes [] (some [(1, 101)])

/-- Staying in r1. -/
def stayScene (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [userA (10 + 10 * (k : Int)) 2] lanes [] (some [(1, 100)])

/-- `holds` (compliant): Two adjacent lanes of the same direction; r2 is recorded as r1's left neighbour (and r1 as r2's right neighbour), looking along their common direction; s is left. At the observation before the judged one, a's footprint lies wholly inside r1, clear of r2. At the judged observation, a's footprint straddles the line between r1 and r2 and overlaps both. The scenario is judged at that observation only, which has a previous observation in the trace. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) changeScene

/-- `fails` (violated): Same lanes, adjacency and s as holds. a's footprint lies wholly inside r1, clear of r2, at the judged observation and at the previous one. The scenario is judged at that observation only, which has a previous observation in the trace. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) stayScene

/-- `blind` (unknown): Same trace, lanes, adjacency and s as holds, judged at the same observation, with a's footprint occupancy unobserved: whether a overlaps r1 or r2 at the judged observation and at the previous one is not known. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) changeScene

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r1", 100), ("r2", 101)]
    expected := expected
    window := some (1000, 1000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.entering_adjacent_lane

/-
  Witnesses for drv.lane.enters_region.

  The map, the same in every scene of every trace: a junction, region 100, the square
  (0, 0)–(20, 20) of kind `intersection`; its western approach, lane 101, the rectangle
  (−60, 10)–(0, 20), direction east; and beside it lane 102, the rectangle (−60, 0)–(0, 10),
  direction east as well, which only the `blind` scene's second car uses.

  The bodies: a car of half-extents 2 m × 1 m × 0.75 m, heading east at 9 m/s, on the centre line
  of its lane. Track 1 (the subject) runs along y = 15 m; the `blind` trace adds track 2 along
  y = 5 m. Observations are one second apart, so a car advances 9 m between them; `pathLength` is
  the 9 m per step it travels.

  `approachCar k` is at x = 9k − 8 m: at k = 0 its body spans x ∈ [−10, −6], wholly on lane 101 and
  clear of the junction; at k = 1 it spans x ∈ [−1, 3] and overlaps the junction, its reference
  point just past the boundary at x = 1, so the footprint and the reference point agree that it
  occupies region 100 from this observation on; at k = 2 and k = 3 it is well inside the junction.
  Occupancy is derived from the geometry — no pair is written by hand.

  Each witness names the instants it speaks about, because the body looks back one observation and
  that look back is truncated at the first scene of a trace:
    `holds`  t = 1000 ms — the observation at which the overlap begins;
    `fails`  t = 2000–3000 ms — the car was in the junction before and is in it still;
    `blind`  t = 1000–2000 ms — every instant whose previous observation the trace holds, so the
             only thing left undecided is the masked occupancy itself.

  The instance has no literal formal, no nat and no parameter: there is no magnitude in this
  concept. The region formal `r` is region 100, the junction; the track formal `u` is track 1,
  except in `blind`, where it is the other car, track 2.
-/
import TrafficSpec.Concepts.lane.enters_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.enters_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1 (in `blind`: u ↦ 2)
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: no literal formal, no nat, no parameter, and a
    formula body, so no bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.enters_region@w"
    concept := "drv.lane.enters_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The junction the concept is read about. -/
def junction : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

/-- The western approach the subject travels on. -/
def approach : Structure :=
  Build.lane 101 [(m (-60), m 10), (m 0, m 10), (m 0, m 20), (m (-60), m 20)] Build.east

/-- The lane beside it, which the second car of the `blind` scene travels on. -/
def approachRight : Structure :=
  Build.lane 102 [(m (-60), m 0), (m 0, m 0), (m 0, m 10), (m (-60), m 10)] Build.east

def halfExtent : Q × Q × Q := (m 2, m 1, cm 75)
def speed : Q := Units.metresPerSecond 9

/-- Track 1 on lane 101 at the k-th observation: x = 9k − 8 m, y = 15 m. -/
def approachCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (9 * (k : Int) - 8), m 15) Build.east speed halfExtent
    (some (m (9 * (k : Int))))

/-- Track 2 on lane 102 at the k-th observation: x = 9k − 8 m, y = 5 m. -/
def otherCar (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (9 * (k : Int) - 8), m 5) Build.east speed halfExtent
    (some (m (9 * (k : Int))))

/-- `holds` (compliant): A car approaches a junction; at one observation its footprint lies wholly on its approach lane and does not overlap the junction region, and at the next its front overlaps it. The concept holds at that second observation. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approachCar k ]
      [ junction, approach ]
      [ ]

/-- `fails` (violated): The same car two observations later: its footprint overlapped the junction region at the previous observation and still overlaps it now, so this is not the observation at which it entered and the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approachCar k ]
      [ junction, approach ]
      [ ]

/-- `blind` (unknown): The source declares occupancy of regions absent for road users other than the subject, and the concept is read for another car and the junction region: whether its footprint overlapped the region at either observation is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approachCar k, otherCar k ]
      [ junction, approach, approachRight ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict) (track : TrackId)
    (win : Option (Timestamp × Timestamp)) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", track)]
    regions := [("r", 100)]
    expected := expected
    window := win }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 1 (some (1000, 1000))
  , witness "fails" failsTrace .violated 1 (some (2000, 3000))
  , witness "blind" blindTrace (.unknown []) 2 (some (1000, 2000)) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.enters_region

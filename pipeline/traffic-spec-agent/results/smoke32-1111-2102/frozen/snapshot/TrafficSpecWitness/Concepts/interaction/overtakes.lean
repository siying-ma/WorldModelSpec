/-
  Witnesses for drv.interaction.overtakes.

  Two passenger cars, half-extent 2.25 m × 0.9 m × 0.75 m (4.5 m long), over six instants one
  second apart (t = 0, 1000, …, 5000 ms). b (track 2) drives east in the right lane at y = 0 at
  10 m/s, at x = 10·k − 10 m at instant k. a (track 1) enters the left lane at t = 0: it is at
  (−36, 1) m heading 15/17 east, 8/17 north (cosine 15/17 ≈ 0.88 with b's heading, about 28°:
  not aligned), and from t = 1000 ms drives east at y = 4 m, its heading parallel to b's. No
  regions, no devices: the concept does not say in which lane either travels.
  The instance sets the alignment tolerance to the cosine 9/10 (about 26°).
  At t = 0 the headings are not aligned, so neither car is behind the other and no earlier
  observation can be a's beginning: the `since` of the body is decided there and needs no history
  before the recording.
  - holds: from t = 1000 ms a drives at 20 m/s at x = 20·k − 40 m, so its offset from b along the
    heading is −20, −10, 0, 10, 20 m at t = 1000 … 5000 ms: wholly behind at 1000 and 2000 ms (gaps
    of 15.5 and 5.5 m between the bodies' projections), alongside at 3000 ms (they share 4.5 m),
    wholly ahead from 4000 ms. a becomes wholly ahead at t = 4000 ms with the headings aligned
    since 2000 ms: the window is that instant.
  - fails: a closes in from −20 and −10 m, comes alongside at t = 3000 ms (offset 0) and keeps b's
    speed from there, alongside to the end of the recording, never wholly ahead.
  - blind: the overtaking of `holds` from a source that reports no body extents (so Core cannot
    compute the overlap, and observes no occupancy) and measures the longitudinal overlap itself:
    −17.81 m along a's heading and −21.34 m along b's at t = 0 (a merging), then −15.5, −5.5,
    4.5, −5.5, −15.5 m for both orderings. The source declares rel.longitudinal_overlap absent, so
    neither car is decidedly behind the other from t = 1000 ms; the window is the recognition
    instant of `holds`.
-/
import TrafficSpec.Concepts.interaction.overtakes
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtakes

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the alignment tolerance the cosine 9/10. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtakes@w"
    concept := "drv.interaction.overtakes"
    literals := []
    nats := []
    params := [("alignment", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The heading of a while it enters the left lane: 15/17 east, 8/17 north (about 28° from east). -/
def merging : Vec := (Units.ratio 15 17, Units.ratio 8 17)

/-- Car `a` at `pos`, on `heading` at `speed` m/s. -/
def carA (pos : Vec) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond speed) (cm 225, cm 90, cm 75)

/-- Car `a` entering the left lane at t = 0. -/
def carAMerging : RoadUser := carA (m (-36), m 1) merging 20

/-- Car `b` in the right lane at instant `k`: x = 10·k − 10 m, heading east at 10 m/s. -/
def carB (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (10 * k - 10), m 0) Build.east (Units.metresPerSecond 10) (cm 225, cm 90, cm 75)

/-- Car `a` of `holds` at instant `k`: merging at 0, then at x = 20·k − 40 m in the left lane. -/
def overtaker (k : Nat) : RoadUser :=
  if k = 0 then carAMerging else carA (m (20 * k - 40), m 4) Build.east 20

/-- `holds` (compliant): a, in the left lane wholly behind b with aligned headings, comes alongside and becomes wholly ahead of b; the concept holds at that observation. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ overtaker k, carB k ]
      [ ]
      [ ]

/-- Car `a` of `fails` at instant `k`: merging at 0, at −20 and −10 m behind b at 1 and 2, then
    alongside b (offset 0) at b's speed. -/
def follower (k : Nat) : RoadUser :=
  if k = 0 then carAMerging
  else if k < 3 then carA (m (20 * k - 40), m 4) Build.east 20
  else carA (m (10 * k - 10), m 4) Build.east 10

/-- `fails` (violated): a comes alongside b and stays alongside to the end of the recording, never wholly ahead. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ follower k, carB k ]
      [ ]
      [ ]

/-- A car of the measured source, which reports no body extent. -/
def noExtent (u : RoadUser) : RoadUser :=
  Build.withKin u fun k => { k with extent := none }

/-- The length the projections of the two 4.5 m bodies share along the common heading when a's
    offset from b along it is `dx` m (negative for the gap between them), in centimetres. -/
def overlapCm (dx : Int) : Int :=
  450 - (if dx < 0 then -dx else dx) * 100

/-- The measured overlap along a's heading at instant `k`, in centimetres. -/
def overlapAB (k : Nat) : Int :=
  if k = 0 then -1781 else overlapCm (10 * k - 30)

/-- The measured overlap along b's heading at instant `k`, in centimetres. -/
def overlapBA (k : Nat) : Int :=
  if k = 0 then -2134 else overlapCm (10 * k - 30)

/-- The overtaking of `holds` as a source that measures the longitudinal overlap itself and
    reports no body extents, so Core cannot compute it from the kinematics; without footprints the
    source observes no occupancy. -/
def measuredTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1)
          [ noExtent (overtaker k), noExtent (carB k) ]
          [ ]
          [ ] with occupancyObserved := [] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (cm (overlapAB k)) },
        Build.relation 2 1 fun r => { r with longitudinalOverlap := some (cm (overlapBA k)) } ]

/-- `blind` (unknown): The source declares rel.longitudinal_overlap absent. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["rel.longitudinal_overlap"]) measuredTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (4000, 4000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] (some (4000, 4000)) ]

end TrafficSpecWitness.Concepts.interaction.overtakes

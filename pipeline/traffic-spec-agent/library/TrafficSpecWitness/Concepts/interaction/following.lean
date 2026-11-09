/-
  Witnesses for drv.interaction.following.

  The bodies. Two road users run east at 20 m/s over three observations one second apart: track 1
  the car (4 m long, 2 m wide, `a`) and track 2 the van (6 m long, 2 m wide, `b`). The van heads
  due east; the car heads 1/40 to the left of it, about 1.4°, so the cosine between the headings
  is about 0.9997 — inside the 0.97 the instance gives `same_direction_tolerance`, the cosine of
  about 14°. The car drifts the 0.5 m per second that heading implies, so its position, heading and
  velocity agree.

  `holds` (compliant): one lane (region 10, y ∈ [-4, 4] from x = -20 m to x = 160 m, directed
  east); both bodies in it, the van 30 m ahead of the car along the lane. The in-lane order and
  the heading alignment both hold at every observation.
  `fails` (violated): two adjacent lanes of the same carriageway, region 11 (the left/north lane,
  y ∈ [0, 4]) and region 10 (the right/south lane, y ∈ [-4, 0]), both directed east; the car in
  region 10 at y = -2 m and the van in region 11 at y = 2 m, their centres at the same distance
  along the way at every observation. Abreast in neighbouring lanes: neither is ahead of the other
  in the same lane, while the headings stay aligned, so the conjunction is false.
  `blind` (unknown): the pair of `holds`, 30 m apart in one strip of carriageway, but a source
  that labels the strip a roadway and cannot tell whether it is a lane (region 10,
  `unobservedKinds := [.lane]`). From that scene the in-lane order is not computable, so this
  source supplies it measured (the relation's `aAheadOfB` on the ordered pair (van, car)); the
  manifest declares `rel.ahead_behind_in_lane` absent, which blanks that measurement, and the
  order cannot be read at all. The heading alignment still holds, so the conjunction is unknown
  rather than false.

  Every figure here is the witness's own: the 20 m/s speeds, the 30 m spacing, the body extents,
  the lane boundaries and the 0.97 tolerance the instance passes.
-/
import TrafficSpec.Concepts.interaction.following
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the tolerance is the cosine of about 14°. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following@w"
    concept := "drv.interaction.following"
    literals := []
    nats := []
    params := [("same_direction_tolerance", .lit (Units.ratio 97 100) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The speed both bodies run at. -/
def runSpeed : Q := Units.metresPerSecond 20

/-- The car's heading: 1/40 to the left of due east, about 1.4°. -/
def carHeading : Vec := (Units.ratio 1 1, Units.ratio 1 40)

/-- The car (`a`) at the `k`-th observation, running east and drifting 0.5 m a second to the left
    along its heading. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle]
    (m (20 * (k : Int)), Q.add y (cm (50 * (k : Int)))) carHeading runSpeed (m 2, m 1, m 1)

/-- The van (`b`) at the `k`-th observation, running due east. -/
def van (k : Nat) (x0 y : Q) : RoadUser :=
  Build.user 2 [.motorVehicle]
    (Q.add x0 (m (20 * (k : Int))), y) Build.east runSpeed (m 3, m 1, m 1)

/-- The one lane of `holds`: the whole 8 m carriageway, directed east. -/
def wideLane : Structure :=
  Build.lane 10 [(m (-20), m (-4)), (m 160, m (-4)), (m 160, m 4), (m (-20), m 4)]
    Build.east (ordinal := some 0) (count := some 1)

/-- The two adjacent lanes of `fails`, both directed east: 11 to the left of 10. -/
def leftLane : Structure :=
  Build.lane 11 [(m (-20), m 0), (m 160, m 0), (m 160, m 4), (m (-20), m 4)]
    Build.east (right := some 10) (ordinal := some 0) (count := some 2)

def rightLane : Structure :=
  Build.lane 10 [(m (-20), m (-4)), (m 160, m (-4)), (m 160, m 0), (m (-20), m 0)]
    Build.east (left := some 11) (ordinal := some 1) (count := some 2)

/-- The strip of `blind`: the same carriageway, labelled a roadway by a source that cannot tell
    whether it is a lane. -/
def unclassifiedWay : Structure :=
  { wideLane with kind := .roadway, unobservedKinds := [.lane] }

/-- `holds` (compliant): A car runs in the same lane as a van, 30 m behind it, both headings within
    a few degrees of each other along the lane. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car k (m 0), van k (m 30) (m 0) ] [ wideLane ] []

/-- `fails` (violated): The car runs abreast of the van in the neighbouring lane: neither is ahead
    of the other in the same lane. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * (k : Int)), m (-2))
          Build.east runSpeed (m 2, m 1, m 1)
      , van k (m 0) (m 2) ]
      [ leftLane, rightLane ]
      []

/-- `blind` (unknown): The same pair with the source declaring the in-lane order of road users
    absent: whether the van is ahead of the car in its lane cannot be read. The source measures
    that order (the scene alone does not give it: the strip may or may not be a lane), and the
    manifest blanks the measurement. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      (Build.scene t (some 1) [ car k (m 0), van k (m 30) (m 0) ] [ unclassifiedWay ] [])
      [ Build.relation 2 1 fun r => { r with aAheadOfB := some true } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.ahead_behind_in_lane"] ]

end TrafficSpecWitness.Concepts.interaction.following

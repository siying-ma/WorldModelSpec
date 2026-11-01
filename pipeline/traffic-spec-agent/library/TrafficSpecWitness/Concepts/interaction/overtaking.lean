/-
  Witnesses for drv.interaction.overtaking.

  The instance fills the one formal parameter with a figure of this witness's own:
  `same_direction_cosine` 0.98, the cosine of about 11 degrees — wide enough to cover the few
  degrees of heading error two vehicles running along a straight way carry, narrow enough to keep a
  crossing or an oncoming road user out (rel.same_direction compares the cosine strictly against
  this bound, so a bound of exactly 1 would decide nothing: 0.98 leaves identical headings decidedly
  agreeing).

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over a static map: a
  straight two-lane carriageway, both lanes eastbound — a highway region (100, x in [-20, 400] m,
  y in [-8, 8] m) with the right-hand lane inside it (101, y in [-4, 0] m, due east) and the
  left-hand lane beside it (102, y in [0, 4] m, due east), each named the other's neighbour. The
  concept reads no region: the lanes are here only so that the two road users of each scenario are
  seen never to share a line of travel, which the contract says is denoted as much as a pass begun
  directly behind.

  `holdsTrace` — the pass. Two lorries (12 m long, 2.5 m wide, 3.5 m tall, as half-extents
  6/1.25/1.75 m), both headed due east: the overtaking lorry, track 1 and the road user judged
  (`u` |-> 1), runs in the left-hand lane at y = 2 m at twenty-eight metres per second from
  x = 44 m; the lorry passed, track 2 (`v` |-> 2), runs in the right-hand lane at y = -2 m at
  twenty-four metres per second from x = 50 m. The reference points therefore stand 6 m, 2 m and
  -2 m apart along the heading at the three observations: the headings are identical, so their
  cosine is 1, above the tolerance; the projections of the two bodies on the heading share 6 m, 10 m
  and 10 m, never below zero, so the bodies are abreast throughout; u's speed exceeds v's by four
  metres a second at every observation; and u lies behind v at the first two observations and, at the
  third, where it has drawn 2 m past, lay behind it earlier in the recording. The body holds at
  every instant — the pass is denoted both before and after u's reference point draws level.

  `failsTrace` — two cars (4.5 m long, 1.8 m wide, 1.5 m tall) run abreast in the two lanes, track 1
  at y = 2 m and track 2 at y = -2 m, both due east at twenty-five metres per second from x = 60 m,
  so their reference points stay exactly level. The headings agree and the projections share the
  whole 4.5 m of body, but neither car is gaining: the speeds are equal, so u's speed above v's is
  false and the body is false at every instant. (Level reference points are not u behind v, and
  neither car was ever behind the other in the recording, so that conjunct is unknown throughout;
  the false speed comparison decides the conjunction all the same.)

  `blindTrace` is the pass of `holdsTrace`, judged with kin.speed absent: the bodies, the headings
  and the positions are all mapped, so the headings are decidedly agreeing, the bodies decidedly
  abreast and u decidedly behind v or lately behind it, but whether u is still gaining cannot be
  read, so the body is unknown — a pass under way and two lorries running abreast at one speed
  cannot be told apart.
-/
import TrafficSpec.Concepts.interaction.overtaking
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtaking

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The lorries: 12 m long, 2.5 m wide, 3.5 m tall, as half-extents. -/
def lorryExtent : Q × Q × Q := (m 6, cm 125, cm 175)
/-- The cars of the second scenario: 4.5 m long, 1.8 m wide, 1.5 m tall, as half-extents. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Twenty-eight metres a second, the speed of the overtaking lorry. -/
def passingSpeed : Q := Units.metresPerSecond 28
/-- Twenty-four metres a second, the speed of the lorry passed. -/
def passedSpeed : Q := Units.metresPerSecond 24
/-- Twenty-five metres a second, the one speed of the two cars running abreast. -/
def abreastSpeed : Q := Units.metresPerSecond 25

-- Formals ↦ tracks: u ↦ 1, v ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the one formal parameter given a value of this
    witness's own through a `Units` constructor. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtaking@w"
    concept := "drv.interaction.overtaking"
    literals := []
    nats := []
    params := [("same_direction_cosine", .lit (Units.ratio 98 100) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map: a straight carriageway with two eastbound lanes
-- ---------------------------------------------------------------------------------------------
/-- The way the pass is made on: a highway region 420 m long and 16 m wide. -/
def way : Structure := Build.rect 100 .highway (m (-20)) (m (-8)) (m 400) (m 8)

/-- The right-hand eastbound lane, the lorry passed running in it. -/
def rightLane : Structure :=
  Build.lane 101
    [(m (-20), m (-4)), (m 400, m (-4)), (m 400, m 0), (m (-20), m 0)]
    Build.east (left := some 102) (ordinal := some 2) (count := some 2)

/-- The left-hand eastbound lane, the overtaking lorry running in it. -/
def leftLane : Structure :=
  Build.lane 102
    [(m (-20), m 0), (m 400, m 0), (m 400, m 4), (m (-20), m 4)]
    Build.east (right := some 101) (ordinal := some 1) (count := some 2)

def map : List Structure := [way, rightLane, leftLane]

/-- The distance travelled in `k` seconds at `speed`. -/
def advance (speed : Q) (k : Nat) : Q := Q.mul speed (Q.ofInt (Int.ofNat k))

/-- A road user running due east along the lane at height `y`, from `x0` at `speed`, at step `k`. -/
def runner (track : TrackId) (classes : List RoadUserClass) (x0 y : Q) (speed : Q)
    (halfExtent : Q × Q × Q) (k : Nat) : RoadUser :=
  Build.user track classes (Q.add x0 (advance speed k), y) Build.east speed halfExtent

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): A lorry comes up in the next lane from behind another and draws level with
    it at twenty-eight metres per second against the lead's twenty-four, the two headings identical
    so that their cosine is well above the tolerance, and the two bodies overlapping along the
    overtaking lorry's heading; the two have never shared a lane in the recording. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner 1 [.truck] (m 44) (m 2) passingSpeed lorryExtent k
      , runner 2 [.truck] (m 50) (m (-2)) passedSpeed lorryExtent k ]
      map []

/-- `fails` (violated): Two cars run abreast in adjacent lanes on identical headings at exactly the
    same speed, neither having been behind the other in the recording, so neither is gaining. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner 1 [.motorVehicle] (m 60) (m 2) abreastSpeed carExtent k
      , runner 2 [.motorVehicle] (m 60) (m (-2)) abreastSpeed carExtent k ]
      map []

/-- `blind` (unknown): A lorry draws level with another, having come up from behind it, but the
    source declares speeds absent, so whether it is still gaining cannot be decided. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1), ("v", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.overtaking

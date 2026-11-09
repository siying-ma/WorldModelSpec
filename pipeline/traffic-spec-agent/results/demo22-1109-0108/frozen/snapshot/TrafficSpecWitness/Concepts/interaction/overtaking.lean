/-
  Witnesses for drv.interaction.overtaking.

  The map, the same in every scene of every witness: two eastbound lanes of one highway, 400 m long
  and 3.5 m wide, region 1 the right-hand lane (y from 0 to 3.5 m) and region 2 the lane on its left
  (y from 3.5 to 7 m), each carrying the eastward direction, its neighbour and its place from the
  left.

  The bodies: two lorries, each 12 m long, 2.5 m wide and 4 m high (half-extents 6 m, 1.25 m, 2 m),
  running due east, track 1 the overtaking lorry (the formal a) and track 2 the overtaken one (b).
  Every instant is one second after the one before it, each lorry advancing by its own speed, so the
  motion is pure eastward and no lorry ever changes the lanes its body covers.

  - `holds`: six instants of one pass. Track 1 runs at 24 m/s with its centre at y = 4.5 m, that is
    in the left lane with the right quarter-metre of its body over the lane line, so it covers both
    lanes; track 2 runs at 20 m/s in the right lane alone, centred at y = 1.75 m. Track 1 starts
    13 m behind track 2 (centres at x = 85 m and x = 98 m) and gains 4 m/s on it, so the gap of the
    two centres is −13, −9, −5, −1, +3 and +7 m: the projections of the two bodies on the eastward
    axis are 1 m apart at the first instant and then share 3, 7, 11, 9 and 5 m. At the first instant
    the two bodies share the right lane with b ahead of a, which is the earlier part of the pass; at
    the last two a's centre has gone past b's, and the shared projections carry it. So each of the
    two readings of a pass in progress decides the first clause alone at some instant, and a is
    passing b at every one of them.
  - `fails`: both lorries at 20 m/s in the right lane, track 1 centred at x = 60 m and track 2 at
    x = 100 m, 40 m apart and holding that distance. b is ahead of a in the same lane, so the
    disjunction holds, and the projections are 28 m apart; the speed difference is zero.
  - `blind`: the `holds` trace with the manifest declaring `kin.speed` absent.

  The instance's own figures: the same-direction tolerance is the cosine 0.95 (an angle of about
  18°, which the two parallel eastward headings clear with a cosine of 1), and the speed excess is
  1 m/s (cleared by the 4 m/s of `holds`, not by the 0 of `fails`).
-/
import TrafficSpec.Concepts.interaction.overtaking
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtaking

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtaking@w"
    concept := "drv.interaction.overtaking"
    literals := []
    nats := []
    params := [ ("same_direction_tolerance", .lit (Units.ratio 95 100) .ratio)
              , ("min_speed_excess", .lit (Units.metresPerSecond 1) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The right-hand eastbound lane, second from the left of the two. -/
def rightLane : Structure :=
  Build.lane 1 [(m 0, m 0), (m 400, m 0), (m 400, cm 350), (m 0, cm 350)] Build.east
    (left := some 2) (ordinal := some 2) (count := some 2)

/-- The eastbound lane to its left, the one the overtaking lorry uses. -/
def leftLane : Structure :=
  Build.lane 2 [(m 0, cm 350), (m 400, cm 350), (m 400, m 7), (m 0, m 7)] Build.east
    (right := some 1) (ordinal := some 1) (count := some 2)

def lanes : List Structure := [rightLane, leftLane]

/-- The half-extents of a lorry: 6 m, 1.25 m, 2 m. -/
def lorry : Q × Q × Q := (m 6, cm 125, m 2)

/-- A lorry running due east: its position at observation `k` is `x0 + k · speed`. -/
def eastbound (track : TrackId) (x0 y speed : Q) (k : Nat) : RoadUser :=
  Build.user track [.truck, .motorVehicle]
    (Q.add x0 (Q.mul (Q.ofInt (Int.ofNat k)) speed), y) Build.east speed lorry

/-- One pass: track 1 at 24 m/s over the lane line, from 13 m behind track 2 at 20 m/s to 7 m
    in front of it. Track 1's body, from y = 3.25 m to y = 5.75 m, lies over the line between the
    two lanes and so covers both; track 2's, from y = 0.5 m to y = 3 m, covers the right lane
    alone, a quarter of a metre clear of track 1's. -/
def passScene (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ eastbound 1 (m 85) (cm 450) (Units.metresPerSecond 24) k
    , eastbound 2 (m 98) (cm 175) (Units.metresPerSecond 20) k ]
    lanes
    [ ]
    (occupies := some [(1, 1), (1, 2), (2, 1)])

/-- `holds` (compliant): A lorry at 24 m/s draws level with a lorry at 20 m/s on a two-lane highway, their headings aligned and their bodies' projections on the overtaking lorry's heading sharing several metres. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) passScene

/-- `fails` (violated): The two lorries run in file at the same speed, 40 m apart: there is no speed excess, so neither is passing the other. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ eastbound 1 (m 60) (cm 175) (Units.metresPerSecond 20) k
      , eastbound 2 (m 100) (cm 175) (Units.metresPerSecond 20) k ]
      lanes
      [ ]

/-- `blind` (unknown): The same pair drawing level with the source declaring the speed of road users absent: whether one is gaining on the other cannot be read. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) passScene

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.overtaking

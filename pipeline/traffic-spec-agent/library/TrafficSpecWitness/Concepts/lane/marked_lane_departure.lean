/-
  Witnesses for drv.lane.marked_lane_departure.

  One straight way running north carries the three scenarios. Every figure below is the witness's
  own, including the one the instance gives the formal parameter: a window behind of four seconds.

  The subject is a car, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), track 1, the formal
  `u`; it runs north at 5 m/s, 5 m further on at each observation. Eleven instants one second
  apart from t = 0, so t = 0 s … 10 s. The body looks four seconds behind, so the window of every
  scenario is t = 8 s … 10 s: there the stretch behind is carried by the trace in full (an
  observation four seconds earlier and three between) and sampled one second apart, which is
  inside the library's adequacy of half the window; at t = 0 s … 3 s the stretch reaches past the
  start of the trace. Nothing looks ahead, so no padding is needed — and padding would be wrong
  here, since it would put observations at negative instants before the start of the recording.

  Occupancy is given to each scene rather than derived from the polygons, so that each scenario
  says exactly which lanes the footprint overlaps; the positions are drawn to match it (a car
  whose footprint straddles a lane boundary overlaps both lanes).

  holds:  two lanes of one direction — the left lane x = -8 … -4 m, the right lane x = -4 … 0 m —
          whose common boundary is a broken white line, and an unmarked verge (a shoulder) beside
          them at x = 0 … 4 m. The car runs on the verge at t = 0 s … 5 s, its footprint overlaps
          the right-hand marked lane at t = 6 s and t = 7 s, and it is back on the verge from
          t = 8 s to the end. At each of t = 8 s, 9 s and 10 s it overlaps no lane at all, the
          four seconds behind are carried in full, and the left side of that lane carries the
          broken white line. At t = 8 s the overlap just behind is the observation immediately
          before; at t = 9 s both overlaps lie strictly between the two ends of the stretch
          (neither at the observation just before nor at the far end); at t = 10 s the overlap at
          t = 7 s lies strictly inside the stretch and the one at t = 6 s sits exactly at its far
          end, and no observation after either carries an overlap. The concept holds at all three,
          the interior case exactly as the one just behind. The car never enters the left-hand
          lane, which is marked and was overlapped at no observation of the stretch.
  fails:  the same way, with three lanes and no verge: an unmarked lane at x = -12 … -8 m (neither
          of its sides carries a marking), the lane the car runs in at x = -8 … -4 m (its right
          side a solid white line), and a marked lane at x = -4 … 0 m the car never touches. The
          car's footprint straddles the boundary of the unmarked lane and the lane it runs in up
          to t = 6 s and lies wholly inside the lane it runs in from t = 7 s on. At each of
          t = 8 s, 9 s and 10 s it still overlaps the marked lane it ran the whole covered stretch
          in, so that lane is not departed; the other marked lane was overlapped at no observation
          of the stretch; and the lane it did leave within the stretch carries a marking of type
          none on both of its sides, so it is no marked lane. No marked lane both was overlapped
          within the stretch and is unoccupied at the observation: the concept fails at all three.
  blind:  the holds scene on a source whose manifest declares rel.occupies absent. The lanes and
          their markings are observed and the stretch behind is carried in full, but no footprint
          overlap is observed for any lane at any observation, so neither which lanes the body
          overlapped within the stretch nor which it overlaps now is decided, and the concept is
          unknown for that atom alone.
-/
import TrafficSpec.Concepts.lane.marked_lane_departure
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.marked_lane_departure

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The timestamp, in milliseconds, of the observation at second `n`. -/
def atSecond (n : Int) : Timestamp := n * 1000

/-- The northing of the car at the observation at second `k`: 5 m further on each second. -/
def northing (k : Nat) : Q := m (5 * (Int.ofNat k) - 25)

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The window
    behind is four seconds — the witness's own figure for the stretch within which the source
    looks for a lane the road user came from. -/
def inst : Concept.Instance :=
  { name := "drv.lane.marked_lane_departure@w"
    concept := "drv.lane.marked_lane_departure"
    literals := []
    nats := []
    params := [("lane_departure_window", .lit (Units.seconds 4) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The way: lanes running north, each side of each lane carrying the marking the source observed
-- ---------------------------------------------------------------------------------------------
/-- A side that carries no marking at all. -/
def unmarkedSide : MarkingType × MarkingColour := (.none, .other)
/-- A broken white line. -/
def brokenWhite : MarkingType × MarkingColour := (.broken, .white)
/-- A solid white line. -/
def solidWhite : MarkingType × MarkingColour := (.solid, .white)

/-- A lane between two northings far outside the car's run, with the marking of each of its two
    sides as the source observed it. -/
def markedLane (id : RegionId) (x0 x1 : Q) (left right : MarkingType × MarkingColour) : Structure :=
  let base := Build.lane id [(x0, m (-60)), (x1, m (-60)), (x1, m 60), (x0, m 60)] Build.north
  { base with lane := base.lane.map fun l => { l with markingLeft := some left, markingRight := some right } }

/-- The car of the witness at a place on the way. -/
def car (x y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.north (Units.metresPerSecond 5) (m 2, m 1, m 1)

-- ---------------------------------------------------------------------------------------------
-- holds (and blind): two marked lanes and an unmarked verge; the car leaves the right-hand lane
-- ---------------------------------------------------------------------------------------------
/-- The left-hand lane: a solid white line at the road's edge on its left, the broken white line
    it shares with the right-hand lane on its right. -/
def holdsLaneLeft : Structure := markedLane 11 (m (-8)) (m (-4)) solidWhite brokenWhite
/-- The right-hand lane: the broken white line on its left, nothing on its right, where the verge
    begins. -/
def holdsLaneRight : Structure := markedLane 12 (m (-4)) (m 0) brokenWhite unmarkedSide
/-- The verge beside the way: a shoulder, no lane, and no marking of its own. -/
def verge : Structure := Build.rect 13 .shoulder (m 0) (m (-60)) (m 4) (m 60)

def holdsStructures : List Structure := [holdsLaneLeft, holdsLaneRight, verge]

/-- Where the car is across the way at the observation at second `k`: in the right-hand lane at
    t = 6 s and t = 7 s, on the verge everywhere else. -/
def holdsEasting (k : Nat) : Q := if k == 6 || k == 7 then m (-2) else m 2

/-- The regions the car's footprint overlaps at the observation at second `k`. -/
def holdsOccupies (k : Nat) : List (TrackId × RegionId) :=
  if k == 6 || k == 7 then [(1, 12)] else [(1, 13)]

/-- `holds` (compliant): Two lanes of one direction whose common boundary is a broken white line, and an unmarked verge beside them; observations one second apart from the start of the trace, and the instance's window four seconds. The vehicle runs on the verge, is inside the right-hand marked lane at two observations in the middle of the trace - say the sixth and seventh second - and is back on the verge from the eighth second to the end. The scenario's window is the observations at the eighth, ninth and tenth second: at each of them the footprint overlaps no lane at all, the four seconds behind are carried by the trace in full and sampled one second apart, and the lane's left side carries the broken white line. At the eighth second the overlap just behind is the observation immediately before; at the ninth and the tenth second the overlaps lie strictly between the two ends of the stretch, neither at the observation just before nor at the far end of it, and no observation after them carries an overlap. The concept holds at each of the three, the interior case exactly as the one just behind. -/
def holdsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (holdsEasting k) (northing k) ]
      holdsStructures
      []
      (some (holdsOccupies k))

-- ---------------------------------------------------------------------------------------------
-- fails: three lanes; the car stays in the marked lane it ran the whole stretch in
-- ---------------------------------------------------------------------------------------------
/-- The unmarked lane: neither of its sides carries a marking. -/
def failsLaneUnmarked : Structure := markedLane 21 (m (-12)) (m (-8)) unmarkedSide unmarkedSide
/-- The lane the car runs in: no marking towards the unmarked lane, a solid white line towards the
    marked lane on its right. -/
def failsLaneRun : Structure := markedLane 22 (m (-8)) (m (-4)) unmarkedSide solidWhite
/-- A marked lane the car never touches. -/
def failsLaneOther : Structure := markedLane 23 (m (-4)) (m 0) solidWhite solidWhite

def failsStructures : List Structure := [failsLaneUnmarked, failsLaneRun, failsLaneOther]

/-- Where the car is across the way at the observation at second `k`: straddling the boundary of
    the unmarked lane up to t = 6 s, wholly inside the lane it runs in from t = 7 s. -/
def failsEasting (k : Nat) : Q := if k ≤ 6 then cm (-750) else m (-6)

/-- The regions the car's footprint overlaps at the observation at second `k`. -/
def failsOccupies (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 6 then [(1, 21), (1, 22)] else [(1, 22)]

/-- `fails` (violated): The same way. A vehicle runs the whole of a window behind that the trace covers inside one marked lane and still overlaps it at the observation. The lane it overlaps now is overlapped now, and every other marked lane of the scene was overlapped at no observation of that covered window, so no marked lane both was overlapped within the window and is unoccupied at the observation. The concept fails. -/
def failsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (failsEasting k) (northing k) ]
      failsStructures
      []
      (some (failsOccupies k))

/-- `blind` (unknown): The holds scene, except that the source declares occupancy absent, so no footprint overlap is observed for any lane at any observation. The lanes and their markings are observed and the stretch behind is carried by the trace in full, but which lanes the body overlapped within the stretch and which it overlaps now are both undecided, so the concept is unknown for that atom alone. -/
def blindTrace : Trace := holdsTrace

/-- The instants every scenario speaks about: t = 8 s … 10 s, where the four seconds behind the
    observation are carried by the trace in full. -/
def theWindow : Option (Timestamp × Timestamp) := some (atSecond 8, atSecond 10)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := theWindow }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.marked_lane_departure

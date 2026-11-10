/-
  Witnesses for NRS_484B_223_4b.

  Geometry (metres, +x east, +y north). A highway (10) covers x ∈ [-100, 100], y ∈ [-40, 40]; an
  intersection (20, on the highway) spans x ∈ [0, 20], y ∈ [-12, 12]. Eastbound approach lanes run
  x ∈ [-60, 0] and enter it: a through lane (31) y ∈ [-3.5, 0] and, to its right, the single right
  turn lane (32) y ∈ [-7, -3.5]. The car (track 1, a motor vehicle, half-extents 2 × 0.9 × 0.75)
  is sampled every 50 ms (the reading's step bound) at 0.5 m per step: from x = -10.25 it enters
  the intersection at k = 17 (front at 0.25, rear still in its lane) and, driving straight, leaves
  it at k = 65 (rear at 20.25), yaw rate zero: a heading change of 0° against the 30° bound.
  In `permit` it turns right inside the intersection over k = 31…50 at -90°/s (-90° in all) and
  leaves southwards at k = 56. Occupancy is the footprint's overlap with each boundary.
  `idle`: two plain lanes, no turn lane. `branch_2`: two right turn lanes side by side (34, 32);
  `branch_3`: as `branch_2`, with a westbound single right turn lane (36) east of the
  intersection that the car never uses. Each witness speaks about t ∈ [100, end]: the first
  observation has no previous one for an exit to be read against.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def dt : Q := Units.milliseconds 50

/-- The car: track 1, a motor vehicle at 10 m/s, with its yaw rate (deg/s). -/
def car (p : Vec) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] p h (Units.metresPerSecond 10) (m 2, cm 90, cm 75))
    fun k => { k with yawRate := some yaw }

/-- Occupancy from the footprint: the pair (track, structure) exactly when the body's rectangle and
    the boundary overlap, so a body across two regions occupies both. -/
def footprintOccupancy (s : Scene) : List (TrackId × RegionId) :=
  s.users.flatMap fun u =>
    match footprint s u.track with
    | none => []
    | some fp => s.structures.filterMap fun st =>
      match st.boundary with
      | some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
      | none => none

def mkScene (t : Timestamp) (users : List RoadUser) (structures : List Structure) : Scene :=
  let s := Build.scene t (some 1) users structures [] (occupies := some [])
  { s with occupies := footprintOccupancy s }

-- The map ------------------------------------------------------------------------------------

def highway : Structure := Build.rect 10 .highway (m (-100)) (m (-40)) (m 100) (m 40)
def intersection : Structure :=
  { Build.rect 20 .intersection (m 0) (m (-12)) (m 20) (m 12) with ways := some [10] }

/-- An eastbound lane on x ∈ [-60, 0] between y0 < y1, entering the intersection. -/
def eastLane (id : RegionId) (y0 y1 : Q) (left right : Option RegionId) (ordinal count : Nat) : Structure :=
  { Build.lane id [(m (-60), y0), (m 0, y0), (m 0, y1), (m (-60), y1)] Build.east left right
      (some ordinal) (some count) none (some 20) with ways := some [10] }

def rightTurn (s : Structure) : Structure := { s with kind := .turnLane, turnSide := some .right }

/-- Through lane 31 and the single right turn lane 32. -/
def singleMap : List Structure :=
  [ highway, intersection
  , eastLane 31 (cm (-350)) (m 0) none (some 32) 1 2
  , rightTurn (eastLane 32 (m (-7)) (cm (-350)) (some 31) none 2 2) ]

/-- Two plain lanes, no turn lane. -/
def plainMap : List Structure :=
  [ highway, intersection
  , eastLane 31 (cm (-350)) (m 0) none (some 33) 1 2
  , eastLane 33 (m (-7)) (cm (-350)) (some 31) none 2 2 ]

/-- Through lane 31 and two right turn lanes, 34 and the rightmost 32. -/
def dualMap : List Structure :=
  [ highway, intersection
  , eastLane 31 (cm (-350)) (m 0) none (some 34) 1 3
  , rightTurn (eastLane 34 (m (-7)) (cm (-350)) (some 31) (some 32) 2 3)
  , rightTurn (eastLane 32 (cm (-1050)) (m (-7)) (some 34) none 3 3) ]

/-- `dualMap` with a westbound approach on x ∈ [20, 80]: through lane 35 (y ∈ [0, 3.5]) and the
    single right turn lane 36 (y ∈ [3.5, 7]) on its right, entering the same intersection. -/
def dualAndWestMap : List Structure :=
  dualMap ++
  [ { Build.lane 35 [(m 20, m 0), (m 80, m 0), (m 80, cm 350), (m 20, cm 350)] Build.west
        none (some 36) (some 1) (some 2) none (some 20) with ways := some [10] }
  , rightTurn { Build.lane 36 [(m 20, cm 350), (m 80, cm 350), (m 80, m 7), (m 20, m 7)] Build.west
        (some 35) none (some 2) (some 2) none (some 20) with ways := some [10] } ]

-- Motions ------------------------------------------------------------------------------------

/-- Straight east along y = `y`, from x = -10.25 at 0.5 m per step: enters the intersection at
    k = 17, leaves it at k = 65. -/
def straightEast (y : Q) (k : Nat) : RoadUser :=
  car (cm (-1025 + 50 * (k : Int)), y) Build.east (Units.degrees 0)

def straightTrace (y : Q) (structures : List Structure) : Trace :=
  Build.trace 70 0 dt fun k t => mkScene t [straightEast y k] structures

/-- `forbid` (violated): A car in the single right turn lane enters the intersection the lane runs into and leaves it on the far side heading as it entered (heading change since entry below the bound). -/
def forbidTrace : Trace := straightTrace (cm (-525)) singleMap

/-- Right turn: east in lane 32 until k = 30 (x = 4.75, inside the intersection), then over
    k = 31…50 the heading turns from east to south at -90°/s, then south from (8.75, -9.25) at
    0.5 m per step; the footprint leaves the intersection at k = 56. -/
def turningRight (k : Nat) : RoadUser :=
  if k ≤ 30 then straightEast (cm (-525)) k
  else if k ≤ 50 then
    let j : Int := (k : Int) - 30
    car (cm (475 + 20 * j), cm (-525 - 20 * j)) (Q.ofInt (20 - j), Q.ofInt (-j)) (Units.degrees (-90))
  else
    let j : Int := (k : Int) - 50
    car (cm 875, cm (-925 - 50 * j)) Build.south (Units.degrees 0)

/-- `permit` (compliant): The same car turns right in the intersection and leaves it heading to the right of its entry heading. -/
def permitTrace : Trace :=
  Build.trace 60 0 dt fun k t => mkScene t [turningRight k] singleMap

/-- `idle` (not_applicable): A highway without any turn lane; a car crosses an intersection straight. -/
def idleTrace : Trace := straightTrace (cm (-525)) plainMap

/-- `blind` (unknown): As forbid, with kin.yaw_rate declared absent, so the heading change since entry is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A car in the through lane beside the single right turn lane crosses the intersection straight; its footprint never overlapped the turn lane since its entry. -/
def branch_1Trace : Trace := straightTrace (cm (-175)) singleMap

/-- `branch_2` (not_applicable): two right turn lanes side by side; the car crosses straight from
    the rightmost one, which is no single right turn lane. -/
def branch_2Trace : Trace := straightTrace (cm (-875)) dualMap

/-- `branch_3` (compliant): as `branch_2`, but the highway has a single right turn lane on the
    westbound approach, which the car never occupies; the lane it crosses from is not single. -/
def branch_3Trace : Trace := straightTrace (cm (-875)) dualAndWestMap

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_4b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (100, ((τ.getLast?.map (·.t)).getD 0))
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_223_4b

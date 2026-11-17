/-
  Witnesses for NRS_484B_287_1c.

  Geometry (+x east, +y north, metres). A two-way street along x between two intersections:
  intersection 10 (x −60…−40) and intersection 11 (x 40…60), both y −7…7. Mid-block the street is
  written as two directed roadway segments: 20, eastbound, y −7…0, entering 11; 21, westbound,
  y 0…7, entering 10. Crosswalk 30 is a marked mid-block crossing (x −2…2) that marks no entrance;
  crosswalk 31 (x −40…−37) is an unmarked crossing recorded as marking the entrance of 21 into 10.
  Signal 1 governs intersection 10 itself; signal 2 governs segment 20, which enters 11. Both are
  uncovered, not inoperative, showing a circular indication.
  The pedestrian (track 1, half-extent 0.25 m) walks north at 1.4 m/s across the street: across a
  carrier whose direction is east or west, so its velocity's cosine with the direction is 0, far
  below p.crossing_motion_cos, and its speed far above p.halt_speed_tolerance.
  Lane witnesses (branch_3, branch_4): a one-way street with a single eastbound lane 41 (x −40…40,
  y −3…0) entering 11, fed by lane 40 (x −80…−60) entering 10, directly or through lane 42 inside 10.
  Occupancy is stated per scene. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_287_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_287_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def walk : Q := cm 140

def ped (x y : Q) (speed : Q := walk) : RoadUser :=
  Build.user 1 [.pedestrian] (x, y) Build.north speed (cm 25, cm 25, cm 90)

def caneUser : RoadUser :=
  Build.user 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 0, cm 50) Build.west Q.zero (cm 25, cm 25, cm 90)

def inter1 : Structure := Build.rect 10 .intersection (m (-60)) (m (-7)) (m (-40)) (m 7)
def inter2 : Structure := Build.rect 11 .intersection (m 40) (m (-7)) (m 60) (m 7)

/-- A directed mid-block roadway segment entering an intersection. -/
def segment (id : Nat) (y0 y1 : Q) (dir : Vec) (entersId : Nat) : Structure :=
  { Build.rect id .roadway (m (-40)) y0 (m 40) y1 with
    lane := some { direction := some dir, entersIntersection := some entersId } }

def eastbound : Structure := segment 20 (m (-7)) (m 0) Build.east 11
def westbound : Structure := segment 21 (m 0) (m 7) Build.west 10

def midCrosswalk : Structure :=
  { Build.rect 30 .crosswalk (m (-2)) (m (-7)) (m 2) (m 7) with
    marked := some true, entranceObserved := true, entranceOf := [] }

def entranceCrosswalk : Structure :=
  { Build.rect 31 .crosswalk (m (-40)) (m (-7)) (m (-37)) (m 7) with
    marked := some false, entranceObserved := true, entranceOf := [21] }

def street : List Structure := [inter1, inter2, eastbound, westbound]

def operatingSignal (id : Nat) (governs : List Nat) (shows : SignalIndication) : Device :=
  { Build.signal id governs [shows] with uncovered := some true, inoperative := some false }

def signals : List Device := [operatingSignal 1 [10] .circularGreen, operatingSignal 2 [20] .circularRed]

/-- The pedestrian's y and its occupancy at instant k of a crossing: first only the eastbound
    half, then straddling the centre, then only the westbound half. -/
def crossY (k : Nat) : Q := if k == 0 then m (-1) else if k == 1 then m 0 else m 1
def crossOcc (k : Nat) (extra : List Nat := []) : List (TrackId × RegionId) :=
  let carriers : List Nat := if k == 0 then [20] else if k == 1 then [20, 21] else [21]
  (carriers ++ extra).map fun r => (1, r)

/-- `forbid` (violated): Mid-block between two intersections each governed by an operating traffic signal, a pedestrian walks across both directional carriers of the roadway, outside any crosswalk. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (m 0) (crossY k)] street signals (some (crossOcc k))

/-- `permit` (compliant): Between the same two signalized intersections, a pedestrian walks across the roadway within a marked mid-block crosswalk. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (m 0) (crossY k)] (street ++ [midCrosswalk]) signals
      (some (crossOcc k [30]))

/-- `idle` (not_applicable): A pedestrian walks across a roadway mid-block between two intersections controlled only by stop signs, with no signal head at either. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (m 0) (crossY k)] street
      [Build.sign 1 .stopSign [21], Build.sign 2 .stopSign [20]] (some (crossOcc k))

/-- `blind` (unknown): A pedestrian crosses mid-block outside any crosswalk between two intersections with signal heads; which regions the signal heads govern is not observed on this source. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): A pedestrian crosses at the unmarked crosswalk recorded as marking the entrance of the approach into a signalized intersection: it is at the intersection, not between. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (cm (-3850)) (crossY k)] (street ++ [entranceCrosswalk]) signals
      (some (crossOcc k [31]))

/-- `branch_2` (not_applicable): the walking pedestrian, off the roadway at the first two
    observations (28 m, then 14 m south of the cane user), comes at the third to touch the cane
    user standing at the centre of the street (centre distance 0.5 m), while walking across both
    carriers outside any crosswalk between the signalized intersections: LVMC_11_30_140_B_o1
    applies there. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y : Q := if k == 0 then m (-28) else if k == 1 then m (-14) else m 0
    let occ : List (TrackId × RegionId) :=
      (if k == 2 then [(1, 20), (1, 21)] else []) ++ [(2, 21)]
    Build.scene t (some 1) [ped (m 0) y, caneUser] street signals (some occ)

/-- `branch_3` (violated): on a one-way street of one eastbound lane, entering intersection 11 and
    fed directly by a lane entering intersection 10, a pedestrian crosses the lane outside any
    crosswalk; the other intersection is found through lane connectivity. -/
def laneIn : Structure := Build.lane 40 [(m (-80), m (-3)), (m (-60), m (-3)), (m (-60), m 0), (m (-80), m 0)]
  Build.east (leadsTo := some [41]) (enters := some 10)
def laneMid : Structure := Build.lane 41 [(m (-40), m (-3)), (m 40, m (-3)), (m 40, m 0), (m (-40), m 0)]
  Build.east (enters := some 11)
/-- branch_3: signal 1 governs intersection 10 itself; signal 2 governs lane 41, which enters 11. -/
def laneSignals3 : List Device := [operatingSignal 1 [10] .circularGreen, operatingSignal 2 [41] .circularRed]
/-- branch_4: signal 1 governs lane 40, which enters 10; signal 2 governs intersection 11 itself. -/
def laneSignals4 : List Device := [operatingSignal 1 [40] .circularGreen, operatingSignal 2 [11] .circularRed]

def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ped (m 0) (cm (-150))] [inter1, inter2, laneIn, laneMid] laneSignals3
      (some [(1, 41)])

/-- `branch_4` (violated): as branch_3, but the lane entering intersection 10 leads into the
    lane between through a connector lane inside intersection 10. -/
def laneInVia : Structure := Build.lane 40 [(m (-80), m (-3)), (m (-60), m (-3)), (m (-60), m 0), (m (-80), m 0)]
  Build.east (leadsTo := some [42]) (enters := some 10)
def laneConnector : Structure := Build.lane 42 [(m (-60), m (-3)), (m (-40), m (-3)), (m (-40), m 0), (m (-60), m 0)]
  Build.east (leadsTo := some [41])

def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ped (m 0) (cm (-150))] [inter1, inter2, laneInVia, laneConnector, laneMid]
      laneSignals4 (some [(1, 41)])

/-- `branch_5` (not_applicable): the pedestrian, off the roadway at first, comes to touch the cane
    user at the centre of the street (o1's event), halts there, then proceeds across the street a
    metre aside, no longer touching: LVMC_11_30_140_B_o2 applies while it proceeds. -/
def branch_5Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let p : RoadUser :=
      if k == 0 then ped (m 0) (m (-28))
      else if k == 1 then ped (m 0) (m 0)
      else if k == 2 then ped (m 0) (m 0) Q.zero
      else ped (m 1) (m 0)
    let occ : List (TrackId × RegionId) :=
      (if k == 0 then [] else [(1, 20), (1, 21)]) ++ [(2, 21)]
    Build.scene t (some 1) [p, caneUser] street signals (some occ)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_287_1c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_287_1c

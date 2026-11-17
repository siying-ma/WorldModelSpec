/-
  Witnesses for NRS_484B_287_1c.

  Geometry (metres, +x east, +y north): a two-way roadway along x between two intersections,
  I2 (region 11, x ∈ [-70, -50]) to the west and I1 (region 10, x ∈ [50, 70]) to the east, each
  14 m deep (y ∈ [-7, 7]). The roadway between them is written as one directed carrier per
  direction: lane 20 (y ∈ [-7, 0], eastbound, enters I1) and lane 21 (y ∈ [0, 7], westbound,
  enters I2). Signal 1 governs I1 itself; signal 2 governs lane 21, which enters I2; both are
  uncovered, show circular green and are not inoperative.

  The pedestrian (track 1) walks north at 1.4 m/s (far above the 0.1 m/s halt tolerance; its
  velocity is perpendicular to both carriers, cosine 0 against 0.94), body 0.6 m × 0.6 m. Three
  instants 0.1 s apart. Occupancy is stated: in the mid-block scenes the body straddles the lane
  line y = 0, so it overlaps both lanes.

  branch_3 / branch_4: the pedestrian is in lane 20 only, and I2 is reached through lane
  connectivity: lane 22 (x ∈ [-90, -70], eastbound, enters I2) leads into lane 20 directly
  (branch_3), or through lane 23 (x ∈ [-50, -30], recorded as entering no intersection) between
  (branch_4); signal 2 then governs lane 22.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_287_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_287_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def i1 : Structure := Build.rect 10 .intersection (m 50) (m (-7)) (m 70) (m 7)
def i2 : Structure := Build.rect 11 .intersection (m (-70)) (m (-7)) (m (-50)) (m 7)
def laneE : Structure :=
  Build.lane 20 (box (m (-50)) (m (-7)) (m 50) (m 0)) Build.east (leadsTo := some []) (enters := some 10)
def laneW : Structure :=
  Build.lane 21 (box (m (-50)) (m 0) (m 50) (m 7)) Build.west (leadsTo := some []) (enters := some 11)

/-- A traffic signal in operation: uncovered, showing circular green, not inoperative. -/
def opSignal (id : DeviceId) (gov : List RegionId) : Device :=
  { Build.signal id gov [.circularGreen] with uncovered := some true, inoperative := some false }

def signals : List Device := [opSignal 1 [10], opSignal 2 [21]]

/-- The pedestrian walking north at 1.4 m/s from `(x, y0)`, 0.14 m per 0.1 s step. -/
def ped (k : Nat) (x y0 : Q) : RoadUser :=
  Build.user 1 [.pedestrian] (x, Q.add y0 (Q.mul (Q.ofInt (Int.ofNat k)) (cm 14))) Build.north (cm 140)
    (cm 30, cm 30, cm 90)

def dt : Q := Units.milliseconds 100

/-- `forbid` (violated): Mid-block between two intersections each governed by an operating traffic signal, a pedestrian walks across both directional carriers of the roadway, outside any crosswalk. -/
def forbidTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-14)) ]
      [ i1, i2, laneE, laneW ]
      signals
      (occupies := some [(1, 20), (1, 21)])

/-- `permit` (compliant): Between the same two signalized intersections, a pedestrian walks across the roadway within a marked mid-block crosswalk. -/
def permitTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-14)) ]
      [ i1, i2, laneE, laneW,
        { Build.rect 30 .crosswalk (m (-2)) (m (-7)) (m 2) (m 7) with
            marked := some true, entranceOf := [], entranceObserved := true } ]
      signals
      (occupies := some [(1, 20), (1, 21), (1, 30)])

/-- `idle` (not_applicable): A pedestrian walks across a roadway mid-block between two intersections controlled only by stop signs, with no signal head at either. -/
def idleTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-14)) ]
      [ i1, i2, laneE, laneW ]
      [ Build.sign 1 .stopSign [20], Build.sign 2 .stopSign [21] ]
      (occupies := some [(1, 20), (1, 21)])

/-- `blind` (unknown): A pedestrian crosses mid-block outside any crosswalk between two intersections with signal heads; which regions the signal heads govern is not observed on this source. -/
def blindTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-14)) ]
      [ i1, i2, laneE, laneW ]
      [ { opSignal 1 [] with governsObserved := false },
        { opSignal 2 [] with governsObserved := false } ]
      (occupies := some [(1, 20), (1, 21)])

/-- `branch_1` (not_applicable): A pedestrian crosses at the unmarked crosswalk recorded as marking the entrance of the approach into a signalized intersection: it is at the intersection, not between. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 48) (cm (-14)) ]
      [ i1, i2, laneE, laneW,
        { Build.rect 31 .crosswalk (m 46) (m (-7)) (m 50) (m 7) with
            marked := some false, entranceOf := [20], entranceObserved := true } ]
      signals
      (occupies := some [(1, 20), (1, 21), (1, 31)])

/-- `branch_2` (not_applicable): A pedestrian who is not blind approaches a person carrying a white cane while crossing mid-block between two signalized intersections, so LVMC_11_30_140_B_o1 applies to it. -/
-- Twelve instants 1 s apart. The pedestrian stands at y = -18 m (off the roadway) for the first
-- three, then walks north at 2 m/s to y = 0 m (straddling the lane line). A person with a white
-- cane stands at (0, 9) north of the roadway for the first four, then walks south at 1 m/s into
-- lane 21 (from the sixth instant) and reaches (0, 1), 0.4 m ahead of the pedestrian's body; the
-- two close on each other, each in the other's line of sight throughout (the measured `visible`
-- relation, which Core never computes). The roadway (region 40) under both lanes is built, so each
-- one's entry onto it is recorded. The witness speaks about the last instant, every onset
-- having happened inside the trace.
def branch_2Trace : Trace :=
  Build.trace 12 0 (Units.seconds 1) fun k t =>
    let walked : Int := if k < 3 then 0 else 2 * (Int.ofNat k - 2)
    let caneWalked : Int := if k < 4 then 0 else Int.ofNat k - 3
    Build.withRelations
      (Build.scene t (some 1)
        [ Build.user 1 [.pedestrian] (m 0, m (-18 + walked)) Build.north (if k < 3 then m 0 else m 2)
            (cm 30, cm 30, cm 90),
          Build.user 2 [.pedestrian, .pedestrianWithWhiteCaneOrGuideAnimal] (m 0, m (9 - caneWalked))
            Build.south (if k < 4 then m 0 else m 1) (cm 30, cm 30, cm 90) ]
        [ i1, i2, laneE, laneW, Build.rect 40 .roadway (m (-50)) (m (-7)) (m 50) (m 7) ]
        signals
        (occupies := some ((if k ≥ 8 then [(1, 20), (1, 40)] else [])
                            ++ (if k = 11 then [(1, 21)] else [])
                            ++ (if k ≥ 5 then [(2, 21), (2, 40)] else []))))
      [ Build.relation 1 2 (fun r => { r with visible := some true }),
        Build.relation 2 1 (fun r => { r with visible := some true }) ]

def laneEshort : Structure :=
  Build.lane 20 (box (m (-30)) (m (-7)) (m 50) (m 0)) Build.east (leadsTo := some []) (enters := some 10)

/-- `branch_3` (violated): a pedestrian crosses the eastbound lane only, outside any crosswalk; the
    second signalized intersection is the one whose approach lane leads directly into that lane. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-364)) ]
      [ i1, i2, laneE, laneW,
        Build.lane 22 (box (m (-90)) (m (-7)) (m (-70)) (m 0)) Build.east (leadsTo := some [20])
          (enters := some 11) ]
      [ opSignal 1 [10], opSignal 2 [22] ]
      (occupies := some [(1, 20)])

/-- `branch_4` (violated): as branch_3, but the approach lane into the second intersection leads
    into the pedestrian's lane through one lane between. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ ped k (m 0) (cm (-364)) ]
      [ i1, i2, laneEshort, laneW,
        Build.lane 22 (box (m (-90)) (m (-7)) (m (-70)) (m 0)) Build.east (leadsTo := some [23])
          (enters := some 11),
        Build.lane 23 (box (m (-50)) (m (-7)) (m (-30)) (m 0)) Build.east (leadsTo := some [20]) ]
      [ opSignal 1 [10], opSignal 2 [22] ]
      (occupies := some [(1, 20)])

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
  , { witness "branch_2" branch_2Trace .notApplicable with window := some (11000, 11000) }
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_287_1c

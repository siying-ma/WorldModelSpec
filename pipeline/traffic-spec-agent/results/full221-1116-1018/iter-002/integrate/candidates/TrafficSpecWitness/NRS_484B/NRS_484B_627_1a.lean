/-
  Witnesses for NRS_484B_627_1a.

  Geometry (the witness's own figures, none in the rule). A two-way highway (region 1) runs east
  along x, from y = −2 to y = 2·half + 2 where `half` is the paved half width (5.5 m; 3.2 m in
  branch_1). Lane 10 (eastbound, count 1) spans y ∈ [0, half]; lane 11 (westbound, count 1) spans
  y ∈ [half, 2·half]. The centre line (20) is the strip y ∈ [half, half + 0.1], the right road edge
  (21) the strip y ∈ [−0.1, 0], the left road edge (22) the strip y ∈ [2·half, 2·half + 0.1]; all lie
  on highway 1. In branch_4 a second westbound lane (12) spans y ∈ [2·half, 2·half + 3.5], both
  westbound lanes count two, and the left road edge moves out to 2·half + 3.5. A maximum speed limit sign (30) of 25 m/s governs lane 10.

  The subject (track 1, a motor vehicle, 4.5 m × 1.8 m) heads east at 15 m/s (24 m/s in branch_2)
  from x = −200, at lateral position y = 2.7 (right side 1.8 m from the edge; y = 1.3 in permit,
  right side 0.4 m). A following car (track 2) runs at the same speed 10 m (body gap) behind it in
  lane 10 (in blind its body size and occupancy are unobserved, the source measures that it is
  behind the subject in the lane and the 10 m gap, and the manifest masks the gap, which therefore
  cannot be computed either); in branch_3 a leading car (track 3) runs 10 m ahead of it. Scenes every second over
  0 … 15 s; the witnesses speak about 12 … 15 s, so the 10 s move-over window is covered.

  Reading values used: margin 4.5 m/s (15 + 4.5 < 25; 24 + 4.5 > 25), reach 30 m (gap 10 m),
  free passage 3.0 m (width 1.8 + 3.0 = 4.8 ≤ 5.5, > 3.2), pull-over gap 1.0 m (right side 1.8 m
  breaks it, 0.4 m keeps it), opposed cosine 0.9 (east·west = −1).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_627_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_627_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Half extents of a car: 4.5 m long, 1.8 m wide, 1.5 m high. -/
def carHalf : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The carriageway with a paved half of `half` metres (as centimetres). -/
def structures (halfCm : Int) (twoWest : Bool := false) : List Structure :=
  let h := cm halfCm
  let h2 := cm (2 * halfCm)
  let far := if twoWest then Q.add h2 (cm 350) else h2   -- the left road edge
  let westCount : Nat := if twoWest then 2 else 1
  let x0 := m (-1000); let x1 := m 1000
  let onWay (s : Structure) : Structure := { s with ways := some [1] }
  [ Build.rect 1 .highway x0 (m (-2)) x1 (Q.add far (m 2))
  , onWay (Build.lane 10 [(x0, Q.zero), (x1, Q.zero), (x1, h), (x0, h)] Build.east
      (ordinal := some 1) (count := some 1))
  , onWay (Build.lane 11 [(x0, h), (x1, h), (x1, h2), (x0, h2)] Build.west
      (ordinal := some westCount) (count := some westCount))
  , onWay (Build.rect 20 .centreLine x0 h x1 (Q.add h (cm 10)))
  , onWay (Build.rect 21 .roadEdge x0 (cm (-10)) x1 Q.zero)
  , onWay (Build.rect 22 .roadEdge x0 far x1 (Q.add far (cm 10))) ]
  ++ (if twoWest then
        [ onWay (Build.lane 12 [(x0, h2), (x1, h2), (x1, far), (x0, far)] Build.west
            (ordinal := some 1) (count := some 2)) ]
      else [])

def devices : List Device := [Build.speedLimit 30 [10] (Units.metresPerSecond 25) .maximum]

/-- A scene at step `k`: subject at lateral `yCm`, speed `v`; follower and leader optional. -/
def sceneAt (k : Nat) (t : Timestamp) (halfCm yCm : Int) (v : Int)
    (follower leader measuredGap twoWest : Bool) : Scene :=
  let x : Q := Q.add (m (-200)) (Units.metres (v * Int.ofNat k))
  let y := cm yCm
  let speed := Units.metresPerSecond v
  let subj := Build.user 1 [.motorVehicle] (x, y) Build.east speed carHalf
  let fol0 := Build.user 2 [.motorVehicle] (Q.sub x (cm 1450), y) Build.east speed carHalf
  -- with a measured gap, the follower's body size is not observed: Core cannot compute the gap
  let fol := if measuredGap then Build.withKin fol0 (fun kn => { kn with extent := none }) else fol0
  let lead := Build.user 3 [.motorVehicle] (Q.add x (cm 1450), y) Build.east speed carHalf
  let users := [subj] ++ (if follower then [fol] else []) ++ (if leader then [lead] else [])
  let s := Build.scene t (some 1) users (structures halfCm twoWest) devices
  if measuredGap then
    -- the source observes only the subject's occupancy and measures the order in the lane and
    -- the gap itself; neither can be computed from the follower's kinematics
    let s' := { s with occupancyObserved := [1], occupies := s.occupies.filter (·.1 == 1) }
    Build.withRelations s'
      [ Build.relation 1 2 (fun r => { r with surfaceGap := some (m 10, Q.zero), aAheadOfB := some true })
      , Build.relation 2 1 (fun r => { r with aAheadOfB := some false }) ]
  else s

def mkTrace (halfCm yCm v : Int) (follower : Bool := true) (leader : Bool := false)
    (measuredGap : Bool := false) (twoWest : Bool := false) : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    sceneAt k t halfCm yCm v follower leader measuredGap twoWest

/-- `forbid` (violated): A car on a two-lane two-way highway (one lane in its direction, centre line present) under a 25 m/s maximum sign has moved at 15 m/s for longer than the move-over time with a car 10 m behind it in its lane and no one ahead; the paved half is 5.5 m wide, enough for its width plus the passage width; its right side stays 1.8 m from the right road edge. -/
def forbidTrace : Trace := mkTrace 550 270 15

/-- `permit` (compliant): The same scene, but the car's right side runs 0.4 m from the right road edge. -/
def permitTrace : Trace := mkTrace 550 130 15

/-- `idle` (not_applicable): The same slow car on the same highway with no road user behind it. -/
def idleTrace : Trace := mkTrace 550 270 15 (follower := false)

/-- `blind` (unknown): As in forbid, but the source does not supply the gap between the car and the vehicle behind it, so whether traffic is immediately behind is unobserved. -/
def blindTrace : Trace := mkTrace 550 270 15 (measuredGap := true)

/-- `branch_1` (not_applicable): As in forbid, but the paved half of the roadway is 3.2 m: it is narrower than the car's width plus the passage width, so the width does not permit. -/
def branch_1Trace : Trace := mkTrace 320 270 15

/-- `branch_2` (not_applicable): As in forbid, but the car travels at 24 m/s under the 25 m/s maximum: it is not slow. -/
def branch_2Trace : Trace := mkTrace 550 270 24

/-- `branch_3` (not_applicable): As in forbid, but a car runs 10 m ahead of it in its lane: it is itself held back, not impeding. -/
def branch_3Trace : Trace := mkTrace 550 270 15 (leader := true)

/-- `branch_4` (not_applicable): As in forbid, but the other direction has two lanes (lanes 11 and 12, each counting two in its direction): the highway does not have one lane in each direction. -/
def branch_4Trace : Trace := mkTrace 550 270 15 (twoWest := true)

/-- The instants the witnesses speak about: the move-over window behind each is covered. -/
def judged : Option (Timestamp × Timestamp) := some (12000, 15000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_627_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_627_1a

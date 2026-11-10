/-
  Witnesses for NRS_484B_210_3.

  The carriageway runs east (+x), so a road user's left is north (+y). Lane 10 is the strip
  y ∈ [0, 4], lane 11 the strip y ∈ [4, 8], both 400 m long; shoulder 20 is the strip y ∈ [-4, 0]
  beside lane 10 on its right (south); road edge 30 is the strip y ∈ [-1/2, 1/2] at the lane's
  right edge, its `paved` the surface beyond it. Every body is 5 m long and 2 m wide (half extents
  250 cm, 100 cm, 80 cm). The subject (track 1) heads east; the other road user (track 2) heads
  east 1 m ahead of it and 4 m to its left, so the two footprints share 4 m along the subject's
  heading and the other lies on the subject's left. The gainer moves at 20 m/s, the other at
  15 m/s: 5 m/s apart, far above the reading's 0.2 m/s speed tolerance; the headings are equal
  (cosine 1, above the reading's 0.9). Three instants one second apart, each scene the same;
  occupancy follows the reference points except where a footprint straddles the road edge,
  where it is stated. In forbid and blind the source does not observe the other car's extent, so
  the overlap is its measured 4 m (which blind's manifest masks) and only the subject's occupancy
  is observed. The rule looks back nowhere, so no witness names a window.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_210_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_210_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def body : Q × Q × Q := (cm 250, cm 100, cm 80)
def fast : Q := Units.metresPerSecond 20
def slow : Q := Units.metresPerSecond 15

def lane10 : Structure := Build.rect 10 .lane (m (-200)) (m 0) (m 200) (m 4)
def lane11 : Structure := Build.rect 11 .lane (m (-200)) (m 4) (m 200) (m 8)
def shoulder (paved : Bool) : Structure :=
  { Build.rect 20 .shoulder (m (-200)) (m (-4)) (m 200) (m 0) with paved := some paved }
def roadEdge (paved : Bool) : Structure :=
  { Build.rect 30 .roadEdge (m (-200)) (cm (-50)) (m 200) (cm 50) with paved := some paved }

/-- Subject on the shoulder (y = -2), the other in lane 10 on its left (y = 2). -/
def shoulderScene (t : Timestamp) (paved : Bool) (cls1 cls2 : List RoadUserClass) (v1 v2 : Q) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 cls1 (m 0, m (-2)) Build.east v1 body
    , Build.user 2 cls2 (m 1, m 2) Build.east v2 body ]
    [ lane10, lane11, shoulder paved ]
    [ ]

/-- Subject straddling the road edge (y = 1/2, footprint y ∈ [-1/2, 3/2]), the other in lane 11. -/
def edgeScene (t : Timestamp) (paved : Bool) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (m 0, cm 50) Build.east fast body
    , Build.user 2 [.motorVehicle] (m 1, cm 450) Build.east slow body ]
    [ lane10, lane11, roadEdge paved ]
    [ ]
    (occupies := some [(1, 30), (1, 10), (2, 11)])

/-- `forbid` (violated): A car's footprint overlaps an unpaved st.shoulder; a slower car travels the same way in the adjacent lane on its left; their footprints overlap along the subject's heading and the subject is gaining. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    -- the source does not observe the other car's extent, so the overlap is not computable from
    -- the footprints and is the source's measurement: the 4 m the two share; without a footprint
    -- the other car's occupancy is not observed
    let s := Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (m 0, m (-2)) Build.east fast body
        , Build.withKin (Build.user 2 [.motorVehicle] (m 1, m 2) Build.east slow body)
            fun k => { k with extent := none } ]
        [ lane10, lane11, shoulder false ]
        [ ]
        (occupies := some [(1, 20)])
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (m 4) } ]

/-- `permit` (compliant): A car on the unpaved shoulder moves slower than the car beside it on its left: it is being passed, not passing. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    shoulderScene t false [.motorVehicle] [.motorVehicle] slow fast

/-- `idle` (not_applicable): A car passes a slower car on its right within the paved roadway; no unpaved shoulder or edge is overlapped. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 2) Build.east fast body
      , Build.user 2 [.motorVehicle] (m 1, m 6) Build.east slow body ]
      [ lane10, lane11, shoulder false,
        { Build.rect 30 .roadEdge (m (-200)) (m (-4)) (m 200) (m (-3)) with paved := some false } ]
      [ ]

/-- `blind` (unknown): As forbid, with rel.longitudinal_overlap declared absent, so whether the two are side by side is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A car moves alone along the unpaved shoulder; no other road user is in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-2)) Build.east fast body ]
      [ lane10, lane11, shoulder false ]
      [ ]

/-- `branch_2` (violated): the car's footprint straddles a road edge whose surface beyond is unpaved while it gains on a slower car on its left. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => edgeScene t false

/-- `branch_3` (not_applicable): as branch_2, but the surface beyond the straddled edge is paved. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => edgeScene t true

/-- `branch_4` (not_applicable): as forbid, but the shoulder is paved. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    shoulderScene t true [.motorVehicle] [.motorVehicle] fast slow

/-- `branch_5` (compliant): as forbid, but the road user gained on is a bicycle, no member of the vehicle aggregate. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    shoulderScene t false [.motorVehicle] [.bicycle] fast slow

/-- `branch_6` (not_applicable): as forbid, but the subject on the shoulder is a bicycle, no member of the vehicle aggregate. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    shoulderScene t false [.bicycle] [.motorVehicle] fast slow

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_210_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_210_3

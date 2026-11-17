/-
  Witnesses for NRS_484B_283_1d4_o1.

  Geometry (x east, y north, metres; observations 1 s apart; the pedestrian, track 1, heads north
  with half-extents 25 cm × 25 cm × 90 cm):
  - forbid / permit / idle / blind: sidewalk 10 (y ∈ [-5, 0]), roadway 11 (y ∈ [0, 12], traffic
    direction east), sidewalk 12 (y ∈ [12, 17]), all x ∈ [-20, 20]; a marked crosswalk 16
    (x ∈ [-2, 2], y ∈ [0, 12]) over the crossing. Pedestrian head 20 at (0, 14), across the
    roadway, governing roadway 11. The pedestrian is at (0, -2.5), (0, -1) (on the curb, 15 m from
    the head, heading straight at it) and, where it steps, (0, 0.5) inside roadway 11.
  - branch_1: sidewalk 10 (y ∈ [-5, 0]), roadway 11 (y ∈ [0, 3]), median 13 (y ∈ [3, 5]),
    roadway 14 (y ∈ [5, 8]), sidewalk 12 (y ∈ [8, 12]). Head 20 at (0, 4.5) governs roadway 11 and
    shows dont_walk_flashing with countdown; head 21 at (0, 10) governs roadway 14 and shows
    dont_walk_steady. The pedestrian walks (0,-0.5) → (0,1) → (0,2.5) → (0,4) → (0,5.5).
  - branch_2: as forbid, but the region crossed is lane 15 (y ∈ [0, 12]) governed by the head.
  - branch_3: as branch_1, but the first carriageway is lane 15 (y ∈ [0, 3]) and its head 20 shows
    walk.
  The rule looks back one observation (`rises`, `since`), so each witness names the instants from
  the second observation on.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ped (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.pedestrian] pos Build.north speed (cm 25, cm 25, cm 90)

def pedHead (id : DeviceId) (governs : List RegionId) (pos : Vec) (st : PedSignalState)
    (countdown : Bool := false) : Device :=
  { Build.device id .pedestrianSignal governs (some pos) with
      pedState := some st, countdown := some countdown }

/-- One carriageway between two sidewalks; the crossed region has the given kind. -/
def oneCrossing (crossedKind : StructureKind) : List Structure :=
  [ Build.rect 10 .sidewalk (m (-20)) (m (-5)) (m 20) (m 0)
  , { Build.rect 11 crossedKind (m (-20)) (m 0) (m 20) (m 12) with
        lane := some { direction := some Build.east } }
  , { Build.rect 16 .crosswalk (m (-2)) (m 0) (m 2) (m 12) with marked := some true }
  , Build.rect 12 .sidewalk (m (-20)) (m 12) (m 20) (m 17) ]

/-- Positions of a pedestrian that waits on the curb, then (if `steps`) steps into the roadway. -/
def curbPos (steps : Bool) (k : Nat) : Vec :=
  match k with
  | 0 => (m 0, cm (-250))
  | 1 => (m 0, cm (-100))
  | _ => if steps then (m 0, cm 50) else (m 0, cm (-100))

def curbSpeed (steps : Bool) (k : Nat) : Q :=
  match k with
  | 0 => cm 150
  | 1 => if steps then cm 150 else m 0
  | _ => if steps then cm 150 else m 0

/-- `forbid` (violated): At the curb, the pedestrian faces a head 15 m away across roadway r that governs r and shows dont_walk_steady; at the next observation its footprint overlaps r. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (curbPos true k) (curbSpeed true k) ]
      (oneCrossing .roadway)
      [ pedHead 20 [11] (m 0, m 14) .dontWalkSteady ]

/-- `permit` (compliant): Same head and state; the pedestrian waits on the sidewalk. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (curbPos false k) (curbSpeed false k) ]
      (oneCrossing .roadway)
      [ pedHead 20 [11] (m 0, m 14) .dontWalkSteady ]

/-- `idle` (not_applicable): The faced head shows walk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (curbPos true k) (curbSpeed true k) ]
      (oneCrossing .roadway)
      [ pedHead 20 [11] (m 0, m 14) .walk ]

/-- `blind` (unknown): The pedestrian steps onto r facing the head, but the head's state is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (curbPos true k) (curbSpeed true k) ]
      (oneCrossing .roadway)
      [ pedHead 20 [11] (m 0, m 14) .dontWalkSteady ]

/-- Two carriageways with a median between; the first has the given kind. -/
def twoCrossings (firstKind : StructureKind) (firstId : RegionId) : List Structure :=
  [ Build.rect 10 .sidewalk (m (-20)) (m (-5)) (m 20) (m 0)
  , Build.rect firstId firstKind (m (-20)) (m 0) (m 20) (m 3)
  , Build.rect 13 .medianOrDivider (m (-20)) (m 3) (m 20) (m 5)
  , Build.rect 14 .roadway (m (-20)) (m 5) (m 20) (m 8)
  , Build.rect 12 .sidewalk (m (-20)) (m 8) (m 20) (m 12) ]

def acrossPos (k : Nat) : Vec := (m 0, Q.add (cm (-50)) (Q.mul (Q.ofInt (Int.ofNat k)) (cm 150)))

/-- `branch_1` (not_applicable): The pedestrian stepped onto the first roadway while its head showed dont_walk_flashing with countdown, reached the median, and now steps onto the second roadway r while its faced head shows dont_walk_steady: it is continuing a lawful crossing. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (acrossPos k) (cm 150) ]
      (twoCrossings .roadway 11)
      [ pedHead 20 [11] (m 0, cm 450) .dontWalkFlashing true
      , pedHead 21 [14] (m 0, m 10) .dontWalkSteady ]

/-- `branch_2` (violated): as forbid, but the head governs a lane and the pedestrian steps into it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (curbPos true k) (curbSpeed true k) ]
      (oneCrossing .lane)
      [ pedHead 20 [11] (m 0, m 14) .dontWalkSteady ]

/-- `branch_3` (not_applicable): the pedestrian stepped into a lane while its head showed walk,
    reached the median, and steps onto the second roadway under dont_walk_steady. -/
def branch_3Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (acrossPos k) (cm 150) ]
      (twoCrossings .lane 15)
      [ pedHead 20 [15] (m 0, cm 450) .walk
      , pedHead 21 [14] (m 0, m 10) .dontWalkSteady ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (1000, 2000))
  , witness "permit" permitTrace .compliant (window := some (1000, 2000))
  , witness "idle" idleTrace .notApplicable (window := some (1000, 2000))
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"] (window := some (1000, 2000))
  , witness "branch_1" branch_1Trace .notApplicable (window := some (1000, 4000))
  , witness "branch_2" branch_2Trace .violated (window := some (1000, 2000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (1000, 4000)) ]

end TrafficSpecWitness.NRS_484B_283_1d4_o1

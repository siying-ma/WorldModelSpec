/-
  Witnesses for NRS_484B_270_3_o2.

  A straight road running east: bicycle lane b (region 10) between y = 0 and y = 2 m, general
  lane g (region 11) between y = 2 and y = 5.5 m, a further general lane n (region 12) between
  y = 5.5 and y = 9 m; both general lanes run east. South of b, a driveway entrance d (region 13,
  x 30…36 m, y −8…0 m) or an alley a (region 14, x 30…36 m, y −30…0 m) meets the road.
  x (track 1) is a car, half-length 2.25 m, half-width 0.9 m; on b its reference point is at
  y = 1 m, in g at y = 3.75 m. Scenes are 1 s apart from t = 0. Every scene declares the three
  assumptions false, except in blind and branches 4–6, which each set one true. A body across two regions has its occupancy
  stated. Where x is off b at the trace's ends (so the stay on b is bounded and the look-backs and
  look-aheads over it are decided), `window` names the instants on b the witness speaks about.
  Conflicts (branch_2, branch_7): the other car z (track 2) heads (0.8, −0.6) at 10 m/s from 1 m
  ahead and 6 m left of x running east at 8 m/s: closest approach after 1 s at 1 m between
  centres, inside the 3 s horizon and well below the 4 m clearance.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_3_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_3_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def bLane : RegionId := 10
def gLane : RegionId := 11
def nLane : RegionId := 12
def dEntrance : RegionId := 13
def aAlley : RegionId := 14

def road : List Structure :=
  [ Build.rect bLane .bicycleLaneOrPath (m (-100)) (m 0) (m 300) (m 2)
  , Build.rect gLane .lane (m (-100)) (m 2) (m 300) (cm 550)
  , Build.rect nLane .lane (m (-100)) (cm 550) (m 300) (m 9) ]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed carExtent

/-- The heading of the merging car: 0.8 east, 0.6 south. -/
def southEast : Vec := (Units.ratio 4 5, Units.ratio (-3) 5)

def asms (disabled duties emergency : Bool) : List (AsmId × Bool) :=
  [("asm.vehicle_disabled", disabled), ("asm.performing_official_duties", duties),
   ("asm.emergency", emergency)]

def noAsm : List (AsmId × Bool) := asms false false false

/-- x in g at k = 0, on b from k = 1 to k = 6 (50 m along it), back in g at k = 7. -/
def alongLanePos (k : Nat) : Vec :=
  if k = 0 ∨ k ≥ 7 then (m (10 * k), cm 375) else (m (10 * k), cm 100)

def alongLaneTrace (as : List (AsmId × Bool)) : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (alongLanePos k) Build.east (Units.metresPerSecond 10) ]
      road
      [ ]
      (assumptions := as)

/-- `forbid` (violated): x drives 50 m along bicycle lane b mid-block; no driveway or alley, no officer, no conflict at entry; the trace declares asm.vehicle_disabled, asm.performing_official_duties and asm.emergency false. -/
def forbidTrace : Trace := alongLaneTrace noAsm

/-- `permit` (compliant): x drives in the general lane next to b, never overlapping b. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (10 * k), cm 375) Build.east (Units.metresPerSecond 10) ]
      road
      [ ]
      (assumptions := noAsm)

/-- `idle` (not_applicable): x crosses b to turn into a driveway: during the stay its footprint overlaps a st.driveway_or_alley_entrance. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let pos : Vec :=
      if k = 0 then (m 20, cm 375) else if k = 1 then (m 30, cm 100)
      else if k = 2 then (m 33, m (-1)) else (m 33, m (-6))
    Build.scene t (some 1)
      [ car 1 pos (if k ≤ 1 then Build.east else Build.south) (Units.metresPerSecond 5) ]
      (road ++ [ Build.rect dEntrance .drivewayOrAlleyEntrance (m 30) (m (-8)) (m 36) (m 0) ])
      [ ]
      (occupies := if k = 2 then some [(1, bLane), (1, dEntrance)] else none)
      (assumptions := noAsm)

/-- `blind` (unknown): As forbid, but rel.occupies is not observed, so whether x is on b is unknown.
    The scenes also declare asm.emergency true. With occupancy unobserved, the run on b cannot be
    seen to start or end, so exceptions (a) and (c), which look back and ahead over the current
    stay, would otherwise be unknown because the trace is cut off, not because of the mask. With
    the emergency declared, the exceptions are decided and occupancy alone leaves the verdict
    open: on b, the rule does not apply; off b, it is complied with. -/
def blindTrace : Trace := alongLaneTrace (asms false false true)

/-- `branch_1` (not_applicable): x drives in b while a dev.human_direction with role police_officer governs b and directs traffic through it. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (10 * k), cm 100) Build.east (Units.metresPerSecond 10) ]
      road
      [ { Build.device 30 .humanDirection [bLane] (some (m 25, m (-1))) with
          humanRole := some .policeOfficer, humanIndication := some .proceed } ]
      (assumptions := noAsm)

/-- `branch_2` (not_applicable): x swerves onto b at the moment a vehicle merging from the left has a predicted closest approach to x of 1 m in 1 s. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let xPos : Vec := if k = 0 then (m 0, cm 375) else (m (8 * k), cm 100)
    let z : RoadUser :=
      if k = 0 then car 2 (m 1, cm 725) Build.east (Units.metresPerSecond 8)
      else if k = 1 then car 2 (m 9, m 7) southEast (Units.metresPerSecond 10)
      else if k = 2 then car 2 (m 17, m 4) Build.east (Units.metresPerSecond 10)
      else car 2 (m 27, cm 375) Build.east (Units.metresPerSecond 10)
    Build.scene t (some 1)
      [ car 1 xPos Build.east (Units.metresPerSecond 8), z ]
      road
      [ ]
      (assumptions := noAsm)

/-- `branch_3` (not_applicable): x exits an alley across b into g; at the later observations of
    the stay on b its footprint no longer overlaps the alley, but it did earlier in the stay. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let pos : Vec :=
      if k = 0 then (m 33, m (-5)) else if k = 1 then (m 33, m (-1))
      else if k = 2 then (m 36, m 1) else (m 45, cm 375)
    Build.scene t (some 1)
      [ car 1 pos (if k ≤ 1 then Build.north else Build.east) (Units.metresPerSecond 5) ]
      (road ++ [ Build.rect aAlley .alley (m 30) (m (-30)) (m 36) (m 0) ])
      [ ]
      (occupies := if k = 1 then some [(1, bLane), (1, aAlley)] else none)
      (assumptions := noAsm)

/-- `branch_4` (not_applicable): as forbid, the vehicle declared disabled. -/
def branch_4Trace : Trace := alongLaneTrace (asms true false false)

/-- `branch_5` (not_applicable): as forbid, x declared performing official duties. -/
def branch_5Trace : Trace := alongLaneTrace (asms false true false)

/-- `branch_6` (not_applicable): as forbid, an emergency declared in progress for x. -/
def branch_6Trace : Trace := alongLaneTrace (asms false false true)

/-- `branch_7` (violated): x moves onto b with no conflict at entry (z runs parallel in n at x's
    velocity); one second later, mid-stay, z merges with a predicted closest approach of 1 m in
    1 s. The conflict is not at the observation at which the stay began. -/
def branch_7Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let xPos : Vec := if k = 0 ∨ k ≥ 4 then (m (8 * k), cm 375) else (m (8 * k), cm 100)
    let z : RoadUser :=
      if k ≤ 1 then car 2 (m (8 * k + 1), cm 725) Build.east (Units.metresPerSecond 8)
      else if k = 2 then car 2 (m 17, m 7) southEast (Units.metresPerSecond 10)
      else car 2 (m (8 * k + 3), cm 725) Build.east (Units.metresPerSecond 8)
    Build.scene t (some 1)
      [ car 1 xPos Build.east (Units.metresPerSecond 8), z ]
      road
      [ ]
      (assumptions := noAsm)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_270_3_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (0, 7000))
  , witness "permit" permitTrace .compliant (window := some (0, 3000))
  , witness "idle" idleTrace .notApplicable (window := some (1000, 2000))
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (window := some (0, 7000))
  , witness "branch_1" branch_1Trace .notApplicable (window := some (0, 2000))
  , witness "branch_2" branch_2Trace .notApplicable (window := some (1000, 3000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (1000, 2000))
  , witness "branch_4" branch_4Trace .notApplicable (window := some (1000, 6000))
  , witness "branch_5" branch_5Trace .notApplicable (window := some (1000, 6000))
  , witness "branch_6" branch_6Trace .notApplicable (window := some (1000, 6000))
  , witness "branch_7" branch_7Trace .violated (window := some (2000, 2000)) ]

end TrafficSpecWitness.NRS_484B_270_3_o2

/-
  Witnesses for NRS_484B_283_1d3_o1.

  Geometry (+x east, +y north, metres). The pedestrian (track 1, half-extent 0.25 × 0.25 × 0.9)
  walks north along x = 0 at 2 m/s, sampled every second.

  One crossing (forbid, permit, idle, blind, branch_2): south sidewalk 10 (y −4…0), roadway 11
  (y 0…12), north sidewalk 12 (y 12…16), marked crosswalk 13 (x −2…2 over the roadway). The head
  100 stands at (0, 14), governs roadway 11 (branch_2: lanes 20, y 0…6, and 21, y 6…12, only),
  15 m ahead of the pedestrian at the curb (0, −1): h·Δ = 15, cos²·|Δ|² ≈ 170, |Δ|² = 225 ≤ 1600.
  The pedestrian is at y = −1, 1, 3 at t = 0, 1, 2 s (permit: stays at y = −1).

  Divided crossing (branch_1, branch_3): south sidewalk 10 (y −4…0), roadway 11 (y 0…10;
  branch_3: lanes 20, y 0…5, and 21, y 5…10, which head 100 governs instead), median 14
  (y 10…14), roadway 15 (y 14…24), north sidewalk 12 (y 24…28), crosswalks 13 and 16. Head 100 at
  (0, 12) governs the first roadway, head 101 at (0, 26) the second. The pedestrian is at
  y = −1 + 2k at t = k s, k = 0…8: on roadway 11 from k = 1, on the median at k = 6, 7, on
  roadway 15 at k = 8. Both heads show walk for k ≤ 5 and dont_walk_flashing from k = 6.

  The rule reads the previous observation, so each witness speaks about the instants after the
  first (`window`). Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d3_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d3_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The pedestrian at (0, y), heading north. -/
def pedAt (y : Int) (speed : Int) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, m y) Build.north (Units.metresPerSecond speed) (cm 25, cm 25, cm 90)

/-- A pedestrian head with no countdown timer. -/
def head (id : DeviceId) (governs : List RegionId) (y : Int) (st : PedSignalState) : Device :=
  { Build.device id .pedestrianSignal governs (some (m 0, m y)) with
      pedState := some st, countdown := some false }

def crosswalk (id : RegionId) (y0 y1 : Int) : Structure :=
  { Build.rect id .crosswalk (m (-2)) (m y0) (m 2) (m y1) with marked := some true }

/-- One undivided crossing; `lanes` adds two lanes over the roadway. -/
def oneCrossing (lanes : Bool) : List Structure :=
  [ Build.rect 10 .sidewalk (m (-20)) (m (-4)) (m 20) (m 0)
  , Build.rect 11 .roadway (m (-20)) (m 0) (m 20) (m 12)
  , Build.rect 12 .sidewalk (m (-20)) (m 12) (m 20) (m 16)
  , crosswalk 13 0 12 ] ++
  (if lanes then
    [ Build.lane 20 [(m (-20), m 0), (m 20, m 0), (m 20, m 6), (m (-20), m 6)] Build.east
    , Build.lane 21 [(m (-20), m 6), (m 20, m 6), (m 20, m 12), (m (-20), m 12)] Build.west ]
  else [])

/-- One crossing: the pedestrian steps from the curb onto the roadway at t = 1 s (or waits). -/
def oneCrossingTrace (steps lanes : Bool) (st : PedSignalState) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y : Int := if steps then -1 + 2 * (Int.ofNat k) else -1
    Build.scene t (some 1)
      [ pedAt y (if steps then 2 else 0) ]
      (oneCrossing lanes)
      [ head 100 (if lanes then [20, 21] else [11]) 14 st ]

/-- The divided crossing; `lanes` puts the first head on two lanes of the first roadway. -/
def dividedCrossing (lanes : Bool) : List Structure :=
  [ Build.rect 10 .sidewalk (m (-20)) (m (-4)) (m 20) (m 0)
  , Build.rect 11 .roadway (m (-20)) (m 0) (m 20) (m 10)
  , Build.rect 14 .medianOrDivider (m (-20)) (m 10) (m 20) (m 14)
  , Build.rect 15 .roadway (m (-20)) (m 14) (m 20) (m 24)
  , Build.rect 12 .sidewalk (m (-20)) (m 24) (m 20) (m 28)
  , crosswalk 13 0 10
  , crosswalk 16 14 24 ] ++
  (if lanes then
    [ Build.lane 20 [(m (-20), m 0), (m 20, m 0), (m 20, m 5), (m (-20), m 5)] Build.east
    , Build.lane 21 [(m (-20), m 5), (m 20, m 5), (m 20, m 10), (m (-20), m 10)] Build.west ]
  else [])

def dividedCrossingTrace (lanes : Bool) : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    let st : PedSignalState := if k ≤ 5 then .walk else .dontWalkFlashing
    Build.scene t (some 1)
      [ pedAt (-1 + 2 * (Int.ofNat k)) 2 ]
      (dividedCrossing lanes)
      [ head 100 (if lanes then [20, 21] else [11]) 12 st
      , head 101 [15] 26 st ]

/-- `forbid` (violated): At the curb, the pedestrian faces a head 15 m away across roadway r that governs r and shows dont_walk_flashing without countdown; at the next observation its footprint overlaps r. -/
def forbidTrace : Trace := oneCrossingTrace true false .dontWalkFlashing

/-- `permit` (compliant): Same head and state; the pedestrian waits on the sidewalk and its footprint never overlaps r. -/
def permitTrace : Trace := oneCrossingTrace false false .dontWalkFlashing

/-- `idle` (not_applicable): The faced head shows walk. -/
def idleTrace : Trace := oneCrossingTrace true false .walk

/-- `blind` (unknown): The pedestrian steps onto r facing the head, but the head's state is not observed. -/
def blindTrace : Trace := oneCrossingTrace true false .dontWalkFlashing

/-- `branch_1` (not_applicable): The pedestrian stepped onto the first roadway from the sidewalk while the head governing it showed walk, reached the median, and now steps onto the second roadway r while its faced head shows dont_walk_flashing without countdown: it is continuing a lawful crossing. -/
def branch_1Trace : Trace := dividedCrossingTrace false

/-- `branch_2` (violated): as forbid, but the head governs the two lanes of the roadway, not the roadway: the lane limb of the selection. -/
def branch_2Trace : Trace := oneCrossingTrace true true .dontWalkFlashing

/-- `branch_3` (not_applicable): as branch_1, but the first head governs the lanes of the first roadway: the lawful entry is a step onto a lane. -/
def branch_3Trace : Trace := dividedCrossingTrace true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d3_o1"
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
  , witness "branch_1" branch_1Trace .notApplicable (window := some (1000, 8000))
  , witness "branch_2" branch_2Trace .violated (window := some (1000, 2000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (1000, 8000)) ]

end TrafficSpecWitness.NRS_484B_283_1d3_o1

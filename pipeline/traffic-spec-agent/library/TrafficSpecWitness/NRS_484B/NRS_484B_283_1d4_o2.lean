/-
  Witnesses for NRS_484B_283_1d4_o2.

  The carriageway: an east–west crossing region 100, 8 m deep (y from 0 to 8, x from −20 to 20),
  of kind roadway (or, in the `lane` variants, of kind lane); a sidewalk 200 south of it (y from −4
  to 0) and a sidewalk 201 north of it (y from 8 to 12). The pedestrian head 10 stands on the north
  sidewalk at (2, 10) and governs region 100. Region 100 carries its direction of travel (east),
  which the composed exception rules read. Where region 100 is a roadway, a marked crosswalk 300
  (x from −2 to 2, y from 0 to 8) lies across it and the pedestrian crosses within it.

  The pedestrian (track 1, class pedestrian, half-extent 25 × 25 × 90 cm) heads north along x = 0.
  Instants every second, five of them:
    k = 0  on the south sidewalk at y = −0.5, the head showing the entry indication;
    k = 1  on region 100 at y = 0.8 (the step off the sidewalk), the head still showing the entry
           indication; Δ to the head is (2, 9.2): h·Δ = 9.2 > 0, (h·Δ)² = 84.64 against
           0.87² · 88.64 ≈ 67.1, |Δ|² = 88.64 against 40² = 1600 — the pedestrian faces the head;
    k = 2  at y = 2.1, entry indication;
    k = 3, 4  the head shows dont_walk_steady; the pedestrian at y = 3.4 standing (0 m/s), or
           walking on to y = 4.7 at 1.3 m/s (reading floor 0.5 m/s).
  Occupancy is derived from the reference point. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def walkingSpeed : Q := Units.micrometresPerSecond 1300000
def standing : Q := Units.metresPerSecond 0

/-- The crossing region, of the kind the variant names. -/
def crossing (kind : StructureKind) : Structure :=
  { Build.rect 100 kind (m (-20)) (m 0) (m 20) (m 8) with
      lane := some { direction := some Build.east } }
/-- The marked crosswalk the pedestrian crosses the roadway in (x from −2 to 2). -/
def crosswalk : Structure :=
  { Build.rect 300 .crosswalk (m (-2)) (m 0) (m 2) (m 8) with marked := some true }
def southWalk : Structure := Build.rect 200 .sidewalk (m (-20)) (m (-4)) (m 20) (m 0)
def northWalk : Structure := Build.rect 201 .sidewalk (m (-20)) (m 8) (m 20) (m 12)
/-- The structures of a variant: the roadway carries the crosswalk. -/
def structures (kind : StructureKind) : List Structure :=
  if kind == .roadway then [crossing kind, crosswalk, southWalk, northWalk]
  else [crossing kind, southWalk, northWalk]

/-- The pedestrian head showing `st`, with or without a countdown displayed. -/
def head (st : PedSignalState) (countdown : Bool) : Device :=
  { Build.device 10 .pedestrianSignal [100] (some (m 2, m 10)) with
      pedState := some st, countdown := some countdown }

def pedestrian (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, y) Build.north speed (cm 25, cm 25, cm 90)

/-- The crossing: the pedestrian steps off the south sidewalk onto region 100 while the head shows
    `entry` (with `countdown`), then the head turns dont_walk_steady and the pedestrian moves at
    `after`. -/
def crossingTrace (kind : StructureKind) (entry : PedSignalState) (countdown : Bool) (after : Q) : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let (y, v, sig) : Q × Q × Device :=
      match k with
      | 0 => (cm (-50), walkingSpeed, head entry countdown)
      | 1 => (cm 80, walkingSpeed, head entry countdown)
      | 2 => (cm 210, walkingSpeed, head entry countdown)
      | 3 => (cm 340, after, head .dontWalkSteady false)
      | _ => (if after == standing then cm 340 else cm 470, after, head .dontWalkSteady false)
    Build.scene t (some 1)
      [ pedestrian y v ]
      (structures kind)
      [ sig ]

/-- `forbid` (violated): The pedestrian stepped onto r from the sidewalk facing d while d showed walk; d now shows dont_walk_steady and the pedestrian stands still (0.0 m/s) in the middle of r. -/
def forbidTrace : Trace := crossingTrace .roadway .walk false standing

/-- `permit` (compliant): Same, but the pedestrian walks on across r at 1.3 m/s. -/
def permitTrace : Trace := crossingTrace .roadway .walk false walkingSpeed

/-- `idle` (not_applicable): d shows dont_walk_steady and the pedestrian waits on the sidewalk, off r. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ pedestrian (cm (-100)) standing ]
      [ crossing .roadway, southWalk, northWalk ]
      [ head .dontWalkSteady false ]

/-- `blind` (unknown): Same as forbid but the pedestrian's speed is not observed. -/
def blindTrace : Trace := crossingTrace .roadway .walk false standing

/-- `history_boundary` (unknown): The recording begins with the pedestrian standing on r while d shows dont_walk_steady; its step onto r is not recorded, so whether it entered lawfully cannot be told. -/
def history_boundaryTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ pedestrian (cm 340) standing ]
      [ crossing .roadway, southWalk, northWalk ]
      [ head .dontWalkSteady false ]

/-- `branch_1` (violated): the pedestrian stepped onto the roadway facing d while d showed the
    flashing don't-walk indication with its countdown; d now shows dont_walk_steady and it stands still. -/
def branch1Trace : Trace := crossingTrace .roadway .dontWalkFlashing true standing

/-- `branch_2` (violated): as forbid, but the region crossed and governed by d is a lane. -/
def branch2Trace : Trace := crossingTrace .lane .walk false standing

/-- `branch_3` (violated): as branch_1 (flashing with countdown at entry), on a lane. -/
def branch3Trace : Trace := crossingTrace .lane .dontWalkFlashing true standing

/-- `branch_4` (not_applicable): the pedestrian stepped onto the roadway while d showed the
    flashing don't-walk indication with no countdown displayed: not a lawful entry under (1) or (2). -/
def branch4Trace : Trace := crossingTrace .roadway .dontWalkFlashing false standing

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d4_o2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the pedestrian's step from the sidewalk onto r, which lies before the recording")
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated
  , witness "branch_3" branch3Trace .violated
  , witness "branch_4" branch4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_283_1d4_o2

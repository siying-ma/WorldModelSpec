/-
  Witnesses for NRS_484B_267_1b_o1.

  Geometry (the witness's own figures; none appears in the rule). A straight eastbound highway
  (region 10, x 0..400, y -4..12) carries a right lane (11, y 0..4) and a left lane (12, y 4..8),
  both directed east, a right road edge (13, y -0.2..0) and beyond it a paved shoulder (14,
  y -3..-0.2, directed east); every one of them lies on the highway. Bodies are 5 m by 2 m.

  The subject (track 1, a motor vehicle) drives east in the left lane at 10 m/s from x 170. The
  approaching road user (track 2) is an official vehicle of a regulatory agency (the
  authorized-emergency-vehicle aggregate leaves every vehicle class unresolved in the reading, so a
  witness decides the u2/u3 alternative through u3); its red flashing lamp is lit from the second
  observation (t = 1 s), so the trigger rises there: it moves (2 m/s from x 120 by default), the
  subject 58 m ahead of it in its frame, within the 100 m reach. Thirteen observations at 1 s cover
  the 10 s window ahead of the rise.

  Pull-over scenes: the subject is at x 170, 180, 190 in the left lane for t = 0, 1, 2 s and then
  stands at its end position from t = 3 s. At the right edge (y 1.5) its body is 0.5 m from the
  edge (within the 1 m gap) with the edge 1.5 m to its right; in the left lane (y 6) it is 5 m off.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1b_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_1b_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 250, m 1, cm 75)

def highwayId : RegionId := 10
def laneR : RegionId := 11
def laneL : RegionId := 12
def edgeId : RegionId := 13
def shoulderId : RegionId := 14
def intersectionId : RegionId := 15

def highway : Structure := Build.rect highwayId .highway (m 0) (m (-4)) (m 400) (m 12)
def rightLane : Structure :=
  { Build.lane laneR [(m 0, m 0), (m 400, m 0), (m 400, m 4), (m 0, m 4)] Build.east (some laneL) none
      with ways := some [highwayId] }
def leftLane : Structure :=
  { Build.lane laneL [(m 0, m 4), (m 400, m 4), (m 400, m 8), (m 0, m 8)] Build.east none (some laneR)
      with ways := some [highwayId] }
def roadEdge : Structure :=
  { Build.rect edgeId .roadEdge (m 0) (cm (-20)) (m 400) (m 0) with paved := some true, ways := some [highwayId] }
def shoulder : Structure :=
  { Build.rect shoulderId .shoulder (m 0) (m (-3)) (m 400) (cm (-20))
      with paved := some true, ways := some [highwayId], lane := some { direction := some Build.east } }
/-- An intersection spanning the highway at x 195..220. -/
def intersection : Structure :=
  { Build.rect intersectionId .intersection (m 195) (m (-4)) (m 220) (m 12) with ways := some [highwayId] }

def baseStructures : List Structure := [highway, rightLane, leftLane, roadEdge, shoulder]

def redFlashingFront : WarningLamp := { colour := .red, mode := .flashing, facing := .front }

def subjectAt (p : Vec) (v : Q) (h : Vec := Build.east) : RoadUser :=
  Build.user 1 [.motorVehicle] p h v body

/-- The regulatory-agency vehicle, its red flashing lamp lit or not. -/
def regulator (p : Vec) (v : Q) (lit : Bool) : RoadUser :=
  Build.withSignals
    { Build.user 2 [.officialVehicle] p Build.east v body with officialKind := some .regulatoryAgency }
    (fun s => { s with warningLamps := some (if lit then [redFlashingFront] else []) })

/-- The subject staying in the left lane at 10 m/s. -/
def subjectInLeftLane (k : Nat) : RoadUser := subjectAt (m (170 + 10 * (k : Int)), m 6) (m 10)

/-- The subject pulling over: left lane until t = 2 s, then standing at `stop` from t = 3 s. -/
def subjectPullingOver (stop : Vec) (k : Nat) (h : Vec := Build.east) : RoadUser :=
  if k < 3 then subjectInLeftLane k else subjectAt stop (m 0) h

/-- The default approaching vehicle: left lane, standing at x 120 at t = 0, then moving at 2 m/s
    (x 121 at t = 1 s), lamp lit from t = 1 s. -/
def slowRegulator (k : Nat) (lit : Bool := true) : RoadUser :=
  if k = 0 then regulator (m 120, m 6) (m 0) false
  else regulator (m (119 + 2 * (k : Int)), m 6) (m 2) lit

def sceneOf (t : Timestamp) (users : List RoadUser) (structures : List Structure := baseStructures)
    (devices : List Device := []) (extraOcc : List (TrackId × RegionId) := []) : Scene :=
  Build.scene t (some 1) users structures devices
    (some (Build.occupancyFromGeometry users structures ++ extraOcc))

def n : Nat := 13

/-- `forbid` (violated): The trigger rises: ambulance e with a lit red flashing front lamp comes within p.emergency_immediate_approach_reach behind the moving subject. Over the next p.emergency_pullover_window the subject stays in the left lane, far from any road_edge region, and e does not pass it. -/
def forbidTrace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, slowRegulator k]

/-- `permit` (compliant): At the trigger's rise the subject moves right and, within p.emergency_pullover_window, its body is within p.pullover_edge_gap of the right road_edge (prim.region_lateral_offset negative), heading parallel to its lane's direction within p.curb_parallel_cos, overlapping no intersection and no signed shoulder. -/
def permitTrace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectPullingOver (m 200, cm 150) k, slowRegulator k]

/-- `idle` (not_applicable): e approaches with its warning lamps off: the trigger never rises. -/
def idleTrace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, slowRegulator k false]

/-- `blind` (unknown): As forbid, but sig.warning_lamp is not observed, so whether the trigger rose is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): Within the window the subject reaches the right edge, parallel, but its footprint overlaps an intersection region at every such observation, and e has not passed. -/
def branch_1Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectPullingOver (m 205, cm 150) k, slowRegulator k] (baseStructures ++ [intersection])

/-- `branch_2` (compliant): e overtakes and passes the subject (the subject behind e, no longitudinal overlap) before the subject reaches the edge, within p.emergency_pullover_window. -/
def branch_2Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, regulator (m (120 + 30 * (k : Int)), cm 150) (m 30) (k ≥ 1)]

/-- `branch_3` (violated): Within the window the subject moves onto a paved shoulder governed by a shoulder_use_permitted regulatory sign and stays there; it is never at the roadway edge off that shoulder, and e has not passed. -/
def shoulderSign : Device :=
  { Build.sign 20 .regulatorySign [shoulderId] with code := some .shoulderUsePermitted, conditions := some {} }
def branch_3Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectPullingOver (m 200, cm (-160)) k, slowRegulator k] baseStructures [shoulderSign]

/-- `branch_4` (compliant): the subject pulls onto the unsigned paved shoulder beyond the edge (the edge then on its left) and stands there, parallel. -/
def branch_4Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectPullingOver (m 200, cm (-160)) k, slowRegulator k]

/-- `branch_5` (violated): the subject stops near the right edge but skewed about 27 degrees to its lanes (heading (2,1)), its body across both lanes. -/
def branch_5Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectPullingOver (m 200, cm 250) k (m 2, m 1), slowRegulator k] baseStructures []
      (if k < 3 then [] else [(1, laneL)])

/-- `branch_6` (violated): e comes alongside the subject (its reference point 1 m ahead, the bodies side by side) and stays there; the subject keeps the left lane. -/
def branch_6Regulator (k : Nat) : RoadUser :=
  if k < 3 then regulator (m (110 + 25 * (k : Int)), cm 150) (m 25) (k ≥ 1)
  else regulator (m (171 + 10 * (k : Int)), cm 150) (m 10) true
def branch_6Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, branch_6Regulator k]

/-- `branch_7` (not_applicable): as forbid, but a police officer directing traffic governs the left lane the subject occupies. -/
def officer : Device :=
  { Build.device 21 .humanDirection [laneL] with humanRole := some .policeOfficer }
def branch_7Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, slowRegulator k] baseStructures [officer]

/-- `branch_8` (not_applicable): e lights its lamp beyond the immediate-approach reach (138 m) and stays beyond it. -/
def branch_8Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, regulator (m (40 + 2 * (k : Int)), m 6) (m 2) (k ≥ 1)]

/-- `branch_9` (not_applicable): e stands still behind the subject with its lamp lit. -/
def branch_9Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, regulator (m 122, m 6) (m 0) (k ≥ 1)]

/-- `branch_10` (not_applicable): e is ahead of the subject (the subject behind it in its frame), within reach, lamp lit. -/
def branch_10Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, regulator (m (250 + 5 * (k : Int)), m 6) (m 5) (k ≥ 1)]

/-- `branch_11` (not_applicable): a cyclist (no vehicle, so neither an authorized emergency vehicle nor an official vehicle) with a red flashing lamp closes on the subject from behind, within reach. -/
def cyclist (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.withSignals (Build.user track [.bicycle] (m (x0 + 6 * (k : Int)), cm 150) Build.east (m 6) (cm 90, cm 30, cm 90))
    (fun s => { s with warningLamps := some (if k ≥ 1 then [redFlashingFront] else []) })
def branch_11Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, cyclist 2 120 k]

/-- `branch_12` (compliant): as branch_2 (the regulator passes the subject, which keeps its lane), while a cyclist with a red flashing lamp closes from behind and never passes: the cyclist's approach puts no duty on the subject. -/
def branch_12Trace : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    sceneOf t [subjectInLeftLane k, regulator (m (120 + 30 * (k : Int)), cm 150) (m 30) (k ≥ 1), cyclist 3 100 k]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_1b_o1"
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
  , witness "blind" blindTrace (.unknown []) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_1b_o1

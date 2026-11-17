/-
  Witnesses for NRS_484B_307_8d.

  Geometry (metres, +x east, +y north), the same in every witness:
    intersection i (10): x ∈ [-10, 10], y ∈ [0, 20].
    approach c (11): lane x ∈ [0, 4], y ∈ [-50, 0], direction north, entering i — the rider's.
    cross approach (12): lane x ∈ [-50, -10], y ∈ [12, 16], direction east, entering i.
    far approach (13): lane x ∈ [-4, 0], y ∈ [24, 70], direction south, entering i.
    far crosswalk (22): x ∈ [-10, 10], y ∈ [20, 24], recorded as marking the far approach's entrance.
    stop line (20): x ∈ [0, 4], y ∈ [-3, -2.5], recorded as marking c's entrance (most witnesses);
    near crosswalk (21): x ∈ [-10, 10], y ∈ [-4, -1], marking c's entrance (branch_7 only, no line);
    branch_8 has neither, so the place is the edge of i.
    head s (100) governs c; head g (101) governs the cross approach.

  Instants: one scene every 50 ms (the step bound of the turn concepts), k = 0, 1, ….
    k = 0: the rider approaches on c at 2 m/s; s shows circular_green, then circular_red alone.
    k = 1 … 10: the rider is at rest at its halt point (1 m short of the mark: centre y = -5 for the
      line, half-length 1 m). g shows circular_green at k = 3, 4 and again from k = 7: two rising
      green indications during the wait (idle: only at k = 3, 4).
    k = 11: the rider moves off at 5 m/s, still on c and outside i.
    k = 12: the rider's body overlaps i (entry); k ≥ 13 inside i (or turning out of it).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8d
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8d

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def rI : RegionId := 10
def rC : RegionId := 11
def rCross : RegionId := 12
def rFar : RegionId := 13
def rLine : RegionId := 20
def rNearWalk : RegionId := 21
def rFarWalk : RegionId := 22
def dS : DeviceId := 100
def dG : DeviceId := 101
def dSign : DeviceId := 102

def intersection : Structure := Build.rect rI .intersection (m (-10)) (m 0) (m 10) (m 20)
def approach : Structure :=
  Build.lane rC [(m 0, m (-50)), (m 4, m (-50)), (m 4, m 0), (m 0, m 0)] Build.north (enters := some rI)
def crossApproach : Structure :=
  Build.lane rCross [(m (-50), m 12), (m (-10), m 12), (m (-10), m 16), (m (-50), m 16)] Build.east (enters := some rI)
def farApproach : Structure :=
  Build.lane rFar [(m (-4), m 24), (m 0, m 24), (m 0, m 70), (m (-4), m 70)] Build.south (enters := some rI)
def stopLine : Structure :=
  { Build.rect rLine .stopLine (m 0) (cm (-300)) (m 4) (cm (-250)) with
    entranceOf := [rC], entranceObserved := true }
def nearWalk : Structure :=
  { Build.rect rNearWalk .crosswalk (m (-10)) (m (-4)) (m 10) (m (-1)) with
    entranceOf := [rC], entranceObserved := true, marked := some true }
def farWalk : Structure :=
  { Build.rect rFarWalk .crosswalk (m (-10)) (m 20) (m 10) (m 24) with
    entranceOf := [rFar], entranceObserved := true, marked := some true }
def rFarLine : RegionId := 23
/-- The far approach's own stop line (branch_7, branch_8): a stop line that does not mark c. -/
def farLine : Structure :=
  { Build.rect rFarLine .stopLine (m (-4)) (m 26) (m 0) (cm 2650) with
    entranceOf := [rFar], entranceObserved := true }

/-- One subject observation from k = 12 on: position, heading, speed, yaw rate, regions occupied. -/
abbrev Step := Vec × Vec × Q × Q × List RegionId

structure Cfg where
  subjectClasses : List RoadUserClass := [.moped]
  subjectExtent : Q × Q × Q := (m 1, cm 40, cm 60)
  /-- 0: stop line marks c; 1: near crosswalk marks c; 2: no mark. -/
  marks : Nat := 0
  /-- Extra structures (the far approach's stop line). -/
  extra : List Structure := []
  haltY : Q := m (-5)
  rollY : Q := m (-3)
  rollOcc : List RegionId := [rC, rLine]
  crossGreen : Nat → Bool := fun k => k == 3 || k == 4 || decide (7 ≤ k)
  tail : List Step
  others : Nat → List (RoadUser × List RegionId) := fun _ => []
  signs : List Device := []
  governsObserved : Bool := true

def v5 : Q := Units.metresPerSecond 5

/-- Straight through: entry at k = 12, inside i at k = 13, 14. -/
def straightTail : List Step :=
  [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
    ((m 2, m 14), Build.north, v5, Q.zero, [rI]),
    ((m 2, m 18), Build.north, v5, Q.zero, [rI]) ]

def subjectAt (cfg : Cfg) (k : Nat) : RoadUser × List RegionId :=
  let mk (pos : Vec) (h : Vec) (v : Q) (yaw : Q) : RoadUser :=
    Build.withKin (Build.user 1 cfg.subjectClasses pos h v cfg.subjectExtent) fun kn => { kn with yawRate := some yaw }
  if k == 0 then (mk (m 2, Q.sub cfg.haltY (m 3)) Build.north (Units.metresPerSecond 2) Q.zero, [rC])
  else if k ≤ 10 then (mk (m 2, cfg.haltY) Build.north Q.zero Q.zero, [rC])
  else if k == 11 then (mk (m 2, cfg.rollY) Build.north v5 Q.zero, cfg.rollOcc)
  else match cfg.tail[k - 12]? with
    | some (pos, h, v, yaw, occ) => (mk pos h v yaw, occ)
    | none => (mk (m 2, m 18) Build.north v5 Q.zero, [rI])

def structuresOf (cfg : Cfg) : List Structure :=
  [intersection, approach, crossApproach, farApproach, farWalk] ++
    (if cfg.marks == 0 then [stopLine] else if cfg.marks == 1 then [nearWalk] else []) ++ cfg.extra

def head (cfg : Cfg) (id : DeviceId) (gov : List RegionId) (shows : List SignalIndication) : Device :=
  { Build.signal id gov shows with
    governs := if cfg.governsObserved then gov else []
    governsObserved := cfg.governsObserved }

def devicesOf (cfg : Cfg) (k : Nat) : List Device :=
  [ head cfg dS [rC] (if k == 0 then [.circularGreen] else [.circularRed]),
    head cfg dG [rCross] (if cfg.crossGreen k then [.circularGreen] else [.circularRed]) ] ++ cfg.signs

def sceneOf (cfg : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  let (subj, subjOcc) := subjectAt cfg k
  let os := cfg.others k
  Build.scene t (some 1) (subj :: os.map (·.1)) (structuresOf cfg) (devicesOf cfg k)
    (occupies := some ((subjOcc.map fun r => (1, r)) ++ os.flatMap fun (u, rs) => rs.map fun r => (u.track, r)))

def traceOf (cfg : Cfg) : Trace :=
  Build.trace (12 + cfg.tail.length) 0 (Units.milliseconds 50) fun k t => sceneOf cfg k t

/-- A pedestrian walking west at 1.3 m/s. -/
def walker (pos : Vec) : RoadUser :=
  Build.user 2 [.pedestrian] pos Build.west (Units.micrometresPerSecond 1300000) (cm 30, cm 30, cm 90)

/-- The pedestrian in the far crosswalk: its centre's closest approach to the rider's at k = 13 is
    about 1.4 s ahead at about 0.2 m (rider (2, 14) north at 5 m/s, walker (4, 21) west). -/
def farWalker : Nat → List (RoadUser × List RegionId) := fun _ => [(walker (m 4, m 21), [rFarWalk])]

def forbidCfg : Cfg := { tail := straightTail, others := farWalker }

/-- `forbid` (violated): A moped halts 1 m short of the stop line marking lane c's entrance while head s displays circular_red alone; while it waits, the head governing the cross street's lane begins circular_green twice and s stays circular_red alone; no turn-prohibiting sign governs c or i. The moped enters i straight through at 5 m/s while a pedestrian walks at 1.3 m/s in the crosswalk marking the entrance of the far approach, the closest approach of their centres 1.0 s ahead at 0.6 m. -/
def forbidTrace : Trace := traceOf forbidCfg

/-- `permit` (compliant): Same wait and entry with no other road user in the scene: the duty binds the rider alone and is met. -/
def permitTrace : Trace := traceOf { tail := straightTail }

/-- `idle` (not_applicable): The moped halts at the line and enters i after the cross street's head has begun circular_green only once since its halt: the wait of two cycles is not met. -/
def idleTrace : Trace :=
  traceOf { forbidCfg with crossGreen := fun k => k == 3 || k == 4 }

/-- `blind` (unknown): As forbid, but the source does not observe which travel regions the heads govern: which head is the rider's and whether the cross head belongs to this intersection are unknown. -/
def blindTrace : Trace := traceOf { forbidCfg with governsObserved := false }

/-- `branch_1` (not_applicable): A passenger car (DEF-NRS-484A-320::vehicle, not of the classes of s4) waits two cycles at the line under circular_red alone and enters i. -/
def branch_1Trace : Trace :=
  traceOf { tail := straightTail, subjectClasses := [.motorVehicle], subjectExtent := (cm 230, cm 90, cm 75),
            haltY := cm (-650), rollY := cm (-350), rollOcc := [rC, rLine] }

/-- `branch_2` (not_applicable): As forbid, but the moped halted 15 m short of the line behind a queue and, when the queue cleared, rolled to the line and into i without halting at the place: the halt the requirement to stop names did not occur, and the paragraph does not apply. -/
def branch_2Trace : Trace := traceOf { forbidCfg with haltY := m (-19) }

/-- A heading as a unit vector given to five decimals. -/
def dir (x y : Int) : Vec := (Units.ratio x 100000, Units.ratio y 100000)

/-- Right turn out of i: the yaw rate -425°/s is held over each 50 ms interval after the entry
    (k = 13 … 16), so the heading turns by -21.25° per scene, from north (90°) at the entry
    (k = 12) through 68.75°, 47.5°, 26.25° to 5° at the exit (k = 16): -85° in all. -/
def rightTail : List Step :=
  [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
    ((m 3, m 4), dir 36244 93201, v5, Units.degrees (-425), [rI]),
    ((m 6, m 6), dir 67559 73728, v5, Units.degrees (-425), [rI]),
    ((m 9, m 6), dir 89687 44229, v5, Units.degrees (-425), [rI]),
    ((m 13, m 6), dir 99619 8716, v5, Units.degrees (-425), []) ]

/-- Left turn out of i: +425°/s over k = 13 … 16, from north through 111.25°, 132.5°, 153.75° to
    175° at the exit: +85° in all. -/
def leftTail : List Step :=
  [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
    ((m 1, m 4), dir (-36244) 93201, v5, Units.degrees 425, [rI]),
    ((m (-2), m 6), dir (-67559) 73728, v5, Units.degrees 425, [rI]),
    ((m (-6), m 6), dir (-89687) 44229, v5, Units.degrees 425, [rI]),
    ((m (-13), m 6), dir (-99619) 8716, v5, Units.degrees 425, []) ]

def turnSign (gov : List RegionId) (code : SignCode) : Device :=
  { Build.sign dSign .regulatorySign gov with code := some code, conditions := some {} }

/-- `branch_3` (not_applicable): As forbid, but a regulatory sign coded no_right_turn governs lane c and the moped's passage through i is recognized at its exit as a right turn (heading change -85 degrees): a device at the place prohibits the turn it made, and the permission with its yield does not arise. -/
def branch_3Trace : Trace :=
  traceOf { forbidCfg with tail := rightTail, signs := [turnSign [rC] .noRightTurn] }

-- branch_4 (violated): as forbid without the pedestrian; a car on the cross approach, its head g
-- showing circular_green, comes on at 10 m/s: centres' closest approach about 1.5 s ahead at
-- about 0.9 m (rider (2, 8) north at 5 m/s, car (-13, 14.5) east).
def branch_4Trace : Trace :=
  traceOf { tail := [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
                      ((m 2, m 8), Build.north, v5, Q.zero, [rI]),
                      ((m 2, m 12), Build.north, v5, Q.zero, [rI]) ]
            others := fun k =>
              if k == 13 then
                [(Build.user 2 [.motorVehicle] (m (-13), cm 1450) Build.east (Units.metresPerSecond 10) (cm 230, cm 90, cm 75),
                  [rCross])]
              else [] }

-- branch_5 (violated): as forbid, but the pedestrian walks inside i, in no crosswalk (4, 18).
def branch_5Trace : Trace :=
  traceOf { tail := straightTail, others := fun _ => [(walker (m 4, m 18), [rI])] }

-- branch_6 (violated): the rider enters i and comes to rest at (2, 8); a pedestrian walking west
-- inside i at (2.6, 8) is in contact with its body (no conflict by closest approach: the rider is
-- at rest).
def branch_6Trace : Trace :=
  traceOf { tail := [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
                      ((m 2, m 8), Build.north, Q.zero, Q.zero, [rI]),
                      ((m 2, m 8), Build.north, Q.zero, Q.zero, [rI]) ]
            others := fun k => if 13 ≤ k then [(walker (cm 260, m 8), [rI])] else [] }

-- branch_7 (violated): as forbid, but no stop line marks c (the far approach has its own); the
-- near crosswalk marks c's entrance and the moped halts 1 m short of it (centre y = -6).
def branch_7Trace : Trace :=
  traceOf { forbidCfg with marks := 1, extra := [farLine], haltY := m (-6), rollOcc := [rC, rNearWalk] }

-- branch_8 (violated): as forbid, but neither a stop line nor a crosswalk marks c's entrance (the
-- far approach has its own stop line); the moped halts 1 m short of the intersection's edge
-- (centre y = -2).
def branch_8Trace : Trace :=
  traceOf { forbidCfg with marks := 2, extra := [farLine], haltY := m (-2), rollY := cm (-150), rollOcc := [rC] }

-- branch_9 (not_applicable): as forbid, but a regulatory sign coded no_left_turn governs i and the
-- passage is recognized at its exit as a left turn (+85 degrees).
def branch_9Trace : Trace :=
  traceOf { forbidCfg with tail := leftTail, signs := [turnSign [rI] .noLeftTurn] }

/-- A pedestrian walking west inside i at (9, 9), in the path of the rider's right turn: at k = 14
    (rider (6, 6), heading 47.5°, 5 m/s) the centres' closest approach is about 0.7 s ahead at
    about 0.5 m. -/
def turnWalker : Nat → List (RoadUser × List RegionId) := fun _ => [(walker (m 9, m 9), [rI])]

-- branch_10 (violated): a no_right_turn sign governs the cross approach only (neither c nor i);
-- the rider turns right, which no device at its place prohibits, and comes on the pedestrian.
def branch_10Trace : Trace :=
  traceOf { forbidCfg with tail := rightTail, signs := [turnSign [rCross] .noRightTurn], others := turnWalker }

-- branch_11 (violated): a no_left_turn sign governs c; the rider turns right, which the sign does
-- not prohibit, and comes on the pedestrian.
def branch_11Trace : Trace :=
  traceOf { forbidCfg with tail := rightTail, signs := [turnSign [rC] .noLeftTurn], others := turnWalker }

/-- Straight through and out of i at k = 16 (into the far crosswalk). -/
def straightExitTail : List Step :=
  [ ((m 2, cm 50), Build.north, v5, Q.zero, [rC, rI]),
    ((m 2, m 6), Build.north, v5, Q.zero, [rI]),
    ((m 2, m 12), Build.north, v5, Q.zero, [rI]),
    ((m 2, m 18), Build.north, v5, Q.zero, [rI]),
    ((m 2, m 22), Build.north, v5, Q.zero, [rFarWalk]) ]

-- branch_12 (violated): a no_right_turn sign governs i; the rider goes straight through (exit
-- recorded at k = 16), which the sign does not prohibit, and comes on the pedestrian in the far
-- crosswalk (at k = 14, rider (2, 12): closest approach about 1.8 s ahead at about 0.3 m).
def branch_12Trace : Trace :=
  traceOf { forbidCfg with tail := straightExitTail, signs := [turnSign [rI] .noRightTurn] }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8d"
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
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_8d

/-
  Witnesses for NRS_484B_257_1_o2.

  A four-way junction: highway h1 (region 1) runs north–south over x ∈ [-10, 10], highway h2
  (region 2) east–west over y ∈ [-10, 10]; their intersection i (region 3) is the square
  [-10, 10]². x's approach c (region 4) is the northbound lane x ∈ [0, 4], y ∈ [-60, -10] on h1,
  entering i; upstream of it lane u (region 5), y ∈ [-120, -60], leads into c. The crossing
  approach c2 (region 6) is the eastbound lane x ∈ [-150, -10], y ∈ [-4, 0] on h2, entering i. A
  stop line (region 7), y ∈ [-11, -10] across c, marks c's entrance.

  Instants k = 0 … 7, one second apart. x (track 1, a motor vehicle, half-extents 2 × 1 × 1 m)
  drives north from u through c, halts with its front on the stop line (centre y = -12.5) at
  k = 4 … 6, and at k = 7 its front crosses into i (centre y = -9): its entry into i, while its
  body still overlaps c and the stop line. In `branch_2` it keeps 10 m/s throughout and enters i
  at k = 7 without halting.

  y (track 2, a motor vehicle, same extents) is on c2 heading east. In `forbid`, `blind` and the
  device branches it keeps 15 m/s, its front 25 m from i at k = 7: within 15 × 4.1 = 61.5 m. In
  `branch_1` it moves at 5 m/s, enters i at k = 6 from c2 and occupies i at k = 7.

  Occupancy is stated per instant from the footprints. Every figure here is the witness's own and
  appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def body : Q × Q × Q := (m 2, m 1, m 1)

def h1 : Structure := Build.rect 1 .highway (m (-10)) (m (-130)) (m 10) (m 130)
def h2 : Structure := Build.rect 2 .highway (m (-160)) (m (-10)) (m 160) (m 10)
def junction : Structure := { Build.rect 3 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [1, 2] }
def approach : Structure :=
  { Build.lane 4 [(m 0, m (-60)), (m 4, m (-60)), (m 4, m (-10)), (m 0, m (-10))] Build.north
      (enters := some 3) with ways := some [1] }
def upstream : Structure :=
  { Build.lane 5 [(m 0, m (-120)), (m 4, m (-120)), (m 4, m (-60)), (m 0, m (-60))] Build.north
      (leadsTo := some [4]) with ways := some [1] }
def crossing : Structure :=
  { Build.lane 6 [(m (-150), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-150), m 0)] Build.east
      (enters := some 3) with ways := some [2] }
def stopLine : Structure :=
  { Build.rect 7 .stopLine (m 0) (m (-11)) (m 4) (m (-10)) with
      ways := some [1], entranceOf := [4], entranceObserved := true }

def structures : List Structure := [h1, h2, junction, approach, upstream, crossing, stopLine]

def stopSign : Device := Build.sign 1 .stopSign [4]

/-- x halting at the stop line: centre y (cm), speed (m/s), regions occupied, at instant k. -/
def xHalting (k : Nat) : Q × Q × List RegionId :=
  match k with
  | 0 => (cm (-7500), m 25, [5, 1])
  | 1 => (cm (-5000), m 20, [4, 1])
  | 2 => (cm (-3200), m 15, [4, 1])
  | 3 => (cm (-1900), m 7, [4, 1])
  | 4 | 5 | 6 => (cm (-1250), m 0, [4, 7, 1])
  | _ => (cm (-900), m 3, [4, 7, 3, 1, 2])

/-- x never halting: 10 m/s throughout, centre y = -79 + 10 k. -/
def xRolling (k : Nat) : Q × Q × List RegionId :=
  let yc := m (-79 + 10 * Int.ofNat k)
  let regs : List RegionId :=
    match k with
    | 0 | 1 => [5, 1]
    | 2 => [5, 4, 1]
    | 3 | 4 | 5 | 6 => [4, 1]
    | _ => [4, 7, 3, 1, 2]
  (yc, m 10, regs)

def xUser (st : Q × Q × List RegionId) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 2, st.1) Build.north st.2.1 body

/-- y approaching on c2 at 15 m/s, its front 25 m from i at k = 7. -/
def yFast (k : Nat) : RoadUser × List RegionId :=
  (Build.user 2 [.motorVehicle] (m (-37 - 15 * (7 - Int.ofNat k)), m (-2)) Build.east (m 15) body, [6, 2])

/-- y crossing at 5 m/s: enters i from c2 at k = 6. -/
def ySlow (k : Nat) : RoadUser × List RegionId :=
  let regs : List RegionId :=
    match k with
    | 6 => [6, 3, 1, 2]
    | 7 => [3, 1, 2]
    | _ => [6, 2]
  (Build.user 2 [.motorVehicle] (m (-16 + 5 * (Int.ofNat k - 5)), m (-2)) Build.east (m 5) body, regs)

/-- A scene with x and, optionally, y, under the given devices. -/
def sceneWith (t : Timestamp) (xs : Q × Q × List RegionId) (y : Option (RoadUser × List RegionId))
    (devices : List Device) : Scene :=
  let xOcc := xs.2.2.map fun r => ((1 : TrackId), r)
  match y with
  | some (u, regs) =>
    Build.scene t (some 1) [xUser xs, u] structures devices
      (occupies := some (xOcc ++ regs.map fun r => ((2 : TrackId), r)))
  | none => Build.scene t (some 1) [xUser xs] structures devices (occupies := some xOcc)

def traceWith (x : Nat → Q × Q × List RegionId) (y : Nat → Option (RoadUser × List RegionId))
    (devices : List Device) : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t => sceneWith t (x k) (y k) devices

/-- `forbid` (violated): dev.stop_sign governs c; x halts at the stop line marking c, then enters i while vehicle y on approach carrier c2 of the crossing highway h2 is 25 m from i at 15 m/s. -/
def forbidTrace : Trace := traceWith xHalting (fun k => some (yFast k)) [stopSign]

/-- `permit` (compliant): As forbid, but x enters i as the only road user in the scene. -/
def permitTrace : Trace := traceWith xHalting (fun _ => none) [stopSign]

/-- `idle` (not_applicable): No sign governs c or i; x enters i. -/
def idleTrace : Trace := traceWith xHalting (fun k => some (yFast k)) []

/-- `blind` (unknown): As forbid, but kin.speed is not observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): x halts at its stop line and enters i while vehicle y, whose entry into i through c2 on h2 is recorded, occupies i. -/
def branch_1Trace : Trace := traceWith xHalting (fun k => some (ySlow k)) [stopSign]

/-- `branch_2` (not_applicable): As forbid, but x never halted or slowed on the approach (NRS_484B_257_1_o1 not complied with): this duty does not arise. -/
def branch_2Trace : Trace := traceWith xRolling (fun k => some (yFast k)) [stopSign]

/-- `branch_3` (not_applicable): as forbid, but a police officer directs traffic at i. -/
def branch_3Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [stopSign, { Build.device 2 .humanDirection [3] with humanRole := some .policeOfficer, humanIndication := some .proceed }]

/-- `branch_4` (not_applicable): as forbid, but an operating traffic signal governs c. -/
def branch_4Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [stopSign, { Build.signal 3 [4] [.circularGreen] with uncovered := some true, inoperative := some false }]

/-- `branch_5` (violated): as branch_4, but the signal is inoperative: the stop sign controls. -/
def branch_5Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [stopSign, { Build.signal 3 [4] [.dark] with uncovered := some true, inoperative := some true }]

/-- `branch_6` (violated): as forbid, but a yield sign governing i, not a stop sign, is the sign. -/
def branch_6Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k)) [Build.sign 4 .yieldSign [3]]

/-- `branch_7` (violated): as forbid, but the stop sign governs i, not c. -/
def branch_7Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k)) [Build.sign 1 .stopSign [3]]

/-- `branch_8` (violated): as forbid, but a yield sign governing c is the sign. -/
def branch_8Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k)) [Build.sign 4 .yieldSign [4]]

/-- `branch_9` (not_applicable): as forbid, but a police officer directs traffic on c. -/
def branch_9Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [stopSign, { Build.device 2 .humanDirection [4] with humanRole := some .policeOfficer, humanIndication := some .proceed }]

/-- `branch_10` (not_applicable): as forbid, but an operating traffic signal governs i. -/
def branch_10Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [stopSign, { Build.signal 3 [3] [.circularGreen] with uncovered := some true, inoperative := some false }]

/-- `branch_11` (violated): as forbid; a police officer and an operating signal control only the
    crossing approach c2, and a flagger, no police officer, directs at i: neither controls x. -/
def branch_11Trace : Trace :=
  traceWith xHalting (fun k => some (yFast k))
    [ stopSign
    , { Build.device 2 .humanDirection [6] with humanRole := some .policeOfficer, humanIndication := some .stop }
    , { Build.signal 3 [6] [.circularRed] with uncovered := some true, inoperative := some false }
    , { Build.device 5 .humanDirection [3] with humanRole := some .flagger, humanIndication := some .proceed } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_1_o2

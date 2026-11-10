/-
  Witnesses for NRS_484B_270_4.

  Geometry (world frame, metres): a bicycle lane b (region 1) from x = 0 to 100, y = 0 to 2,
  eastbound; beside it a general traffic lane g (region 2), y = 2 to 6; the intersection i
  (region 3) from x = 100 to 120, y = -10 to 20. Track 1 is a motor vehicle, half-length 2.5 m,
  half-width 1 m, driving east at 10 m/s (far above the speed tolerance), sampled each second.
  Occupancy is stated per scene. Each trace starts with x on g and ends with x off b (back on g, or
  wholly in i), so that its stretch on b is bounded on both sides inside the trace. At 4 s of
  forbid, its front (x + 2.5 = 100.5) has crossed x = 100 while its reference point is still on b,
  so it overlaps both.
  Every scene declares asm.vehicle_disabled, asm.performing_official_duties and asm.emergency
  false, and has no alley or driveway, so no exception of subsection 3 holds unless a scene adds
  one. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def bLane : RegionId := 1
def gLane : RegionId := 2
def iX : RegionId := 3

def structures : List Structure :=
  [ Build.rect bLane .bicycleLaneOrPath (m 0) (m 0) (m 100) (m 2)
  , Build.rect gLane .lane (m 0) (m 2) (m 100) (m 6)
  , Build.rect iX .intersection (m 100) (m (-10)) (m 120) (m 20) ]

def noExceptions : List (AsmId × Bool) :=
  [ ("asm.vehicle_disabled", false)
  , ("asm.performing_official_duties", false)
  , ("asm.emergency", false) ]

def car (x y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 10) (cm 250, cm 100, cm 75)

/-- One scene per step: x's reference point (x, y) and the regions its footprint overlaps. -/
def drive (steps : List (Int × Int × List RegionId)) (devices : List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let (px, py, rs) := steps.getD k (0, 0, [])
    Build.scene t (some 1)
      [ car (m px) (m py) ]
      structures
      devices
      (occupies := some (rs.map fun r => (1, r)))
      (assumptions := noExceptions)

/-- x moves from g into b, follows b, and its front crosses x = 100 into i while its rear is still
    on b (at 4 s), then is wholly in i. -/
def intoIntersectionOnB : List (Int × Int × List RegionId) :=
  [ (58, 4, [gLane]), (68, 2, [gLane, bLane]), (78, 1, [bLane]), (88, 1, [bLane])
  , (98, 1, [bLane, iX]), (108, 1, [iX]) ]

/-- `forbid` (violated): x drives in bicycle lane b up to intersection i and its footprint enters i while still on b; no exception holds and the trace declares asm.vehicle_disabled, asm.performing_official_duties and asm.emergency false. -/
def forbidTrace : Trace := drive intoIntersectionOnB []

/-- `permit` (compliant): x drives in b mid-block (no exception holds) and does not enter an intersection while in it. -/
def permitTrace : Trace :=
  drive [ (20, 4, [gLane]), (30, 2, [gLane, bLane]), (40, 1, [bLane]), (50, 1, [bLane])
        , (60, 2, [gLane, bLane]), (70, 4, [gLane]) ] []

/-- `idle` (not_applicable): x enters i from a general traffic lane, never on a bicycle lane or path. -/
def idleTrace : Trace :=
  drive [ (58, 4, [gLane]), (68, 4, [gLane]), (78, 4, [gLane]), (88, 4, [gLane])
        , (98, 4, [gLane, iX]), (108, 4, [iX]) ] []

/-- `blind` (unknown): As forbid, but rel.occupies is not observed, so neither the bicycle-lane occupancy nor the entry can be read. -/
def blindTrace : Trace := drive intoIntersectionOnB []

/-- A police officer standing at the end of b, governing it and directing x to proceed. -/
def officer : Device :=
  { Build.device 1 .humanDirection [bLane] (some (m 99, m (-1))) with
    humanRole := some .policeOfficer
    humanIndication := some .proceed }

/-- `branch_1` (not_applicable): As forbid, but a dev.human_direction with role police_officer governs b and directs x through it: subsection 3's exception (e) holds, so NRS_484B_270_3_o2 does not apply. -/
def branch_1Trace : Trace := drive intoIntersectionOnB [officer]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_4"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_270_4

/-
  Witnesses for NRS_484B_270_4.

  Geometry (the witness's own figures, nowhere in the rule): an eastbound street with a general
  lane g (region 2, y ∈ [2, 5]) and a bicycle lane b (region 1, y ∈ [0, 2]) along its right edge,
  both running from x = -120 to x = 0, where intersection i (region 3, x ∈ [0, 20],
  y ∈ [-10, 10]) begins; past it the street continues as lane e (region 4, x ∈ [20, 100]).
  x (track 1) is a motor vehicle, half-length 2.5 m, half-width 0.9 m, travelling east at
  10 m/s — fifty times the reading's motion tolerance — sampled at 1 s. It is first seen in g,
  so its entry into b is recorded, and the trace ends with x off b, so whether x keeps to b is
  decided at the end; the first and last scenes are repeated for 60 s so that no window of
  subsection 3's rule is truncated. Occupancy is stated: at the entering instant the body
  straddles b's end and i's edge. Every scene declares asm.vehicle_disabled,
  asm.performing_official_duties and asm.emergency false.
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
def iSect : RegionId := 3
def eLane : RegionId := 4

def structures : List Structure :=
  [ Build.rect bLane .bicycleLaneOrPath (m (-120)) (m 0) (m 0) (m 2)
  , Build.lane gLane [(m (-120), m 2), (m 0, m 2), (m 0, m 5), (m (-120), m 5)] Build.east
  , Build.rect iSect .intersection (m 0) (m (-10)) (m 20) (m 10)
  , Build.lane eLane [(m 20, m 0), (m 100, m 0), (m 100, m 5), (m 20, m 5)] Build.east ]

def assumptions : List (AsmId × Bool) :=
  [("asm.vehicle_disabled", false), ("asm.performing_official_duties", false), ("asm.emergency", false)]

def car (x y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, cm y) Build.east (Units.metresPerSecond 10) (cm 250, cm 90, cm 75)

/-- Scenes of x at the given (easting m, northing cm, regions occupied), 1 s apart, padded 60 s
    at both ends. -/
def drive (path : List (Int × Int × List RegionId)) (devices : List Device := []) : Trace :=
  Build.pad
    (Build.trace path.length 0 (Units.seconds 1) fun k t =>
      let (x, y, occ) := path.getD k (0, 0, [])
      Build.scene t (some 1)
        [ car x y ]
        structures
        devices
        (occupies := some (occ.map (fun r => (1, r))))
        (assumptions := assumptions))
    (Units.seconds 60) (Units.seconds 60) (Units.seconds 1)

/-- From g into b, along b to its end, into i while still on b, through i into e. -/
def throughFromBicycleLane : List (Int × Int × List RegionId) :=
  [ (-71, 350, [gLane]), (-61, 350, [gLane])
  , (-51, 100, [bLane]), (-41, 100, [bLane]), (-31, 100, [bLane]), (-21, 100, [bLane])
  , (-11, 100, [bLane]), (-1, 100, [bLane, iSect])
  , (9, 100, [iSect]), (19, 100, [iSect, eLane]), (29, 100, [eLane]), (39, 100, [eLane]) ]

/-- `forbid` (violated): x drives in bicycle lane b up to intersection i and its footprint enters i while still on b; no exception holds and the trace declares asm.vehicle_disabled, asm.performing_official_duties and asm.emergency false. -/
def forbidTrace : Trace := drive throughFromBicycleLane

/-- `permit` (compliant): x drives in b mid-block (no exception holds) and does not enter an intersection while in it. -/
def permitTrace : Trace :=
  drive
    [ (-111, 350, [gLane]), (-101, 350, [gLane])
    , (-91, 100, [bLane]), (-81, 100, [bLane]), (-71, 100, [bLane])
    , (-61, 350, [gLane]), (-51, 350, [gLane]) ]

/-- `idle` (not_applicable): x enters i from a general traffic lane, never on a bicycle lane or path. -/
def idleTrace : Trace :=
  drive
    [ (-31, 350, [gLane]), (-21, 350, [gLane]), (-11, 350, [gLane]), (-1, 350, [gLane, iSect])
    , (9, 350, [iSect]), (19, 350, [iSect, eLane]), (29, 350, [eLane]) ]

/-- `blind` (unknown): As forbid, but kin.speed is not observed, so whether x is driving (in motion) in the bicycle lane when it enters i cannot be read; occupancy stays observed, so subsection 3's rule remains decided. -/
def blindTrace : Trace := forbidTrace

/-- A police officer directing traffic on b, indicating x to proceed. -/
def officer : Device :=
  { Build.device 1 .humanDirection [bLane] (some (m (-5), m (-1))) with
    humanRole := some .policeOfficer
    humanIndication := some .proceed }

/-- `branch_1` (not_applicable): As forbid, but a dev.human_direction with role police_officer governs b and directs x through it: subsection 3's exception (e) holds, so NRS_484B_270_3_o2 does not apply. -/
def branch_1Trace : Trace := drive throughFromBicycleLane [officer]

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_270_4

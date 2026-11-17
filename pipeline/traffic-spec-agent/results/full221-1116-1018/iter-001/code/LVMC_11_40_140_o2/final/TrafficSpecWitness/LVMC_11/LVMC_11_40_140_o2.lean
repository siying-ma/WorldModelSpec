/-
  Witnesses for LVMC_11_40_140_o2.

  Geometry (x east, y north, metres; one scene per second):
    roadway   y ∈ [0, 10],  x ∈ [-50, 50]                      (region 10)
    sidewalk  y ∈ [10, 13]                                        (region 11)
    highway   y ∈ [0, 15]: roadway, sidewalk and a 2 m border to the property line at y = 15 (region 12)
    driveway / alley entrance x ∈ [-2, 2], y ∈ [13, 30]           (region 13)
    alley                      x ∈ [-3, 3], y ∈ [13, 30]           (region 14)
    beyond y = 15 and outside those regions: a building (no region).
  The subject (track 1) has half-extents 0.9 × 0.3 m and travels along x = 0; at y = 14 (driveway or
  alley inside the border) its outline is 0.1 m short of the sidewalk, at y = 12 and 10.5 it is on
  it, at y = 8.5 it is 0.6 m off it on the roadway. The pedestrian (track 2, half-extents 0.25 m)
  walks west along the sidewalk at 1.5 m/s. The district assumption holds in every scene.
  Against the reading (horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s):
    forbid  k = 3: bicycle (0, 12) southbound 2 m/s, pedestrian (3, 11.5): closest approach after
            0.88 s at 2.1 m — moving into a conflict.
    permit  the bicycle is at rest on the sidewalk (k = 3…6) while the pedestrian passes 0.45 m clear
            of its body at y = 10.4, and moves on (k = 7, 8) when the pedestrian is moving away
            (closest approach in the past).
    branch_2 k = 2: bicycle (0, 12) southbound 4 m/s, pedestrian (2, 11): 1.5 m after 0.38 s.
    branch_3 k = 2: bicycle (0, 12) northbound 4 m/s, pedestrian (2, 12.5): 1.7 m after 0.27 s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_140_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_140_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 10)
def sidewalk : Structure := Build.rect 11 .sidewalk (m (-50)) (m 10) (m 50) (m 13)
def highway : Structure := Build.rect 12 .highway (m (-50)) (m 0) (m 50) (m 15)
def driveway : Structure := Build.rect 13 .drivewayOrAlleyEntrance (m (-2)) (m 13) (m 2) (m 30)
def alley : Structure := Build.rect 14 .alley (m (-3)) (m 13) (m 3) (m 30)

def district : List (AsmId × Bool) := [("asm.business_or_residence_district", true)]

def riderExt : Q × Q × Q := (cm 90, cm 30, cm 60)
def pedExt : Q × Q × Q := (cm 25, cm 25, cm 90)
def walk : Q := Units.micrometresPerSecond 1500000

/-- The pedestrian, walking west along the sidewalk line `y` (cm), at `x0 − 1.5 k` m. -/
def pedestrian (x0 y : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (cm (x0 - 150 * Int.ofNat k), cm y) Build.west walk pedExt

/-- y (cm) of a rider coming south out of a driveway or alley: off the highway, in the border,
    on the sidewalk twice, then on the roadway. -/
def southYs : List Int := [1800, 1600, 1400, 1200, 1050, 850, 650]

/-- `forbid` (violated): In a declared business district a bicycle emerges from a driveway onto the sidewalk and keeps moving while a pedestrian walking along the sidewalk is on a course whose closest approach falls within the conflict horizon and the clearance. -/
def forbidTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, cm (southYs.getD k 0)) Build.south (Units.metresPerSecond 2) riderExt
      , pedestrian 750 1150 k ]
      [ roadway, sidewalk, highway, driveway ]
      [ ]
      (assumptions := district)

def permitYs : List Int := [1800, 1600, 1400, 1200, 1200, 1200, 1200, 1200, 1050, 850]
def permitSpeeds : List Int := [2, 2, 2, 0, 0, 0, 0, 2, 2, 2]

/-- `permit` (compliant): The same bicycle halts on the sidewalk area and waits while the pedestrian passes, then moves on once the closest approach no longer falls within the clearance. -/
def permitTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, cm (permitYs.getD k 0)) Build.south
          (Units.metresPerSecond (permitSpeeds.getD k 0)) riderExt
      , pedestrian 750 1040 k ]
      [ roadway, sidewalk, highway, driveway ]
      [ ]
      (assumptions := district)

/-- `idle` (not_applicable): The bicycle rides on the roadway past the driveway and never occupies the sidewalk. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (-6 + 3 * Int.ofNat k), m 5) Build.east (Units.metresPerSecond 3) riderExt
      , pedestrian 750 1150 k ]
      [ roadway, sidewalk, highway, driveway ]
      [ ]
      (assumptions := district)

/-- `blind` (unknown): A bicycle near a driveway with a pedestrian approaching, where the source does not observe which regions the bicycle occupies. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): An electric scooter emerges from an alley across the sidewalk with no pedestrian in the scene: the duty binds the subject alone and is met.
    The scooter is observed as an electric scooter and an electric bicycle (a seated device with an
    electric motor): the run's reading admits no class into DEF-LVMC-11-02-083::electric_scooter,
    so a scooter observed as nothing else leaves the class unknown (see task_result.md). -/
def branch_1Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.electricScooter, .electricBicycle] (m 0, cm (southYs.getD k 0)) Build.south
          (Units.metresPerSecond 2) riderExt ]
      [ roadway, sidewalk, highway, alley ]
      [ ]
      (assumptions := district)

/-- `branch_2` (violated): a bicycle emerges from a building (off the highway, no region) straight
    onto the sidewalk and rides on into a pedestrian's path. -/
def branch_2Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, cm ([2000, 1600, 1200, 800, 400].getD k 0)) Build.south
          (Units.metresPerSecond 4) riderExt
      , pedestrian 500 1100 k ]
      [ roadway, sidewalk, highway ]
      [ ]
      (assumptions := district)

/-- `branch_3` (violated): a bicycle comes off the roadway across the sidewalk into a building (off
    the highway, no region) while riding into a pedestrian's path on the sidewalk. -/
def branch_3Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, cm ([400, 800, 1200, 1600, 2000].getD k 0)) Build.north
          (Units.metresPerSecond 4) riderExt
      , pedestrian 500 1250 k ]
      [ roadway, sidewalk, highway ]
      [ ]
      (assumptions := district)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_40_140_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_140_o2

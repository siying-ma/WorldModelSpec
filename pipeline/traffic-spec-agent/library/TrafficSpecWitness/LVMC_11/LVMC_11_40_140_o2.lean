/-
  Witnesses for LVMC_11_40_140_o2.

  One street map for every scene (+x east, +y north, metres):
    10 roadway        x ∈ [-40, 40], y ∈ [0, 7]
    11 sidewalk       x ∈ [-40, 40], y ∈ [7, 10]   (property line at y = 10)
    12 highway        the public way: y ∈ [0, 12] for x ≤ 20 (a strip of right-of-way behind the
                      sidewalk), y ∈ [0, 10] for x ≥ 20 (building frontage on the property line)
    13 driveway D1    x ∈ [-2, 2],   y ∈ [10, 30]  (meets the sidewalk at the property line)
    14 driveway D2    x ∈ [8, 12],   y ∈ [8, 30]   (its apron runs across part of the sidewalk)
    15 alley A1       x ∈ [-24, -18], y ∈ [8, 30]  (runs across part of the sidewalk)
    16 alley A2       x ∈ [-36, -30], y ∈ [10, 30]
    Beyond the property line at x ≥ 20 no region is mapped: a building.
  Bodies: the subject (track 1) half-extent 0.9 × 0.3 m, 2 m/s while riding; a pedestrian
  (track 2) half-extent 0.3 × 0.3 m, walking 1.5 m/s along the sidewalk. Instants 1 s apart.
  Every scene declares asm.business_or_residence_district true, except `branch_6`.

  A conflict scene puts the pedestrian 3 m from the subject across its path at the entry: the
  centres then approach within 0.72 s to 2.4 m (horizon 3 s, clearance 3 m). The distance scene
  puts the pedestrian 6 m away: closest approach at 1.44 s, 4.8 m. Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_140_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_140_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def mapStructures : List Structure :=
  [ Build.rect 10 .roadway (m (-40)) (m 0) (m 40) (m 7)
  , Build.rect 11 .sidewalk (m (-40)) (m 7) (m 40) (m 10)
  , Build.region 12 .highway
      [(m (-40), m 0), (m 40, m 0), (m 40, m 10), (m 20, m 10), (m 20, m 12), (m (-40), m 12)]
  , Build.rect 13 .drivewayOrAlleyEntrance (m (-2)) (m 10) (m 2) (m 30)
  , Build.rect 14 .drivewayOrAlleyEntrance (m 8) (m 8) (m 12) (m 30)
  , Build.rect 15 .alley (m (-24)) (m 8) (m (-18)) (m 30)
  , Build.rect 16 .alley (m (-36)) (m 10) (m (-30)) (m 30) ]

/-- The subject at (x, y) cm, riding at `v` cm/s. -/
def subjectAt (cls : RoadUserClass) (x y : Int) (h : Vec) (v : Int) : RoadUser :=
  Build.user 1 [cls] (cm x, cm y) h (Units.micrometresPerSecond (v * 10000)) (cm 90, cm 30, cm 60)

/-- A pedestrian at (x, y) cm, walking at 1.5 m/s. -/
def pedAt (x y : Int) (h : Vec) : RoadUser :=
  Build.user 2 [.pedestrian] (cm x, cm y) h (Units.micrometresPerSecond 1500000) (cm 30, cm 30, cm 90)

/-- A pedestrian walking along the sidewalk line `y` from `x0`, 150 cm per instant in `h`. -/
def walker (x0 y : Int) (h : Vec) (dir : Int) (k : Nat) : List RoadUser :=
  [pedAt (x0 + dir * 150 * Int.ofNat k) y h]

/-- A trace of `n` instants: the subject at the listed positions (cm) and speeds (cm/s). -/
def ride (n : Nat) (cls : RoadUserClass) (h : Vec) (xs ys vs : List Int)
    (others : Nat → List RoadUser) (asmOn : Bool := true) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (subjectAt cls (xs.getD k 0) (ys.getD k 0) h (vs.getD k 0) :: others k)
      mapStructures []
      (assumptions := [("asm.business_or_residence_district", asmOn)])

/-- `forbid` (violated): In a declared business district a bicycle emerges from a driveway onto the sidewalk and keeps moving while a pedestrian walking along the sidewalk is on a course whose closest approach falls within the conflict horizon and the clearance. -/
-- Driveway D1 (inside the right-of-way strip at the instant before the entry): the bicycle is in
-- D1 at instants 0–1, on the sidewalk at 2 (the entry, moving 2 m/s, pedestrian 3 m west on
-- the sidewalk walking east), on the roadway at 3.
def forbidTrace : Trace :=
  ride 4 .bicycle Build.south [0, 0, 0, 0] [1250, 1050, 850, 650] [200, 200, 200, 200]
    (walker (-600) 850 Build.east 1)

/-- `permit` (compliant): The same bicycle halts on the sidewalk area and waits while the pedestrian passes, then moves on once the closest approach no longer falls within the clearance. -/
-- The bicycle halts at y = 9.4 from instant 2 to 6 while the pedestrian passes 0.6 m clear at
-- y = 7.6; it moves on at instant 7, when the pedestrian is 4.5 m east and walking away.
def permitTrace : Trace :=
  ride 10 .bicycle Build.south [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    [1250, 1050, 940, 940, 940, 940, 940, 940, 740, 540]
    [200, 200, 0, 0, 0, 0, 0, 200, 200, 200]
    (walker (-600) 760 Build.east 1)

/-- `idle` (not_applicable): The bicycle rides on the roadway past the driveway and never occupies the sidewalk. -/
def idleTrace : Trace :=
  ride 5 .bicycle Build.east [-1000, -500, 0, 500, 1000] [350, 350, 350, 350, 350]
    [500, 500, 500, 500, 500]
    (walker (-600) 850 Build.east 1)

/-- `blind` (unknown): A bicycle near a driveway with a pedestrian approaching, where the source does not observe which regions the bicycle occupies. -/
-- The forbid ride, continued onto the roadway at instant 4; the occupancy is masked.
def blindTrace : Trace :=
  ride 5 .bicycle Build.south [0, 0, 0, 0, 0] [1250, 1050, 850, 650, 450] [200, 200, 200, 200, 200]
    (walker (-600) 850 Build.east 1)

/-- `branch_1` (compliant): An electric scooter emerges from an alley across the sidewalk with no pedestrian in the scene: the duty binds the subject alone and is met. -/
-- Built with an electric bicycle: the reading admits no class into
-- DEF-LVMC-11-02-083::electric_scooter (it leaves ru.electric_scooter unresolved), so an electric
-- scooter's class is unknown and no decided verdict is reachable for it. The rider leaves alley
-- A1 (inside the right-of-way) onto the sidewalk where A1 runs across it: at the entry it
-- occupies both.
def branch_1Trace : Trace :=
  ride 4 .electricBicycle Build.south [-2100, -2100, -2100, -2100] [1250, 1050, 850, 650]
    [200, 200, 200, 200] (fun _ => [])

-- `branch_2` (violated): a bicycle emerges from a building (x = 30, no region beyond the property
-- line) onto the sidewalk and keeps moving in conflict with a pedestrian.
def branch_2Trace : Trace :=
  ride 4 .bicycle Build.south [3000, 3000, 3000, 3000] [1250, 1050, 850, 650] [200, 200, 200, 200]
    (walker 2400 850 Build.east 1)

-- `branch_3` (violated): a bicycle crosses from the roadway over the sidewalk into a building
-- (x = 34), in conflict with a pedestrian walking west at the entry.
def branch_3Trace : Trace :=
  ride 5 .bicycle Build.north [3400, 3400, 3400, 3400, 3400] [450, 650, 850, 1050, 1250]
    [200, 200, 200, 200, 200]
    (walker 4000 850 Build.west (-1))

-- `branch_4` (violated): a bicycle from driveway D1 halts on the sidewalk, and the pedestrian
-- walks into it (bodies overlap at instant 4): contact, with the bicycle at rest.
def branch_4Trace : Trace :=
  ride 6 .bicycle Build.south [0, 0, 0, 0, 0, 0] [1250, 1050, 940, 940, 940, 940] [200, 200, 0, 0, 0, 0]
    (walker (-600) 840 Build.east 1)

-- `branch_5` (compliant): a bicycle from alley A2 rides over the sidewalk while a pedestrian 6 m
-- away approaches within the horizon but to 4.8 m, beyond the clearance.
def branch_5Trace : Trace :=
  ride 4 .bicycle Build.south [-3300, -3300, -3300, -3300] [1250, 1050, 850, 650] [200, 200, 200, 200]
    (walker (-4200) 850 Build.east 1)

-- `branch_6` (not_applicable): the forbid ride outside a business or residence district.
def branch_6Trace : Trace :=
  ride 4 .bicycle Build.south [0, 0, 0, 0] [1250, 1050, 850, 650] [200, 200, 200, 200]
    (walker (-600) 850 Build.east 1) (asmOn := false)

-- `branch_7` (violated): a bicycle turns from the roadway into driveway D2, whose apron runs
-- across the sidewalk: at the entry it occupies the sidewalk and D2, in conflict with a pedestrian.
def branch_7Trace : Trace :=
  ride 4 .bicycle Build.north [1000, 1000, 1000, 1000] [450, 650, 850, 1050] [200, 200, 200, 200]
    (walker 400 850 Build.east 1)

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
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_140_o2

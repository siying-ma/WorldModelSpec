/-
  Witnesses for NRS_484B_403_3.

  Every trace has 45 observations, one per second (t = 0 … 44 s). The subject (track 1, a motor
  vehicle, 4.5 m × 1.8 m) drives east at 3 m/s along y = -2 m with zero yaw rate for k = 0 … 29,
  turns left for k = 30 … 33 at 36.87 / 53.13 / 53.13 / 36.87 deg/s, its heading passing through
  (4/5, 3/5), north, (-4/5, 3/5) to west (180 degrees in all, well inside the band [135, 225]
  degrees; every turning rate far above the 3 deg/s tolerance), and runs west along y = +2 m with
  zero yaw rate from k = 34. The reversal is recognized at k = 34 (t = 34 s): the 10 s window behind
  holds the whole turn and the yaw rate is back to zero. Each witness judges t = 25 … 44 s.

  Regions: highway 1 (x -60…60, y -10…10); intersection 2 (x -6…6, y -10…10); median/divider 3
  (x -3…3, y -1…1) with the opening attribute, lying on the highway the scene says; highway 4 (a
  second, divided stretch, x -60…60, y -10…10 of its own map) for the scenes that change way.
  Occupancy is stated per instant (the turning body straddles regions).

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_403_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_403_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The subject's yaw rate (held over the interval before each scene): 36.870 / 53.130 / 53.130 /
    36.870 deg/s at k = 30 … 33 (180 degrees in all), zero otherwise. -/
def yaw (k : Nat) : Q :=
  if k = 30 ∨ k = 33 then Units.millidegrees 36870
  else if k = 31 ∨ k = 32 then Units.millidegrees 53130
  else Q.zero

def pos (k : Nat) : Vec :=
  if k < 30 then (m (3 * (k : Int) - 90), m (-2))
  else if k ≤ 33 then (m 0, m 0)
  else (m (-3 * ((k : Int) - 34)), m 2)

/-- East; then (4/5, 3/5) at 36.87°, north, (-4/5, 3/5) at 143.13°; then west. -/
def hdg (k : Nat) : Vec :=
  if k < 30 then Build.east
  else if k = 30 then (Units.ratio 4 5, Units.ratio 3 5)
  else if k = 31 then Build.north
  else if k = 32 then (Units.ratio (-4) 5, Units.ratio 3 5)
  else Build.west

def subjectAt (k : Nat) (yawObserved : Bool := true) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (pos k) (hdg k) (Units.metresPerSecond 3) (cm 225, cm 90, cm 75))
    fun kn => { kn with yawRate := if yawObserved then some (yaw k) else none }

def highway1 : Structure := Build.rect 1 .highway (m (-60)) (m (-10)) (m 60) (m 10)
def highway4 : Structure := Build.rect 4 .highway (m (-60)) (m (-10)) (m 60) (m 10)
def intersection2 : Structure := Build.rect 2 .intersection (m (-6)) (m (-10)) (m 6) (m 10)
/-- A divider region with the opening attribute, lying on way `w`. -/
def divider3 (w : RegionId) : Structure :=
  { Build.rect 3 .medianOrDivider (m (-3)) (m (-1)) (m 3) (m 1) with ways := some [w], opening := some true }

/-- A trace of the turn: business district declared `asm`, occupancy `occ k` at instant k. -/
def mkTrace (asm : Bool) (structs : List Structure) (occ : Nat → List RegionId) : Trace :=
  Build.trace 45 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k] structs []
      (occupies := some ((occ k).map fun r => ((1 : TrackId), r)))
      (assumptions := [("asm.business_district", asm)])

/-- `forbid` (violated): asm.business_district declared true; the subject vehicle on a two-way street mid-block, with no intersection and no divider anywhere near, reverses its heading by about 180 degrees within 8 s with its yaw rate observed throughout, occupying the highway region. -/
def forbidTrace : Trace :=
  mkTrace true [highway1] fun _ => [1]

/-- `permit` (compliant): asm.business_district declared true; the subject vehicle reverses its heading by about 180 degrees while its footprint overlaps an intersection region at every observation of the turn. -/
def permitTrace : Trace :=
  mkTrace true [highway1, intersection2] fun _ => [1, 2]

/-- `idle` (not_applicable): asm.business_district declared false for every place of the trace; the subject vehicle makes a mid-block reversal of direction. -/
def idleTrace : Trace :=
  mkTrace false [highway1] fun _ => [1]

/-- `blind` (unknown): asm.business_district declared true; the subject vehicle's heading reverses mid-block but kin.yaw_rate is not observed on this source, so neither the reversal nor its under-way observations can be decided. -/
def blindTrace : Trace :=
  Build.trace 45 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k] [highway1] []
      (occupies := some [((1 : TrackId), 1)])
      (assumptions := [("asm.business_district", true)])

/-- `occasion_s4` (violated): In the business district the subject begins the reversal inside an intersection region and completes it mid-block beyond the intersection, so it occupies the intersection for part of the turn only; no divider. -/
def occasion_s4Trace : Trace :=
  mkTrace true [highway1, intersection2] fun k => if 30 ≤ k ∧ k ≤ 31 then [1, 2] else [1]

/-- `occasion_s4_outside` (compliant): In the business district the subject approaches on a lane outside the intersection, enters it, and makes the whole reversal with its footprint overlapping the intersection at every observation while the turn is under way. -/
def occasion_s4_outsideTrace : Trace :=
  mkTrace true [highway1, intersection2] fun k => if k ≤ 28 then [1] else [1, 2]

/-- `occasion_s5` (violated): In the business district the subject starts its reversal on a stretch whose way carries no divider and finishes it where a divider with an opening lies on the way, passing through the opening; it is on the divided highway for part of the turn only and occupies no intersection. -/
def occasion_s5Trace : Trace :=
  mkTrace true [highway1, highway4, divider3 4] fun k =>
    if k ≤ 31 then [1] else if k = 32 then [4, 3] else [4]

/-- `occasion_s5_outside` (compliant): In the business district the subject, having driven on an undivided stretch before, makes the whole reversal on a highway on which a divider lies, passing through the divider's opening mid-turn. -/
def occasion_s5_outsideTrace : Trace :=
  mkTrace true [highway1, highway4, divider3 4] fun k =>
    if k ≤ 27 then [1] else if k = 32 then [4, 3] else [4]

/-- `occasion_s6` (compliant): In the business district, on a divided highway throughout the reversal, the subject's footprint overlaps the divider region with the opening attribute during the middle part of the turn only. -/
def occasion_s6Trace : Trace :=
  mkTrace true [highway1, divider3 1] fun k => if k = 32 then [1, 3] else [1]

/-- `occasion_s6_outside` (violated): In the business district, on a divided highway throughout, the subject drives through a divider opening region before beginning its reversal and then reverses within one roadway without overlapping any opening while the turn is under way; no intersection. -/
def occasion_s6_outsideTrace : Trace :=
  mkTrace true [highway1, divider3 1] fun k => if 26 ≤ k ∧ k ≤ 27 then [1, 3] else [1]

/-- The instants judged: t = 25 … 44 s, where every window the rule and its concept read behind
    lies inside the recorded straight run. -/
def judged : Option (Timestamp × Timestamp) := some (25000, 44000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_403_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s4" occasion_s4Trace .violated
  , witness "occasion_s4_outside" occasion_s4_outsideTrace .compliant
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .compliant
  , witness "occasion_s6" occasion_s6Trace .compliant
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .violated ]

end TrafficSpecWitness.NRS_484B_403_3

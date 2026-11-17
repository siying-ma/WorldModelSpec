/-
  Witnesses for NRS_484B_270_7b.

  The carriageway is an eastbound street along +x (no structure is read by the rule). Observations
  are one second apart, from t = 0. Track 1 is the subject, a bicycle (half-extents 1 m × 0.3 m),
  riding east at 5 m/s; track 2 a car (half-extents 2 m × 1 m) on y = 0, heading east.

  The standard pass (forbid, permit, blind, idle, branch_3): car at x = 2k + 40, bicycle at x = 5k,
  so the car is ahead (longitudinal gap between the projections) up to k = 12, alongside at k = 13
  and 14, and behind at k = 15: the act begins at k = 12 and is recognized at k = 15. The traces
  run from k = 0 so that the act's 10 s look-back is covered; the witnesses speak of k = 11 … 18.
  The lateral gap between the bodies is the bicycle's offset less 1.3 m: 0.7 m at y = 2 (below the
  1 m safe gap), 1.7 m at y = 3 (above it).

  branch_4: the bicycle follows the car in its lane 0.5 m behind it until k = 10, moves out to
  y = 3 at k = 11 (the act's beginning), is alongside at k = 12, 13 and clears it at k = 14.

  branch_2: a standing car at (40, 0); the bicycle at x = 5k − 25, y = 3, passes it (begins k = 12,
  recognized k = 14) while an oncoming car (track 3) runs west at 10 m/s on y = 5 from x = 200 − 10k:
  from k = 12 their centres reach a closest approach of 2 m within 3 s.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_7b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_7b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The subject on a bicycle, at (x, y) in centimetres, riding east. -/
def bike (x y : Int) : RoadUser :=
  Build.user 1 [.bicycle] (cm x, cm y) Build.east (Units.metresPerSecond 5) (m 1, cm 30, m 1)

/-- A car at (x, y) in centimetres. -/
def car (tr : TrackId) (x y : Int) (h : Vec) (v : Q) : RoadUser :=
  Build.user tr [.motorVehicle] (cm x, cm y) h v (m 2, m 1, m 1)

/-- The standard pass, the bicycle's lateral offset (cm) a function of the instant. -/
def standardPass (subj : Nat → Int → Int → RoadUser) (yOf : Nat → Int) : Trace :=
  Build.trace 19 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    Build.scene t (some 1)
      [ subj k (500 * ki) (yOf k)
      , car 2 (200 * ki + 4000) 0 Build.east (Units.metresPerSecond 2) ]
      [ ]
      [ ]

def passWindow : Option (Timestamp × Timestamp) := some (11000, 18000)

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A bicycle overtakes and passes a car moving slowly in the same direction, keeping a gap between bodies smaller than p.bicycle_pass_safe_gap while alongside. -/
def forbidTrace : Trace := standardPass (fun _ x y => bike x y) (fun _ => 200)

/-- `permit` (compliant): A bicycle overtakes and passes a slow car with a gap of at least p.bicycle_pass_safe_gap throughout the pass, no contact and no conflicting closest approach with any other road user. -/
def permitTrace : Trace := standardPass (fun _ x y => bike x y) (fun _ => 300)

/-- `idle` (not_applicable): The subject is a motor-driven road user outside the three aggregates
    (a moped: a car's own class is left unresolved by DEF-NRS-484B-017 and -018, so a car's
    membership is unknown under the reading, never false) overtaking a car. -/
def idleTrace : Trace :=
  standardPass
    (fun _ x y => Build.user 1 [.moped] (cm x, cm y) Build.east (Units.metresPerSecond 5) (m 1, cm 40, m 1))
    (fun _ => 300)

/-- `blind` (unknown): A bicycle overtakes and passes a car with no conflict with other road users; the gap between bodies is not observed on this source. -/
def blindTrace : Trace := standardPass (fun _ x y => bike x y) (fun _ => 300)

/-- `branch_3` (violated): A bicycle begins the pass of a car with a wide gap, then closes to a gap below p.bicycle_pass_safe_gap while still alongside before clearing the car: the pass is safe for part of the act only. -/
def branch_3Trace : Trace := standardPass (fun _ x y => bike x y) (fun k => if k ≤ 13 then 300 else 200)

/-- `branch_4` (compliant): A bicycle follows close behind a car with a small gap before the pass begins, then moves out and keeps a gap of at least p.bicycle_pass_safe_gap at every observation from the pass's beginning to its recognition. -/
def branch_4Trace : Trace :=
  Build.trace 18 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    let carX : Int := 200 * ki + 4000
    -- the car's centre ahead of the bicycle's, cm
    let rel : Int := if k ≤ 11 then 350 else 100 - 300 * (ki - 12)
    let y : Int := if k ≤ 10 then 0 else 300
    Build.scene t (some 1)
      [ bike (carX - rel) y
      , car 2 carX 0 Build.east (Units.metresPerSecond 2) ]
      [ ]
      [ ]

/-- `branch_1` (compliant): A bicycle rides on a street with no motor vehicle in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ bike (500 * Int.ofNat k) 0 ]
      [ ]
      [ ]

/-- `branch_2` (violated): A bicycle overtakes and passes a standing car with a wide gap, but during the pass an oncoming car comes into a closest approach with the bicycle within p.conflict_horizon and below p.conflict_centre_clearance. -/
def branch_2Trace : Trace :=
  Build.trace 17 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    Build.scene t (some 1)
      [ bike (500 * ki - 2500) 300
      , car 2 4000 0 Build.east Q.zero
      , car 3 (20000 - 1000 * ki) 500 Build.west (Units.metresPerSecond 10) ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_270_7b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := passWindow)
  , witness "permit" permitTrace .compliant (window := passWindow)
  , witness "idle" idleTrace .notApplicable (window := passWindow)
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"] (window := passWindow)
  , witness "branch_3" branch_3Trace .violated (window := passWindow)
  , witness "branch_4" branch_4Trace .compliant (window := some (10000, 17000))
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated (window := some (10000, 16000)) ]

end TrafficSpecWitness.NRS_484B_270_7b

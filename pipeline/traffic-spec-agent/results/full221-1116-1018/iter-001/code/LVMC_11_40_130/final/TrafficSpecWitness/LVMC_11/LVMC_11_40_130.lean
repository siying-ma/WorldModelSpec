/-
  Witnesses for LVMC_11_40_130.

  One bicycle (track 1, class bicycle, half-extent 0.9 × 0.3 × 0.6 m) rides east along y = 0,
  three instants one second apart, its x advancing by its speed each second. The weather is the
  scene's `env`, every field set so that each condition is decided. Against the reading
  (reaction 2.5 s; decel dry 3.1, wet 1.6, ice 0.5 m/s²; lamp reach 30 m), stopping distance
  S(v) = 2.5 v + v² / (2 a):
    forbid    v = 10 m/s, dry, day, visibility 15 m: S_dry ≈ 41 m > 15 m.
    permit    v = 5 m/s, dry, day, visibility 200 m: S_dry ≈ 16.5 m ≪ 200 m.
    idle      v = 0: not above the halt tolerance.
    blind     v = 5 m/s, dry, day, visibility masked.
    branch_1  v = 6 m/s, ice, day, visibility 40 m: S_ice = 51 m > 40 m, S_dry ≈ 20.8 m < 40 m.
    branch_2  v = 8 m/s, wet road (no precipitation), day, visibility 35 m: S_wet = 40 m > 35 m,
              S_dry ≈ 30.3 m < 35 m.
    branch_3  as branch_2 with precipitation falling on a road not reported wet.
    branch_4  v = 9 m/s, dry, darkness, visibility 200 m: S_dry ≈ 35.6 m > lamp reach 30 m,
              though well inside the visibility.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_130
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_130

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A dry road in daylight with the given visibility. -/
def dryDay (vis : Q) : Env :=
  { darkness := some false
    precipitation := some false
    wetRoad := some false
    iceOrSnow := some false
    visibility := some vis }

/-- The bicycle riding east at `v` under `env`. -/
def ride (v : Q) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (Q.mul v (Q.ofInt (k : Int)), m 0) Build.east v (cm 90, cm 30, cm 60) ]
      [ ]
      [ ]
      (env := env)

/-- `forbid` (violated): A bicycle rides fast in dense fog: env.visibility is far shorter than the reaction distance plus the dry braking distance at its speed. -/
def forbidTrace : Trace := ride (Units.metresPerSecond 10) (dryDay (m 15))

/-- `permit` (compliant): A bicycle rides at a moderate speed on a dry road in daylight with long visibility and sight distance, its stopping distance well inside both. -/
def permitTrace : Trace := ride (Units.metresPerSecond 5) (dryDay (m 200))

/-- `idle` (not_applicable): The bicycle stands at rest at a signal: its speed is at the halt tolerance. -/
def idleTrace : Trace := ride Q.zero (dryDay (m 15))

/-- `blind` (unknown): The bicycle rides at a speed whose verdict depends on the visibility, which the source does not observe. -/
def blindTrace : Trace := ride (Units.metresPerSecond 5) (dryDay (m 15))

/-- `branch_1` (violated): On an icy road in light mist the bicycle rides at a speed whose stopping distance at the ice deceleration exceeds the visibility, though the dry stopping distance would not. -/
def branch_1Trace : Trace :=
  ride (Units.metresPerSecond 6) { dryDay (m 40) with iceOrSnow := some true }

/-- `branch_2` (violated): On a wet road (no rain falling) the wet stopping distance exceeds the visibility, the dry one would not. -/
def branch_2Trace : Trace :=
  ride (Units.metresPerSecond 8) { dryDay (m 35) with wetRoad := some true }

/-- `branch_3` (violated): Rain falling on a road not reported wet: the wet deceleration applies, its stopping distance exceeds the visibility. -/
def branch_3Trace : Trace :=
  ride (Units.metresPerSecond 8) { dryDay (m 35) with precipitation := some true }

/-- `branch_4` (violated): In darkness with long visibility, the dry stopping distance exceeds the headlamp's reach. -/
def branch_4Trace : Trace :=
  ride (Units.metresPerSecond 9) { dryDay (m 200) with darkness := some true }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_40_130"
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
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_130

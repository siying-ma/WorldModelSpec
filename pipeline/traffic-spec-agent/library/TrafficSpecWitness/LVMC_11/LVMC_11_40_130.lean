/-
  Witnesses for LVMC_11_40_130.

  One bicycle (track 1) rides east along y = 0 for three instants one second apart, its position
  advancing by its speed each second; no structure is needed (the rule reads only the subject's
  speed and the environment). Bicycle half-extents 0.9 m × 0.3 m × 0.6 m. Every environment field
  the rule reads is set (darkness, precipitation, wet road, ice or snow, visibility), so each
  verdict is decided by the leaf the scene is about.

  Against the run's reading (reaction 2.5 s; dry 3.1, wet 1.6, ice 0.5 m/s²; lamp 30 m), with the
  bound v·v ≤ 2·a·(D − 2.5·v):
    forbid   v 6, dry, daylight, fog D 10:   36 vs 2·3.1·(10 − 15) < 0       → violated
    permit   v 5, dry, daylight, D 200:      25 vs 2·3.1·(200 − 12.5) ≈ 1162 → compliant
    idle     v 0 (at rest at a signal)                                         → not applicable
    blind    v 5, dry, daylight, visibility masked (200 in the scene)          → unknown
    branch_1 v 6, ice, mist D 40:            36 vs 2·0.5·(40 − 15) = 25      → violated
             (dry would give 2·3.1·25 = 155 ≥ 36)
    branch_2 v 7, wet road, D 29:            49 vs 2·1.6·(29 − 17.5) = 36.8  → violated
             (dry would give 2·3.1·11.5 = 71.3 ≥ 49)
    branch_3 v 7, precipitation (road not flagged wet), D 29: as branch_2     → violated
    branch_4 v 9, dry, darkness, D 200:      lamp 81 vs 2·3.1·(30 − 22.5) = 46.5 → violated
             (in daylight 2·3.1·(200 − 22.5) ≈ 1100 ≥ 81)
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_130
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_130

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A bicycle riding east at `v` m/s, at the `k`-th second. -/
def bike (k : Nat) (v : Int) : RoadUser :=
  Build.user 1 [.bicycle] (m (Int.ofNat k * v), m 0) Build.east (Units.metresPerSecond v)
    (cm 90, cm 30, cm 60)

/-- A dry road in daylight, no precipitation, with visibility `vis` metres. -/
def dryDay (vis : Int) : Env :=
  { darkness := some false
    precipitation := some false
    wetRoad := some false
    iceOrSnow := some false
    visibility := some (m vis) }

/-- A bicycle at speed `v` in the environment `env`, three instants one second apart. -/
def ride (v : Int) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ bike k v ] [ ] [ ] (env := env)

/-- `forbid` (violated): A bicycle rides fast in dense fog: env.visibility is far shorter than the reaction distance plus the dry braking distance at its speed. -/
def forbidTrace : Trace := ride 6 (dryDay 10)

/-- `permit` (compliant): A bicycle rides at a moderate speed on a dry road in daylight with long visibility and sight distance, its stopping distance well inside both. -/
def permitTrace : Trace := ride 5 (dryDay 200)

/-- `idle` (not_applicable): The bicycle stands at rest at a signal: its speed is at the halt tolerance. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, m 0) Build.east Q.zero (cm 90, cm 30, cm 60) ]
      [ ]
      [ ]
      (env := dryDay 10)

/-- `blind` (unknown): The bicycle rides at a speed whose verdict depends on the visibility, which the source does not observe. -/
def blindTrace : Trace := ride 5 (dryDay 200)

/-- `branch_1` (violated): On an icy road in light mist the bicycle rides at a speed whose stopping distance at the ice deceleration exceeds the visibility, though the dry stopping distance would not. -/
def branch_1Trace : Trace := ride 6 { dryDay 40 with iceOrSnow := some true }

/-- `branch_2` (violated): On a wet road (no precipitation) the wet stopping distance exceeds the visibility, though the dry one would not. -/
def branch_2Trace : Trace := ride 7 { dryDay 29 with wetRoad := some true }

/-- `branch_3` (violated): In rain on a road not flagged wet the wet stopping distance exceeds the visibility, though the dry one would not. -/
def branch_3Trace : Trace := ride 7 { dryDay 29 with precipitation := some true }

/-- `branch_4` (violated): In darkness with long visibility the dry stopping distance exceeds the headlamp's reach, though not the visibility. -/
def branch_4Trace : Trace := ride 9 { dryDay 200 with darkness := some true }

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

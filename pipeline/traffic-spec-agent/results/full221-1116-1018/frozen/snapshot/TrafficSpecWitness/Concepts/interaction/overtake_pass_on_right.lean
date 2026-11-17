/-
  Witnesses for drv.interaction.overtake_pass_on_right.

  Geometry (every figure here is the witness's own):
    - lane 10, the strip y ∈ [-2, 2] m; lane 11, its right-hand neighbour y ∈ [-6, -2] m; lane 12,
      its left-hand neighbour y ∈ [2, 6] m; all running east from x = 0 to x = 200 m (not read by
      the concept; the narrative's lanes).
    - road user b = track 2, a motor vehicle of half-extent 2 m × 1 m × 1 m, halted at (100, 0)
      heading east in every scene.
    - road user a = track 1, a motor vehicle of the same half-extent, heading east in every scene:
      the headings are aligned (cosine 1).
    - ten scenes, one per second (t = 0 … 9000 ms); a's position at scene k, with s = −4 m (moving
      to the right, holds and blind) or s = +4 m (moving to the left, fails):
        k0 (40,0)  k1 (52,0)  k2 (64,0)  k3 (76,0)   following b in lane 10, b ahead
        k4 (88,s)  in the next lane, b still ahead: projections [86,90] and [98,102], gap 8 m
        k5 (97,s)  k6 (100,s)  k7 (103,s)   alongside: the projections share 1, 4, 1 m
        k8 (107,s) b behind: projections [105,109] and [98,102], gap 3 m; the component of b − a
                   along a's heading is −7 m: the recognition of the pass, t = 8000 ms.
        k9 (119,s) b still behind.
      b − a has lateral component −s in a's frame: +4 (b on a's left) in holds and blind, −4 (b on
      a's right) in fails, at every scene from k4 on.
    - every scenario judges the recognition instant only (window 8000–8000 ms).
  Instance: window = 6 s (it reaches back from 8000 ms to 2000 ms, so k4 lies inside it and the
  window is covered by the trace), same_dir_cos = 9/10.
  blind: the pass of holds, from a source that does not observe the bodies' extents (it measures
  the longitudinal overlap on the relation a → b instead, the same figures as above) and that loses
  the positions of the two road users while they are side by side (k5–k7), where it measures b's
  bearing in a's frame on the relation a → b instead ((3,4), (0,4), (−3,4)). Core computes the
  bearing from the positions and a's heading wherever those are observed, so it is only at k5–k7
  that the bearing is the source's measurement; overtake_pass does not need the positions there
  (the bodies share length, so b is neither ahead nor behind). With rel.bearing masked, the side on
  which b lies while the two are side by side cannot be read: the concept is unknown for the
  masked bearing alone; with it observed, the trace is the compliant pass of holds.
-/
import TrafficSpec.Concepts.interaction.overtake_pass_on_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtake_pass_on_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtake_pass_on_right@w"
    concept := "drv.interaction.overtake_pass_on_right"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 6) .second), ("same_dir_cos", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The three lanes of the narrative (not read by the concept). -/
def laneOwn : Structure := Build.lane 10 [(m 0, m (-2)), (m 200, m (-2)), (m 200, m 2), (m 0, m 2)] Build.east
def laneRight : Structure := Build.lane 11 [(m 0, m (-6)), (m 200, m (-6)), (m 200, m (-2)), (m 0, m (-2))] Build.east
def laneLeft : Structure := Build.lane 12 [(m 0, m 2), (m 200, m 2), (m 200, m 6), (m 0, m 6)] Build.east
def lanes : List Structure := [laneOwn, laneRight, laneLeft]

def half : Q × Q × Q := (m 2, m 1, m 1)

/-- b, halted at (100, 0) heading east. -/
def userB : RoadUser := Build.user 2 [.motorVehicle] (m 100, m 0) Build.east (Units.metresPerSecond 0) half

/-- a at a position, heading east, at a speed (m/s). -/
def userA (x y : Int) (v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond v) half

/-- a passing b, moving to the lateral offset `s` (m) from scene 4 on. -/
def passing (s : Int) (k : Nat) : RoadUser :=
  match k with
  | 0 => userA 40 0 12
  | 1 => userA 52 0 12
  | 2 => userA 64 0 12
  | 3 => userA 76 0 12
  | 4 => userA 88 s 12
  | 5 => userA 97 s 3
  | 6 => userA 100 s 3
  | 7 => userA 103 s 3
  | 8 => userA 107 s 12
  | _ => userA 119 s 12

/-- The shared length of the projections on a's heading (m). -/
def overlapPassing (k : Nat) : Int :=
  match k with
  | 0 => -56
  | 1 => -44
  | 2 => -32
  | 3 => -20
  | 4 => -8
  | 5 => 1
  | 6 => 4
  | 7 => 1
  | 8 => -3
  | _ => -15

/-- `holds` (compliant): a follows b in the same lane with headings aligned, b ahead; a moves to
    the right-hand lane, draws alongside with b on its left while the projections share length,
    and comes to have b behind it, still on its left, 4 s after b was last ahead of it: the
    concept holds at that observation. -/
def holdsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [passing (-4) k, userB] lanes []

/-- `fails` (violated): the same pass made with a moving to the left-hand lane: while side by
    side and at the recognition b is on a's right; overtake_pass holds but the passage is on b's
    left, so the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [passing 4 k, userB] lanes []

/-- The source of blind: no extents; no positions while the two are side by side (k5–k7). -/
def alongside (k : Nat) : Bool := k == 5 || k == 6 || k == 7

def blindUser (k : Nat) (u : RoadUser) : RoadUser :=
  Build.withKin u fun kn =>
    { kn with extent := none, position := if alongside k then none else kn.position }

/-- b's bearing in a's frame (longitudinal, lateral), measured where the positions are not. -/
def bearingAlongside (k : Nat) : Option Vec :=
  match k with
  | 5 => some (m 3, m 4)
  | 6 => some (m 0, m 4)
  | 7 => some (m (-3), m 4)
  | _ => none

/-- `blind` (unknown): the pass of holds with rel.bearing not observed on the source:
    overtake_pass, read from the positions, headings and overlap, holds at the observation at
    which b first is behind a, but the side on which b lies while the two are side by side cannot
    be read, so the concept is unknown. -/
def blindTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1) [blindUser k (passing (-4) k), blindUser k userB] lanes [] with
          occupancyObserved := [], occupies := [] }
      [Build.relation 1 2 fun r =>
        { r with longitudinalOverlap := some (m (overlapPassing k)), bearing := bearingAlongside k }]

def witness (name : String) (τ : Trace) (expected : Verdict) (at_ : Timestamp)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := some (at_, at_) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 8000
  , witness "fails" failsTrace .violated 8000
  , witness "blind" blindTrace (.unknown []) 8000 ["rel.bearing"] ]

end TrafficSpecWitness.Concepts.interaction.overtake_pass_on_right

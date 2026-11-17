/-
  Witnesses for drv.interaction.overtake_pass_on_right.

  TODO(code): describe the geometry once built — the bodies, the regions, the instants; every figure
  here is the witness's own, including the values the instance gives the formal parameters.
-/
import TrafficSpec.Concepts.interaction.overtake_pass_on_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtake_pass_on_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor (TODO), a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtake_pass_on_right@w"
    concept := "drv.interaction.overtake_pass_on_right"
    literals := []
    nats := []
    params := [("window", .lit (Q.ofInt 0) .second), ("same_dir_cos", .lit (Q.ofInt 0) .ratio)]  -- TODO values
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): a follows b in the same lane with headings aligned (rel.same_direction), b ahead with no longitudinal overlap; a moves to the right, draws alongside with b's bearing lateral component positive (b on a's left) while rel.longitudinal_overlap is non-negative, and comes to have b behind it with b still on its left, all within the window: the concept holds at the observation at which b first is behind a. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

/-- `fails` (violated): The same pass made with a moving to the left: while side by side, b's bearing lateral component is negative (b on a's right), and at recognition b is behind a on its right: drv.interaction.overtake_pass holds but the passage is on b's left, so the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

/-- `blind` (unknown): The pass of the holds scenario with rel.bearing not observed on the source: neither the order nor the side can be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"] ]

end TrafficSpecWitness.Concepts.interaction.overtake_pass_on_right

/-
  Witnesses for NRS_484B_297_6_o2.

  Geometry (metres, +x east, +y north): highway 10 spans y ∈ [-6, 5], x ∈ [-50, 100]; on it the
  roadway 11 (y ∈ [-6, 2]) and the sidewalk 12 (y ∈ [2, 5]), both lying on highway 10. A barrier
  13 (an obstruction) fills the sidewalk's width over x ∈ [10, 12]. Highway 14 (y ∈ [5, 15]) is a
  second public way the sidewalk does not lie on (branch_2 only).

  The pedestrian (track 1, half-extents 0.25 × 0.25 × 0.9 m) walks east at 1 m/s, one observation a
  second from t = 20 s: on the sidewalk (y = 3.5) at x = 7, 8, 9 — the last 0.75 m short of the
  barrier — then on the roadway (y = 1) at x = 7 + k, 0.75 m beside the barrier while passing it,
  and more than the encounter reach (2 m) from it from x = 15 on (k = 8). Every trace is padded
  10 s before with its first scene, so the 5 s return window is never truncated.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_297_6_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_297_6_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asmId : AsmId := "asm.sidewalk_section_missing_or_impassable"

def highway1 : Structure := Build.rect 10 .highway (m (-50)) (m (-6)) (m 100) (m 5)
def roadway : Structure := { Build.rect 11 .roadway (m (-50)) (m (-6)) (m 100) (m 2) with ways := some [10] }
def sidewalk : Structure := { Build.rect 12 .sidewalk (m (-50)) (m 2) (m 100) (m 5) with ways := some [10] }
def highway2 : Structure := Build.rect 14 .highway (m (-50)) (m 5) (m 100) (m 15)

/-- A barrier across the sidewalk over x ∈ [x0, x0 + 2]. -/
def barrier (x0 : Int) : Structure :=
  { Build.rect 13 .obstruction (m x0) (m 2) (m (x0 + 2)) (m 5) with obstructionKind := some .barrier }

/-- A mail drop box at the sidewalk's outer edge, beside the walking line, not blocking it. -/
def dropBox : Structure :=
  { Build.rect 15 .obstruction (m 14) (cm 460) (m 15) (m 5) with obstructionKind := some .mailDropBox }

def ped (pos : Vec) : RoadUser :=
  Build.user 1 [.pedestrian] pos Build.east (Units.metresPerSecond 1) (cm 25, cm 25, cm 90)

/-- On the sidewalk for k ≤ 2, then at `y` (cm) from k = 3 on, walking east at 1 m/s. -/
def leaving (y : Int) (k : Nat) : Vec :=
  if k ≤ 2 then (m (7 + k), cm 350) else (m (7 + k), cm y)

def run (n : Nat) (pos : Nat → Vec) (structures : List Structure) (asm : Bool) : Trace :=
  Build.pad
    (Build.trace n 20000 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [ped (pos k)] structures [] (assumptions := [(asmId, asm)]))
    (Units.seconds 10) (Units.seconds 0) (Units.seconds 1)

/-- `forbid` (violated): x leaves sidewalk w at a st.obstruction (barrier), passes it on the roadway, and keeps walking on the roadway 20 s after it is more than 2 m from the barrier, a sidewalk beside it. -/
def forbidTrace : Trace :=
  run 30 (leaving 100) [highway1, roadway, sidewalk, barrier 10] false

/-- `permit` (compliant): Same, but x steps back onto w 2 s after clearing the barrier. -/
def permitTrace : Trace :=
  run 20 (fun k => if k ≤ 2 || 10 ≤ k then (m (7 + k), cm 350) else (m (7 + k), cm 100))
    [highway1, roadway, sidewalk, barrier 10] false

/-- `idle` (not_applicable): x walks on the sidewalk throughout (past a mail drop box at its edge). -/
def idleTrace : Trace :=
  run 30 (fun k => (m k, cm 350)) [highway1, roadway, sidewalk, dropBox] false

/-- `blind` (unknown): As forbid, but st.region_geometry is absent, so neither the encounter nor clearing the obstruction can be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): x leaves the sidewalk where no obstruction is near and no section is
    missing, then passes a barrier on the roadway and stays there: no encounter on the sidewalk. -/
def branch1Trace : Trace :=
  run 30 (leaving 100) [highway1, roadway, sidewalk, barrier 16] false

/-- `branch_2` (not_applicable): x leaves the sidewalk at the barrier onto highway 14, a way the
    sidewalk does not lie on, and stays there. -/
def branch2Trace : Trace :=
  run 30 (leaving 700) [highway1, roadway, sidewalk, highway2, barrier 10] false

/-- `branch_3` (violated): no obstruction; x leaves the sidewalk at a missing section (the declared
    assumption) and keeps walking on the roadway for 20 s. -/
def branch3Trace : Trace :=
  run 30 (leaving 100) [highway1, roadway, sidewalk] true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_297_6_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .violated ]

end TrafficSpecWitness.NRS_484B_297_6_o2

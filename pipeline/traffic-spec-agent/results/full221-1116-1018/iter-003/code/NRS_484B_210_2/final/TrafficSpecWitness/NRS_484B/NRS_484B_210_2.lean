/-
  Witnesses for NRS_484B_210_2.

  Geometry (every figure is the witness's own and appears nowhere in the rule). A straight road
  running east; no structures are needed (the rule reads only the two road users' kinematics).
  Cars: half-length 2 m, half-width 0.9 m, half-height 0.75 m, class motor_vehicle (included in
  DEF-NRS-484A-320::vehicle). Subject = track 1, b = track 2, a third car = track 3.

  Eight observations k = 0 … 7 at 1 s spacing from t = 20 s; each trace is padded 12 s before
  (the first scene repeated, so the 10 s look-back of the act and of the obligation is covered) and
  2 s after. The subject runs east at 14 m/s from x = 0; b runs east at 10 m/s from x = 18 m.
  Their centre gap along the road is 18 − 4k m: k = 3 gap 6 m (b ahead, projections 2 m apart:
  the act's beginning), k = 4 gap 2 m and k = 5 gap −2 m (side by side), k = 6 gap −6 m (b behind,
  2 m apart): the pass is recognized at k = 6 (t = 26 s).

  forbid: b 4.5 m to the subject's left; between k = 3 and k = 4 the subject moves 2.5 m toward b
          (lateral velocity 2.5 m/s at k = 3), so at k = 4 the centres are 2 m apart laterally and
          closing at 4 m/s: closest approach 2 m after 0.5 s, below the 3 m clearance.
  permit: b 4.5 m to the left throughout: every closest approach within 3 s is 4.5 m.
  idle:   both at 10 m/s in one line, b 20 m ahead: no pass.
  blind:  the permit scene with rel.bearing unobserved.
  branch_1 (compliant): the subject first closes on b from behind in b's own line (at k = 2,
          10 m behind at 4 m/s faster: a closest approach of 0 m in 2.5 s), then is 4.5 m to b's
          right from k = 3 (the act's beginning) and passes there: the conflict lies before the act.
  branch_2 (violated): the permit pass, with a third car riding alongside the subject on its right,
          bodies touching (centres 1.8 m apart laterally, same velocity: no closest approach), so
          only rel.contact speaks.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_210_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_210_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

/-- A car heading east. -/
def car (track : TrackId) (x y speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east speed (m 2, cm 90, cm 75)

/-- Longitudinal positions: the subject from 0 at 14 m/s, b from 18 m at 10 m/s. -/
def subjX (k : Nat) : Q := m (14 * (k : Int))
def bX (k : Nat) : Q := m (18 + 10 * (k : Int))

def t0 : Timestamp := 20000

/-- The eight observations, padded before and after. -/
def episode (users : Nat → List RoadUser) : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t => Build.scene t (some 1) (users k) [] [])
    (Units.seconds 12) (Units.seconds 2) (Units.seconds 1)

/-- The instants the witnesses speak about. -/
def span : Timestamp × Timestamp := (t0, t0 + 7000)

/-- `forbid` (violated): The subject passes b on b's right and, while side by side, closes laterally on b so that their closest approach within p.conflict_horizon falls below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  episode fun k =>
    let sy : Q := if k ≤ 3 then Q.zero else cm 250
    let s := car 1 (subjX k) sy (mps 14)
    let s' := if k == 3 then Build.withKin s (fun kin => { kin with velocity := some (mps 14, cm 250) }) else s
    [ s', car 2 (bX k) (cm 450) (mps 10) ]

/-- `permit` (compliant): The subject passes b on b's right in the adjacent lane keeping its distance; no closest approach within p.conflict_horizon falls below p.conflict_centre_clearance and no contact occurs; no other road user is in the scene. -/
def permitTrace : Trace :=
  episode fun k => [ car 1 (subjX k) Q.zero (mps 14), car 2 (bX k) (cm 450) (mps 10) ]

/-- `idle` (not_applicable): The subject follows b in the same lane at a steady gap and never passes it. -/
def idleTrace : Trace :=
  episode fun k =>
    [ car 1 (m (10 * (k : Int))) Q.zero (mps 10), car 2 (m (20 + 10 * (k : Int))) Q.zero (mps 10) ]

/-- `blind` (unknown): The subject draws past b on its right but rel.bearing is not observed: whether a pass on the right occurred is unknown. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (compliant): the subject closes on b in b's own line before moving 4.5 m to its
    right and passing there safely; the conflict lies before the act's beginning. -/
def branch1Trace : Trace :=
  episode fun k =>
    let sy : Q := if k ≤ 2 then Q.zero else cm (-450)
    [ car 1 (subjX k) sy (mps 14), car 2 (bX k) Q.zero (mps 10) ]

/-- `branch_2` (violated): the permit pass, with a third car touching the subject's right side
    throughout at the subject's velocity: contact, no closest approach. -/
def branch2Trace : Trace :=
  episode fun k =>
    [ car 1 (subjX k) Q.zero (mps 14), car 2 (bX k) (cm 450) (mps 10),
      car 3 (subjX k) (cm (-180)) (mps 14) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_210_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some span
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch1Trace .compliant
  , witness "branch_2" branch2Trace .violated ]

end TrafficSpecWitness.NRS_484B_210_2

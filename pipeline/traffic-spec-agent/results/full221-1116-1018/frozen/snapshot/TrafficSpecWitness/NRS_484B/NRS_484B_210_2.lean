/-
  Witnesses for NRS_484B_210_2.

  Geometry (every figure is the witness's own): a straight road heading east (+x); b's lane centre
  at y = 4 m, i.e. on the subject's left. Both bodies are passenger cars of half-length 2.5 m,
  half-width 0.9 m. Instants k = 0 … 5 at one-second spacing (t = 0 … 5000 ms), the first scene
  repeated for 12 s before so that the 10 s look-back of the act and of the duty is covered.

  Passing scenes: the subject (track 1) runs at 20 m/s from x = 0, b (track 2) at 15 m/s from
  x = 17 m, so b's centre is 17, 12, 7, 2, −3, −8 m ahead: ahead with a gap at k = 0 … 2 (the act
  begins at k = 2), side by side at k = 3, 4, behind with a gap at k = 5 (the recognition).
    forbid: the subject moves from y = 0 to y = 2 m at k = 3 (centres 2 m apart laterally, bodies
            0.2 m apart): the closest approach at k = 3 is 2 m, 0.4 s ahead — below the 3 m bound.
    permit: the subject keeps y = 0: lateral separation 4 m, the closest approach is 4 m.
    idle:   both at 15 m/s in one lane (y = 0), b 20 m ahead throughout: no pass.
    blind:  the permit geometry with positions (and the relations computed from them) unobserved.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_210_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_210_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def car : Q × Q × Q := (cm 250, cm 90, cm 75)

-- Binders ↦ tracks: subject ↦ 1; the overtaken vehicle b is track 2.

/-- A pass of b (track 2, at y = 4 m) by the subject on b's right; `subjY k` is the subject's lateral position. -/
def passTrace (subjY : Nat → Int) : Trace :=
  Build.pad
    (Build.trace 6 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (m (20 * (k : Int)), m (subjY k)) Build.east (Units.metresPerSecond 20) car
        , Build.user 2 [.motorVehicle] (m (17 + 15 * (k : Int)), m 4) Build.east (Units.metresPerSecond 15) car ]
        [ ]
        [ ])
    (Units.seconds 12) Q.zero (Units.seconds 1)

/-- `forbid` (violated): The subject passes b on b's right and, while side by side, closes laterally on b so that their closest approach within p.conflict_horizon falls below p.conflict_centre_clearance. -/
def forbidTrace : Trace := passTrace fun k => if k ≥ 3 then 2 else 0

/-- `permit` (compliant): The subject passes b on b's right in the adjacent lane keeping its distance; no closest approach within p.conflict_horizon falls below p.conflict_centre_clearance and no contact occurs; no other road user is in the scene. -/
def permitTrace : Trace := passTrace fun _ => 0

/-- `idle` (not_applicable): The subject follows b in the same lane at a steady gap and never passes it. -/
def idleTrace : Trace :=
  Build.pad
    (Build.trace 6 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (Units.metresPerSecond 15) car
        , Build.user 2 [.motorVehicle] (m (20 + 15 * (k : Int)), m 0) Build.east (Units.metresPerSecond 15) car ]
        [ ]
        [ ])
    (Units.seconds 12) Q.zero (Units.seconds 1)

/-- `blind` (unknown): The subject draws past b on its right, but the source observes no positions of road users (kin.position absent), so the relations the rule reads that are computed from positions (rel.bearing, rel.longitudinal_overlap, rel.contact) are unobserved too: whether a pass on the right occurred, and whether it was made without conflict, is unknown. -/
def blindTrace : Trace := passTrace fun _ => 0

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_210_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, 5000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.position", "rel.bearing", "rel.longitudinal_overlap", "rel.contact"] ]

end TrafficSpecWitness.NRS_484B_210_2

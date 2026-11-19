import TrafficSpec.Core.Language.RuleEval
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Runtime.Monitor
import TrafficSpec.Core.Runtime.Decode
namespace TrafficSpec.Tests.SampledDuration
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.SampledDuration Lean

-- The sampled duration of a state formula in the window behind each observation. The window, the
-- step and the bound below are test values, no proposal: every case states them. No parameter the
-- case does not give enters it.

-- ---------------------------------------------------------------------------------------------
-- A. The operator against its specification: `boundsAll` equals `inWindow` of the cells' counts
-- (in `Rat`), on random traces whose windows start anywhere, cells inside and beyond the step.
-- ---------------------------------------------------------------------------------------------
def OP : String := "duration_within"
def lcg (s : Nat) : Nat := (s * 1103515245 + 12345) % 2147483648
def pick {α : Type} [Inhabited α] (xs : List α) (s : Nat) : α := xs[(s / 65536) % xs.length]!

structure Gen where
  times : Array Q
  vals : Array R
  w : Q
  step : Q

def gen (seed : Nat) : Gen := Id.run do
  let mut s := lcg (seed + 11)
  let mut t : Q := Q.ofInt (Int.ofNat (seed % 5))
  let mut times : Array Q := #[]
  let mut vals : Array R := #[]
  for k in [0:30] do
    s := lcg s
    vals := vals.push (pick [R.t, R.f, R.t, R.u (.absentAtom "a"), R.f, R.t] s)
    s := lcg s
    if k > 0 then t := Q.add t (pick [Q.ofInt 5, Q.ofInt 10, Q.ofInt 10, Q.mk' 25 2, Q.ofInt 40, Q.zero] s)
    times := times.push t
  let w := pick [Q.ofInt 25, Q.mk' 121 2, Q.ofInt 100, Q.ofInt 1000, Q.ofInt 7] (lcg (seed * 17 + 1))
  let step := pick [Q.ofInt 15, Q.ofInt 10, Q.mk' 25 2] (lcg (seed * 29 + 5))
  return { times, vals, w, step }

def tv (times : Array Q) : Nat → Rat := fun k => (times[k]!).val

def specLower (c : Gen) (i : Nat) : Rat :=
  inWindow (tv c.times) (lin (tv c.times) (low c.times c.step c.vals)) (fun _ => 0) 29 c.w.val (tv c.times i)
def specUpper (c : Gen) (i : Nat) : Rat :=
  inWindow (tv c.times) (lin (tv c.times) (high c.times c.step c.vals)) (fun y => y - tv c.times 0) 29 c.w.val (tv c.times i)

#guard (List.range 100).all fun seed =>
  let c := gen seed
  let B := boundsAll c.times c.w c.step OP c.vals
  B.size == 30 && (List.range 30).all fun i =>
    (B[i]!).lower.val == specLower c i && (B[i]!).upper.val == specUpper c i &&
    (B[i]!).lower.val ≤ (B[i]!).upper.val
-- the cases reach windows that start before the first observation, within a cell and at an
-- observation, and every kind of uncertainty
def whys : List String := (List.range 100).flatMap fun seed =>
  let c := gen seed
  (boundsAll c.times c.w c.step OP c.vals).toList.flatMap fun b => b.why.map (·.tag.takeWhile (· != ':') |>.toString)
#guard ["sampling_gap", "window_truncated", "absent_atom"].all fun o => whys.count o > 30

-- ---------------------------------------------------------------------------------------------
-- B. Through the language: φ a state formula over two declarations of the scene, `a` and `b`
-- (`.and`), a window `p.window`, a step `p.step` and a bound `p.bound` from the reading, compared
-- by `gt`. Times in seconds.
-- ---------------------------------------------------------------------------------------------
structure Row where
  t : Int
  a : Option Bool := some true
  b : Option Bool := some true

def sceneOf (r : Row) : Scene :=
  { t := r.t * 1000, subject := some 1, users := [{ track := 1, classes := some [.motorVehicle] }],
    assumptions := (match r.a with | some x => [("asm.a", x)] | none => []) ++ (match r.b with | some x => [("asm.b", x)] | none => []) }

def ρ (window step bound : Q) : Reading :=
  { params := [{ name := "p.window", value := window, unit := .second }, { name := "p.step", value := step, unit := .second },
               { name := "p.bound", value := bound, unit := .second }] }
def φab : Formula := .and (.asm "asm.a") (.asm "asm.b")
def dw (φ : Formula := φab) (op : CmpOp := .gt) : Formula :=
  .durationWithin (.param "p.window") (.param "p.step") φ op (.param "p.bound")

def ctxOf (rows : List Row) (window step bound : Q) : SemCtx := SemCtx.mk' (rows.map sceneOf) (ρ window step bound)
def show_ (r : R) : String := match r.v with
  | .t => "t" | .f => "f" | .u => "u:" ++ ",".intercalate (r.why.map (·.tag))
/-- The verdict at the observation at time `at_` (seconds). -/
def verdictAt (rows : List Row) (at_ : Int) (window step bound : Q) (φ : Formula := φab) : String :=
  match rows.findIdx? (·.t == at_) with
  | some i => show_ ((evalAll (ctxOf rows window step bound) (dw φ))[i]!)
  | none => "no observation"
/-- The bounds (lower, upper) at the observation at time `at_`. -/
def boundsAt (rows : List Row) (at_ : Int) (window step : Q) (φ : Formula := φab) : Rat × Rat :=
  let c := ctxOf rows window step Q.zero
  let i := (rows.findIdx? (·.t == at_)).getD 0
  let b := (boundsAll c.d.times window step OP (evalAll c φ))[i]!
  (b.lower.val, b.upper.val)

def H : Q := Q.ofInt 3600
def S : Q := Q.ofInt 15
def B : Q := Q.ofInt 1800
/-- Samples every 10 s from `a` to `b` (seconds), each with the values `f` gives. -/
def every10 (a b : Int) (f : Int → Row → Row) : List Row :=
  (List.range ((b - a).toNat / 10 + 1)).map fun k => let t := a + 10 * Int.ofNat k; f t { t }
def held (va vb : Bool) : Row → Row := fun r => { r with a := some va, b := some vb }

-- An a∧b case: both true up to 1700 s; at 1710 `a` still true, `b` false; then both false to
-- 3000 s; the next sample only at 3200 s (200 s > step), with `a` false and `b` true, φ false at
-- both ends of that interval; then φ false to 3600 s. The wide interval counts toward the upper
-- bound only: 1700 ≤ held ≤ 1900, around the bound: unknown, for the sampling gap.
def t1 : List Row :=
  every10 0 1700 (fun t r => if t == 0 then held false false r else held true true r) ++
  every10 1710 1710 (fun _ => held true false) ++ every10 1720 3000 (fun _ => held false false) ++
  every10 3200 3600 (fun _ => held false true)
#guard boundsAt t1 3600 H S = (1700, 1900)
#guard verdictAt t1 3600 H S B = "u:sampling_gap:duration_within"
-- the same samples with a step that admits the 200 s interval: the samples show 1700 s, compliant.
-- This is the sampled reading the mark discloses: between 3000 s and 3200 s φ may have held.
#guard boundsAt t1 3600 H (Q.ofInt 200) = (1700, 1700)
#guard verdictAt t1 3600 H (Q.ofInt 200) B = "f"
-- an interval exactly the step is integrated; one just over it is not
#guard boundsAt t1 3600 H (Q.ofInt 199) = (1700, 1900)

-- Unknown samples count toward the upper bound only, with their reasons.
def unk : List Row :=
  every10 0 3000 (fun t r => if t == 1000 then { r with a := none, b := some true } else held false false r) ++
  every10 3010 3600 (fun _ => held true true)
#guard boundsAt unk 3600 H S = (600, 610)
#guard verdictAt unk 3600 H S B = "f"
#guard verdictAt unk 3600 H S (Q.ofInt 605) = "u:assumption_missing:asm.a"
-- an unknown sample decides nothing on its own: it widens the range by its interval
#guard verdictAt unk 3600 H S (Q.ofInt 599) = "t"

-- Wide intervals: an interval longer than the step counts toward the upper bound only, whatever φ
-- is at its end.
def wide (v : Bool) : List Row := [{ t := 0, a := some v }, { t := 100, a := some v }] ++ every10 110 200 (fun _ => held v true)
#guard boundsAt (wide true) 200 (Q.ofInt 200) S = (100, 200)
#guard boundsAt (wide false) 200 (Q.ofInt 200) S = (0, 100)
#guard verdictAt (wide true) 200 (Q.ofInt 200) S (Q.ofInt 150) = "u:sampling_gap:duration_within"

-- Windows that reach before the first observation: that part counts toward the upper bound only.
-- φ true from the first observation to 1500 s; at 1500 s the held time is 1500 to 3600: unknown.
def t3a : List Row := every10 0 1500 (fun _ => held true true)
#guard boundsAt t3a 1500 H S = (1500, 3600)
#guard verdictAt t3a 1500 H S B = "u:window_truncated:duration_within"
-- the same to 1900 s: more than the bound however the earlier part went: violated
def t3b : List Row := every10 0 1900 (fun _ => held true true)
#guard boundsAt t3b 1900 H S = (1900, 3600)
#guard verdictAt t3b 1900 H S B = "t"
-- φ false to 3000 s, then true: at 2000 s at most the 1600 s before the trace: compliant;
-- at 3600 s exactly 600 s
def t3c : List Row := every10 0 3000 (fun _ => held false false) ++ every10 3010 3600 (fun _ => held true true)
#guard boundsAt t3c 2000 H S = (0, 1600)
#guard verdictAt t3c 2000 H S B = "f"
#guard boundsAt t3c 3600 H S = (600, 600)
#guard verdictAt t3c 3600 H S B = "f"
-- φ true from the start to 100 s, then false: at 1000 s up to 2600 + 100 s: unknown
def t3d : List Row := every10 0 100 (fun _ => held true true) ++ every10 110 1000 (fun _ => held false false)
#guard boundsAt t3d 1000 H S = (100, 2700)
#guard verdictAt t3d 1000 H S B = "u:window_truncated:duration_within"
-- a window starting inside an interval counts the part of it inside the window
#guard boundsAt t3c 3600 (Q.ofInt 595) S = (595, 595)
#guard boundsAt t3c 3600 (Q.mk' 1191 2) S = ((1191 : Rat) / 2, (1191 : Rat) / 2)
-- the first observation stands for nothing: a trace of one observation holds nothing, and the
-- whole window is before it
#guard boundsAt [{ t := 0 }] 0 H S = (0, 3600)

-- Exactly the bound is not more than it: compliant; just over it: violated.
def exact (n : Int) : List Row := every10 0 3600 (fun t r => if t ≥ 10 && t ≤ n then held true true r else held false false r)
#guard boundsAt (exact 1800) 3600 H S = (1800, 1800)
#guard verdictAt (exact 1800) 3600 H S B = "f"
#guard verdictAt (exact 1810) 3600 H S B = "t"

-- The other comparisons decide on the range alike (only `gt` passes the static check).
#guard show_ ((evalAll (ctxOf (exact 1800) H S B) (dw φab .ge))[360]!) = "t"
#guard show_ ((evalAll (ctxOf (exact 1800) H S B) (dw φab .eq))[360]!) = "t"
#guard show_ ((evalAll (ctxOf (exact 1800) H S B) (dw φab .lt))[360]!) = "f"
#guard show_ ((evalAll (ctxOf t1 H S B) (dw φab .le))[t1.length - 1]!) = "u:sampling_gap:duration_within"

-- A window or a step not positive: malformed everywhere; a missing parameter: unknown everywhere.
def NP : String := "u:malformed:duration_within window or step bound is not positive"
#guard (evalAll (ctxOf t3c H Q.zero B) (dw)).toList.all (show_ · == NP)
#guard (evalAll (ctxOf t3c Q.zero S B) (dw)).toList.all (show_ · == NP)
#guard (evalAll (SemCtx.mk' (t3c.map sceneOf) {}) (dw)).toList.all (show_ · == "u:parameter_missing:p.window")

-- The cached evaluator agrees.
#guard [t1, unk, wide true, t3a, t3b, t3c, t3d, exact 1800].all fun rows =>
  let c := ctxOf rows H S B
  (evalAll c (dw)).toList.map show_ == (evalFastAll c (dw)).toList.map show_

-- ---------------------------------------------------------------------------------------------
-- C. Agreement with `Accumulate.integral`: where the window starts at an observation and every
-- interval in it is within the step with φ known, both bounds are the integral of φ's indicator.
-- ---------------------------------------------------------------------------------------------
#guard (List.range 20).all fun seed =>
  let c := gen seed
  let vals := c.vals.map fun r => if r.v == .u then R.f else r
  let times := (Array.range 30).map fun k => Q.ofInt (Int.ofNat (10 * k))
  (List.range 30).all fun i => (List.range (i + 1)).all fun j =>
    let w := Q.ofInt (Int.ofNat (10 * (i - j)))
    let rate := vals.map fun r => some (if r.v == .t then Q.ofInt 1 else Q.zero)
    let b := (boundsAll times w (Q.ofInt 10) OP vals)[i]!
    Accumulate.integral times rate j i == some b.lower.val && Accumulate.integral times rate j i == some b.upper.val

-- ---------------------------------------------------------------------------------------------
-- D. The static check, units, export and decode.
-- ---------------------------------------------------------------------------------------------
def rOf (φ : Formula) : Rule :=
  { id := "t/dw", laws := [], binders := [{ name := "x", cls := .tt }], applicability := .tt, obligation := .not φ,
    assumptions := ["asm.a", "asm.b"] }
def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1
#guard Rule.check [] (rOf dw) = []
#guard has (Rule.check [] (rOf (dw φab .ge))) "duration_within compares by `gt` only"
#guard has (Rule.check [] (rOf (.durationWithin (.param "p.window") (.lit Q.zero .second) φab .gt (.param "p.bound"))))
  "duration_within step bound is not strictly positive"
#guard has (Rule.check [] (rOf (.durationWithin (.param "p.window") (.mul (.lit (Q.ofInt 2) .ratio) (.param "p.step")) φab .gt (.param "p.bound"))))
  "duration_within step bound is not a literal or a reading parameter"
#guard has (Rule.check [] (rOf (.durationWithin (.param "p.window") (.param "p.step") φab .gt (.measure "kin_speed" [.var "x"]))))
  "duration_within bound is not a constant term"
#guard has (Rule.check [] (rOf (.durationWithin (.measure "kin_speed" [.var "x"]) (.param "p.step") φab .gt (.param "p.bound"))))
  "window length is not a constant term"
#guard Formula.params (dw) = ["p.window", "p.step", "p.bound"]
#guard (Formula.atoms (dw)).contains "kin_time"
def env : DimEnv := DimCheck.envOf (ρ H S B) []
#guard DimCheck.errors env (dw) = []
#guard (DimCheck.errors env (.durationWithin (.param "p.window") (.lit (Q.ofInt 1) .metre) φab .gt (.param "p.bound"))).map DimError.tag = ["mismatch"]
#guard (DimCheck.errors env (.durationWithin (.param "p.window") (.param "p.step") φab .gt (.lit (Q.ofInt 1) .metre))).map DimError.tag = ["mismatch"]
#guard (DimCheck.errors env (.durationWithin (.lit (Q.ofInt 1) .metre) (.param "p.step") φab .gt (.param "p.bound"))).map DimError.tag = ["mismatch"]
#guard match Decode.formula "f" (Formula.toJson (dw)) with
  | .ok φ => (Formula.toJson φ).compress == (Formula.toJson (dw)).compress
  | .error _ => false
#guard ((rOf dw).toJson.compress.splitOn "\"sampled_duration\":true").length == 2
#guard ((rOf φab).toJson.compress.splitOn "\"sampled_duration\":false").length == 2

-- ---------------------------------------------------------------------------------------------
-- E. The mark: every verdict of a rule that reads `durationWithin`, itself, through a concept
-- call, a composition, a case or a rule-set operator, is marked `sampled_duration`; the monitor's
-- lines and JSON carry it. No law is named; the ids are test labels.
-- ---------------------------------------------------------------------------------------------
def X : Arg := .var "x"
def halted : Formula := .cmp (.measure "kin_speed" [X]) .le (.lit Q.zero .metrePerSecond)
def durRule : Rule :=
  { rOf dw with id := "t/dur", cases := [{ name := "halt_here", kind := .requires .halt, shown := halted }] }
def plain : Rule := { id := "t/plain", laws := [], binders := [{ name := "x", cls := .tt }], applicability := .tt, obligation := halted }
def viaRule : Rule := { plain with id := "t/via_rule", obligation := .rule "t/dur" [("x", "x")] }
def viaApplies : Rule := { plain with id := "t/via_applies", applicability := .ruleApplies "t/dur" [("x", "x")] }
def viaCase : Rule := { plain with id := "t/via_case", applicability := .not (.ruleCase "t/dur" "halt_here" [("x", "x")]) }
def viaRequired : Rule := { plain with id := "t/via_required", obligation := .or (.not halted) (.requiredBy .halt "x") }
def viaLawful : Rule := { plain with id := "t/via_lawful", obligation := .lawful .every "x" }
def viaTwo : Rule := { plain with id := "t/via_two", obligation := .rule "t/via_rule" [("x", "x")] }
def lib : List Rule := [durRule, plain, viaRule, viaApplies, viaCase, viaRequired, viaLawful, viaTwo]
#guard (lib.map fun r => (r.id, RuleSet.sampledDurationOf lib r)) =
  [("t/dur", true), ("t/plain", false), ("t/via_rule", true), ("t/via_applies", true), ("t/via_case", true),
   ("t/via_required", true), ("t/via_lawful", true), ("t/via_two", true)]
-- a rule-set operator over a library with no such rule is unmarked
#guard RuleSet.sampledDurationOf [plain, viaRequired, viaLawful] viaLawful = false
-- through a concept call: seen on the rule with its calls expanded, as the monitor reads it
def heldC : Concept :=
  { id := "drv.test.held_long", contract := "a state held for long in the window behind", args := [("x", .track)],
    params := [{ name := "w", unit := .second }, { name := "s", unit := .second }, { name := "b", unit := .second }],
    body := .formula (.durationWithin (.param "w") (.param "s") φab .gt (.param "b")) }
def viaConcept : Rule :=
  { plain with id := "t/via_concept", obligation := .not (.derived "drv_test_held_long" [X] [.param "p.window", .param "p.step", .param "p.bound"]) }
#guard RuleSet.sampledDurationOf [Concept.expandRule [heldC] viaConcept] (Concept.expandRule [heldC] viaConcept) = true

def rep : Monitor.Report :=
  match Monitor.check [durRule, plain, viaRule, viaLawful, viaConcept] (t3c.map sceneOf) (ρ H S B) (Manifest.full "t") [heldC] with
  | .ok r => r
  | .error _ => default
def text : List String := (Monitor.renderText rep).splitOn "\n"
#guard text.any fun l => l.startsWith "RULE\tt/dur\t" && l.endsWith "\tsampled_duration=true"
#guard text.any fun l => l.startsWith "RULE\tt/plain\t" && l.endsWith "\tsampled_duration=false"
#guard text.any fun l => l.startsWith "RULE\tt/via_rule\t" && l.endsWith "\tsampled_duration=true"
#guard text.any fun l => l.startsWith "RULE\tt/via_lawful\t" && l.endsWith "\tsampled_duration=true"
#guard text.any fun l => l.startsWith "RULE\tt/via_concept\tconcrete\t" && l.endsWith "\tsampled_duration=true"
#guard text.any fun l => l.startsWith "GROUND\tt/via_rule\t" && l.endsWith "\tsampled_duration=true"
#guard text.any fun l => l.startsWith "SUMMARY\tconcrete\trules=5\t" && l.endsWith "\tsampled_duration=4"
#guard ((Monitor.renderJsonLines rep).splitOn "\n").any fun l =>
  (l.splitOn "\"kind\":\"rule\"").length == 2 && (l.splitOn "\"rule\":\"t/via_rule\"").length == 2
    && (l.splitOn "\"sampled_duration\":true").length == 2 && (l.splitOn "\"partial_coverage\":false").length == 2
#guard ((Monitor.renderJsonLines rep).splitOn "\n").any fun l =>
  (l.splitOn "\"kind\":\"grounding\"").length == 2 && (l.splitOn "\"rule\":\"t/plain\"").length == 2
    && (l.splitOn "\"sampled_duration\":false").length == 2

-- ---------------------------------------------------------------------------------------------
-- F. The proofs use no axiom beyond Lean's own.
-- ---------------------------------------------------------------------------------------------
/-- info: 'TrafficSpec.SampledDuration.completion_within' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms completion_within
/-- info: 'TrafficSpec.SampledDuration.worst_at_observation' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms worst_at_observation
/-- info: 'TrafficSpec.SampledDuration.judged_at_observations' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms judged_at_observations
/-- info: 'TrafficSpec.SampledDuration.bounds_val' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms bounds_val
/-- info: 'TrafficSpec.SampledDuration.agrees_integral' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms agrees_integral
/-- info: 'TrafficSpec.Semantics.durationWithin_sound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms durationWithin_sound

end TrafficSpec.Tests.SampledDuration

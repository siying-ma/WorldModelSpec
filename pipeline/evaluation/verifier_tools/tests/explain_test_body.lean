-- The checks of the explain program, appended by `run_tests.sh` to the shipped `Explain.lean`
-- (its `main` renamed `explainCli`), so the functions under test are the shipped ones.
--
-- 1. Witnesses: every scenario of the packaged rules' witness files, set up by `prepare` as the CLI
--    sets it up. The scenario's expected episode verdict is reproduced; at every observation
--    `choose` picks, the report's verdict, applicability and obligation agree with the monitor's
--    evaluator, the choice follows its rule, the JSON round-trips, no text line holds a line break,
--    and every window lies inside the trace and contains its deciding observation.
-- 2. Windows on a hand-built trace, computed here by hand, including the Core's branches for a
--    window past the trace and a later unknown guard of `atLast`.
-- 3. The review's minimal counter-examples (design file §13.9): a track absent in the middle of
--    the trace (identity gap) on the whole trace, a composed rule registered with its dependency,
--    the values of a true conjunction, exact values that round alike, a fifth grounding, and one
--    margin pick per comparison.

namespace ExplainTest
open Explain

structure Tally where
  checks : Nat := 0
  fails : Array String := #[]
  notes : Array String := #[]

def Tally.check (t : Tally) (ok : Bool) (msg : String) : Tally :=
  { t with checks := t.checks + 1, fails := if ok then t.fails else t.fails.push msg }

def Tally.note (t : Tally) (s : String) : Tally := { t with notes := t.notes.push s }

def runEM {α} (x : EM α) : α := Id.run (x.run' {})

partial def winsOf : Item → List (Win × R)
  | .node v _ _ w _ _ ch => (match w with | some x => [(x, v)] | none => []) ++ ch.flatMap winsOf
  | .member _ _ b => winsOf b
  | .other .. => []

def rootTri : Item → Option Tri | .node v .. => some v.v | _ => none

def checkWindow (t : Tally) (where_ : String) (w : Win) : Tally :=
  let t := match w.fromMs, w.toMs with
    | some a, some b => t.check (a ≤ b) s!"{where_}: window {w.op} from {a} after to {b}"
    | _, _ => t
  match w.fromMs, w.toMs, w.decidedAtMs with
  | some a, some b, some d => t.check (a ≤ d && d ≤ b) s!"{where_}: {w.op} decided at {d}, outside {a}…{b}"
  | _, _, _ => t

def scenario (t0 : Tally) (ρ : Reading) (shown : List String) (sc : Scenario) : Tally := Id.run do
  let (S, r, _) ← match prepare allRules allConcepts sc.rule sc.trace ρ sc.manifest with
    | .ok x => pure x
    | .error e => return t0.check false s!"{sc.name}: {e}"
  let g : Grounding := ⟨sc.grounding.map (fun (n, t) => (n, canon S.cm t)), sc.regions⟩
  let tl := Grounding.timeline S r g
  let rows := tl.toList.filter fun (t, _) => match sc.window with | some (a, b) => a ≤ t && t ≤ b | none => true
  let ep := (Grounding.episode (rows.map (·.2))).tag
  let mut t := t0.check (ep == sc.expected.tag) s!"{sc.rule}/{sc.name}: episode {ep}, the witness expects {sc.expected.tag}"
  let c := S.ctx g.binding
  let eng := r.engagedAll c
  let tag (i : Nat) := ((tl[i]?).map (·.2.tag)).getD ""
  let n := tl.size
  let chosen : List (Nat × String) × List String := runEM (choose S r g tl 3)
  let picks := chosen.1
  let choiceNotes := chosen.2
  t := t.check (!picks.isEmpty) s!"{sc.rule}/{sc.name}: no observation chosen"
  t := t.check ((picks.map (·.1)).eraseDups.length == picks.length) s!"{sc.rule}/{sc.name}: an observation chosen twice"
  let anyViol := (List.range n).any (tag · == "violated")
  let engagedIdx := (List.range n).filter fun i => (eng[i]?.map (·.v == .t)).getD false && tag i != "not_applicable"
  let kind := if anyViol then "violated" else if !engagedIdx.isEmpty then "engaged" else "never engaged"
  for (i, why) in picks do
    let w := s!"{sc.rule}/{sc.name}@{i}"
    if anyViol then
      t := t.check (tag i == "violated" && (i == 0 || tag (i - 1) != "violated")) s!"{w}: a violated pick that does not open a violated interval"
    else if !engagedIdx.isEmpty then
      t := t.check (engagedIdx.contains i) s!"{w}: picked an observation at which the rule is not engaged"
    else
      t := t.check (why.startsWith "never engaged") s!"{w}: never engaged, but chosen because '{why}'"
    let rp : Report := runEM (report S r g tl i why)
    t := t.check (rp.verdict.tag == tag i) s!"{w}: report verdict {rp.verdict.tag}, monitor {tag i}"
    t := t.check (rootTri rp.obligation == some (Rule.evalRuleFormula c r.obligation)[i]!.v) s!"{w}: obligation tree root disagrees with the evaluator"
    t := t.check (rootTri rp.applicability == some (Rule.evalRuleFormula c r.applicability)[i]!.v) s!"{w}: applicability tree root disagrees with the evaluator"
    t := t.check (rp.applies.v == ((eng[i]?).map (·.v)).getD .u) s!"{w}: applies disagrees with engagedAll"
    let j := reportJson r.id g rp
    t := match Lean.Json.parse j.compress with
      | .ok j' => t.check ((j'.getObjValAs? String "verdict").toOption == some (tag i)) s!"{w}: JSON verdict lost in the round trip"
      | .error e => t.check false s!"{w}: JSON does not parse back: {e}"
    let text := reportText r.id g rp
    t := t.check (text.all fun l => !l.contains '\n') s!"{w}: a text line holds a line break"
    t := t.check (decide (((text.head?.getD "").splitOn s!"verdict {tag i}").length > 1)) s!"{w}: text header lacks the verdict"
    if shown.contains s!"{sc.rule}/{sc.name}" then
      t := { t with notes := t.notes ++ (text.map (s!"  | " ++ ·)).toArray }
    for (x, _) in winsOf rp.obligation ++ winsOf rp.applicability do
      t := checkWindow t w x
    t := t.note s!"{sc.rule}/{sc.name}: expected {sc.expected.tag}, {kind}, chose t={rp.t} ({why.take 50}), windows {(winsOf rp.obligation ++ winsOf rp.applicability).map (·.1.op)}, notes {choiceNotes}"
  return t

-- ---------------------------------------------------------------------------------------------
-- Hand-built traces: one car, observations every second
-- ---------------------------------------------------------------------------------------------
def car (track : Nat) (k : Nat) (speed : Option Int) : RoadUser :=
  let u := Build.user track [.motorVehicle] (Q.ofInt (10 * k), Q.ofInt (5 * track)) Build.east
    (Units.metresPerSecond (speed.getD 0)) (Q.ofInt 2, Q.ofInt 1, Q.ofInt 1)
  match speed with
  | some _ => u
  | none => { u with kin := { u.kin with speed := none, velocity := none } }

def traceOf (speeds : List (Option Int)) : Trace :=
  Build.trace speeds.length 0 (Units.seconds 1) fun k t => Build.scene t (some 1) [car 1 k speeds[k]!] [] []

/-- speed 12 m/s at t = 3 s and 4 s, 5 m/s otherwise, t = 0 … 10 s. -/
def trace1 : Trace := traceOf ([5, 5, 5, 12, 12, 5, 5, 5, 5, 5, 5].map some)
/-- speed 12 m/s at t = 0, unknown at t = 1 s, 5 m/s afterwards. -/
def trace2 : Trace := traceOf [some 12, none, some 5, some 5, some 5]

def fast : Formula := .cmp (.measure "kin_speed" [.var "veh"]) .gt (.lit (Units.metresPerSecond 10) .metrePerSecond)
def secs (n : Int) : Term := .lit (Units.seconds n) .second
def lit (q : Q) : Term := .lit q .ratio

def ruleWith (id : String) (obl : Formula) : Rule :=
  { id, laws := [], binders := [{ name := "veh", cls := .tt }], applicability := .tt, obligation := obl }

def setupOf (rules : List Rule) (rid : String) (τ : Trace) : Except String (Setup × Rule × Support) :=
  prepare rules [] rid τ {} (Build.manifest [])

/-- (name, trace, formula, observation, expected value, expected window from, to, decided at). -/
def windowCases : List (String × Trace × Formula × Nat × Tri × Option Int × Option Int × Option Int) :=
  [ ("holdsFor fails at its first fast observation", trace1, .holdsFor .time (secs 3) "veh" (.not fast), 6, .f, some 3000, some 6000, some 3000)
  , ("holdsFor truncated at the trace start", trace1, .holdsFor .time (secs 3) "veh" (.not fast), 1, .u, some 0, some 1000, none)
  , ("holdsFor not covered at t=2 s: truncated, though the operand holds", trace1, .holdsFor .time (secs 3) "veh" (.not fast), 2, .u, some 0, some 2000, none)
  , ("within finds the first fast observation ahead", trace1, .within .time (secs 3) "veh" fast, 1, .t, some 1000, some 4000, some 3000)
  , ("within past the trace end: truncated", trace1, .within .time (secs 3) "veh" fast, 9, .u, some 9000, some 10000, none)
  , ("untilWithin reaches its goal", trace1, .untilWithin .time (secs 3) "veh" (.not fast) fast, 1, .t, some 1000, some 4000, some 3000)
  , ("atLast reads the last fast observation", trace1, .atLast .time (secs 5) "veh" fast (.not fast), 7, .f, some 2000, some 7000, some 4000)
  , ("atLast: a later unknown guard decides, not the earlier true one", trace2, .atLast .time (secs 10) "veh" fast .tt, 1, .u, some 0, some 1000, some 1000)
  , ("since finds the latest right operand", trace1, .since (.not fast) fast, 8, .t, some 4000, some 8000, some 4000)
  , ("since unknown before any right operand", trace1, .since (.not fast) fast, 2, .u, some 0, some 2000, none)
  , ("rises reads the previous observation", trace1, .rises fast, 3, .t, some 2000, some 3000, some 2000)
  , ("rises: the operand false here decides", trace1, .rises fast, 0, .f, none, some 0, some 0) ]

def windows (t0 : Tally) : Tally := Id.run do
  let mut t := t0
  for (name, τ, φ, i, v, a, b, d) in windowCases do
    match setupOf [ruleWith "w" .tt] "w" τ with
    | .error e => t := t.check false s!"{name}: {e}"
    | .ok (S, _, _) =>
      let c := S.ctx ⟨[("veh", Val.track 1)]⟩
      match runEM (build c i φ 1) with
      | .node val _ _ (some w) _ _ _ =>
        t := t.check (val.v == v) s!"{name}: value {triStr val.v}, expected {triStr v}"
        t := t.check (w.fromMs == a && w.toMs == b) s!"{name}: window {w.fromMs}…{w.toMs}, expected {a}…{b}"
        t := t.check (w.decidedAtMs == d) s!"{name}: decided at {w.decidedAtMs}, expected {d} ({w.how})"
        t := t.note s!"window/{name}: {winLine w}"
      | _ => t := t.check false s!"{name}: no window reported"
  return t

-- ---------------------------------------------------------------------------------------------
-- The review's counter-examples
-- ---------------------------------------------------------------------------------------------
def firstGrounding (S : Setup) (r : Rule) : Option (Grounding × Array (Timestamp × Verdict) × Verdict) :=
  (selectGroundings S r [] none).1.head?

def identityGap (t : Tally) : Tally :=
  -- a track present at 0 and 2 s, absent at 1 s: on the whole trace that instant is an identity gap
  -- (unknown); the trace cut after 1 s (the earlier `--at` cut) made it not applicable
  let gapTrace : Trace := [Build.scene 0 (some 1) [car 1 0 (some 5)] [] [], Build.scene 1000 (some 1) [] [] [],
                           Build.scene 2000 (some 1) [car 1 2 (some 5)] [] []]
  match setupOf [ruleWith "gap" .tt] "gap" gapTrace, setupOf [ruleWith "gap" .tt] "gap" (gapTrace.filter (·.t ≤ 1000)) with
  | .ok (S, r, _), .ok (S', r', _) =>
    match firstGrounding S r, firstGrounding S' r' with
    | some (g, tl, _), some (_, tl', _) =>
      let rp : Report := runEM (report S r g tl 1)
      let cutTag := ((tl'[1]?).map (·.2.tag)).getD "?"
      let t := t.check (rp.verdict.tag == "unknown" && (rp.verdict.reasons.map UnknownReason.tag).any (·.startsWith "identity_gap"))
        s!"identity gap: the report at t=1 s is {rp.verdict.tag} {(rp.verdict.reasons.map UnknownReason.tag)}, expected unknown (identity_gap)"
      let t := t.check (cutTag == "not_applicable") "identity gap: the cut trace no longer differs (the counter-example is gone)"
      t.note s!"identity gap: whole trace {rp.verdict.tag} {(rp.verdict.reasons.map UnknownReason.tag)}, cut trace {cutTag}"
    | _, _ => t.check false "identity gap: no grounding"
  | _, _ => t.check false "identity gap: not admitted"

def composition (t : Tally) : Tally :=
  -- a rule composing another: registered with its closure the composition decides (false);
  -- registered alone it is unknown
  let dep := ruleWith "dep" .ff
  let caller := ruleWith "caller" (.rule "dep" [("veh", "veh")])
  match setupOf [caller, dep] "caller" trace1 with
  | .ok (S, r, _) =>
    match firstGrounding S r with
    | some (g, tl, _) =>
      let rp : Report := runEM (report S r g tl 0)
      let t := t.check (rootTri rp.obligation == some .f && rp.verdict.tag == "violated")
        s!"composition: obligation {(rootTri rp.obligation).map triStr}, verdict {rp.verdict.tag}; expected false, violated"
      let alone : Tri := match Setup.admit [caller] trace1 {} Q.zero with
        | .ok S1 => (Rule.evalRuleFormula (S1.ctx g.binding) caller.obligation)[0]!.v
        | .error _ => .t
      let t := t.check (alone == .u) "composition: registered alone the caller is no longer unknown (the counter-example is gone)"
      t.note s!"composition: with its closure {(rootTri rp.obligation).map triStr}, alone {triStr alone}"
    | none => t.check false "composition: no grounding"
  | .error e => t.check false s!"composition: {e}"

def trueConjunction (t : Tally) : Tally :=
  -- the diagnosis tree does not open a true conjunction; `allValues` lists both comparisons exactly
  let conjRule := ruleWith "conj" (.and (.cmp (lit (Q.ofInt 1)) .le (lit (Q.ofInt 2))) (.cmp (lit (Q.ofInt 3)) .le (lit (Q.ofInt 4))))
  match setupOf [conjRule] "conj" trace1 with
  | .ok (S, r, _) =>
    match firstGrounding S r with
    | some (g, tl, _) =>
      let rp : Report := runEM (report S r g tl 0)
      let res : List Value × Bool := runEM (allValues S r g 0)
      let vs := res.1
      let closed := match rp.obligation with | .node _ _ _ _ _ _ ch => ch.isEmpty | _ => false
      let t := t.check closed "true conjunction: the diagnosis tree should stay closed"
      let t := t.check (vs.length == 2 && !res.2) s!"true conjunction: {vs.length} values, expected 2"
      t.check ((vs.map fun x => (x.path, x.cmp.lhs.value.map qNorm, x.cmp.rhs.value.map qNorm, triStr x.value.v)) ==
                 [("obligation.0", some (1, 1), some (2, 1), "true"), ("obligation.1", some (3, 1), some (4, 1), "true")])
        "true conjunction: the values are wrong"
    | none => t.check false "true conjunction: no grounding"
  | .error e => t.check false s!"true conjunction: {e}"

def exactValues (t : Tally) : Tally :=
  let q1 := Q.mk' 10001 10000
  let q2 := Q.mk' 10002 10000
  t.check (qStr q1 == qStr q2 && qNorm q1 != qNorm q2 && (qJson q1).compress != (qJson q2).compress)
    s!"exact values: {qStr q1} {qStr q2} {(qJson q1).compress} {(qJson q2).compress}"

def fiveGroundings (t : Tally) : Tally :=
  -- five vehicles, the fifth too fast: every grounding is selected unless a cap is asked for
  let five : Trace := Build.trace 3 0 (Units.seconds 1) fun k tt =>
    Build.scene tt none ((List.range 5).map fun j => car (j + 1) k (some (if j == 4 then 12 else 5))) [] []
  match setupOf [ruleWith "five" (.not fast)] "five" five with
  | .ok (S, r, _) =>
    let (all, total) := selectGroundings S r [] none
    let (capped, total') := selectGroundings S r [] (some 4)
    let violatedOf (xs : List (Grounding × Array (Timestamp × Verdict) × Verdict)) : Nat :=
      (xs.filter fun x => x.2.2 == .violated).length
    let t := t.check (all.length == 5 && total == 5 && violatedOf all == 1) s!"groundings: {all.length} of {total}, {violatedOf all} violated"
    t.check (capped.length == 4 && total' == 5) "groundings: an explicit cap does not report the total"
  | .error e => t.check false s!"groundings: {e}"

def margins (t : Tally) : Tally :=
  -- one margin pick per comparison. The 4 s window behind is truncated before t = 4 s (the first
  -- unknown observation is t = 0); among the compliant observations t = 4 … 10 s, speed ≤ 20 is
  -- closest at the fastest (t = 4 s, 12 m/s) and speed ≥ 1 at the first slow one (t = 5 s, 5 m/s);
  -- the comparison under the temporal operator is counted as not searched
  let sp : Term := .measure "kin_speed" [.var "veh"]
  let mps (n : Int) : Term := .lit (Units.metresPerSecond n) .metrePerSecond
  let two := ruleWith "two" (.and (.cmp sp .le (mps 20)) (.and (.cmp sp .ge (mps 1)) (.holdsFor .time (secs 4) "veh" (.not (.cmp sp .gt (mps 50))))))
  match setupOf [two] "two" trace1 with
  | .ok (S, r, _) =>
    match firstGrounding S r with
    | some (g, tl, _) =>
      let res : List (Nat × String) × List String := runEM (choose S r g tl 3)
      let idx := res.1.map (·.1)
      let t := t.check (idx == [0, 4, 5]) s!"margins: picks {idx}, expected [0, 4, 5] (first unknown, closest to ≤ 20, closest to ≥ 1)"
      let t := t.check (res.2.any (·.startsWith "comparisons not searched")) s!"margins: the comparison under holdsFor is not counted: {res.2}"
      t.note s!"margins: picks {idx}; notes {res.2}"
    | none => t.check false "margins: no grounding"
  | .error e => t.check false s!"margins: {e}"

end ExplainTest

open ExplainTest in
def main (args : List String) : IO UInt32 := do
  let some rp := args.head? | IO.eprintln "explaintest READING.json"; return 2
  let ρ ← match Decode.parse Decode.reading (← IO.FS.readFile rp) with
    | .ok v => pure v
    | .error e => IO.eprintln s!"{rp}: {e}"; return 2
  let shown := ((← IO.getEnv "SHOW").getD "").splitOn "," |>.filter (· != "")
  let mut t : Tally := {}
  let sets : List (String × List Scenario) :=
    [ ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios)
    , ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios)
    , ("NRS_484A_450_2", TrafficSpecWitness.NRS_484A_450_2.scenarios) ]
  for (_, scs) in sets do
    for sc in scs do
      t := scenario t ρ shown sc
  t := windows t
  t := identityGap t
  t := composition t
  t := trueConjunction t
  t := exactValues t
  t := fiveGroundings t
  t := margins t
  for n in t.notes do IO.println n
  IO.println s!"checks: {t.checks}, failures: {t.fails.size}"
  for f in t.fails do IO.println s!"FAIL {f}"
  return (if t.fails.isEmpty then 0 else 1)

import TrafficSpec.Core.Language.RuleEval
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Runtime.Grounding
import TrafficSpec.Core.Runtime.Manifest
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Tests.EvalFast
namespace TrafficSpec.Tests.HeadingSince
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Accumulate Lean

-- ---------------------------------------------------------------------------------------------
-- A. The operator against a direct computation written without `runStartAll`, `runs` or `Q`
-- prefix sums: a walk back from each observation to its start, then a separate pass over the
-- observations since, summed in `Rat`. Same value (in `Rat`), same reason.
-- ---------------------------------------------------------------------------------------------
def OP : String := "heading_since"
def MISS : UnknownReason := .absentAtom "kin_yaw_rate"

def naiveStart (ψ : Array R) (i : Nat) : Except UnknownReason Nat := Id.run do
  let mut k := i
  for _ in [0:i + 1] do
    match ψ[k]!.v with
    | .u => return .error (ψ[k]!.why.head?.getD (.malformed OP))
    | .f => if k = 0 then return .error (.windowTruncated OP) else k := k - 1
    | .t =>
      if k = 0 then return .error (.windowTruncated OP)
      match ψ[k - 1]!.v with
      | .f => return .ok k
      | .u => return .error (ψ[k - 1]!.why.head?.getD (.malformed OP))
      | .t => k := k - 1
  return .error (.windowTruncated OP)

def naive (times : Array Q) (rate : Array (Option Q)) (g : Q) (ψ : Array R) (i : Nat) : Except UnknownReason Rat :=
  if !decide (0 < g.val) then .error (.malformed s!"{OP} step bound is not positive") else
  match naiveStart ψ i with
  | .error e => .error e
  | .ok j =>
    let ks := (List.range (i + 1)).filter (j ≤ ·)
    let gap (k : Nat) : Rat := times[k]!.val - times[k - 1]!.val
    if ks.any (fun k => decide (gap k > g.val)) then .error (.samplingGap OP)
    else
      let since := ks.filter (j < ·)
      if since.any (fun k => (rate[k]!).isNone) then .error MISS
      else .ok (since.foldl (fun acc k => acc + ((rate[k]!).getD Q.zero).val * gap k) 0)

def agreeAt (F : Array QR) (N : Except UnknownReason Rat) (i : Nat) : Bool :=
  match F[i]!, N with
  | .ok q, .ok r => q.val == r
  | .error e, .error e' => e == e'
  | _, _ => false

def lcg (s : Nat) : Nat := (s * 1103515245 + 12345) % 2147483648
def pick {α : Type} [Inhabited α] (xs : List α) (s : Nat) : α := xs[(s / 65536) % xs.length]!

structure Gen where
  times : Array Q
  rate : Array (Option Q)
  ψ : Array R
  g : Q

/-- A case of 30 observations: ψ drawn from {t, f, u} (unknown with one of three reasons, rarer in
    the second half of the seeds), rates positive, negative, zero or missing, intervals from 0.1 s to
    1.5 s, and a step bound mostly positive, sometimes zero or negative. -/
def gen (seed : Nat) : Gen := Id.run do
  let mut s := lcg (seed + 7)
  let mut t : Q := Q.zero
  let mut times : Array Q := #[]
  let mut rate : Array (Option Q) := #[]
  let mut ψ : Array R := #[]
  let unk := if seed < 250 then 7 else 21
  for k in [0:30] do
    s := lcg s
    let p := (s / 65536) % unk
    ψ := ψ.push (if p < 3 then R.f else if p < 6 then R.t else if p == 6 then R.u (.absentAtom s!"psi{k % 3}") else R.t)
    s := lcg s
    rate := rate.push (pick [some (Q.mk' 25 2), some (Q.ofInt (-7)), some Q.zero, none, some (Q.mk' (-3) 4), some (Q.ofInt 30)] s)
    s := lcg s
    if k > 0 then t := Q.add t (pick [Q.mk' 1 10, Q.mk' 1 5, Q.mk' 1 2, Q.ofInt 1, Q.mk' 3 2, Q.mk' 1 10] s)
    times := times.push t
  let g := pick [Q.mk' 1 2, Q.ofInt 1, Q.ofInt 2, Q.ofInt 1, Q.mk' 3 10, Q.zero, Q.ofInt (-1), Q.ofInt 1] (lcg (seed * 31 + 3))
  return { times, rate, ψ, g }

def outcomes (seed : Nat) : List String :=
  let c := gen seed
  let F := sinceRiseIntegralAll c.times c.rate c.g OP MISS c.ψ
  (List.range 30).map fun i => match F[i]! with
    | .ok _ => "value" | .error e => e.tag.takeWhile (· != ':') |>.toString

#guard (List.range 500).all fun seed =>
  let c := gen seed
  let F := sinceRiseIntegralAll c.times c.rate c.g OP MISS c.ψ
  F.size == 30 && (List.range 30).all fun i => agreeAt F (naive c.times c.rate c.g c.ψ i) i
-- the cases reach every outcome, each many times
def tally : List String := (List.range 500).flatMap outcomes
#guard ["value", "sampling_gap", "absent_atom", "window_truncated", "malformed"].all fun o => tally.count o > 200
#guard tally.count "value" > 2000

-- ---------------------------------------------------------------------------------------------
-- B. Named scenarios through the language: one road user, the onset an assumption of the scene
-- (true, false, or missing: unknown), the step bound the reading parameter `p.step`.
-- ---------------------------------------------------------------------------------------------
structure Row where
  t : Int
  yaw : Option Int := some 10
  on : Option Bool := some true
  present : Bool := true
  speed : Int := 5
  track : Nat := 1
  links : List (TrackId × TrackId) := []

def sceneOf (r : Row) : Scene :=
  { t := r.t, subject := some r.track,
    users := if r.present then [{ track := r.track, classes := some [.motorVehicle],
                                   kin := { yawRate := r.yaw.map degrees, speed := some (metresPerSecond r.speed) } }] else [],
    assumptions := match r.on with | some b => [("asm.onset", b)] | none => [],
    links := r.links }

def X : Arg := .var "x"
def onset : Formula := .asm "asm.onset"
def ρs (step : Q) : Reading := { params := [{ name := "p.step", value := step, unit := .second }] }
def βx : Binding := ({} : Binding).bind "x" (.track 1)
def hs (step : Term := .param "p.step") (ψ : Formula := onset) (s : String := "x") : Term := .headingSince s step ψ
def deg0 : Term := .lit Q.zero .degree

def show_ : QR → String
  | .ok q => let r := Q.mk' q.num q.den; if r.den == 1 then toString r.num else s!"{r.num}/{r.den}"
  | .error e => e.tag

def ctxOf (rows : List Row) (step : Q := Q.ofInt 1) (β : Binding := βx) : SemCtx := SemCtx.mk' (rows.map sceneOf) (ρs step) β
def run (rows : List Row) (t : Term := hs) (step : Q := Q.ofInt 1) (β : Binding := βx) : List String :=
  (evalTAll (ctxOf rows step β) t).toList.map show_
def every (n : Nat) (f : Nat → Row) : List Row := (List.range n).map f
def ints (xs : List Int) : List String := xs.map toString
def TR : String := "window_truncated:heading_since"
def GAP : String := "sampling_gap:heading_since"
def ABS : String := "absent_atom:kin_yaw_rate"
def ASM : String := "assumption_missing:asm.onset"

-- a left turn at +10°/s, sampled at 100 ms, onset at 100 ms: zero there, +1° per observation
def left : List Row := every 31 fun k => { t := k * 100, on := some (k ≥ 1) }
#guard run left = TR :: ints ((List.range 30).map Int.ofNat)
-- a right turn: negative
def right : List Row := every 31 fun k => { t := k * 100, yaw := some (-10), on := some (k ≥ 1) }
#guard run right = TR :: ints ((List.range 30).map fun k => -Int.ofNat k)
-- a stop mid-turn (yaw zero, ψ still true): the angle stays, then grows again
def stop : List Row := every 21 fun k =>
  { t := k * 100, on := some (k ≥ 1), yaw := some (if k ≥ 11 && k ≤ 15 then 0 else 10), speed := if k ≥ 11 && k ≤ 15 then 0 else 5 }
#guard run stop = TR :: ints ((List.range 20).map fun m => let k := m + 1; if k ≤ 10 then Int.ofNat k - 1 else if k ≤ 15 then 9 else Int.ofNat k - 6)
-- ψ turns false mid-act: the start persists
def falls : List Row := every 21 fun k => { t := k * 100, on := some (k ≥ 1 && k ≤ 5) }
#guard run falls = TR :: ints ((List.range 20).map Int.ofNat)
-- a three-point manoeuvre: one rise gives the net angle over the legs; a rise per leg resets per leg
def legYaw (k : Nat) : Int := if k ≤ 10 then 20 else if k ≤ 20 then -20 else 20
def three (on : Nat → Bool) : List Row := every 31 fun k => { t := k * 100, yaw := some (legYaw k), on := some (on k) }
#guard (run (three (· ≥ 1)))[10]! = "18" ∧ (run (three (· ≥ 1)))[20]! = "-2" ∧ (run (three (· ≥ 1)))[30]! = "18"
def perLeg (k : Nat) : Bool := k != 0 && k != 10 && k != 20
#guard (run (three perLeg))[11]! = "0" ∧ (run (three perLeg))[20]! = "-18" ∧ (run (three perLeg))[21]! = "0" ∧
  (run (three perLeg))[30]! = "18"
-- a repeated event: the second rise starts again from zero
def twice : List Row := every 14 fun k => { t := k * 100, on := some ((k ≥ 1 && k ≤ 5) || k ≥ 10) }
#guard run twice = TR :: ints [0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3]
-- ψ true at the first observation: truncated until the next rise; ψ never true: truncated
def first : List Row := every 9 fun k => { t := k * 100, on := some (k != 5) }
#guard run first = [TR, TR, TR, TR, TR, TR, "0", "1", "2"]
#guard run (every 6 fun k => { t := k * 100, on := some false }) = List.replicate 6 TR
-- ψ unknown: t,u,t; f,u,f; u,t; t,u,f (the conservative unknown)
def onsets (xs : List (Option Bool)) : List Row := xs.zipIdx.map fun (b, k) => { t := k * 100, on := b }
#guard run (onsets [some false, some true, none, some true, some true]) = [TR, "0", ASM, ASM, ASM]
#guard run (onsets [some false, none, some false, some true, some true]) = [TR, ASM, ASM, "0", "1"]
#guard run (onsets [none, some true, some true]) = [ASM, ASM, ASM]
#guard run (onsets [some false, some true, none, some false, some false]) = [TR, "0", ASM, ASM, ASM]
-- the rate at the start covers the interval before it: missing there, still decided; missing just after: unknown
#guard run (every 4 fun k => { t := k * 100, on := some (k ≥ 1), yaw := if k == 1 then none else some 10 }) = [TR, "0", "1", "2"]
#guard run (every 4 fun k => { t := k * 100, on := some (k ≥ 1), yaw := if k == 2 then none else some 10 }) = [TR, "0", ABS, ABS]
-- intervals: a long one before the bracket has no effect; a long bracket (the onset somewhere in
-- (0 s, 100 s]) and a long one after the start are sampling gaps; exactly the bound is within it
def at_ (ts : List Int) (on : List Bool) : List Row := (ts.zip on).map fun (t, b) => { t, on := some b }
#guard run (at_ [0, 2000, 2100, 2200] [false, false, true, true]) = [TR, TR, "0", "1"]
#guard run (at_ [0, 100000, 100100] [false, true, true]) = [TR, GAP, GAP]
#guard run (at_ [0, 100, 200, 1500, 1600] [false, true, true, true, true]) = [TR, "0", "1", GAP, GAP]
#guard run (at_ [0, 100, 1100] [false, true, true]) = [TR, "0", "10"]
#guard run (at_ [0, 100, 1101] [false, true, true]) = [TR, "0", GAP]
#guard run (at_ [0, 1000, 1100] [false, true, true]) = [TR, "0", "1"]
#guard run (at_ [0, 1001, 1100] [false, true, true]) = [TR, GAP, GAP]

-- the step bound: zero, negative, missing, a parameter not positive, arithmetic, a time; the bound's
-- reasons hold at every observation and come before every reason of the data
def NP : String := "malformed:heading_since step bound is not positive"
def NL : String := "malformed:heading_since step bound is not a literal or a reading parameter"
#guard run left (hs (.lit Q.zero .second)) = List.replicate 31 NP
#guard run left (hs (.lit (Q.ofInt (-1)) .second)) = List.replicate 31 NP
#guard run left (hs (.param "p.step")) (step := Q.zero) = List.replicate 31 NP
#guard (evalTAll (SemCtx.mk' (left.map sceneOf) {} βx) hs).toList.map show_ = List.replicate 31 "parameter_missing:p.step"
#guard run left (hs (.mul (.lit (Q.ofInt 2) .ratio) (.param "p.step"))) = List.replicate 31 NL
#guard run (onsets [none, none, none]) (hs (.lit Q.zero .second)) = List.replicate 3 NP
#guard run left (hs (.lit Q.zero .second) (s := "y")) = List.replicate 31 "unbound_variable:y"
#guard (evalTAll (SemCtx.mk' (left.map sceneOf) {} βx) (hs (s := "y"))).toList.map show_ = List.replicate 31 "unbound_variable:y"
-- the static check: a literal not strictly positive, arithmetic, an unbound subject
def rOf (t : Term) : Rule := { id := "t/hs", laws := [], binders := [{ name := "x", cls := .tt }], applicability := .tt,
                               obligation := .cmp t .le (.lit (degrees 90) .degree), assumptions := ["asm.onset"] }
def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1
#guard Rule.check [] (rOf hs) = []
#guard Rule.check [] (rOf (hs (.lit (Q.mk' 1 2) .second))) = []
#guard has (Rule.check [] (rOf (hs (.lit Q.zero .second)))) "heading_since step bound is not strictly positive"
#guard has (Rule.check [] (rOf (hs (.lit (Q.ofInt (-2)) .second)))) "heading_since step bound is not strictly positive"
#guard has (Rule.check [] (rOf (hs (.mul (.lit (Q.ofInt 2) .ratio) (.param "p.step"))))) "heading_since step bound is not a literal or a reading parameter"
#guard has (Rule.check [] (rOf (hs (s := "y")))) "subject `y` is not a bound track"
#guard has (Rule.checkReading [rOf hs] (rOf hs) {}) "parameter `p.step` is not in the reading"
-- units: the term is in degrees; a step bound that is not a time is a mismatch, a parameter of no
-- known unit is unknown
def env : DimEnv := DimCheck.envOf (ρs (Q.ofInt 1)) []
#guard match DimCheck.termDim env hs with | .ok d => d == Dim.ofUnit .degree | .error _ => false
#guard DimCheck.errors env (.cmp hs .le (.lit (degrees 90) .degree)) = []
#guard (DimCheck.errors env (.cmp (hs (.lit (Q.ofInt 1) .metre)) .le (.lit (degrees 90) .degree))).map DimError.tag = ["mismatch"]
#guard (DimCheck.errors env (.cmp hs .le (.lit (Q.ofInt 1) .second))).map DimError.tag = ["mismatch"]
#guard (DimCheck.errors env (.cmp (hs (.param "p.other")) .le deg0)).map DimError.tag = ["unknown"]
#guard (DimCheck.errors env (.cmp (hs (ψ := .cmp (.measure "kin_speed" [X]) .gt (.lit (Q.ofInt 1) .metre))) .le deg0)).map DimError.tag = ["mismatch"]

-- an independent computation of the language-level values: ψ through `evalAll`, the rest by the
-- direct walk and sum of part A
def direct (rows : List Row) (step : Q := Q.ofInt 1) : List String :=
  let c := ctxOf rows step
  let Ψ := evalAll c onset
  let rate := c.d.scenes.map (kin_yaw_rate · 1)
  (List.range rows.length).map fun i => match naive c.d.times rate step Ψ i with
    | .ok r => let q := Q.mk' r.num r.den; show_ (.ok q)
    | .error e => e.tag
def scenarios : List (List Row) :=
  [left, right, stop, falls, three (· ≥ 1), three perLeg, twice, first,
   onsets [some false, some true, none, some true, some true], onsets [some false, some true, none, some false, some false],
   at_ [0, 100000, 100100] [false, true, true], at_ [0, 100, 200, 1500, 1600] [false, true, true, true, true]]
#guard scenarios.all fun rows => run rows = direct rows

-- ---------------------------------------------------------------------------------------------
-- C. One integral, one interval convention, one unit: where the window of `prim_heading_change`
-- starts exactly at the start of `headingSince`, the two values are equal.
-- ---------------------------------------------------------------------------------------------
def wavy : List Row := every 25 fun k => { t := k * 100, yaw := some ((Int.ofNat (k % 7) - 3) * 5), on := some (k ≥ 3) }
#guard (List.range 25).all fun i =>
  if i < 5 then true else
  let c := ctxOf wavy
  let w := Q.mk' (Int.ofNat ((i - 3) * 100)) 1000
  match (evalTAll c hs)[i]!, (Primitives.prim_heading_change c.d 1 w)[i]! with
  | .ok a, .ok b => Q.eq a b
  | _, _ => false
#guard (run wavy)[8]! = "1/2"

-- ---------------------------------------------------------------------------------------------
-- D. Identity. Two adjacent sightings joined by an accepted link, no observation missing between
-- them: one canonical track, the integral continues decided. A link-joined break with scenes
-- missing between: the yaw rate is missing there, unknown until a new rise, and the timeline
-- reports the identity gap inside the break.
-- ---------------------------------------------------------------------------------------------
def adjacent : List Row := every 11 fun k =>
  { t := k * 100, on := some (k ≥ 1), track := if k ≤ 5 then 1 else 5, links := if k == 6 then [(1, 5)] else [] }
def evalIn (rows : List Row) (gap : Q) (t : Term := hs) : Option (List String) :=
  match Grounding.Setup.admit [] (rows.map sceneOf) (ρs (Q.ofInt 1)) gap with
  | .ok S => some ((evalTAll (S.ctx βx) t).toList.map show_)
  | .error _ => none
#guard Grounding.acceptedLinks ((adjacent.map sceneOf).toArray) (seconds 1) = [(1, 5)]
#guard evalIn adjacent (seconds 1) = some (TR :: ints ((List.range 10).map Int.ofNat))
def broken : List Row := every 11 fun k =>
  { t := k * 100, on := some (k ≥ 1), track := if k ≤ 5 then 1 else 5, present := k != 6 && k != 7,
    links := if k == 8 then [(1, 5)] else [] }
#guard Grounding.acceptedLinks ((broken.map sceneOf).toArray) (seconds 1) = [(1, 5)]
#guard evalIn broken (seconds 1) = some ([TR, "0", "1", "2", "3", "4"] ++ List.replicate 5 ABS)
def hsRule : Rule := { id := "t/hs", laws := [], binders := [{ name := "x", cls := .atom "ru_motor_vehicle" [X] [] }],
                       applicability := .tt, obligation := .cmp hs .le (.lit (degrees 1000) .degree) }
#guard match Grounding.Setup.admit [hsRule] (broken.map sceneOf) (ρs (Q.ofInt 1)) (seconds 1) with
  | .ok S => ((Grounding.timeline S hsRule ⟨[("x", 1)], []⟩).toList.map (·.2)).drop 5 =
      [Verdict.compliant, .unknown [.identityGap 1], .unknown [.identityGap 1], .unknown [MISS], .unknown [MISS], .unknown [MISS]]
  | .error _ => false
-- a missing yaw rate on a present track, and the track absent before its first sighting: both the
-- yaw rate's absence
#guard run (every 5 fun k => { t := k * 100, on := some (k ≥ 1), yaw := if k == 3 then none else some 10 }) = [TR, "0", "1", ABS, ABS]
#guard run (every 5 fun k => { t := k * 100, on := some (k ≥ 1), present := k ≥ 3 }) = [TR, "0", ABS, ABS, ABS]

-- ---------------------------------------------------------------------------------------------
-- E. Concepts: a quantity concept with a track formal and a step formal whose onset quantifies over
-- another road user; a concept called inside another's onset; a formal and a bound variable of the
-- same name.
-- ---------------------------------------------------------------------------------------------
def moving (a : Arg) : Formula := .cmp (.measure "kin_speed" [a]) .ge (.lit (metresPerSecond 1) .metrePerSecond)
def turned : Concept :=
  { id := "drv.t.turned", contract := "the heading change of x since some other road user started moving", args := [("x", .track)],
    params := [⟨"s", .second⟩],
    body := .quantity (.headingSince "x" (.param "s") (.existsUser "u" (.and (.not (.same (.var "u") (.var "x"))) (moving (.var "u"))))) }
def onC : Concept :=
  { id := "drv.t.on", contract := "x moves", args := [("x", .track)], params := [], body := .formula (moving (.var "x")) }
def sinceOn : Concept :=
  { id := "drv.t.since_on", contract := "the heading change of x since x started moving", args := [("x", .track)],
    params := [⟨"s", .second⟩], body := .quantity (.headingSince "x" (.param "s") (.derived "drv_t_on" [.var "x"] [])) }
def shadow : Concept :=
  { id := "drv.t.shadow", contract := "x's heading change since the largest of every road user's own", args := [("x", .track)],
    params := [⟨"s", .second⟩],
    body := .quantity (.sub (.headingSince "x" (.param "s") (moving (.var "x")))
      (.aggregate .max "x" .tt (.headingSince "x" (.param "s") (moving (.var "x"))))) }
def cs : List Concept := [turned, onC, sinceOn, shadow]
def sameF (a b : Formula) : Bool := a.toJson == b.toJson
def callQ (n : String) : Formula := .cmp (.quantity n [.var "v"] [.param "p.step"]) .ge deg0
#guard sameF (Concept.expand cs (callQ "drv_t_turned"))
  (.cmp (.headingSince "v" (.param "p.step") (.existsUser "u#0" (.and (.not (.same (.var "u#0") (.var "v"))) (moving (.var "u#0"))))) .ge deg0)
#guard sameF (Concept.expand cs (callQ "drv_t_since_on")) (.cmp (.headingSince "v" (.param "p.step") (moving (.var "v"))) .ge deg0)
#guard sameF (Concept.expand cs (callQ "drv_t_shadow"))
  (.cmp (.sub (.headingSince "v" (.param "p.step") (moving (.var "v")))
             (.aggregate .max "x#0" .tt (.headingSince "x#0" (.param "p.step") (moving (.var "x#0"))))) .ge deg0)
#guard sinceOn.refs = ["drv_t_on"]
#guard cs.all fun c => Concept.check cs c = []
#guard has (Concept.check cs { turned with body := .quantity (.headingSince "x" (.lit Q.zero .second) .tt) }) "not strictly positive"
-- the expanded call and the formula written by hand evaluate alike
def βv : Binding := ({} : Binding).bind "v" (.track 1)
def handSinceOn : Formula := .cmp (.headingSince "v" (.param "p.step") (moving (.var "v"))) .ge deg0
#guard let c := ctxOf (every 12 fun k => { t := k * 100, speed := if k ≥ 2 then 5 else 0 }) (β := βv)
  Tests.EvalFast.sameR (evalAll c (Concept.expand cs (callQ "drv_t_since_on"))) (evalAll c handSinceOn) &&
  (evalAll c handSinceOn).toList.map (·.v) = [.u, .u] ++ List.replicate 10 .t
-- a bound variable named like the binding's: inside `existsUser "x"` the subject is the quantified user
def two : List Row := every 6 fun k => { t := k * 100, on := some (k ≥ 1) }
def twoScenes : List Scene := two.map fun r => { sceneOf r with
  users := (sceneOf r).users ++ [{ track := 2, classes := some [.motorVehicle], kin := { yawRate := some (degrees (-10)), speed := some (metresPerSecond 5) } }] }
#guard let c := SemCtx.mk' twoScenes (ρs (Q.ofInt 1)) βx
  (evalAll c (.existsUser "x" (.cmp hs .le (.lit (degrees (-3)) .degree)))).toList.map (·.v) =
    [.u, .f, .f, .f, .t, .t]

-- ---------------------------------------------------------------------------------------------
-- F. JSON: the strict decoder inverts the encoder; a missing or extra key is refused.
-- ---------------------------------------------------------------------------------------------
def roundTrips (φ : Formula) : Bool :=
  match Decode.formula "f" φ.toJson with
  | .ok ψ => ψ.toJson == φ.toJson
  | .error _ => false
#guard roundTrips (.cmp hs .ge deg0)
#guard roundTrips (.cmp (.abs (hs (.lit (Q.mk' 3 2) .second) (.existsUser "u" (moving (.var "u"))))) .ge deg0)
#guard (Term.toJson hs).compress = "{\"heading_since\":\"x\",\"max_step\":{\"param\":\"p.step\"},\"onset\":{\"asm\":\"asm.onset\"}}"
def rejects (text : String) : Bool :=
  match Json.parse text with
  | .ok j => (Decode.formula "f" j).toOption.isNone
  | .error _ => true
#guard rejects "{\"cmp\":\"ge\",\"lhs\":{\"heading_since\":\"x\",\"max_step\":{\"param\":\"p.step\"}},\"rhs\":{\"lit\":{\"num\":0,\"den\":1},\"unit\":\"degree\"}}"
#guard rejects "{\"cmp\":\"ge\",\"lhs\":{\"heading_since\":\"x\",\"max_step\":{\"param\":\"p.step\"},\"onset\":\"tt\",\"length\":{\"param\":\"p.step\"}},\"rhs\":{\"lit\":{\"num\":0,\"den\":1},\"unit\":\"degree\"}}"
#guard !rejects "{\"cmp\":\"ge\",\"lhs\":{\"heading_since\":\"x\",\"max_step\":{\"param\":\"p.step\"},\"onset\":\"tt\"},\"rhs\":{\"lit\":{\"num\":0,\"den\":1},\"unit\":\"degree\"}}"

-- ---------------------------------------------------------------------------------------------
-- G. The functions that end in a wildcard reach the step bound and the onset.
-- ---------------------------------------------------------------------------------------------
def rich : Formula := .and (.asm "asm.onset") (.and (.cmp (.measure "kin_speed" [X]) .ge (.param "p.v")) (.rule "t/other" [("a", "x")]))
def big : Term := .headingSince "x" (.lit (Q.ofInt 2) .second) (.and rich (.derived "drv_t_on" [X] []))
#guard Formula.termAtoms (hs (.param "p.step") (.cmp (.measure "kin_speed" [X]) .ge (.param "p.v"))) = ["kin_yaw_rate", "kin_time", "kin_speed"]
#guard Formula.termParams (hs (.param "p.step") rich) = ["p.step", "p.v"]
#guard Formula.termLiterals big = [(Q.ofInt 2, .second)]
#guard Formula.termCompositions big = [("t/other", [("a", "x")])]
#guard Formula.termDeclared big = [.asm "asm.onset"]
#guard sameF (Concept.expand cs (.cmp big .ge deg0)) (.cmp (.headingSince "x" (.lit (Q.ofInt 2) .second) (.and rich (moving X))) .ge deg0)
#guard ((Concept.expandT cs 3 (.headingSince "x" (.quantity "drv_t_since_on" [X] [.param "p.step"]) .tt)).run' 0).toJson ==
  (Term.headingSince "x" (.headingSince "x" (.param "p.step") (moving X)) .tt).toJson
#guard (Rule.futureReads (fun _ => false) true (.cmp (hs (ψ := .intent "int.turn_left" X (.var "r"))) .ge deg0)).length = 1
#guard (Rule.futureReads (fun _ => false) false (.cmp (hs (ψ := .intent "int.turn_left" X (.var "r"))) .ge deg0)).length = 0
#guard (Rule.pathReads (fun _ => false) false (.cmp (hs (ψ := .cmp (.measure "kin_path_length" [X]) .ge (.lit (metres 5) .metre))) .ge deg0)).length = 1
#guard ((DimCheck.inTerm (hs (ψ := rich))).1.map Formula.toJson) == [rich.toJson]
#guard (Concept.callDefects cs [("x", .track)] "w" (.cmp (hs (ψ := .derived "drv_t_on" [.lit "nope"] [])) .ge deg0)).length = 1
#guard (Rule.check [] (rOf (hs (ψ := .atom "ru_unicorn" [X] [])))).length = 1
-- the manifest: a source without the yaw rate cannot support the term
def manifestWithout (absent : List String) : Manifest :=
  { source := "t", entries := atomIds.filterMap fun a => if absent.contains a then none else some (a, .exact) }
def hsMoving : Rule := { rOf (hs (ψ := moving X)) with binders := [{ name := "x", cls := .atom "ru_motor_vehicle" [X] [] }] }
#guard (support [hsMoving] hsMoving (manifestWithout [])).tag = "supported"
#guard (support [hsMoving] hsMoving (manifestWithout ["kin.yaw_rate"])).tag != "supported"
#guard (support [hsMoving] hsMoving (manifestWithout ["kin.yaw_rate"])).absent = ["kin.yaw_rate"]

-- ---------------------------------------------------------------------------------------------
-- The reference and the cached evaluator agree on the term, at every instant, in every context
-- above, with a large cache and with one emptied again and again.
-- ---------------------------------------------------------------------------------------------
def hsCorpus : List Formula :=
  [.cmp hs .ge deg0, .cmp (.abs hs) .ge (.lit (degrees 3) .degree), .cmp (.add hs (.neg hs)) .eq deg0,
   .existsUser "u" (.cmp (.headingSince "u" (.param "p.step") onset) .le (.lit (degrees 90) .degree)),
   .existsUser "x" (.cmp hs .le (.lit (degrees (-3)) .degree)),
   .and (.cmp (.sinceRise onset) .ge (.lit (seconds 1) .second)) (.cmp hs .ge deg0),
   .cmp (.headingSince "x" (.param "p.step") (.cmp (.headingSince "x" (.param "p.step") (moving X)) .ge (.lit (degrees 2) .degree))) .ge deg0,
   .cmp (hs (.lit Q.zero .second)) .ge deg0, .cmp (hs (s := "y")) .ge deg0]
def hsContexts : List SemCtx :=
  (scenarios ++ [wavy, adjacent, broken]).map (ctxOf ·) ++ [SemCtx.mk' twoScenes (ρs (Q.ofInt 1)) βx, SemCtx.mk' [] (ρs (Q.ofInt 1)) βx]
#guard hsContexts.all fun c => hsCorpus.all (Tests.EvalFast.agrees defaultCells c)
#guard hsContexts.all fun c => hsCorpus.all (Tests.EvalFast.agrees 10 c)
#guard hsContexts.all fun c => [hs, .abs hs, .add hs hs, hs (.lit Q.zero .second)].all (Tests.EvalFast.agreesT 10 c)
-- the onset shared with `sinceRise` is read from the cache
#guard (evalFastWith defaultCells (ctxOf left) (.and (.cmp (.sinceRise onset) .ge (.lit (seconds 1) .second)) (.cmp hs .ge deg0))).2.hits > 0

-- ---------------------------------------------------------------------------------------------
-- T1–T11 rest on Lean's standard axioms only: no `sorryAx`, no axiom of this library.
-- ---------------------------------------------------------------------------------------------
/-- info: 'TrafficSpec.Accumulate.size_sinceRiseIntegralAll' depends on axioms: [propext, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.size_sinceRiseIntegralAll
/-- info: 'TrafficSpec.Accumulate.startAt_some_iff' depends on axioms: [propext, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.startAt_some_iff
/-- info: 'TrafficSpec.Accumulate.startAt_none_iff' depends on axioms: [propext, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.startAt_none_iff
/-- info: 'TrafficSpec.Accumulate.at_anchor' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.at_anchor
/-- info: 'TrafficSpec.Accumulate.zero_at_anchor' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.zero_at_anchor
/-- info: 'TrafficSpec.Accumulate.decided_anchored' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.decided_anchored
/-- info: 'TrafficSpec.Accumulate.none_observed' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.none_observed
/-- info: 'TrafficSpec.Accumulate.onset_before_recording' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.onset_before_recording
/-- info: 'TrafficSpec.Accumulate.no_anchor_unknown' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.no_anchor_unknown
/-- info: 'TrafficSpec.Accumulate.wide_interval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.wide_interval
/-- info: 'TrafficSpec.Accumulate.bracket_wide' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.bracket_wide
/-- info: 'TrafficSpec.Accumulate.missing_rate' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.missing_rate
/-- info: 'TrafficSpec.Accumulate.causal' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.causal
/-- info: 'TrafficSpec.Accumulate.integral_split' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.integral_split
/-- info: 'TrafficSpec.Accumulate.accumulates' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Accumulate.accumulates
/-- info: 'TrafficSpec.Semantics.evalTAll_headingSince' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Semantics.evalTAll_headingSince
/-- info: 'TrafficSpec.Primitives.headingSince_agrees_prim_heading_change' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs (whitespace := lax) in #print axioms Primitives.headingSince_agrees_prim_heading_change

end TrafficSpec.Tests.HeadingSince

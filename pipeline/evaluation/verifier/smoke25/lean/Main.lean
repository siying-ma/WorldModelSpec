/-
  monitor — decode traces at run time, evaluate the registered rules, print the report.

    monitor --manifest <m.json> [--reading <r.json>] [--rules id,id,...] [--json] <trace.json>...

  One report per trace. Exit status 2 on a decode error or a trace the admission refuses, 0
  otherwise: verdicts are the report's business, not the process's.
-/
import TrafficSpec
import TrafficSpec.Core.Runtime.Decode

open TrafficSpec

structure Opts where
  manifest : Option String := none
  reading : Option String := none
  rules : Option (List String) := none
  json : Bool := false
  traces : List String := []

partial def parseArgs : List String → Opts → Except String Opts
  | [], o => pure o
  | "--manifest" :: p :: rest, o => parseArgs rest { o with manifest := some p }
  | "--reading" :: p :: rest, o => parseArgs rest { o with reading := some p }
  | "--rules" :: ids :: rest, o => parseArgs rest { o with rules := some ((ids.splitOn ",").map (·.trimAscii.toString)) }
  | "--json" :: rest, o => parseArgs rest { o with json := true }
  | p :: rest, o => if p.startsWith "--" then throw s!"unknown option {p}" else parseArgs rest { o with traces := o.traces ++ [p] }

def readJson {α : Type} (dec : Lean.Json → Decode.D α) (path : String) : IO α := do
  let text ← IO.FS.readFile path
  match Decode.parse dec text with
  | .ok v => pure v
  | .error e => throw (IO.userError s!"{path}: {e}")

/-- The JSON line naming the trace's subject as the groundings name it (the scenes' `subject`
    tracks after identity merging, distinct, in order) and each reported rule's subject binder
    (its first binder), so a reader can tell the groundings that judge the subject from the others. -/
def subjectLine (rules targets : List Rule) (τ : Trace) (ρ : Reading) (m : Manifest) : String :=
  let ego : List TrackId := match Grounding.Setup.admit (rules.map (Concept.expandRule allConcepts)) (maskTrace m τ) ρ m.reidGap with
    | .ok S => (τ.filterMap fun s => (Grounding.canonicalScene S.cm s).subject).eraseDups
    | .error _ => []
  let binders := targets.map fun (r : Rule) => (r.id, match r.subject with | some b => Lean.Json.str b | none => Lean.Json.null)
  (Lean.Json.mkObj [("kind", "subject"), ("ego", Lean.Json.arr (ego.map fun (t : TrackId) => (Lean.toJson t)).toArray),
    ("binders", Lean.Json.mkObj binders)]).compress

def main (args : List String) : IO UInt32 := do
  let opts ← match parseArgs args {} with
    | .ok o => pure o
    | .error e => do IO.eprintln e; return (2 : UInt32)
  let some mpath := opts.manifest | do IO.eprintln "monitor: --manifest is required"; return (2 : UInt32)
  if opts.traces.isEmpty then IO.eprintln "monitor: no trace given"; return (2 : UInt32)
  try
    let m ← readJson Decode.manifest mpath
    if !m.complete then
      IO.eprintln s!"monitor: manifest {m.source} is not complete over the atom ids ({m.absentIds.length} unlisted or unknown)"
    let ρ ← match opts.reading with
      | some p => readJson Decode.reading p
      | none => pure ({} : Reading)
    -- the rules reported, and the rules registered for their evaluation: each reported rule with
    -- every rule it composes, so a composition is evaluated as with the whole rule set
    let targets : List Rule := match opts.rules with
      | some ids => allRules.filter fun (r : Rule) => ids.contains r.id
      | none => allRules
    let rules := (targets.flatMap (Rule.closure allRules)).foldl (fun (acc : List Rule) (r : Rule) => if acc.any (fun (x : Rule) => x.id == r.id) then acc else acc ++ [r]) []
    let reported := targets.map (fun (r : Rule) => r.id)
    for path in opts.traces do
      let τ ← readJson Decode.trace path
      match Monitor.check rules τ ρ m allConcepts with
      | .ok rep =>
        let rep := { rep with rules := rep.rules.filter (fun (l : Monitor.RuleLine) => reported.contains l.rule), rows := rep.rows.filter (fun (w : Monitor.Row) => reported.contains w.rule) }
        IO.print (if opts.json then Monitor.renderJsonLines rep else Monitor.renderText rep)
        if opts.json then IO.println (subjectLine rules targets τ ρ m)
      | .error ds =>
        IO.eprintln s!"monitor: {path}: the trace is not admitted: {"; ".intercalate ds}"
        return (2 : UInt32)
    return (0 : UInt32)
  catch e =>
    IO.eprintln s!"monitor: {e}"
    return (2 : UInt32)

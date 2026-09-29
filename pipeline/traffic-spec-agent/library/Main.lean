/-
  monitor — decode traces at run time, evaluate the registered rules, print the report.

    monitor --manifest <m.json> [--reading <r.json>] [--rules id,id,...] [--json] <trace.json>...

  One report per trace. Exit status 2 on a decode error, 0 otherwise: verdicts are the report's
  business, not the process's.
-/
import TrafficSpec
import TrafficSpec.Core.Decode

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
    let rules := match opts.rules with
      | some ids => allRules.filter fun r => ids.contains r.id
      | none => allRules
    for path in opts.traces do
      let τ ← readJson Decode.trace path
      let rep := Monitor.check rules τ ρ m allConcepts
      IO.print (if opts.json then Monitor.renderJsonLines rep else Monitor.renderText rep)
    return (0 : UInt32)
  catch e =>
    IO.eprintln s!"monitor: {e}"
    return (2 : UInt32)

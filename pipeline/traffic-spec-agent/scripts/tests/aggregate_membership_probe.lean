import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Runtime.Decode

/-
  aggregate_membership_probe <reading.json> <cases.json>

  Decodes a reading with Core's decoder, and each case's road user as a trace writes it; prints, per
  case, Core's membership of that road user in the named aggregate at one scene: `T`, `F` or `U`,
  then the unknown reasons' tags. Cases: [{"aggregate": "<id>", "user": {<road user>}}].
-/
open TrafficSpec TrafficSpec.Semantics Lean

def triLetter : Tri → String
  | .t => "T"
  | .f => "F"
  | .u => "U"

def caseLine (ρ : Reading) (c : Json) : Except String String := do
  let aid ← c.getObjValAs? String "aggregate"
  let u ← Decode.roadUser "user" (← c.getObjVal? "user")
  let some a := ρ.aggregates.find? (·.id == aid) | throw s!"no aggregate {aid} in the reading"
  let r := aggregateMembership { t := 0, users := [u] } u.track a
  pure s!"{triLetter r.v} {",".intercalate (r.why.map UnknownReason.tag)}"

def main (args : List String) : IO UInt32 := do
  let [rp, cp] := args | do IO.eprintln "usage: aggregate_membership_probe <reading.json> <cases.json>"; return 2
  let ρ ← match Decode.parse Decode.reading (← IO.FS.readFile rp) with
    | .ok r => pure r
    | .error e => do IO.eprintln s!"reading: {e}"; return 2
  let cases ← match Json.parse (← IO.FS.readFile cp) >>= (·.getArr?) with
    | .ok cs => pure cs
    | .error e => do IO.eprintln s!"cases: {e}"; return 2
  for c in cases do
    match caseLine ρ c with
    | .ok line => IO.println line
    | .error e => do IO.eprintln s!"case: {e}"; return 2
  return 0

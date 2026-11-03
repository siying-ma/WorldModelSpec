/-
  The region kinds Core declares at every region argument of its atoms and primitives
  (`TraceLint.regionArgKinds`), printed as JSON: `lake env lean --run RegionKinds.lean`, from
  `library/`.

  Output (stdout): `{"entries": [{"name": n, "position": i, "admitted": "any" | [kind, …]}, …]}`, one
  entry per entry of the table, in its order: `position` is the argument's index in the full argument
  list, `admitted` the spellings of the kinds a region there may have, or `any`.
-/
import Lean.Data.Json
import TrafficSpec.Core.Evidence.TraceLint

open Lean TrafficSpec

def main : IO UInt32 := do
  let entries := TraceLint.regionArgKinds.map fun ((n, i), ks) =>
    Json.mkObj [("name", n), ("position", i), ("admitted", match ks with
      | none => Json.str "any"
      | some ks => Json.arr (ks.map fun k => Json.str k.toString).toArray)]
  IO.println (Json.mkObj [("entries", Json.arr entries.toArray)]).compress
  return 0

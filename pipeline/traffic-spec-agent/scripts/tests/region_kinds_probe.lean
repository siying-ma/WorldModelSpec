/-
  A regression probe of the declared region-argument kinds (`TraceLint.regionArgKinds`): it runs Core
  on probe traces and reports what it observed, from which a test refutes a table that is too narrow
  (a kind read outside it) or too broad (a listed kind the trace check rejects on the field read
  there). It never supplies a constraint. `lake env lean --run region_kinds_probe.lean <signatures.json>`,
  from `library/`.

  Input: `{"signatures": [{"name": n, "args": [a, …]}]}`, each argument `"track"`, `"region"`,
  `"device"`, or the list of literal spellings that position is tried with.
  Output (stdout): `{"labels": [kind, …], "entries": [{"name": n, "args": [a, …], "regions":
  [{"position": i, "read": [kind, …], "targets": [field, …], "rejected": [{"kind": k, "fields":
  [field, …]}, …]}, …]}, …]}`, one entry per signature, one region entry per region argument, `position`
  its index in the full argument list.

  The probes: two regions of every pair of kinds Core admits as labels (`labels`), one road user
  (position, heading, extent) and two devices whose control is observed; a device argument is tried
  with each. A probe trace is admitted
  when `Admission.defects` and `TraceLint.checkTrace` are both empty after
  `TraceLint.completeOccupancy`.
  - `read`: the kinds a region at that argument has in an admitted probe on which the name reads
    true (a Boolean atom or primitive) or a value (a measured one). The probe of a pair carries every
    field that the check admits alone on that pair, together.
  - `targets`: the fields that, set alone on the base probe of a pair that admits them, make the name
    read where the base probe does not: the fields the name reads at that signature.
  - `rejected`: the kinds at that argument on which every target field, set alone, is rejected by
    the check on every pair whose base probe is admitted. Empty where there is no target field.
  Exits 1 when a probe whose fields each pass the check fails it together.
-/
import Lean.Data.Json
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Runtime.Admission
import TrafficSpec.Core.Language.Semantics

open Lean TrafficSpec

namespace RegionKindsProbe

inductive Pos
  | track | region | device
  | literal (spellings : List String)

structure Sig where
  name : String
  args : List Pos

def Pos.toJson : Pos → Json
  | .track => "track" | .region => "region" | .device => "device"
  | .literal ss => Json.arr (ss.map Json.str).toArray

def parseSig (j : Json) : Except String Sig := do
  let name ← j.getObjValAs? String "name"
  let args ← j.getObjValAs? (Array Json) "args"
  let ps ← args.toList.mapM fun a => match a with
    | .str "track" => pure Pos.track
    | .str "region" => pure .region
    | .str "device" => pure .device
    | .arr xs => do
      let ss ← xs.toList.mapM fun x => match x with
        | .str s => pure s
        | _ => throw s!"{name}: a literal spelling is not a string"
      pure (.literal ss)
    | _ => throw s!"{name}: an argument is neither a sort nor a list of spellings"
  pure ⟨name, ps⟩

def q (n : Int) : Q := Q.ofInt n
def square : List Vec := [(q (-10), q (-10)), (q 10, q (-10)), (q 10, q 10), (q (-10), q 10)]

def withLane (f : LaneInfo → LaneInfo) (st : Structure) : Structure := { st with lane := some (f (st.lane.getD {})) }

/-- Every field a structure may carry, by name, set, those naming a region naming `other`. -/
def structureFields (other : RegionId) : List (String × (Structure → Structure)) := [
  ("lane.direction", withLane fun l => { l with direction := some (q 1, q 0) }),
  ("lane.left", withLane fun l => { l with leftNeighbour := some other }),
  ("lane.right", withLane fun l => { l with rightNeighbour := some other }),
  ("lane.ordinal_from_left", withLane fun l => { l with ordinalFromLeft := some 2 }),
  ("lane.count_in_direction", withLane fun l => { l with countInDirection := some 3 }),
  ("lane.leads_to", withLane fun l => { l with leadsTo := some [other] }),
  ("lane.enters_intersection", withLane fun l => { l with entersIntersection := some other }),
  ("lane.marking_left", withLane fun l => { l with markingLeft := some default }),
  ("lane.marking_right", withLane fun l => { l with markingRight := some default }),
  ("lane.width", withLane fun l => { l with width := some (q 3) }),
  ("paved", fun st => { st with paved := some true }),
  ("opening", fun st => { st with opening := some true }),
  ("marked", fun st => { st with marked := some true }),
  ("sight_distance", fun st => { st with sightDistance := some (q 100) }),
  ("ways", fun st => { st with ways := some [other] }),
  ("entrance_of", fun st => { st with entranceOf := [other], entranceObserved := true }),
  ("reserved_class", fun st => { st with reservedClass := some default }),
  ("turn_side", fun st => { st with turnSide := some default }),
  ("parking_angle", fun st => { st with parkingAngle := some (q 45) }),
  ("designation", fun st => { st with designation := some default }),
  ("angle_marking", fun st => { st with angleMarking := some true }),
  ("axis", fun st => { st with parkingAxis := some (q 1, q 0) }),
  ("curb_kind", fun st => { st with curbKind := some default }),
  ("curb_colour", fun st => { st with curbColour := some default }),
  ("obstruction_kind", fun st => { st with obstructionKind := some default })]

def onStructure (r : RegionId) (f : Structure → Structure) (s : Scene) : Scene :=
  { s with structures := s.structures.map fun st => if st.id == r then f st else st }

def onDevice (i : DeviceId) (f : Device → Device) (s : Scene) : Scene :=
  { s with devices := s.devices.map fun d => if d.id == i then f d else d }

/-- Each field the probe may set, by name, one scene change each. -/
def fields : List (String × (Scene → Scene)) :=
  ([(1, 2), (2, 1)].flatMap fun (r, o) => (structureFields o).map fun (n, f) => (s!"region {r} {n}", onStructure r f))
  ++ ([1, 2].map fun (r : RegionId) => (s!"device governs region {r}", fun (s : Scene) =>
       { s with devices := s.devices.map fun d => { d with governs := d.governs ++ [r] } }))
  ++ ([1, 2].map fun (r : RegionId) => (s!"device 1 governs_sidewalk region {r}", onDevice 1 fun d =>
       { d with kind := .regulatorySign, code := some .bicyclesProhibited, governsSidewalk := some ((d.governsSidewalk.getD []) ++ [r]) }))
  ++ ([1, 2].map fun (r : RegionId) => (s!"device 2 governs_parking_space region {r}", onDevice 2 fun d =>
       { d with kind := .regulatorySign, code := some .angleParking, governsParkingSpace := some ((d.governsParkingSpace.getD []) ++ [r]) }))
  ++ ([1, 2].map fun (r : RegionId) => (s!"user sight_along_way region {r}", fun (s : Scene) =>
       { s with users := s.users.map fun u => { u with sightAlongWay := some ((u.sightAlongWay.getD []) ++ [(r, q 100)]) } }))
  ++ [("user occupancy_observed", fun (s : Scene) => { s with occupancyObserved := [1] })]

def base (ka kb : StructureKind) : Scene :=
  { t := 0
    users := [{ track := 1, kin := { position := some (q 0, q 0), heading := some (q 1, q 0), extent := some (q 1, q 1, q 1) } }]
    structures := [{ id := 1, kind := ka, position := some (q 0, q 0), boundary := some square },
                   { id := 2, kind := kb, position := some (q 0, q 0), boundary := some square }]
    devices := [{ id := 1, kind := default, position := some (q 0, q 0), governs := [], governsObserved := true },
                { id := 2, kind := default, position := some (q 0, q 0), governs := [], governsObserved := true }] }

def admit (s : Scene) : Option Scene :=
  let τ := TraceLint.completeOccupancy [s]
  if (Admission.defects τ Q.zero).isEmpty && (TraceLint.checkTrace τ).isEmpty then τ.head? else none

/-- Whether the name reads true or a value on the scene with these arguments. -/
def reads (s : Scene) (n : String) (args : List Primitives.DArg) : Bool :=
  let ctx := Primitives.Ctx.mk' [s] {}
  let atomB : Bool := match Semantics.evalAtomE s n args [] with | .ok r => r.v == .t | .error _ => false
  let atomQ : Bool := match Semantics.evalMeasure s n args with | .ok _ => true | .error _ => false
  let primB : Bool := match Primitives.evalB n ctx args [] with | .ok a => (a[0]?.map (·.v == .t)).getD false | .error _ => false
  let primQ : Bool := match Primitives.evalQ n ctx args [] with
    | .ok a => match a[0]? with | some (Except.ok _) => true | _ => false
    | .error _ => false
  atomB || atomQ || primB || primQ

/-- The argument lists of a signature: entities bound to the probe's track 1, each of its devices
    and, in order, regions 1 and 2; literal positions over their spellings. -/
def argLists (g : Sig) : List (List Primitives.DArg) :=
  let rec go : List Pos → Nat → List (List Primitives.DArg)
    | [], _ => [[]]
    | .region :: rest, k => (go rest (k + 1)).map (.v (k + 1) :: ·)
    | .track :: rest, k => (go rest k).map (.v 1 :: ·)
    | .device :: rest, k => [1, 2].flatMap fun d => (go rest k).map (.v d :: ·)
    | .literal ss :: rest, k => ss.flatMap fun l => (go rest k).map (.s l :: ·)
  go g.args 0

def readsSig (s : Scene) (g : Sig) : Bool := (argLists g).any (reads s g.name)

def regionPositions (g : Sig) : List Nat :=
  ((g.args.zip (List.range g.args.length)).filter fun | (.region, _) => true | _ => false).map (·.2)

def kindsJson (ks : List StructureKind) : Json := Json.arr ((StructureKind.all.filter ks.contains).map (Json.str ·.toString)).toArray

def run (sigs : List Sig) : Except String Json := do
  if sigs.any (fun g => (regionPositions g).length > 2) then throw "a signature has more than two region arguments"
  let fs := fields.toArray
  -- per signature, per region argument: the kinds read there
  let mut readAt : Array (Array (List StructureKind)) := (sigs.map fun g => Array.replicate (regionPositions g).length []).toArray
  -- per signature: the indices of its target fields
  let mut targets : Array (List Nat) := Array.replicate sigs.length []
  let mut tried : Array Bool := Array.replicate fs.size false
  -- the admitted pairs with, per field, whether the field alone is admitted on the pair
  let mut pairs : Array (StructureKind × StructureKind × Array Bool) := #[]
  let mut labels : List StructureKind := []
  for ka in StructureKind.all do
    for kb in StructureKind.all do
      let s0 := base ka kb
      let some b0 := admit s0 | continue
      labels := if labels.contains ka then labels else labels ++ [ka]
      let ok := fs.map fun (_, f) => (admit (f s0)).isSome
      pairs := pairs.push (ka, kb, ok)
      let kept := (fs.toList.zip ok.toList).filterMap fun ((_, f), a) => if a then some f else none
      let some s := admit (kept.foldl (fun s f => f s) s0)
        | throw s!"the probe of {ka} and {kb} passes the trace check field by field but not as a whole"
      for (g, i) in sigs.zip (List.range sigs.length) do
        let row := readAt[i]!
        let known := (row.size < 1 || row[0]!.contains ka) && (row.size < 2 || row[1]!.contains kb)
        if !known && readsSig s g then
          let row := if row.size > 0 && !row[0]!.contains ka then row.set! 0 (row[0]! ++ [ka]) else row
          let row := if row.size > 1 && !row[1]!.contains kb then row.set! 1 (row[1]! ++ [kb]) else row
          readAt := readAt.set! i row
      -- target fields: on the first pair that admits a field alone
      for fi in List.range fs.size do
        if tried[fi]! || !ok[fi]! then continue
        tried := tried.set! fi true
        let some s1 := admit (fs[fi]!.2 s0) | continue
        for (g, i) in sigs.zip (List.range sigs.length) do
          if readsSig s1 g && !readsSig b0 g then
            targets := targets.set! i (targets[i]! ++ [fi])
  let mut entries : Array Json := #[]
  for (g, i) in sigs.zip (List.range sigs.length) do
    let mut regions : Array Json := #[]
    for (pos, j) in (regionPositions g).zip (List.range (regionPositions g).length) do
      let slot := fun (p : StructureKind × StructureKind × Array Bool) => if j == 0 then p.1 else p.2.1
      let rejected := if targets[i]!.isEmpty then [] else labels.filter fun k =>
        let at_ := pairs.toList.filter (slot · == k)
        !at_.isEmpty && at_.all fun p => targets[i]!.all fun fi => !p.2.2[fi]!
      regions := regions.push (Json.mkObj [("position", pos), ("read", kindsJson readAt[i]![j]!),
        ("targets", Json.arr (targets[i]!.map fun fi => Json.str fs[fi]!.1).toArray),
        ("rejected", Json.arr (rejected.map fun k => Json.mkObj [("kind", Json.str k.toString),
          ("fields", Json.arr (targets[i]!.map fun fi => Json.str fs[fi]!.1).toArray)]).toArray)])
    entries := entries.push (Json.mkObj [("name", g.name), ("args", Json.arr (g.args.map Pos.toJson).toArray),
      ("regions", Json.arr regions)])
  pure (Json.mkObj [("labels", kindsJson labels), ("entries", Json.arr entries)])

end RegionKindsProbe

def main (args : List String) : IO UInt32 := do
  let some file := args.head? | IO.eprintln "usage: region_kinds_probe.lean <signatures.json>"; return 1
  let text ← IO.FS.readFile file
  let result := do
    let j ← Json.parse text
    let sigs ← (← j.getObjValAs? (Array Json) "signatures").toList.mapM RegionKindsProbe.parseSig
    RegionKindsProbe.run sigs
  match result with
  | .ok out => IO.println out.compress; return 0
  | .error e => IO.eprintln e; return 1

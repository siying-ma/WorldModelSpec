import TrafficSpec.Core.Runtime.Monitor
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.TravelRegion
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Grounding

-- ---------------------------------------------------------------------------------------------
-- The abstract travel region: refined by exactly the kinds a device may govern.
-- ---------------------------------------------------------------------------------------------
def concreteKinds : List StructureKind := StructureKind.all.filter (!·.isAbstract)
def children : List StructureKind := StructureKind.all.filter (·.parent? == some .travelRegion)
def governsList : List StructureKind :=
  [.lane, .reservedLane, .turnLane, .centreTurnLane, .bicycleLaneOrPath, .roadway, .oneWayRoadway, .shoulder, .intersection]
#guard StructureKind.all.filter (·.isAbstract) = [.travelRegion]
#guard children = [.roadway, .lane, .shoulder, .intersection, .bicycleLaneOrPath]
#guard TraceLint.governedKinds.length = governsList.length && governsList.all TraceLint.governedKinds.contains
-- the derived list is, as a set, the hand-written one it replaced; the direction kinds are unchanged
def oldGovernedKinds : List StructureKind := TraceLint.directionKinds ++ [.centreTurnLane, .intersection]
#guard TraceLint.governedKinds.length = oldGovernedKinds.length && oldGovernedKinds.all TraceLint.governedKinds.contains
#guard TraceLint.directionKinds = [.lane, .reservedLane, .turnLane, .bicycleLaneOrPath, .roadway, .oneWayRoadway, .shoulder]
#guard !TraceLint.governedKinds.contains .sidewalk
#guard ![StructureKind.sidewalk, .crosswalk, .stopLine, .highway, .controlledAccess].any (·.refines .travelRegion)

-- ---------------------------------------------------------------------------------------------
-- Kind membership three ways: Core before the abstract kind (its refinement tables), Core with the
-- abstract kind as a plain parent, and Core.
-- ---------------------------------------------------------------------------------------------
def oldAncestors : StructureKind → List StructureKind
  | .oneWayRoadway => [.roadway]
  | .reservedLane | .centreTurnLane | .turnLane => [.lane]
  | _ => []
def refinesBy (anc : StructureKind → List StructureKind) (a b : StructureKind) : Bool := a == b || (anc a).contains b
def generic (par : StructureKind → Option StructureKind) (anc : StructureKind → List StructureKind)
    (st : Structure) (k : StructureKind) : Option Bool :=
  let masked := st.unobservedKinds.filter fun m => (par m).isNone || refinesBy anc m st.kind
  if masked.any (refinesBy anc k ·) then none
  else if refinesBy anc st.kind k then some true
  else if masked.any (refinesBy anc · k) then none
  else some false
def oldSem := generic (fun k => (oldAncestors k).head?) oldAncestors
def naiveSem := generic StructureKind.parent? StructureKind.ancestors
def kOr (vs : List (Option Bool)) : Option Bool :=
  if vs.contains (some true) then some true else if vs.contains none then none else some false

def st (k : StructureKind) (u : List StructureKind := []) : Structure := { id := 1, kind := k, unobservedKinds := u }
def pairs {α : Type} : List α → List (α × α)
  | [] => []
  | x :: xs => xs.map (x, ·) ++ pairs xs
def relevant : List StructureKind :=
  [.lane, .turnLane, .centreTurnLane, .roadway, .oneWayRoadway, .shoulder, .intersection, .bicycleLaneOrPath,
   .sidewalk, .crosswalk, .stopLine, .highway, .medianOrDivider]
/-- Every concrete label under no mask, one mask, two masks of any concrete kinds, and three masks of
    the kinds a travel region, its parts and its neighbours involve. -/
def maskSets : List (List StructureKind) :=
  [[]] ++ concreteKinds.map ([·]) ++ (pairs concreteKinds).map (fun (a, b) => [a, b])
    ++ (relevant.flatMap fun a => (pairs relevant).filterMap fun (b, c) =>
          if a != b && a != c && relevant.idxOf a < relevant.idxOf b then some [a, b, c] else none)
def structures : List Structure := concreteKinds.flatMap fun k => maskSets.map fun m => st k m

-- Core decides every old kind exactly as before, on every enumerated structure.
#guard structures.all fun s => concreteKinds.all fun k => s.isOfKind k == oldSem s k
-- the travel region is the union of the kinds refining it, and of every kind a device may govern
#guard structures.all fun s => s.isOfKind .travelRegion == kOr (children.map s.isOfKind)
#guard structures.all fun s => s.isOfKind .travelRegion == kOr (governsList.map s.isOfKind)
-- a plain parent changes old verdicts (the three audit examples among them); Core does not
#guard naiveSem (st .roadway [.lane]) .lane = some false && oldSem (st .roadway [.lane]) .lane = none
#guard naiveSem (st .shoulder [.roadway]) .roadway = some false && oldSem (st .shoulder [.roadway]) .roadway = none
#guard naiveSem (st .sidewalk [.lane]) .lane = some false && oldSem (st .sidewalk [.lane]) .lane = none
#guard (st .roadway [.lane]).isOfKind .lane = none
#guard (st .shoulder [.roadway]).isOfKind .roadway = none
#guard (st .sidewalk [.lane]).isOfKind .lane = none
#guard (structures.filter fun s => concreteKinds.any fun k => naiveSem s k != oldSem s k).length > 0
-- the travel region under masks
#guard (st .lane).isOfKind .travelRegion = some true
#guard (st .turnLane).isOfKind .travelRegion = some true
#guard (st .sidewalk).isOfKind .travelRegion = some false
#guard (st .highway).isOfKind .travelRegion = some false
#guard (st .lane [.lane]).isOfKind .travelRegion = none            -- the label cannot be trusted for lane
#guard (st .sidewalk [.lane]).isOfKind .travelRegion = none        -- any region may be a lane
#guard (st .roadway [.lane]).isOfKind .travelRegion = some true    -- a known roadway
#guard (st .lane [.turnLane]).isOfKind .travelRegion = some true   -- a child's mask leaves the lane known
#guard (st .sidewalk [.turnLane]).isOfKind .travelRegion = some false

-- ---------------------------------------------------------------------------------------------
-- Quantifiers: over the travel region, the disjunction (conjunction) of the quantifiers over the
-- kinds refining it, on every enumerated two-region scene.
-- ---------------------------------------------------------------------------------------------
def labels : List StructureKind :=
  [.lane, .turnLane, .roadway, .oneWayRoadway, .shoulder, .intersection, .bicycleLaneOrPath, .sidewalk, .crosswalk, .highway]
def masks : List (List StructureKind) := [[], [.lane], [.turnLane], [.lane, .shoulder], [.sidewalk, .intersection]]
def one (id : Nat) : List Structure := labels.flatMap fun k => masks.map fun m => { id := id, kind := k, unobservedKinds := m }
def occupancies : List (List TrackId × List (TrackId × RegionId)) :=
  [([1], []), ([1], [(1, 1)]), ([1], [(1, 2)]), ([1], [(1, 1), (1, 2)]), ([], [])]
def scenes : List Scene :=
  (one 1).flatMap fun a => (one 2).flatMap fun b => occupancies.map fun (o, occ) =>
    { t := 0, users := [{ track := 1 }], structures := [a, b], occupancyObserved := o, occupies := occ }
def body : Formula := .atom "rel_occupies" [.var "x", .var "r"] []
def tri (s : Scene) (φ : Formula) : Tri := (eval (SemCtx.mk' [s] Tests.Semantics.ρ Tests.Semantics.β) 0 φ).v
def exK (k : StructureKind) : Formula := .existsRegion (.lit k.toString) "r" body
def allK (k : StructureKind) : Formula := .forallRegion (.lit k.toString) "r" body
#guard scenes.all fun s =>
  tri s (exK .travelRegion) == (children.map fun k => tri s (exK k)).foldl Tri.or .f
  && tri s (allK .travelRegion) == (children.map fun k => tri s (allK k)).foldl Tri.and .t
  && tri s (.atom "st_travel_region" [.nat 1] []) == (children.map fun k => tri s (.atom s!"st_{k}" [.nat 1] [])).foldl Tri.or .f

-- ---------------------------------------------------------------------------------------------
-- Support: the kinds a read depends on are exactly those whose mask can leave it unknown; no
-- source declares the abstract kind.
-- ---------------------------------------------------------------------------------------------
#guard kindDependencies "st.travel_region" = ["st.roadway", "st.lane", "st.shoulder", "st.intersection", "st.bicycle_lane_or_path"]
#guard concreteKinds.all fun k => kindDependencies s!"st.{k}" = (k :: oldAncestors k).map (s!"st.{·}")
#guard StructureKind.all.all fun k => concreteKinds.all fun a =>
  (kindDependencies s!"st.{k}").contains s!"st.{a}" == concreteKinds.any fun l => (st l [a]).isOfKind k == none
def withAbsent (ids : List String) : Manifest :=
  let full := Manifest.full "test"
  { full with entries := full.entries.map fun (id, c) => if ids.contains id then (id, .absent) else (id, c) }
def trRule : Rule :=
  { id := "t", laws := [], binders := [⟨"x", .tt⟩], applicability := .tt, obligation := .existsRegion (.lit "travel_region") "r" body }
#guard support [] trRule (withAbsent ["st.travel_region"]) = .supported
#guard support [] trRule (withAbsent ["st.shoulder"]) = .partially ["st.shoulder"]
#guard support [] trRule (withAbsent ["st.sidewalk"]) = .supported
#guard (Mask.structure' "st.travel_region" (st .lane [.turnLane])).map (·.unobservedKinds) = some [.turnLane]
#guard (Mask.structure' "st.shoulder" (st .lane)).map (·.unobservedKinds) = some [.shoulder]

-- ---------------------------------------------------------------------------------------------
-- Admission: an abstract kind is no label and no unobserved kind, on the JSON path (the monitor,
-- the certificate) and the Lean path (a witness), with the same text.
-- ---------------------------------------------------------------------------------------------
def sceneJson (sj : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1}], \"structures\": [" ++ sj ++ "]}]}"
def labelled : String := "{\"id\": 20, \"kind\": \"travel_region\"}"
def masking : String := "{\"id\": 20, \"kind\": \"lane\", \"unobserved_kinds\": [\"travel_region\", \"turn_lane\"]}"
def leanTrace (s : Structure) : Trace := [{ t := 0, users := [{ track := 1 }], structures := [s] }]
def viaMonitor (text : String) : List String :=
  match Decode.parse Decode.trace text with
  | .ok τ => match Monitor.check [] τ {} (Manifest.full "t") with | .error ds => ds | .ok _ => []
  | .error e => [e]
def anyRule : Rule := { id := "test/any", laws := [], binders := [⟨"x", .tt⟩], applicability := .tt, obligation := .tt }
def viaWitness (τ : Trace) : List String :=
  let sc : Scenario := { name := "w", rule := "test/any", trace := τ, reading := {}, manifest := Manifest.full "t",
                         grounding := [("x", 1)], expected := .compliant }
  match sc.run [anyRule] with
  | .error e => [e]
  | .ok _ => []
def sameBoth (text : String) (τ : Trace) : Bool :=
  let ds := viaMonitor text
  !ds.isEmpty && ds == Admission.defects τ Q.zero && viaWitness τ == [s!"w: the trace is not admitted: {"; ".intercalate ds}"]
#guard (Decode.parse Decode.trace (sceneJson labelled)).isOk       -- the decoder spells it; admission refuses it
#guard sameBoth (sceneJson labelled) (leanTrace { id := 20, kind := .travelRegion })
#guard sameBoth (sceneJson masking) (leanTrace { id := 20, kind := .lane, unobservedKinds := [.travelRegion, .turnLane] })
#guard viaMonitor (sceneJson labelled) = ["scene t=0: structure 20 is labelled `travel_region`, an abstract kind; label it with a kind that refines `travel_region`"]
#guard viaWitness (leanTrace (Build.rect 20 .travelRegion Q.zero Q.zero (metres 10) (metres 4))) ≠ []
#guard viaMonitor (sceneJson "{\"id\": 20, \"kind\": \"lane\", \"unobserved_kinds\": [\"turn_lane\"]}") = []
#guard viaWitness (leanTrace (Build.rect 20 .lane Q.zero Q.zero (metres 10) (metres 4))) = []
-- a reviewer's case on such a trace is refused before any verdict
def certOn (trace : String) : Lean.Json :=
  Certificate.record [anyRule] anyRule {} 1 trace
    "{\"case\": {\"atom\": \"ru_subject\", \"args\": [{\"var\": \"x\"}], \"params\": []}, \"entities\": {}, \"at\": 0}" [("x", 1)]
def refusedAbstract (j : Lean.Json) : Bool :=
  match j.getObjVal? "rule_result", j.getObjVal? "lint_errors" with
  | .ok .null, .ok l => (l.compress.splitOn "an abstract kind").length > 1
  | _, _ => false
#guard refusedAbstract (certOn (sceneJson labelled))
#guard refusedAbstract (certOn (sceneJson masking))

end TrafficSpec.Tests.TravelRegion

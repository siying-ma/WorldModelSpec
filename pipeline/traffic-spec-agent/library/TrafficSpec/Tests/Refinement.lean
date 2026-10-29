import TrafficSpec.Core.Runtime.Manifest
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.Refinement
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Tests.Semantics

-- ---------------------------------------------------------------------------------------------
-- The relation: turn, reserved and centre turn lane refine lane; one-way roadway refines roadway;
-- nothing else refines anything.
-- ---------------------------------------------------------------------------------------------
def structureKinds : List StructureKind :=
  atomIds.filterMap fun id => if id.startsWith "st." then StructureKind.ofString (id.drop 3).toString else none
#guard structureKinds.filter (·.parent?.isSome) = [.oneWayRoadway, .reservedLane, .centreTurnLane, .turnLane]
#guard StructureKind.parent? .turnLane = some .lane
#guard StructureKind.parent? .oneWayRoadway = some .roadway
#guard StructureKind.parent? .bicycleLaneOrPath = none
#guard structureKinds.all fun k => k.refines k
#guard structureKinds.all fun k => k.ancestors = k.parent?.toList

def st (id : Nat) (k : StructureKind) (u : List StructureKind := []) : Structure := { id := id, kind := k, unobservedKinds := u }

-- forward, and never in reverse, between siblings, or by lying on a way
#guard [StructureKind.turnLane, .reservedLane, .centreTurnLane].all fun k => (st 1 k).isOfKind .lane = some true
#guard (st 1 .oneWayRoadway).isOfKind .roadway = some true
#guard [StructureKind.turnLane, .reservedLane, .centreTurnLane].all fun k => (st 1 .lane).isOfKind k = some false
#guard (st 1 .roadway).isOfKind .oneWayRoadway = some false
#guard (st 1 .turnLane).isOfKind .reservedLane = some false
#guard (st 1 .turnLane).isOfKind .centreTurnLane = some false
#guard (st 1 .reservedLane).isOfKind .turnLane = some false
#guard (st 1 .centreTurnLane).isOfKind .reservedLane = some false
#guard (st 1 .bicycleLaneOrPath).isOfKind .lane = some false
#guard (st 1 .oneWayRoadway).isOfKind .lane = some false
#guard (st 1 .turnLane).isOfKind .roadway = some false
#guard ({ st 1 .sidewalk with ways := some [9] } : Structure).isOfKind .highway = some false

-- a child's mask: unknown only on regions labelled with an ancestor of the child
#guard (st 1 .lane [.turnLane]).isOfKind .turnLane = none
#guard (st 1 .lane [.turnLane]).isOfKind .lane = some true
#guard (st 1 .sidewalk [.turnLane]).isOfKind .turnLane = some false
#guard (st 1 .roadway [.turnLane]).isOfKind .turnLane = some false
#guard (st 1 .reservedLane [.turnLane]).isOfKind .turnLane = some false
#guard (st 1 .turnLane [.turnLane]).isOfKind .turnLane = none            -- the label cannot be trusted
#guard (st 1 .roadway [.oneWayRoadway]).isOfKind .oneWayRoadway = none
#guard (st 1 .lane [.oneWayRoadway]).isOfKind .oneWayRoadway = some false
-- a parent's mask keeps its global meaning, and reaches every kind refining it
#guard (st 1 .lane [.lane]).isOfKind .lane = none
#guard (st 1 .turnLane [.lane]).isOfKind .lane = none
#guard (st 1 .sidewalk [.lane]).isOfKind .lane = none
#guard (st 1 .turnLane [.lane]).isOfKind .turnLane = none
#guard (st 1 .sidewalk [.lane]).isOfKind .turnLane = none              -- no lane can be told, so no turn lane

-- ---------------------------------------------------------------------------------------------
-- Quantifiers range over the candidates of the one membership; predicate and quantifier agree.
-- ---------------------------------------------------------------------------------------------
def users2 : List RoadUser := [{ track := 1 }, { track := 2 }]
def sceneOf (ss : List Structure) (occ : List (TrackId × RegionId)) : Scene :=
  { t := 0, users := users2, structures := ss, occupancyObserved := [1, 2], occupies := occ }
def ctxOf (s : Scene) : SemCtx := SemCtx.mk' [s] ρ β
def occ (v r : String) : Formula := .atom "rel_occupies" [.var v, .var r] []
def ex (s : Scene) (k : String) (φ : Formula) : Tri := (eval (ctxOf s) 0 (.existsRegion (.lit k) "r" φ)).v
def all (s : Scene) (k : String) (φ : Formula) : Tri := (eval (ctxOf s) 0 (.forallRegion (.lit k) "r" φ)).v

-- known: a turn lane is a lane
def sKnown : Scene := sceneOf [st 2 .turnLane, st 7 .sidewalk] [(1, 2)]
#guard regionCandidates sKnown .lane = [2]
#guard regionsOfKind sKnown .lane = [2]
#guard ex sKnown "lane" (occ "x" "r") = .t
#guard ex sKnown "lane" (occ "y" "r") = .f
#guard all sKnown "lane" (occ "x" "r") = .t
#guard all sKnown "lane" (occ "y" "r") = .f
#guard ex sKnown "reserved_lane" .tt = .f
-- unknown: a lane-labelled region the source cannot tell a turn lane; the sidewalk is known not one
def sUnknown : Scene := sceneOf [st 1 .lane [.turnLane], st 7 .sidewalk [.turnLane]] [(1, 1)]
#guard regionCandidates sUnknown .turnLane = [1]
#guard regionsOfKind sUnknown .turnLane = []
#guard ex sUnknown "turn_lane" (occ "x" "r") = .u
#guard ex sUnknown "turn_lane" (occ "y" "r") = .f
#guard all sUnknown "turn_lane" (occ "x" "r") = .t
#guard all sUnknown "turn_lane" (occ "y" "r") = .u
#guard ex sUnknown "lane" (occ "x" "r") = .t
#guard all sUnknown "lane" (occ "x" "r") = .t
-- empty: no region could be one
def sEmpty : Scene := sceneOf [st 7 .sidewalk [.turnLane]] []
#guard regionCandidates sEmpty .turnLane = []
#guard ex sEmpty "turn_lane" .tt = .f
#guard all sEmpty "turn_lane" .ff = .t

-- no region twice, within a scene and across scenes
def sMany : Scene := sceneOf [st 1 .lane [.turnLane, .reservedLane, .centreTurnLane], st 2 .turnLane [.lane, .turnLane]] []
#guard regionCandidates sMany .lane = [1, 2]
#guard regionCandidates sMany .turnLane = [1, 2]
#guard regionsOf (SemCtx.mk' [sMany, { sMany with t := 100 }] ρ β) .lane = [1, 2]

-- on a one-region scene, the quantifier with a true body is the kind atom, for every kind and mask
def probes : List Structure :=
  [st 1 .lane, st 1 .turnLane, st 1 .lane [.turnLane], st 1 .sidewalk [.turnLane], st 1 .turnLane [.lane],
   st 1 .roadway [.oneWayRoadway], st 1 .oneWayRoadway [.roadway], st 1 .sidewalk [.lane, .reservedLane]]
#guard probes.all fun p => structureKinds.all fun k =>
  let s := sceneOf [p] []
  ex s k.toString .tt == (eval (ctxOf s) 0 (.atom s!"st_{k}" [.nat 1] [])).v
  && (regionCandidates s k).contains 1 == (isKind s 1 k != some false)
  && (regionsOfKind s k).contains 1 == (isKind s 1 k == some true)

-- ---------------------------------------------------------------------------------------------
-- Two vehicles in one lane: three-valued over the lane candidates they share.
-- ---------------------------------------------------------------------------------------------
def carAt (id : Nat) (x : Int) : RoadUser :=
  { track := id, kin := { position := some (metres x, metres 0), heading := some (Q.ofInt 1, Q.ofInt 0) } }
def pair (r : Structure) : Scene :=
  { t := 0, users := [carAt 1 20, carAt 2 0], structures := [r, st 7 .sidewalk],
    occupancyObserved := [1, 2], occupies := [(1, r.id), (2, r.id), (2, 7)] }
#guard rel_ahead_in_lane (pair (st 3 .turnLane)) 1 2 = some true
#guard rel_ahead_in_lane (pair (st 3 .turnLane)) 2 1 = some false
#guard rel_ahead_in_lane (pair (st 3 .lane [.turnLane])) 1 2 = some true
#guard rel_ahead_in_lane (pair (st 3 .roadway [.lane])) 1 2 = none
#guard rel_ahead_in_lane (pair (st 3 .roadway [.lane])) 2 1 = some false
#guard rel_ahead_in_lane (pair (st 3 .bicycleLaneOrPath)) 1 2 = some false
#guard rel_ahead_in_lane (pair (st 3 .oneWayRoadway)) 1 2 = some false

-- ---------------------------------------------------------------------------------------------
-- A source that cannot tell turn, reserved or centre turn lanes still decides a lane quantifier.
-- ---------------------------------------------------------------------------------------------
def noLaneKinds : Manifest :=
  let full := Manifest.full "test"
  { full with entries := full.entries.map fun (id, c) =>
      if ["st.turn_lane", "st.reserved_lane", "st.centre_turn_lane"].contains id then (id, .absent) else (id, c) }
def roadScene : Scene :=
  { t := 0, users := [carAt 1 20, carAt 2 0, carAt 3 40],
    structures := [st 1 .lane, st 2 .lane, st 7 .sidewalk, st 8 .roadway],
    occupancyObserved := [1, 2, 3], occupies := [(1, 1), (2, 1), (3, 7), (1, 8), (2, 8)] }
def masked : Scene := mask noLaneKinds roadScene
def βm : Binding := ({} : Binding).bind "x" (.track 1) |>.bind "y" (.track 2) |>.bind "z" (.track 3)
def exm (k : String) (φ : Formula) : Tri := (eval (SemCtx.mk' [masked] ρ βm) 0 (.existsRegion (.lit k) "r" φ)).v
def allm (k : String) (φ : Formula) : Tri := (eval (SemCtx.mk' [masked] ρ βm) 0 (.forallRegion (.lit k) "r" φ)).v
#guard (masked.structures.map (·.unobservedKinds.length)) = [3, 3, 3, 3]
#guard regionCandidates masked .lane = [1, 2]
#guard exm "lane" (occ "x" "r") = .t
#guard exm "lane" (occ "z" "r") = .f
#guard allm "lane" (.not (occ "z" "r")) = .t
#guard allm "lane" (occ "x" "r") = .f
#guard exm "roadway" (occ "x" "r") = .t
#guard exm "turn_lane" (occ "x" "r") = .u
#guard exm "turn_lane" (occ "z" "r") = .f
#guard rel_ahead_in_lane masked 1 2 = some true
#guard rel_ahead_in_lane masked 1 3 = some false


-- ---------------------------------------------------------------------------------------------
-- The decision table, and a child's mask never making a known parent unknown.
-- ---------------------------------------------------------------------------------------------
def carla : List StructureKind := [.turnLane, .reservedLane, .centreTurnLane]
#guard (st 1 .lane carla).isOfKind .lane = some true
#guard (st 1 .lane carla).isOfKind .turnLane = none
#guard (st 1 .sidewalk carla).isOfKind .turnLane = some false
#guard (st 1 .turnLane [.turnLane]).isOfKind .lane = some true
#guard (st 1 .oneWayRoadway [.oneWayRoadway]).isOfKind .roadway = some true
#guard (st 1 .oneWayRoadway [.oneWayRoadway]).isOfKind .oneWayRoadway = none
#guard (st 1 .sidewalk [.roadway]).isOfKind .oneWayRoadway = none

-- the matrix: every kind under every mask set, predicate, quantifier, candidates and the lane relation agree
def maskSets : List (List StructureKind) :=
  [[], [.lane], [.turnLane], carla, [.roadway], [.oneWayRoadway], [.sidewalk], [.lane, .turnLane]]
def matrix : List Structure := structureKinds.flatMap fun k => maskSets.map fun m => st 1 k m
#guard matrix.all fun p => structureKinds.all fun k =>
  let s := sceneOf [p] []
  ex s k.toString .tt == (eval (ctxOf s) 0 (.atom s!"st_{k}" [.nat 1] [])).v
  && (regionCandidates s k).contains 1 == (isKind s 1 k != some false)
  && (regionsOfKind s k).contains 1 == (isKind s 1 k == some true)
#guard matrix.all fun p => rel_ahead_in_lane (pair { p with id := 3 }) 1 2 == p.isOfKind .lane

-- the support of a kind read covers the kinds whose masks decide it
#guard formulaAtomIds [.atom "st_turn_lane" [.nat 1] []] = ["st.turn_lane", "st.lane"]
#guard formulaAtomIds [.existsRegion (.lit "turn_lane") "r" .tt] = ["st.turn_lane", "st.lane"]
#guard formulaAtomIds [.atom "rel_ahead_in_lane" [.var "x", .var "y"] []] = ["rel.ahead_behind_in_lane", "st.lane"]
#guard formulaAtomIds [.atom "st_sidewalk" [.nat 1] []] = ["st.sidewalk"]
def laneAbsent : Manifest :=
  let full := Manifest.full "test"
  { full with entries := full.entries.map fun (id, c) => if id == "st.lane" then (id, .absent) else (id, c) }
def turnRule : Rule :=
  { id := "t", laws := [], binders := [⟨"x", .tt⟩], applicability := .tt, obligation := .atom "st_turn_lane" [.nat 1] [] }
#guard support [] turnRule laneAbsent = .partially ["st.lane"]           -- no longer reported supported
#guard support [] turnRule (Manifest.full "test") = .supported

end TrafficSpec.Tests.Refinement

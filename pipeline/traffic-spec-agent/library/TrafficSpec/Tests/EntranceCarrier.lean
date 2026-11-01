import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Runtime.Manifest
namespace TrafficSpec.Tests.EntranceCarrier
open TrafficSpec TrafficSpec.Semantics Units

-- ---------------------------------------------------------------------------------------------
-- A two-way road with no lanes between junction 50 (west) and junction 60 (east), on way 1. The
-- source separates its directions: segment 21 runs east into 60, segment 22 runs west into 50;
-- both cover the same pavement and stay roadways. Road 20 is the whole two-way roadway. Lane 10
-- runs east into 60 with shoulder 23 beside it, and lane 12 runs east into 60 beside lane 10.
-- ---------------------------------------------------------------------------------------------
def pave : List Vec := [(metres 0, metres (-4)), (metres 100, metres (-4)), (metres 100, metres 4), (metres 0, metres 4)]
def way1 : Structure := { id := 1, kind := .highway }
def junction (id : Nat) : Structure := { id := id, kind := .intersection, ways := some [1] }
def east : Vec := (Q.ofInt 1, Q.zero)
def west : Vec := (Q.ofInt (-1), Q.zero)
def carrier (id : Nat) (k : StructureKind) (dir : Option Vec) (j : Option Nat) : Structure :=
  { id := id, kind := k, ways := some [1], boundary := some pave, lane := some { direction := dir, entersIntersection := j } }
def segE : Structure := carrier 21 .roadway (some east) (some 60)
def segW : Structure := carrier 22 .roadway (some west) (some 50)
def whole : Structure := { id := 20, kind := .roadway, ways := some [1], boundary := some pave }
def lane10 : Structure := carrier 10 .lane (some east) (some 60)
def lane12 : Structure := carrier 12 .lane (some east) (some 60)
def shoulder23 : Structure := carrier 23 .shoulder (some east) (some 60)
def mark (id : Nat) (k : StructureKind) (carriers : Option (List RegionId)) : Structure :=
  match carriers with
  | some cs => { id := id, kind := k, ways := some [1], entranceOf := cs, entranceObserved := true }
  | none => { id := id, kind := k, ways := some [1] }
def scene (structures : List Structure) (users : List RoadUser := []) (occ : List (TrackId × RegionId) := []) (devs : List Device := []) : Scene :=
  { t := 0, structures := [way1, junction 50, junction 60] ++ structures, users := users,
    occupancyObserved := users.map (·.track), occupies := occ, devices := devs }

def at0 (s : Scene) (φ : Formula) : Tri := evalTri (SemCtx.mk' [s] {}) 0 φ
/-- A line of kind `k` marks carrier `c`'s entrance, and `c` enters junction `j`: the same `c` in both. -/
def lineOf (k : String) (c j : Arg) : Formula :=
  .existsRegion (.lit k) "m" (.and (.atom "st_entrance_of" [.var "m", c] []) (.atom "st_lane_enters" [c, j] []))

-- both ends of the two-way road, supplied as two directed segments
def ends : Scene := scene [segE, segW, mark 41 .stopLine (some [21]), mark 42 .stopLine (some [22])]
#guard st_lane_enters ends 21 = some 60
#guard st_lane_enters ends 22 = some 50
#guard at0 ends (lineOf "stop_line" (.nat 21) (.nat 60)) = .t
#guard at0 ends (lineOf "stop_line" (.nat 21) (.nat 50)) = .f
#guard at0 ends (lineOf "stop_line" (.nat 22) (.nat 50)) = .t
#guard at0 ends (lineOf "stop_line" (.nat 22) (.nat 60)) = .f
#guard st_entrance_of ends 41 22 = some false
#guard st_entrance_of ends 42 21 = some false
#guard TraceLint.checkTrace [ends] = []

-- the whole two-way roadway, no segments: lawful, and every entrance judgment unknown
def wholeOnly : Scene := scene [whole, mark 41 .stopLine none, mark 42 .stopLine none]
#guard st_lane_enters wholeOnly 20 = none
#guard at0 wholeOnly (lineOf "stop_line" (.nat 20) (.nat 60)) = .u
#guard at0 wholeOnly (lineOf "stop_line" (.nat 20) (.nat 50)) = .u
#guard TraceLint.checkTrace [wholeOnly] = []
-- a line that lists the whole roadway cannot give it an entrance: which junction stays unknown
def wholeListed : Scene := scene [whole, mark 41 .stopLine (some [20])]
#guard st_entrance_of wholeListed 41 20 = some true
#guard at0 wholeListed (lineOf "stop_line" (.nat 20) (.nat 60)) = .u
#guard TraceLint.checkTrace [wholeListed] = []

-- a shoulder beside a lane: each has its own entrance; the lane's line is not the shoulder's
def besideLane : Scene := scene [lane10, shoulder23, mark 43 .stopLine (some [10]), mark 44 .stopLine (some [23])]
#guard st_lane_enters besideLane 23 = some 60
#guard st_entrance_of besideLane 43 23 = some false
#guard at0 besideLane (lineOf "stop_line" (.nat 23) (.nat 60)) = .t
#guard at0 besideLane (.atom "st_entrance_of" [.nat 43, .nat 23] []) = .f
#guard TraceLint.checkTrace [besideLane] = []

-- one line across several lanes and a roadway segment
def across : Scene := scene [lane10, lane12, segE, segW, mark 45 .stopLine (some [10, 12, 21])]
#guard [10, 12, 21].all fun c => st_entrance_of across 45 c = some true
#guard st_entrance_of across 45 22 = some false
#guard [10, 12, 21].all fun c => at0 across (lineOf "stop_line" (.nat c) (.nat 60)) = .t
#guard at0 across (lineOf "stop_line" (.nat 22) (.nat 50)) = .f
#guard TraceLint.checkTrace [across] = []

-- the association missing (unknown) against explicitly excluded (false)
#guard st_entrance_of (scene [segE, mark 41 .stopLine none]) 41 21 = none
#guard st_entrance_of (scene [segE, mark 41 .stopLine (some [])]) 41 21 = some false
#guard st_entrance_of (scene [segE, segW, mark 41 .stopLine (some [22])]) 41 21 = some false
#guard at0 (scene [segE, mark 41 .stopLine none]) (lineOf "stop_line" (.nat 21) (.nat 60)) = .u
#guard at0 (scene [segE, mark 41 .stopLine (some [])]) (lineOf "stop_line" (.nat 21) (.nat 60)) = .f

-- overlapping carriers inherit neither an entrance nor a device's governance
def sig : Device := { id := 9, kind := .trafficSignal, governs := [21] }
def onlyEast : Scene := scene [segE, carrier 22 .roadway (some west) none, mark 41 .stopLine (some [21])] (devs := [sig])
#guard st_lane_enters onlyEast 22 = none
#guard at0 onlyEast (.atom "st_lane_enters" [.nat 22, .nat 60] []) = .u
#guard st_entrance_of onlyEast 41 22 = some false
#guard dev_governs onlyEast 9 21 = some true
#guard dev_governs onlyEast 9 22 = some false

-- a missing direction is not missing topology: the entrance is decided, the direction unknown
def noDir : Scene := scene [carrier 21 .roadway none (some 60), mark 41 .stopLine (some [21])]
#guard st_lane_enters noDir 21 = some 60
#guard st_lane_direction noDir 21 = none
#guard at0 noDir (lineOf "stop_line" (.nat 21) (.nat 60)) = .t
#guard TraceLint.checkTrace [noDir] = []

-- ---------------------------------------------------------------------------------------------
-- Which carrier a road user approaches through, written with the atoms: a carrier it occupies whose
-- entrance end is the intersection the rule reads, and the line that governs is one the source
-- records as marking that carrier. Neither velocity nor heading is read.
-- ---------------------------------------------------------------------------------------------
def X : Arg := .nat 1
/-- The road user approaches junction `j` through carrier `c`. -/
def approach (c j : Arg) : Formula :=
  .and (.atom "rel_occupies" [X, c] []) (.atom "st_lane_enters" [c, j] [])
/-- Stop line `m` governs the road user's approach to junction `j`. -/
def governing (m j : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "c" (.and (approach (.var "c") j) (.atom "st_entrance_of" [m, .var "c"] []))
/-- An act judged per line, standing for what a rule requires at it: here, the road user's body
    is clear of the line. -/
def act (m : Arg) : Formula := .not (.atom "rel_occupies" [X, m] [])
/-- The verdict through carrier `c`: the act holds at every stop line marking `c`. -/
def through (c : Arg) : Formula :=
  .forallRegion (.lit "stop_line") "m" (.implies (.atom "st_entrance_of" [.var "m", c] []) (act (.var "m")))
/-- The verdict on the approach to `j`: decided where it is the same through every carrier the road
    user approaches `j` through, unknown where it differs. -/
def onApproach (j : Arg) : Formula :=
  let each (ψ : Arg → Formula) : Formula :=
    .forallRegion (.lit "travel_region") "c" (.implies (approach (.var "c") j) (ψ (.var "c")))
  .definedWhen (.or (each through) (each fun c => .not (through c))) (each through)

def car (v : Option Vec) (h : Option Vec) : RoadUser :=
  { track := 1, classes := some [.motorVehicle], kin := { position := some (metres 50, metres 0), velocity := v, heading := h } }
def v (x y : Int) : Option Vec := some (metresPerSecond x, metresPerSecond y)
def h (x y : Int) : Option Vec := some (Q.ofInt x, Q.ofInt y)
def motions : List RoadUser :=
  [car (v 5 0) (h 1 0), car (v (-5) 0) (h (-1) 0), car (v 0 0) (h 1 0), car (v 0 0) (h 0 1),
   car (v 2 0) (h (-1) 0), car (v (-2) 0) (h 1 0), car none (h (-1) 0), car (v 5 0) none, car none none]

-- (a) facing west while backing east on both overlapping segments: the junction entered decides.
-- Entering the east junction, the approach is the eastbound segment and its line 41 governs, line
-- 42 does not; entering the west junction, the other way round; the same for every motion
def on (u : RoadUser) : Scene :=
  scene [segE, segW, mark 41 .stopLine (some [21]), mark 42 .stopLine (some [22])] [u] [(1, 21), (1, 22)]
def backing : Scene := on (car (v 2 0) (h (-1) 0))
#guard at0 backing (.atom "rel_occupies" [X, .nat 21] []) = .t
#guard at0 backing (.atom "rel_occupies" [X, .nat 22] []) = .t
#guard at0 backing (approach (.nat 21) (.nat 60)) = .t
#guard at0 backing (approach (.nat 22) (.nat 60)) = .f
#guard at0 backing (governing (.nat 41) (.nat 60)) = .t
#guard at0 backing (governing (.nat 42) (.nat 60)) = .f
#guard at0 backing (governing (.nat 42) (.nat 50)) = .t
#guard at0 backing (governing (.nat 41) (.nat 50)) = .f
#guard motions.all fun u =>
  [((41 : Nat), (60 : Nat), Tri.t), (42, 60, .f), (42, 50, .t), (41, 50, .f)].all fun (m, j, r) =>
    at0 (on u) (governing (.nat m) (.nat j)) == r

-- (b) one carrier, velocity and heading unobserved: it is the approach, and its line governs
def alone (k : StructureKind) (over : List Nat := []) : Scene :=
  scene [carrier 21 k (some east) (some 60), mark 41 .stopLine (some [21])] [car none none] ((21 :: over).map (1, ·))
#guard [StructureKind.lane, .roadway, .oneWayRoadway, .shoulder].all fun k =>
  at0 (alone k) (approach (.nat 21) (.nat 60)) == .t && at0 (alone k) (governing (.nat 41) (.nat 60)) == .t
#guard at0 (alone .roadway) (onApproach (.nat 60)) = .t
#guard at0 (alone .roadway [41]) (onApproach (.nat 60)) = .f

-- (c) two carriers entering the same junction, each with its own line: decided where the act holds
-- at both lines or at neither, unknown where it holds at one only, whatever the motion. `over`
-- lists the lines the road user's body is on
def straddle (u : RoadUser) (marks : List Structure) (over : List Nat) : Scene :=
  scene ([lane10, lane12] ++ marks) [u] (([10, 12] ++ over).map (1, ·))
def twoLines : List Structure := [mark 43 .stopLine (some [10]), mark 46 .stopLine (some [12])]
#guard motions.all fun u =>
  at0 (straddle u twoLines []) (onApproach (.nat 60)) == .t
    && at0 (straddle u twoLines [43, 46]) (onApproach (.nat 60)) == .f
    && at0 (straddle u twoLines [46]) (onApproach (.nat 60)) == .u
    && at0 (straddle u twoLines [43]) (onApproach (.nat 60)) == .u
-- one line marking both: the same verdict through each, decided
#guard at0 (straddle (car none none) [mark 43 .stopLine (some [10, 12])] []) (onApproach (.nat 60)) = .t
#guard at0 (straddle (car none none) [mark 43 .stopLine (some [10, 12])] [43]) (onApproach (.nat 60)) = .f

-- (d) line 46's entrances unobserved: it may mark either lane, or neither. The verdict is decided
-- only where no completion of its list can change it, that is where the act holds at every line;
-- where the act fails at a line whose association is unobserved, that line may govern one approach
-- and not the other (or none), so the verdict is unknown
def oneOpen : List Structure := [mark 43 .stopLine (some [10]), mark 46 .stopLine none]
#guard at0 (straddle (car none none) oneOpen []) (onApproach (.nat 60)) = .t
#guard at0 (straddle (car none none) oneOpen [46]) (onApproach (.nat 60)) = .u
#guard at0 (straddle (car none none) oneOpen [43]) (onApproach (.nat 60)) = .u
#guard at0 (straddle (car none none) oneOpen [43, 46]) (onApproach (.nat 60)) = .u
#guard at0 (straddle (car none none) oneOpen [43]) (through (.nat 12)) = .t
#guard at0 (straddle (car none none) oneOpen [46]) (through (.nat 12)) = .u

-- (e) the wrong way along a one-way roadway entering junction 60, at its far end by junction 50:
-- no approach to 50 through it, so no line governs one; the carrier still enters 60
def wrongWay : Scene :=
  scene [carrier 25 .oneWayRoadway (some east) (some 60), mark 47 .stopLine (some [25])] [car (v (-5) 0) (h (-1) 0)] [(1, 25)]
#guard at0 wrongWay (approach (.nat 25) (.nat 50)) = .f
#guard at0 wrongWay (.existsRegion (.lit "travel_region") "c" (approach (.var "c") (.nat 50))) = .f
#guard at0 wrongWay (governing (.nat 47) (.nat 50)) = .f
#guard at0 wrongWay (approach (.nat 25) (.nat 60)) = .t

-- ---------------------------------------------------------------------------------------------
-- A bicycle lane or path as an entrance carrier: a directed approach segment the source records, as
-- a roadway segment is, and its own kind, never a lane. Bicycle path segments 31 (east into 60) and
-- 32 (west into 50) run beside lane 10 (east into 60); path 30 is a whole two-way bicycle path.
-- ---------------------------------------------------------------------------------------------
def bikeE : Structure := carrier 31 .bicycleLaneOrPath (some east) (some 60)
def bikeW : Structure := carrier 32 .bicycleLaneOrPath (some west) (some 50)
def wholeBike : Structure := { id := 30, kind := .bicycleLaneOrPath, ways := some [1], boundary := some pave }

-- two segments of opposite direction, each entering its own junction, each with its own line
def bikeEnds : Scene := scene [bikeE, bikeW, mark 48 .stopLine (some [31]), mark 49 .stopLine (some [32])]
#guard st_lane_enters bikeEnds 31 = some 60
#guard st_lane_enters bikeEnds 32 = some 50
#guard at0 bikeEnds (lineOf "stop_line" (.nat 31) (.nat 60)) = .t
#guard at0 bikeEnds (lineOf "stop_line" (.nat 32) (.nat 50)) = .t
#guard at0 bikeEnds (lineOf "stop_line" (.nat 31) (.nat 50)) = .f
#guard st_entrance_of bikeEnds 48 32 = some false
#guard st_bicycle_lane_or_path bikeEnds 31 = some true
#guard st_lane bikeEnds 31 = some false
#guard TraceLint.checkTrace [bikeEnds] = []

-- a line marking the bicycle carrier alone, a line marking the lane alone, and a line spanning both
def beside (marks : List Structure) : Scene := scene ([lane10, bikeE] ++ marks)
def ownLines : Scene := beside [mark 43 .stopLine (some [10]), mark 48 .stopLine (some [31])]
#guard st_entrance_of ownLines 48 31 = some true
#guard st_entrance_of ownLines 48 10 = some false
#guard st_entrance_of ownLines 43 31 = some false
#guard at0 ownLines (lineOf "stop_line" (.nat 31) (.nat 60)) = .t
#guard TraceLint.checkTrace [ownLines] = []
def spanning : Scene := beside [mark 45 .stopLine (some [10, 31])]
#guard [10, 31].all fun c => at0 spanning (lineOf "stop_line" (.nat c) (.nat 60)) == .t
#guard TraceLint.checkTrace [spanning] = []

-- no propagation between the bicycle carrier and the lane beside it: a rider on the path is
-- governed by the path's line, a driver in the lane by the lane's, whatever the motion; a device's
-- governance stays on the carrier it names
def rider (u : RoadUser) (c : Nat) : Scene :=
  scene [lane10, bikeE, mark 43 .stopLine (some [10]), mark 48 .stopLine (some [31])] [u] [(1, c)]
#guard motions.all fun u =>
  at0 (rider u 31) (governing (.nat 48) (.nat 60)) == .t && at0 (rider u 31) (governing (.nat 43) (.nat 60)) == .f
    && at0 (rider u 10) (governing (.nat 43) (.nat 60)) == .t && at0 (rider u 10) (governing (.nat 48) (.nat 60)) == .f
def laneSignal : Scene := scene [lane10, bikeE] (devs := [{ id := 9, kind := .trafficSignal, governs := [10] }])
def pathSignal : Scene := scene [lane10, bikeE] (devs := [{ id := 9, kind := .trafficSignal, governs := [31] }])
#guard dev_governs laneSignal 9 10 = some true
#guard dev_governs laneSignal 9 31 = some false
#guard dev_governs pathSignal 9 31 = some true
#guard dev_governs pathSignal 9 10 = some false

-- the association unobserved (unknown) against observed and excluding (false)
#guard st_entrance_of (beside [mark 48 .stopLine none]) 48 31 = none
#guard at0 (beside [mark 48 .stopLine none]) (lineOf "stop_line" (.nat 31) (.nat 60)) = .u
#guard st_entrance_of (beside [mark 43 .stopLine (some [10])]) 43 31 = some false
#guard at0 (beside [mark 43 .stopLine (some [10])]) (.atom "st_entrance_of" [.nat 43, .nat 31] []) = .f

-- known topology with no direction: the entrance stays decided, the direction unknown, and a
-- rider's velocity never stands in for it
def bikeNoDir (u : RoadUser) : Scene :=
  scene [carrier 31 .bicycleLaneOrPath none (some 60), mark 48 .stopLine (some [31])] [u] [(1, 31)]
#guard motions.all fun u =>
  st_lane_enters (bikeNoDir u) 31 == some 60 && st_lane_direction (bikeNoDir u) 31 == none
    && at0 (bikeNoDir u) (governing (.nat 48) (.nat 60)) == .t
#guard TraceLint.checkTrace [scene [carrier 31 .bicycleLaneOrPath none (some 60), mark 48 .stopLine (some [31])]] = []

-- the whole two-way bicycle path, as the whole roadway: it carries no entrance, so every entrance
-- judgment through it is unknown, and a line listing it gives it none
def wholeBikeListed : Scene := scene [wholeBike, mark 48 .stopLine (some [30])]
#guard st_lane_enters wholeBikeListed 30 = none
#guard st_entrance_of wholeBikeListed 48 30 = some true
#guard at0 wholeBikeListed (lineOf "stop_line" (.nat 30) (.nat 60)) = .u
#guard at0 wholeBikeListed (lineOf "stop_line" (.nat 30) (.nat 50)) = .u
#guard TraceLint.checkTrace [wholeBikeListed] = []

-- the same through the decoder
def bikeTrace : String :=
  "{\"scenes\": [{\"t\": 0, \"structures\": [{\"id\": 50, \"kind\": \"intersection\"}, {\"id\": 60, \"kind\": \"intersection\"}, " ++
  "{\"id\": 10, \"kind\": \"lane\", \"lane\": {\"direction\": [1, 0], \"enters_intersection\": 60}}, " ++
  "{\"id\": 31, \"kind\": \"bicycle_lane_or_path\", \"lane\": {\"direction\": [1, 0], \"enters_intersection\": 60}}, " ++
  "{\"id\": 32, \"kind\": \"bicycle_lane_or_path\", \"lane\": {\"direction\": [-1, 0], \"enters_intersection\": 50}}, " ++
  "{\"id\": 33, \"kind\": \"bicycle_lane_or_path\", \"lane\": {\"enters_intersection\": 60}}, " ++
  "{\"id\": 30, \"kind\": \"bicycle_lane_or_path\"}, " ++
  "{\"id\": 43, \"kind\": \"stop_line\", \"entrance_of\": [10]}, " ++
  "{\"id\": 48, \"kind\": \"stop_line\", \"entrance_of\": [31]}, " ++
  "{\"id\": 49, \"kind\": \"stop_line\", \"entrance_of\": [32, 33]}, " ++
  "{\"id\": 45, \"kind\": \"stop_line\", \"entrance_of\": [10, 31]}, " ++
  "{\"id\": 46, \"kind\": \"stop_line\"}, " ++
  "{\"id\": 47, \"kind\": \"crosswalk\", \"entrance_of\": [30]}]}]}"
def bikeτ : Trace := (Decode.parse Decode.trace bikeTrace).toOption.getD []
def bs : Scene := bikeτ[0]!
#guard bikeτ.length = 1
#guard TraceLint.checkTrace bikeτ = []
#guard (st_lane_enters bs 31, st_lane_enters bs 32, st_lane_enters bs 33, st_lane_enters bs 30) = (some 60, some 50, some 60, none)
#guard st_lane_direction bs 33 = none
#guard (st_entrance_of bs 48 31, st_entrance_of bs 48 10, st_entrance_of bs 43 31) = (some true, some false, some false)
#guard (st_entrance_of bs 45 10, st_entrance_of bs 45 31) = (some true, some true)
#guard (st_entrance_of bs 46 31, st_entrance_of bs 49 31) = (none, some false)
#guard at0 bs (lineOf "stop_line" (.nat 32) (.nat 50)) = .t
#guard at0 bs (lineOf "stop_line" (.nat 33) (.nat 60)) = .t
#guard at0 bs (lineOf "crosswalk" (.nat 30) (.nat 60)) = .u
#guard (st_bicycle_lane_or_path bs 31, st_lane bs 31) = (some true, some false)

-- ---------------------------------------------------------------------------------------------
-- The trace check: which kinds carry `enters_intersection` and which an `entrance_of` entry names
-- ---------------------------------------------------------------------------------------------
def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1
def withKind (k : StructureKind) : Scene := scene [carrier 30 k (some east) (some 60)]
#guard [StructureKind.lane, .reservedLane, .turnLane, .roadway, .oneWayRoadway, .shoulder, .bicycleLaneOrPath].all fun k =>
  TraceLint.checkTrace [withKind k] = []
#guard TraceLint.checkTrace [scene [carrier 30 .centreTurnLane none (some 60)]] = []
#guard [StructureKind.sidewalk, .intersection, .crosswalk, .medianOrDivider].all fun k =>
  has (TraceLint.checkTrace [scene [carrier 30 k none (some 60)]]) s!"structure 30 ({k}) carries lane.enters_intersection; only a lane, a roadway, a shoulder or a bicycle lane or path"
def entryOf (k : StructureKind) : Scene := scene [{ id := 30, kind := k, ways := some [1] }, mark 41 .stopLine (some [30])]
#guard [StructureKind.lane, .reservedLane, .turnLane, .centreTurnLane, .roadway, .oneWayRoadway, .shoulder, .bicycleLaneOrPath].all fun k =>
  TraceLint.checkTrace [entryOf k] = []
#guard [StructureKind.sidewalk, .intersection, .medianOrDivider, .crosswalk].all fun k =>
  has (TraceLint.checkTrace [entryOf k]) "entrance_of names region 30, which is not a lane, roadway, shoulder or bicycle_lane_or_path"

-- the trace as written: a roadway segment through decode and the check
def segmentTrace : String :=
  "{\"scenes\": [{\"t\": 0, \"structures\": [{\"id\": 50, \"kind\": \"intersection\"}, " ++
  "{\"id\": 21, \"kind\": \"roadway\", \"lane\": {\"direction\": [1, 0], \"enters_intersection\": 50}}, " ++
  "{\"id\": 22, \"kind\": \"shoulder\", \"lane\": {\"enters_intersection\": 50}}, " ++
  "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [21, 22]}]}]}"
#guard (Decode.parse Decode.trace segmentTrace).toOption.map (fun τ => TraceLint.checkTrace τ) = some []
#guard (Decode.parse Decode.trace segmentTrace).toOption.map (fun τ => (st_lane_enters τ[0]! 21, st_entrance_of τ[0]! 31 22)) = some (some 50, some true)

-- ---------------------------------------------------------------------------------------------
-- Support and masks: a read depends on no carrier kind, and an entrance's read on the line kinds; a
-- mask blanks the relation on every carrier, and a source that cannot tell a refining kind reads the
-- entrance as before
-- ---------------------------------------------------------------------------------------------
#guard kindDependencies "st.lane_enters" = ["st.lane_enters"]
#guard kindDependencies "st.entrance_of" = ["st.entrance_of", "st.stop_line", "st.crosswalk"]
def withAbsent (ids : List String) : Manifest :=
  let full := Manifest.full "test"
  { full with entries := full.entries.map fun (id, c) => if ids.contains id then (id, .absent) else (id, c) }
def entRule : Rule :=
  { id := "t", laws := [], binders := [⟨"x", .tt⟩], applicability := .tt,
    obligation := .existsRegion (.lit "lane") "c" (.existsRegion (.lit "intersection") "j" (lineOf "stop_line" (.var "c") (.var "j"))) }
#guard support [] entRule (withAbsent ["st.roadway", "st.shoulder"]) = .supported
#guard support [] entRule (withAbsent ["st.crosswalk"]) = .partially ["st.crosswalk"]
#guard st_lane_enters (Mask.scene "st.lane_enters" ends) 21 = none
#guard st_lane_enters (Mask.scene "st.lane_enters" besideLane) 23 = none
#guard st_entrance_of (Mask.scene "st.entrance_of" ends) 41 21 = none
def oneWay : Scene := scene [carrier 21 .oneWayRoadway (some east) (some 60), mark 41 .stopLine (some [21])]
#guard at0 (Mask.scene "st.one_way_roadway" oneWay) (lineOf "stop_line" (.nat 21) (.nat 60)) = .t
#guard at0 (Mask.scene "st.roadway" ends) (lineOf "stop_line" (.nat 21) (.nat 60)) = .t

end TrafficSpec.Tests.EntranceCarrier

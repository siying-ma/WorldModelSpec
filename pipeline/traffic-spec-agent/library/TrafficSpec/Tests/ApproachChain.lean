import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
namespace TrafficSpec.Tests.ApproachChain
open TrafficSpec Units

/-
  An act due at a place before an event, read on the approach, written over any entrance carrier
  (a lane or a kind refining it, a roadway, one-way roadway, shoulder or bicycle lane or path that
  carries `st_lane_enters`) and run through the witness path (`Scenario.run`: admission, the
  manifest mask, the episode verdict and its reason checks).

  Two duties:
  - `approachEntry`: each entry into an intersection owes a halt, made before it, at a stop line
    governing the approach to that intersection, on it or short of it within the stop-point
    tolerance;
  - `approachPass`: each passing of a stop line owes a halt at that line, on it or short of it
    within the tolerance, before the passing.

  The approach to an intersection `i` at an observation is every carrier the road user occupies
  whose entrance end is `i`; a predicate read through the approach is decided only where it is the
  same through each such carrier, and unknown where it differs. A mark governs a carrier where the
  source lists it as marking that carrier. The side of a mark is the sign of
  `prim_region_offset_along` along the carrier (positive short of it, negative past it); every
  distance (the place's tolerance, the stopping zone) is the region distance
  `st_region_geometry_distance`. The approach start is an observation at which the road user, on a
  carrier a governing mark marks, is off, short of and farther than the tolerance from every mark
  of the kind marking that carrier. The search for the halt runs back from the event to the
  approach start or to the previous event for the same road user and place; whether the event
  happened is read from its observation and the one before, unknown where the one before shows the
  road user on no carrier.
-/

-- ---------------------------------------------------------------------------------------------
-- Formula pieces
-- ---------------------------------------------------------------------------------------------
def a (x : String) : Arg := .var x
def pTol : Term := .param "p.stop_point_tolerance"
def pStand : Term := .param "p.standstill_speed_tolerance"
def zeroM : Term := .lit (metres 0) .metre
def occ (x r : String) : Formula := .atom "rel_occupies" [a x, a r] []
def dist (x r : String) : Term := .measure "st_region_geometry_distance" [a x, a r]
def near (x r : String) : Formula := .cmp (dist x r) .le pTol
def far (x r : String) : Formula := .cmp (dist x r) .gt pTol
def halt (x : String) : Formula := .cmp (.measure "kin_speed" [a x]) .le pStand
def isJ (r : String) : Formula := .atom "st_intersection" [a r] []
def marks (m c : String) : Formula := .atom "st_entrance_of" [a m, a c] []
def enters (c i : String) : Formula := .atom "st_lane_enters" [a c, a i] []
def offAlong (x m c : String) : Term := .quantity "prim_region_offset_along" [a x, a m, a c] []
def ahead (x m c : String) : Formula := .cmp (offAlong x m c) .gt zeroM
def behind (x m c : String) : Formula := .cmp (offAlong x m c) .lt zeroM
/-- False where φ is false; unknown where φ holds or is unknown. -/
def unk (φ : Formula) : Formula := .definedWhen (.not φ) .ff
/-- ψ at the observation before, where ψ is false at this one. -/
def fell (ψ : Formula) : Formula := .rises (.not ψ)
def exK (k v : String) (φ : Formula) : Formula := .existsRegion (.lit k) v φ
def allK (k v : String) (φ : Formula) : Formula := .forallRegion (.lit k) v φ
/-- Over carriers: travel regions other than intersections. -/
def exC (c : String) (φ : Formula) : Formula := exK "travel_region" c (.and (.not (isJ c)) φ)
def allC (c : String) (φ : Formula) : Formula := allK "travel_region" c (.implies (.not (isJ c)) φ)

-- ---------------------------------------------------------------------------------------------
-- The approach and the agreement over its carriers
-- ---------------------------------------------------------------------------------------------
/-- x approaches i through carrier c: x occupies c and c enters i. -/
def appr (x c i : String) : Formula := .and (occ x c) (enters c i)
def someC (x i n : String) : Formula := exC n (appr x n i)
def each (x i n : String) (P : String → Formula) : Formula := allC n (.implies (appr x n i) (P n))
/-- P through x's approach to i: decided where it is the same through every carrier of the approach,
    unknown (undefined) where it differs; false where x approaches i through no carrier. -/
def through (x i n : String) (P : String → Formula) : Formula :=
  .and (someC x i (n ++ "s"))
    (.definedWhen (.or (each x i (n ++ "a") P) (each x i (n ++ "b") fun c => .not (P c))) (each x i (n ++ "c") P))
/-- x occupies no carrier. -/
def offCarrier (x : String) : Formula := allC (x ++ "_oc") (.not (occ x (x ++ "_oc")))

/-- Off mark t, farther from it than the tolerance, and short of it along c. -/
def outsideT (x t c : String) : Formula := .and (.not (occ x t)) (.and (far x t) (ahead x t c))
/-- Outside the stopping zone of every stop line marking c, and short of each. -/
def zoneOut (x c : String) : Formula :=
  allK "stop_line" (c ++ "_t") (.implies (marks (c ++ "_t") c) (outsideT x (c ++ "_t") c))

-- ---------------------------------------------------------------------------------------------
-- E: the entry into an intersection
-- ---------------------------------------------------------------------------------------------
def hasLine (c : String) : Formula := exK "stop_line" (c ++ "_h") (marks (c ++ "_h") c)
def placeE (x c : String) : Formula :=
  let m := c ++ "_m"
  exK "stop_line" m (.and (marks m c) (.and (near x m) (.or (occ x m) (ahead x m c))))
def startE (x c : String) : Formula := .and (hasLine c) (zoneOut x c)
/-- A stop line governs x's approach to i; unknown where x is on no carrier. -/
def govE (x i : String) : Formula := .or (through x i "g" hasLine) (unk (offCarrier x))
def epE (x i : String) : Formula := .and (.not (occ x i)) (.not (through x i "z" (startE x)))
def actE (x i : String) : Formula := .and (.not (occ x i)) (.and (halt x) (through x i "p" (placeE x)))
def searchE (x i : String) : Formula := .since (epE x i) (actE x i)
def trigE (x i : String) : Formula := .rises (occ x i)
def eventE (x i : String) : Formula := .and (trigE x i) (fell (.and (.not (occ x i)) (govE x i)))
def foundE (x i : String) : Formula := fell (searchE x i)
/-- The act found on the stretch where a line governs x's approach (or x is on no carrier): what the
    applicability reads where the governance at the event is not decided. -/
def foundGovE (x i : String) : Formula := fell (.since (.and (epE x i) (govE x i)) (actE x i))

def subjectCls : Formula := .or (.atom "ru_motor_vehicle" [a "v"] []) (.atom "ru_bicycle" [a "v"] [])

def approachEntry : Rule :=
  { id := "t/approach_entry", laws := []
    binders := [{ name := "v", cls := subjectCls }]
    applicability := exK "intersection" "i" (.and (trigE "v" "i") (.or (fell (.and (.not (occ "v" "i")) (govE "v" "i"))) (foundGovE "v" "i")))
    obligation := allK "intersection" "i" (.implies (eventE "v" "i") (foundE "v" "i")) }

-- ---------------------------------------------------------------------------------------------
-- M: the passing of a stop line
-- ---------------------------------------------------------------------------------------------
/-- Mark s marks an entrance into i. -/
def gi (s i : String) : Formula := exC (s ++ "_gc") (.and (marks s (s ++ "_gc")) (enters (s ++ "_gc") i))
/-- P through x's approach to an intersection s marks an entrance into. -/
def throughM (x s n : String) (P : String → Formula) : Formula :=
  exK "intersection" (n ++ "_i") (.and (gi s (n ++ "_i")) (through x (n ++ "_i") n P))
def shortM (x s c : String) : Formula := .and (marks s c) (.or (occ x s) (ahead x s c))
def placeM (x s c : String) : Formula := .and (marks s c) (.and (near x s) (.or (occ x s) (ahead x s c)))
def startM (x s c : String) : Formula := .and (marks s c) (zoneOut x c)
/-- Wholly past s: off it, behind it along a carrier it marks that x is on or whose intersection x is in. -/
def past (x s : String) : Formula :=
  let c := s ++ "_pc"
  .and (.not (occ x s)) (exC c (.and (marks s c) (.and (behind x s c)
    (.or (occ x c) (exK "intersection" (c ++ "_j") (.and (enters c (c ++ "_j")) (occ x (c ++ "_j"))))))))
def prevM (x s : String) : Formula := .or (throughM x s "q" (shortM x s)) (unk (offCarrier x))
def epM (x s : String) : Formula := .and (.not (past x s)) (.not (throughM x s "z" (startM x s)))
def actM (x s : String) : Formula := .and (halt x) (throughM x s "p" (placeM x s))
def foundM (x s : String) : Formula := fell (.and (.not (past x s)) (.since (epM x s) (actM x s)))
/-- s governs x's approach (or x is on no carrier). -/
def govM (x s : String) : Formula := .or (throughM x s "r" (marks s)) (unk (offCarrier x))
def foundGovM (x s : String) : Formula := fell (.and (.not (past x s)) (.since (.and (epM x s) (govM x s)) (actM x s)))
def eventM (x s : String) : Formula := .and (past x s) (fell (.and (.not (past x s)) (prevM x s)))

def approachPass : Rule :=
  { id := "t/approach_pass", laws := []
    binders := [{ name := "v", cls := subjectCls }]
    applicability := exK "stop_line" "s" (.and (past "v" "s") (.or (fell (.and (.not (past "v" "s")) (prevM "v" "s"))) (foundGovM "v" "s")))
    obligation := allK "stop_line" "s" (.implies (eventM "v" "s") (foundM "v" "s")) }

def rules : List Rule := [approachEntry, approachPass]

def ρ : Reading :=
  { params := [⟨"p.stop_point_tolerance", metres 2, .metre⟩, ⟨"p.standstill_speed_tolerance", centimetres 10, .metrePerSecond⟩] }

-- both rules pass the static check (the path-length check included) and the dimension check
#guard rules.all fun r => Rule.check rules r == []
#guard rules.all fun r => Rule.checkReading rules r ρ == []
#guard rules.all fun r => (DimCheck.rule (DimCheck.envOf ρ []) r).isEmpty
-- neither reads a path length, nor any parameter but the two
#guard rules.all fun r => !Rule.readsPath rules r
#guard rules.all fun r => r.params == ["p.stop_point_tolerance", "p.standstill_speed_tolerance"]
-- a carrier is reached through `travel_region`: no lane quantifier is written
#guard rules.all fun r => ((Rule.toJson r).compress.splitOn "\"lane\"").length == 1

-- ---------------------------------------------------------------------------------------------
-- Maps (metres). Highway 10 spans y -15..15; junction 30 spans x 100..112, junction 20 x -12..0.
-- ---------------------------------------------------------------------------------------------
def cm (n : Int) : Q := centimetres n
def m (n : Int) : Q := metres n
def way : Structure := Build.rect 10 .highway (m (-200)) (m (-15)) (m 400) (m 15)
def jn (id : RegionId) (x0 x1 : Q) : Structure := { Build.rect id .intersection x0 (m (-15)) x1 (m 15) with ways := some [10] }
def j30 : Structure := jn 30 (m 100) (m 112)
def j20 : Structure := jn 20 (m (-12)) (m 0)
/-- A carrier of kind k (x0..x1, y0..y1) with a direction and the intersection it enters. -/
def carrier (id : RegionId) (k : StructureKind) (x0 y0 x1 y1 : Q) (dir : Option Vec) (enters : Option RegionId) : Structure :=
  { Build.rect id k x0 y0 x1 y1 with ways := some [10], lane := some { direction := dir, entersIntersection := enters } }
def east : Vec := Build.east
def west : Vec := Build.west
/-- A stop line 0.2 m wide centred at xc cm across y0..y1, marking `ms` (unobserved when none). -/
def line (id : RegionId) (xc : Int) (y0 y1 : Q) (ms : Option (List RegionId)) : Structure :=
  match ms with
  | some cs => { Build.rect id .stopLine (cm (xc - 10)) y0 (cm (xc + 10)) y1 with entranceOf := cs, entranceObserved := true }
  | none => Build.rect id .stopLine (cm (xc - 10)) y0 (cm (xc + 10)) y1

/-- Carriers 11 (y -3..0) and 12 (y -6..-3) of kind k east into 30, line 40 at x = 90 marking both. -/
def twoMap (k : StructureKind) (ms : Option (List RegionId) := some [11, 12]) (dir : Option Vec := some east) : List Structure :=
  [way, j30, carrier 11 k (m (-200)) (m (-3)) (m 100) (m 0) dir (some 30),
   carrier 12 k (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30), line 40 9000 (m (-6)) (m 0) ms]
/-- One roadway segment 21 (y -6..0) east into 30, line 40 marking it. -/
def roadMap (ms : Option (List RegionId) := some [21]) (dir : Option Vec := some east) : List Structure :=
  [way, j30, carrier 21 .roadway (m (-200)) (m (-6)) (m 100) (m 0) dir (some 30), line 40 9000 (m (-6)) (m 0) ms]
/-- Lanes 11, 12 and shoulder segment 13 (y -9..-6) east into 30; line 40 across y -9..0 marking `ms`. -/
def shoulderMap (ms : List RegionId) : List Structure :=
  [way, j30, carrier 11 .lane (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
   carrier 12 .lane (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30),
   carrier 13 .shoulder (m (-200)) (m (-9)) (m 100) (m (-6)) (some east) (some 30), line 40 9000 (m (-9)) (m 0) (some ms)]
/-- Lanes 11, 12 and bicycle lane segment 14 (y -8..-6) east into 30; line 40 across y -8..0 marking `ms`. -/
def bikeMap (ms : Option (List RegionId)) : List Structure :=
  [way, j30, carrier 11 .lane (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
   carrier 12 .lane (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30),
   carrier 14 .bicycleLaneOrPath (m (-200)) (m (-8)) (m 100) (m (-6)) (some east) (some 30), line 40 9000 (m (-8)) (m 0) ms]
/-- A two-way road with no lanes between junctions 20 and 30 (x 0..100, y -6..6), written as two
    directed roadway segments over the same pavement: 21 east into 30, 22 west into 20. Line 41 at
    x = 90 (y -6..0) marks 21; line 42 at x = 10 (y 0..6) marks 22. -/
def pairMap : List Structure :=
  [way, j20, j30, carrier 21 .roadway (m 0) (m (-6)) (m 100) (m 6) (some east) (some 30),
   carrier 22 .roadway (m 0) (m (-6)) (m 100) (m 6) (some west) (some 20),
   line 41 9000 (m (-6)) (m 0) (some [21]), line 42 1000 (m 0) (m 6) (some [22])]
/-- Lane 12 and shoulder segment 13 both east into 30, each with its own line: 40 at x = 90 marks
    12, 44 at x = 85 marks 13. -/
def straddleMap : List Structure :=
  [way, j30, carrier 12 .lane (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30),
   carrier 13 .shoulder (m (-200)) (m (-9)) (m 100) (m (-6)) (some east) (some 30),
   line 40 9000 (m (-6)) (m (-3)) (some [12]), line 44 8500 (m (-9)) (m (-6)) (some [13])]
/-- A one-way roadway 25 (x 0..100, y -6..0) east into 30, its exit end at junction 20; line 47 at x = 90. -/
def oneWayMap : List Structure :=
  [way, j20, j30, carrier 25 .oneWayRoadway (m 0) (m (-6)) (m 100) (m 0) (some east) (some 30), line 47 9000 (m (-6)) (m 0) (some [25])]

-- ---------------------------------------------------------------------------------------------
-- Traces: a road user per track, observed at whole seconds, occupancy derived from the footprint
-- ---------------------------------------------------------------------------------------------
/-- One observation: seconds, centre x and y (cm), speed (cm/s), heading, and whether the body
    moves against its heading. -/
structure P where
  t : Int
  x : Int
  y : Int
  v : Int
  h : Int × Int := (1000, 0)
  rev : Bool := false
def pe (t x y v : Int) : P := { t := t, x := x, y := y, v := v }

/-- A road user: its classes and half-extent (cm). -/
structure Body where
  cls : List RoadUserClass := [.motorVehicle]
  hl : Int := 200
  hw : Int := 100
def car : Body := {}
def bike : Body := { cls := [.bicycle], hl := 90, hw := 30 }

def iabs (z : Int) : Int := if z < 0 then -z else z
def pathsOf (obs : List P) : List Int :=
  (obs.foldl (fun (acc : List Int × Option (Int × Int)) o =>
    let p := match acc.2 with
      | none => 0
      | some (px, py) => (acc.1.getLast?.getD 0) + iabs (o.x - px) + iabs (o.y - py)
    (acc.1 ++ [p], some (o.x, o.y))) ([], none)).1

def mkUser (k : TrackId) (b : Body) (o : P) (path : Int) : RoadUser :=
  let hv : Vec := (Q.ofInt o.h.1, Q.ofInt o.h.2)
  let u0 := Build.user k b.cls (cm o.x, cm o.y) hv (cm o.v) (cm b.hl, cm b.hw, cm 75) (pathLength := some (cm path))
  let vel := (Geom.unit hv).map (Build.scale · (if o.rev then Q.neg (cm o.v) else cm o.v))
  { u0 with kin := { u0.kin with velocity := vel } }

/-- Every track observed at its own instants; a scene at each instant some track is observed; the
    subject is track 1. -/
def mkTrace (ss : List Structure) (tracks : List (TrackId × Body × List P)) : Trace :=
  let times := ((tracks.flatMap fun (_, _, ps) => ps.map (·.t)).eraseDups).mergeSort (· ≤ ·)
  let paths := tracks.map fun (k, b, ps) => (k, b, ps.zip (pathsOf ps))
  TraceLint.completeOccupancy <| times.map fun t =>
    let us := paths.filterMap fun (k, b, pps) => (pps.find? (·.1.t == t)).map fun (o, p) => mkUser k b o p
    Build.scene (t * 1000) (if us.any (·.track == 1) then some 1 else none) us ss []
def drive (ss : List Structure) (b : Body) (obs : List P) : Trace := mkTrace ss [(1, b, obs)]

-- the prototype's motions along one centre line y (cm), for a car (the front 2 m ahead of the centre)
def rng (n : Nat) : List Int := (List.range n).map Int.ofNat
def far8 (y : Int) : List P := (rng 8).map fun k => pe k (2000 + 800 * k) y 800
def goThrough (t0 y : Int) : List P :=
  [pe t0 8950 y 200, pe (t0 + 1) 9400 y 400, pe (t0 + 2) 9800 y 500, pe (t0 + 3) 10400 y 600, pe (t0 + 4) 11100 y 700]
/-- Halts 0.5 m short of the line (front at 89.4), waits, then drives through. -/
def properHalt (y : Int) : List P := far8 y ++ [pe 8 8400 y 300, pe 9 8740 y 0, pe 10 8740 y 0] ++ goThrough 11 y
def noHalt (y : Int) : List P := far8 y ++ [pe 8 8400 y 800, pe 9 9200 y 800, pe 10 10000 y 800, pe 11 10800 y 800]
/-- The same motion for a body of half-length hl: every centre moved so the front is where the car's is. -/
def forBody (b : Body) (ps : List P) : List P := ps.map fun p => { p with x := p.x + 200 - b.hl }

-- ---------------------------------------------------------------------------------------------
-- The witness path
-- ---------------------------------------------------------------------------------------------
def scen (rule : String) (τ : Trace) (expected : Verdict) (boundary : String := "") (absent : List String := []) : Scenario :=
  { name := "w", rule := rule, trace := τ, reading := ρ, manifest := Build.manifest absent,
    grounding := [("v", 1)], expected := expected, boundary := boundary }
/-- `Scenario.run`'s answer: the tag and reasons it returns, or its error. -/
def render (r : Except String Verdict) : String :=
  match r with
  | .ok v => v.tag ++ (if v.reasons.isEmpty then "" else s!" {(v.reasons.map UnknownReason.tag)}")
  | .error e => "error: " ++ e
def E (τ : Trace) (exp : Verdict) (boundary : String := "") (absent : List String := []) : String :=
  render ((scen approachEntry.id τ exp boundary absent).run rules)
def M (τ : Trace) (exp : Verdict) (boundary : String := "") (absent : List String := []) : String :=
  render ((scen approachPass.id τ exp boundary absent).run rules)
def U : Verdict := .unknown []
/-- What `Scenario.run` reports for an unknown whose reasons are no masked atom and no truncation. -/
def stray (rs : String) : String := s!"error: w: unknown for {rs}, not for an atom the manifest masks"
def lint (τ : Trace) : Bool := TraceLint.checkTrace τ == []

-- ---------------------------------------------------------------------------------------------
-- 1. Halt or no halt on each carrier kind: lane, roadway segment, shoulder segment, bicycle lane
--    segment (a bicycle: the act is its own halt)
-- ---------------------------------------------------------------------------------------------
def laneHalt := drive (twoMap .lane) car (properHalt (-150))
def laneNo := drive (twoMap .lane) car (noHalt (-150))
def roadHalt := drive (roadMap) car (properHalt (-300))
def roadNo := drive (roadMap) car (noHalt (-300))
def shHalt := drive (shoulderMap [11, 12, 13]) car (properHalt (-750))
def shNo := drive (shoulderMap [11, 12, 13]) car (noHalt (-750))
def bkHalt := drive (bikeMap (some [11, 12, 14])) bike (forBody bike (properHalt (-700)))
def bkNo := drive (bikeMap (some [11, 12, 14])) bike (forBody bike (noHalt (-700)))
#guard [laneHalt, laneNo, roadHalt, roadNo, shHalt, shNo, bkHalt, bkNo].all lint
#guard [laneHalt, roadHalt, shHalt, bkHalt].all fun τ => E τ .compliant = "compliant" && M τ .compliant = "compliant"
#guard [laneNo, roadNo, shNo, bkNo].all fun τ => E τ .violated = "violated" && M τ .violated = "violated"
-- the body occupies its carrier only, the bicycle the bicycle lane only
#guard (shHalt[9]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 13]
#guard (bkHalt[9]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 14]

-- ---------------------------------------------------------------------------------------------
-- 2. A line that does not list the carrier does not govern it; the opposite direction's line
--    never governs
-- ---------------------------------------------------------------------------------------------
-- line 40 lies across the shoulder (bicycle lane) but lists the lanes only: no duty on that carrier
def shAdjNo := drive (shoulderMap [11, 12]) car (noHalt (-750))
def shAdjHalt := drive (shoulderMap [11, 12]) car (properHalt (-750))
def bkAdjNo := drive (bikeMap (some [11, 12])) bike (forBody bike (noHalt (-700)))
#guard [shAdjNo, shAdjHalt, bkAdjNo].all lint
#guard [shAdjNo, shAdjHalt, bkAdjNo].all fun τ => E τ .notApplicable = "not_applicable" && M τ .notApplicable = "not_applicable"
-- the two-way road: eastbound on both segments; line 42 (westbound, x = 10) is passed over at the start
def pairObs (halt : Bool) : List P :=
  [pe 0 1500 (-300) 800, pe 1 1700 (-300) 800, pe 2 2100 (-300) 800] ++
  ((rng 7).map fun k => pe (3 + k) (2900 + 800 * k) (-300) 800) ++
  (if halt then [pe 10 8400 (-300) 300, pe 11 8740 (-300) 0, pe 12 8740 (-300) 0] ++ goThrough 13 (-300)
   else [pe 10 8400 (-300) 800, pe 11 9200 (-300) 800, pe 12 10000 (-300) 800, pe 13 10800 (-300) 800])
def pairHalt := drive pairMap car (pairObs true)
def pairNo := drive pairMap car (pairObs false)
/-- Halted 0.5 m east of the westbound line 42 (short of it along 22), then on without a halt at 41. -/
def pairHalt42 := drive pairMap car ([pe 0 1260 (-300) 0, pe 1 1260 (-300) 0] ++
  ((rng 9).map fun k => pe (2 + k) (1500 + 800 * k) (-300) 800) ++ [pe 11 9200 (-300) 800, pe 12 10000 (-300) 800])
/-- Starting 5 m into the road, between junction 20 and line 42: through segment 22 the road user is
    already past 42 at its first observation, so whether it passed 42 there is unknown. -/
def pairStartPast42 := drive pairMap car ([pe 0 500 (-300) 800, pe 1 1300 (-300) 800] ++ (pairObs true).drop 2)
#guard [pairHalt, pairNo, pairHalt42, pairStartPast42].all lint
#guard E pairStartPast42 .compliant = "compliant"
#guard M pairStartPast42 U "the passing of line 42 before the recording" = "unknown [window_truncated:rises]"
#guard (pairHalt[5]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 21, 22]
#guard E pairHalt .compliant = "compliant" && M pairHalt .compliant = "compliant"
#guard E pairNo .violated = "violated" && M pairNo .violated = "violated"
#guard E pairHalt42 .violated = "violated" && M pairHalt42 .violated = "violated"

-- ---------------------------------------------------------------------------------------------
-- 3. Missing association, missing direction
-- ---------------------------------------------------------------------------------------------
-- the only line's entrances unobserved: whether it governs is unknown
def noEntNo := drive (roadMap none) car (noHalt (-300))
def noEntHalt := drive (roadMap none) car (properHalt (-300))
#guard [noEntNo, noEntHalt].all lint
#guard E noEntNo U = stray "[absent_atom:st_entrance_of, window_truncated:since]"
#guard M noEntNo U = stray "[absent_atom:st_entrance_of, window_truncated:since, undefined:defined_when]"
-- a halt at the unobserved line: compliant if it governs, no duty if not; the rule cannot tell them apart
#guard E noEntHalt U = stray "[absent_atom:st_entrance_of, window_truncated:since]"
#guard M noEntHalt U = stray "[absent_atom:st_entrance_of, window_truncated:since, undefined:defined_when]"
-- an observed line 40 governs the carrier and an unobserved line 41 lies upstream: the recorded halt
-- at 40 decides the entry; the passing of 41 stays unknown
def noEnt2Map : List Structure := roadMap ++ [line 41 8000 (m (-6)) (m 0) none]
def noEnt2Halt := drive noEnt2Map car (properHalt (-300))
def noEnt2No := drive noEnt2Map car (noHalt (-300))
#guard [noEnt2Halt, noEnt2No].all lint
#guard E noEnt2Halt .compliant = "compliant"
#guard E noEnt2No .violated = "violated"
#guard M noEnt2Halt U = stray "[absent_atom:st_entrance_of, window_truncated:since, undefined:defined_when]"
#guard M noEnt2No .violated = "violated"
-- the direction missing, the entrance known: a halt with the body on the line is the act at the place;
-- a halt short of it has no side
def onLine : List P := far8 (-300) ++ [pe 8 8400 (-300) 300, pe 9 8850 (-300) 0, pe 10 8850 (-300) 0] ++ goThrough 11 (-300)
def noDirOn := drive (roadMap (dir := none)) car onLine
def noDirShort := drive (roadMap (dir := none)) car (properHalt (-300))
#guard [noDirOn, noDirShort].all lint
#guard (noDirOn[9]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 21, 40]
#guard E noDirOn .compliant = "compliant"
#guard E noDirShort U = stray "[absent_atom:st_lane_direction, window_truncated:since]"
-- the passing itself has no side without the direction
#guard M noDirOn U = stray "[absent_atom:st_lane_direction, window_truncated:rises, window_truncated:since, undefined:defined_when]"
-- speed masked by the manifest (a blind witness): unknown for the masked atom only
#guard E roadHalt U (absent := ["kin.speed"]) = "unknown [absent_atom:kin_speed]"
#guard M roadHalt U (absent := ["kin.speed"]) = "unknown [absent_atom:kin_speed]"

-- a whole two-way roadway 15 (no entrance recorded) under lanes 11 and 12: which junction it is an
-- approach to is unknown, so the governance at the entry is unknown; a recorded halt is still the act
def wholeMap : List Structure := twoMap .lane ++ [Build.rect 15 .roadway (m (-200)) (m (-6)) (m 100) (m 0)]
def wholeHalt := drive wholeMap car (properHalt (-150))
def wholeNo := drive wholeMap car (noHalt (-150))
#guard [wholeHalt, wholeNo].all lint
#guard [wholeHalt, wholeNo].all fun τ =>
  E τ U = stray "[absent_atom:st_lane_enters, window_truncated:since]" && M τ U = stray "[absent_atom:st_lane_enters, window_truncated:since]"

-- ---------------------------------------------------------------------------------------------
-- 4. The approach start: only an observed upstream exit from the zone begins a new approach
-- ---------------------------------------------------------------------------------------------
def haltAt (y : Int) : List P := far8 y ++ [pe 8 8400 y 300, pe 9 8740 y 0, pe 10 8740 y 0]
/-- Halt; reverse to 3.9 m short (outside the zone); drive on without another halt. -/
def revOut := drive (shoulderMap [11, 12, 13]) car (haltAt (-750) ++
  [{ pe 11 8600 (-750) 140 with rev := true }, { pe 12 8400 (-750) 200 with rev := true }, pe 13 8400 (-750) 0, pe 14 8700 (-750) 300,
   pe 15 9050 (-750) 350, pe 16 9500 (-750) 450, pe 17 10000 (-750) 500, pe 18 10500 (-750) 500])
/-- Halt; reverse 0.6 m inside the zone; on without another halt. -/
def revIn := drive (shoulderMap [11, 12, 13]) car (haltAt (-750) ++ [{ pe 11 8680 (-750) 60 with rev := true }, pe 12 8680 (-750) 0] ++ goThrough 13 (-750))
/-- Halt; cross the line and roll the 10 m to the junction over five observations. -/
def cross := drive (roadMap) car (haltAt (-300) ++
  [pe 11 8950 (-300) 200, pe 12 9200 (-300) 250, pe 13 9450 (-300) 250, pe 14 9700 (-300) 250, pe 15 9900 (-300) 200, pe 16 10400 (-300) 500])
/-- Halt in lane 11; move into lane 12 inside the zone (straddling both at t = 11); enter from lane 12.
    One line marks both lanes; no second halt. -/
def changeObs : List P := haltAt (-150) ++ [pe 11 8760 (-300) 40, pe 12 8780 (-450) 40] ++ goThrough 13 (-450)
def change := drive (twoMap .lane) car changeObs
/-- Halt; enter the junction; back out of it (staying past the line); enter again without a halt: the
    search for the second entry ends at the previous entry. One passing of the line, after the halt. -/
def reenter := drive (roadMap) car (haltAt (-300) ++
  [pe 11 8950 (-300) 200, pe 12 9800 (-300) 500, pe 13 10200 (-300) 400, { pe 14 9500 (-300) 700 with rev := true }, pe 15 9500 (-300) 0,
   pe 16 10000 (-300) 300, pe 17 10600 (-300) 600])
#guard [revOut, revIn, cross, change, reenter].all lint
#guard E reenter .violated = "violated" && M reenter .compliant = "compliant"
#guard (change[11]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 11, 12]
#guard E revOut .violated = "violated" && M revOut .violated = "violated"
#guard E revIn .compliant = "compliant" && M revIn .compliant = "compliant"
#guard E cross .compliant = "compliant" && M cross .compliant = "compliant"
#guard E change .compliant = "compliant" && M change .compliant = "compliant"
-- the same lane change where each lane has its own line at x = 90: the entry is decided; the passing
-- of lane 12's line has no approach start on lane 12 in the trace
def change2Map : List Structure :=
  [way, j30, carrier 11 .lane (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
   carrier 12 .lane (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30),
   line 40 9000 (m (-3)) (m 0) (some [11]), line 46 9000 (m (-6)) (m (-3)) (some [12])]
def change2 := drive change2Map car changeObs
#guard lint change2
#guard E change2 .compliant = "compliant"
#guard M change2 U "the approach on lane 12 before the recording" = "unknown [window_truncated:since]"

-- ---------------------------------------------------------------------------------------------
-- 5. The side of the mark: oblique, U-shaped, a travel line that misses the mark
-- ---------------------------------------------------------------------------------------------
/-- Four carriers into junction 30 at x 104..116 (roadway segment 11, lanes 12 and 14, shoulder
    segment 15, from y 0 down to -12); a 45-degree line, centre x = 90 + (y + 6). -/
def obliqueMap : List Structure :=
  [way, { Build.rect 30 .intersection (m 104) (m (-15)) (m 116) (m 15) with ways := some [10] },
   carrier 11 .roadway (m (-200)) (m (-3)) (m 104) (m 0) (some east) (some 30),
   carrier 12 .lane (m (-200)) (m (-6)) (m 104) (m (-3)) (some east) (some 30),
   carrier 14 .lane (m (-200)) (m (-9)) (m 104) (m (-6)) (some east) (some 30),
   carrier 15 .shoulder (m (-200)) (m (-12)) (m 104) (m (-9)) (some east) (some 30),
   { Build.region 40 .stopLine [(cm 8390, m (-12)), (cm 8410, m (-12)), (cm 9610, m 0), (cm 9590, m 0)] with
       entranceOf := [11, 12, 14, 15], entranceObserved := true }]
def ob1 := drive obliqueMap car (far8 (-150) ++ [pe 8 8400 (-150) 600, pe 9 8860 (-150) 300, pe 10 9060 (-150) 0, pe 11 9060 (-150) 0,
  pe 12 9300 (-150) 200, pe 13 9700 (-150) 400, pe 14 10200 (-150) 500, pe 15 10800 (-150) 600])
def ob2 := drive obliqueMap car (far8 (-1050) ++ [pe 8 8160 (-1050) 600, pe 9 8910 (-1050) 0, pe 10 8910 (-1050) 0,
  pe 11 9300 (-1050) 300, pe 12 9800 (-1050) 500, pe 13 10300 (-1050) 500, pe 14 10900 (-1050) 600])
/-- A U-shaped line round x = 88 (bars at 85.0..85.2 and 90.8..91.0 over y -6..0, joined below) on
    roadway segment 21; the halt's reference point lies in its opening. -/
def uLine : List Vec := [(cm 8500, cm (-620)), (cm 9100, cm (-620)), (cm 9100, m 0), (cm 9080, m 0), (cm 9080, cm (-600)),
                         (cm 8520, cm (-600)), (cm 8520, m 0), (cm 8500, m 0)]
def uMap : List Structure :=
  [way, j30, carrier 21 .roadway (m (-200)) (m (-7)) (m 100) (m 0) (some east) (some 30),
   { Build.region 40 .stopLine uLine with entranceOf := [21], entranceObserved := true }]
def uHalt := drive uMap car (far8 (-300) ++ [pe 8 8400 (-300) 300, pe 9 8800 (-300) 0, pe 10 8800 (-300) 0,
  pe 11 9300 (-300) 300, pe 12 9800 (-300) 500, pe 13 10400 (-300) 600])
#guard [ob1, ob2, uHalt].all lint
#guard E ob1 .compliant = "compliant" && M ob1 .compliant = "compliant"
#guard E ob2 .violated = "violated" && M ob2 .violated = "violated"
#guard E uHalt U = stray "[undefined:prim_region_offset_along]"
#guard M uHalt U = stray "[undefined:prim_region_offset_along]"
/-- Five carriers into junction 30 (roadway segments 16, 17, 11; shoulder segment 12; bicycle lane
    segment 14; y 6 down to -9); a perpendicular line at x = 90 across all of them. -/
def wideMap : List Structure :=
  [way, j30, carrier 16 .roadway (m (-200)) (m 3) (m 100) (m 6) (some east) (some 30),
   carrier 17 .roadway (m (-200)) (m 0) (m 100) (m 3) (some east) (some 30),
   carrier 11 .roadway (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
   carrier 12 .shoulder (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30),
   carrier 14 .bicycleLaneOrPath (m (-200)) (m (-9)) (m 100) (m (-6)) (some east) (some 30),
   line 40 9000 (m (-9)) (m 6) (some [16, 17, 11, 12, 14])]
def hp (t x y v hx hy : Int) : P := { t := t, x := x, y := y, v := v, h := (hx, hy) }
def hcObs (pts : List (Int × Int × Int)) (hx hy : Int) : List P :=
  (pts.zipIdx.map fun ((x, y, v), k) => hp k x y v hx hy) ++
  [pe 5 9000 150 300, pe 6 9400 150 400, pe 7 9800 150 500, pe 8 10400 150 600]
def hlObs (pts : List (Int × Int × Int)) (hx hy : Int) : List P :=
  (pts.zipIdx.map fun ((x, y, v), k) => hp k x y v hx hy) ++
  [pe 5 9500 150 300, pe 6 9800 150 400, pe 7 10400 150 600]
/-- Heading 50 degrees left, halt 0.5 m short: the early travel lines miss the line, all of it ahead. -/
def hc50 := drive wideMap car (hcObs [(7706, -1075, 800), (8220, -463, 800), (8542, -80, 500), (8735, 150, 0), (8735, 150, 0)] 643 766)
/-- Heading 35 degrees right, the line crossed between observations, halt with the rear past it. -/
def hl35 := drive wideMap car (hlObs [(7070, 1700, 900), (7807, 1183, 900), (8544, 667, 900), (9281, 150, 0), (9281, 150, 0)] 819 (-574))
#guard [hc50, hl35].all lint
#guard E hc50 .compliant = "compliant" && M hc50 .compliant = "compliant"
#guard E hl35 .violated = "violated" && M hl35 .violated = "violated"
/-- Line 40 spans y -6..-0.5 only; carriers 11 (roadway segment) and 12 (lane). A diagonal approach
    (heading 35 degrees right) whose reference point stays at y > -0.5, so the travel line along the
    carrier misses the line's end while all of the line lies ahead. -/
def missMap : List Structure :=
  [way, j30, carrier 11 .roadway (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
   carrier 12 .lane (m (-200)) (m (-6)) (m 100) (m (-3)) (some east) (some 30), line 40 9000 (m (-6)) (cm (-50)) (some [11, 12])]
/-- Halts at centre x (cm), y = -0.2 m, heading 35 degrees right; then east into the junction. -/
def missObs (x : Int) : List P :=
  [hp 0 6400 1500 800 819 (-574), hp 1 7000 1080 600 819 (-574), hp 2 7600 650 600 819 (-574), hp 3 8200 170 600 819 (-574),
   hp 4 x (-20) 300 819 (-574), hp 5 x (-20) 0 819 (-574), hp 6 x (-20) 0 819 (-574),
   pe 7 9200 (-150) 300, pe 8 9800 (-150) 500, pe 9 10400 (-150) 600]
def miss0 := drive missMap car (missObs 8740)
def miss1 := drive missMap car (missObs 8620)
def miss2 := drive missMap car (missObs 8540)
#guard [miss0, miss1, miss2].all lint
-- at the halt the reference point's travel line misses the line: the offset is decided and positive
def offAt (τ : Trace) (k : Nat) : Option Q :=
  match (Primitives.prim_region_offset_along (Primitives.Ctx.mk' τ ρ) 1 40 11)[k]? with
  | some (.ok q) => some q
  | _ => none
def distAt (τ : Trace) (k : Nat) : Option Q := st_region_geometry_distance τ[k]! 1 40
#guard offAt miss0 5 = some (cm 250) && (distAt miss0 5).any (fun d => Q.lt Q.zero d && Q.le d (metres 2))
-- the variant: the offset's magnitude (3.7 m) is beyond the tolerance, the region distance (1.5 m) within it
#guard offAt miss1 5 = some (cm 370) && (distAt miss1 5).any (fun d => Q.le (metres 1) d && Q.le d (metres 2))
-- the control: the region distance beyond the tolerance
#guard (distAt miss2 5).any (fun d => Q.lt (metres 2) d)
#guard E miss0 .compliant = "compliant" && M miss0 .compliant = "compliant"
#guard E miss1 .compliant = "compliant" && M miss1 .compliant = "compliant"
#guard E miss2 .violated = "violated" && M miss2 .violated = "violated"

-- ---------------------------------------------------------------------------------------------
-- 6. The history boundary
-- ---------------------------------------------------------------------------------------------
/-- First observed 1 m short of the line moving, no halt, then through. -/
def startInZone := drive roadMap car ([pe 0 8600 (-300) 300, pe 1 8800 (-300) 300] ++ goThrough 2 (-300))
/-- First observed halted 0.5 m short of the line. -/
def startHalted := drive roadMap car ([pe 0 8740 (-300) 0, pe 1 8740 (-300) 0] ++ goThrough 2 (-300))
/-- First observed inside the junction. -/
def startAfter := drive roadMap car [pe 0 10400 (-300) 600, pe 1 11000 (-300) 600, pe 2 11600 (-300) 600]
#guard [startInZone, startHalted, startAfter].all lint
#guard E startInZone U "the approach before the recording" = "unknown [window_truncated:since]"
#guard M startInZone U "the approach before the recording" = "unknown [window_truncated:since]"
-- without the boundary the same trace is no witness
#guard E startInZone U = stray "[window_truncated:since]"
#guard E startHalted .compliant = "compliant" && M startHalted .compliant = "compliant"
#guard E startAfter U "the entry before the recording" = "unknown [window_truncated:rises]"
#guard M startAfter U "the passing before the recording" = "unknown [window_truncated:rises]"
-- unknown, never absent
#guard E startAfter .notApplicable = "error: w: expected not_applicable, got unknown [window_truncated:rises]"

-- ---------------------------------------------------------------------------------------------
-- 7. Identity from the target, not from motion; no favourable choice
-- ---------------------------------------------------------------------------------------------
/-- Facing west and backing east on both segments, into junction 30, with no halt. -/
def backing := drive pairMap car (((rng 9).map fun k => { hp k (2000 + 800 * k) (-300) 800 (-1000) 0 with rev := true }) ++
  [{ hp 9 9200 (-300) 800 (-1000) 0 with rev := true }, { hp 10 10000 (-300) 800 (-1000) 0 with rev := true }])
#guard lint backing
#guard E backing .violated = "violated" && M backing .violated = "violated"
/-- Straddling lane 12 and shoulder 13 (y = -6), halted with the front 0.5 m short of 40 and the
    rear 0.3 m past 44. -/
def straddle := drive straddleMap car (haltAt (-600) ++ goThrough 11 (-600))
#guard lint straddle
#guard (straddle[9]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 12, 13]
#guard E straddle U = stray "[undefined:defined_when]"
#guard M straddle U = stray "[undefined:defined_when, window_truncated:since]"
/-- Westbound on the one-way roadway 25 (it enters 30), arriving at its exit end into junction 20. -/
def wrongWay := drive oneWayMap car ((rng 10).map fun k => hp k (8500 - 1000 * k) (-300) 1000 (-1000) 0)
#guard lint wrongWay
#guard E wrongWay .notApplicable = "not_applicable" && M wrongWay .notApplicable = "not_applicable"

-- ---------------------------------------------------------------------------------------------
-- 8. The event: read from its observation and the one before
-- ---------------------------------------------------------------------------------------------
/-- On shoulder segment 13 (line 40 lists the lanes only) straight into the junction: the line is
    past at the entry, but the observation before shows a carrier it is observed not to mark. -/
def evNotMarked := drive (shoulderMap [11, 12]) car (far8 (-750) ++ [pe 8 9400 (-750) 800, pe 9 10200 (-750) 800])
/-- The same with line 40's entrances unobserved. -/
def evUnobserved := drive ([way, j30, carrier 11 .lane (m (-200)) (m (-3)) (m 100) (m 0) (some east) (some 30),
  carrier 13 .shoulder (m (-200)) (m (-9)) (m 100) (m (-6)) (some east) (some 30), line 40 9000 (m (-9)) (m 0) none]) car
  (far8 (-750) ++ [pe 8 9400 (-750) 800, pe 9 10200 (-750) 800])
/-- On carrier 11 short of the line, then on no carrier (beyond y = 9... north of every carrier),
    then in the junction past the line. -/
def evOff := drive (twoMap .lane) car (far8 (-150) ++ [pe 8 9300 400 800, pe 9 10200 400 800])
/-- First observed in the junction past the line, at t = 3, while another road user is recorded from t = 0. -/
def evFirst := mkTrace (roadMap) [(2, car, (rng 6).map fun k => pe k (-15000) (-300) 0),
  (1, car, [pe 3 10200 (-300) 600, pe 4 10800 (-300) 600, pe 5 11400 (-300) 600])]
#guard [evNotMarked, evUnobserved, evOff, evFirst].all lint
#guard (evOff[8]!.occupies.filter (·.1 == 1)).map (·.2) = [10]
#guard E evNotMarked .notApplicable = "not_applicable" && M evNotMarked .notApplicable = "not_applicable"
#guard E evUnobserved U = stray "[absent_atom:st_entrance_of, window_truncated:since]"
#guard M evUnobserved U = stray "[absent_atom:st_entrance_of, window_truncated:since]"
#guard E evOff U = stray "[undefined:defined_when]"
#guard M evOff U = stray "[undefined:defined_when]"
#guard E evFirst U = stray "[absent_atom:rel_occupies, absent_atom:kin_speed, absent_atom:st_region_geometry_distance, absent_atom:kin_position, window_truncated:since]"
#guard M evFirst U = stray "[absent_atom:rel_occupies, absent_atom:kin_position, absent_atom:kin_speed, absent_atom:st_region_geometry_distance, window_truncated:since]"

-- ---------------------------------------------------------------------------------------------
-- Decoded from JSON: a roadway, a shoulder and a bicycle case, written as a source writes them and
-- run with the occupancy derived from the footprints, as a reviewer's trace is
-- ---------------------------------------------------------------------------------------------
/-- cm as a decimal number of metres. -/
def dec (n : Int) : String :=
  let s := if n < 0 then "-" else ""
  let k := iabs n
  let f := k % 100
  s ++ s!"{k / 100}." ++ (if f < 10 then "0" else "") ++ s!"{f}"
def jRect (x0 y0 x1 y1 : Int) : String := s!"[[{dec x0}, {dec y0}], [{dec x1}, {dec y0}], [{dec x1}, {dec y1}], [{dec x0}, {dec y1}]]"
def jWay : String := s!"\{\"id\": 10, \"kind\": \"highway\", \"boundary\": {jRect (-20000) (-1500) 40000 1500}}"
def jJ30 : String := s!"\{\"id\": 30, \"kind\": \"intersection\", \"ways\": [10], \"boundary\": {jRect 10000 (-1500) 11200 1500}}"
def jCarrier (id : Nat) (k : String) (y0 y1 : Int) : String :=
  s!"\{\"id\": {id}, \"kind\": \"{k}\", \"ways\": [10], \"boundary\": {jRect (-20000) y0 10000 y1}, \"lane\": \{\"direction\": [1, 0], \"enters_intersection\": 30}}"
def jLine (y0 y1 : Int) (ms : String) : String :=
  s!"\{\"id\": 40, \"kind\": \"stop_line\", \"boundary\": {jRect 8990 y0 9010 y1}, \"entrance_of\": {ms}}"
def jScene (structs : String) (cls : String) (hl hw : Int) (o : P) (path : Int) : String :=
  s!"\{\"t\": {o.t * 1000}, \"subject\": 1, \"occupancy_observed\": true, \"structures\": [{structs}], \"users\": [\{\"track\": 1, \"classes\": [\"{cls}\"], " ++
  s!"\"kin\": \{\"position\": [{dec o.x}, {dec o.y}], \"heading\": [1, 0], \"velocity\": [{dec o.v}, 0], \"speed\": {dec o.v}, " ++
  s!"\"extent\": [{dec hl}, {dec hw}, 0.75], \"path_length\": {dec path}}}]}"
def jTrace (structs cls : String) (b : Body) (obs : List P) : String :=
  "{\"scenes\": [" ++ ", ".intercalate ((obs.zip (pathsOf obs)).map fun (o, p) => jScene structs cls b.hl b.hw o p) ++ "]}"
def decoded (s : String) : Trace := TraceLint.completeOccupancy ((Decode.parse Decode.trace s).toOption.getD [])
def jRoad (obs : List P) : String := jTrace (", ".intercalate [jWay, jJ30, jCarrier 21 "roadway" (-600) 0, jLine (-600) 0 "[21]"]) "motor_vehicle" car obs
def jShoulder (obs : List P) : String :=
  jTrace (", ".intercalate [jWay, jJ30, jCarrier 11 "lane" (-300) 0, jCarrier 12 "lane" (-600) (-300), jCarrier 13 "shoulder" (-900) (-600),
    jLine (-900) 0 "[11, 12, 13]"]) "motor_vehicle" car obs
def jBike (ms : String) (obs : List P) : String :=
  jTrace (", ".intercalate [jWay, jJ30, jCarrier 11 "lane" (-300) 0, jCarrier 12 "lane" (-600) (-300), jCarrier 14 "bicycle_lane_or_path" (-800) (-600),
    jLine (-800) 0 ms]) "bicycle" bike obs
def dRoadHalt := decoded (jRoad (properHalt (-300)))
def dRoadNo := decoded (jRoad (noHalt (-300)))
def dShHalt := decoded (jShoulder (properHalt (-750)))
def dShNo := decoded (jShoulder (noHalt (-750)))
def dBkHalt := decoded (jBike "[11, 12, 14]" (forBody bike (properHalt (-700))))
def dBkAdj := decoded (jBike "[11, 12]" (forBody bike (noHalt (-700))))
#guard [dRoadHalt, dRoadNo, dShHalt, dShNo, dBkHalt, dBkAdj].all fun τ => !τ.isEmpty && lint τ
#guard dRoadHalt.length = 16 && st_lane_enters dRoadHalt[0]! 21 = some 30 && st_entrance_of dRoadHalt[0]! 40 21 = some true
#guard st_bicycle_lane_or_path dBkHalt[0]! 14 = some true && st_lane dBkHalt[0]! 14 = some false
#guard st_entrance_of dBkAdj[0]! 40 14 = some false
#guard (dShHalt[9]!.occupies.filter (·.1 == 1)).map (·.2) = [10, 13]
#guard E dRoadHalt .compliant = "compliant" && M dRoadHalt .compliant = "compliant"
#guard E dRoadNo .violated = "violated" && M dRoadNo .violated = "violated"
#guard E dShHalt .compliant = "compliant" && M dShHalt .compliant = "compliant"
#guard E dShNo .violated = "violated" && M dShNo .violated = "violated"
#guard E dBkHalt .compliant = "compliant" && M dBkHalt .compliant = "compliant"
#guard E dBkAdj .notApplicable = "not_applicable" && M dBkAdj .notApplicable = "not_applicable"

end TrafficSpec.Tests.ApproachChain

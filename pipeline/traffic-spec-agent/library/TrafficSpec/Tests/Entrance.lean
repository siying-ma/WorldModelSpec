import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Runtime.Decode
namespace TrafficSpec.Tests.Entrance
open TrafficSpec TrafficSpec.Semantics

-- ---------------------------------------------------------------------------------------------
-- One way (1) with two intersections (50, then 60 further east). Lanes 10 and 12 run east into 50,
-- lane 11 runs west into 50, lane 20 runs east into 60. Every line and crossing lies on way 1.
-- ---------------------------------------------------------------------------------------------
def way1 : Structure := { id := 1, kind := .highway }
def junction (id : Nat) : Structure := { id := id, kind := .intersection, ways := some [1] }
def lane (id j : Nat) : Structure := { id := id, kind := .lane, ways := some [1], lane := some { entersIntersection := some j } }
def mark (id : Nat) (k : StructureKind) (lanes : Option (List RegionId)) : Structure :=
  match lanes with
  | some ls => { id := id, kind := k, ways := some [1], entranceOf := ls, entranceObserved := true }
  | none => { id := id, kind := k, ways := some [1] }
def base : List Structure := [way1, junction 50, junction 60, lane 10 50, lane 12 50, lane 11 50, lane 20 60]
def scene (marks : List Structure) : Scene := { t := 0, structures := base ++ marks }

def at0 (s : Scene) (φ : Formula) : Tri := evalTri (SemCtx.mk' [s] {}) 0 φ
def marksF (l a : Nat) : Formula := .atom "st_entrance_of" [.nat l, .nat a] []
/-- Lane `a` has a stop line marking its entrance into intersection `i`. -/
def stopLineOf (a i : Nat) : Formula :=
  .existsRegion (.lit "stop_line") "sl" (.and (.atom "st_entrance_of" [.var "sl", .nat a] []) (.atom "st_lane_enters" [.nat a, .nat i] []))
/-- No stop line marks lane `a`'s entrance: the condition under which a crossing or the intersection is the halting place. -/
def noStopLine (a : Nat) : Formula :=
  .not (.existsRegion (.lit "stop_line") "sl" (.atom "st_entrance_of" [.var "sl", .nat a] []))

-- two entrances on one way: line 31 marks lane 10 (into 50), line 32 marks lane 20 (into 60)
def twoEntrances : Scene := scene [mark 31 .stopLine (some [10]), mark 32 .stopLine (some [20])]
#guard st_entrance_of twoEntrances 31 10 = some true
#guard st_entrance_of twoEntrances 31 20 = some false
#guard st_entrance_of twoEntrances 32 20 = some true
#guard st_entrance_of twoEntrances 32 10 = some false
#guard st_on_way twoEntrances 32 = some [1]
#guard at0 twoEntrances (.atom "st_on_way" [.nat 32, .nat 1] []) = .t
#guard at0 twoEntrances (marksF 32 10) = .f
#guard at0 twoEntrances (stopLineOf 10 50) = .t
#guard at0 twoEntrances (stopLineOf 20 60) = .t
#guard at0 twoEntrances (stopLineOf 10 60) = .f
#guard at0 twoEntrances (stopLineOf 20 50) = .f

-- an adjacent line not of this approach: line 33 marks the opposing lane 11 at the same intersection
def adjacent : Scene := scene [mark 31 .stopLine (some [10]), mark 33 .stopLine (some [11])]
#guard st_entrance_of adjacent 33 10 = some false
#guard st_entrance_of adjacent 33 11 = some true
#guard at0 adjacent (stopLineOf 11 50) = .t
#guard at0 (scene [mark 33 .stopLine (some [11])]) (stopLineOf 10 50) = .f

-- near and far crossings: crosswalk 41 before the intersection for lanes 10 and 12, crosswalk 42 for lane 11
def crossings : Scene := scene [mark 41 .crosswalk (some [10, 12]), mark 42 .crosswalk (some [11])]
#guard st_entrance_of crossings 41 10 = some true
#guard st_entrance_of crossings 42 10 = some false
#guard st_entrance_of crossings 42 11 = some true
#guard st_entrance_of crossings 41 11 = some false
#guard at0 crossings (marksF 42 10) = .f
#guard at0 crossings (.existsRegion (.lit "crosswalk") "c" (.and (.atom "st_entrance_of" [.var "c", .nat 10] []) (.atom "st_lane_enters" [.nat 10, .nat 50] []))) = .t

-- no stop line at all: the fallback holds, decided
#guard at0 crossings (noStopLine 10) = .t
#guard at0 crossings (stopLineOf 10 50) = .f
-- a stop line whose entrances are not observed: the fallback is unknown, never "no stop line"
def unobservedLine : Scene := scene [mark 31 .stopLine none, mark 41 .crosswalk (some [10, 12])]
#guard at0 unobservedLine (noStopLine 10) = .u
#guard at0 unobservedLine (stopLineOf 10 50) = .u
-- a stop line observed to mark only another lane: the fallback holds for this lane
#guard at0 (scene [mark 32 .stopLine (some [20]), mark 41 .crosswalk (some [10, 12])]) (noStopLine 10) = .t

-- several lanes on one line
def shared : Scene := scene [mark 31 .stopLine (some [10, 12])]
#guard st_entrance_of shared 31 10 = some true
#guard st_entrance_of shared 31 12 = some true
#guard st_entrance_of shared 31 11 = some false
#guard at0 shared (stopLineOf 12 50) = .t
#guard at0 shared (stopLineOf 10 50) = .t

-- observed-false against unobserved: one map, line 31 observed or not
def observed : Scene := scene [mark 31 .stopLine (some [10])]
def unobserved : Scene := scene [mark 31 .stopLine none]
#guard st_entrance_of observed 31 11 = some false
#guard st_entrance_of unobserved 31 11 = none
#guard st_entrance_of observed 31 10 = some true
#guard st_entrance_of unobserved 31 10 = none
#guard st_entrance_of (scene [mark 31 .stopLine (some [])]) 31 10 = some false
-- only a stop line or a crosswalk marks an entrance; a region whose kind is unknown may
#guard st_entrance_of observed 10 10 = some false
#guard st_entrance_of observed 50 10 = some false
#guard st_entrance_of { observed with structures := observed.structures.map fun st =>
          if st.id == 50 then { st with unobservedKinds := [.stopLine] } else st } 50 10 = none
#guard st_entrance_of observed 99 10 = none
-- the mask: a source without the relation leaves every line unknown
#guard st_entrance_of (Mask.scene "st.entrance_of" observed) 31 10 = none
#guard at0 (Mask.scene "st.entrance_of" observed) (stopLineOf 10 50) = .u
#guard at0 (Mask.scene "st.entrance_of" crossings) (noStopLine 10) = .t

-- the formula read and its sorts
#guard knowsAtom "st_entrance_of"
#guard atomArgSorts "st_entrance_of" = some [some .region, some .region]
#guard StructureKind.ofString "entrance_of" = none

-- ---------------------------------------------------------------------------------------------
-- The trace: `entrance_of` on a structure; absent or null is not observed, `[]` marks none.
-- ---------------------------------------------------------------------------------------------
def traceWith (line : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"structures\": [{\"id\": 10, \"kind\": \"lane\", \"lane\": {\"enters_intersection\": 50}}, " ++
  "{\"id\": 11, \"kind\": \"turn_lane\"}, {\"id\": 50, \"kind\": \"intersection\"}, " ++ line ++ "]}]}"
def decoded (line : String) : Except String Trace := Decode.parse Decode.trace (traceWith line)
def marksOf (line : String) : Option (Option Bool) := (decoded line).toOption.map fun τ => st_entrance_of τ[0]! 31 10
#guard marksOf "{\"id\": 31, \"kind\": \"stop_line\"}" = some none
#guard marksOf "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": null}" = some none
#guard marksOf "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": []}" = some (some false)
#guard marksOf "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [10]}" = some (some true)
#guard (decoded "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": \"10\"}").isOk = false

def lint (line : String) : List String := match decoded line with
  | .ok τ => TraceLint.checkTrace τ
  | .error e => [e]
def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1
#guard lint "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [10]}" = []
#guard lint "{\"id\": 31, \"kind\": \"crosswalk\", \"entrance_of\": [10]}" = []
#guard lint "{\"id\": 31, \"kind\": \"stop_line\"}" = []
#guard has (lint "{\"id\": 31, \"kind\": \"median_or_divider\", \"entrance_of\": [10]}") "structure 31 (median_or_divider) carries entrance_of"
#guard has (lint "{\"id\": 31, \"kind\": \"median_or_divider\", \"entrance_of\": []}") "carries entrance_of"
#guard has (lint "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [50]}") "entrance_of names region 50, which is not a lane"
#guard has (lint "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [99]}") "entrance_of names region 99, which is not in this scene"
-- an entry is a lane by refinement: a turn lane is accepted, a region of another kind is not
#guard !(has (lint "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [11]}") "names region 11")


-- joint with refinement: every lane kind may be named, and a one-way roadway as a roadway; the atom reads them alike
def traceKinds (line : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"structures\": [{\"id\": 10, \"kind\": \"lane\"}, {\"id\": 11, \"kind\": \"turn_lane\"}, " ++
  "{\"id\": 12, \"kind\": \"reserved_lane\"}, {\"id\": 13, \"kind\": \"centre_turn_lane\"}, {\"id\": 14, \"kind\": \"sidewalk\"}, " ++
  "{\"id\": 15, \"kind\": \"one_way_roadway\"}, " ++ line ++ "]}]}"
def lintK (line : String) : List String := match Decode.parse Decode.trace (traceKinds line) with
  | .ok τ => TraceLint.checkTrace τ
  | .error e => [e]
#guard lintK "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [10, 11, 12, 13]}" = []
#guard has (lintK "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [14]}") "names region 14, which is not a lane"
#guard !(has (lintK "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [15]}") "names region 15")
def marksK (line : String) (a : RegionId) : Option (Option Bool) :=
  (Decode.parse Decode.trace (traceKinds line)).toOption.map fun τ => st_entrance_of τ[0]! 31 a
#guard [10, 11, 12, 13].all fun a => marksK "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [10, 11, 12, 13]}" a = some (some true)
#guard marksK "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [11]}" 12 = some (some false)
#guard marksK "{\"id\": 31, \"kind\": \"stop_line\"}" 11 = some none
-- under a source that cannot tell the refining lane kinds, a line's entrances read as before
def carlaMask : Manifest :=
  let full := Manifest.full "test"
  { full with entries := full.entries.map fun (id, c) =>
      if ["st.turn_lane", "st.reserved_lane", "st.centre_turn_lane"].contains id then (id, .absent) else (id, c) }
#guard (Decode.parse Decode.trace (traceKinds "{\"id\": 31, \"kind\": \"stop_line\", \"entrance_of\": [11]}")).toOption.map
  (fun τ => st_entrance_of (mask carlaMask τ[0]!) 31 11) = some (some true)

end TrafficSpec.Tests.Entrance

import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.Chains
open TrafficSpec Units Lean

-- ---------------------------------------------------------------------------------------------
-- Each capability through the production chain of a certificate: decode, occupancy completed,
-- admission, the trace check, the case, and the rule's verdict.
-- ---------------------------------------------------------------------------------------------
def mps (n : Int) : Term := .lit (metresPerSecond n) .metrePerSecond
def speedV : Term := .measure "kin_speed" [.var "v"]
def caseAt (t : Int) : String :=
  (Json.mkObj [("case", (Formula.cmp speedV .ge (mps 0)).toJson), ("entities", Json.mkObj []), ("at", toJson t)]).compress
def scene (t : Nat) (structures occupies : String) (speed : String := "5") (velocity : String := "[5, 0]") (observed : Bool := true) : String :=
  "{\"t\": " ++ toString t ++ ", \"subject\": 1, \"users\": [{\"track\": 1, \"classes\": [\"motor_vehicle\"], \"kin\": {\"position\": [0, 0], " ++
  "\"heading\": [1, 0], \"extent\": [2.25, 0.9, 0.75], \"speed\": " ++ speed ++ ", \"velocity\": " ++ velocity ++ "}}], \"structures\": [" ++
  structures ++ "]" ++ (if observed then ", \"occupancy_observed\": true, \"occupies\": [" ++ occupies ++ "]" else "") ++ "}"
-- a strip under the car, one beside it, and a line ahead of it, none of them touching the other two
def under : String := "\"boundary\": [[-50, -2], [50, -2], [50, 2], [-50, 2]]"
def beside : String := "\"boundary\": [[-50, 5], [50, 5], [50, 9], [-50, 9]]"
def ahead : String := "\"boundary\": [[10, -2], [10.3, -2], [10.3, 2], [10, 2]]"
def trace (scenes : List String) : String := "{\"scenes\": [" ++ ", ".intercalate scenes ++ "]}"
def car : Binder := { name := "v", cls := .atom "ru_motor_vehicle" [.var "v"] [] }
def occ (v r : String) : Formula := .atom "rel_occupies" [.var v, .var r] []
def run (r : Rule) (tr : String) (t : Int) : Json := Certificate.record [r] r {} 1 tr (caseAt t) [("v", 1)]
def verdictOf (r : Rule) (tr : String) (t : Int) : Json := ((run r tr t).getObjValD "rule_result").getObjValD "verdict"
def lintOf (r : Rule) (tr : String) (t : Int) : Json := (run r tr t).getObjValD "lint_errors"

-- refinement: a rule reading `lane` meets a turn lane through decode, lint, certificate and evaluation
def rLane : Rule := { id := "t/lane", laws := [], binders := [car], applicability := .tt,
                      obligation := .forallRegion (.lit "lane") "r" (.not (occ "v" "r")) }
def onKind (k : String) : String := trace [scene 0 ("{\"id\": 11, \"kind\": \"" ++ k ++ "\", " ++ under ++ "}") "[1, 11]"]

-- entrances: the line of this entrance, of another, unobserved, observed to mark none; a turn lane named
def rEnt : Rule := { id := "t/entrance", laws := [], binders := [car], applicability := .tt,
                     obligation := .existsRegion (.lit "stop_line") "sl" (.existsRegion (.lit "lane") "a"
                       (.and (occ "v" "a") (.atom "st_entrance_of" [.var "sl", .var "a"] []))) }
def withLine (key : String) : String :=
  trace [scene 0 ("{\"id\": 10, \"kind\": \"lane\", " ++ beside ++ "}, {\"id\": 11, \"kind\": \"turn_lane\", " ++ under ++ "}, " ++
                  "{\"id\": 31, \"kind\": \"stop_line\", " ++ ahead ++ key ++ "}") "[1, 11]"]

-- directions: the agreement of motion with the designated direction, at any written length
def comp (m : String) (x : String) (k : String) : Term := .measure m [.var x, .lit k]
def rDir : Rule := { id := "t/direction", laws := [], binders := [car], applicability := .tt,
                     obligation := .existsRegion (.lit "lane") "r" (.and (occ "v" "r")
                       (.cmp (.add (.mul (comp "kin_velocity" "v" "x") (comp "st_lane_direction" "r" "x"))
                                   (.mul (comp "kin_velocity" "v" "y") (comp "st_lane_direction" "r" "y")))
                             .ge (.mul (.lit (Q.mk' 4 5) .ratio) speedV))) }
def dirTrace (d : String) (velocity : String) : String :=
  trace [scene 0 ("{\"id\": 10, \"kind\": \"lane\", " ++ under ++ ", \"lane\": {\"direction\": " ++ d ++ "}}") "[1, 10]" "5" velocity]

-- rises: a first observation where the condition is observed false is no rise
def rRise : Rule := { id := "t/rises", laws := [], binders := [car], applicability := .tt,
                      obligation := .not (.rises (.cmp speedV .le (mps 4))) }
def riseTrace : String := trace [scene 0 "" "" "5" (observed := false), scene 1000 "" "" "3" (observed := false)]

def s (x : String) : Json := Json.str x
#guard [onKind "turn_lane", onKind "reserved_lane", onKind "centre_turn_lane"].all fun tr => verdictOf rLane tr 0 == s "violated"
#guard verdictOf rLane (onKind "sidewalk") 0 == s "compliant"
#guard lintOf rLane (onKind "turn_lane") 0 == Json.arr #[]

#guard verdictOf rEnt (withLine ", \"entrance_of\": [11]") 0 == s "compliant"
#guard verdictOf rEnt (withLine ", \"entrance_of\": [10]") 0 == s "violated"
#guard verdictOf rEnt (withLine "") 0 == s "unknown"
#guard verdictOf rEnt (withLine ", \"entrance_of\": []") 0 == s "violated"
#guard lintOf rEnt (withLine ", \"entrance_of\": [11]") 0 == Json.arr #[]

#guard ["[2, 0]", "[1, 0]", "[0.0000001, 0]"].all fun d => verdictOf rDir (dirTrace d "[3, 4]") 0 == s "violated"
#guard ["[0.999999, 0]", "[2, 0]", "[1, 0]"].all fun d => verdictOf rDir (dirTrace d "[4, 3]") 0 == s "compliant"
#guard lintOf rDir (dirTrace "[2, 0]" "[3, 4]") 0 == Json.arr #[]

#guard verdictOf rRise riseTrace 0 == s "compliant"
#guard verdictOf rRise riseTrace 1000 == s "violated"
#guard lintOf rRise riseTrace 0 == Json.arr #[]

end TrafficSpec.Tests.Chains

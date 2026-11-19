import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Runtime.Decode
namespace TrafficSpec.Tests.RuleSets
open TrafficSpec Units TrafficSpec.Grounding Lean

-- Rule cases and the operators that read them, over a small synthetic library. No law is named;
-- the ids are test labels.
def S : Arg := .var "subject"
def P : Arg := .var "p"
def cls (c : String) (v : String) : Formula := .atom c [.var v] []
def halted : Formula := .cmp (.measure "kin_speed" [S]) .le (.lit Q.zero .metrePerSecond)
def underSign : Formula :=
  .existsDevice (.lit "stop_sign") "d" (.existsRegion (.lit "lane") "r"
    (.and (.atom "dev_governs" [.var "d", .var "r"] []) (.atom "rel_occupies" [S, .var "r"] [])))
def inCrosswalk : Formula := .existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [P, .var "c"] [])
def exempt : Formula := cls "ru_emergency_vehicle" "subject"

/-- A duty to halt under a sign, and its case. -/
def stopRule : Rule :=
  { id := "test/stop", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := underSign, obligation := halted
    cases := [{ name := "halt_at_sign", kind := .requires .halt, shown := halted }] }
/-- A duty toward a second road user with an exception in the obligation: halt while a pedestrian
    is in a crosswalk, unless the subject is an emergency vehicle. Its case follows the exception. -/
def giveWay : Rule :=
  { id := "test/give_way", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩, ⟨"p", cls "ru_pedestrian" "p"⟩]
    applicability := inCrosswalk, obligation := .or halted exempt
    cases := [{ name := "halt_for_walker", kind := .requires .halt, shown := halted, when := .not exempt }] }
/-- The same duty with a case that ignores the exception: the gate's controls refuse it. -/
def giveWayBroad : Rule :=
  { giveWay with id := "test/give_way_broad", cases := [{ name := "halt_for_walker", kind := .requires .halt, shown := halted }] }
/-- A prohibition of halting, except where some rule of the library requires the halt. -/
def noHalt : Rule :=
  { id := "test/no_halt", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := .tt, obligation := .or (.not halted) (.requiredBy .halt "subject") }
def library : List Rule := [stopRule, giveWay, noHalt]

def lane : Structure := Build.rect 10 .lane (metres (-50)) (metres 0) (metres 50) (metres 4)
def crosswalk : Structure := Build.rect 11 .crosswalk (metres 60) (metres 0) (metres 64) (metres 4)
def sidewalk : Structure := Build.rect 12 .sidewalk (metres 60) (metres 6) (metres 64) (metres 8)
def car (speed : Q) (classes : List RoadUserClass := [.motorVehicle]) : RoadUser :=
  Build.user 1 classes (metres 0, metres 2) Build.east speed (centimetres 250, metres 1, centimetres 75)
def walker (y : Int) : RoadUser := Build.user 2 [.pedestrian] (metres 62, metres y) Build.north Q.zero (centimetres 25, centimetres 25, centimetres 90)
def sign : Device := Build.sign 31 .stopSign [10]
def τ (users : List RoadUser) (devices : List Device) : Trace :=
  Build.trace 3 0 (seconds 1) fun _ t => Build.scene t (some 1) users [lane, crosswalk, sidewalk] devices
def ρ : Reading := { aggregates := [{ id := "T-1::vehicle", included := ["ru.motor_vehicle"] }] }
def setup (rules : List Rule) (tr : Trace) (incomplete : List String := []) : Setup :=
  { Setup.mk' rules tr ρ (seconds 2) with incomplete := incomplete }
def at0 (rules : List Rule) (tr : Trace) (r : Rule) (incomplete : List String := []) : Verdict :=
  Grounding.verdictAt (setup rules tr incomplete) r { assign := [("subject", 1)] } 0
def moving : Q := metresPerSecond 5

-- requiredBy: a halt a case of an engaged rule requires is excepted; one no case requires is not
#guard at0 library (τ [car Q.zero] [sign]) noHalt = .compliant                 -- the sign's rule requires it
#guard at0 library (τ [car Q.zero] []) noHalt = .violated                      -- nothing requires it
#guard at0 library (τ [car Q.zero, walker 2] []) noHalt = .compliant           -- a two-binder rule requires it
#guard at0 library (τ [car Q.zero, walker 7] []) noHalt = .violated            -- the pedestrian is on the sidewalk
#guard at0 library (τ [car moving] []) noHalt = .compliant                     -- no halt
-- an exception of the duty removes its case: an emergency vehicle is required no halt for the walker
#guard at0 library (τ [car Q.zero [.motorVehicle, .emergencyVehicle], walker 2] []) noHalt = .violated
-- no rule of the library declares the case: unknown, never an excuse and never a violation
#guard at0 [noHalt] (τ [car Q.zero] [sign]) noHalt = .unknown [.compositionUnknown "#requiredBy:halt: no rule of the library declares a case requiring halt"]
-- a set the run declares incomplete is never false: the missing rule might require the halt
#guard (at0 library (τ [car Q.zero] []) noHalt ["#requiredBy:halt"]).tag = "unknown"
#guard at0 library (τ [car Q.zero] [sign]) noHalt ["#requiredBy:halt"] = .compliant
-- an unobserved sign leaves the case, and the verdict, unknown
#guard (at0 library (Build.masked (Build.manifest ["dev.stop_sign"]) (τ [car Q.zero] [sign])) noHalt).tag = "unknown"

-- the gate's controls of a case against its rule's own verdicts (positive and negative)
def wit (r : Rule) (tr : Trace) (g : List (String × TrackId) := [("subject", 1)]) (members : List Rule := []) : Scenario :=
  { name := "w", rule := r.id, trace := tr, reading := ρ, manifest := Build.manifest
    grounding := g, expected := .compliant, setMembers := members }
def controls (lib : List Rule) (r : Rule) (tr : Trace) (g : List (String × TrackId) := [("subject", 1)]) : List String × List String :=
  Scenario.caseControls lib (wit r tr g) [] 0
#guard controls library stopRule (τ [car moving] [sign]) = ([], ["positive"])       -- not halting where the case holds: violated
#guard controls library stopRule (τ [car Q.zero] [sign]) = ([], ["met"])
#guard controls library stopRule (τ [car moving] []) = ([], ["outside"])            -- no sign: the case does not hold
def gw : List (String × TrackId) := [("subject", 1), ("p", 2)]
def emergency : List RoadUserClass := [.motorVehicle, .emergencyVehicle]
#guard controls library giveWay (τ [car moving emergency, walker 2] []) gw = ([], ["exception"])
#guard controls library giveWay (τ [car moving, walker 2] []) gw = ([], ["positive"])
#guard (controls [giveWayBroad] giveWayBroad (τ [car moving emergency, walker 2] []) gw).1 =
  ["w at 0: case `halt_for_walker` holds and the conduct is not shown, but the rule is compliant: the case reaches beyond the duty",
   "w at 1000: case `halt_for_walker` holds and the conduct is not shown, but the rule is compliant: the case reaches beyond the duty",
   "w at 2000: case `halt_for_walker` holds and the conduct is not shown, but the rule is compliant: the case reaches beyond the duty"]

-- strata: a rule that uses an operator is in no case set, so no rule is in its own set
def noHaltDeclaring : Rule := { noHalt with id := "test/no_halt_d", cases := [{ name := "x", kind := .requires .halt, shown := halted }] }
#guard (RuleSet.caseMembers (library ++ [noHaltDeclaring]) .halt).map Rule.id = ["test/stop", "test/give_way"]
#guard Rule.check (library ++ [noHaltDeclaring]) noHaltDeclaring =
  ["test/no_halt_d: declares a case requiring a conduct but uses a rule-set operator, itself or through a rule it composes, so it is in no set and the case is never read"]
#guard (RuleSet.caseMembers [{ stopRule with surrogate := true }] .halt).isEmpty
#guard (Rule.check library { stopRule with cases := [{ name := "c", kind := .requires .halt, shown := .requiredBy .halt "subject" }] }).length = 2
#guard (Rule.check library { stopRule with cases := [{ name := "Bad Name", kind := .requires .halt, shown := halted }] }).length = 1
#guard (Rule.check library { stopRule with cases := stopRule.cases ++ stopRule.cases }).length = 1
#guard (Rule.check library { noHalt with obligation := .requiredBy .halt "q" }).length = 1
#guard (Rule.check library { stopRule with binders := [⟨"subject", .requiredBy .halt "subject"⟩] }).length = 2
#guard Rule.check library noHalt = []
#guard Rule.check library stopRule = []
#guard Rule.check library giveWay = []
#guard (Rule.check library { stopRule with id := "#x" }).length = 1

-- lawful: every rule of the scope engaged for the road user is complied with, and never true
-- where that is not known
def speedLimit : Rule :=
  { id := "test/speed", laws := [], binders := [⟨"subject", .atom "ru_aggregate" [S, .lit "T-1::vehicle"] []⟩]
    applicability := .tt, obligation := .cmp (.measure "kin_speed" [S]) .le (.lit (metresPerSecond 20) .metrePerSecond) }
def lawfulAny : Rule :=
  { id := "test/lawful", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := .tt, obligation := .lawful .every "subject" }
def asVehicle : Rule :=
  { id := "test/as_vehicle", laws := [], binders := [⟨"subject", cls "ru_bicycle" "subject"⟩]
    applicability := .tt, obligation := .lawful (.asClass "T-1::vehicle") "subject" }
def ofVehicles : Rule := { asVehicle with id := "test/of_vehicles", obligation := .lawful (.subjectClass "T-1::vehicle") "subject" }
def lib2 : List Rule := [speedLimit, asVehicle, ofVehicles]
def bike (speed : Q) : RoadUser := Build.user 1 [.bicycle] (metres 0, metres 2) Build.east speed (centimetres 90, centimetres 30, centimetres 75)
-- the vehicle rule does not engage a bicycle, so plain compliance is empty; read as a vehicle it binds
#guard at0 lib2 (τ [bike (metresPerSecond 30)] []) ofVehicles = .compliant
#guard at0 lib2 (τ [bike (metresPerSecond 30)] []) asVehicle = .violated
#guard at0 lib2 (τ [bike (metresPerSecond 10)] []) asVehicle = .compliant
-- a scope the run declares incomplete is never true: a missing rule might be broken
#guard (at0 lib2 (τ [bike (metresPerSecond 10)] []) asVehicle ["#lawful:as:T-1::vehicle"]).tag = "unknown"
#guard at0 lib2 (τ [bike (metresPerSecond 30)] []) asVehicle ["#lawful:as:T-1::vehicle"] = .violated
-- a scope that holds no rule: unknown
#guard (at0 [ofVehicles] (τ [bike Q.zero] []) ofVehicles).tag = "unknown"
-- a rule of the scope left out by the strata (it uses `lawful` itself) whose class the road user
-- meets makes the result unknown, never true: `lawfulAny` is in its own scope
#guard (at0 ([speedLimit, lawfulAny]) (τ [car (metresPerSecond 10)] []) lawfulAny).tag = "unknown"
#guard at0 ([speedLimit, lawfulAny]) (τ [car (metresPerSecond 30)] []) lawfulAny = .violated
-- one whose class the road user does not meet is not relevant to it: a bicycle is no motor vehicle
def lawfulBikeAny : Rule := { asVehicle with id := "test/bike_lawful", obligation := .lawful .every "subject" }
def strictBike : Rule := { speedLimit with id := "test/bike_speed", binders := [⟨"subject", cls "ru_bicycle" "subject"⟩] }
#guard (at0 [strictBike, lawfulAny, lawfulBikeAny] (τ [bike (metresPerSecond 10)] []) lawfulBikeAny).tag = "unknown"  -- itself
#guard (RuleSet.lawfulMembers (lib2 ++ library) .every).map Rule.id = ["test/speed", "test/stop", "test/give_way", "test/no_halt"]

-- purpose scopes (D4): the members are the rules that declare the purpose, held to what they read
def obeySign : Rule :=
  { stopRule with id := "test/obey_sign", cases := [], purposes := [.deviceInstruction] }
def noStanding : Rule :=
  { id := "test/no_standing", laws := [], binders := [⟨"subject", .atom "ru_aggregate" [S, .lit "T-1::vehicle"] []⟩]
    applicability := .existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [S, .var "c"] []),
    obligation := .not halted, purposes := [.standingOrParking] }
def obeyDevices : Rule := { lawfulAny with id := "test/obey_devices", obligation := .lawful (.purpose .deviceInstruction) "subject" }
def lawfullyStood : Rule := { lawfulAny with id := "test/lawfully_stood", obligation := .lawful (.purpose .standingOrParking) "subject" }
def lib4 : List Rule := [obeySign, noStanding, speedLimit, obeyDevices, lawfullyStood]
#guard (RuleSet.lawfulMembers lib4 (.purpose .deviceInstruction)).map Rule.id = ["test/obey_sign"]
#guard (RuleSet.lawfulMembers lib4 (.purpose .standingOrParking)).map Rule.id = ["test/no_standing"]
#guard at0 lib4 (τ [car moving] [sign]) obeyDevices = .violated                 -- the sign's instruction is broken
#guard at0 lib4 (τ [car (metresPerSecond 30)] []) obeyDevices = .compliant       -- speeding is no device instruction
#guard at0 lib4 (τ [car Q.zero] []) obeyDevices = .compliant
-- a declared purpose is held to paired witnesses that turn on standing, or on a device
#guard Rule.check lib4 obeySign = []
#guard Rule.check lib4 noStanding = []
#guard (Rule.check lib4 { obeySign with purposes := [.deviceInstruction, .deviceInstruction] }).length = 1
def carAt (x : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (metres x, metres 2) Build.east speed (centimetres 250, metres 1, centimetres 75)
def pw (r : Rule) (tr : Trace) : Scenario :=
  { name := "p", rule := r.id, trace := tr, reading := ρ, manifest := Build.manifest, grounding := [("subject", 1)], expected := .compliant }
def inWalk (speed : Q) (devices : List Device := []) : Trace := τ [carAt 62 speed] devices
#guard Scenario.purposeControls lib4 (pw noStanding (inWalk Q.zero)) (pw noStanding (inWalk moving)) [] .standingOrParking = []
#guard Scenario.purposeControls (lib4.map fun r => if r.id == "test/speed" then { r with purposes := [.standingOrParking] } else r)
    (pw speedLimit (inWalk Q.zero)) (pw speedLimit (inWalk moving)) [] .standingOrParking =
  ["the first witness is compliant, not violated: the duty does not turn on standing_or_parking"]   -- a speed duty is no parking rule
#guard Scenario.purposeControls lib4 (pw obeySign (τ [car moving] [sign])) (pw obeySign (τ [car moving] [])) [] .deviceInstruction = []
#guard Scenario.purposeControls lib4 (pw speedLimit (τ [car (metresPerSecond 30)] [sign])) (pw speedLimit (τ [car (metresPerSecond 30)] [])) [] .deviceInstruction =
  ["the second witness is violated: the duty is broken without device_instruction"]               -- nor a device instruction
#guard (Scenario.purposeControls lib4 (pw noStanding (inWalk Q.zero)) (pw noStanding (τ [carAt 62 moving, walker 7] [])) [] .standingOrParking).length = 1

-- a case requiring a halt is held to a halt, a drive and a creep in the same external situation
def sw (r : Rule) (tr : Trace) : Scenario :=
  { name := "s", rule := r.id, trace := tr, reading := ρ, manifest := Build.manifest, grounding := [("subject", 1)], expected := .compliant }
def creeping : Q := metresPerSecond 1
#guard Scenario.stopControls library (sw stopRule (τ [car Q.zero] [sign])) (sw stopRule (τ [car moving] [sign])) (sw stopRule (τ [car creeping] [sign])) [] 0 = []
-- a duty met by slowing (no speed above a crawl while a walker is near) requires no stop
def crawlBound : Formula := .cmp (.measure "kin_speed" [S]) .le (.lit (metresPerSecond 2) .metrePerSecond)
def slowNearWalker : Rule :=
  { id := "test/slow", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := .existsUser "p" (.and (cls "ru_pedestrian" "p") (.not (.same (.var "p") S))), obligation := crawlBound
    cases := [{ name := "slow_for_walker", kind := .requires .halt, shown := halted }] }
#guard Scenario.stopControls [slowNearWalker] (sw slowNearWalker (τ [car Q.zero, walker 2] [])) (sw slowNearWalker (τ [car moving, walker 2] []))
    (sw slowNearWalker (τ [car creeping, walker 2] [])) [] 0 =
  ["creeping in the same situation is compliant, not violated: the duty is met short of a stop"]
-- a case that depends on the subject's own motion
def ownMotion : Rule := { stopRule with id := "test/own", cases := [{ name := "x", kind := .requires .halt, shown := halted, when := .not halted }] }
#guard (Scenario.stopControls [ownMotion] (sw ownMotion (τ [car Q.zero] [sign])) (sw ownMotion (τ [car moving] [sign])) (sw ownMotion (τ [car creeping] [sign])) [] 0).contains
  "the case holds differently as the subject halts, drives or creeps: it depends on the subject's own motion"
-- a pair in different situations
#guard (Scenario.stopControls library (sw stopRule (τ [car Q.zero] [sign])) (sw stopRule (τ [car moving] [])) (sw stopRule (τ [car creeping] [sign])) [] 0).contains
  "the halt, drive and creep witnesses differ in more than the subject's motion"

-- a vehicle rule's device instructions applied to a bicycle (class transfer by purpose)
def bikeObeys : Rule :=
  { asVehicle with id := "test/bike_obeys", obligation := .lawful (.asClassPurpose "T-1::vehicle" .deviceInstruction) "subject" }
def vehicleSign : Rule := { obeySign with id := "test/vehicle_sign", binders := [⟨"subject", .atom "ru_aggregate" [S, .lit "T-1::vehicle"] []⟩] }
def lib5 : List Rule := [vehicleSign, speedLimit, bikeObeys]
#guard at0 lib5 (τ [bike moving] [sign]) bikeObeys = .violated                  -- the sign binds the bicycle
#guard at0 lib5 (τ [bike (metresPerSecond 30)] []) bikeObeys = .compliant        -- the vehicle speed rule does not
#guard (at0 lib5 (τ [bike moving] [sign]) bikeObeys ["#lawful:aspurpose:device_instruction:T-1::vehicle"]).tag = "violated"
#guard (at0 lib5 (τ [bike Q.zero] [sign]) bikeObeys ["#lawful:aspurpose:device_instruction:T-1::vehicle"]).tag = "unknown"
#guard ((RuleSet.ofId (RuleSet.lawfulId (.asClassPurpose "T-1::vehicle" .deviceInstruction))).bind RuleSet.idOf) =
  some "#lawful:aspurpose:device_instruction:T-1::vehicle"
#guard ((Decode.parse (Decode.formula "f") (bikeObeys.obligation.toJson.compress)).toOption.map (·.toJson.compress)) = some bikeObeys.obligation.toJson.compress

-- ruleCase: an exception reads the case another rule provides for, not its whole applicability
def mayPass : Formula := .not halted
def passRule : Rule :=
  { id := "test/may_pass", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := underSign, obligation := .tt, permission := true
    cases := [{ name := "pass_when_clear", kind := .permits, shown := mayPass, when := .not (.existsUser "p" (.and (cls "ru_pedestrian" "p") inCrosswalk)) }] }
def keepStill : Rule :=
  { id := "test/keep_still", laws := [], binders := [⟨"subject", cls "ru_motor_vehicle" "subject"⟩]
    applicability := underSign, obligation := .or halted (.ruleCase "test/may_pass" "pass_when_clear" [("subject", "subject")]) }
def lib3 : List Rule := [passRule, keepStill]
#guard at0 lib3 (τ [car moving] [sign]) keepStill = .compliant                  -- the permitted case holds
#guard at0 lib3 (τ [car moving, walker 2] [sign]) keepStill = .violated         -- the target applies, its case does not
#guard at0 lib3 (τ [car moving] [sign]) passRule = .compliant                   -- a permission is never violated
#guard Rule.check lib3 keepStill = []
#guard Rule.check lib3 passRule = []
#guard keepStill.composes = ["test/may_pass"]                                    -- a dependency like any composition
#guard Rule.check lib3 { keepStill with obligation := .ruleCase "test/may_pass" "nowhere" [("subject", "subject")] } =
  ["test/keep_still: reads case `nowhere` of `test/may_pass`, which declares no such case"]
#guard (at0 lib3 (τ [car moving] [sign]) { keepStill with obligation := .ruleCase "test/may_pass" "nowhere" [("subject", "subject")] }).tag = "unknown"
#guard Rule.check lib3 { passRule with obligation := halted } = ["test/may_pass: a permission's obligation is `tt`"]
#guard (Rule.check lib3 { passRule with cases := [] }).length = 1
#guard controls lib3 passRule (τ [car moving] [sign]) = ([], ["positive"])
#guard controls lib3 passRule (τ [car moving] []) = ([], ["outside"])

-- the monitor counts no permission as compliant or violated, and its summaries leave it out
def monLines : List Monitor.RuleLine :=
  match Monitor.check lib3 (τ [car moving] [sign]) ρ (Build.manifest) with
  | .ok rep => rep.rules
  | .error _ => []
#guard (monLines.find? (·.rule == "test/may_pass")).map (fun l => (l.permission, l.violated, l.compliant, l.groundings)) = some (true, 0, 0, 1)
#guard (monLines.find? (·.rule == "test/keep_still")).map (fun l => (l.permission, l.compliant)) = some (false, 1)
#guard (Monitor.summaryLine "concrete" monLines).splitOn "\t" |>.contains "rules=1"

-- an approved abstraction makes a rule partial coverage: its verdicts carry the ids on every line,
-- are tallied apart from the concrete ones, and a rule reading it, by a composition or a rule-set
-- operator, rests on it too
def stopAbs : Rule := { stopRule with abstractions := ["test_abstraction"] }
def libAbs : List Rule := [stopAbs, giveWay, noHalt]
#guard RuleSet.abstractionsOf libAbs stopAbs = ["test_abstraction"]
#guard RuleSet.abstractionsOf libAbs noHalt = ["test_abstraction"]              -- its `requiredBy` ranges over stopAbs
#guard RuleSet.abstractionsOf libAbs giveWay = []
#guard RuleSet.abstractionsOf library noHalt = []
#guard RuleSet.abstractionsOf [{ passRule with abstractions := ["test_abstraction"] }, keepStill] keepStill = ["test_abstraction"]
def keepAbs : Rule := { keepStill with abstractions := ["b", "a"] }
#guard RuleSet.abstractionsOf [{ passRule with abstractions := ["a"] }, keepAbs] keepAbs = ["b", "a"]
#guard (stopAbs.toJson.compress.splitOn "\"abstractions\":[\"test_abstraction\"]").length == 2
def repAbs : Monitor.Report :=
  match Monitor.check libAbs (τ [car Q.zero] [sign]) ρ (Build.manifest) with
  | .ok rep => rep
  | .error _ => default
def textAbs : List String := (Monitor.renderText repAbs).splitOn "\n"
#guard textAbs.contains "RULE\ttest/stop\tabstracted\tsupported\t\tgroundings=1\tlive=true\tv=0\tc=1\tna=0\tu=0\tabstractions=test_abstraction\tsampled_duration=false"
#guard textAbs.any (·.startsWith "RULE\ttest/give_way\tconcrete\t")
#guard textAbs.any (·.startsWith "RULE\ttest/no_halt\tabstracted\t")
#guard textAbs.contains "GROUND\ttest/stop\tsubject=1\tcompliant\tabstractions=test_abstraction\tsampled_duration=false"
#guard textAbs.any (·.startsWith "SUMMARY\tconcrete\trules=1\t")
#guard textAbs.any (·.startsWith "SUMMARY\tabstracted\trules=2\t")
#guard textAbs.any (·.startsWith "SUMMARY\tsurrogate\trules=0\t")
#guard ((Monitor.renderJsonLines repAbs).splitOn "\n").any fun l =>
  (l.splitOn "\"kind\":\"grounding\"").length == 2 && (l.splitOn "\"rule\":\"test/stop\"").length == 2
    && (l.splitOn "\"abstractions\":[\"test_abstraction\"]").length == 2 && (l.splitOn "\"partial_coverage\":true").length == 2
#guard ((Monitor.renderJsonLines repAbs).splitOn "\n").any fun l =>
  (l.splitOn "\"kind\":\"rule\"").length == 2 && (l.splitOn "\"rule\":\"test/give_way\"").length == 2
    && (l.splitOn "\"abstractions\":[]").length == 2 && (l.splitOn "\"partial_coverage\":false").length == 2

-- a witness ranges the operators over its own members, never the library
def witNo (members : List Rule) (tr : Trace) (expected : Verdict) : Scenario :=
  { name := "w", rule := "test/no_halt", trace := tr, reading := ρ, manifest := Build.manifest
    grounding := [("subject", 1)], expected := expected, setMembers := members }
#guard ((witNo [stopRule] (τ [car Q.zero] [sign]) .compliant).run [noHalt]).toOption = some .compliant
#guard ((witNo [giveWay] (τ [car Q.zero] [sign]) .violated).run library).toOption = some .violated

-- the monitor registers the whole library for a rule that reads an operator, else the closure
#guard (RuleSet.registered (library ++ lib2) [noHalt]).length = (library ++ lib2).length
#guard (RuleSet.registered (library ++ lib3) [keepStill]).map Rule.id = ["test/keep_still", "test/may_pass"]

-- the operators as data: distinct encodings, the export and its decoding
#guard (Formula.requiredBy .halt "subject").enc != (Formula.lawful .every "subject").enc
#guard (Formula.lawful (.subjectClass "a") "x").enc != (Formula.lawful (.asClass "a") "x").enc
#guard (Formula.ruleCase "r" "a" []).enc != (Formula.ruleApplies "r" []).enc
#guard (Formula.requiredBy .halt "subject").toJson.compress = "{\"required_by\":\"halt\",\"who\":\"subject\"}"
#guard ((Decode.parse (Decode.formula "f") ((Formula.lawful (.asClass "T-1::vehicle") "s").toJson.compress)).toOption.map (·.toJson.compress))
  = some (Formula.lawful (.asClass "T-1::vehicle") "s").toJson.compress
#guard ((Decode.parse (Decode.formula "f") (keepStill.obligation.toJson.compress)).toOption.map (·.toJson.compress)) = some keepStill.obligation.toJson.compress
#guard (Formula.ruleSets noHalt.obligation).length = 1
#guard Formula.caseRefs keepStill.obligation = [("test/may_pass", "pass_when_clear")]
#guard ((RuleSet.ofId (RuleSet.lawfulId (.subjectClass "T-1::vehicle"))).bind RuleSet.idOf) = some "#lawful:class:T-1::vehicle"
#guard RuleSet.ofCaseId (RuleSet.caseId "test/may_pass" "pass_when_clear") = some ("test/may_pass", "pass_when_clear")

end TrafficSpec.Tests.RuleSets

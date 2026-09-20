import TrafficSpec.Core.Monitor
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.Grounding
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Grounding TrafficSpec.Tests.Semantics

-- A synthetic rule over the braking trace: two motor vehicles, x following y within 30 m, must
-- keep a time gap of at least 1.5 s. No law is named; the ids are test labels.
def X : Arg := .var "x"
def Y : Arg := .var "y"
def mv (v : String) : Formula := .atom "ru_motor_vehicle" [.var v] []
def rule : Rule :=
  { id := "test/gap"
    laws := []
    binders := [⟨"x", mv "x"⟩, ⟨"y", mv "y"⟩]
    applicability := .derived "drv_following" [X, Y] [.lit (metres 30) .metre]
    obligation := .cmp (.quantity "drv_time_gap" [X, Y] []) .ge (.lit (Q.mk' 15 10) .second)
    residues := ["the text's standard is quantified by the reading"] }
def truckRule : Rule :=
  { id := "test/truck_stop"
    laws := []
    binders := [⟨"x", .atom "ru_truck" [X] []⟩]
    applicability := .tt
    obligation := .derived "drv_stopped" [X] [.param "p.stop_speed", .lit (seconds 1) .second] }
def composed : Rule :=
  { id := "test/both"
    laws := []
    binders := [⟨"x", mv "x"⟩, ⟨"y", mv "y"⟩]
    applicability := .tt
    obligation := .and (.rule "test/gap" [("x", "x"), ("y", "y")]) (.rule "test/truck_stop" [("x", "y")]) }
def rules : List Rule := [rule, truckRule, composed]

#guard rule.wellFormed
#guard rule.atoms = ["ru_motor_vehicle", "drv_following", "drv_time_gap"]
#guard rule.atomIds = ["ru.motor_vehicle", "rel.ahead_behind_in_lane", "rel.surface_gap", "kin.speed"]
#guard composed.composes = ["test/gap", "test/truck_stop"]
#guard atomIdOf "dev_traffic_signal_shows" = some "dev.traffic_signal"
#guard atomIdOf "st_lane_adjacency_left" = some "st.lane_adjacency"
#guard atomIdOf "st_lane" = some "st.lane"
#guard atomIdOf "rel_ahead_in_lane" = some "rel.ahead_behind_in_lane"
#guard atomIdOf "drv_stopped" = none

def full : Manifest := Manifest.full "test" (seconds 2)
#guard full.complete
#guard support rule full = .supported
def noSpeed : Manifest := { full with entries := full.entries.map fun (id, c) => if id == "kin.speed" then (id, .absent) else (id, c) }
#guard support rule noSpeed = .partially ["kin.speed"]        -- the obligation also reads the surface gap
#guard support truckRule noSpeed = .unsupported ["kin.speed"] -- drv_stopped reads nothing else
def noGap : Manifest := { full with entries := full.entries.map fun (id, c) => if id == "rel.surface_gap" then (id, .absent) else (id, c) }
#guard support rule noGap = .partially ["rel.surface_gap"]
def noClass : Manifest := { full with entries := full.entries.map fun (id, c) => if id == "ru.motor_vehicle" then (id, .absent) else (id, c) }
#guard support rule noClass = .unsupported ["ru.motor_vehicle"]
#guard !({ full with entries := full.entries.drop 1 } : Manifest).complete

-- masking blanks the field and only that field
#guard kin_speed (mask noSpeed (sceneAt 0)) 1 = none
#guard (kin_position (mask noSpeed (sceneAt 0)) 1).isSome
#guard ru_motor_vehicle (mask noClass (sceneAt 0)) 1 = none
#guard ru_truck (mask noClass (sceneAt 0)) 2 = some true
def noSignals : Manifest := { full with entries := full.entries.map fun (id, c) => if id == "dev.traffic_signal" then (id, .absent) else (id, c) }
#guard (mask noSignals (sceneAt 0)).devices = []
#guard (mask full (sceneAt 0)).devices.length = 1

-- groundings over the unbroken trace: x, y ∈ {1, 2}, distinct
def S : Setup := Setup.mk' rules τ ρ (seconds 2)
#guard (groundings S rule).length = 2
#guard predictedGroundings S rule = 4
#guard (groundings S truckRule) = [⟨[("x", 2)]⟩]
def g12 : Grounding := ⟨[("x", 1), ("y", 2)]⟩
def g21 : Grounding := ⟨[("x", 2), ("y", 1)]⟩
-- gaps 25.5/10, 20.5/8, 16.5/6, 13.5/4, 11.5/2 s all exceed 1.5 s; then x stands and the gap is undefined
#guard (timeline S rule g12).map (·.2) =
  List.replicate 5 Verdict.compliant ++ List.replicate 4 (Verdict.unknown [.divisionByZero "drv_time_gap"])
def strict : Rule := { rule with obligation := .cmp (.quantity "drv_time_gap" [X, Y] []) .ge (.lit (seconds 3) .second) }
#guard ((timeline S strict g12).map (·.2)).take 3 = [Verdict.violated, Verdict.violated, Verdict.violated]
#guard (timeline S rule g21).map (·.2) = List.replicate 9 Verdict.notApplicable   -- y=1 is not ahead of x=2
#guard episode ((timeline S rule g21).map (·.2)) = .notApplicable
#guard live S rule
#guard !(live S { rule with applicability := .ff })
#guard episode [.compliant, .notApplicable] = .compliant
#guard episode [.compliant, .unknown [.outOfRange], .violated] = .violated
#guard episode [.compliant, .unknown [.outOfRange], .unknown [.outOfRange]] = .unknown [.outOfRange]
#guard episode [] = .notApplicable

-- composition: both rules through the callback, binders remapped
#guard (((timeline S composed g12).map (·.2)).drop 2).take 3 = List.replicate 3 Verdict.compliant
#guard Grounding.verdictAt S composed g12 0 = Verdict.unknown [.windowTruncated "drv_stopped"]
#guard Grounding.verdictAt S composed g12 8 = Verdict.unknown [.divisionByZero "drv_time_gap"]
#guard Grounding.verdictAt S truckRule ⟨[("x", 2)]⟩ 8 = Verdict.compliant
#guard Grounding.verdictAt S truckRule ⟨[("x", 2)]⟩ 0 = Verdict.unknown [.windowTruncated "drv_stopped"]

-- re-identification: track 1 vanishes at instants 3–4 and returns as track 5 from instant 5
def rename (s : Scene) : Scene :=
  { s with users := s.users.map fun u => if u.track == 1 then { u with track := 5 } else u
           occupies := s.occupies.map fun (t, r) => if t == 1 then (5, r) else (t, r)
           subject := some 5 }
def τb : Trace := (List.range 9).map fun k =>
  let s := sceneAt k
  if k == 3 || k == 4 then { s with users := s.users.filter (·.track != 1), occupies := s.occupies.filter (·.1 != 1) }
  else if k ≥ 5 then (if k == 5 then { rename s with links := [(1, 5)] } else rename s)
  else s
def Sb : Setup := Setup.mk' rules τb ρ (Q.mk' 15 10)     -- the break spans 1000 ms → 2500 ms: 1.5 s, accepted
#guard acceptedLinks τb (Q.mk' 15 10) = [(1, 5)]
#guard acceptedLinks τb (seconds 1) = []
#guard canon Sb.cm 5 = 1
#guard canonicalTracks Sb.cm = [1, 2]
#guard span τb Sb.cm 1 = some (0, 8)
#guard (groundings Sb rule).length = 2
#guard (((timeline Sb rule g12).map (·.2)).drop 2).take 4 =
  [Verdict.compliant, Verdict.unknown [.identityGap 1], Verdict.unknown [.identityGap 1], Verdict.unknown [.divisionByZero "drv_time_gap"]]
-- with a gap the source does not bridge, 5 is a new party and 1 leaves the scene
def Sc : Setup := Setup.mk' rules τb ρ (seconds 1)
#guard canonicalTracks Sc.cm = [1, 2, 5]
#guard (groundings Sc rule).length = 6
#guard ((timeline Sc rule g12).map (·.2)).drop 3 = List.replicate 6 Verdict.notApplicable

-- the report
def rep : Monitor.Report := Monitor.check rules τ ρ full
#guard rep.rules.length = 3
#guard rep.rows.length = 2 + 1 + 2
#guard (rep.rules.map (·.live)) = [true, true, true]
def text : String := Monitor.renderText rep
#guard (text.splitOn "\n").any (·.startsWith "SOURCE\ttest\tinstants=9\tgap=2")
#guard (text.splitOn "\n").any (· == "GROUND\ttest/gap\tx=2,y=1\tnot_applicable")
#guard (text.splitOn "\n").any (· == "TL\ttest/gap\tx=1,y=2\t2500\t4000\tunknown")
#guard (text.splitOn "\n").any (· == "UNK\ttest/gap\tx=1,y=2\tdivision_by_zero:drv_time_gap\t4")
#guard (text.splitOn "\n").any (·.startsWith "SUMMARY\tconcrete\trules=3\tsupported=3\tpartial=0\tunsupported=0\tlive=3")
#guard (text.splitOn "\n").any (·.startsWith "SUMMARY\tsurrogate\trules=0")
def repNoSpeed : Monitor.Report := Monitor.check rules τ ρ noSpeed
#guard (repNoSpeed.rules.map (·.support.tag)) = ["partial", "unsupported", "supported"]
#guard repNoSpeed.rows.length = 2 + 0 + 2                       -- the unsupported rule is not enumerated
#guard (repNoSpeed.rows.map (·.episode)) =
  [Verdict.unknown [.absentAtom "kin_speed"], Verdict.notApplicable,
   Verdict.unknown [.absentAtom "kin_speed", .windowTruncated "drv_stopped"], Verdict.compliant]
#guard ((Monitor.renderJsonLines rep).splitOn "\n").length = 1 + 3 + 5 + 1

end TrafficSpec.Tests.Grounding

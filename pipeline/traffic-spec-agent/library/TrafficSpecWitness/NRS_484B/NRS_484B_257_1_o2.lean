/-
  Witnesses for NRS_484B_257_1_o2.

  Geometry (metres, +x east, +y north). Intersection X (region 1) is the square [-5,5]×[-5,5],
  lying on highways h1 (100, north–south, [-5,5]×[-100,100]) and h2 (101, east–west,
  [-100,100]×[-5,5]). Four approach carriers enter X:
    c  (10) northbound on h1, [0,5]×[-100,-5]  — the subject's approach;
    c2 (11) eastbound  on h2, [-100,-5]×[-5,0];
    c4 (12) southbound on h1, [-5,0]×[5,100];
    c5 (13) westbound  on h2, [5,100]×[0,5].
  A stop line (20) on c spans [0,5]×[-9,-7]. Devices: stop sign 50, yield sign 51, a sign 52 on c2,
  a police officer 60, a traffic signal 70.

  Instants every 1 s, k = 0 … 11. The subject (track 1, car, half extents 2.25 × 0.9 × 0.75) runs
  north on x = 2.5: y = -24, -20, -16, -12, then halts at y = -8 (on the stop line) for k = 4..6,
  creeps to -6.5 (k = 7), enters X at k = 8 (y = -4) and crosses at 3 m/s (y = -1, 2), leaving X at
  k = 11 (y = 6). The other vehicle v (track 2) runs east on y = -2.5.
  Reading: halt tolerance 0.1 m/s, horizon 3 s, clearance 3 m.
    forbid: v at x = -0.5 at k = 8 (in X since k = 7, from c2), 3 m/s: closest approach to the
      subject 0.75 s ahead at 1.06 m — conflict by a wide margin.
    permit: v crosses X at k = 4..6 and is 9.5 m east of X by k = 8: no v is protected while the
      subject moves.
    branch_3: v at x = -5.5 in c2 at k = 8 at 10 m/s: closest approach 0.78 s ahead at 0.86 m; v
      then halts in c2 (k ≥ 9), so only the approaching limb (n) decides.
    branch_12: v halted inside X at (-3.5, -2.5) (entered from c2): closest approach 6 m — no
      conflict, no contact: compliant with a protected v present.
    branch_13: stop sign governs X only; v on c4 (h1, the subject's own highway) at (-2.5, 5.5)
      heading (0.6, -0.8) at 5 m/s: closest approach 0.85 m within 1.4 s, but h1 carries c, so it
      is no through highway: compliant.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def regX : Structure := { Build.rect 1 .intersection (m (-5)) (m (-5)) (m 5) (m 5) with ways := some [100, 101] }
def laneC : Structure := { Build.lane 10 (box 0 (-100) 5 (-5)) Build.north (enters := some 1) with ways := some [100] }
def laneC2 : Structure := { Build.lane 11 (box (-100) (-5) (-5) 0) Build.east (enters := some 1) with ways := some [101] }
def laneC4 : Structure := { Build.lane 12 (box (-5) 5 0 100) Build.south (enters := some 1) with ways := some [100] }
def laneC5 : Structure := { Build.lane 13 (box 5 0 100 5) Build.west (enters := some 1) with ways := some [101] }
def stopLine : Structure :=
  { Build.rect 20 .stopLine (m 0) (m (-9)) (m 5) (m (-7)) with
      ways := some [100], entranceOf := [10], entranceObserved := true }
def hwy1 : Structure := Build.rect 100 .highway (m (-5)) (m (-100)) (m 5) (m 100)
def hwy2 : Structure := Build.rect 101 .highway (m (-100)) (m (-5)) (m 100) (m 5)

def structures : List Structure := [regX, laneC, laneC2, laneC4, laneC5, stopLine, hwy1, hwy2]

-- Devices
def stopOn (id : Nat) (rs : List Nat) : Device := { Build.sign id .stopSign rs with conditions := some {} }
def yieldOn (id : Nat) (rs : List Nat) : Device := { Build.sign id .yieldSign rs with conditions := some {} }
def police (rs : List Nat) : Device :=
  { Build.device 60 .humanDirection rs with humanRole := some .policeOfficer, humanIndication := some .proceed }
def signalOn (rs : List Nat) (inop : Bool) : Device :=
  { Build.signal 70 rs (if inop then [.dark] else [.circularGreen]) with
      uncovered := some true, inoperative := some inop }

-- The subject, halting at the stop line before entering X (y in cm, speed in m/s).
def stopY : Nat → Int
  | 0 => -2400 | 1 => -2000 | 2 => -1600 | 3 => -1200
  | 4 => -800 | 5 => -800 | 6 => -800 | 7 => -650
  | 8 => -400 | 9 => -100 | 10 => 200 | _ => 600
def stopSpeed : Nat → Int
  | 0 => 4 | 1 => 4 | 2 => 4 | 3 => 3
  | 4 => 0 | 5 => 0 | 6 => 0 | 7 => 2
  | 8 => 3 | 9 => 3 | 10 => 3 | _ => 4
def subjStop (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 250, cm (stopY k)) Build.north (Units.metresPerSecond (stopSpeed k)) carExt

-- The subject running through without halting: y = -24 + 4k, 4 m/s; enters X at k = 5.
def subjRun (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 250, cm (-2400 + 400 * (k : Int))) Build.north (Units.metresPerSecond 4) carExt

-- v entering X from c2 at k = 7, at x = -0.5 at k = 8, 3 m/s east.
def vForbid (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-2450 + 300 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 3) carExt
-- v that crossed X at k = 4..6, long gone when the subject enters.
def vPermit (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-1450 + 300 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 3) carExt
-- v for the run-through subject: x = -0.5 at k = 5.
def vRun (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-1550 + 300 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 3) carExt
-- v approaching fast on c2, at x = -5.5 at k = 8, halting there from k = 9.
def vApproach (k : Nat) : RoadUser :=
  if k ≤ 8 then
    Build.user 2 [.motorVehicle] (cm (-8550 + 1000 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 10) carExt
  else
    Build.user 2 [.motorVehicle] (cm (-550), cm (-250)) Build.east (Units.metresPerSecond 0) carExt
-- v entering X from c2 at k = 5 and halting inside X at (-3.5, -2.5).
def vHalted (k : Nat) : RoadUser :=
  if k ≤ 4 then
    Build.user 2 [.motorVehicle] (cm (-1850 + 300 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 3) carExt
  else
    Build.user 2 [.motorVehicle] (cm (-350), cm (-250)) Build.east (Units.metresPerSecond 0) carExt
-- v on c4 (h1) at (-2.5, 5.5), heading (0.6, -0.8), moving at 5 m/s at k = 8 only.
def vFromNorth (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-250), cm 550) (Units.ratio 3 5, Units.ratio (-4) 5)
    (Units.metresPerSecond (if k = 8 then 5 else 0)) carExt

def mkTraceS (structs : List Structure) (subj : Nat → RoadUser) (others : Nat → List RoadUser)
    (devs : List Device) : Trace :=
  Build.trace 12 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (subj k :: others k) structs devs

def mkTrace (subj : Nat → RoadUser) (others : Nat → List RoadUser) (devs : List Device) : Trace :=
  mkTraceS structures subj others devs

-- Two overlapping northbound carriers of the subject's approach: c (10) recorded on h1 and h2, and
-- c' (14), the same strip, on h1 only.
def laneCBoth : Structure := { laneC with ways := some [100, 101] }
def laneCPrime : Structure := { Build.lane 14 (box 0 (-100) 5 (-5)) Build.north (enters := some 1) with ways := some [100] }
def structuresTwo : List Structure := [regX, laneCBoth, laneCPrime, laneC2, laneC4, laneC5, stopLine, hwy1, hwy2]

/-- `forbid` (violated): A dev.stop_sign governs c; the subject halted at the stop line and entered X; v occupies X having entered from carrier c2 on a crossing highway whose carriers entering X carry no stop or yield sign; the subject moves across X with kin.speed above p.halt_speed_tolerance and its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10]]

/-- `permit` (compliant): Same scene; v has cleared X before the subject moves; no closest approach to any through-highway vehicle falls within the bound while the subject moves. -/
def permitTrace : Trace := mkTrace subjStop (fun k => [vPermit k]) [stopOn 50 [10]]

/-- `idle` (not_applicable): No stop or yield sign governs c or X when the subject enters X. -/
def idleTrace : Trace := mkTrace subjStop (fun k => [vForbid k]) []

/-- `blind` (unknown): The subject moves within X while v crosses from another highway on a conflicting path; dev.governs is absent, so whether a sign governs c, and which highway is the through highway, are unknown. -/
def blindTrace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10]]

/-- `branch_1` (compliant): After its stop the subject crosses X with no other road user in the scene. -/
def branch_1Trace : Trace := mkTrace subjStop (fun _ => []) [stopOn 50 [10]]

/-- `branch_2` (not_applicable): The subject entered X without halting at its stop sign (NRS_484B_257_1_o1 violated at its entry) and moves across X in conflict with v: the duty follows the stop the words name; the omitted stop is judged by NRS_484B_257_1_o1. -/
def branch_2Trace : Trace := mkTrace subjRun (fun k => [vRun k]) [stopOn 50 [10]]

/-- `branch_3` (violated): After its stop the subject moves within X; v approaches on carrier c2 of the through highway, not yet in X, with its closest approach to the subject within p.conflict_horizon below p.conflict_centre_clearance; the subject keeps moving. -/
def branch_3Trace : Trace := mkTrace subjStop (fun k => [vApproach k]) [stopOn 50 [10]]

/-- `branch_4` (not_applicable): as forbid, but a police officer directs traffic on c (exception a). -/
def branch_4Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], police [10]]

/-- `branch_5` (not_applicable): as forbid, but a police officer directs the intersection X itself. -/
def branch_5Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], police [1]]

/-- `branch_6` (not_applicable): as forbid, but an operating traffic signal governs c (exception b). -/
def branch_6Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], signalOn [10] false]

/-- `branch_7` (not_applicable): as forbid, but an operating traffic signal governs X. -/
def branch_7Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], signalOn [1] false]

/-- `branch_8` (violated): as forbid, with an inoperative (dark) signal on c: the exception does not hold. -/
def branch_8Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], signalOn [10] true]

/-- `branch_9` (violated): as forbid, with a yield sign on c in place of the stop sign. -/
def branch_9Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [yieldOn 51 [10]]

/-- `branch_10` (compliant): as forbid, but a stop sign also governs c2, so h2 is no through highway. -/
def branch_10Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], stopOn 52 [11]]

/-- `branch_11` (compliant): as forbid, but a yield sign governs c2, so h2 is no through highway. -/
def branch_11Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], yieldOn 52 [11]]

/-- `branch_12` (compliant): v entered X from c2 and halted inside it, clear of the subject's path. -/
def branch_12Trace : Trace := mkTrace subjStop (fun k => [vHalted k]) [stopOn 50 [10]]

/-- `branch_13` (compliant): a stop sign governs X only; v on c4 of the subject's own highway h1 is in
    conflict, but h1 carries c and is no through highway. -/
def branch_13Trace : Trace := mkTrace subjStop (fun k => [vFromNorth k]) [stopOn 50 [1]]

/-- `branch_14` (compliant): a yield sign governs X only; the subject crosses alone. -/
def branch_14Trace : Trace := mkTrace subjStop (fun _ => []) [yieldOn 51 [1]]

/-- `branch_15` (violated): a stop sign governs X only (no sign on c); v enters X from c2 of the
    through highway h2 in conflict with the moving subject. -/
def branch_15Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [1]]

/-- `branch_16` (violated): as forbid, with a police officer directing only another approach (c4):
    no officer controls c or X. -/
def branch_16Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], police [12]]

/-- `branch_17` (violated): as forbid, with an operating signal governing only another approach (c4). -/
def branch_17Trace : Trace := mkTrace subjStop (fun k => [vForbid k]) [stopOn 50 [10], signalOn [12] false]

/-- `branch_18` (compliant): the subject enters X through two overlapping carriers, c (on h1 and h2)
    and c' (on h1); a stop sign governs X; a police officer directs c' only. Through c the duty is
    engaged and h2 is no through highway for it (c lies on h2); through c' the officer's control
    lifts the duty. v from c2 is in conflict, but no engaged carrier makes it protected. -/
def branch_18Trace : Trace :=
  mkTraceS structuresTwo subjStop (fun k => [vForbid k]) [stopOn 50 [1], police [14]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .compliant
  , witness "branch_15" branch_15Trace .violated
  , witness "branch_16" branch_16Trace .violated
  , witness "branch_17" branch_17Trace .violated
  , witness "branch_18" branch_18Trace .compliant ]

end TrafficSpecWitness.NRS_484B_257_1_o2

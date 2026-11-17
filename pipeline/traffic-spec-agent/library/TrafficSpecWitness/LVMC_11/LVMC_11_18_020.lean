/-
  Witnesses for LVMC_11_18_020.

  Geometry (the witness's own figures, nowhere in the rule): a north–south highway (region 10,
  x ∈ [-8, 8] m, y ∈ [-50, 50] m). South of the junction, two lanes: region 11 (the subject's
  approach carrier, heading north, entering intersection 13) and region 12 (the other half,
  heading south). Normally lane 11 is x ∈ [0, 4] and lane 12 x ∈ [-4, 0], with a centre line
  (region 15, x ∈ [-0.1, 0.1], y ∈ [-50, 0]) between; branch_3 swaps the halves (subject on the
  left of the centre line); branch_2 replaces the centre line by a one-way roadway (region 16,
  x ∈ [-8, 8], y ∈ [-50, 0]). A crosswalk (region 14, y ∈ [0, 4]) marks lane 11's entrance; the
  intersection (13) is y ∈ [4, 20]. A school_crossing zone sign (device 20) governs lane 11
  (lane 12 in `idle`; unobserved in `blind`).
  Subject (track 1): a motor vehicle, half-length 2.5 m, half-width 1 m, heading north at
  y = -9, -4, 1 (it enters the crosswalk at the last instant). Person (track 2): in the crosswalk
  at y = 2, 1 m to the subject's right (forbid) or 5 m to its left, beyond the centre line
  (branch_1). Instants 1 s apart.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_18_020
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_18_020

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- The static map. `subjLeft` puts the subject's lane west of the centre line; `oneWay` replaces
    the centre line by a one-way roadway. -/
def structures (subjLeft : Bool) (oneWay : Bool) : List Structure :=
  let (nb0, nb1, sb0, sb1) :=
    if subjLeft then (m (-4), m 0, m 0, m 4) else (m 0, m 4, m (-4), m 0)
  let base : List Structure :=
    [ Build.rect 10 .highway (m (-8)) (m (-50)) (m 8) (m 50)
    , { Build.lane 11 (box nb0 (m (-50)) nb1 (m 0)) Build.north (enters := some 13) with ways := some [10] }
    , { Build.lane 12 (box sb0 (m (-50)) sb1 (m 0)) Build.south with ways := some [10] }
    , { Build.rect 13 .intersection (m (-8)) (m 4) (m 8) (m 20) with ways := some [10] }
    , { Build.rect 14 .crosswalk (m (-8)) (m 0) (m 8) (m 4) with
          ways := some [10], entranceOf := [11], entranceObserved := true, marked := some true } ]
  if oneWay then
    base ++ [ { Build.rect 16 .oneWayRoadway (m (-8)) (m (-50)) (m 8) (m 0) with ways := some [10] } ]
  else
    base ++ [ { Build.rect 15 .centreLine (cm (-10)) (m (-50)) (cm 10) (m 0) with ways := some [10] } ]

def subjectAt (x y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.north speed (cm 250, m 1, cm 75)

def personAt (cls : RoadUserClass) (x y : Q) : RoadUser :=
  Build.user 2 [cls] (x, y) Build.west Q.zero (cm 30, cm 30, cm 90)

/-- Occupancy by footprint (the bodies span several regions): the subject is on the highway and in
    lane 11 throughout (and on the one-way roadway where there is one), and in the crosswalk once
    it has entered it; the person, where present in the crosswalk, is on the highway and in it. -/
def occupancy (subjInCrosswalk personInCrosswalk oneWay : Bool) : List (TrackId × RegionId) :=
  [(1, 10), (1, 11)] ++ (if oneWay then [(1, 16)] else []) ++
    (if subjInCrosswalk then [(1, 14)] else []) ++
    (if personInCrosswalk then [(2, 10), (2, 14)] else [])

/-- The subject drives into the crosswalk at the third instant, the person standing in it. -/
def drivesIn (cls : RoadUserClass) (subjX personX : Q) (subjLeft oneWay : Bool) (sign : Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y := if k == 0 then m (-9) else if k == 1 then m (-4) else m 1
    Build.scene t (some 1)
      [ subjectAt subjX y (m 5), personAt cls personX (m 2) ]
      (structures subjLeft oneWay)
      [ sign ]
      (occupies := some (occupancy (k == 2) true oneWay))

def schoolSign : Device := Build.zoneSign 20 [11] .schoolCrossing false

/-- `forbid` (violated): A school_crossing sign governs the subject's lane; a child walks in the crosswalk on the subject's half of the roadway; the subject drives into the crosswalk. -/
def forbidTrace : Trace := drivesIn .pedestrian (m 2) (m 3) false false schoolSign

/-- `permit` (compliant): Same, but the subject halts short of the crosswalk until the child has left it. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (y, v) := if k == 0 then (m (-9), m 5) else if k == 3 then (m 1, m 5) else (m (-4), Q.zero)
    let px := if k == 3 then m 12 else m 3
    Build.scene t (some 1)
      [ subjectAt (m 2) y v, personAt .pedestrian px (m 2) ]
      (structures false false)
      [ schoolSign ]
      (occupies := some (occupancy (k == 3) (k != 3) false))

/-- `idle` (not_applicable): No school_crossing sign governs the subject's lane; a pedestrian is in the crosswalk. -/
def idleTrace : Trace :=
  drivesIn .pedestrian (m 2) (m 3) false false (Build.zoneSign 20 [12] .schoolCrossing false)

/-- `blind` (unknown): The sign is present but the source does not observe which carriers it governs; the subject drives into an occupied crosswalk. -/
def blindTrace : Trace :=
  drivesIn .pedestrian (m 2) (m 3) false false
    { Build.zoneSign 20 [] .schoolCrossing false with governsObserved := false }

/-- `branch_1` (not_applicable): The pedestrian is in the crosswalk on the far side of the centre line when the subject drives in. -/
def branch_1Trace : Trace := drivesIn .pedestrian (m 2) (m (-3)) false false schoolSign

/-- `branch_2` (violated): on a one-way roadway the whole crosswalk is the subject's side; a
    pedestrian 7 m to its left is in it when it drives in. -/
def branch_2Trace : Trace := drivesIn .pedestrian (m 2) (m (-5)) false true schoolSign

/-- `branch_3` (violated): the subject's lane lies left of the centre line (L < 0); a pedestrian
    1 m to its left, on its side of the line, is in the crosswalk when it drives in. -/
def branch_3Trace : Trace := drivesIn .pedestrian (m (-2)) (m (-3)) true false schoolSign

/-- `branch_4` (violated): as forbid, the person in the crosswalk riding a bicycle. -/
def branch_4Trace : Trace := drivesIn .bicycle (m 2) (m 3) false false schoolSign

/-- `branch_5` (violated): as forbid, the person riding an electric bicycle. -/
def branch_5Trace : Trace := drivesIn .electricBicycle (m 2) (m 3) false false schoolSign

/-- `branch_6` (violated): as forbid, the person riding an electric scooter. -/
def branch_6Trace : Trace := drivesIn .electricScooter (m 2) (m 3) false false schoolSign

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_18_020"
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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.LVMC_11_18_020

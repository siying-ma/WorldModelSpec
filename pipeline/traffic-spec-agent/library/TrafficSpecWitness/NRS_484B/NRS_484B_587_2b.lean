/-
  Witnesses for NRS_484B_587_2b.

  Geometry (the witness's own figures; none appears in the rule). An east-bound carriageway along
  x ∈ [0, 200] m; looking east, left is north (+y):
  (ordinals 1, 2, 3 from the left, three lanes in the direction)
    lane 14 "through2"  y ∈ [4, 8]   (leftmost; left edge solid yellow)
    lane 11 "through"   y ∈ [0, 4]
    lane 12 "ramp"      y ∈ [-4, 0]  (an entrance or exit lane: regulatory sign 31 coded entrance or
                                      exit governs it; right edge solid white)
    shoulder 13         y ∈ [-7, -4] (paved, lies on highway 21; regulatory sign 32 coded
                                      shoulder_use_permitted, unrestricted legend, governs it)
    highway 21          y ∈ [-10, 10]
    controlled-access 20 y ∈ [-7, 8] (absent on the surface street of `idle`)
  The marking between ramp and through (ramp's left, through's right) and between through and
  through2 (through's left, through2's right) are set per case, white.
  The subject (track 1) runs east at 22 m/s (far above the 0.1 m/s halt tolerance), at x = 20, 42,
  64 m at t = 0, 1, 2 s. Occupancy is stated: at t = 0 it is in its starting lane only, at t = 1 its
  footprint first reaches the neighbouring lane (both occupied), at t = 2 it is in the new lane (on
  the shoulder cases it stays across shoulder and ramp throughout, and reaches the through lane at
  t = 1). Hazard lamps are observed off and warning lamps observed none unless stated.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def throughId : RegionId := 11
def rampId : RegionId := 12
def shoulderId : RegionId := 13
def through2Id : RegionId := 14
def caId : RegionId := 20
def hwId : RegionId := 21

/-- A strip of the carriageway between two lateral offsets. -/
def box (y0 y1 : Int) : List Vec := [(m 0, m y0), (m 200, m y0), (m 200, m y1), (m 0, m y1)]

def withMarkings (s : Structure) (l r : Option (MarkingType × MarkingColour)) : Structure :=
  { s with lane := s.lane.map fun li => { li with markingLeft := l, markingRight := r } }

/-- One case of the shared scene. -/
structure Case where
  classes : List RoadUserClass := [.motorVehicle]
  official : Option OfficialKind := none
  emergency : Option EmergencyKind := none
  hazard : Bool := false
  lamps : List WarningLamp := []
  between : MarkingType := .solid      -- between ramp and through
  between2 : MarkingType := .broken    -- between through and through2
  rampCode : SignCode := .entrance
  throughCode : Option SignCode := none   -- a sign 33 governing the through lane, when present
  controlledAccess : Bool := true
  path : Nat → List RegionId
  lateral : Nat → Q

def rampToThrough : Nat → List RegionId
  | 0 => [rampId] | 1 => [rampId, throughId] | _ => [throughId]
def rampToThroughY : Nat → Q
  | 0 => m (-2) | 1 => m 0 | _ => m 2
def throughToRamp : Nat → List RegionId
  | 0 => [throughId] | 1 => [throughId, rampId] | _ => [rampId]
def throughToRampY : Nat → Q
  | 0 => m 2 | 1 => m 0 | _ => m (-2)
def throughToThrough2 : Nat → List RegionId
  | 0 => [throughId] | 1 => [throughId, through2Id] | _ => [through2Id]
def throughToThrough2Y : Nat → Q
  | 0 => m 2 | 1 => m 4 | _ => m 6
/-- Across shoulder and ramp, reaching the through lane at t = 1 and staying across all three. -/
def shoulderRampToThrough : Nat → List RegionId
  | 0 => [shoulderId, rampId] | _ => [shoulderId, rampId, throughId]
def shoulderRampToThroughY : Nat → Q
  | 0 => m (-4) | _ => m (-2)

def structuresOf (c : Case) : List Structure :=
  let t2 := withMarkings (Build.lane through2Id (box 4 8) Build.east none (some throughId) (some 1) (some 3))
    (some (.solid, .yellow)) (some (c.between2, .white))
  let t := withMarkings (Build.lane throughId (box 0 4) Build.east (some through2Id) (some rampId) (some 2) (some 3))
    (some (c.between2, .white)) (some (c.between, .white))
  let r := withMarkings (Build.lane rampId (box (-4) 0) Build.east (some throughId) none (some 3) (some 3))
    (some (c.between, .white)) (some (.solid, .white))
  let sh := { Build.rect shoulderId .shoulder (m 0) (m (-7)) (m 200) (m (-4)) with
              paved := some true, ways := some [hwId] }
  let hw := Build.rect hwId .highway (m 0) (m (-10)) (m 200) (m 10)
  let ca := Build.rect caId .controlledAccess (m 0) (m (-7)) (m 200) (m 8)
  [t2, t, r, sh, hw] ++ (if c.controlledAccess then [ca] else [])

def devicesOf (c : Case) : List Device :=
  [ { Build.sign 31 .regulatorySign [rampId] with code := some c.rampCode, conditions := some {} }
  , { Build.sign 32 .regulatorySign [shoulderId] with
      code := some .shoulderUsePermitted, conditions := some {} } ] ++
  (match c.throughCode with
   | some k => [{ Build.sign 33 .regulatorySign [throughId] with code := some k, conditions := some {} }]
   | none => [])

def subjectAt (c : Case) (k : Nat) : RoadUser :=
  let base := Build.user 1 c.classes (m (20 + 22 * Int.ofNat k), c.lateral k) Build.east
    (Units.metresPerSecond 22) (cm 230, cm 95, cm 75)
  Build.withSignals { base with officialKind := c.official, emergencyKind := c.emergency }
    (fun s => { s with hazard := some c.hazard, warningLamps := some c.lamps })

def traceOf (c : Case) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let regs := c.path k ++ [hwId] ++ (if c.controlledAccess then [caId] else [])
    Build.scene t (some 1) [subjectAt c k] (structuresOf c) (devicesOf c)
      (some (regs.map fun r => (1, r)))

def redFlashing : WarningLamp := { colour := .red, mode := .flashing, facing := .front }

/-- `forbid` (violated): On a controlled-access highway, the subject car in an entrance lane (governed by an entrance-coded sign) moves at 22 m/s and its footprint first reaches into the adjacent through lane across a solid white marking on that side. -/
def forbidTrace : Trace :=
  traceOf { path := rampToThrough, lateral := rampToThroughY }

/-- `permit` (compliant): The subject car in the entrance lane merges into the through lane where the marking between them on that side is broken white. -/
def permitTrace : Trace :=
  traceOf { between := .broken, path := rampToThrough, lateral := rampToThroughY }

/-- `idle` (not_applicable): The subject car changes lanes across a solid white line on a surface street; it never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  traceOf { controlledAccess := false, path := rampToThrough, lateral := rampToThroughY }

/-- `blind` (unknown): The subject car moves from the entrance lane into the through lane on a controlled-access highway; the source does not observe lane markings. -/
def blindTrace : Trace :=
  traceOf { path := rampToThrough, lateral := rampToThroughY }

/-- `branch_1` (not_applicable): An emergency vehicle with lit warning lamps crosses the solid white line from the through lane into an exit lane. -/
def branch_1Trace : Trace :=
  traceOf { classes := [.emergencyVehicle, .motorVehicle], emergency := some .police,
            lamps := [redFlashing], rampCode := .exit,
            path := throughToRamp, lateral := throughToRampY }

/-- `branch_2` (compliant): The subject car crosses a solid white line between two through lanes, neither governed by an entrance or exit sign. -/
def branch_2Trace : Trace :=
  traceOf { between := .broken, between2 := .solid,
            path := throughToThrough2, lateral := throughToThrough2Y }

/-- `branch_3` (not_applicable): On a controlled-access highway, a public transit bus (no hazard or warning lamps) on a paved shoulder lying on the highway and governed by a shoulder_use_permitted sign with an unrestricted legend reaches from the entrance lane across a solid white line into the through lane. -/
def branch_3Trace : Trace :=
  traceOf { classes := [.bus, .transitBus, .motorVehicle],
            path := shoulderRampToThrough, lateral := shoulderRampToThroughY }

/-- `branch_4` (violated): The scene of branch_3 with an ordinary car, of no listed class, in place of the transit bus: it reaches across the same solid white line from the shoulder-side entrance lane into the through lane. -/
def branch_4Trace : Trace :=
  traceOf { path := shoulderRampToThrough, lateral := shoulderRampToThroughY }

/-- `branch_5` (not_applicable): The scene of branch_3 with a tow vehicle (an official vehicle of kind tow, a motor vehicle) in place of the transit bus. -/
def branch_5Trace : Trace :=
  traceOf { classes := [.officialVehicle, .motorVehicle], official := some .tow,
            path := shoulderRampToThrough, lateral := shoulderRampToThroughY }

/-- `branch_6` (not_applicable): The scene of branch_3 with an emergency vehicle showing no warning lamp and no hazard lamps in place of the transit bus. -/
def branch_6Trace : Trace :=
  traceOf { classes := [.emergencyVehicle, .motorVehicle], emergency := some .police,
            path := shoulderRampToThrough, lateral := shoulderRampToThroughY }

/-- `branch_7` (not_applicable): The scene of branch_3 with a traffic incident management vehicle (an official vehicle of kind incident_management) in place of the transit bus. -/
def branch_7Trace : Trace :=
  traceOf { classes := [.officialVehicle, .motorVehicle], official := some .incidentManagement,
            path := shoulderRampToThrough, lateral := shoulderRampToThroughY }

/-- `branch_8` (violated): An ordinary car crosses the solid white line from the through lane into an exit lane (exit-coded sign) on a controlled-access highway. -/
def branch_8Trace : Trace :=
  traceOf { rampCode := .exit, path := throughToRamp, lateral := throughToRampY }

/-- `branch_9` (not_applicable): The scene of forbid with the car's hazard lamps flashing. -/
def branch_9Trace : Trace :=
  traceOf { hazard := true, path := rampToThrough, lateral := rampToThroughY }

/-- `branch_10` (compliant): The scene of forbid with the through lane also governed by an entrance-coded sign (sign 33): the solid white line separates two entrance lanes, not an entrance lane from a marked traffic lane. -/
def branch_10Trace : Trace :=
  traceOf { throughCode := some .entrance, path := rampToThrough, lateral := rampToThroughY }

/-- `branch_11` (compliant): The scene of branch_8 with the through lane also governed by an exit-coded sign (sign 33): the car crosses the solid white line between two exit lanes. -/
def branch_11Trace : Trace :=
  traceOf { rampCode := .exit, throughCode := some .exit, path := throughToRamp, lateral := throughToRampY }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_587_2b"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_marking"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant ]

end TrafficSpecWitness.NRS_484B_587_2b

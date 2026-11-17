/-
  Witnesses for NRS_484B_587_2b.

  Geometry (every figure is the witness's own and appears nowhere in the rule). An eastbound
  carriageway from x = -100 m to x = 300 m: lane 10 (ordinal 1 of 2, y 3.5..7 m) on the left, lane 11
  (ordinal 2 of 2, y 0..3.5 m) on the right; lane 10's left edge is solid yellow, lane 11's right
  edge solid white, and the line between them (lane 11's left, lane 10's right) is what each scene
  varies. Region 2 is the controlled-access region over y 0..7 m (absent on the surface street of
  `idle`, where region 1 is a plain highway). Lane 11 is the entrance lane (a regulatory sign of code
  entrance governs it) or the exit lane (code exit), or, in `branch_2`, an ordinary lane.

  The subject (track 1) is a car of half-extent 2 m × 0.9 m at 22 m/s (far above the halt
  tolerance), observed at t = 0, 1, 2 s at x = 0, 22, 44 m. A move to the left puts its centre at
  y = 1.75, 3.5, 5.25 m: its footprint (y ± 0.9 m) lies in lane 11 alone, then across the line in both
  lanes, then in lane 10 alone; a move to the right is the mirror. The occupancy listed per scene is
  the footprint's overlap with each region's boundary.

  `branch_3` is the shoulder exception: a paved shoulder (region 3, y -3..0 m) lies on highway
  region 1 (y -4..6.5 m) and is governed by a shoulder_use_permitted sign with an unrestricted
  legend; the entrance lane 11 tapers to 2 m (y 0..2 m) and lane 10 spans y 2..5.5 m. An incident
  management vehicle of half-extent 3 m × 1.25 m at 8 m/s, centre y = 0.5 m then 1.0 m, has its
  footprint on the shoulder and lane 11, then on the shoulder, lane 11 and lane 10.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def xWest : Q := m (-100)
def xEast : Q := m 300

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def solidWhite : Option (MarkingType × MarkingColour) := some (.solid, .white)
def brokenWhite : Option (MarkingType × MarkingColour) := some (.broken, .white)
def solidYellow : Option (MarkingType × MarkingColour) := some (.solid, .yellow)

/-- An eastbound lane of a two-lane carriageway with its markings per side. -/
def laneAt (id : RegionId) (y0 y1 : Q) (left right : Option RegionId) (ord : Nat)
    (ml mr : Option (MarkingType × MarkingColour)) : Structure :=
  let st := Build.lane id (box xWest y0 xEast y1) Build.east left right (some ord) (some 2)
  { st with lane := st.lane.map fun li => { li with markingLeft := ml, markingRight := mr } }

/-- A regulatory sign of a code with an unrestricted legend. -/
def regSign (id : DeviceId) (governs : List RegionId) (c : SignCode) : Device :=
  { Build.sign id .regulatorySign governs with code := some c, conditions := some {} }

/-- The controlled-access region over the carriageway. -/
def caRegion : Structure := Build.rect 2 .controlledAccess xWest (m 0) xEast (m 7)

/-- The carriageway with the line between lanes 10 and 11 as given (as seen from each side). -/
def lanes (between : Option (MarkingType × MarkingColour)) : List Structure :=
  [ laneAt 10 (cm 350) (m 7) none (some 11) 1 solidYellow between
  , laneAt 11 (m 0) (cm 350) (some 10) none 2 between solidWhite ]

/-- A road user with its hazard lamps off and no warning lamp lit. -/
def quiet (u : RoadUser) : RoadUser :=
  Build.withSignals u fun s => { s with hazard := some false, warningLamps := some [] }

/-- The subject car at (x, y), eastbound at 22 m/s. -/
def car (x y : Q) : RoadUser :=
  quiet (Build.user 1 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 22) (m 2, cm 90, cm 75))

/-- Centre ordinates of a move from lane 11 into lane 10, and back. -/
def toLeft : List Q := [cm 175, cm 350, cm 525]
def toRight : List Q := [cm 525, cm 350, cm 175]

/-- A three-observation lane change at 22 m/s; `occ k` lists the regions the footprint overlaps. -/
def laneChange (structures : List Structure) (devices : List Device) (u : Q → Q → RoadUser)
    (ys : List Q) (occ : List (List RegionId)) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [u (m (22 * (k : Int))) (ys.getD k Q.zero)] structures devices
      (some ((occ.getD k []).map fun r => (1, r)))

/-- Occupancy of a move 11 → 10 on the controlled-access carriageway, and 10 → 11. -/
def occLeftCA : List (List RegionId) := [[2, 11], [2, 11, 10], [2, 10]]
def occRightCA : List (List RegionId) := [[2, 10], [2, 10, 11], [2, 11]]

/-- `forbid` (violated): On a controlled-access highway, the subject car in an entrance lane (governed by an entrance-coded sign) moves at 22 m/s and its footprint first reaches into the adjacent through lane across a solid white marking on that side. -/
def forbidTrace : Trace :=
  laneChange (caRegion :: lanes solidWhite) [regSign 1 [11] .entrance] car toLeft occLeftCA

/-- `permit` (compliant): The subject car in the entrance lane merges into the through lane where the marking between them on that side is broken white. -/
def permitTrace : Trace :=
  laneChange (caRegion :: lanes brokenWhite) [regSign 1 [11] .entrance] car toLeft occLeftCA

/-- `idle` (not_applicable): The subject car changes lanes across a solid white line on a surface street; it never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  laneChange (Build.rect 1 .highway xWest (m (-2)) xEast (m 9) :: lanes solidWhite) []
    car toLeft [[1, 11], [1, 11, 10], [1, 10]]

/-- A lane whose markings the source does not record. -/
def blindLane (id : RegionId) (y0 y1 : Q) (left right : Option RegionId) (ord : Nat) : Structure :=
  laneAt id y0 y1 left right ord none none

/-- `blind` (unknown): The subject car moves from the entrance lane into the through lane on a controlled-access highway; the source does not observe lane markings. -/
def blindTrace : Trace :=
  laneChange [caRegion, blindLane 10 (cm 350) (m 7) none (some 11) 1, blindLane 11 (m 0) (cm 350) (some 10) none 2]
    [regSign 1 [11] .entrance] car toLeft occLeftCA

/-- An emergency vehicle at (x, y), eastbound at 22 m/s, its red warning lamps flashing. -/
def emergency (x y : Q) : RoadUser :=
  let u := Build.user 1 [.emergencyVehicle, .motorVehicle] (x, y) Build.east (Units.metresPerSecond 22) (m 2, cm 90, cm 75)
  Build.withSignals { u with emergencyKind := some .fire } fun s =>
    { s with hazard := some false
             warningLamps := some [ { colour := .red, mode := .flashing, facing := .front } ] }

/-- `branch_1` (not_applicable): An emergency vehicle with lit warning lamps crosses the solid white line from the through lane into an exit lane. -/
def branch_1Trace : Trace :=
  laneChange (caRegion :: lanes solidWhite) [regSign 1 [11] .exit] emergency toRight occRightCA

/-- `branch_2` (compliant): The subject car crosses a solid white line between two through lanes, neither governed by an entrance or exit sign. -/
def branch_2Trace : Trace :=
  laneChange (caRegion :: lanes solidWhite) [] car toLeft occLeftCA

/-- `branch_3` (not_applicable): An incident management vehicle on a paved shoulder signed for its
    use, at the taper of the entrance lane, reaches across the solid white line into the through lane. -/
def branch_3Trace : Trace :=
  let structures : List Structure :=
    [ Build.rect 1 .highway xWest (m (-4)) xEast (cm 650)
    , Build.rect 2 .controlledAccess xWest (m (-3)) xEast (cm 550)
    , { Build.rect 3 .shoulder xWest (m (-3)) xEast (m 0) with paved := some true, ways := some [1] }
    , laneAt 10 (m 2) (cm 550) none (some 11) 1 solidYellow solidWhite
    , laneAt 11 (m 0) (m 2) (some 10) none 2 solidWhite solidWhite ]
  let devices := [regSign 1 [11] .entrance, regSign 2 [3] .shoulderUsePermitted]
  let ys : List Q := [cm 50, m 1]
  let occ : List (List RegionId) := [[1, 2, 3, 11], [1, 2, 3, 11, 10]]
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let u := Build.user 1 [.officialVehicle, .motorVehicle] (m (8 * (k : Int)), ys.getD k Q.zero)
      Build.east (Units.metresPerSecond 8) (m 3, cm 125, cm 150)
    Build.scene t (some 1) [quiet { u with officialKind := some .incidentManagement }] structures devices
      (some ((occ.getD k []).map fun r => (1, r)))

/-- `branch_4` (violated): The subject car crosses the solid white line from the through lane into an exit lane. -/
def branch_4Trace : Trace :=
  laneChange (caRegion :: lanes solidWhite) [regSign 1 [11] .exit] car toRight occRightCA

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
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_587_2b

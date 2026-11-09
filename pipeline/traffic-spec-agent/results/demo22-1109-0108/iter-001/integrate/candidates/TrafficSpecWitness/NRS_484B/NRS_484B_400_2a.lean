/-
  Witnesses for NRS_484B_400_2a.

  The geometry (every figure here is the witness's own and appears nowhere in the rule).

  The world frame is +x east, +y north, and traffic keeps right, so an east-bound carrier lies south
  of the centre of its way and a west-bound one north of it.

  The laned street (`lanedStreet`, used by `forbid`, `permit`, `blind` and `idle`): an east–west
  highway (region 10) 14.4 m wide between y = -7.2 and y = 7.2, meeting a north–south highway
  (region 20) 7.2 m wide at the intersection (region 30, x in [-3.6, 3.6]), which lies on both ways.
  Four lanes 3.6 m wide, two each way: the east-bound approach segments 101 (ordinal 1, beside the
  centre of the way) and 102 (ordinal 2, kerbside) run from x = -60 to the junction and enter it; the
  west-bound segments 111 (ordinal 1) and 112 (ordinal 2) run from the junction's east side and enter
  it too; the crossing street's north-bound 201 and south-bound 202 likewise. No divider lies on
  either way, and each carries carriers of opposed designated direction, so both are two-directional.

  The divided street (`dividedStreet`, `branch_2`): the same east-bound lanes, with a raised median
  (region 40, 0.2 m wide) on way 10 between the two directions, so way 10 is not two-directional.

  The street whose crossing way is divided (`crossDividedStreet`, `branch_4`): way 10 as in
  `lanedStreet`, and a median (region 41) on way 20, so the other intersecting highway is not
  two-directional.

  The unlaned streets (`narrowStreet`, `branch_1`; `wideStreet`, `branch_3`): no lane is recorded.
  Each direction of way 10 is one roadway approach segment (103 east-bound, which enters the
  junction, and 104 west-bound), a centre line (region 50, a 0.2 m strip on the centre of the
  roadway) divides them, and the crossing way carries two roadway segments (203, 204). In
  `narrowStreet` the east-bound roadway runs from y = -4 to y = 0, in `wideStreet` from y = -7 to
  y = 0.

  The body: track 1, a motor vehicle 4.8 m by 1.8 m, east-bound at 10 m/s, at x = -40, -30 and -20 at
  t = 0, 1 and 2 s, so it never reaches the junction. Its lateral place is the witness's variable:
  y = -5.4 (kerbside lane 102), y = -1.8 (lane 101 beside the centre of the way), y = -2 (1.9 m from
  the near edge of the centre line, inside the centre-line portion) and y = -6 (5.9 m from it,
  outside). The source declares the plan for it at region 30 to be a left turn in every scenario but
  `idle`, where it declares it not to be.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- A rectangular region of a kind, lying on the given ways. -/
def area (id : RegionId) (kind : StructureKind) (x0 y0 x1 y1 : Q) (ways : List RegionId) : Structure :=
  let st := Build.rect id kind x0 y0 x1 y1
  { st with ways := some ways }

/-- A public way: a highway region, on no way of its own. -/
def way (id : RegionId) (x0 y0 x1 y1 : Q) : Structure := Build.rect id .highway x0 y0 x1 y1

/-- A lane of a way: a directed approach segment with its place among the lanes of its direction. -/
def laneSeg (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) (left right : Option RegionId)
    (ordinal count : Nat) (enters : Option RegionId) (onWay : RegionId) : Structure :=
  let st := Build.lane id [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] dir left right
              (some ordinal) (some count) none enters
  { st with ways := some [onWay] }

/-- One direction of an unlaned roadway: a directed approach segment with no lane recorded on it. -/
def roadSeg (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) (enters : Option RegionId)
    (onWay : RegionId) : Structure :=
  let st := Build.rect id .roadway x0 y0 x1 y1
  { st with lane := some { direction := some dir, entersIntersection := enters }
            ways := some [onWay] }

/-- The source's current plan for track 1 at region `r`. -/
def leftTurnAt (r : RegionId) (yes : Bool) : List DeclaredIntent :=
  [{ vehicle := 1, target := r, values := [("int.left_turn", yes)] }]

/-- The subject at its lateral place `y`, 10 m further east at each instant. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-40 + 10 * (k : Int)), y) Build.east (mps 10)
    (cm 240, cm 90, cm 75)

-- ---------------------------------------------------------------------------------------------
-- The maps
-- ---------------------------------------------------------------------------------------------

/-- Two undivided two-way streets, four lanes on the east–west one. -/
def lanedStreet : List Structure :=
  [ way 10 (m (-60)) (cm (-720)) (m 60) (cm 720)
  , way 20 (cm (-360)) (m (-60)) (cm 360) (m 60)
  , area 30 .intersection (cm (-360)) (cm (-720)) (cm 360) (cm 720) [10, 20]
  , laneSeg 101 (m (-60)) (cm (-360)) (cm (-360)) (m 0) Build.east none (some 102) 1 2 (some 30) 10
  , laneSeg 102 (m (-60)) (cm (-720)) (cm (-360)) (cm (-360)) Build.east (some 101) none 2 2 (some 30) 10
  , laneSeg 111 (cm 360) (m 0) (m 60) (cm 360) Build.west none (some 112) 1 2 (some 30) 10
  , laneSeg 112 (cm 360) (cm 360) (m 60) (cm 720) Build.west (some 111) none 2 2 (some 30) 10
  , laneSeg 201 (m 0) (m (-60)) (cm 360) (cm (-720)) Build.north none none 1 1 (some 30) 20
  , laneSeg 202 (cm (-360)) (cm 720) (m 0) (m 60) Build.south none none 1 1 (some 30) 20 ]

/-- The east–west way divided by a raised median between its two directions. -/
def dividedStreet : List Structure :=
  [ way 10 (m (-60)) (cm (-720)) (m 60) (cm 740)
  , way 20 (cm (-360)) (m (-60)) (cm 360) (m 60)
  , area 30 .intersection (cm (-360)) (cm (-720)) (cm 360) (cm 740) [10, 20]
  , laneSeg 101 (m (-60)) (cm (-360)) (cm (-360)) (m 0) Build.east none (some 102) 1 2 (some 30) 10
  , laneSeg 102 (m (-60)) (cm (-720)) (cm (-360)) (cm (-360)) Build.east (some 101) none 2 2 (some 30) 10
  , area 40 .medianOrDivider (m (-60)) (m 0) (cm (-360)) (cm 20) [10]
  , laneSeg 111 (m (-60)) (cm 20) (cm (-360)) (cm 380) Build.west none (some 112) 1 2 none 10
  , laneSeg 112 (m (-60)) (cm 380) (cm (-360)) (cm 740) Build.west (some 111) none 2 2 none 10
  , laneSeg 201 (m 0) (m (-60)) (cm 360) (cm (-720)) Build.north none none 1 1 (some 30) 20
  , laneSeg 202 (cm (-360)) (cm 740) (m 0) (m 60) Build.south none none 1 1 (some 30) 20 ]

/-- The other intersecting highway divided by a raised median. -/
def crossDividedStreet : List Structure :=
  [ way 10 (m (-60)) (cm (-720)) (m 60) (cm 720)
  , way 20 (cm (-380)) (m (-60)) (cm 380) (m 60)
  , area 30 .intersection (cm (-380)) (cm (-720)) (cm 380) (cm 720) [10, 20]
  , laneSeg 101 (m (-60)) (cm (-360)) (cm (-380)) (m 0) Build.east none (some 102) 1 2 (some 30) 10
  , laneSeg 102 (m (-60)) (cm (-720)) (cm (-380)) (cm (-360)) Build.east (some 101) none 2 2 (some 30) 10
  , laneSeg 111 (cm 380) (m 0) (m 60) (cm 360) Build.west none (some 112) 1 2 (some 30) 10
  , laneSeg 112 (cm 380) (cm 360) (m 60) (cm 720) Build.west (some 111) none 2 2 (some 30) 10
  , laneSeg 201 (cm 20) (m (-60)) (cm 380) (cm (-720)) Build.north none none 1 1 (some 30) 20
  , area 41 .medianOrDivider (cm (-20)) (m (-60)) (cm 20) (cm (-720)) [20]
  , laneSeg 202 (cm (-380)) (cm 720) (cm (-20)) (m 60) Build.south none none 1 1 (some 30) 20 ]

/-- A narrow undivided two-way street with no lane recorded, meeting another such street. -/
def narrowStreet : List Structure :=
  [ way 10 (m (-60)) (m (-6)) (m 60) (m 6)
  , way 20 (m (-4)) (m (-60)) (m 4) (m 60)
  , area 30 .intersection (m (-4)) (m (-6)) (m 4) (m 6) [10, 20]
  , roadSeg 103 (m (-60)) (m (-4)) (m (-4)) (m 0) Build.east (some 30) 10
  , roadSeg 104 (m (-60)) (m 0) (m (-4)) (m 4) Build.west none 10
  , area 50 .centreLine (m (-60)) (cm (-10)) (m (-4)) (cm 10) [10]
  , roadSeg 203 (m 0) (m (-60)) (m 4) (m (-6)) Build.north (some 30) 20
  , roadSeg 204 (m (-4)) (m 6) (m 0) (m 60) Build.south none 20 ]

/-- A wide undivided two-way street with no lane recorded. -/
def wideStreet : List Structure :=
  [ way 10 (m (-60)) (m (-9)) (m 60) (m 9)
  , way 20 (m (-4)) (m (-60)) (m 4) (m 60)
  , area 30 .intersection (m (-4)) (m (-9)) (m 4) (m 9) [10, 20]
  , roadSeg 103 (m (-60)) (m (-7)) (m (-4)) (m 0) Build.east (some 30) 10
  , roadSeg 104 (m (-60)) (m 0) (m (-4)) (m 7) Build.west none 10
  , area 50 .centreLine (m (-60)) (cm (-10)) (m (-4)) (cm 10) [10]
  , roadSeg 203 (m 0) (m (-60)) (m 4) (m (-9)) Build.north (some 30) 20
  , roadSeg 204 (m (-4)) (m 9) (m 0) (m 60) Build.south none 20 ]

/-- A trace of three instants: the subject at lateral place `y` on the given map, with the declared
    plan at the junction. -/
def approach (map : List Structure) (y : Q) (turningLeft : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k y] map [] (intents := leftTurnAt 30 turningLeft)

/-- `forbid` (violated): A four-lane undivided street, two lanes each way, meets another undivided two-way street. The source declares the car's plan to be a left turn at that junction, and the car runs the whole approach in the kerbside lane -- ordinal 2 of its direction -- up to the junction. -/
def forbidTrace : Trace := approach lanedStreet (cm (-540)) true

/-- `permit` (compliant): The same geometry and the same declared left turn. The car runs the approach in the lane of ordinal 1 for its direction, the one adjoining the centre line, throughout. No other road user is in the scene and the verdict is decided. -/
def permitTrace : Trace := approach lanedStreet (cm (-180)) true

/-- `idle` (not_applicable): The car approaches the same junction in the kerbside lane, but the source's current plan for it is to go straight through: no left turn is declared at that junction, so the rule is not engaged. -/
def idleTrace : Trace := approach lanedStreet (cm (-540)) false

/-- `blind` (unknown): The car approaches the junction with a declared left turn, but the source does not report the lane ordinals of the carriageway and the roadway carries a recorded lane, so which portion of the right half the car occupies is unknown. -/
def blindTrace : Trace := approach lanedStreet (cm (-180)) true

/-- `branch_1` (compliant): A narrow two-way street with no lanes recorded, meeting another undivided two-way street. The car, declared to turn left at the junction, runs the approach with the centre line two metres to its left, inside the centre-line portion. -/
def branch_1Trace : Trace := approach narrowStreet (m (-2)) true

/-- `branch_2` (not_applicable): The car, declared to turn left, approaches a junction on a highway divided by a raised median: the way is not two-directional in the definition's sense, so this paragraph does not apply. -/
def branch_2Trace : Trace := approach dividedStreet (cm (-540)) true

/-- `branch_3` (violated): An unlaned two-way street, the car declared to turn left at the junction, running the whole approach close to the kerb with the centre line six metres to its left, outside the centre-line portion. -/
def branch_3Trace : Trace := approach wideStreet (m (-6)) true

/-- `branch_4` (not_applicable): The car, declared to turn left, approaches the junction on a two-directional highway, but the other highway meeting there is divided by a raised median: both intersecting highways are not two-directional, so this paragraph does not apply. -/
def branch_4Trace : Trace := approach crossDividedStreet (cm (-540)) true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_400_2a

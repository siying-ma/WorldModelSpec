/-
  Witnesses for drv.road.on_curve.

  One rural highway carries all three scenarios. Every figure below is the witness's own, including
  the 0.001 1/m the instance gives the formal parameter `curve_curvature_tolerance`.

  The highway, two roadway regions (+x east, +y north), both the improved part of the way and both
  20 m wide (y = -10 m to y = 10 m):

    - region 21, the bend: x = -200 m to x = 200 m, the alignment through a curve of 125 m radius,
      so the mapped horizontal curvature the source carries for it is 1/125 m = 0.008 1/m;
    - region 22, the tangent 300 m further on: x = 300 m to x = 700 m, where the alignment is
      straight to the resolution of the survey, so the curvature carried for it is 1/5000 m =
      0.0002 1/m.

    Both regions stand in every scene, so the body's existential has a bending roadway to find in
    all three: what decides is which of the two the subject's footprint overlaps. The regions are
    drawn as rectangles — the bend is carried by the curvature the source maps for the region, not
    by the shape of the polygon, which is the segmentation the concept reads.

  The subject is a car, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), track 1, the formal
  `u`; it runs east at 20 m/s. Three instants 1 s apart from t = 0. Nothing in the body looks
  behind or ahead, so no padding and no window are needed.

  holds:  the car is upon the bend, at x = -20 m, 0 m and 20 m in region 21, 3 m north of the
          centre. Region 21 is a roadway, the footprint overlaps it, and its curvature 0.008 1/m
          is at or above the tolerance 0.001 1/m. The body is true at every instant.
  fails:  the same highway 300 m further on: the car is at x = 400 m, 420 m and 440 m in region
          22, steering round a lorry parked at x = 480 m, so that its own yaw rate is 3 deg/s. The
          footprint overlaps region 22 alone, whose curvature 0.0002 1/m is below the tolerance;
          the bend of region 21 is in the scene but the car is not upon it, and the car's own
          turning is no bend of the road. The body is false at every instant.
  blind:  the holds scene on a source whose manifest declares st.curvature absent. Both roadway
          regions and the car's membership of region 21 are observed, but no curvature is carried
          for any point of the alignment: the comparison is unknown for the region the car is
          upon, no binding of the quantifier is true, and the body is unknown for that atom alone.
-/
import TrafficSpec.Concepts.road.on_curve
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.on_curve

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A horizontal curvature, as the reciprocal of the radius of the arc in metres: the figure a
    mapped alignment carries for a circular curve of that radius. -/
def curvatureOfRadius (radius : Int) : Q := Q.div (Units.perMetre 1) (Units.metres radius)

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The
    curvature below which this source's alignment counts as a tangent is 0.001 1/m — the
    reciprocal of a 1000 m radius — the witness's own figure. -/
def inst : Concept.Instance :=
  { name := "drv.road.on_curve@w"
    concept := "drv.road.on_curve"
    literals := []
    nats := []
    params := [("curve_curvature_tolerance", .lit (curvatureOfRadius 1000) .perMetre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A roadway region of the highway, with the horizontal curvature the source maps for it. -/
def roadway (id : RegionId) (x0 x1 : Q) (curvature : Q) : Structure :=
  { Build.rect id .roadway x0 (m (-10)) x1 (m 10) with curvature := some curvature }

/-- The bend: a curve of 125 m radius, so 0.008 1/m. -/
def theBend : Structure := roadway 21 (m (-200)) (m 200) (curvatureOfRadius 125)

/-- The tangent 300 m further on: 0.0002 1/m, a straight road to the resolution of the survey. -/
def theTangent : Structure := roadway 22 (m 300) (m 700) (curvatureOfRadius 5000)

/-- The highway: the bend and the tangent beyond it, in every scene. -/
def highway : List Structure := [theBend, theTangent]

/-- A car of the witness: 4 m long and 2 m wide, running east. -/
def car (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed (m 2, m 1, m 1)

/-- `holds` (compliant): A two-lane rural highway bends through a curve of about 120 m radius; the mapped horizontal curvature at the point of the roadway the subject's footprint overlaps is 0.008 1/m, well above the tolerance the caller sets. The subject is upon that roadway at the observation. The concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-20 + 20 * (k : Int)), m 3) (Units.metresPerSecond 20) ]
      highway
      []

/-- `fails` (violated): The same highway 300 m further on, where the alignment is a tangent: the mapped curvature at the point of the roadway the subject's footprint overlaps is 0.0002 1/m, below the tolerance the caller sets, although the subject is steering round a parked lorry and its own yaw rate is 3 deg/s. The concept fails: the road is straight whatever the body does. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car 1 (m (400 + 20 * (k : Int)), m 3) (Units.metresPerSecond 20))
          (fun kin => { kin with yawRate := some (Units.degrees 3) })
      , car 2 (m 480, m (-3)) Q.zero ]
      highway
      []

/-- `blind` (unknown): The same bend and the same subject upon the roadway, but the source's manifest declares st.curvature absent: the roadway region and the subject's membership of it are observed, yet no curvature is carried for any point of the alignment and whether the road bends there cannot be decided. The concept is unknown. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.curvature"] ]

end TrafficSpecWitness.Concepts.road.on_curve

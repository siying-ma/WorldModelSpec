/-
  Witnesses for drv.lane.travel_with_roadway_designated_direction.

  One straight way running east and west carries the three scenarios. Every figure below is the
  witness's own, including the one the instance gives the formal parameter: an along-roadway speed
  tolerance of 1 m/s, and the literal formal filled with `one_way_roadway`.

  The way: a one-way roadway region (id 10), its boundary polygon carried, from x = -100 m to
  x = 100 m and y = -5 m to y = 5 m, designated eastbound — its carried direction of travel is the
  unit vector due east. It lies on a highway region (id 20), the wider rectangle y = -8 m … 8 m,
  which carries no designation of its own and which the body never quantifies over: the instance
  names the one-way roadway kind.

  The subject is a car, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), track 1, the formal
  `u`, with yaw rate zero at every observation. Three observations one second apart from t = 0, so
  t = 0 s, 1 s, 2 s. Occupancy is given to each scene rather than derived from the polygons, so
  that each scenario says exactly which regions the footprint overlaps: the one-way roadway and
  the highway it lies on, at every observation. Nothing of the body looks before or after the
  observation, so no padding and no window are needed.

  holds:  the car heads due east at 10 m/s — x = 0 m at t = 0 s and x = 10 m at t = 1000 ms, so its
          velocity is (10, 0) m/s. The component of that velocity along the region's designated
          direction, the inner product with the unit vector due east, is 10 m/s, above the
          instance's tolerance of 1 m/s, at each of the three observations.
  fails:  the same eastbound one-way roadway. The car heads due west at 10 m/s — x = 0 m at
          t = 0 s and x = -10 m at t = 1000 ms, so its velocity is (-10, 0) m/s. Its footprint
          still overlaps the region, but the component along the designated direction is -10 m/s,
          below the tolerance, at each of the three observations.
  blind:  the holds scene on a source whose manifest declares st.lane_direction absent. The region
          is mapped, its kind is told and the footprint's overlap of it is observed, and the car's
          velocity is observed; but the direction the region is designated for is unobserved, so
          the component along it is undecided and the concept is unknown for that atom alone.
-/
import TrafficSpec.Concepts.lane.travel_with_roadway_designated_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.travel_with_roadway_designated_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The kind of
    travel region is the one-way roadway, and the along-roadway speed tolerance is 1 m/s — the
    witness's own figure for the along-roadway speed below which this source's measured velocity
    does not stand clear of zero. -/
def inst : Concept.Instance :=
  { name := "drv.lane.travel_with_roadway_designated_direction@w"
    concept := "drv.lane.travel_with_roadway_designated_direction"
    literals := [("kind", "one_way_roadway")]
    nats := []
    params := [("along_roadway_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The way: a one-way roadway designated eastbound, on the highway it lies on
-- ---------------------------------------------------------------------------------------------
/-- The one-way roadway region: its boundary polygon carried, designated eastbound (a direction of
    unit length), lying on the highway region 20. -/
def roadway : Structure :=
  let base := Build.rect 10 .oneWayRoadway (m (-100)) (m (-5)) (m 100) (m 5)
  { base with lane := some { direction := some Build.east }, ways := some [20] }

/-- The highway the one-way roadway lies on: no designation of its own. -/
def highway : Structure := Build.rect 20 .highway (m (-100)) (m (-8)) (m 100) (m 8)

def structures : List Structure := [roadway, highway]

/-- The regions the car's footprint overlaps at every observation: the one-way roadway and the
    highway it lies on. -/
def occupies : List (TrackId × RegionId) := [(1, 10), (1, 20)]

/-- The car of the witness: at a place on the way, pointing the way it travels, at 10 m/s, with
    yaw rate zero. -/
def car (x : Q) (heading : Vec) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (x, m 0) heading (Units.metresPerSecond 10) (m 2, m 1, m 1))
    fun k => { k with yawRate := some Q.zero }

/-- The easting of the car at the observation at second `k`, travelling 10 m each second in the
    direction `sign` (+1 east, -1 west). -/
def easting (sign : Int) (k : Nat) : Q := m (sign * 10 * Int.ofNat k)

/-- `holds` (compliant): A one-way roadway region, its boundary polygon carried, lies on a highway and is designated eastbound. Track 1's footprint overlaps it; the car heads due east with yaw rate zero, at x=0 at t=0 and x=10 at t=1000 ms, its velocity 10 m/s due east. The component of its velocity along the designated direction, 10 m/s, is above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (easting 1 k) Build.east ]
      structures
      []
      (some occupies)

/-- `fails` (violated): The same eastbound one-way roadway with its boundary carried. Track 1's footprint overlaps it; the car heads due west with yaw rate zero, at x=0 at t=0 and x=-10 at t=1000 ms, its velocity 10 m/s due west. The component along the designated direction is -10 m/s, below the tolerance. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (easting (-1) k) Build.west ]
      structures
      []
      (some occupies)

/-- `blind` (unknown): The same one-way roadway with its boundary carried and the same eastbound car, on a source that maps regions and occupancy but declares the designated direction of travel absent. The direction the region is designated for is unobserved, so the concept is unknown. -/
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.lane.travel_with_roadway_designated_direction

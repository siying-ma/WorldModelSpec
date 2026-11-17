/-
  Witnesses for LVMC_11_60_030_A4.

  Geometry (the witness's own figures; none appears in the rule). A street (highway region 10,
  x ∈ [-50, 50], y ∈ [-5, 12]) carries two eastbound lanes: lane 11 (y ∈ [0, 3.5], next to the
  curb) and lane 12 (y ∈ [3.5, 7]). The curb is road edge 14, a thin strip y ∈ [-0.1, 0] along the
  south side, i.e. on the right of an eastbound vehicle. A bus-stop curb zone 13 (x ∈ [-10, 10],
  y ∈ [0, 3]) lies along it; `branch_2` replaces it by a transit stop 15 of the same outline.
  The bus (track 1, transit bus) is 12 m long and 2.5 m wide (half-extents 6, 1.25, 1.5). Three
  scenes, one second apart. Occupancy is stated (the bus body spans regions its reference point
  is not in).

    forbid   at rest, door open, heading east, centre y = 2.75: body 1.5 m from the curb.
    permit   at rest, door open, heading east, centre y = 1.45: body 0.2 m from the curb.
    idle     moving east at 5 m/s through the zone, doors closed.
    blind    as permit, the road edge mapped without its outline (st.region_geometry masked).
    branch_1 at rest, door open, heading 30° right of east (cos 30° ≈ 0.866), centre (0, 4.28):
             the front-right corner ≈ 0.2 m from the curb, the rear out across lane 12.
    branch_2 as permit, but the stop is a transit stop (no curb zone): compliant.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_60_030_A4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_60_030_A4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def street : Structure := Build.rect 10 .highway (m (-50)) (m (-5)) (m 50) (m 12)
def curbLane : Structure :=
  Build.lane 11 [(m (-50), m 0), (m 50, m 0), (m 50, cm 350), (m (-50), cm 350)] Build.east
def outerLane : Structure :=
  Build.lane 12 [(m (-50), cm 350), (m 50, cm 350), (m 50, m 7), (m (-50), m 7)] Build.east
def busZone : Structure :=
  { Build.rect 13 .curbZone (m (-10)) (m 0) (m 10) (m 3) with curbKind := some .busStop }
def curb : Structure := Build.rect 14 .roadEdge (m (-50)) (cm (-10)) (m 50) (m 0)
def transitStop : Structure := Build.rect 15 .transitStop (m (-10)) (m 0) (m 10) (m 3)

def busExtent : Q × Q × Q := (m 6, cm 125, cm 150)

/-- The transit bus at `(x, y)` with heading `h`, speed `v`, the doors listed open. -/
def bus (x y : Q) (h : Vec) (v : Q) (doors : List DoorSide) : RoadUser :=
  Build.withSignals (Build.user 1 [.bus, .transitBus] (x, y) h v busExtent)
    fun s => { s with doorsOpen := some doors }

def stoppedScene (t : Timestamp) (y : Q) (h : Vec) (structures : List Structure)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) [bus (m 0) y h Q.zero [.curb]] structures [] (some occ)

def standard : List Structure := [street, curbLane, outerLane, busZone, curb]

/-- `forbid` (violated): A transit bus comes to rest in a st.curb_zone of kind bus_stop on a street, its curb-side door open, with its body 1.5 m from the road edge on its right and its heading along the lane direction. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    stoppedScene t (cm 275) Build.east standard [(1, 10), (1, 11), (1, 13)]

/-- `permit` (compliant): A transit bus comes to rest in a st.curb_zone of kind bus_stop, door open, its body 0.2 m from the road edge on its right and its heading along the lane direction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    stoppedScene t (cm 145) Build.east standard [(1, 10), (1, 11), (1, 13)]

/-- `idle` (not_applicable): A transit bus drives through a bus-stop curb zone without halting, all doors closed. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [bus (m (5 * (k : Int) - 5)) (cm 145) Build.east (Units.metresPerSecond 5) []]
      standard [] (some [(1, 10), (1, 11), (1, 13)])

/-- `blind` (unknown): A transit bus comes to rest in a bus-stop curb zone with its door open; the source maps the road edge without its outline, so the distance from the bus's body to the curb is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    stoppedScene t (cm 145) Build.east standard [(1, 10), (1, 11), (1, 13)]

/-- `branch_1` (violated): A transit bus comes to rest in a bus-stop curb zone with its door open, its front body 0.2 m from the road edge on its right but its heading thirty degrees off the lane direction, its rear swung out into the lane. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    stoppedScene t (cm 428) (Units.ratio 866 1000, Units.ratio (-1) 2) standard
      [(1, 10), (1, 11), (1, 12), (1, 13)]

/-- `branch_2` (compliant): a transit bus at rest at a transit stop (no posted curb zone), door
    open, 0.2 m from the curb on its right, heading along the lane. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    stoppedScene t (cm 145) Build.east [street, curbLane, outerLane, transitStop, curb]
      [(1, 10), (1, 11), (1, 15)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_60_030_A4"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.LVMC_11_60_030_A4

/-
  Witnesses for LVMC_11_40_140_o1.

  Geometry (metres, +x east, +y north). A roadway (y 0–10) and a sidewalk (y 10–13) run east–west
  along x −30…30. The highway region (the public way) covers roadway and sidewalk, up to y 13, or
  up to y 15 where a strip behind the walk (the apron of a driveway) lies in the right-of-way.
  A driveway / alley entrance region (x −3…3) runs north from the walk (y 13–30), or from y 10
  where the sidewalk area extends across it. An alley (x −3…3, y 13–40, or 10–40) is itself a
  public way, mapped under its own highway region.
  The rider's body is 1.8 m long and 0.6 m wide (half-extents 0.9 / 0.3 / 0.6 m), heading along
  its motion, so the ground distance from the body to the walk is |y − 13| − 0.9 (north of the
  walk) or 10 − y − 0.9 (south of it). Instants are 1 s apart. With p.stop_point_tolerance = 2 m
  the approach observations sit at 2.6 m or more (outside the zone) and the zone observations at
  0.1–0.7 m; a moving rider goes 1–4 m/s, a halt is 0 m/s (p.halt_speed_tolerance = 0.1 m/s).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_140_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_140_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The rider's half-extents. -/
def body : Q × Q × Q := (cm 90, cm 30, cm 60)

def asmId : AsmId := "asm.business_or_residence_district"

-- Regions.
def roadway : Structure := Build.rect 1 .roadway (m (-30)) (m 0) (m 30) (m 10)
def sidewalk : Structure := Build.rect 2 .sidewalk (m (-30)) (m 10) (m 30) (m 13)
/-- The public way up to the back of the walk. -/
def highway13 : Structure := Build.rect 3 .highway (m (-30)) (m 0) (m 30) (m 13)
/-- The public way including a 2 m strip behind the walk. -/
def highway15 : Structure := Build.rect 3 .highway (m (-30)) (m 0) (m 30) (m 15)
/-- A driveway entrance behind the walk. -/
def driveway : Structure := Build.rect 4 .drivewayOrAlleyEntrance (m (-3)) (m 13) (m 3) (m 30)
/-- A driveway entrance the sidewalk area extends across. -/
def drivewayAcross : Structure := Build.rect 4 .drivewayOrAlleyEntrance (m (-3)) (m 10) (m 3) (m 30)
/-- Two sidewalk regions meeting at x = 0 (idle). -/
def sidewalkWest : Structure := Build.rect 2 .sidewalk (m (-30)) (m 10) (m 0) (m 13)
def sidewalkEast : Structure := Build.rect 5 .sidewalk (m 0) (m 10) (m 30) (m 13)
/-- An alley behind the walk, and the public way it is. -/
def alley : Structure := Build.rect 6 .alley (m (-3)) (m 13) (m 3) (m 40)
def alleyWay : Structure := Build.rect 7 .highway (m (-3)) (m 13) (m 3) (m 40)
/-- An alley the sidewalk area extends across, and the public way it is. -/
def alleyAcross : Structure := Build.rect 6 .alley (m (-3)) (m 10) (m 3) (m 40)
def alleyAcrossWay : Structure := Build.rect 7 .highway (m (-3)) (m 10) (m 3) (m 40)

/-- The driveway layout of forbid / permit / blind / history_boundary. -/
def drivewayLayout : List Structure := [roadway, sidewalk, highway15, driveway]

/-- One observation of the rider: x, y (cm), heading, speed (m/s). -/
abbrev Pose := Int × Int × Vec × Int

/-- A trace of the rider (track 1, the subject) along `path`, 1 s apart, among `sts`, with the
    district assumption declared `district`. -/
def pathTrace (cls : List RoadUserClass) (sts : List Structure) (district : Bool)
    (path : List Pose) : Trace :=
  Build.trace path.length 0 (Units.seconds 1) fun k t =>
    let (x, y, h, v) := path.getD k (0, 0, Build.east, 0)
    Build.scene t (some 1)
      [ Build.user 1 cls (cm x, cm y) h (Units.metresPerSecond v) body ]
      sts
      []
      (assumptions := [(asmId, district)])

/-- Out of the driveway: 10.1, 6.1, 2.6 m from the walk, then 0.6 m (zone, on the apron inside the
    public way), then on the walk, then on the roadway; never slower than 2 m/s. -/
def emergeNoHalt : List Pose :=
  [ (0, 2400, Build.south, 4), (0, 2000, Build.south, 4), (0, 1650, Build.south, 3)
  , (0, 1450, Build.south, 2), (0, 1150, Build.south, 3), (0, 800, Build.south, 3) ]

/-- From the roadway northwards: 7.1, 3.1 m from the walk, 0.6 m (zone), on the walk, then on. -/
def fromRoadway (last : List Pose) : List Pose :=
  [ (0, 200, Build.north, 4), (0, 600, Build.north, 3), (0, 850, Build.north, 2)
  , (0, 1150, Build.north, 3) ] ++ last

/-- `forbid` (violated): In a declared residence district a bicycle rides out of a driveway entrance and onto the sidewalk without its speed falling to the halt tolerance while within the stopping zone; it was farther than the tolerance from the sidewalk earlier in the recording. -/
def forbidTrace : Trace := pathTrace [.bicycle] drivewayLayout true emergeNoHalt

/-- `permit` (compliant): The same bicycle halts just short of the sidewalk, within the stopping zone and outside the sidewalk, then rides onto it. -/
def permitTrace : Trace :=
  pathTrace [.bicycle] drivewayLayout true
    [ (0, 2400, Build.south, 4), (0, 2000, Build.south, 4), (0, 1650, Build.south, 3)
    , (0, 1450, Build.south, 0)      -- halt 0.6 m from the walk
    , (0, 1400, Build.south, 1)      -- creeps on, 0.1 m from the walk
    , (0, 1150, Build.south, 3), (0, 800, Build.south, 3) ]

/-- `idle` (not_applicable): An electric scooter rides along the sidewalk from one sidewalk region into the next, coming from the sidewalk, not from an alley, a driveway or off the public way. -/
def idleTrace : Trace :=
  pathTrace [.electricScooter] [roadway, sidewalkWest, sidewalkEast, highway13] true
    [ (-600, 1150, Build.east, 3), (-300, 1150, Build.east, 3)
    , (100, 1150, Build.east, 3)     -- onto the eastern sidewalk region, from the western one
    , (500, 800, Build.south, 3), (500, 500, Build.south, 3) ]

/-- `blind` (unknown): A bicycle emerges from a driveway onto the sidewalk with no halt recorded, and the source maps regions without their outline, so the stopping zone and the approach start cannot be read.
    The bicycle rides along the walk, turns into the driveway, stands once at its turn-round (whether
    within the zone the outline-less map cannot tell), and comes back out onto the walk without
    another halt. -/
def blindTrace : Trace :=
  pathTrace [.bicycle] drivewayLayout true
    [ (-800, 1150, Build.east, 3), (-400, 1150, Build.east, 3)
    , (0, 1450, Build.north, 2), (0, 1800, Build.north, 2)
    , (0, 1900, Build.south, 0)
    , (0, 1650, Build.south, 2), (0, 1450, Build.south, 2)
    , (0, 1150, Build.south, 3), (0, 800, Build.south, 3) ]

/-- `history_boundary` (unknown): The recording begins with the electric bicycle already within the stopping zone, moving out of a driveway; it enters the sidewalk with no halt recorded, and the search reaches the start of the recording without reaching the approach start. -/
def history_boundaryTrace : Trace :=
  pathTrace [.electricBicycle] drivewayLayout true
    [ (0, 1460, Build.south, 2), (0, 1400, Build.south, 1)
    , (0, 1150, Build.south, 3), (0, 800, Build.south, 3) ]

/-- `branch_1` (not_applicable): The same driveway exit without a halt, in a place the map's reading declares outside any business or residence district. -/
def branch_1Trace : Trace := pathTrace [.bicycle] drivewayLayout false emergeNoHalt

/-- `branch_2` (violated): an electric bicycle emerges from an alley (a public way) onto the walk without halting. -/
def branch_2Trace : Trace :=
  pathTrace [.electricBicycle] [roadway, sidewalk, highway13, alley, alleyWay] true emergeNoHalt

/-- `branch_3` (violated): a bicycle crosses from the roadway onto the sidewalk area across an alley, entering the alley, without halting. -/
def branch_3Trace : Trace :=
  pathTrace [.bicycle] [roadway, sidewalk, highway13, alleyAcross, alleyAcrossWay] true
    (fromRoadway [(0, 1600, Build.north, 3), (0, 2000, Build.north, 3)])

/-- `branch_4` (violated): a bicycle crosses from the roadway onto the sidewalk area across a driveway, entering the driveway, without halting. -/
def branch_4Trace : Trace :=
  pathTrace [.bicycle] [roadway, sidewalk, highway15, drivewayAcross] true
    (fromRoadway [(0, 1450, Build.north, 2), (0, 1480, Build.north, 0)])

/-- `branch_5` (violated): a bicycle emerges from a building beyond the property line (no alley or driveway mapped) onto the walk without halting. -/
def branch_5Trace : Trace := pathTrace [.bicycle] [roadway, sidewalk, highway13] true emergeNoHalt

/-- `branch_6` (violated): a bicycle crosses the walk from the roadway into a building beyond the property line without halting. -/
def branch_6Trace : Trace :=
  pathTrace [.bicycle] [roadway, sidewalk, highway13] true
    (fromRoadway [(0, 1600, Build.north, 3), (0, 2000, Build.north, 3)])

/-- `branch_7` (violated): a bicycle halts in the zone and enters the walk, backs into the driveway, and re-enters without a new halt: the earlier halt does not count. -/
def branch_7Trace : Trace :=
  pathTrace [.bicycle] drivewayLayout true
    [ (0, 2000, Build.south, 3), (0, 1700, Build.south, 3)
    , (0, 1450, Build.south, 0)      -- halt in the zone
    , (0, 1150, Build.south, 3)      -- first entry
    , (0, 1450, Build.north, 2)      -- back into the driveway, in the zone
    , (0, 1150, Build.south, 3)      -- second entry, no halt since the first
    , (0, 800, Build.south, 3) ]

/-- `branch_8` (not_applicable): a pedestrian walks out of the driveway onto the walk without halting; no device of the classes. -/
def branch_8Trace : Trace := pathTrace [.pedestrian] drivewayLayout true emergeNoHalt

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_40_140_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable (window := some (1000, 4000))
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] (window := some (1000, 8000))
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the subject's approach to the sidewalk: the last observation at which it was farther than p.stop_point_tolerance from the sidewalk lies before the recording")
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_40_140_o1

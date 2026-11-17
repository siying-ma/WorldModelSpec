/-
  Witnesses for NRS_484B_307_2b.

  Geometry (metres, +x east, +y north). Highway 100 runs east–west, x ∈ [-100, 100], y ∈ [-12, 12];
  its roadway 10 is y ∈ [-7, 7], with eastbound lane 11 (y ∈ [0, 7], x ∈ [-100, 40], entering
  intersection 20) and westbound lane 12 (y ∈ [-7, 0]). Highway 101 runs north–south,
  x ∈ [40, 60]; intersection 20 (x ∈ [40, 60], y ∈ [-7, 7]) lies on both; its northbound lane 13
  (x ∈ [50, 57], y ∈ [-100, -7]) enters 20. A marked crosswalk 30 spans the west leg,
  x ∈ [34, 40]. A third highway 102 (x ∈ [200, 220], y ∈ [100, 300]) has intersection 21 and an
  approach lane 14 entering it, used only in branch_2.

  The pedestrian (track 1) walks north at 1.3 m/s over three instants 1 s apart, y = -2, -0.7, 0.6
  (crossing from lane 12 into lane 11), at x = 4 (30 m west of the crosswalk) or at x = 37 (inside
  it). The traffic-signal head (device 1) stands at y = 23, straight ahead: 25 m to 22.4 m away,
  inside the 60 m reach and exactly on the heading.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def hwy1 : Structure := Build.rect 100 .highway (m (-100)) (m (-12)) (m 100) (m 12)
def hwy2 : Structure := Build.rect 101 .highway (m 40) (m (-100)) (m 60) (m 100)
def hwy3 : Structure := Build.rect 102 .highway (m 200) (m 100) (m 220) (m 300)
def roadway1 : Structure := { Build.rect 10 .roadway (m (-100)) (m (-7)) (m 100) (m 7) with ways := some [100] }
def laneEast : Structure := { Build.lane 11 (box (-100) 0 40 7) Build.east (enters := some 20) with ways := some [100] }
def laneWest : Structure := { Build.lane 12 (box (-100) (-7) 100 0) Build.west with ways := some [100] }
def laneNorth : Structure := { Build.lane 13 (box 50 (-100) 57 (-7)) Build.north (enters := some 20) with ways := some [101] }
def laneFar : Structure := { Build.lane 14 (box 210 100 217 200) Build.north (enters := some 21) with ways := some [102] }
def isect1 : Structure := { Build.rect 20 .intersection (m 40) (m (-7)) (m 60) (m 7) with ways := some [100, 101] }
def isect2 : Structure := { Build.rect 21 .intersection (m 200) (m 200) (m 220) (m 220) with ways := some [102] }
def crosswalk1 : Structure :=
  { Build.rect 30 .crosswalk (m 34) (m (-7)) (m 40) (m 7) with marked := some true, ways := some [100] }

def structures : List Structure :=
  [hwy1, hwy2, hwy3, roadway1, laneEast, laneWest, laneNorth, laneFar, isect1, isect2, crosswalk1]

def speed : Q := cm 130

/-- The pedestrian at instant `k`, starting at `p0`, walking along unit heading `h`. -/
def ped (p0 : Vec) (h : Vec) (k : Nat) : RoadUser :=
  let d := Q.mul (Q.ofInt k) speed
  Build.user 1 [.pedestrian] (Q.add p0.1 (Q.mul h.1 d), Q.add p0.2 (Q.mul h.2 d)) h speed
    (cm 25, cm 25, cm 90)

/-- The traffic-signal head. -/
def head (gov : List RegionId) (shows : List SignalIndication) (pos : Vec) : Device :=
  { Build.signal 1 gov shows with position := some pos }

def sceneTrace (p0 : Vec) (h : Vec) (devs : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped p0 h k] structures devs

def outside : Vec := (m 4, m (-2))
def inside : Vec := (m 37, m (-2))

/-- `forbid` (violated): A pedestrian (ru.aggregate pedestrian) crosses a st.lane of a st.roadway, both lying on a st.highway (st.on_way), at 1.3 m/s perpendicular to the lanes' designated direction (drv.motion.moving_across_carrier holds), 30 m from any st.crosswalk. A st.intersection lies on that highway, and a dev.traffic_signal head that governs a lane entering that intersection (dev.governs, st.lane_enters) stands 25 m straight ahead of the pedestrian (dev.position within the facing angle and reach) and displays circular_green alone; no pedestrian signal governs; no other road user is in the scene. -/
def forbidTrace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularGreen] (m 4, m 23)]

/-- `permit` (compliant): The same pedestrian makes the same crossing within a marked crosswalk (rel.occupies st.crosswalk). -/
def permitTrace : Trace :=
  sceneTrace inside Build.north [head [13] [.circularGreen] (m 37, m 23)]

/-- `idle` (not_applicable): As in forbid, but the signal the pedestrian faces displays circular_red. -/
def idleTrace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularRed] (m 4, m 23)]

/-- `blind` (unknown): As in forbid, the pedestrian crosses outside a crosswalk while the head tied to the crossed highway displays circular_green alone, but the positions of the signal heads are not observed: whether it faces the signal cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As in permit, and a dev.pedestrian_signal governing the crossed lanes and roadway displays dont_walk_steady, so NRS_484B_283_1d4_o1 applies to the pedestrian: another device directs it, and this rule does not apply. -/
def branch_1Trace : Trace :=
  -- The composed rule looks back to the onset of the steady don't-walk and to the start of the
  -- crossing: the pedestrian signal shows dont_walk_flashing at 0 s and 1 s and dont_walk_steady
  -- from 2 s; the pedestrian is recorded from 11.9 m south of the centre line (off the roadway),
  -- y = -11.9 + 1.3 k over fourteen instants, and steps onto the roadway, inside the crosswalk, at
  -- 4 s, after the onset. The witness speaks of instants 2 s … 13 s.
  -- A sidewalk 40 (y ∈ [-12, -7]) borders the roadway on the south: the pedestrian starts on it.
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (m 37, cm (-1190)) Build.north k]
      (structures ++ [{ Build.rect 40 .sidewalk (m (-100)) (m (-12)) (m 100) (m (-7)) with ways := some [100] }])
      [ head [13] [.circularGreen] (m 37, m 23)
      , { Build.device 2 .pedestrianSignal [10, 11, 12] (some (m 37, m 12)) with
            pedState := some (if k < 2 then .dontWalkFlashing else .dontWalkSteady) } ]

/-- `branch_2` (not_applicable): As in forbid, except that the green head straight ahead governs neither an intersection on the crossed highway nor any travel region entering one: it governs only a lane entering an intersection that lies on a different highway, which the crossed roadway and lanes do not lie on. The pedestrian faces a green head, but not a signal of the highway it crosses. -/
def branch_2Trace : Trace :=
  sceneTrace outside Build.north [head [14] [.circularGreen] (m 4, m 23)]

/-- `branch_3` (not_applicable): As in forbid, but the head displays circular_green together with green_arrow(left): the signal is not circular green alone. -/
def branch_3Trace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularGreen, .greenArrow .left] (m 4, m 23)]

/-- `branch_4` (violated): As in forbid, but the head governs intersection 20 itself (directly),
    no approach lane. -/
def branch_4Trace : Trace :=
  sceneTrace outside Build.north [head [20] [.circularGreen] (m 4, m 23)]

/-- `branch_5` (not_applicable): As in forbid, but the head stands about 45 degrees off the
    pedestrian's heading (outside the facing angle), within reach. -/
def branch_5Trace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularGreen] (m 22, m 16)]

/-- `branch_6` (not_applicable): As in forbid, but the head stands straight ahead 80 m away,
    beyond the facing reach. -/
def branch_6Trace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularGreen] (m 4, m 78)]

/-- `branch_7` (not_applicable): As in forbid, but the head stands straight behind the pedestrian. -/
def branch_7Trace : Trace :=
  sceneTrace outside Build.north [head [13] [.circularGreen] (m 4, m (-27))]

/-- `branch_8` (not_applicable): The pedestrian walks east along lane 11 (not across it), the
    green head straight ahead of it; it does not proceed across the highway. -/
def branch_8Trace : Trace :=
  sceneTrace (m 4, m 3) Build.east [head [13] [.circularGreen] (m 29, m 3)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_2b"
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
  , witness "blind" blindTrace (.unknown []) ["dev.position"]
  , { witness "branch_1" branch_1Trace .notApplicable with window := some (2000, 13000) }
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_2b

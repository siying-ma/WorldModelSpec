/-
  Witnesses for NRS_484B_250_4_o1.

  The carriageway: an east-bound lane c (id 10, x from -120 m to 0, y from 0 to 4 m, entering the
  intersection) runs into intersection i (id 20, x 0 to 16 m, y -8 to 8 m). Near-side marks of c,
  each recorded as marking c alone: stop line s (id 40, x -3 to -2.5 m) or crosswalk w (id 50, x -4
  to 0 m). Far side, every scene: a west-bound lane (id 12) entering i, its stop line (id 41) and
  crosswalk (id 51), recorded as marking that lane only. Ways (branch_3): the east-west highway
  (id 30) carries c and i, the north-south highway (id 31) carries i. Signal d (id 60) governs i
  (c in branch_1 and branch_2), installed and uncovered; dark and inoperative except in idle.

  The body: x (track 1, motor vehicle) runs east along y = 2 m, 5 m long and 2 m wide (reference
  point at its centre), one observation per second. Its occupancy is stated per observation from
  its body's overlap with every region. Every window starts at the second observation, so the
  entry judged is never the trace's first.

  Against the reading: the stopping zone is 2 m (p.stop_point_tolerance); halts are at speed 0
  (p.speed_resolution 0.2 m/s); the crossing way in branch_3 is in view for 150 m against
  p.intersection_sight_distance 100 m. Every figure here is the witness's own and appears nowhere
  in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def cId : RegionId := 10
def farLaneId : RegionId := 12
def iId : RegionId := 20
def eastWestId : RegionId := 30
def northSouthId : RegionId := 31
def sId : RegionId := 40
def farLineId : RegionId := 41
def wId : RegionId := 50
def farWalkId : RegionId := 51
def dId : DeviceId := 60

def approachLane : Structure :=
  Build.lane cId [(m (-120), m 0), (m 0, m 0), (m 0, m 4), (m (-120), m 4)] Build.east (enters := some iId)
def farLane : Structure :=
  Build.lane farLaneId [(m 16, m (-4)), (m 136, m (-4)), (m 136, m 0), (m 16, m 0)] Build.west (enters := some iId)
def junction : Structure := Build.rect iId .intersection (m 0) (m (-8)) (m 16) (m 8)
def stopLine : Structure :=
  { Build.rect sId .stopLine (m (-3)) (m 0) (cm (-250)) (m 4) with entranceOf := [cId], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect wId .crosswalk (m (-4)) (m (-8)) (m 0) (m 8)
    with entranceOf := [cId], entranceObserved := true, marked := some true }
def farStopLine : Structure :=
  { Build.rect farLineId .stopLine (cm 2050) (m (-4)) (m 21) (m 0)
    with entranceOf := [farLaneId], entranceObserved := true }
def farCrosswalk : Structure :=
  { Build.rect farWalkId .crosswalk (m 16) (m (-8)) (m 20) (m 8)
    with entranceOf := [farLaneId], entranceObserved := true, marked := some true }
def eastWest : Structure := Build.rect eastWestId .highway (m (-150)) (m (-10)) (m 150) (m 10)
def northSouth : Structure := Build.rect northSouthId .highway (m (-2)) (m (-150)) (m 18) (m 150)

def farSide : List Structure := [farLane, farStopLine, farCrosswalk]
/-- c marked by stop line s. -/
def stopLineScene : List Structure := [approachLane, junction, stopLine] ++ farSide
/-- c marked by crosswalk w, no stop line marking it. -/
def crosswalkScene : List Structure := [approachLane, junction, crosswalk] ++ farSide
/-- c marked by nothing. -/
def bareScene : List Structure := [approachLane, junction] ++ farSide
/-- As bareScene, with the ways mapped: c and the far lane on the east-west highway, i on both. -/
def wayScene : List Structure :=
  [ { approachLane with ways := some [eastWestId] }
  , { junction with ways := some [eastWestId, northSouthId] }
  , { farLane with ways := some [eastWestId] }, farStopLine, farCrosswalk, eastWest, northSouth ]

/-- Signal d over the regions it governs: dark and inoperative, or green and operating. -/
def signal (inoperative : Bool) (governs : List RegionId) : Device :=
  { Build.signal dId governs [if inoperative then .dark else .circularGreen]
    with uncovered := some true, inoperative := some inoperative }

/-- A trace of x, one observation per second: per step its reference point's x (m), its speed and
    the regions its body overlaps. -/
def run (structures : List Structure) (dev : Device) (steps : List (Q × Q × List RegionId))
    (sight : Option (List (RegionId × Q)) := none)
    (adjust : Nat → RoadUser → RoadUser := fun _ u => u) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let (px, v, occ) := steps.getD k (Q.zero, Q.zero, [])
    let u : RoadUser := adjust k
      { Build.user 1 [.motorVehicle] (px, m 2) Build.east v (cm 250, m 1, cm 75) with sightAlongWay := sight }
    Build.scene t (some 1) [u] structures [dev] (some (occ.map fun r => (1, r)))

/-- x passes s above 3 m/s and enters i at the ninth observation (8 s). -/
def forbidSteps : List (Q × Q × List RegionId) :=
  [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
  , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-14), mps 6, [cId])
  , (m (-7), mps 5, [cId])                 -- body front 1.5 m short of s
  , (m (-2), mps 4, [cId, sId, iId])       -- across s, entering i
  , (m 3, mps 5, [iId]), (m 9, mps 6, [iId]) ]

/-- `forbid` (violated): x (motor vehicle class, member of the vehicle aggregate) drives on lane c with st.lane_enters c i; stop line s with st.entrance_of s c; dev.traffic_signal d governs i and is dev.inoperative. x is first observed 80 m upstream of s at 12 m/s, keeps kin.speed above 3 m/s past s and enters i. -/
def forbidTrace : Trace := run stopLineScene (signal true [iId]) forbidSteps

/-- `permit` (compliant): As forbid, but x halts (kin.speed 0) with its body 0.5 m short of s, s ahead along c, then moves on and enters i. -/
def permitTrace : Trace :=
  run stopLineScene (signal true [iId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-14), mps 5, [cId])
    , (m (-6), mps 0, [cId]), (m (-6), mps 0, [cId])    -- halted, body front 0.5 m short of s
    , (m (-4), mps 2, [cId, sId])
    , (m 1, mps 4, [cId, iId])                          -- entering i
    , (m 7, mps 6, [iId]) ]

/-- `idle` (not_applicable): As forbid, but d shows circular_green and dev.inoperative is false at x's entry into i. -/
def idleTrace : Trace := run stopLineScene (signal false [iId]) forbidSteps

/-- `blind` (unknown): As forbid, but the source does not observe dev.inoperative for d. -/
def blindTrace : Trace := run stopLineScene (signal true [iId]) forbidSteps

/-- `branch_1` (violated): No stop line marks c (the line list is observed); crosswalk w with st.entrance_of w c; d inoperative. x halts with its footprint overlapping w, then enters i: the halt is not before entering the crosswalk and no other halt occurs on the approach. (d governs c, not i.) -/
def branch_1Trace : Trace :=
  run crosswalkScene (signal true [cId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-13), mps 5, [cId])
    , (m (-7), mps 3, [cId])
    , (m (-3), mps 0, [cId, wId]), (m (-3), mps 0, [cId, wId])   -- halted on w
    , (m 1, mps 4, [cId, wId, iId])                               -- entering i
    , (m 7, mps 6, [iId]) ]

/-- `branch_2` (compliant): No stop line and no crosswalk marks c; d inoperative. x halts outside i, 1 m from it, then enters i. (d governs c, not i.) -/
def branch_2Trace : Trace :=
  run bareScene (signal true [cId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-13), mps 5, [cId])
    , (m (-7), mps 3, [cId])
    , (cm (-350), mps 0, [cId]), (cm (-350), mps 0, [cId])        -- halted, body front 1 m short of i
    , (m 1, mps 4, [cId, iId])                                    -- entering i
    , (m 7, mps 6, [iId]) ]

/-- `branch_3` (compliant): No stop line and no crosswalk marks c; d inoperative. x halts 3 m short of i, outside the tolerance, where the north-south highway (on which i lies and c does not) is in view for 150 m; its next observation is within the tolerance of i, and it enters i. -/
def branch_3Trace : Trace :=
  run wayScene (signal true [iId])
    [ (m (-83), mps 12, [cId, eastWestId]), (m (-71), mps 12, [cId, eastWestId])
    , (m (-59), mps 12, [cId, eastWestId]), (m (-47), mps 12, [cId, eastWestId])
    , (m (-35), mps 10, [cId, eastWestId]), (m (-24), mps 8, [cId, eastWestId])
    , (m (-15), mps 5, [cId, eastWestId]), (m (-9), mps 3, [cId, eastWestId])
    , (cm (-550), mps 0, [cId, eastWestId])                              -- halted, body front 3 m short of i
    , (m (-4), mps 2, [cId, eastWestId, northSouthId])                   -- body front 1.5 m short of i
    , (m 1, mps 4, [cId, iId, eastWestId, northSouthId])                 -- entering i
    , (m 7, mps 6, [iId, eastWestId, northSouthId]) ]
    (sight := some [(eastWestId, m 40), (northSouthId, m 150)])

/-- `branch_4` (violated): As permit, but after entering i x backs out onto c, within the stopping zone of s, and enters i again without halting: the halt before the previous entry does not count for the second entry. -/
def branch_4Trace : Trace :=
  run stopLineScene (signal true [iId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-14), mps 5, [cId])
    , (m (-6), mps 0, [cId])                    -- halted, body front 0.5 m short of s
    , (m (-2), mps 3, [cId, sId, iId])          -- first entry into i
    , (m 1, mps 2, [cId, iId])
    , (cm (-350), mps 2, [cId, sId])            -- backing out of i, on s
    , (cm 50, mps 3, [cId, iId])                -- second entry into i
    , (m 6, mps 5, [iId]) ]
    (adjust := fun k u => if k == 10 then Build.withKin u (fun kn => { kn with velocity := some (Build.scale Build.west (mps 2)) }) else u)

/-- `branch_5` (compliant): No stop line marks c; crosswalk w with st.entrance_of w c; d inoperative. x halts with its body 1 m short of w, w ahead along c, then enters i. -/
def branch_5Trace : Trace :=
  run crosswalkScene (signal true [iId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-15), mps 5, [cId])
    , (cm (-750), mps 0, [cId]), (cm (-750), mps 0, [cId])        -- halted, body front 1 m short of w
    , (m (-4), mps 3, [cId, wId])
    , (m 1, mps 5, [cId, wId, iId])                               -- entering i
    , (m 7, mps 6, [iId]) ]

/-- `branch_6` (violated): No stop line and no crosswalk marks c; d inoperative. x halts 6 m short of i, outside the tolerance, where no crossing way is mapped in view, then moves on and enters i without another halt. -/
def branch_6Trace : Trace :=
  run bareScene (signal true [iId])
    [ (m (-83), mps 12, [cId]), (m (-71), mps 12, [cId]), (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId])
    , (m (-35), mps 10, [cId]), (m (-24), mps 8, [cId]), (m (-15), mps 5, [cId]), (m (-9), mps 1, [cId])
    , (cm (-850), mps 0, [cId]), (cm (-850), mps 0, [cId])        -- halted, body front 6 m short of i
    , (m (-4), mps 3, [cId])                                      -- body front 1.5 m short of i
    , (m 1, mps 4, [cId, iId])                                    -- entering i
    , (m 7, mps 6, [iId]) ]

/-- `history_boundary` (unknown): As forbid, but the recording begins with x already on c 1.5 m short of s at 1 m/s, inside the stopping zone; no halt is recorded before x enters i. -/
def history_boundaryTrace : Trace :=
  run stopLineScene (signal true [iId])
    [ (m (-7), mps 1, [cId])                    -- body front 1.5 m short of s
    , (m (-6), mps 1, [cId])
    , (m (-4), mps 2, [cId, sId])
    , (cm (-150), mps 3, [cId, sId, iId])       -- entering i
    , (cm 150, mps 3, [cId, iId])
    , (m 5, mps 4, [iId]) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 60000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "x's approach start on c, the last observation outside the stopping zone upstream of s, lies before the recording.") ]

end TrafficSpecWitness.NRS_484B_250_4_o1

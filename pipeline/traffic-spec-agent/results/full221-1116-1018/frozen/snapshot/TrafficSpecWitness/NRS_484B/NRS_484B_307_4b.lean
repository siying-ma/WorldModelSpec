/-
  Witnesses for NRS_484B_307_4b.

  The junction: highway 101 (east–west, y ∈ [-15, 15]) meets highway 102 (north–south,
  x ∈ [-15, 15]) at intersection 103 (x, y ∈ [-10, 10]), which lies on both. West of the junction,
  roadway 104 (y ∈ [-10, 10]) of highway 101, split into eastbound lane 105 (y ∈ [-10, 0], entering
  103) and westbound lane 106 (y ∈ [0, 10]); the north sidewalk 107 (y ∈ [10, 15]); the north
  arm's roadway 111 (x ∈ [-10, 10], y ≥ 10) of highway 102.
  Vehicular head 201 at (-16, -13), across the roadway; pedestrian head 202 at (-20, -3).
  The pedestrian (track 1) heads south: at t = 0 it stands at (-20, 12) on the sidewalk (25.3 m
  from head 201, cosine 0.99 to the line to it); from t = 1 s it is at (-20, 8), its footprint on
  roadway 104 and lane 106, 21.4 m from head 201 (cosine 0.98) and 11 m from head 202 (cosine 1).
  The rule reads the previous observation through `rises`, so each witness judges t ∈ [1 s, 2 s].
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def wEW : RegionId := 101
def wNS : RegionId := 102
def junction : RegionId := 103
def roadwayW : RegionId := 104
def laneEast : RegionId := 105
def laneWest : RegionId := 106
def sidewalkN : RegionId := 107
/-- The north arm's roadway, of highway 102 (x ∈ [-10, 10], y ≥ 10). -/
def roadwayN : RegionId := 111

def structures : List Structure :=
  [ Build.rect wEW .highway (m (-60)) (m (-15)) (m 60) (m 15)
  , Build.rect wNS .highway (m (-15)) (m (-60)) (m 15) (m 60)
  , { Build.rect junction .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [wEW, wNS] }
  , { Build.rect roadwayW .roadway (m (-60)) (m (-10)) (m (-10)) (m 10) with ways := some [wEW] }
  , { Build.lane laneEast [(m (-60), m (-10)), (m (-10), m (-10)), (m (-10), m 0), (m (-60), m 0)] Build.east
        (enters := some junction) with ways := some [wEW] }
  , { Build.lane laneWest [(m (-60), m 0), (m (-10), m 0), (m (-10), m 10), (m (-60), m 10)] Build.west
        with ways := some [wEW] }
  , { Build.rect sidewalkN .sidewalk (m (-60)) (m 10) (m (-10)) (m 15) with ways := some [wEW] }
  , { Build.rect roadwayN .roadway (m (-10)) (m 10) (m 10) (m 60) with ways := some [wNS] } ]

/-- The vehicular head, governing `governs`, displaying `shows`. -/
def vehHead (governs : List RegionId) (shows : List SignalIndication) : Device :=
  { Build.device 201 .trafficSignal governs (some (m (-16), m (-13))) with indications := some shows }

/-- A pedestrian head at `pos` governing `governs`. -/
def pedHead (pos : Vec) (governs : List RegionId) (st : PedSignalState) (cd : Bool) : Device :=
  { Build.device 202 .pedestrianSignal governs (some pos) with pedState := some st, countdown := some cd }

def pedAhead : Vec := (m (-20), m (-3))

/-- The pedestrian: on the sidewalk at k = 0, on the roadway from k = 1 when `steps`. -/
def walker (k : Nat) (steps : Bool) (heading : Bool := true) : RoadUser :=
  let pos : Vec := if steps && k ≥ 1 then (m (-20), m 8) else (m (-20), m 12)
  let u := Build.user 1 [.pedestrian] pos Build.south (Units.metresPerSecond 1) (cm 25, cm 25, cm 90)
  if heading then u else Build.withKin u fun kn => { kn with heading := none }

def occ (k : Nat) (steps : Bool) : List (TrackId × RegionId) :=
  if steps && k ≥ 1 then [(1, roadwayW), (1, laneWest), (1, wEW)] else [(1, sidewalkN), (1, wEW)]

def junctionTrace (steps : Bool) (devices : List Device) (heading : Bool := true) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [walker k steps heading] structures devices (some (occ k steps))

def greenLeft : List SignalIndication := [.greenArrow .left]

/-- `forbid` (violated): A pedestrian stands on the corner sidewalk of a highway that meets another at a signalized intersection, 25 m from a vehicular head it faces (heading within 10 degrees of the line to the head) that governs a lane entering the intersection and displays green_arrow(left) alone; a pedestrian head 15 m ahead that it faces, governing the roadway it is about to step onto, displays dont_walk_steady. At the next observation its footprint overlaps that roadway, which lies on a highway on which the intersection lies. -/
def forbidTrace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]

/-- `permit` (compliant): Same scene; the pedestrian stays on the sidewalk while the vehicular head displays green_arrow(left) alone; its footprint never overlaps the roadway. -/
def permitTrace : Trace :=
  junctionTrace false [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]

/-- `idle` (not_applicable): The vehicular head the pedestrian faces displays circular_green alone; it steps onto the roadway. -/
def idleTrace : Trace :=
  junctionTrace true [vehHead [laneEast] [.circularGreen], pedHead pedAhead [roadwayW] .dontWalkSteady false]

/-- `blind` (unknown): As forbid, but the source supplies no heading for the pedestrian: whether it faces the vehicular head is unknown.
    The scenes are forbid's (occupancy is the adapter's, from the footprint); the manifest masks
    kin.heading, so the formula reads it as unobserved. -/
def blindTrace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]

/-- `branch_1` (compliant): As forbid, but the pedestrian head it faces, governing the roadway it steps onto, displays walk at the observation of its entry: another device permits it to proceed. -/
def branch_1Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .walk false]

/-- `branch_2` (compliant): As forbid, but the roadway the pedestrian steps onto lies on a way that does not meet at the intersection the vehicular head controls (no st.on_way to any highway on which that intersection lies); it never overlaps a roadway of the highway at the signal.
    A frontage road, highway 108 (y ∈ [15, 35], x ≤ -10), runs north of highway 101 and meets
    nothing at 103: its sidewalk 109 (y ∈ [15, 19]) and roadway 110 (y ∈ [20, 30]). The pedestrian
    heads north from (-20, 17) on 109 to (-20, 22) on 110; the vehicular head stands at (-16, 40)
    across it (23.3 m, cosine 0.99 at t = 0; 18.4 m, cosine 0.98 at t = 1 s) and governs lane 105
    of highway 101; the pedestrian head at (-20, 35) governs roadway 110 and shows dont_walk_steady. -/
def branch_2Trace : Trace :=
  let frontage : RegionId := 108
  let sidewalkF : RegionId := 109
  let roadwayF : RegionId := 110
  let sts := structures ++
    [ Build.rect frontage .highway (m (-60)) (m 15) (m (-10)) (m 35)
    , { Build.rect sidewalkF .sidewalk (m (-60)) (m 15) (m (-10)) (m 19) with ways := some [frontage] }
    , { Build.rect roadwayF .roadway (m (-60)) (m 20) (m (-10)) (m 30) with ways := some [frontage] } ]
  let devs : List Device :=
    [ { Build.device 201 .trafficSignal [laneEast] (some (m (-16), m 40)) with indications := some greenLeft }
    , pedHead (m (-20), m 35) [roadwayF] .dontWalkSteady false ]
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := if k ≥ 1 then (m (-20), m 22) else (m (-20), m 17)
    let occs : List (TrackId × RegionId) :=
      if k ≥ 1 then [(1, roadwayF), (1, frontage)] else [(1, sidewalkF), (1, frontage)]
    Build.scene t (some 1)
      [Build.user 1 [.pedestrian] pos Build.north (Units.metresPerSecond 1) (cm 25, cm 25, cm 90)]
      sts devs (some occs)

/-- `branch_3` (violated): As forbid, but the vehicular head governs the intersection itself (dev.governs on the intersection) rather than an approach lane; the pedestrian steps onto the roadway of a highway on which that intersection lies, its pedestrian head showing dont_walk_steady. -/
def branch_3Trace : Trace :=
  junctionTrace true [vehHead [junction] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]

/-- `branch_4` (compliant): As forbid, but the pedestrian head displays dont_walk_flashing with its countdown attribute at the observation of the entry: the flashing indication with a countdown permits the pedestrian to proceed. -/
def branch_4Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkFlashing true]

/-- `branch_5` (violated): As branch_4, but the pedestrian head displays dont_walk_flashing without a countdown: it permits nothing, and the entry violates the duty. Differs from branch_4 only in the countdown. -/
def branch_5Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkFlashing false]

/-- `branch_6` (violated): As forbid, but the scene has no pedestrian head at all; the pedestrian steps onto the roadway of the highway at the signal while the vehicular head displays green_arrow(left) alone. The duty binds the subject alone. -/
def branch_6Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft]

/-- `branch_7` (violated): As branch_1, but the pedestrian head displaying walk lies behind the pedestrian (the angle between its heading and the line to the head is about 120 degrees): it does not face the device, so it is not permitted, and the entry violates the duty.
    The head stands at (-7, 15.5): from (-20, 8) the line to it is (13, 7.5), at 120° to south. -/
def branch_7Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead (m (-7), cm 1550) [roadwayW] .walk false]

/-- `branch_8` (compliant): As branch_1, but the pedestrian head showing walk governs only the
    westbound lane 106 of the same highway, which the pedestrian's footprint overlaps on entry,
    not the roadway itself: the lane limb of the permission. -/
def branch_8Trace : Trace :=
  junctionTrace true [vehHead [laneEast] greenLeft, pedHead pedAhead [laneWest] .walk false]

/-- `branch_9` (compliant): As forbid, but the pedestrian is already on roadway 104 at
    (-20, 8) at every observation: at no judged observation does it come onto a roadway of
    highway 101 from off it, so there is no entry the words forbid. (The selection still holds for
    highway 102, on which junction 103 also lies and which has no roadway the pedestrian
    entered, so the rule applies and is complied with rather than not engaged.) -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [walker (k + 1) true] structures
      [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]
      (some (occ (k + 1) true))

/-- `branch_10` (not_applicable): As forbid, but the pedestrian stands at the corner (-10, 10) at
    every observation, its footprint (±0.25 m) already overlapping roadway 104 of highway 101 and
    roadway 111 of highway 102, the two ways on which junction 103 lies: at no observation does it
    come onto a roadway of either from off it, so no entry is engaged. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [Build.user 1 [.pedestrian] (m (-10), m 10) Build.south (Units.metresPerSecond 0) (cm 25, cm 25, cm 90)]
      structures
      [vehHead [laneEast] greenLeft, pedHead pedAhead [roadwayW] .dontWalkSteady false]
      (some [(1, roadwayW), (1, laneWest), (1, junction), (1, sidewalkN), (1, roadwayN), (1, wEW), (1, wNS)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_4b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_4b

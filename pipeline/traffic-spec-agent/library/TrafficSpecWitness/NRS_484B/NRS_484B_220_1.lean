/-
  Witnesses for NRS_484B_220_1.

  The geometry. One straight way running east–west: the highway region 10, a rectangle 600 m long
  and as wide as each scene needs (the whole public way between its boundary lines, its sidewalks
  and shoulders included), with `ways := some []` — a way lies on no way. Every other region is a
  strip of the same 600 m, declared to lie on way 10 (`ways := some [10]`): the one-way roadways
  (region 11, and region 12 where a scene carries two), the lane of a roadway, the paved shoulder
  beside it, the bicycle lane, the sidewalk, and the centre line of the two-way scene. The junction
  on that way is region 13, a 20 m square of the carriageway, which lies on way 10 as an
  intersection lies on every way that meets there. A region carries a designated direction of
  travel only where the scene gives it one.

  The subject is track 1, a motor vehicle 4 m long and 2 m wide, running due east or due west and
  advancing one second's travel at each of the three observations. Each scene states the
  occupancy the source records — the regions the subject's footprint is recorded against — rather
  than leaving it to the polygons, since what a source records the footprint against is exactly
  what several of these scenes turn on.

  The margins, against the run's reading (motion floor 0.5 m/s, opposition tolerance 0.5): every
  subject here runs at 2 m/s or more, well above the floor, and runs due east or due west against a
  designation of due east or due west, so the directional cosine is 1 or −1 and never near the
  tolerance. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_220_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def ms (n : Int) : Q := Units.metresPerSecond n
def oneSecond : Q := Units.seconds 1

-- Binders ↦ tracks: v ↦ 1

/-- A region whose designated direction of travel the source declares. -/
def designated (d : Vec) : LaneInfo := { direction := some d }

/-- The highway region: the whole public way between its boundary lines, of the given half-width. -/
def highwayOf (halfWidth : Q) : Structure :=
  { Build.rect 10 .highway (m 0) (Q.neg halfWidth) (m 600) halfWidth with ways := some [] }

def way14 : Structure := highwayOf (m 14)
def way20 : Structure := highwayOf (m 20)
def way24 : Structure := highwayOf (m 24)
def way40 : Structure := highwayOf (m 40)

/-- A part of way 10: a strip of it between two offsets, with the direction designated for it (where
    the source declares one) and, for a shoulder, whether it is paved. -/
def strip (id : RegionId) (kind : StructureKind) (y0 y1 : Q) (dir : Option Vec := none)
    (isPaved : Option Bool := none) : Structure :=
  { Build.rect id kind (m 0) y0 (m 600) y1 with
      ways := some [10], lane := dir.map designated, paved := isPaved }

/-- The junction on way 10. -/
def junction : Structure :=
  { Build.rect 13 .intersection (m 90) (m (-8)) (m 110) (m 8) with ways := some [10] }

/-- A regulatory sign of catalogue code one_way, its control recorded at the given regions; its
    legend states no restriction of time, class or occupancy. -/
def oneWaySign (id : DeviceId) (governs : List RegionId) : Device :=
  { Build.sign id .regulatorySign governs with code := some .oneWay, conditions := some {} }

/-- A regulatory sign of another code — keep right — at the same place. -/
def keepRightSign (id : DeviceId) (governs : List RegionId) : Device :=
  { Build.sign id .regulatorySign governs with code := some .keepRight, conditions := some {} }

/-- The subject, a motor vehicle. -/
def subjectAt (x y : Q) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) heading speed (m 2, m 1, m 1)

/-- Where a body that started at `x0` and has run `step` each second stands at observation `k`. -/
def along (x0 step : Q) (k : Nat) : Q := Q.add x0 (Q.mul step (Q.ofInt (Int.ofNat k)))

/-- The subject running east at `speed` from `x0`, at the offset `y`. -/
def eastbound (x0 y speed : Q) : Nat → RoadUser :=
  fun k => subjectAt (along x0 speed k) y Build.east speed

/-- The subject running west at `speed` from `x0`, at the offset `y`. -/
def westbound (x0 y speed : Q) : Nat → RoadUser :=
  fun k => subjectAt (along x0 (Q.neg speed) k) y Build.west speed

/-- Three observations a second apart of one subject on one map, the source recording its footprint
    against the regions `occ`. -/
def traceOf (u : Nat → RoadUser) (structures : List Structure) (devices : List Device)
    (occ : List RegionId) : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1) [u k] structures devices
      (occupies := some (occ.map fun r => ((1 : TrackId), r)))

/-- The eastbound one-way roadway of way 10, the whole carriageway. -/
def eastRoadway : Structure := strip 11 .oneWayRoadway (m (-8)) (m 8) (some Build.east)

/-- `forbid` (violated): A one-way sign governs a single-direction roadway running east on a highway. The subject vehicle travels west along that roadway at six metres per second for several observations. -/
def forbidTrace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6)) [way14, eastRoadway] [oneWaySign 1 [11]] [10, 11]

/-- `permit` (compliant): On the same signposted one-way roadway the subject travels east at eight metres per second throughout. -/
def permitTrace : Trace :=
  traceOf (eastbound (m 50) (m 0) (ms 8)) [way14, eastRoadway] [oneWaySign 1 [11]] [10, 11]

/-- `idle` (not_applicable): The subject travels west on an ordinary two-way roadway with a centre line, lying on a highway with no one-way sign; no one-way roadway is present in the scene. The regulatory sign on that way is a keep-right sign, whose catalogue code is not one_way. -/
def idleTrace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6))
    [ way14, strip 11 .roadway (m (-8)) (m 8), strip 12 .centreLine (cm (-10)) (cm 10) ]
    [ keepRightSign 1 [11] ] [10, 11]

/-- `blind` (unknown): The subject travels along a signposted one-way roadway of a highway, but the source declares no direction of travel for the roadway's structures, so whether the subject's motion opposes the designated direction cannot be decided. -/
def blindTrace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6)) [way14, eastRoadway] [oneWaySign 1 [11]] [10, 11]

/-- `branch_1` (violated): On an eastbound signposted one-way highway the subject travels west at six metres per second entirely on the paved shoulder, whose own designated direction is east, its footprint never overlapping the roadway; the shoulder and the roadway both lie on that highway and the one-way sign's control is recorded at the roadway. -/
def branch_1Trace : Trace :=
  traceOf (westbound (m 50) (m 10) (ms 6))
    [ way14, eastRoadway, strip 12 .shoulder (m 8) (m 12) (some Build.east) (some true) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_2` (violated): The subject travels west at six metres per second in the sole lane of an eastbound one-way roadway, occupying the lane and the roadway alike; the one-way sign's observed control is recorded at that lane and not at the enclosing roadway. -/
def branch_2Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6))
    [ way14, strip 11 .oneWayRoadway (m (-4)) (m 4) (some Build.east)
    , strip 12 .lane (m (-4)) (m 4) (some Build.east) ]
    [ oneWaySign 1 [12] ] [10, 11, 12]

/-- `branch_3` (compliant): A divided highway carries two one-way roadways, one designated east and one designated west, each governed by its own one-way sign; the subject travels east at eight metres per second in the eastbound roadway, which it alone occupies. -/
def branch_3Trace : Trace :=
  traceOf (eastbound (m 50) (m 6) (ms 8))
    [ way20, strip 11 .oneWayRoadway (m 2) (m 10) (some Build.east)
    , strip 12 .oneWayRoadway (m (-10)) (m (-2)) (some Build.west) ]
    [ oneWaySign 1 [11], oneWaySign 2 [12] ] [10, 11]

/-- `branch_4` (violated): A one-way sign's control is recorded at the intersection on an eastbound one-way highway and nowhere else. The subject travels west at five metres per second through that junction, its footprint overlapping the junction and the eastbound one-way roadway together. -/
def branch_4Trace : Trace :=
  traceOf (westbound (m 100) (m 0) (ms 5)) [way14, eastRoadway, junction]
    [ oneWaySign 1 [13] ] [10, 11, 13]

/-- `branch_5` (compliant): A signposted one-way highway bends back on itself, so one limb's roadway is designated east and a remote limb's roadway is designated west. The subject travels east at two metres per second on the shoulder beside the eastbound limb, whose designated direction is east; it occupies neither roadway, and the remote limb lies twenty metres away. -/
def branch_5Trace : Trace :=
  traceOf (eastbound (m 50) (m 10) (ms 2))
    [ way40, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .oneWayRoadway (m (-30)) (m (-22)) (some Build.west)
    , strip 13 .shoulder (m 8) (m 12) (some Build.east) (some true) ]
    [ oneWaySign 1 [11] ] [10, 13]

/-- `branch_6` (violated): A highway is designated and signposted for eastbound one-way traffic, its sole one-way roadway designated east and the one-way sign's control recorded at that roadway. The subject is driven west at four metres per second along the sidewalk lying on that highway, the source recording its footprint against the highway region and that sidewalk and against no part of the way that carries a designation of its own. -/
def branch_6Trace : Trace :=
  traceOf (westbound (m 50) (m 11) (ms 4))
    [ way14, eastRoadway, strip 12 .sidewalk (m 9) (m 13) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_7` (compliant): On the same eastbound signposted one-way highway the subject is driven east at four metres per second along the sidewalk, the source again recording its footprint against the highway region and the sidewalk alone. -/
def branch_7Trace : Trace :=
  traceOf (eastbound (m 50) (m 11) (ms 4))
    [ way14, eastRoadway, strip 12 .sidewalk (m 9) (m 13) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_8` (compliant): A signposted one-way highway carries two one-way roadways, one designated east and one designated west, both lying on it and the one-way sign's control recorded at the eastbound one. The subject is driven west at four metres per second along the sidewalk of that highway, occupying neither roadway nor any other part carrying a designation: it travels along the direction designated for the westbound one-way roadway of that way. -/
def branch_8Trace : Trace :=
  traceOf (westbound (m 50) (m 11) (ms 4))
    [ way24, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .oneWayRoadway (m (-16)) (m (-8)) (some Build.west)
    , strip 13 .sidewalk (m 9) (m 13) ]
    [ oneWaySign 1 [11] ] [10, 13]

/-- `branch_9` (violated): On an eastbound signposted one-way highway whose sole one-way roadway is designated east, the source records the subject's footprint against the highway region itself and against no part of it, as the subject travels west at six metres per second. -/
def branch_9Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6)) [way14, eastRoadway] [oneWaySign 1 [11]] [10]

/-- `branch_10` (violated): the same eastbound signposted one-way roadway as `forbid`, but the
    source records the subject's footprint against that roadway alone and not against the highway
    region: the subject is upon the way through the part of it it is driven on, and travels west. -/
def branch_10Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6)) [way14, eastRoadway] [oneWaySign 1 [11]] [11]

/-- `branch_11` (violated): the sole lane of an eastbound one-way roadway, the one-way sign's
    control recorded at the roadway; the source records the subject's footprint against that lane
    alone, and the subject travels west along it at six metres per second. -/
def branch_11Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6))
    [ way14, strip 11 .oneWayRoadway (m (-4)) (m 4) (some Build.east)
    , strip 12 .lane (m (-4)) (m 4) (some Build.east) ]
    [ oneWaySign 1 [11] ] [12]

/-- `branch_12` (violated): as `branch_1`, the eastbound paved shoulder of a signposted one-way
    highway, but the source records the subject's footprint against that shoulder alone; it travels
    west along it at six metres per second. -/
def branch_12Trace : Trace :=
  traceOf (westbound (m 50) (m 10) (ms 6))
    [ way14, eastRoadway, strip 12 .shoulder (m 8) (m 12) (some Build.east) (some true) ]
    [ oneWaySign 1 [11] ] [12]

/-- `branch_13` (violated): as `branch_6`, the sidewalk of an eastbound signposted one-way highway,
    but the source records the subject's footprint against that sidewalk alone: it is upon the way
    through its sidewalk, and travels west at four metres per second against the direction the way's
    one-way roadway designates. -/
def branch_13Trace : Trace :=
  traceOf (westbound (m 50) (m 11) (ms 4))
    [ way14, eastRoadway, strip 12 .sidewalk (m 9) (m 13) ]
    [ oneWaySign 1 [11] ] [12]

/-- `branch_14` (violated): a bicycle lane lying on an eastbound signposted one-way highway and
    designated east; the subject is driven west along it at six metres per second, its footprint
    recorded against the highway region and that bicycle lane and never the roadway. -/
def branch_14Trace : Trace :=
  traceOf (westbound (m 50) (cm 950) (ms 6))
    [ way14, eastRoadway, strip 12 .bicycleLaneOrPath (m 8) (m 11) (some Build.east) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_15` (violated): the junction on an eastbound signposted one-way highway, the sign's
    control recorded at the roadway; the source records the subject's footprint against that
    junction alone, which carries no designation of its own, and the subject travels west through it
    at six metres per second, against the direction the way's one-way roadway designates. -/
def branch_15Trace : Trace :=
  traceOf (westbound (m 100) (m 0) (ms 6)) [way14, eastRoadway, junction]
    [ oneWaySign 1 [11] ] [13]

/-- `branch_16` (violated): the one-way sign's observed control is recorded at the paved shoulder of
    the way and nowhere else; the subject travels west at six metres per second on the eastbound
    one-way roadway of that signposted way. -/
def branch_16Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6))
    [ way14, eastRoadway, strip 12 .shoulder (m 8) (m 12) (some Build.east) (some true) ]
    [ oneWaySign 1 [12] ] [10, 11]

/-- `branch_17` (violated): the one-way sign's observed control is recorded at the bicycle lane of
    the way and nowhere else; the subject travels west at six metres per second on the eastbound
    one-way roadway of that signposted way. -/
def branch_17Trace : Trace :=
  traceOf (westbound (m 50) (m 0) (ms 6))
    [ way14, eastRoadway, strip 12 .bicycleLaneOrPath (m 8) (m 11) (some Build.east) ]
    [ oneWaySign 1 [12] ] [10, 11]

/-- `branch_18` (compliant): a signposted one-way highway whose one-way roadway is designated east;
    a further roadway of that way, a remote limb of it, is designated west, and the subject travels
    west along that roadway at six metres per second. The designation of the roadway driven upon
    binds, and the eastbound designation of the way's one-way roadway does not. -/
def branch_18Trace : Trace :=
  traceOf (westbound (m 50) (m (-12)) (ms 6))
    [ way24, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .roadway (m (-16)) (m (-8)) (some Build.west) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_19` (compliant): the same way, the remote limb being a lane designated west; the subject
    travels west along that lane at six metres per second, and the lane's own designation binds. -/
def branch_19Trace : Trace :=
  traceOf (westbound (m 50) (m (-12)) (ms 6))
    [ way24, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .lane (m (-16)) (m (-8)) (some Build.west) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_20` (compliant): the same way, the remote limb being a paved shoulder designated west;
    the subject travels west along that shoulder at six metres per second, and the shoulder's own
    designation binds rather than the eastbound designation of the way's one-way roadway. -/
def branch_20Trace : Trace :=
  traceOf (westbound (m 50) (m (-12)) (ms 6))
    [ way24, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .shoulder (m (-16)) (m (-8)) (some Build.west) (some true) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_21` (compliant): the same way, the remote limb being a bicycle lane designated west; the
    subject travels west along that bicycle lane at six metres per second, and its designation
    binds. -/
def branch_21Trace : Trace :=
  traceOf (westbound (m 50) (m (-12)) (ms 6))
    [ way24, strip 11 .oneWayRoadway (m 0) (m 8) (some Build.east)
    , strip 12 .bicycleLaneOrPath (m (-16)) (m (-8)) (some Build.west) ]
    [ oneWaySign 1 [11] ] [10, 12]

/-- `branch_22` (violated): as `branch_14`, a bicycle lane designated east lying on an eastbound
    signposted one-way highway, but the source records the subject's footprint against that bicycle
    lane alone: it is upon the way through the path it is driven on, and travels west along it at six
    metres per second. -/
def branch_22Trace : Trace :=
  traceOf (westbound (m 50) (cm 950) (ms 6))
    [ way14, eastRoadway, strip 12 .bicycleLaneOrPath (m 8) (m 11) (some Build.east) ]
    [ oneWaySign 1 [11] ] [12]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_220_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated
  , witness "branch_15" branch_15Trace .violated
  , witness "branch_16" branch_16Trace .violated
  , witness "branch_17" branch_17Trace .violated
  , witness "branch_18" branch_18Trace .compliant
  , witness "branch_19" branch_19Trace .compliant
  , witness "branch_20" branch_20Trace .compliant
  , witness "branch_21" branch_21Trace .compliant
  , witness "branch_22" branch_22Trace .violated ]

end TrafficSpecWitness.NRS_484B_220_1

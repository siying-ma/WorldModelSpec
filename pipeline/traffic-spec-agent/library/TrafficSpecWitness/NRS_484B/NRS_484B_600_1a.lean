/-
  Witnesses for NRS_484B_600_1a.

  The geometry. One straight way running east: the highway region 10, a rectangle 600 m long and
  28 m wide; on it the roadway region 11 (16 m wide), which carries the curvature and the grade
  each scene gives it; and in the roadway a lane region 12 of the width each scene gives it
  (3.6 m where the way is of full width, 7 m where it is unusually wide, 2 m where it is narrow),
  with a second lane region 13 where a scene needs one. The parking bay, region 20, lies clear of
  the highway polygon, between y = 16 m and y = 19 m, for the scene in which the subject stands off
  the public way.

  The subject is track 1, a motor vehicle 4 m long and 2 m wide, travelling east along its lane and
  advancing at its own speed between observations; every scene gives it the distance it can see
  along way 10. The other road users are track 2: a motor vehicle of the same size, or a pedestrian
  0.6 m by 0.6 m.

  The margins, against the run's reading (baseline 24.6 m/s; wet 0.8, ice 0.5, precipitation 0.85
  and darkness 0.8 of it; 3.6 m reference lane width; 4 s sight time; 2 s headway; 3 m/s² lateral
  acceleration; downgrade sensitivity 2): a scene that breaks one factor breaks that one alone and
  keeps every other by a clear margin, so that each factor of the standard decides a verdict
  somewhere. 15 m/s and 22 m/s are the two speeds below the baseline, 25 m/s the one above it;
  1 m/s is walking pace and 5 m/s a crawl. Every figure here is the witness's own and appears
  nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def ms (n : Int) : Q := Units.metresPerSecond n
def oneSecond : Q := Units.seconds 1
def fifthSecond : Q := Units.milliseconds 200

-- Binders ↦ tracks: v ↦ 1

/-- The curvature of a bend of radius `r` metres. -/
def bendOfRadius (r : Int) : Q := Q.div (Units.perMetre 1) (Units.metres r)
def straight : Q := Units.perMetre 0
def level : Q := Units.percent 0

/-- The way: the whole public way between its boundary lines. -/
def way : Structure := Build.rect 10 .highway (m 0) (m (-14)) (m 600) (m 14)

/-- The roadway of that way, with the curvature and grade of the scene. -/
def carriageway (curv grd : Q) : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-8)) (m 600) (m 8) with
      curvature := some curv, grade := some grd }

/-- A lane of that roadway, running east, of the given width. -/
def laneOf (id : RegionId) (y0 y1 width : Q) : Structure :=
  { Build.lane id [(m 0, y0), (m 600, y0), (m 600, y1), (m 0, y1)] Build.east with
      lane := some { direction := some Build.east, width := some width } }

/-- A lane of the reference width. -/
def fullLane : Structure := laneOf 12 (m 0) (cm 360) (cm 360)
/-- An unusually wide lane. -/
def wideLane : Structure := laneOf 12 (m 0) (m 7) (m 7)
/-- A lane narrower than the reference width. -/
def narrowLane : Structure := laneOf 12 (m 0) (m 2) (m 2)
/-- The lane beside `fullLane`, to its left. -/
def nextLane : Structure := laneOf 13 (cm 360) (m 6) (cm 240)
/-- A marked bay clear of the public way. -/
def bay : Structure := Build.rect 20 .parkingSpace (m 40) (m 16) (m 46) (m 19)

/-- The subject: a motor vehicle running east, with the distance it can see along way 10. -/
def subjectAt (x y speed sight : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (x, y) Build.east speed (m 2, m 1, m 1) with
      sightAlongWay := some [(10, sight)] }

/-- Another motor vehicle of the same size. -/
def vehicleAt (track : TrackId) (x y speed : Q) (heading : Vec) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading speed (m 2, m 1, m 1)

/-- A pedestrian walking east. -/
def walkerAt (track : TrackId) (x y speed : Q) : RoadUser :=
  Build.user track [.pedestrian] (x, y) Build.east speed (cm 30, cm 30, cm 90)

/-- Where a body that started at `x0` and has run at `speed` for `k` steps of `dt` stands. -/
def along (x0 speed dt : Q) (k : Nat) : Q :=
  Q.add x0 (Q.mul speed (Q.mul dt (Q.ofInt (Int.ofNat k))))

/-- The conditions of a scene: the light, the falling weather, the surface and what can be seen. -/
def weather (dark precip wet ice : Bool) (vis : Q) : Env :=
  { darkness := some dark, precipitation := some precip, wetRoad := some wet,
    iceOrSnow := some ice, visibility := some vis }

def clearDay : Env := weather false false false false (m 400)
def foggyDay : Env := weather false false false false (m 40)
def night : Env := weather true false false false (m 400)
def rainOnWetRoad : Env := weather false true true false (m 200)
def rainOnly : Env := weather false true false false (m 400)
def wetOnly : Env := weather false false true false (m 400)
def packedSnow : Env := weather false false false true (m 400)

/-- `forbid` (violated): Rain is falling and the road surface is wet; the subject travels a tightening bend of the roadway at a speed whose square is well above the lateral-acceleration bound for that curvature, and above the wet and precipitation scalings of the baseline as well. -/
def forbidTrace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 25) oneSecond k) (cm 180) (ms 25) (m 200) ]
      [ way, carriageway (bendOfRadius 50) level, fullLane ]
      [ ]
      (env := rainOnWetRoad)

/-- `permit` (compliant): Dry surface, no precipitation, daylight, a straight stretch of full lane width with long sight distance, and no other road user anywhere in the scene; the subject's speed is well below the baseline and below every factor bound, so the verdict is decided with no other party present. -/
def permitTrace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

/-- `idle` (not_applicable): The subject stands at rest in a marked bay off the public way: its footprint overlaps no highway region and its speed is zero, so it is not a vehicle in controlled motion on a highway and the node does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 oneSecond fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 43) (cm 1750) (ms 0) (m 400) ]
      [ way, carriageway straight level, fullLane, bay ]
      [ ]
      (env := clearDay)

/-- `blind` (unknown): The subject is moving on a highway in clear conditions, but the source does not observe speed for it, so no bound can be compared with anything. -/
def blindTrace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_1` (violated): Dry, straight, wide road in daylight, but a stopped vehicle stands clear ahead of the subject in its own lane, a positive longitudinal gap between the two bodies; the subject's speed exceeds that gap divided by the headway time. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 fifthSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 5) fifthSecond k) (cm 180) (ms 5) (m 400)
      , vehicleAt 2 (m 60) (cm 180) (ms 0) Build.east ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_2` (compliant): The roadway is covered in packed snow and the subject crawls along it, below the icy-surface scaling of the baseline and below every other factor bound. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 5) oneSecond k) (cm 180) (ms 5) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := packedSnow)

/-- `branch_3` (compliant): A pedestrian walks in the same direction abeam of the subject in an unusually wide lane, some three metres laterally clear, their bodies just meeting along the lane axis so that the longitudinal gap is zero; the way is dry, clear, straight, level and of ample width and the subject moves at walking pace, so no headway is owed and every other factor bound is kept. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 1) oneSecond k) (cm 150) (ms 1) (m 400)
      , walkerAt 2 (along (cm 5230) (ms 1) oneSecond k) (cm 580) (ms 1) ]
      [ way, carriageway straight level, wideLane ]
      [ ]
      (env := clearDay)

/-- `branch_4` (compliant): Two vehicles travel abreast at walking pace in one lane of a dry, clear, straight, level way, their bodies overlapping along the lane axis so that the longitudinal gap between them is negative; the subject is below every factor bound and the overlapping road user leaves no clear length ahead to measure. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 1) oneSecond k) (cm 150) (ms 1) (m 400)
      , vehicleAt 2 (along (m 51) (ms 1) oneSecond k) (m 5) (ms 1) Build.east ]
      [ way, carriageway straight level, wideLane ]
      [ ]
      (env := clearDay)

/-- `branch_5` (compliant): A vehicle follows close behind the subject in its own lane on a dry, clear, straight, level way of full width, a positive longitudinal gap between them but the follower bearing astern of the subject; the subject travels below the baseline and below every other factor bound, and the road user behind it bounds nothing. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400)
      , vehicleAt 2 (along (m 30) (ms 15) oneSecond k) (cm 180) (ms 15) Build.east ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_6` (compliant): a vehicle stands in the subject's own lane well behind it but turned
    about, facing the subject: it is ahead of the subject along its own heading, and a positive
    longitudinal gap stands between the bodies, yet its bearing in the subject's frame is astern,
    so it is not traffic clear ahead and bounds nothing. The subject is below every other bound. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400)
      , vehicleAt 2 (m 30) (cm 180) (ms 0) Build.west ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_7` (compliant): a stopped vehicle stands close ahead of the subject and bearing ahead
    of it, but in the lane beside the subject's, so the two share no lane: the headway the gap
    would demand is well below the subject's speed, and yet no headway is owed. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 fifthSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) fifthSecond k) (cm 180) (ms 15) (m 400)
      , vehicleAt 2 (m 62) (cm 480) (ms 0) Build.east ]
      [ way, carriageway straight level, fullLane, nextLane ]
      [ ]
      (env := clearDay)

/-- `branch_8` (violated): night on a dry, clear, straight, level way of full lane width with long
    sight distance; the subject travels below the baseline but above its darkness scaling. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 22) oneSecond k) (cm 180) (ms 22) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := night)

/-- `branch_9` (violated): rain falls on a road whose surface the source reports dry, the way
    otherwise clear, straight, level and of full width; the subject is below the baseline but above
    its precipitation scaling. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 22) oneSecond k) (cm 180) (ms 22) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := rainOnly)

/-- `branch_10` (violated): the surface is wet with no precipitation falling, the way otherwise
    clear, straight, level and of full width; the subject is below the baseline but above its
    wet-surface scaling. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 22) oneSecond k) (cm 180) (ms 22) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := wetOnly)

/-- `branch_11` (violated): the same packed snow as `branch_2`, but the subject travels at a speed
    above the icy-surface scaling of the baseline and below every other bound. -/
def branch_11Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := packedSnow)

/-- `branch_12` (violated): a dry, clear, straight, level way whose lane is far narrower than the
    reference width; the subject is below the baseline but above the width's scaling of it. -/
def branch_12Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (m 1) (ms 15) (m 400) ]
      [ way, carriageway straight level, narrowLane ]
      [ ]
      (env := clearDay)

/-- `branch_13` (violated): a dry, clear, straight way of full lane width descending a one-in-ten
    grade; the subject is below the baseline but above what the downgrade leaves of it. -/
def branch_13Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 22) oneSecond k) (cm 180) (ms 22) (m 400) ]
      [ way, carriageway straight (Units.percent (-10)), fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_14` (violated): a dry, clear, level way of full lane width bending through a radius of
    100 m; the subject is below the baseline but the square of its speed times that curvature is
    above the lateral acceleration. -/
def branch_14Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 20) oneSecond k) (cm 180) (ms 20) (m 400) ]
      [ way, carriageway (bendOfRadius 100) level, fullLane ]
      [ ]
      (env := clearDay)

/-- `branch_15` (violated): fog shortens the visibility to 40 m on a dry, straight, level way of
    full lane width along which the subject can still be told it sees 400 m; the subject is below
    the baseline but above the assured clear distance the visibility leaves. -/
def branch_15Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 400) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := foggyDay)

/-- `branch_16` (violated): a dry, clear, straight, level way of full lane width on which the
    subject can see only 40 m along the way; the subject is below the baseline but above the
    assured clear distance that sight leaves. -/
def branch_16Trace : Trace :=
  Build.trace 3 0 oneSecond fun k t =>
    Build.scene t (some 1)
      [ subjectAt (along (m 50) (ms 15) oneSecond k) (cm 180) (ms 15) (m 40) ]
      [ way, carriageway straight level, fullLane ]
      [ ]
      (env := clearDay)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated
  , witness "branch_15" branch_15Trace .violated
  , witness "branch_16" branch_16Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a

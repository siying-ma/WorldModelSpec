/-
  Witnesses for NRS_484B_600_1a.

  The map is the same straight east–west stretch in every witness, 400 m long: a highway region
  (id 1) 20 m wide between its boundary lines, the roadway of that highway (id 2) 14 m wide, which
  carries the slope and the sight distance of the place and lies on the way, and the eastbound lane
  the subject runs in (id 3), whose polygon is as wide as the width it records and which lies on the
  same way. The `forbid` witness adds the opposing lane (id 4), so that its stretch is the two-lane
  highway of the narrative; the subject's footprint never reaches it, so the subject occupies one
  lane in every witness.

  The subject is track 1: a motor vehicle 5 m long and 1.8 m wide, running in the middle of its
  lane at x = 100 m. Other road users are motor vehicles of the same body, in file behind it on the
  same lane at 20 m spacing, so each of them lies on the highway region the subject occupies and
  each lowers the bound by the per-user traffic decrement. Occupancy is derived from the geometry:
  every body lies wholly inside its lane, the roadway and the highway and touches nothing else.

  Each trace is three instants a second apart, the scene unchanged, so the episode verdict is the
  verdict at any one of them; no formula of this rule looks back, so no witness names a window.

  Every figure here is the witness's own and appears nowhere in the rule. The margins are measured
  against the run's reading: a base limit of 29 m/s, decrements of 2.8 m/s (wet or precipitation),
  8 m/s (ice or snow) and 0.5 m/s per road user, a grade decrement of 30 m/s per unit of slope, a
  lateral-recovery time of 0.12 s and a stopping time of 2.5 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def kmh (n : Int) : Q := Units.kmh n
def umps (n : Int) : Q := Units.micrometresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width and half-height of every body in these scenes: a 5 m × 1.8 m car. -/
def carBody : Q × Q × Q := (cm 250, cm 90, cm 80)

/-- The public way between its boundary lines. -/
def highway : Structure := Build.rect 1 .highway (m 0) (m (-10)) (m 400) (m 10)

/-- The roadway of that highway, with the slope and the sight distance of the place. -/
def roadway (grade sight : Q) : Structure :=
  { Build.rect 2 .roadway (m 0) (m (-7)) (m 400) (m 7) with
      grade := some grade
      sightDistance := some sight
      ways := some [1] }

/-- The eastbound lane the subject runs in: a strip as wide as the width it records. -/
def runningLane (width : Q) : Structure :=
  { Build.rect 3 .lane (m 0) (cm 20) (m 400) (Q.add (cm 20) width) with
      lane := some { direction := some Build.east, width := some width }
      ways := some [1] }

/-- The opposing lane of the two-lane stretch, which no witness's subject occupies. -/
def opposingLane : Structure :=
  { Build.rect 4 .lane (m 0) (m (-4)) (m 400) (cm (-40)) with
      lane := some { direction := some Build.west, width := some (cm 360) }
      ways := some [1] }

/-- The middle of the running lane of that width. -/
def laneCentre (width : Q) : Q := Q.add (cm 20) (Q.half width)

/-- The subject, in the middle of its lane at x = 100 m. -/
def subject (speed width : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 100, laneCentre width) Build.east speed carBody

/-- Another road user of the stream, in file behind the subject on the same lane. -/
def follower (track : TrackId) (x width : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, laneCentre width) Build.east (mps 20) carBody

/-- The first `n` followers, 20 m apart, the nearest 20 m behind the subject. -/
def followers (n : Nat) (width : Q) : List RoadUser :=
  (List.range n).map fun k => follower (2 + k) (m (120 + 20 * (k : Int))) width

/-- A dry, snow-free surface with no precipitation, and the visibility the source records. -/
def dry (visibility : Q) : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false
    visibility := some visibility }

/-- A wet surface, with no precipitation falling and no ice. -/
def wet (visibility : Q) : Env :=
  { precipitation := some false, wetRoad := some true, iceOrSnow := some false
    visibility := some visibility }

/-- Rain falling on a surface the source records as not yet wet. -/
def raining (visibility : Q) : Env :=
  { precipitation := some true, wetRoad := some false, iceOrSnow := some false
    visibility := some visibility }

/-- An icy or snow-covered surface, dry of standing water. -/
def icy (visibility : Q) : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some true
    visibility := some visibility }

/-- One instant of the stretch: the bodies, the recorded lane width, the slope and sight distance
    of the place, the weather, and whether the opposing lane is mapped. -/
def stretch (t : Timestamp) (users : List RoadUser) (width grade sight : Q) (env : Env)
    (twoLane : Bool := false) : Scene :=
  Build.scene t (some 1) users
    ([highway, roadway grade sight, runningLane width] ++ (if twoLane then [opposingLane] else []))
    [] (env := env)

/-- Three instants a second apart of one unchanged scene. -/
def still (f : Timestamp → Scene) : Trace := Build.trace 3 0 (Units.seconds 1) fun _k t => f t

/-- `forbid` (violated): On a wet two-lane highway with a short sight distance at the subject's place and a file of other road users on the same way, the subject runs at a speed far above the base limit, let alone the lowered bound and the sight-derived bounds. -/
-- Wet (−2.8) and five road users on the way (−2.5) lower the bound to 23.7 m/s; the subject runs
-- at 40 m/s, which also needs 100 m of sight where the place has 60 m.
def forbidTrace : Trace :=
  still fun t =>
    stretch t (subject (mps 40) (cm 360) :: followers 4 (cm 360))
      (cm 360) Q.zero (m 60) (wet (m 300)) true

/-- `permit` (compliant): A dry, level, wide stretch with a long sight distance, good visibility and no other road user in the scene; the subject runs at a speed well below the base limit and below every sight- and width-derived bound. -/
-- The bound is 28.5 m/s (the subject is the only road user on the way); 20 m/s needs 50 m of sight
-- against 300 m, and 2.4 m of lane against 3.6 m.
def permitTrace : Trace :=
  still fun t =>
    stretch t [subject (mps 20) (cm 360)] (cm 360) Q.zero (m 300) (dry (m 1000))

/-- `idle` (not_applicable): The subject stands at the kerb with its engine running, the magnitude of its velocity within the standstill tolerance, so it is not driven or operated and the duty does not arise. -/
-- 0.05 m/s is within the standstill tolerance of 0.1 m/s, so the subject is not driven; it stands
-- on the roadway clear of the running lane, at the edge of the way.
def idleTrace : Trace :=
  still fun t =>
    stretch t
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 100, cm 550) Build.east (umps 50000) carBody)
          fun k => { k with engineRunning := some true } ]
      (cm 360) Q.zero (m 300) (dry (m 1000))

/-- `blind` (unknown): The subject runs on a dry, level, wide stretch at a speed below the base limit, the traffic count and the place's sight distance recorded, but the source declares the visibility distance absent, so whether the visibility-derived bound is exceeded cannot be told. -/
-- Every other bound is kept by a margin at 20 m/s; only the visibility-derived bound is open.
def blindTrace : Trace :=
  still fun t =>
    stretch t [subject (mps 20) (cm 360)] (cm 360) Q.zero (m 200) (dry (m 1000))

/-- `branch_1` (violated): A dry, level, straight stretch with a long sight distance and no other road user in the scene, but the lane the subject occupies is a narrow one: the subject's speed exceeds the lane's width divided by the lateral-recovery time while staying below the base limit. -/
-- 25 m/s is below the bound of 28.5 m/s and needs 62.5 m of sight against 300 m, but 25 × 0.12 =
-- 3 m of lane against the 2.5 m the lane records.
def branch_1Trace : Trace :=
  still fun t =>
    stretch t [subject (mps 25) (cm 250)] (cm 250) Q.zero (m 300) (dry (m 1000))

/-- `branch_2` (violated): A dry stretch running down a steep grade with no other road user present; the subject's speed stays below the base limit but above that limit lowered by the grade decrement times the magnitude of the slope at its place. -/
-- A downgrade of 8% costs 2.4 m/s, so the bound is 26.1 m/s and the subject runs at 27 m/s; the
-- sight- and width-derived bounds are kept.
def branch_2Trace : Trace :=
  still fun t =>
    stretch t [subject (mps 27) (cm 360)] (cm 360) (Units.percent (-8)) (m 300) (dry (m 1000))

/-- `branch_3` (violated): rain falling on a surface the source does not record as wet; the
    wet-pavement decrement applies through the precipitation limb, and the subject's 27.5 m/s
    exceeds the lowered bound of 25.7 m/s while every other bound is kept. -/
def branch_3Trace : Trace :=
  still fun t =>
    stretch t [subject (kmh 99) (cm 360)] (cm 360) Q.zero (m 300) (raining (m 1000))

/-- `branch_4` (violated): an icy surface, dry of standing water; the winter-surface decrement
    lowers the bound to 20.5 m/s and the subject runs at 22 m/s, every other bound kept. -/
def branch_4Trace : Trace :=
  still fun t =>
    stretch t [subject (mps 22) (cm 360)] (cm 360) Q.zero (m 300) (icy (m 1000))

/-- `branch_5` (violated): a dry, level, wide stretch with a long sight distance, but a thick
    stream: the subject and six other road users on the way lower the bound to 25.5 m/s, and the
    subject runs at 27 m/s. -/
def branch_5Trace : Trace :=
  still fun t =>
    stretch t (subject (mps 27) (cm 360) :: followers 6 (cm 360))
      (cm 360) Q.zero (m 300) (dry (m 1000))

/-- `branch_6` (violated): fog cuts the visibility distance to 50 m on a stretch whose own sight
    distance is 300 m; at 25 m/s the subject needs 62.5 m of sight, so the visibility-derived bound
    alone is broken. -/
def branch_6Trace : Trace :=
  still fun t =>
    stretch t [subject (mps 25) (cm 360)] (cm 360) Q.zero (m 300) (dry (m 50))

/-- `branch_7` (violated): clear air but a blind place: the sight distance of the subject's place is
    50 m where 25 m/s needs 62.5 m, so the sight-derived bound alone is broken. -/
def branch_7Trace : Trace :=
  still fun t =>
    stretch t [subject (mps 25) (cm 360)] (cm 360) Q.zero (m 50) (dry (m 1000))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
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
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a

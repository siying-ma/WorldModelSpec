/-
  Witnesses for NRS_484B_407.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - The road runs east–west; each roadway region is a rectangle spanning y ∈ [−12, 12] m and a
    stretch of x. A bend carries curvature 1/200 per metre (a 200 m radius, ten times the map
    resolution); a straight stretch carries curvature zero. Sight distances are set per region.
  - Track 1, a motor vehicle (half-length 2 m, half-width 1 m), is sampled every second over
    23 instants (t = 0 … 22 s). Up to t = 11 s it drives east at 10 m/s along y = −8 m, reaching
    (0, −8) at t = 11 s, with zero yaw rate. From t = 12 s to t = 17 s it reverses to the left at
    30 °/s (six samples, 180° in all), through (12, −7), (20, −4.5), (24, 0), (20, 4.5), (12, 7)
    to (0, 8) heading west; from t = 18 s it drives west at 10 m/s with zero yaw rate. The
    reversal is recognized at t = 18 s (180° over the 10 s window behind, yaw rate zero there).
  - Every witness names the instants t = 11 … 22 s, where the 10 s window behind is covered.
  - In the occasion layouts the change of region lies at x = 15 m: the first turning sample
    (t = 12 s, body up to x = 14.2 m) and the last (t = 16 s, 17 s) lie short of it, the middle of
    the turn (t = 13–15 s, body from x = 18.1 m) beyond it. In the "outside" layouts the change lies
    at x = −40 m, which the subject passes at t = 7 s, five seconds before the turn begins, and
    re-crosses westbound at t = 21 s, after it ended.
  - The crest (occasion_s4) spans x ∈ [168, 188] m: 153.8 m from the body at t = 12 s, 146.1 m at
    t = 13 s, 143 m at t = 14 s. In occasion_s4_outside it spans x ∈ [−200, −180] m, within 70 m
    of the body before the turn and at least 178 m from it during the turn.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_407
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_407

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def rt (a : Int) (b : Nat) : Q := Units.ratio a b

-- Binders ↦ tracks: subject ↦ 1

/-- Heading of the reversing subject (direction only; length is not read). -/
def revHeading (k : Nat) : Vec :=
  if k ≤ 11 then Build.east
  else if k == 12 then (rt 87 100, rt 50 100)
  else if k == 13 then (rt 50 100, rt 87 100)
  else if k == 14 then Build.north
  else if k == 15 then (rt (-50) 100, rt 87 100)
  else if k == 16 then (rt (-87) 100, rt 50 100)
  else Build.west

def revYaw (k : Nat) : Q :=
  if 12 ≤ k ∧ k ≤ 17 then Units.degrees 30 else Q.zero

def revPos (k : Nat) : Vec :=
  if k ≤ 11 then (m (10 * ((k : Int) - 11)), m (-8))
  else if k == 12 then (m 12, m (-7))
  else if k == 13 then (m 20, cm (-450))
  else if k == 14 then (m 24, m 0)
  else if k == 15 then (m 20, cm 450)
  else if k == 16 then (m 12, m 7)
  else (m (-10 * ((k : Int) - 17)), m 8)

def revSpeed (k : Nat) : Q :=
  if 12 ≤ k ∧ k ≤ 17 then Units.metresPerSecond 8 else Units.metresPerSecond 10

def body : Q × Q × Q := (m 2, m 1, cm 75)

/-- The subject making the standard reversal. -/
def reverser (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (revPos k) (revHeading k) (revSpeed k) body)
    (fun kn => { kn with yawRate := some (revYaw k) })

/-- A roadway stretch from x0 to x1 with its curvature and sight distance. -/
def road (id : RegionId) (x0 x1 : Int) (curv sight : Q) : Structure :=
  { Build.rect id .roadway (m x0) (m (-12)) (m x1) (m 12) with
      curvature := some curv, sightDistance := some sight }

/-- A crest region from x0 to x1, with its reference point. -/
def crest (id : RegionId) (x0 x1 : Int) : Structure :=
  { Build.rect id .crest (m x0) (m (-12)) (m x1) (m 12) with
      position := some (m ((x0 + x1) / 2), m 0) }

def bend : Q := rt 1 200
def straight : Q := Q.zero

/-- The standard reversal over a map. -/
def reversalTrace (structs : List Structure) : Trace :=
  Build.trace 23 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reverser k] structs []

/-- `forbid` (violated): The subject vehicle on a roadway bend (curvature well above the resolution) where st.sight_distance is 100 m reverses its heading by about 180 degrees within 8 s, yaw rate observed. -/
def forbidTrace : Trace :=
  reversalTrace [road 10 (-300) 300 bend (m 100)]

/-- Heading of the subject following the bend: 6° more at each second from t = 12 s to 17 s. -/
def bendHeading (k : Nat) : Vec :=
  if k ≤ 11 then Build.east
  else if k == 12 then (rt 995 1000, rt 105 1000)
  else if k == 13 then (rt 978 1000, rt 208 1000)
  else if k == 14 then (rt 951 1000, rt 309 1000)
  else if k == 15 then (rt 914 1000, rt 407 1000)
  else if k == 16 then (rt 866 1000, rt 500 1000)
  else (rt 809 1000, rt 588 1000)

def bendYaw (k : Nat) : Q :=
  if 12 ≤ k ∧ k ≤ 17 then Units.degrees 6 else Q.zero

def bendPos (k : Nat) : Vec :=
  if k ≤ 11 then (m (10 * ((k : Int) - 11)), m (-8))
  else (m (10 * ((k : Int) - 11)), m (-8 + ((k : Int) - 11)))

def follower (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (bendPos k) (bendHeading k) (Units.metresPerSecond 10) body)
    (fun kn => { kn with yawRate := some (bendYaw k) })

/-- `permit` (compliant): On the same bend with st.sight_distance 80 m the subject drives through without reversing; no other road user in the scene.
    It follows the bend at 6 °/s for six seconds (36° in all), its yaw rate above the tolerance. -/
def permitTrace : Trace :=
  Build.trace 23 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [follower k] [road 10 (-300) 300 bend (m 80)] []

/-- `idle` (not_applicable): The subject reverses direction on a straight, level roadway (curvature at or below the resolution) with no crest within the reach and st.sight_distance 400 m. -/
def idleTrace : Trace :=
  reversalTrace [road 10 (-300) 300 straight (m 400)]

/-- `blind` (unknown): The subject reverses direction on a roadway bend; st.sight_distance is not observed on this source, so whether the condition holds is unknown. -/
def blindTrace : Trace :=
  reversalTrace [road 10 (-300) 300 bend (m 100)]

/-- `occasion_s3` (violated): The subject begins its reversal on a straight stretch and the second half of the turn takes place where the roadway curves; sight distance is 100 m throughout; no crest near.
    The bend begins at x = 15 m: the turn starts short of it and its middle (t = 13–15 s) lies on it. -/
def occasion_s3Trace : Trace :=
  reversalTrace [road 10 (-300) 15 straight (m 100), road 11 15 300 bend (m 100)]

/-- `occasion_s3_outside` (not_applicable): The subject is on the bend (sight distance 100 m) only before the reversal begins; it makes the whole reversal on the straight stretch beyond, where sight distance is 400 m; no crest near.
    On the bend it runs without turning (yaw rate zero). -/
def occasion_s3_outsideTrace : Trace :=
  reversalTrace [road 10 (-300) (-40) bend (m 100), road 11 (-40) 300 straight (m 400)]

/-- `occasion_s4` (violated): On a straight roadway the subject begins its reversal farther than the reach from a crest and ends it within the reach, where sight distance is 90 m. -/
def occasion_s4Trace : Trace :=
  reversalTrace [road 10 (-300) 300 straight (m 90), crest 20 168 188]

/-- `occasion_s4_outside` (not_applicable): The subject passes within the reach of a crest (sight 90 m) before the reversal begins and makes the whole reversal on a straight level stretch far beyond it, where sight distance is 400 m. -/
def occasion_s4_outsideTrace : Trace :=
  reversalTrace [road 10 (-300) (-40) straight (m 90), road 11 (-40) 300 straight (m 400),
                 crest 20 (-200) (-180)]

/-- `occasion_s5` (violated): On a bend the subject begins its reversal where sight distance is 200 m, and during the turn moves to where it is 120 m. -/
def occasion_s5Trace : Trace :=
  reversalTrace [road 10 (-300) 15 bend (m 200), road 11 15 300 bend (m 120)]

/-- `occasion_s5_outside` (not_applicable): On a bend the subject passes a spot where sight distance is 120 m before the reversal begins, then makes the whole reversal where sight distance is 250 m. -/
def occasion_s5_outsideTrace : Trace :=
  reversalTrace [road 10 (-300) (-40) bend (m 120), road 11 (-40) 300 bend (m 250)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_407"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (11000, 22000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s4" occasion_s4Trace .violated
  , witness "occasion_s4_outside" occasion_s4_outsideTrace .notApplicable
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_407

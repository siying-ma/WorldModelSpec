/-
  Witnesses for NRS_484B_407.

  One carriageway, built east-west in the world frame (+x east), 24 m wide so that a body turning
  about stays within it; every roadway segment is a rectangle of kind `roadway` carrying its own
  horizontal curvature and its own sight distance, so that "the curvature at the vehicle's
  position" and "the sight distance of the place it is at" are read off the region the vehicle
  occupies. A crest, where a scene needs one, is a ten-metre block of the same carriageway of kind
  `crest` with its reference point at its centre; where a scene needs no crest, one stands far down
  the road (x = 2000 m) so that the crest leaf is decided false rather than left unobserved.

  Magnitudes (all the witness's own; none appears in the rule):
    a bend          curvature 1/100 m⁻¹ (a 100 m radius), well inside the 500 m radius floor;
    a tangent       curvature 0, so the curve leaf is decided false;
    a blind place   sight distance 100 m, below the 500 feet (152.4 m) the text states;
    an open place   sight distance 300 m, above it;
    the body        a motor vehicle, half-extents 2 m × 0.9 m × 1.5 m;
    a turning about yaw rate 22.5 deg/s held over nine observations, so the heading change
                    integrated over the 8 s window behind is 180 deg at the end of the swing and
                    at least 157.5 deg on either side of it — inside the 30 deg tolerance;
    rounding a bend yaw rate 3 deg/s, 24 deg over the window: a bend taken, not a turning about.

  Every trace is sampled at 1 s, which is inside the 4 s adequacy limit of an 8 s window, and every
  trace holds its opening scene for the first nine observations so that the window behind is
  covered from t = 9 s. Each scenario names that range in `window`: the instants it speaks about
  are the ones at which the look-back is covered, and nothing is unknown there for want of trace.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_407
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_407

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of the body. -/
def halfExtent : Q × Q × Q := (m 2, cm 90, cm 150)

/-- 22.5 deg/s: nine observations of it integrate to a half turn over the 8 s window. -/
def turnRate : Q := Units.millidegrees 22500
/-- 3 deg/s: the yaw of a body following a 100 m bend at 5 m/s. -/
def bendRate : Q := Units.degrees 3

/-- The curvature of the bend (a 100 m radius) and of a tangent. -/
def kBend : Q := Units.ratio 1 100
def kTangent : Q := Q.zero
/-- Sight distances: one short of the 500 feet the text states, one well beyond. -/
def sightBlind : Q := m 100
def sightOpen : Q := m 300

/-- The subject: a motor vehicle with its position, heading, speed and yaw rate. -/
def car (pos : Vec) (heading : Vec) (speed yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed halfExtent)
    (fun k => { k with yawRate := some yaw })

/-- Nine headings from east round to west through north: the body's attitude through a swing. -/
def headingOfIndex : Nat → Vec
  | 0 => Build.east
  | 1 => (Q.mk' 92 100, Q.mk' 38 100)
  | 2 => (Q.mk' 71 100, Q.mk' 71 100)
  | 3 => (Q.mk' 38 100, Q.mk' 92 100)
  | 4 => Build.north
  | 5 => (Q.mk' (-38) 100, Q.mk' 92 100)
  | 6 => (Q.mk' (-71) 100, Q.mk' 71 100)
  | 7 => (Q.mk' (-92) 100, Q.mk' 38 100)
  | _ => Build.west

/-- The swing runs over the nine observations `lo … lo + 8`. -/
def swingYaw (k lo : Nat) : Q := if lo ≤ k ∧ k ≤ lo + 8 then turnRate else Q.zero
def swingHeading (k lo : Nat) : Vec :=
  headingOfIndex (if k ≤ lo then 0 else min (k - lo) 8)

/-- A body that holds `x0` until `lo`, moves `step` metres an observation, and holds from `hi`. -/
def rampX (x0 step : Int) (k lo hi : Nat) : Q :=
  m (x0 + step * Int.ofNat (min (max k lo) hi - lo))

/-- A stretch of carriageway with its own curvature and sight distance. -/
def roadSeg (id : RegionId) (x0 x1 : Int) (curv sight : Q) : Structure :=
  { Build.rect id .roadway (m x0) (m (-12)) (m x1) (m 12) with
      curvature := some curv, sightDistance := some sight }

/-- A crest: ten metres of the carriageway, with its reference point at its centre. -/
def crestRegion (id : RegionId) (x : Int) : Structure :=
  { Build.rect id .crest (m (x - 5)) (m (-12)) (m (x + 5)) (m 12) with
      position := some (m x, Q.zero) }

/-- The crest a scene keeps far away, so that the crest leaf is decided false. -/
def farCrest : Structure := crestRegion 9 2000

def sceneAt (t : Timestamp) (u : RoadUser) (rs : List Structure) : Scene :=
  Build.scene t (some 1) [u] rs []

/-- `forbid` (violated): A single vehicle on a two-lane rural roadway, with no other vehicle anywhere in the scene and no other road user at all; every atom is observed and the trace runs well before the window behind. The roadway's curvature at the vehicle's position stands well clear of the source's resolution, and the sight distance of that place is less than the distance the text states. Over the window behind, the vehicle's integrated heading change comes within the tolerance of a half turn, and its yaw rate stands above the floor at every observation of the swing, so the turning is under way upon that curve and at that restricted place. That the rule convicts with no second vehicle in the scene is what the place's sight distance, rather than another road user's line of sight, is read for. -/
def forbidRegions : List Structure := [ roadSeg 1 0 400 kBend sightBlind, farCrest ]

def forbidTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (m 200, Q.zero) (swingHeading k 10) (mps 2) (swingYaw k 10)) forbidRegions

/-- `permit` (compliant): The same vehicle on the same restricted stretch of curve, every atom observed and the window behind covered by the trace: it is upon the curve, and the sight distance of the place is less than the distance the text states, so the rule is engaged, but the vehicle holds its heading through and past the bend - its yaw rate never standing above the floor for a swing, and its integrated heading change never coming within the tolerance of a half turn at any observation of the trace - and turns about nowhere. -/
def permitTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX 100 5 k 0 23, Q.zero) (headingOfIndex (k / 8)) (mps 5) bendRate)
      forbidRegions

/-- `idle` (not_applicable): The same vehicle turns about on a straight and level stretch of the same roadway, every atom observed and the trace running well before the window behind: the curvature at its position is below the source's resolution at every observation, the nearest crest region lies farther from its body outline than the reach throughout, and the sight distance of the place exceeds the distance the text states, so no place condition holds while the turning is under way or at any other observation. -/
def idleRegions : List Structure := [ roadSeg 1 (-400) 400 kTangent sightOpen, farCrest ]

def idleTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (Q.zero, Q.zero) (swingHeading k 10) (mps 2) (swingYaw k 10)) idleRegions

/-- `blind` (unknown): The forbid scene - the vehicle upon a mapped curve whose curvature stands clear of the resolution, turning about within the tolerance of a half turn with its yaw rate above the floor - except that the source's manifest declares the sight distance of a place absent: it maps the road's horizontal geometry but carries no sight-distance model, so whether the vehicle could be seen from either direction within the stated distance is never decided, and the rule neither clears nor convicts. -/
def blindTrace : Trace := forbidTrace

/-- `occasion_s3` (violated): The turning begins on the straight approach, where the curvature is below the source's resolution, and carries on into the bend: at the later observations of the swing, with the yaw rate above the floor, the vehicle's position is upon the curve and the sight distance of that place is below the distance the text states. The curve condition holds for part of the act only, and that part is enough. -/
def s3Regions : List Structure :=
  [ roadSeg 1 (-400) 0 kTangent sightOpen, roadSeg 2 0 400 kBend sightBlind, farCrest ]

def occasion_s3Trace : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX (-30) 8 k 10 18, Q.zero) (swingHeading k 10) (mps 8) (swingYaw k 10))
      s3Regions

/-- `occasion_s3_outside` (compliant): The vehicle travels a restricted bend whose curvature stands clear of the resolution and whose sight distance is below the stated distance - so the rule is engaged there - then runs out onto a straight stretch, open in both directions and far from any crest, and only there turns about: at every observation of the swing the curvature is below the resolution, no crest lies within the reach, and the sight distance exceeds the stated distance. The curve condition held only before the act began. -/
def s3OutRegions : List Structure :=
  [ roadSeg 1 (-400) 0 kBend sightBlind, roadSeg 2 0 400 kTangent sightOpen, farCrest ]

def occasion_s3_outsideTrace : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX (-110) 20 k 9 15, Q.zero) (swingHeading k 15) (mps 20) (swingYaw k 15))
      s3OutRegions

/-- `occasion_s5` (violated): The vehicle begins to turn about on open straight road beyond the reach of the crest region and backs and fills its way round, drifting toward the hill: at the later observations of the swing, with the yaw rate above the floor, the ground distance from its body outline to the crest region has fallen to within the reach and the sight distance of the place is below the stated distance. The crest condition holds for part of the act only. -/
def s5Regions : List Structure :=
  [ roadSeg 1 (-400) 400 kTangent sightBlind, crestRegion 2 300 ]

def occasion_s5Trace : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX 60 20 k 10 18, Q.zero) (swingHeading k 10) (mps 20) (swingYaw k 10))
      s5Regions

/-- `occasion_s5_outside` (compliant): The vehicle climbs to within the reach of the crest region, where the sight distance is below the stated distance, so the rule is engaged there; it goes over and on down the far side until the crest region lies farther from its body outline than the reach and the road ahead and behind is open, and turns about there, on a stretch whose curvature is below the source's resolution. The crest condition held only before the act began. -/
def s5OutRegions : List Structure :=
  [ roadSeg 1 (-400) 420 kTangent sightBlind, roadSeg 2 420 1000 kTangent sightOpen,
    crestRegion 3 300 ]

def occasion_s5_outsideTrace : Trace :=
  Build.trace 34 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX 250 25 k 9 19, Q.zero) (swingHeading k 20) (mps 25) (swingYaw k 20))
      s5OutRegions

/-- `occasion_s6` (violated): The whole turning is made upon one long bend whose curvature stands clear of the resolution. The sight distance of the place changes along it: at the first observations of the swing it exceeds the distance the text states, and at the later ones, as the vehicle works round toward the blind part of the bend, it falls below it while the yaw rate is still above the floor. The sight condition holds for part of the act only, and at the same moments as the curve condition it is joined to. -/
def s6Regions : List Structure :=
  [ roadSeg 1 (-400) 0 kBend sightOpen, roadSeg 2 0 400 kBend sightBlind, farCrest ]

def occasion_s6Trace : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX (-30) 8 k 10 18, Q.zero) (swingHeading k 10) (mps 8) (swingYaw k 10))
      s6Regions

/-- `occasion_s6_outside` (compliant): The vehicle stands on a part of the same bend where the sight distance is below the distance the text states, then goes on round to the open part of the bend, whose curvature still stands clear of the resolution but whose sight distance exceeds the stated distance, and turns about there: at every observation of the swing the place can be seen from either direction beyond the stated distance. The sight condition held only before the act began, and the curve alone does not engage the duty. -/
def s6OutRegions : List Structure :=
  [ roadSeg 1 (-400) 0 kBend sightBlind, roadSeg 2 0 400 kBend sightOpen, farCrest ]

def occasion_s6_outsideTrace : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    sceneAt t (car (rampX (-110) 20 k 9 15, Q.zero) (swingHeading k 15) (mps 20) (swingYaw k 15))
      s6OutRegions

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (win : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_407"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := win }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated [] (some (9000, 23000))
  , witness "permit" permitTrace .compliant [] (some (9000, 23000))
  , witness "idle" idleTrace .notApplicable [] (some (9000, 23000))
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"] (some (9000, 23000))
  , witness "occasion_s3" occasion_s3Trace .violated [] (some (9000, 27000))
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .compliant [] (some (9000, 27000))
  , witness "occasion_s5" occasion_s5Trace .violated [] (some (9000, 27000))
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .compliant [] (some (9000, 33000))
  , witness "occasion_s6" occasion_s6Trace .violated [] (some (9000, 27000))
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .compliant [] (some (9000, 27000)) ]

end TrafficSpecWitness.NRS_484B_407

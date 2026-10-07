/-
  Witnesses for NRS_484B_407.

  The stretch. Every scene is laid out on one stretch of highway running east, carried as roadway
  regions 12 m wide about the line y = 0: each declares the curvature of its places (1/m, zero
  where it runs straight) and the sight distance of them. A scene that needs a crest of a grade
  carries it as a short region about a stated place, with its reference point, so the ground
  distance from the subject's body outline to it is the distance the rule reads. The subject
  (track 1) is a car, half-length 2 m and half-width 1 m, on the roadway at y = 0 throughout; no
  other road user is anywhere in any scene.

  The instants. Each witness is 24 observations a second apart, t = 0 … 23 s. The rule looks back
  over the turn window, so every witness names the instants it speaks about: t = 12 s onwards,
  from which the look-back is covered at every instant (12 s behind, sampled every second, well
  inside the adequacy bound). Nothing before t = 12 s is spoken about.

  The reversal. Where a scene carries one, the subject yaws left at 30 deg/s through the six
  seconds k = 11 … 16 and runs straight otherwise: 180° of heading change in all, integrated over
  a 12 s window that holds the whole of it from k = 16 to k = 22, far above the reversal angle,
  and 90° or less at k = 12 … 14, far below it. Its speed is cruising before and after and
  manoeuvring through the turn, always above the motion speed. The scene of 'permit' yaws at
  3 deg/s instead, so the window holds 36° at every instant — the subject drives round the bend
  without turning about.

  The places. The subject's place advances along the stretch at the speed each scene reports, the
  reversal included: these are built scenes and not a simulation, and what the rule reads of the
  manoeuvre is the yaw rate the window integrates, the speed, and the place at which the reversal
  is recognized. Laying the places out this way is what lets each occasion witness put the place
  of the turn on the far side of a threshold the act began on.

  The margins. A bend is declared at a radius of 100 m, a fifth of the resolution the reading
  gives, and a straight place at zero curvature exactly; a short sight distance is 50 m, a third
  of the 500 feet the text states, and a long one 400 m, well over twice it; a crest is placed so
  that the distance to it clears the crest approach distance by about 27 m at the start of an act
  and falls about 27 m below it where the reversal is recognized. Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_407
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_407

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def mps (n : Int) : Q := Units.metresPerSecond n
private def degPerSecond (n : Int) : Q := Units.degrees n

-- Binders ↦ tracks: veh ↦ 1

/-- Half-length, half-width, half-height of the subject car. -/
private def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The bend the curved stretches declare (1/m: a radius of 100 m), and a straight place. -/
private def bend : Q := Units.ratio 1 100
private def straight : Q := Q.zero

/-- Sight distances: one far below the text's 500 feet, one far above it. -/
private def shortSight : Q := m 50
private def longSight : Q := m 400

/-- A roadway of the stretch, carrying the bend of its places and their sight distance. -/
private def roadway (id : RegionId) (x0 x1 : Int) (curvature sight : Q) : Structure :=
  { Build.rect id .roadway (m x0) (m (-6)) (m x1) (m 6) with
      curvature := some curvature, sightDistance := some sight }

/-- The crest of a grade: a short region about `x`, with its reference point. -/
private def crestAt (id : RegionId) (x : Int) : Structure :=
  { Build.rect id .crest (m (x - 1)) (m (-6)) (m (x + 1)) (m 6) with position := some (m x, m 0) }

/-- The subject, with the yaw rate the heading-change primitive integrates. -/
private def subjectCar (pos : Vec) (heading : Vec) (speed yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed carExtent)
    (fun kin => { kin with yawRate := some yaw })

-- The reversal, as the scenes that carry one report it.

/-- 30 deg/s through the six seconds of the turn, nothing before or after: 180° in all. -/
private def yawAt (k : Nat) : Q := if 11 ≤ k ∧ k ≤ 16 then degPerSecond 30 else Q.zero

/-- Manoeuvring speed through the turn, cruising speed before and after it. -/
private def speedAt (k : Nat) : Q := if 11 ≤ k ∧ k ≤ 16 then mps 3 else mps 6

/-- The heading through the turn, sampled every 30°: east before it, west after it. -/
private def headingAt (k : Nat) : Vec :=
  if k ≤ 10 then Build.east
  else if k = 11 then (Units.ratio 866 1000, Units.ratio 500 1000)
  else if k = 12 then (Units.ratio 500 1000, Units.ratio 866 1000)
  else if k = 13 then Build.north
  else if k = 14 then (Units.ratio (-500) 1000, Units.ratio 866 1000)
  else if k = 15 then (Units.ratio (-866) 1000, Units.ratio 500 1000)
  else Build.west

/-- The ground the subject has run along the stretch by instant `k`, at those speeds. -/
private def runAt (k : Nat) : Int :=
  let j : Int := Int.ofNat k
  if k ≤ 10 then 6 * j
  else if k ≤ 16 then 60 + 3 * (j - 10)
  else 78 + 6 * (j - 16)

/-- The subject's place at instant `k`, from `x0` at the start of the trace. -/
private def placeAt (x0 : Int) (k : Nat) : Vec := (m (x0 + runAt k), m 0)

/-- The subject of a scene that carries a reversal, from `x0`. -/
private def turningCar (x0 : Int) (k : Nat) : RoadUser :=
  subjectCar (placeAt x0 k) (headingAt k) (speedAt k) (yawAt k)

/-- `forbid` (violated): A two-lane highway bends left through a cutting. The subject is a car, a member class of the aggregate vehicle, and its footprint overlaps the roadway (rel.occupies on st.roadway); the roadway's radius of curvature at its place is far below p.curve_radius_resolution throughout, so st.curvature there stands clear of zero at the source's resolution, and st.sight_distance there is far below the literal 500 feet throughout. It slows to manoeuvring speed and swings through a turn that leaves it heading back the way it came: over p.turn_window, prim.heading_change exceeds p.direction_reversal_angle in magnitude and kin.speed is above p.motion_speed_min, so drv.motion.direction_reversal holds, and at the observation at which it is recognized the bend and the short sight distance are both reported at the subject's place. No other road user is anywhere in the scene, and every atom the rule reads is observed at every observation of the window and of the look-back. -/
private def forbidTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 140 k ]
      [ roadway 11 0 420 bend shortSight ]
      []

/-- `permit` (compliant): The same bend, the same car on the roadway, st.sight_distance at its place again far below the literal 500 feet and st.curvature standing clear of zero (its radius of curvature far below p.curve_radius_resolution), and no st.crest region within p.crest_approach_distance. It drives through the bend without turning about: over p.turn_window, prim.heading_change stays far below p.direction_reversal_angle at every observation, so drv.motion.direction_reversal fails. No other road user is in the scene. Curvature, crest geometry, sight distance, occupancy, speed and yaw rate are all reported at every observation of the window and of the look-back behind it, so no leaf is unknown and the compliant verdict is not displaced. -/
private def permitTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar (m (140 + 6 * Int.ofNat k), m 0) Build.east (mps 6) (degPerSecond 3) ]
      [ roadway 11 0 420 bend shortSight ]
      []

/-- `idle` (not_applicable): A straight, level highway in open country, with a crest of a grade behind the subject: earlier on its way the subject passed within p.crest_approach_distance of that st.crest region, where st.sight_distance was well above the literal 500 feet. It then drives on past the crest and, on the open straight beyond it, swings through a full reversal and drives back the way it came, so the obligation's concept holds. At the observation at which that reversal is recognized the radius of curvature at its place is above p.curve_radius_resolution, so st.curvature reports no bend; the ground distance st.region_geometry gives to the crest region is above p.crest_approach_distance; and st.sight_distance at its place is well above the literal 500 feet. No condition of the applicability holds where the vehicle was turned, so the duty does not engage — the crest it passed earlier in the window is not the place of the turn. Every atom the rule reads is reported at every observation of the window and of the look-back, so the verdict is decided and not unknown. -/
private def idleTrace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 120 k ]
      [ roadway 11 0 420 straight longSight, crestAt 12 0 ]
      []

/-- `blind` (unknown): The forbid scene exactly — the bend, the subject on the roadway, the reversal carried out over p.turn_window — except that the source's capability manifest declares st.sight_distance absent: this map carries no sight-distance model, and the atom is unobserved at every observation, the roadway region itself and its curvature being reported as before. Curvature, occupancy and the reversal stay decided, so the duty turns on the one condition that is unknown at the observation at which the reversal is recognized. -/
private def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): A straight road rising to a crest. The radius of curvature at the subject's place stays above p.curve_radius_resolution throughout, so st.curvature reports no bend and the curve route is false; the ground distance st.region_geometry gives from the subject to the st.crest region is below p.crest_approach_distance at the observation at which the reversal is recognized, and st.sight_distance at its place is below the literal 500 feet there. The subject, on the roadway, swings through a reversal: prim.heading_change over p.turn_window exceeds p.direction_reversal_angle and kin.speed is above p.motion_speed_min. No other road user is in the scene, and every atom is observed throughout. -/
private def branch_1Trace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 140 k ]
      [ roadway 11 0 420 straight shortSight, crestAt 12 320 ]
      []

/-- `occasion_s3` (violated): The subject begins its reversal on the straight approach to a bend — the radius of curvature at its place above p.curve_radius_resolution at the first observations of the turn, so st.curvature reports no bend there — and completes it after swinging into the bend, where the curvature is well clear of the source's resolution and st.sight_distance is below the literal 500 feet. The curve condition is false while the act is under way and true at the observation at which the reversal is recognized, which is where the occasion reads it (at_recognition), so the duty engages at the place the vehicle was turned. -/
private def occasion_s3Trace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 140 k ]
      [ roadway 11 0 208 straight shortSight, roadway 12 208 420 bend shortSight ]
      []

/-- `occasion_s6` (violated): On a straight road rising to a crest, the subject's reversal begins while the ground distance st.region_geometry gives to the st.crest region is still above p.crest_approach_distance and finishes once that distance has fallen below it, with st.sight_distance below the literal 500 feet at that moment and the radius of curvature above p.curve_radius_resolution throughout, so st.curvature reports no bend. The crest condition is false at the start of the act and true at the observation at which the reversal is recognized, which is where the occasion reads it. -/
private def occasion_s6Trace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 140 k ]
      [ roadway 11 0 420 straight shortSight, crestAt 12 380 ]
      []

/-- `occasion_s7` (violated): On the bend of the forbid scene, st.sight_distance at the subject's place is above the literal 500 feet where the turn begins, near the mouth of the cutting, and falls below it as the subject swings round into the inside of the bend. The radius of curvature stays far below p.curve_radius_resolution throughout, so the bend is reported at every observation, and the reversal is completed within p.turn_window. The sight-distance condition is false at the start of the act and true at the observation at which the reversal is recognized, which is where the occasion reads it. -/
private def occasion_s7Trace : Trace :=
  Build.trace 24 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar 140 k ]
      [ roadway 11 0 208 bend longSight, roadway 12 208 420 bend shortSight ]
      []

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_407"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("veh", 1)]
    expected := expected
    window := some (12000, 23000) }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .violated
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s6" occasion_s6Trace .violated
  , witness "occasion_s7" occasion_s7Trace .violated ]

end TrafficSpecWitness.NRS_484B_407

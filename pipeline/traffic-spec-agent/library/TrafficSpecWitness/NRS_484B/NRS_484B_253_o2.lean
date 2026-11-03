/-
  Witnesses for NRS_484B_253_o2.

  The map is one crossroads, the same in every scene: the junction (region 10) is the square
  [-10, 10] × [-10, 10]; the northbound approach (region 11, a lane, direction north, entrance end
  at 10) is [0, 8] × [-300, -10]; the southbound approach (region 12, a lane, direction south,
  entrance end at 10) is [-8, 0] × [10, 300]. The two designated directions are exactly opposed, so
  a vehicle coming down region 12 and a vehicle coming up region 11 approach the junction from
  opposite directions. No region overlaps another, so a body's reference point lies in one of them.

  The subject (track 1) always approaches on region 11; the turning vehicle (track 2) comes down
  region 12, enters the junction, waits, and turns left (south → south-east → east) at 45° a second
  with the yaw rate to match, so that its accumulated leftward heading change passes 60° at the
  second of the two turning observations. Every body is 5 m long and 2 m wide, and every scene is
  1 s after the last.

  Each witness names the one instant it speaks about (`window`), the observation at which its
  narrative is decided, and its trace carries the history the rule looks back over from there: the
  ten seconds the signal search and the yield search need, with the turn's recognition window
  inside them. Nothing is judged before that instant, and the traces are no longer than the
  look-back needs.

  Every figure here is this witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def deg (n : Int) : Q := Units.degrees n
def sec (n : Int) : Q := Units.seconds n

/-- Half-length, half-width, half-height of every body here. -/
def halfBody : Q × Q × Q := (cm 250, cm 100, cm 75)

/-- The heading 45° to the left of south: the half-way point of the turn. -/
def southEast : Vec := (Units.ratio 707 1000, Units.ratio (-707) 1000)

def junction : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

def northApproach : Structure :=
  Build.lane 11 [(m 0, m (-300)), (m 8, m (-300)), (m 8, m (-10)), (m 0, m (-10))]
    Build.north (enters := some 10)

def southApproach : Structure :=
  Build.lane 12 [(m (-8), m 10), (m 0, m 10), (m 0, m 300), (m (-8), m 300)]
    Build.south (enters := some 10)

def world : List Structure := [junction, northApproach, southApproach]

/-- A vehicle: position, heading, speed, yaw rate and the turn indicator it shows; no arm signal. -/
def car (tr : TrackId) (p h : Vec) (sp yaw : Q) (ind : TurnIndicatorState) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user tr [RoadUserClass.motorVehicle] p h sp halfBody)
      (fun k => { k with yawRate := some yaw }))
    (fun s => { s with turnIndicator := some ind, handSignal := some HandSignal.noSignal })

/-- The same body reversing: the heading stays where it points and the velocity is the other way. -/
def backing (u : RoadUser) (v : Q) : RoadUser :=
  Build.withKin u (fun k => { k with velocity := some (Q.zero, Q.neg v), speed := some v })

/-- The same body, of which the source observed the velocity vector but not its magnitude. -/
def speedUnobserved (u : RoadUser) : RoadUser :=
  Build.withKin u (fun k => { k with speed := none })

/-- The same body with neither indicator lit and the driver's arm held out to the left. -/
def armLeft (u : RoadUser) : RoadUser :=
  Build.withSignals u
    (fun s => { s with turnIndicator := some .off, handSignal := some HandSignal.left })

/-- The source's plan for a vehicle at the junction. -/
def turnIntent (tr : TrackId) (b : Bool) : DeclaredIntent :=
  { vehicle := tr, target := 10, values := [("int.turn_left", b)] }

def sceneOf (t : Timestamp) (us : List RoadUser) (ints : List DeclaredIntent) : Scene :=
  Build.scene t (some 1) us world [] none {} [] ints

def mainIntents : List DeclaredIntent := [turnIntent 2 true]

def leftThroughout : Nat → TurnIndicatorState := fun _ => .left
def noSignalAtAll : Nat → TurnIndicatorState := fun _ => .off
/-- Shown through the approach and the wait, switched off once the turn is under way. -/
def leftUntilTurning : Nat → TurnIndicatorState := fun k => if k ≤ 8 then .left else .off

-- Binders ↦ tracks: v ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The turning vehicle of the main scenes: down region 12 at x = -6, into the junction at k = 6, a
-- wait, and a left turn at k = 9 and 10. Its accumulated leftward heading change is 45° at k = 9
-- (not yet a turn) and 90° at k = 10, the observation the main witnesses judge.
-- ---------------------------------------------------------------------------------------------
def mainTurner (ind : Nat → TurnIndicatorState) (k : Nat) : RoadUser :=
  match k with
  | 0 => car 2 (m (-6), m 40) Build.south (mps 6) Q.zero (ind k)
  | 1 => car 2 (m (-6), m 34) Build.south (mps 6) Q.zero (ind k)
  | 2 => car 2 (m (-6), m 28) Build.south (mps 6) Q.zero (ind k)
  | 3 => car 2 (m (-6), m 22) Build.south (mps 6) Q.zero (ind k)
  | 4 => car 2 (m (-6), m 16) Build.south (mps 6) Q.zero (ind k)
  | 5 => car 2 (m (-6), m 11) Build.south (mps 5) Q.zero (ind k)
  | 6 => car 2 (m (-6), m 6) Build.south (mps 5) Q.zero (ind k)
  | 7 => car 2 (m (-6), m 4) Build.south (mps 2) Q.zero (ind k)
  | 8 => car 2 (m (-6), m 4) Build.south Q.zero Q.zero (ind k)
  | 9 => car 2 (cm (-550), cm 350) southEast (mps 1) (deg 45) (ind k)
  | _ => car 2 (cm (-150), m 3) Build.east (mps 4) (deg 45) (ind k)

/-- The subject, unbraked on region 11 at 13 m/s, 15 m short of the junction at k = 10. -/
def runner (k : Nat) : RoadUser :=
  car 1 (m 4, m (13 * (k : Int) - 145)) Build.north (mps 13) Q.zero .off

/-- The subject at rest on region 11, 30 m short of the junction. -/
def parked (_ : Nat) : RoadUser := car 1 (m 4, m (-30)) Build.north Q.zero Q.zero .off

/-- `forbid` (violated): A crossroads where a vehicle stands within the junction with a declared left-turn intention; it has waited for the opposing stream with a measured gap never below 5 m, has shown its left indicator for three seconds while standing, and begins to swing left. The subject approaches on the opposing carrier at 13 m/s and neither brakes nor deviates; under their current velocities the bodies reach a closest approach of 0.5 m within 1.2 s and the measured gap falls to 0.4 m. -/
-- As built: the turning vehicle waited within the junction with its left indicator shown and is
-- swinging left at k = 10, where its course change passes the bound. The subject, 15 m short of the
-- junction at 13 m/s, neither brakes nor deviates: under the two current velocities the centres
-- reach 0.04 m of each other in 1.4 s, while the measured body gap is still 14.6 m and the bodies
-- never touch, so it is the conflict margin alone that the subject fails.
def forbidTrace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [runner k, mainTurner leftThroughout k] mainIntents

/-- `permit` (compliant): The same junction and the same turning vehicle, which has yielded and signalled and is making its turn. The subject, approaching on the opposing carrier, brakes to a halt short of the junction; the closest approach under their velocities stays above the clearance throughout and the measured gap never falls below 6 m. -/
-- As built: the subject stands at rest 30 m short of the junction on region 11; the closest
-- approach their velocities give is 33 m and the measured gap never below 29 m.
def permitTrace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [parked k, mainTurner leftThroughout k] mainIntents

/-- `idle` (not_applicable): The turning vehicle shows no indicator and gives no arm signal at any observation before its turn, and swings left in front of the subject. Having not given a signal when and as required, it is owed nothing under this clause, so the duty does not arise. -/
-- As built: the indicator is off and the arm signal is `no_signal` at every observation, so the
-- lead window carries no signal anywhere in the search window behind k = 10 and the condition is
-- decided false, not left unobserved.
def idleTrace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [runner k, mainTurner noSignalAtAll k] mainIntents

/-- `blind` (unknown): A vehicle within the junction with a declared left-turn intention has yielded to the opposing stream and is turning left; the source declares the turn indicator absent and carries no arm signal observation either, so whether it gave a signal before its turn cannot be decided. -/
-- The manifest masks `sig.turn_indicator`; the arm signal is observed and shows nothing, so the
-- side of the manoeuvre is the one thing the source leaves undecided. The trace is padded with
-- eight seconds of its first scene so that nothing else in the search window is unknown.
def blindTrace : Trace :=
  Build.pad
    (Build.trace 11 0 (sec 1) fun k t =>
      sceneOf t [parked k, mainTurner leftThroughout k] mainIntents)
    (sec 8) Q.zero (sec 1)

/-- `branch_1` (not_applicable): The subject approaches the junction on its carrier at 13 m/s and crosses it, and no other road user is present in the scene at any observation: no vehicle is making a left turn, so the duty does not arise and the verdict is decided with the subject alone in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (sec 1) fun k t => sceneOf t [runner k] []

-- ---------------------------------------------------------------------------------------------
-- The turning vehicle of the collision branches: the same approach, deeper into the junction, its
-- turn recognized at k = 9 and still under way at k = 10.
-- ---------------------------------------------------------------------------------------------
def deepTurner (ind : Nat → TurnIndicatorState) (k : Nat) : RoadUser :=
  match k with
  | 0 => car 2 (m (-6), m 36) Build.south (mps 6) Q.zero (ind k)
  | 1 => car 2 (m (-6), m 30) Build.south (mps 6) Q.zero (ind k)
  | 2 => car 2 (m (-6), m 24) Build.south (mps 6) Q.zero (ind k)
  | 3 => car 2 (m (-6), m 18) Build.south (mps 6) Q.zero (ind k)
  | 4 => car 2 (m (-6), m 12) Build.south (mps 6) Q.zero (ind k)
  | 5 => car 2 (m (-6), m 6) Build.south (mps 6) Q.zero (ind k)
  | 6 => car 2 (m (-6), m 2) Build.south (mps 3) Q.zero (ind k)
  | 7 => car 2 (m (-6), m 1) Build.south Q.zero Q.zero (ind k)
  | 8 => car 2 (cm (-550), cm 50) southEast (mps 1) (deg 45) (ind k)
  | 9 => car 2 (cm (-150), Q.zero) Build.east (mps 4) (deg 45) (ind k)
  | _ => car 2 (cm 250, Q.zero) Build.east (mps 4) Q.zero (ind k)

/-- The subject at rest clear of the junction, which accelerates at k = 9 and strikes the turning
    vehicle at k = 10. -/
def striker (k : Nat) : RoadUser :=
  match k with
  | 9 => car 1 (m 4, cm (-1050)) Build.north (mps 4) Q.zero .off
  | 10 => car 1 (m 4, cm (-250)) Build.north (mps 8) Q.zero .off
  | _ => car 1 (m 4, m (-14)) Build.north Q.zero Q.zero .off

/-- `branch_3` (violated): The turning vehicle, within the junction with a declared left-turn intention and its left indicator shown throughout, waits while the subject stands clear on the opposing carrier, then turns; its accumulated leftward heading change passes the bound at one observation and has grown further by the next. At that next observation the subject accelerates from rest at 8 m/s into the still-turning vehicle and strikes it. The turn is being made at the observation judged although it was first recognized earlier. -/
-- As built: the course change reaches the bound at k = 9, where the subject still stands clear;
-- the observation judged is k = 10, at which the concept still holds over the window behind and the
-- subject, now at 8 m/s, has driven into the turning vehicle — their footprints overlap.
def branch_3Trace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [striker k, deepTurner leftThroughout k] mainIntents

/-- `branch_5` (violated): The turning vehicle shows its left indicator throughout its approach and its wait within the junction and switches it off once the turn is under way; at the observation judged no indicator is lit and no arm signal is given. The signal was shown for the lead window at observations before it had turned its course, so it was given when and as required, the duty arises, and the subject, which had stopped clear, drives into the turning vehicle. -/
-- As built: the indicator is left up to k = 8, the last observation at which the vehicle had not
-- yet turned its course, and off from k = 9, when the turn is under way; at k = 10, the observation
-- judged, nothing is lit and no arm signal is given.
def branch_5Trace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [striker k, deepTurner leftUntilTurning k] mainIntents

/-- `branch_4` (violated): The turning vehicle entered the junction and then stood still within it, with its left indicator shown, for longer than the recognition window of the course change before beginning its turn, so no observation inside that window shows it on its approach carrier. The carrier it occupied at the last observation before it came to be within the junction is the southbound carrier, opposed to the subject's northbound one. The subject, which had been stopped clear, drives into the turning vehicle while it turns. -/
-- As built: the vehicle is within the junction from k = 3 and stands still there from k = 4 to
-- k = 10 — nine seconds, longer than the eight-second recognition window — and turns at k = 11 and
-- 12. The last observation at which it was on region 12 is k = 2, outside every window the rule
-- measures. The subject, stopped clear until k = 11, drives in at 8 m/s at k = 12, the observation
-- judged, bringing the centres to 0.9 m under the two velocities.
def branch_4Trace : Trace :=
  Build.trace 13 0 (sec 1) fun k t =>
    sceneOf t
      [ (if k ≤ 11 then car 1 (m 4, m (-14)) Build.north Q.zero Q.zero .off
         else car 1 (m 4, m (-6)) Build.north (mps 8) Q.zero .off)
      , (match k with
         | 0 => car 2 (m (-6), m 26) Build.south (mps 6) Q.zero .left
         | 1 => car 2 (m (-6), m 20) Build.south (mps 6) Q.zero .left
         | 2 => car 2 (m (-6), m 14) Build.south (mps 6) Q.zero .left
         | 3 => car 2 (m (-6), m 8) Build.south (mps 6) Q.zero .left
         | 11 => car 2 (cm (-550), cm 350) southEast (mps 1) (deg 45) .left
         | 12 => car 2 (cm (-150), m 3) Build.east (mps 4) (deg 45) .left
         | _ => car 2 (m (-6), m 4) Build.south Q.zero Q.zero .left) ]
      mainIntents

/-- `branch_6` (violated): The turning vehicle stands still within the junction, its left indicator shown, while the subject moves out of its path, touches it and backs clear; the turning vehicle never moves until the subject is clear, and then makes its left turn. Standing still, it granted precedence throughout, so the duty arises, and the subject then drives into it while it turns. -/
-- As built: the turning vehicle stands at (-2, 2) from k = 5 to k = 10. The subject crosses into
-- the junction, touches its body at k = 8 while it stands, backs clear by k = 10 and waits; the
-- vehicle turns at k = 11 and 12, and at k = 12, the observation judged, the subject drives into it
-- again. The contact the subject brought about while the vehicle stood is no failure of the
-- vehicle's own yield, which it granted by standing still.
def branch_6Trace : Trace :=
  Build.trace 13 0 (sec 1) fun k t =>
    sceneOf t
      [ (match k with
         | 0 => car 1 (m 4, m (-30)) Build.north (mps 6) Q.zero .off
         | 1 => car 1 (m 4, m (-24)) Build.north (mps 6) Q.zero .off
         | 2 => car 1 (m 4, m (-18)) Build.north (mps 4) Q.zero .off
         | 3 => car 1 (m 4, m (-15)) Build.north (mps 2) Q.zero .off
         | 4 => car 1 (m 4, m (-14)) Build.north Q.zero Q.zero .off
         | 5 => car 1 (m 4, m (-12)) Build.north (mps 3) Q.zero .off
         | 6 => car 1 (m 3, m (-7)) Build.north (mps 5) Q.zero .off
         | 7 => car 1 (m 1, m (-2)) Build.north (mps 4) Q.zero .off
         | 8 => car 1 (cm (-50), m 2) Build.north (mps 1) Q.zero .off
         | 9 => backing (car 1 (cm (-50), m (-2)) Build.north Q.zero Q.zero .off) (mps 4)
         | 10 => backing (car 1 (cm (-50), m (-6)) Build.north Q.zero Q.zero .off) (mps 4)
         | 11 => car 1 (cm (-50), m (-8)) Build.north Q.zero Q.zero .off
         | _ => car 1 (cm (-50), m (-2)) Build.north (mps 6) Q.zero .off)
      , (match k with
         | 0 => car 2 (m (-2), m 27) Build.south (mps 6) Q.zero .left
         | 1 => car 2 (m (-2), m 21) Build.south (mps 6) Q.zero .left
         | 2 => car 2 (m (-2), m 15) Build.south (mps 6) Q.zero .left
         | 3 => car 2 (m (-2), m 9) Build.south (mps 6) Q.zero .left
         | 4 => car 2 (m (-2), m 3) Build.south (mps 4) Q.zero .left
         | 11 => car 2 (cm (-150), cm 150) southEast (mps 1) (deg 45) .left
         | 12 => car 2 (cm 250, m 1) Build.east (mps 4) (deg 45) .left
         | _ => car 2 (m (-2), m 2) Build.south Q.zero Q.zero .left) ]
      mainIntents

/-- `branch_8` (violated): as branch_3, except that the turning vehicle lights no indicator at any
    observation and the driver holds an arm out to the left instead, throughout its approach and its
    wait. The arm signal is the other means the words leave open, so the signal was given when and as
    required, the duty arises, and the subject drives into the turning vehicle while it turns. -/
def branch_8Trace : Trace :=
  Build.trace 11 0 (sec 1) fun k t =>
    sceneOf t [striker k, armLeft (deepTurner noSignalAtAll k)] mainIntents

-- ---------------------------------------------------------------------------------------------
-- The branches in which the turning vehicle had not so yielded. In each, everything else the
-- clause requires of that vehicle holds at the observation judged (k = 10): it is a vehicle of the
-- aggregate within the junction, with a declared left-turn intention, its left indicator shown
-- throughout, its course turned to the left over the window behind, and the subject approaching on
-- the opposed carrier. What fails is the yield alone — at one observation of the window behind, in
-- motion within the junction and its course not yet turned, it did not grant precedence to a
-- vehicle approaching from the opposite direction. Each branch lets exactly one of the three ways
-- of being owed that precedence decide, the other two being false there.
-- ---------------------------------------------------------------------------------------------

/-- The vehicle of those branches: down region 12 at the given x at 8 m/s, its last observation on
    that carrier at k = 6, within the junction from k = 7, in motion there at k = 9 — the failure
    observation, late enough that the recognition window of the course change behind it is covered
    by the trace — at a halt at k = 10, and turning left at k = 11 and 12, where its accumulated
    leftward heading change is 45° and 90°. Its left indicator is shown throughout. -/
def crosser (x : Q) (k : Nat) : RoadUser :=
  match k with
  | 0 => car 2 (x, m 62) Build.south (mps 8) Q.zero .left
  | 1 => car 2 (x, m 54) Build.south (mps 8) Q.zero .left
  | 2 => car 2 (x, m 46) Build.south (mps 8) Q.zero .left
  | 3 => car 2 (x, m 38) Build.south (mps 8) Q.zero .left
  | 4 => car 2 (x, m 30) Build.south (mps 8) Q.zero .left
  | 5 => car 2 (x, m 22) Build.south (mps 8) Q.zero .left
  | 6 => car 2 (x, m 14) Build.south (mps 8) Q.zero .left
  | 7 => car 2 (x, m 6) Build.south (mps 8) Q.zero .left
  | 8 => car 2 (x, Q.zero) Build.south (mps 6) Q.zero .left
  | 9 => car 2 (x, m (-8)) Build.south (mps 6) Q.zero .left
  | 10 => car 2 (x, m (-8)) Build.south Q.zero Q.zero .left
  | 11 => car 2 (Q.add x (cm 50), m (-8)) southEast (mps 1) (deg 45) .left
  | _ => car 2 (Q.add x (m 3), m (-8)) Build.east (mps 4) (deg 45) .left

/-- `branch_2` (not_applicable): As in forbid, except that the turning vehicle never granted precedence: while in motion within the junction it swung left across an opposing vehicle 15 m out at 15 m/s, their bodies closing to 0.6 m, before the subject arrived. Not having so yielded, it is owed nothing under this clause, and the subject's unbraked approach engages no duty here. -/
-- As built: the turning vehicle (track 2, down region 12 at x = -1) is at (-1, -8), within the
-- junction at 6 m/s with its course not yet turned, at k = 9. An opposing vehicle (track 3) is then
-- coming up region 11 at x = 1 at 2 m/s, 17.5 m short of the junction — further from it than its
-- own critical gap of 8 m, and not within it — so what makes it a vehicle precedence was owed to is
-- the conflict alone: under the two current velocities the centres close to 2 m within 2.8 s, which
-- is also why precedence was not granted. The vehicle then halts and turns left at k = 11 and 12,
-- so every other condition of the clause holds at k = 12, the observation judged; the subject comes
-- up region 11 at 6 m/s behind track 3, and the duty does not arise.
def branch_2Trace : Trace :=
  Build.trace 13 0 (sec 1) fun k t =>
    sceneOf t
      [ car 1 (m 4, m (6 * (k : Int) - 90)) Build.north (mps 6) Q.zero .off
      , crosser (m (-1)) k
      , car 3 (m 1, m (2 * (k : Int) - 48)) Build.north (mps 2) Q.zero .off ]
      [turnIntent 2 true, turnIntent 3 false]

/-- The subject of branch_7: up region 11 at x = 1, 1.5 m short of the junction at k = 9 at 2 m/s,
    and at rest there afterwards. -/
def creeper (k : Nat) : RoadUser :=
  if k ≤ 8 then car 1 (m 1, m (2 * (k : Int) - 32)) Build.north (mps 2) Q.zero .off
  else if k = 9 then car 1 (m 1, m (-14)) Build.north (mps 2) Q.zero .off
  else car 1 (m 1, m (-14)) Build.north Q.zero Q.zero .off

/-- `branch_7` (not_applicable): at k = 9 the turning vehicle (down region 12 at x = -3), in motion
    within the junction at 6 m/s and its course not yet turned, left the subject 2.2 m of body gap.
    The subject is not within the junction and the two velocities carry the centres no closer than
    4 m, so what makes the subject a vehicle precedence was owed to is its distance to the junction
    (1.5 m) against its measured speed (2 m/s, a critical gap of 8 m), and nothing else. The vehicle
    then halts and turns left at k = 11 and 12, so at k = 12, the observation judged, every other
    condition of the clause holds; not having so yielded, it is owed nothing here, and the duty does
    not arise. -/
def branch_7Trace : Trace :=
  Build.trace 13 0 (sec 1) fun k t =>
    sceneOf t [creeper k, crosser (m (-3)) k] mainIntents

/-- The subject of branch_9: up region 11 at x = 1, its last observation on that carrier at k = 6,
    within the junction from k = 7 and at rest there from k = 9. The source observed its velocity
    vector throughout but never its speed. -/
def blindSpeedSubject (k : Nat) : RoadUser :=
  speedUnobserved
    (match k with
     | 0 => car 1 (m 1, m (-30)) Build.north (mps 4) Q.zero .off
     | 1 => car 1 (m 1, m (-26)) Build.north (mps 4) Q.zero .off
     | 2 => car 1 (m 1, m (-22)) Build.north (mps 4) Q.zero .off
     | 3 => car 1 (m 1, m (-18)) Build.north (mps 4) Q.zero .off
     | 4 => car 1 (m 1, m (-15)) Build.north (mps 3) Q.zero .off
     | 5 => car 1 (m 1, m (-13)) Build.north (mps 2) Q.zero .off
     | 6 => car 1 (m 1, m (-11)) Build.north (mps 2) Q.zero .off
     | 7 => car 1 (m 1, m (-9)) Build.north (mps 2) Q.zero .off
     | 8 => car 1 (m 1, m (-8)) Build.north (mps 1) Q.zero .off
     | _ => car 1 (m 1, m (-8)) Build.north Q.zero Q.zero .off)

/-- `branch_9` (not_applicable): as branch_7, except that at k = 9 the subject is within the junction
    and the source observed its velocity vector but not its speed, so its distance to the junction
    decides nothing: that it is within the junction is what makes it a vehicle precedence was owed
    to. The two velocities are not converging and the turning vehicle, in motion within the junction
    at 6 m/s with its course not yet turned, left it 2 m of body gap, so it had not so yielded;
    at k = 12, the observation judged, every other condition holds and the duty does not arise. -/
def branch_9Trace : Trace :=
  Build.trace 13 0 (sec 1) fun k t =>
    sceneOf t [blindSpeedSubject k, crosser (m (-3)) k] mainIntents

def witness (name : String) (τ : Trace) (expected : Verdict) (atMs : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := some (atMs, atMs)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 10000
  , witness "idle" idleTrace .notApplicable 10000
  , witness "permit" permitTrace .compliant 10000
  , witness "branch_1" branch_1Trace .notApplicable 2000
  , witness "branch_7" branch_7Trace .notApplicable 12000
  , witness "branch_9" branch_9Trace .notApplicable 12000
  , witness "branch_2" branch_2Trace .notApplicable 12000
  , witness "branch_3" branch_3Trace .violated 10000
  , witness "branch_5" branch_5Trace .violated 10000
  , witness "branch_8" branch_8Trace .violated 10000
  , witness "branch_4" branch_4Trace .violated 12000
  , witness "branch_6" branch_6Trace .violated 12000
  , witness "blind" blindTrace (.unknown []) 10000 ["sig.turn_indicator"] ]

end TrafficSpecWitness.NRS_484B_253_o2

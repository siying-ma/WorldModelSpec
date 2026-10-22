/-
  Witnesses for NRS_484B_307_6a.

  One junction serves every scene. The approach is a single lane running east, 60 m long, from
  x = -60 m to x = 0 m and 3.6 m wide (region 1); its end runs into the junction, region 2, the
  square where the two roadways meet, x from 0 m to 20 m and y from -8 m to 12 m. One traffic
  signal head, device 1, governs the approach; what it displays is the only thing that differs
  between the signal scenes.

  The subject is track 1, a motor vehicle 4 m long and 1.8 m wide, in the middle of the approach
  lane (y = 1.8 m) and heading east; it is the only road user in every scene. Its occupancy is
  stated rather than taken from its reference point, because the duty is about a footprint coming
  to overlap a region: the car overlaps the approach while its rear (x - 2 m) is still west of the
  junction's edge, and overlaps the junction once its front (x + 2 m) has passed that edge and
  while its rear is still west of the junction's far side. Every position below stands clear of
  both edges by at least a metre, so no scene turns on a boundary case.

  Every trace is a run of one-second observations starting at t = 0; the car's velocity is carried
  along the lane (negative where it backs up, its body keeping its eastward heading). Nothing in
  the rule looks back, so no scenario names a window; every trace that must end decided ends with
  the head on something other than the steady yellow or the steady red, which closes the display
  the duty runs over.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_6a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_6a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def carId : TrackId := 1
def approachId : RegionId := 1
def junctionId : RegionId := 2
def headId : DeviceId := 1

/-- The approach: one lane running east, ending at the junction's west edge and entering it. -/
def approach : Structure :=
  Build.lane approachId
    [(m (-60), m 0), (m 0, m 0), (m 0, cm 360), (m (-60), cm 360)]
    Build.east (ordinal := some 1) (count := some 1)
    (leadsTo := some [junctionId]) (enters := some junctionId)

/-- The junction: the region where the two roadways meet. -/
def junction : Structure := Build.rect junctionId .intersection (m 0) (m (-8)) (m 20) (m 12)

/-- Half-length, half-width, half-height of an ordinary car. -/
def halfExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The middle of the approach lane. -/
def lateral : Q := cm 180

/-- The car at `x`, running at `v` along the lane: `v` negative is a reversing car, which keeps
    its eastward heading while its velocity points west. -/
def carAt (x v : Q) : RoadUser :=
  Build.withKin (Build.user carId [.motorVehicle] (x, lateral) Build.east (Q.abs v) halfExtent)
    (fun k => { k with velocity := some (Build.scale Build.east v) })

/-- The regions the car's footprint overlaps at `x`: the approach while its rear is still west of
    the junction's edge, the junction while its front has passed that edge and its rear has not
    passed the far side. -/
def occupiesAt (x : Q) : List (TrackId × RegionId) :=
  (if Q.lt (Q.sub x (m 2)) (m 0) then [(carId, approachId)] else []) ++
  (if Q.lt (m 0) (Q.add x (m 2)) && Q.lt (Q.sub x (m 2)) (m 20) then [(carId, junctionId)] else [])

/-- One observation: where the car is, how it is moving, and what the head facing the approach
    displays. -/
def sceneAt (t : Timestamp) (x v : Q) (shows : List SignalIndication) : Scene :=
  Build.scene t (some carId)
    [ carAt x v ]
    [ approach, junction ]
    [ Build.signal headId [approachId] shows ]
    (some (occupiesAt x))

/-- A trace of one-second observations from a list of (position, velocity, indications). -/
def traceOf (steps : List (Q × Q × List SignalIndication)) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    match steps[k]? with
    | some (x, v, shows) => sceneAt t x v shows
    | none => sceneAt t (m (-60)) Q.zero []

def yellowAlone : List SignalIndication := [.circularYellow]
def redAlone : List SignalIndication := [.circularRed]
def greenAlone : List SignalIndication := [.circularGreen]
/-- A circular yellow displayed together with a protected left arrow: the yellow is not alone. -/
def yellowWithArrow : List SignalIndication := [.circularYellow, .greenArrow .left]

/-- `forbid` (violated): A car runs up to a signalised crossroads with the head facing its lane showing a steady circular yellow and nothing else. The car keeps its speed; the head turns to steady circular red while the car is still short of the junction, and the car's front then crosses into the intersection region. No other road user is in the scene. -/
def forbidTrace : Trace := traceOf
  [ (m (-40), mps 10, yellowAlone)
  , (m (-30), mps 10, yellowAlone)
  , (m (-20), mps 10, redAlone)
  , (m (-10), mps 10, redAlone)
  , (m 0,     mps 10, redAlone)
  , (m 10,    mps 10, redAlone) ]

/-- `permit` (compliant): The same junction and the same car, alone in the scene: facing the steady yellow it slows and stops short of the intersection region, and it is still standing there when the head shows steady circular red; the head later shows steady circular green with the car still standing. -/
def permitTrace : Trace := traceOf
  [ (m (-40), mps 10, yellowAlone)
  , (m (-32), mps 6,  yellowAlone)
  , (m (-28), mps 2,  redAlone)
  , (m (-28), Q.zero, redAlone)
  , (m (-28), Q.zero, redAlone)
  , (m (-28), Q.zero, greenAlone) ]

/-- `idle` (not_applicable): The same junction, but the head facing the car's lane shows a steady circular green throughout, and the car drives through the intersection without slowing. -/
def idleTrace : Trace := traceOf
  [ (m (-40), mps 12, greenAlone)
  , (m (-28), mps 12, greenAlone)
  , (m (-16), mps 12, greenAlone)
  , (m (-4),  mps 12, greenAlone)
  , (m 8,     mps 12, greenAlone)
  , (m 20,    mps 12, greenAlone) ]

/-- `blind` (unknown): The car of the forbid scenario at the same junction with a head standing beside its approach, but the source does not report which traffic any device faces, so whether that head faces the car's lane cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): The same junction with the head showing a steady circular yellow alone: the car is already within the intersection region when the head turns to steady circular red, and it clears the junction on the red without ever coming into it afresh; the head then shows steady circular green with the car well past. -/
def branch_1Trace : Trace := traceOf
  [ (m (-6), mps 8, yellowAlone)
  , (m 1,    mps 8, yellowAlone)
  , (m 9,    mps 8, redAlone)
  , (m 17,   mps 8, redAlone)
  , (m 25,   mps 8, greenAlone)
  , (m 33,   mps 8, greenAlone) ]

/-- `branch_2` (not_applicable): The same junction, with the head facing the car's lane showing a circular yellow together with a green left arrow at the same observation, so the yellow is not displayed alone; the car enters the junction as the circular red appears. -/
def branch_2Trace : Trace := traceOf
  [ (m (-30), mps 10, yellowWithArrow)
  , (m (-20), mps 10, yellowWithArrow)
  , (m (-10), mps 10, yellowWithArrow)
  , (m 0,     mps 10, redAlone)
  , (m 10,    mps 10, redAlone) ]

/-- `branch_3` (violated): The same junction, the head showing a steady circular yellow alone: the car's front already straddles the boundary, so its footprint overlaps both the approach lane and the intersection region at that observation. Still on the yellow it backs up until its footprint is wholly out of the intersection region and on the approach lane only; the head then turns to steady circular red and the car drives forward, its footprint coming to overlap the intersection region again while the red is displayed. -/
def branch_3Trace : Trace := traceOf
  [ (m (-1), mps 2,    yellowAlone)
  , (m (-5), mps (-4), yellowAlone)
  , (m (-5), Q.zero,   redAlone)
  , (m 3,    mps 8,    redAlone)
  , (m 11,   mps 8,    redAlone) ]

/-- `branch_4` (compliant): The same junction with the head showing a steady circular yellow alone: the car crosses into the intersection region while the yellow is still displayed, so no entry is made on a red; the head turns to steady circular red as the car is leaving the junction, and then to steady circular green, the car never coming into the region again. -/
def branch_4Trace : Trace := traceOf
  [ (m (-20), mps 10, yellowAlone)
  , (m (-10), mps 10, yellowAlone)
  , (m 0,     mps 10, yellowAlone)
  , (m 10,    mps 10, redAlone)
  , (m 20,    mps 10, redAlone)
  , (m 30,    mps 10, greenAlone) ]

/-- `branch_5` (compliant): the car stops short of the junction on the steady yellow and is still
    standing when the head shows the steady red; the head then shows steady circular green, which
    closes that display, and the car still does not move. Only at the next circular red — the
    yellow before it displayed together with a green left arrow, so no fresh warning was given
    alone — does the car drive into the junction. The entry is made on a red the warning this
    yellow opened does not reach. -/
def branch_5Trace : Trace := traceOf
  [ (m (-45), mps 10, yellowAlone)
  , (m (-36), mps 5,  redAlone)
  , (m (-34), Q.zero, greenAlone)
  , (m (-34), Q.zero, yellowWithArrow)
  , (m (-29), mps 10, redAlone)
  , (m (-19), mps 12, redAlone)
  , (m (-7),  mps 12, redAlone)
  , (m 5,     mps 12, redAlone) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_307_6a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_6a

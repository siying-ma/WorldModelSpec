/-
  Witnesses for NRS_484B_227_1_o2.

  The map, in the world frame (+x east, +y north), is one dual carriageway running east–west:
  a highway region (10) 400 m long and 40 m wide, the right-hand (eastbound) roadway (11) at
  y ∈ [-12, -2], the opposite roadway (12) at y ∈ [2, 12], and between them the dividing section at
  y ∈ [-2, 2] — mapped as one region (13) where it is continuous, and as a barrier segment (13), a
  paved gap (16) at x ∈ [-10, 10] and a second barrier segment (17) where a crossover opens it. The
  gap carries `opening := some true`, every barrier segment `opening := some false`. The subject is
  track 1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m × 1 m × 1 m); its footprint, 4 m
  along its heading, overlaps the roadway behind it while it stands on the 4 m dividing section, so
  every crossing instant is stated as occupying both. Occupancy is stated rather than derived from
  the reference point, since a crossing body lies across two regions. Each trace is three instants
  one second apart; no formula looks back, so no scenario names a window.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The divided highway and its two roadways. -/
def hwy : Structure := Build.rect 10 .highway (m (-200)) (m (-20)) (m 200) (m 20)
def rwyRight : Structure := Build.rect 11 .roadway (m (-200)) (m (-12)) (m 200) (m (-2))
def rwyLeft : Structure := Build.rect 12 .roadway (m (-200)) (m 2) (m 200) (m 12)

/-- A continuous dividing section: no opening anywhere along it. -/
def medianBarrier : Structure :=
  { Build.rect 13 .medianOrDivider (m (-200)) (m (-2)) (m 200) (m 2) with opening := some false }

/-- The same dividing section, mapped as one region which carries an opening at a crossover. -/
def medianWithOpening : Structure :=
  { Build.rect 13 .medianOrDivider (m (-200)) (m (-2)) (m 200) (m 2) with opening := some true }

/-- A dividing section mapped in three pieces: barrier, paved gap at the crossover, barrier. -/
def medianWest : Structure :=
  { Build.rect 13 .medianOrDivider (m (-200)) (m (-2)) (m (-10)) (m 2) with opening := some false }
def medianGap : Structure :=
  { Build.rect 16 .medianOrDivider (m (-10)) (m (-2)) (m 10) (m 2) with opening := some true }
def medianEast : Structure :=
  { Build.rect 17 .medianOrDivider (m 10) (m (-2)) (m 200) (m 2) with opening := some false }

/-- The intersection a public authority established across the divided highway. -/
def crossIntersection : Structure := Build.rect 14 .intersection (m (-6)) (m (-12)) (m 6) (m 12)

/-- The subject at a place, with a heading and a speed. -/
def subjectAt (pos hdg : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos hdg speed (m 2, m 1, m 1)

/-- `forbid` (violated): On a dual carriageway with a continuous raised median, a vehicle mounts the median and its footprint overlaps the dividing section while it crosses toward the opposite roadway; the median carries no opening there and no intersection covers the place. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-12), m (-7))
      | 1 => (m (-6), m (-3))
      | _ => (m 0, m (-1))
    let hdg : Vec := match k with
      | 0 => Build.east
      | _ => Build.north
    let occ : List (TrackId × RegionId) := match k with
      | 0 => [(1, 10), (1, 11)]
      | _ => [(1, 10), (1, 11), (1, 13)]
    Build.scene t (some 1)
      [ subjectAt pos hdg (Units.kmh 25) ]
      [ hwy, rwyRight, rwyLeft, medianBarrier ]
      []
      (some occ)

/-- `permit` (compliant): The same divided highway has a paved gap in the median at a signed crossover; the vehicle crosses within the gap, the median region it overlaps carrying the opening attribute, and every atom the rule reads is observed throughout the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-6), m (-7))
      | 1 => (m (-2), m (-1))
      | _ => (m 0, m 7)
    let hdg : Vec := match k with
      | 0 => Build.east
      | _ => Build.north
    let occ : List (TrackId × RegionId) := match k with
      | 0 => [(1, 10), (1, 11)]
      | 1 => [(1, 10), (1, 11), (1, 16)]
      | _ => [(1, 10), (1, 12)]
    Build.scene t (some 1)
      [ subjectAt pos hdg (Units.kmh 20) ]
      [ hwy, rwyRight, rwyLeft, medianWest, medianGap, medianEast ]
      []
      (some occ)

/-- `idle` (not_applicable): A vehicle runs along an undivided two-lane street with a painted centre line and no physical barrier or dividing section, so no divided highway is under it; all atoms are observed throughout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-20), m (-4))
      | 1 => (m (-10), m (-4))
      | _ => (m 0, m (-4))
    Build.scene t (some 1)
      [ subjectAt pos Build.east (Units.kmh 40) ]
      [ Build.rect 10 .highway (m (-200)) (m (-10)) (m 200) (m 10)
      , Build.rect 11 .roadway (m (-200)) (m (-8)) (m 200) (m 8)
      , Build.rect 15 .centreLine (m (-200)) (cm (-10)) (m 200) (cm 10) ]
      []
      (some [(1, 10), (1, 11)])

/-- `blind` (unknown): The map carries the highway, its two roadways and the median between them, but the source declares occupancy absent, so whether the subject's footprint overlaps the roadway or the dividing section cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-20), m (-7))
      | 1 => (m (-10), m (-7))
      | _ => (m 0, m (-7))
    Build.scene t (some 1)
      [ subjectAt pos Build.east (Units.kmh 50) ]
      [ hwy, rwyRight, rwyLeft, medianBarrier ]
      []
      (some [(1, 10), (1, 11)])

/-- `branch_1` (compliant): the dividing section is continuous, but a public authority established
    an intersection across it; the vehicle keeps to the right-hand roadway, then crosses the
    dividing section within the intersection, which the exception's second limb withdraws. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-40), m (-7))
      | 1 => (m 0, m (-1))
      | _ => (m 0, m 7)
    let hdg : Vec := match k with
      | 0 => Build.east
      | _ => Build.north
    let occ : List (TrackId × RegionId) := match k with
      | 0 => [(1, 10), (1, 11)]
      | 1 => [(1, 10), (1, 11), (1, 13), (1, 14)]
      | _ => [(1, 10), (1, 12), (1, 14)]
    Build.scene t (some 1)
      [ subjectAt pos hdg (Units.kmh 20) ]
      [ hwy, rwyRight, rwyLeft, medianBarrier, crossIntersection ]
      []
      (some occ)

/-- `branch_2` (compliant): the dividing section of this highway is mapped as one region which
    carries an opening at a crossover; the vehicle never enters it but runs along the right-hand
    roadway, so the rule is engaged — the exception needs the subject's own place, not an opening
    somewhere on the way. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := match k with
      | 0 => (m (-20), m (-7))
      | 1 => (m (-10), m (-7))
      | _ => (m 0, m (-7))
    Build.scene t (some 1)
      [ subjectAt pos Build.east (Units.kmh 50) ]
      [ hwy, rwyRight, rwyLeft, medianWithOpening ]
      []
      (some [(1, 10), (1, 11)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch1Trace .compliant
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o2

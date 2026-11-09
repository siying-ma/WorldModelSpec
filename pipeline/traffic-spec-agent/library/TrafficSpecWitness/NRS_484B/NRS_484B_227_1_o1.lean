/-
  Witnesses for NRS_484B_227_1_o1.

  The geometry. One east–west carriageway, the way `10`, a rectangle 1000 m long and 40 m wide
  (y from -20 to 20). Upon it: the eastbound roadway `11` (y from -9 to -1, designated direction
  east), the westbound roadway `12` (y from 1 to 9, designated direction west), the central
  dividing section `13` (y from -1 to 1, no opening) and the paved south shoulder `14` (y from -13
  to -9). Every one of them records the way `10` as the way it lies on, so the divider and the two
  roadways are parts of one divided highway. Two scenes replace the single barrier with two
  sections `13` and `18` separated by a gap between x = -10 and x = 10, which holds either the
  crossover `15` (a dividing section carrying the opening attribute) or the junction `16` (an
  intersection, 16 m wide across the way). The undivided way of `idle` is the way `20` with one
  two-way roadway `21` and the painted centre line `22` — no dividing section anywhere on it.

  The car is track `1`, a motor vehicle 4 m long and 1.8 m wide, heading east except where the
  narrative has it crossing. Each trace is three observations one second apart; the rule looks
  nowhere into the past, so no scenario names a window. The bodies stand at the same place at every
  observation, so each scene decides the verdict on its own geometry.

  Margins against the reading. The divider's boundary lies 4 m to the left of a car on the
  eastbound roadway and 4 m to its right on the westbound one, and 10 m to the left of a car on the
  shoulder — eight times p.lateral_offset_resolution either way. The direction component is +25 m/s
  where the car travels with the roadway's designation and -25 m/s where it travels against it,
  fifty times p.wrong_way_speed_tolerance either way; the standing car of `branch_3` reads 0 m/s,
  under p.standstill_speed_tolerance. Every figure here is the witness's own and appears nowhere in
  the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of the car. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The car at a place, with a heading and a speed. -/
def car (x y : Int) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) heading (m speed) carExtent

-- The divided highway ------------------------------------------------------------------------

def wayRegion : Structure := Build.rect 10 .highway (m (-500)) (m (-20)) (m 500) (m 20)

/-- The eastbound (south) roadway of the way. -/
def roadwayEast : Structure :=
  { Build.rect 11 .roadway (m (-500)) (m (-9)) (m 500) (m (-1)) with
      lane := some { direction := some Build.east }, ways := some [10] }

/-- The westbound (north) roadway of the way. -/
def roadwayWest : Structure :=
  { Build.rect 12 .roadway (m (-500)) (m 1) (m 500) (m 9) with
      lane := some { direction := some Build.west }, ways := some [10] }

/-- The unbroken central dividing section. -/
def barrier : Structure :=
  { Build.rect 13 .medianOrDivider (m (-500)) (m (-1)) (m 500) (m 1) with
      opening := some false, ways := some [10] }

/-- The western section of a barrier broken between x = -10 and x = 10. -/
def barrierWest : Structure :=
  { Build.rect 13 .medianOrDivider (m (-500)) (m (-1)) (m (-10)) (m 1) with
      opening := some false, ways := some [10] }

/-- The eastern section of that broken barrier. -/
def barrierEast : Structure :=
  { Build.rect 18 .medianOrDivider (m 10) (m (-1)) (m 500) (m 1) with
      opening := some false, ways := some [10] }

/-- The crossover in the gap: a dividing section carrying the opening attribute. -/
def crossover : Structure :=
  { Build.rect 15 .medianOrDivider (m (-10)) (m (-1)) (m 10) (m 1) with
      opening := some true, ways := some [10] }

/-- The junction in the gap: an intersection established across the way. -/
def junction : Structure :=
  { Build.rect 16 .intersection (m (-8)) (m (-13)) (m 8) (m 13) with
      ways := some [10] }

/-- The paved shoulder outside the eastbound roadway. -/
def shoulderEast : Structure :=
  { Build.rect 14 .shoulder (m (-500)) (m (-13)) (m 500) (m (-9)) with
      paved := some true, lane := some { direction := some Build.east }, ways := some [10] }

/-- The divided highway: the way, its two roadways, the unbroken barrier and the shoulder. -/
def dividedHighway : List Structure :=
  [wayRegion, roadwayEast, roadwayWest, barrier, shoulderEast]

/-- The same way with the barrier broken, the gap filled by `extra`. -/
def brokenHighway (extra : List Structure) : List Structure :=
  [wayRegion, roadwayEast, roadwayWest, barrierWest, barrierEast, shoulderEast] ++ extra

-- The undivided highway of `idle` ------------------------------------------------------------

def plainWay : Structure := Build.rect 20 .highway (m (-500)) (m (-20)) (m 500) (m 20)

def plainRoadway : Structure :=
  { Build.rect 21 .roadway (m (-500)) (m (-8)) (m 500) (m 8) with ways := some [20] }

def paintedCentreLine : Structure :=
  { Build.rect 22 .centreLine (m (-500)) (cm (-10)) (m 500) (cm 10) with ways := some [20] }

/-- A trace of three observations one second apart on one unchanging scene. -/
def still (users : List RoadUser) (structures : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => Build.scene t (some 1) users structures []

/-- `forbid` (violated): A car moving at 25 m/s on a divided highway has crossed the central barrier and runs along the opposite roadway in the direction it was already travelling. The barrier's lateral offset from the car is negative — the divider is on its right — and the roadway's designated direction opposes its velocity; its footprint overlaps no roadway of that way that is its right-hand one, and it is not within any opening or junction. -/
def forbidTrace : Trace :=
  still [car 0 5 Build.east 25] dividedHighway

/-- `permit` (compliant): The same car at 25 m/s on the nearside roadway of the divided highway: the roadway's designated direction agrees with its velocity and the central barrier lies to its left, well beyond the offset resolution. -/
def permitTrace : Trace :=
  still [car 0 (-5) Build.east 25] dividedHighway

/-- `idle` (not_applicable): A car runs along a two-lane undivided highway with a painted centre line and no physical barrier or dividing section between the directions. The way is not a divided highway and the rule does not engage. -/
def idleTrace : Trace :=
  still [car 0 (-4) Build.east 25] [plainWay, plainRoadway, paintedCentreLine]

/-- `blind` (unknown): the divided highway with the source declaring the designated direction of
    travel of structures absent: the way, the barrier, the two roadways and the car's velocity are
    recorded, the barrier lies to the car's left, but which roadway is the right-hand one for its
    travel cannot be read, so the duty is unknown. -/
def blindTrace : Trace :=
  still [car 0 (-5) Build.east 25] dividedHighway

/-- `branch_1` (not_applicable): The car's footprint overlaps a crossover recorded as an opening in the central dividing section of the divided highway as it crosses from one roadway to the other. The exception applies by its own words and the duty does not bite at that observation. -/
def branch_1Trace : Trace :=
  still [car 0 0 Build.north 5] (brokenHighway [crossover])

/-- `branch_2` (violated): The car has left the nearside roadway and runs along the paved shoulder of the divided highway at 15 m/s, the barrier still to its left. Its footprint overlaps no roadway of the way, so it is not upon the right-hand roadway, and no opening or junction covers it. -/
def branch_2Trace : Trace :=
  still [car 0 (-11) Build.east 15] dividedHighway

/-- `branch_3` (not_applicable): the car stands motionless on the opposite roadway of the divided
    highway — the forbid geometry with the speed at zero. It is not driven upon the way at that
    observation and the rule does not engage. -/
def branch_3Trace : Trace :=
  still [car 0 5 Build.east 0] dividedHighway

/-- `branch_4` (not_applicable): the car runs at 25 m/s along the opposite roadway, as in forbid,
    but its footprint overlaps an intersection established across the divided highway where the
    barrier is broken. The exception's second limb applies and the duty does not bite there. -/
def branch_4Trace : Trace :=
  still [car 0 5 Build.east 25] (brokenHighway [junction])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_227_1_o1

/-
  Witnesses for NRS_484B_227_1_o2.

  The ground. A north–south divided highway: the way itself (region 10, kind `highway`), its
  right-hand northbound roadway (11, x from 4 to 16 m), its southbound roadway (12, x from −16 to
  −4 m) and the concrete dividing section between them (13, x from −4 to 4 m). Three scenes vary
  it: two cut the dividing section short and put a recorded crossover (14, `opening`) in the gap,
  one leaves the gap to a junction with a cross street (15, `intersection`). The undivided scenes
  carry one roadway (11, x from −12 to 12 m) with a painted centre line (18) and no physical
  divider, and one of them stands a second, divided highway (20, 21, 22) well to the east, whose
  dividing section lies on that way and on no other. One scene adds a private yard (17) beyond the
  highway's boundary line, lying on no way at all.

  The bodies. The subject (track 1), a motor vehicle 4 m long and 2 m wide, is the only road user
  in every scene. It travels at 2 m/s throughout — eight metres between observations — so the
  motion tolerance is kept by a wide margin at every observation of every window.

  The instants. Thirty-six observations four seconds apart, from t = 0. Every trace holds a
  straight course for the first hundred seconds, so that the ten-second window the duty's occasion
  and the turn concept look back over, and the twenty-second window the reversal concept looks
  back over, are covered and adequately sampled at the instants each witness speaks about
  (k = 26, 27, 28, named in `window`).

  The manoeuvres. A scene states the yaw rate (deg/s, left positive) of the interval before each
  observation, and the heading it leaves the body with; the course-change concepts integrate that
  rate over the window behind. Every rotation here is a quarter, half or three-quarter turn over
  one four-second interval, so the heading at every observation is exact:
    forbid, idle, occasion_s2, blind, …  half turn left (45 deg/s) then quarter turn right
                                         (−22.5 deg/s): a 90 degree change of course to the left,
                                         recognized at k = 26 and at no other observation;
    permit                               quarter turn right: no left turn and no reversal;
    branch_divider_only                  quarter turn left and straight back: a turning body whose
                                         course change over the window is nil;
    branch_turn_about                    three-quarter turn left then a quarter turn right: a half
                                         turn over the twenty-second window and never a course
                                         change between 45 and 135 degrees over any ten-second one;
    occasion_s5, occasion_s5_outside     quarter turns that carry the body through the crossover.

  The footprint is the occupancy each scene states: a body across a roadway and a dividing section
  at once is two entries, not a reference point in one polygon.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def deg (n : Int) : Q := Units.degrees n
def mdeg (n : Int) : Q := Units.millidegrees n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- A point of the world frame, in metres. -/
def at_ (x y : Int) : Vec := (m x, m y)

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The ground
-- ---------------------------------------------------------------------------------------------
def wayNS : Structure := Build.rect 10 .highway (m (-30)) (m (-300)) (m 30) (m 400)
def rightRoadway : Structure :=
  { Build.rect 11 .roadway (m 4) (m (-300)) (m 16) (m 400) with ways := some [10] }
def leftRoadway : Structure :=
  { Build.rect 12 .roadway (m (-16)) (m (-300)) (m (-4)) (m 400) with ways := some [10] }
/-- The dividing section: continuous concrete, no recorded opening along the stretch. -/
def barrier : Structure :=
  { Build.rect 13 .medianOrDivider (m (-4)) (m (-300)) (m 4) (m 400) with
      ways := some [10], opening := some false }
/-- The dividing section south of a short crossover. -/
def barrierToShort : Structure :=
  { Build.rect 13 .medianOrDivider (m (-4)) (m (-300)) (m 4) (m (-4)) with
      ways := some [10], opening := some false }
/-- The dividing section south of a long crossover. -/
def barrierToLong : Structure :=
  { Build.rect 13 .medianOrDivider (m (-4)) (m (-300)) (m 4) (m (-40)) with
      ways := some [10], opening := some false }
/-- The dividing section north of the gap. -/
def barrierNorth : Structure :=
  { Build.rect 19 .medianOrDivider (m (-4)) (m 40) (m 4) (m 400) with
      ways := some [10], opening := some false }
/-- A recorded opening in the dividing section, reaching from the barrier's end northward. -/
def crossoverShort : Structure :=
  { Build.rect 14 .medianOrDivider (m (-4)) (m (-4)) (m 4) (m 40) with
      ways := some [10], opening := some true }
/-- The same crossover, long enough to hold a body turning within it. -/
def crossoverLong : Structure :=
  { Build.rect 14 .medianOrDivider (m (-4)) (m (-40)) (m 4) (m 40) with
      ways := some [10], opening := some true }
/-- A junction on the way, where a cross street meets its roadways. -/
def junction : Structure :=
  { Build.rect 15 .intersection (m (-30)) (m (-40)) (m 30) (m 40) with ways := some [10] }
/-- A private yard beyond the highway's boundary line, on no way at all. -/
def yard : Structure :=
  { Build.rect 17 .parkingSpace (m 36) (m (-200)) (m 120) (m 60) with ways := some [] }

/-- An undivided two-lane highway: one roadway, a painted centre line, no physical divider. -/
def wayU : Structure := Build.rect 10 .highway (m (-20)) (m (-300)) (m 20) (m 400)
def roadwayU : Structure :=
  { Build.rect 11 .roadway (m (-12)) (m (-300)) (m 12) (m 400) with ways := some [10] }
def centreLineU : Structure :=
  { Build.rect 18 .centreLine (m (-1)) (m (-300)) (m 1) (m 400) with ways := some [10] }

/-- A second, divided highway to the east: its dividing section lies on that way only. -/
def wayB : Structure := Build.rect 20 .highway (m 100) (m (-300)) (m 160) (m 400)
def roadwayB : Structure :=
  { Build.rect 21 .roadway (m 104) (m (-300)) (m 116) (m 400) with ways := some [20] }
def barrierB : Structure :=
  { Build.rect 22 .medianOrDivider (m 126) (m (-300)) (m 134) (m 400) with
      ways := some [20], opening := some false }

def dividedWay : List Structure := [wayNS, rightRoadway, leftRoadway, barrier]
def dividedWayWithYard : List Structure := [wayNS, rightRoadway, leftRoadway, barrier, yard]
def wayWithShortCrossover : List Structure :=
  [wayNS, rightRoadway, leftRoadway, barrierToShort, crossoverShort, barrierNorth]
def wayWithLongCrossover : List Structure :=
  [wayNS, rightRoadway, leftRoadway, barrierToLong, crossoverLong, barrierNorth]
def wayWithJunction : List Structure :=
  [wayNS, rightRoadway, leftRoadway, barrierToLong, barrierNorth, junction]
def undividedWay : List Structure := [wayU, roadwayU, centreLineU]
def undividedWayBesideDivided : List Structure :=
  [wayU, roadwayU, centreLineU, wayB, roadwayB, barrierB]

-- ---------------------------------------------------------------------------------------------
-- The body and the trace
-- ---------------------------------------------------------------------------------------------
def creep : Q := mps 2

/-- A trace of thirty-six observations four seconds apart: the subject alone on `structures`, its
    position, heading and yaw rate given per observation by `step` and its footprint by `occ`. -/
def runTrace (structures : List Structure) (step : Nat → Vec × Vec × Q)
    (occ : Nat → List (TrackId × RegionId)) : Trace :=
  Build.trace 36 0 (Units.seconds 4) fun k t =>
    let s := step k
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.motorVehicle] s.1 s.2.1 creep (m 2, m 1, m 1))
          fun kin => { kin with yawRate := some s.2.2 } ]
      structures [] (some (occ k))

/-- Northbound in the roadway at `x`, holding a straight course. -/
def straightStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)

/-- Northbound at `x`; the heading swings a half turn to the left over the interval to k = 25 and a
    quarter turn back to the right over the next, leaving the subject westbound: a 90 degree change
    of course to the left, recognized at k = 26. -/
def leftTurnStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else if k = 25 then (at_ x (-8), Build.south, deg 45)
  else (at_ (x - 8 * ((k : Int) - 25)) (-8), Build.west,
        if k = 26 then mdeg (-22500) else Q.zero)

/-- Northbound at `x`, then a quarter turn to the right at k = 25: eastbound thereafter. -/
def rightTurnStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else (at_ (x + 8 * ((k : Int) - 24)) 0, Build.east,
        if k = 25 then mdeg (-22500) else Q.zero)

/-- Northbound at `x`, a quarter turn to the left at k = 25 and a quarter back at k = 26: a turning
    body that ends on its original course. -/
def swerveStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else if k = 25 then (at_ (x - 8) 0, Build.west, mdeg 22500)
  else (at_ (x - 8) (8 * ((k : Int) - 25)), Build.north,
        if k = 26 then mdeg (-22500) else Q.zero)

/-- Northbound at `x`, three quarters of a turn to the left at k = 25 and a quarter to the right at
    k = 26: southbound thereafter, a half turn over the twenty-second window. -/
def turnAboutStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else if k = 25 then (at_ (x + 8) 0, Build.east, mdeg 67500)
  else (at_ (x + 8) (-8 * ((k : Int) - 25)), Build.south,
        if k = 26 then mdeg (-22500) else Q.zero)

/-- Northbound at `x`, a quarter turn to the left at k = 25 and another at k = 26: a half turn,
    made where the body stands at the crossing. -/
def halfTurnStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else if k = 25 then (at_ (x - 8) 0, Build.west, mdeg 22500)
  else (at_ (x - 8) (-8 * ((k : Int) - 25)), Build.south,
        if k = 26 then mdeg 22500 else Q.zero)

/-- As `halfTurnStep`, with a third quarter turn at k = 27 that carries the body westward again,
    out of the gap it turned in. -/
def outOfOpeningStep (x : Int) (k : Nat) : Vec × Vec × Q :=
  if k ≤ 24 then (at_ x (8 * ((k : Int) - 24)), Build.north, Q.zero)
  else if k = 25 then (at_ (x - 8) 0, Build.west, mdeg 22500)
  else if k = 26 then (at_ (x - 8) (-8), Build.south, mdeg 22500)
  else (at_ (x - 8 - 8 * ((k : Int) - 26)) (-8), Build.west,
        if k = 27 then mdeg (-22500) else Q.zero)

/-- Northbound, then a quarter turn to the right at k = 20 that carries the subject off the way
    altogether into the yard, where the half turn to the left and the quarter back are made. -/
def offWayThenLeftStep (k : Nat) : Vec × Vec × Q :=
  if k ≤ 19 then (at_ 13 (8 * ((k : Int) - 19)), Build.north, Q.zero)
  else if k ≤ 24 then (at_ (13 + 8 * ((k : Int) - 19)) 0, Build.east,
                       if k = 20 then mdeg (-22500) else Q.zero)
  else if k = 25 then (at_ 45 0, Build.west, deg 45)
  else (at_ 45 (-8 * ((k : Int) - 25)), Build.south,
        if k = 26 then mdeg (-22500) else Q.zero)

-- ---------------------------------------------------------------------------------------------
-- The footprints
-- ---------------------------------------------------------------------------------------------
/-- On the right-hand roadway throughout. -/
def onRight : Nat → List (TrackId × RegionId) := fun _ => [(1, 11)]
/-- On the right-hand roadway, then across the dividing section into the southbound roadway. -/
def acrossDivider : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 25 then [(1, 11)]
  else if k = 26 then [(1, 11), (1, 13)]
  else if k = 27 then [(1, 12), (1, 13)]
  else if k = 28 then [(1, 12)]
  else []
/-- On the right-hand roadway, then wholly within the dividing section — on no roadway of the
    way — and then in the southbound roadway. -/
def ontoDividerOnly : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 25 then [(1, 11)]
  else if k = 26 then [(1, 13)]
  else if k ≤ 28 then [(1, 12)]
  else []
/-- On the one roadway of an undivided way. -/
def onUndivided : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 27 then [(1, 11)] else []
/-- On the right-hand roadway until the turn carries it off every roadway. -/
def rightThenOff : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 25 then [(1, 11)] else []
/-- On the roadway, then off the way, then in the private yard. -/
def intoYard : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 19 then [(1, 11)]
  else if k ≤ 21 then []
  else [(1, 17)]
/-- Within the crossover at the first observation of the act, on the barrier section at the next. -/
def openingThenBarrier : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 24 then [(1, 11)]
  else if k = 25 then [(1, 12), (1, 14)]
  else if k = 26 then [(1, 12), (1, 13)]
  else if k = 27 then [(1, 12)]
  else []
/-- Outside the crossover on the approach, within it from the first observation of the act. -/
def withinOpening : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 24 then [(1, 11)] else [(1, 12), (1, 14)]
/-- Outside the junction on the approach, within it from the first observation of the act. -/
def withinJunction : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 24 then [(1, 11)] else [(1, 12), (1, 15)]
/-- On the right-hand roadway and on the dividing section together, from k = 25. -/
def ridingDivider : Nat → List (TrackId × RegionId) := fun k =>
  if k ≤ 24 then [(1, 11)] else [(1, 11), (1, 13)]

-- ---------------------------------------------------------------------------------------------
-- The scenes
-- ---------------------------------------------------------------------------------------------
/-- `forbid` (violated): on a divided highway whose dividing section is continuous concrete with no
    recorded opening, the subject swings its heading 90 degrees to the left and turns across the
    dividing section, its footprint overlapping that section while it is still on a roadway of the
    way; at the observation at which the leftward course change rises it is on the right-hand
    roadway. No other road user is in the scene. -/
def forbidTrace : Trace := runTrace dividedWay (leftTurnStep 13) acrossDivider

/-- `permit` (compliant): the subject travels the same divided highway and the manoeuvre it makes
    is a quarter turn to the right off the roadway: its footprint never overlaps the dividing
    section, and neither the leftward course change nor the reversal of direction ever rises. It is
    the only road user in the scene, and the duty is decided for the subject alone. -/
def permitTrace : Trace := runTrace dividedWay (rightTurnStep 13) rightThenOff

/-- `idle` (not_applicable): the subject makes the same left turn across the centre line of an
    undivided two-lane highway: the way carries no physical barrier or dividing section, so the
    trigger fails at every moment of the act and the duty is not engaged. -/
def idleTrace : Trace := runTrace undividedWay (leftTurnStep 9) onUndivided

/-- `blind` (unknown): the subject's turn across the dividing section is as in `forbid`, but the
    source does not observe region occupancy for it: whether its footprint overlapped the dividing
    section, and whether it was on a roadway of the divided highway at all, is unknown. -/
def blindTrace : Trace := runTrace dividedWay (leftTurnStep 13) acrossDivider

/-- `occasion_s2` (violated): the subject begins its left turn on the right-hand roadway and, part
    way through the course change, its footprint lies wholly within the dividing section, on no
    roadway of the way: the trigger holds for part of the act only — at the start of the turn and
    not at its end. Read at some moment of the act, the trigger holds and the turn is a
    violation. -/
def occasion_s2Trace : Trace := runTrace dividedWay (leftTurnStep 9) ontoDividerOnly

/-- `occasion_s2_outside` (not_applicable): the subject travels on the roadway of the divided
    highway, turns off and leaves the way entirely for a private yard, and only there swings a half
    turn to the left and a quarter back — the same 90 degree course change — with no observation of
    the act on the divided highway: the trigger holds only before the act began. -/
def occasion_s2_outsideTrace : Trace := runTrace dividedWayWithYard offWayThenLeftStep intoYard

/-- `occasion_s5` (violated): the subject starts its turn with its footprint inside a recorded
    crossover in the dividing section, and at the next observation, still turning, it has moved out
    of the crossover onto the barrier section south of it: the exception holds for part of the act
    only, so it does not excuse the manoeuvre. -/
def occasion_s5Trace : Trace :=
  runTrace wayWithShortCrossover (outOfOpeningStep 5) openingThenBarrier

/-- `occasion_s5_outside` (not_applicable): the subject approaches along the roadway outside the
    crossover, and from the observation at which its heading begins to change until the course
    change is complete its footprint lies within the recorded crossover: the exception holds
    throughout the act though not before it began. -/
def occasion_s5_outsideTrace : Trace :=
  runTrace wayWithLongCrossover (halfTurnStep 5) withinOpening

/-- `branch_straight` (not_applicable): the subject travels the divided highway northward for the
    whole trace, holding a straight course: its yaw rate stays within the tolerance, so no act is
    under way at any moment of any window and the duty is not engaged. -/
def branch_straightTrace : Trace := runTrace dividedWay (straightStep 13) onRight

/-- `branch_divider_only` (violated): the subject's heading swings a quarter turn to the left and
    straight back — a turning body whose course change over the window is nil, no turn and no
    reversal — while its footprint rides the dividing section: the first limb of the duty alone is
    broken. -/
def branch_divider_onlyTrace : Trace := runTrace dividedWay (swerveStep 13) ridingDivider

/-- `branch_turn_about` (violated): the subject turns about on the divided highway in two
    movements, three quarters of a turn to the left and then a quarter to the right, and is
    southbound in the northbound roadway; its footprint never overlaps the dividing section and no
    ten-second window carries a course change between 45 and 135 degrees, so the duty is broken by
    the reversal of direction alone. -/
def branch_turn_aboutTrace : Trace := runTrace dividedWay (turnAboutStep 5) onRight

/-- `branch_at_junction` (not_applicable): the subject makes the same half turn, but from before
    its heading begins to change until the course change is complete its footprint lies within an
    intersection on the way: the exception holds throughout the act. -/
def branch_at_junctionTrace : Trace := runTrace wayWithJunction (halfTurnStep 5) withinJunction

/-- `branch_divider_other_way` (not_applicable): the subject makes the same left turn on an
    undivided highway; a divided highway stands to the east, its dividing section lying on that
    other way only, so the way the subject is driven upon is undivided. -/
def branch_divider_other_wayTrace : Trace :=
  runTrace undividedWayBesideDivided (leftTurnStep 9) onUndivided

-- ---------------------------------------------------------------------------------------------
-- The witnesses
-- ---------------------------------------------------------------------------------------------
/-- The instants a witness speaks about: the observation at which the act's course change is
    recognized (k = 26, t = 104 s) and the two that follow, at each of which every window the rule
    and its concepts look back over is covered and adequately sampled. -/
def act : Option (Timestamp × Timestamp) := some (104000, 112000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := act) : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "occasion_s2" occasion_s2Trace .violated
  , witness "occasion_s2_outside" occasion_s2_outsideTrace .notApplicable
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .notApplicable
  , witness "branch_straight" branch_straightTrace .notApplicable
  , witness "branch_divider_only" branch_divider_onlyTrace .violated
  , witness "branch_turn_about" branch_turn_aboutTrace .violated
  , witness "branch_at_junction" branch_at_junctionTrace .notApplicable
  , witness "branch_divider_other_way" branch_divider_other_wayTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_227_1_o2

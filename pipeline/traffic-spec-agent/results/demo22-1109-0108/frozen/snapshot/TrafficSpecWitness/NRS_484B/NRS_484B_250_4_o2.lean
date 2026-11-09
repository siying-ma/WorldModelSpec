/-
  Witnesses for NRS_484B_250_4_o2.

  The carriageway (world frame, +x east, +y north; every figure here is this file's own):
    10  the junction, the square [-5, 5] × [-5, 5], lying on both ways
    11  the subject's approach: a lane x ∈ [0, 4], y ∈ [-30, -5], directed north, entering 10
    12  a stop line, x ∈ [0, 4], y ∈ [-8.2, -8.0] (in `crosswalkOnlyStructs` and `unmarkedStructs`
        it sits in the north leg instead and marks carrier 16, so no stop line marks carrier 11)
    13  a marked crosswalk, x ∈ [0, 4], y ∈ [-7.5, -5.5] (in `unmarkedStructs` it sits in the north
        leg and marks carrier 16, so no crosswalk marks carrier 11)
    14  the north–south way, 15 the east–west way (highways)
    16  the north leg's southbound approach, x ∈ [-4, 0], y ∈ [5, 30], entering 10
    17  the east leg's westbound approach, x ∈ [5, 30], y ∈ [-4, 0], entering 10
    device 1  a signal head governing 10, uncovered, showing dark, inoperative

  The subject (track 1) is a 4.8 m × 1.8 m car heading north along x = 2; it runs up the approach,
  halts with its front at the stop line (reference point y = -10.5), moves off, and comes to overlap
  the junction at y = -6.5. The other road user (track 2) is a van of the same size. Instants are
  one second apart; the staged positions are the witness's own and are not integrated from the
  sampled speeds.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- The four corners of an axis-aligned box, as `Build.rect` orders them. -/
def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- Half-length, half-width, half-height of both vehicles. -/
def half : Q × Q × Q := (cm 240, cm 90, cm 75)

-- Binders ↦ tracks: v ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def junction : Structure :=
  { Build.rect 10 .intersection (m (-5)) (m (-5)) (m 5) (m 5) with ways := some [14, 15] }

def approach : Structure :=
  { Build.lane 11 (box (m 0) (m (-30)) (m 4) (m (-5))) Build.north (enters := some 10) with
      ways := some [14] }

def northLeg : Structure :=
  { Build.lane 16 (box (m (-4)) (m 5) (m 0) (m 30)) Build.south (enters := some 10) with
      ways := some [14] }

def eastLeg : Structure :=
  { Build.lane 17 (box (m 5) (m (-4)) (m 30) (m 0)) Build.west (enters := some 10) with
      ways := some [15] }

def wayNS : Structure := Build.rect 14 .highway (m (-5)) (m (-40)) (m 5) (m 30)
def wayEW : Structure := Build.rect 15 .highway (m (-30)) (m (-5)) (m 30) (m 5)

/-- The stop line across the subject's approach, marking the carriers listed. -/
def stopLineSouth (marks : List RegionId) : Structure :=
  { Build.rect 12 .stopLine (m 0) (cm (-820)) (m 4) (cm (-800)) with
      entranceOf := marks, entranceObserved := true, ways := some [14] }

/-- The marked crosswalk across the subject's approach, marking the carriers listed. -/
def crosswalkSouth (marks : List RegionId) : Structure :=
  { Build.rect 13 .crosswalk (m 0) (cm (-750)) (m 4) (cm (-550)) with
      marked := some true, entranceOf := marks, entranceObserved := true, ways := some [14] }

/-- The same line and crossing in the north leg, marking carrier 16 only. -/
def stopLineNorth : Structure :=
  { Build.rect 12 .stopLine (m (-4)) (cm 800) (m 0) (cm 820) with
      entranceOf := [16], entranceObserved := true, ways := some [14] }

def crosswalkNorth : Structure :=
  { Build.rect 13 .crosswalk (m (-4)) (cm 550) (m 0) (cm 750) with
      marked := some true, entranceOf := [16], entranceObserved := true, ways := some [14] }

def darkSignal : Device :=
  { Build.signal 1 [10] [.dark] with uncovered := some true, inoperative := some true }

/-- A stop line and a crosswalk mark the subject's approach. -/
def markedStructs : List Structure :=
  [junction, approach, stopLineSouth [11], crosswalkSouth [11], wayNS, wayEW, northLeg, eastLeg]

/-- No stop line marks the subject's approach; a crosswalk does. -/
def crosswalkOnlyStructs : List Structure :=
  [junction, approach, stopLineNorth, crosswalkSouth [11], wayNS, wayEW, northLeg, eastLeg]

/-- Neither a stop line nor a crosswalk marks the subject's approach. -/
def unmarkedStructs : List Structure :=
  [junction, approach, stopLineNorth, crosswalkNorth, wayNS, wayEW, northLeg, eastLeg]

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------
def carAt (pos : Vec) (speed : Q) : RoadUser := Build.user 1 [.motorVehicle] pos Build.north speed half
def vanAt (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle, .truck] pos heading speed half

/-- The sight along each way from the subject's eye, as the source reports it. -/
def withSight (u : RoadUser) : RoadUser := { u with sightAlongWay := some [(14, m 150), (15, m 120)] }

def carUpstream : RoadUser := carAt (m 2, m (-33)) (mps 6)
def carOnApproach : RoadUser := carAt (m 2, m (-21)) (mps 6)
def carHalted : RoadUser := carAt (m 2, cm (-1050)) (mps 0)
def carRollingThrough : RoadUser := carAt (m 2, cm (-1050)) (mps 4)
def carHaltedBack : RoadUser := carAt (m 2, m (-12)) (mps 0)
def carMovingOff : RoadUser := carAt (m 2, cm (-950)) (mps 2)
def carEntering (speed : Q) : RoadUser := carAt (m 2, cm (-650)) speed
def carInside (speed : Q) : RoadUser := carAt (m 2, cm (-350)) speed
def carAcross (speed : Q) : RoadUser := carAt (m 2, cm (-50)) speed
def carFarAcross (speed : Q) : RoadUser := carAt (m 2, cm 250) speed
def carTouchingVan : RoadUser := carAt (m 2, cm 470) (mps 0)
def carBesideVan : RoadUser := carAt (m 2, cm 350) (mps 3)

def vanAtNorthEntrance : RoadUser := vanAt (m (-2), cm 760) Build.south (mps 0)
def vanEnteringJunction : RoadUser := vanAt (m (-2), m 2) Build.south (mps 5)
def vanCrossingJunction : RoadUser := vanAt (m (-2), m (-1)) Build.south (mps 5)
def vanCrawlingInJunction : RoadUser := vanAt (m (-2), m (-1)) Build.south (mps 1)
def vanLeftJunction : RoadUser := vanAt (m (-2), m (-9)) Build.south (mps 5)
def vanWellSouth : RoadUser := vanAt (m (-2), m (-14)) Build.south (mps 5)
def vanFarSouth : RoadUser := vanAt (m (-2), m (-19)) Build.south (mps 5)
def vanStandingInJunction : RoadUser := vanAt (m (-3), m 4) Build.east (mps 0)
def vanAtNorthEdge : RoadUser := vanAt (cm (-60), m 8) Build.east (mps 0)
def vanEastAtRest : RoadUser := vanAt (m 8, m (-2)) Build.west (mps 0)
def vanEastMovingIn : RoadUser := vanAt (m 8, m (-2)) Build.west (mps 5)

-- ---------------------------------------------------------------------------------------------
-- Occupancy, as the source observes it: every region a footprint overlaps
-- ---------------------------------------------------------------------------------------------
def occUpstream : List (TrackId × RegionId) := [(1, 14)]
def occOnApproach : List (TrackId × RegionId) := [(1, 11), (1, 14)]
def occHalted : List (TrackId × RegionId) := [(1, 11), (1, 12), (1, 14)]
def occHaltedNoLine : List (TrackId × RegionId) := [(1, 11), (1, 14)]
def occMovingOff : List (TrackId × RegionId) := [(1, 11), (1, 12), (1, 13), (1, 14)]
def occMovingOffNoLine : List (TrackId × RegionId) := [(1, 11), (1, 13), (1, 14)]
def occMovingOffUnmarked : List (TrackId × RegionId) := [(1, 11), (1, 14)]
def occEntering : List (TrackId × RegionId) :=
  [(1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15)]
def occEnteringNoLine : List (TrackId × RegionId) := [(1, 10), (1, 11), (1, 13), (1, 14), (1, 15)]
def occEnteringUnmarked : List (TrackId × RegionId) := [(1, 10), (1, 11), (1, 14), (1, 15)]
def occInside : List (TrackId × RegionId) := [(1, 10), (1, 11), (1, 13), (1, 14), (1, 15)]
def occInsideUnmarked : List (TrackId × RegionId) := [(1, 10), (1, 11), (1, 14), (1, 15)]
def occAcross : List (TrackId × RegionId) := [(1, 10), (1, 14), (1, 15)]

def occVanNorthLeg : List (TrackId × RegionId) := [(2, 16), (2, 14)]
def occVanJunction : List (TrackId × RegionId) := [(2, 10), (2, 14), (2, 15)]
def occVanWay : List (TrackId × RegionId) := [(2, 14)]
def occVanEastLeg : List (TrackId × RegionId) := [(2, 17), (2, 15)]

def sceneOf (t : Timestamp) (users : List RoadUser) (structs : List Structure)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) users structs [darkSignal] (some occ)

-- ---------------------------------------------------------------------------------------------
-- The scenarios
-- ---------------------------------------------------------------------------------------------

/-- `forbid` (violated): A car halts at the stop line of its lane at a junction whose signal heads are installed, uncovered and dark, then accelerates into the junction at 8 m/s while a van that halted a moment earlier at the opposite entrance is already within the junction region: the subject enters while the van lies inside, and its speed is above the cautious bound. -/
def forbidTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanAtNorthEntrance] markedStructs (occUpstream ++ occVanNorthLeg)
    | 1 => sceneOf t [carOnApproach, vanAtNorthEntrance] markedStructs (occOnApproach ++ occVanNorthLeg)
    | 2 => sceneOf t [carHalted, vanEnteringJunction] markedStructs (occHalted ++ occVanJunction)
    | 3 => sceneOf t [carMovingOff, vanCrawlingInJunction] markedStructs (occMovingOff ++ occVanJunction)
    | 4 => sceneOf t [carEntering (mps 8), vanCrawlingInJunction] markedStructs (occEntering ++ occVanJunction)
    | 5 => sceneOf t [carInside (mps 8), vanCrawlingInJunction] markedStructs (occInside ++ occVanJunction)
    | _ => sceneOf t [carAcross (mps 8), vanCrawlingInJunction] markedStructs (occAcross ++ occVanJunction)

/-- `permit` (compliant): The same junction and inoperative signal. The car halts at its stop line and then crosses the junction at 3 m/s. No other road user is in the scene at all, so nothing is owed precedence and the verdict is still decided. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream] markedStructs occUpstream
    | 1 => sceneOf t [carOnApproach] markedStructs occOnApproach
    | 2 => sceneOf t [carHalted] markedStructs occHalted
    | 3 => sceneOf t [carMovingOff] markedStructs occMovingOff
    | 4 => sceneOf t [carEntering (mps 3)] markedStructs occEntering
    | 5 => sceneOf t [carInside (mps 3)] markedStructs occInside
    | _ => sceneOf t [carAcross (mps 3)] markedStructs occAcross

/-- `idle` (not_applicable): The same junction, the same dark heads, but the car never halts anywhere on its approach before entering the junction: the condition that it made such a stop does not hold, so this rule is not engaged and only the first node of the line judges the conduct. -/
def idleTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream] markedStructs occUpstream
    | 1 => sceneOf t [carOnApproach] markedStructs occOnApproach
    | 2 => sceneOf t [carRollingThrough] markedStructs occHalted
    | 3 => sceneOf t [carMovingOff] markedStructs occMovingOff
    | 4 => sceneOf t [carEntering (mps 3)] markedStructs occEntering
    | 5 => sceneOf t [carInside (mps 3)] markedStructs occInside
    | _ => sceneOf t [carAcross (mps 3)] markedStructs occAcross

/-- `blind` (unknown): The car halts at its stop line and moves off into the junction, but the source does not report whether the other road user's footprint overlaps the junction region, so whether a road user was within the intersection when the subject entered is unknown. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanStandingInJunction] markedStructs (occUpstream ++ occVanJunction)
    | 1 => sceneOf t [carOnApproach, vanStandingInJunction] markedStructs (occOnApproach ++ occVanJunction)
    | 2 => sceneOf t [carHalted, vanStandingInJunction] markedStructs (occHalted ++ occVanJunction)
    | 3 => sceneOf t [carMovingOff, vanStandingInJunction] markedStructs (occMovingOff ++ occVanJunction)
    | 4 => sceneOf t [carEntering (mps 3), vanStandingInJunction] markedStructs (occEntering ++ occVanJunction)
    | _ => sceneOf t [carInside (mps 3), vanStandingInJunction] markedStructs (occInside ++ occVanJunction)

/-- `branch_1` (compliant): The same junction and inoperative signal. The car halts at its stop line, a van that halted earlier at the opposite entrance is within the junction, and the car stays at rest until the van has left the junction region, then crosses at 3 m/s with a closest approach well clear of the clearance bound. -/
def branch_1Trace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanAtNorthEntrance] markedStructs (occUpstream ++ occVanNorthLeg)
    | 1 => sceneOf t [carOnApproach, vanAtNorthEntrance] markedStructs (occOnApproach ++ occVanNorthLeg)
    | 2 => sceneOf t [carHalted, vanEnteringJunction] markedStructs (occHalted ++ occVanJunction)
    | 3 => sceneOf t [carHalted, vanCrossingJunction] markedStructs (occHalted ++ occVanJunction)
    | 4 => sceneOf t [carHalted, vanLeftJunction] markedStructs (occHalted ++ occVanWay)
    | 5 => sceneOf t [carMovingOff, vanWellSouth] markedStructs (occMovingOff ++ occVanWay)
    | 6 => sceneOf t [carEntering (mps 3), vanFarSouth] markedStructs (occEntering ++ occVanWay)
    | _ => sceneOf t [carInside (mps 3), vanFarSouth] markedStructs (occInside ++ occVanWay)

/-- `branch_2` (violated): The car halts at its stop line, then crosses the junction at 3 m/s, below the cautious bound, but passes within half a metre of a van already within the junction, the closest approach under constant velocities falling below the clearance bound within the horizon: precedence is not granted even though the speed is low. (Here the van halted earlier at the east entrance and is moving in off its carrier as the car enters; their centres would pass 0.77 m apart within the horizon.) -/
def branch_2Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanEastAtRest] markedStructs (occUpstream ++ occVanEastLeg)
    | 1 => sceneOf t [carOnApproach, vanEastAtRest] markedStructs (occOnApproach ++ occVanEastLeg)
    | 2 => sceneOf t [carHalted, vanEastAtRest] markedStructs (occHalted ++ occVanEastLeg)
    | 3 => sceneOf t [carMovingOff, vanEastAtRest] markedStructs (occMovingOff ++ occVanEastLeg)
    | _ => sceneOf t [carEntering (mps 3), vanEastMovingIn] markedStructs (occEntering ++ occVanEastLeg)

/-- `branch_3` (compliant): No stop line marks the car's approach — the only line in the scene marks the opposite carrier — so the halt is owed before the crosswalk that does mark it; the car halts 0.6 m short of the crossing and then crosses the junction at 3 m/s with no other road user present. -/
def branch_3Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream] crosswalkOnlyStructs occUpstream
    | 1 => sceneOf t [carOnApproach] crosswalkOnlyStructs occOnApproach
    | 2 => sceneOf t [carHalted] crosswalkOnlyStructs occHaltedNoLine
    | 3 => sceneOf t [carMovingOff] crosswalkOnlyStructs occMovingOffNoLine
    | 4 => sceneOf t [carEntering (mps 3)] crosswalkOnlyStructs occEnteringNoLine
    | 5 => sceneOf t [carInside (mps 3)] crosswalkOnlyStructs occInside
    | _ => sceneOf t [carAcross (mps 3)] crosswalkOnlyStructs occAcross

/-- `branch_4` (compliant): Neither a stop line nor a crosswalk marks the car's approach, so the halt is owed where the sight along the crossing way reaches the view distance: the car halts 12 m short of the junction with 120 m of sight along that way, then crosses at 3 m/s with no other road user present. -/
def branch_4Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [withSight carUpstream] unmarkedStructs occUpstream
    | 1 => sceneOf t [withSight carOnApproach] unmarkedStructs occOnApproach
    | 2 => sceneOf t [withSight carHaltedBack] unmarkedStructs occHaltedNoLine
    | 3 => sceneOf t [withSight carMovingOff] unmarkedStructs occMovingOffUnmarked
    | 4 => sceneOf t [withSight (carEntering (mps 3))] unmarkedStructs occEnteringUnmarked
    | 5 => sceneOf t [withSight (carInside (mps 3))] unmarkedStructs occInsideUnmarked
    | _ => sceneOf t [withSight (carAcross (mps 3))] unmarkedStructs occAcross

/-- `branch_5` (violated): A van that halted at the north entrance stands just clear of the junction, angled east across the car's path. The car halts at its stop line, crosses at 3 m/s clear of the clearance bound, and then comes to rest against the van's body: the two touch while both are at rest, so nothing closes on anything and contact alone denies precedence. -/
def branch_5Trace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanAtNorthEdge] markedStructs (occUpstream ++ occVanNorthLeg)
    | 1 => sceneOf t [carOnApproach, vanAtNorthEdge] markedStructs (occOnApproach ++ occVanNorthLeg)
    | 2 => sceneOf t [carHalted, vanAtNorthEdge] markedStructs (occHalted ++ occVanNorthLeg)
    | 3 => sceneOf t [carMovingOff, vanAtNorthEdge] markedStructs (occMovingOff ++ occVanNorthLeg)
    | 4 => sceneOf t [carEntering (mps 3), vanAtNorthEdge] markedStructs (occEntering ++ occVanNorthLeg)
    | 5 => sceneOf t [carInside (mps 3), vanAtNorthEdge] markedStructs (occInside ++ occVanNorthLeg)
    | 6 => sceneOf t [carAcross (mps 3), vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)
    | 7 => sceneOf t [carFarAcross (mps 3), vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)
    | _ => sceneOf t [carTouchingVan, vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)

/-- `branch_6` (violated): The same scene, but the car does not touch the van: it passes it at 3 m/s with 1.2 m between the two bodies while their centres approach within the horizon, the centre distance at that approach staying clear of the clearance. The clearance between the bodies alone denies precedence. -/
def branch_6Trace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanAtNorthEdge] markedStructs (occUpstream ++ occVanNorthLeg)
    | 1 => sceneOf t [carOnApproach, vanAtNorthEdge] markedStructs (occOnApproach ++ occVanNorthLeg)
    | 2 => sceneOf t [carHalted, vanAtNorthEdge] markedStructs (occHalted ++ occVanNorthLeg)
    | 3 => sceneOf t [carMovingOff, vanAtNorthEdge] markedStructs (occMovingOff ++ occVanNorthLeg)
    | 4 => sceneOf t [carEntering (mps 3), vanAtNorthEdge] markedStructs (occEntering ++ occVanNorthLeg)
    | 5 => sceneOf t [carInside (mps 3), vanAtNorthEdge] markedStructs (occInside ++ occVanNorthLeg)
    | 6 => sceneOf t [carAcross (mps 3), vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)
    | 7 => sceneOf t [carFarAcross (mps 3), vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)
    | _ => sceneOf t [carBesideVan, vanAtNorthEdge] markedStructs (occAcross ++ occVanNorthLeg)

/-- `branch_7` (violated): The car halts at its stop line and then enters and crosses the empty junction at 8 m/s. Nothing is owed precedence, so the cautious-speed bound alone decides. -/
def branch_7Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream] markedStructs occUpstream
    | 1 => sceneOf t [carOnApproach] markedStructs occOnApproach
    | 2 => sceneOf t [carHalted] markedStructs occHalted
    | 3 => sceneOf t [carMovingOff] markedStructs occMovingOff
    | 4 => sceneOf t [carEntering (mps 8)] markedStructs occEntering
    | 5 => sceneOf t [carInside (mps 8)] markedStructs occInside
    | _ => sceneOf t [carAcross (mps 8)] markedStructs occAcross

/-- `branch_8` (violated): A van stands at rest within the junction, well clear of the car's path. The car halts at its stop line and enters the junction at 3 m/s while the van lies inside it: no contact, no closing approach and a lawful speed, so entering while a road user owed precedence is within the junction alone decides. -/
def branch_8Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream, vanStandingInJunction] markedStructs (occUpstream ++ occVanJunction)
    | 1 => sceneOf t [carOnApproach, vanStandingInJunction] markedStructs (occOnApproach ++ occVanJunction)
    | 2 => sceneOf t [carHalted, vanStandingInJunction] markedStructs (occHalted ++ occVanJunction)
    | 3 => sceneOf t [carMovingOff, vanStandingInJunction] markedStructs (occMovingOff ++ occVanJunction)
    | 4 => sceneOf t [carEntering (mps 3), vanStandingInJunction] markedStructs (occEntering ++ occVanJunction)
    | _ => sceneOf t [carInside (mps 3), vanStandingInJunction] markedStructs (occInside ++ occVanJunction)

/-- `branch_9` (violated): No stop line marks the car's approach, so the halt is owed before the crosswalk that marks it; the car halts there and then enters and crosses the empty junction at 8 m/s, above the cautious bound. -/
def branch_9Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [carUpstream] crosswalkOnlyStructs occUpstream
    | 1 => sceneOf t [carOnApproach] crosswalkOnlyStructs occOnApproach
    | 2 => sceneOf t [carHalted] crosswalkOnlyStructs occHaltedNoLine
    | 3 => sceneOf t [carMovingOff] crosswalkOnlyStructs occMovingOffNoLine
    | 4 => sceneOf t [carEntering (mps 8)] crosswalkOnlyStructs occEnteringNoLine
    | 5 => sceneOf t [carInside (mps 8)] crosswalkOnlyStructs occInside
    | _ => sceneOf t [carAcross (mps 8)] crosswalkOnlyStructs occAcross

/-- `branch_10` (violated): Neither a stop line nor a crosswalk marks the car's approach, so the halt is owed where the sight along the crossing way reaches the view distance; the car halts there and then enters and crosses the empty junction at 8 m/s, above the cautious bound. -/
def branch_10Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [withSight carUpstream] unmarkedStructs occUpstream
    | 1 => sceneOf t [withSight carOnApproach] unmarkedStructs occOnApproach
    | 2 => sceneOf t [withSight carHaltedBack] unmarkedStructs occHaltedNoLine
    | 3 => sceneOf t [withSight carMovingOff] unmarkedStructs occMovingOffUnmarked
    | 4 => sceneOf t [withSight (carEntering (mps 8))] unmarkedStructs occEnteringUnmarked
    | 5 => sceneOf t [withSight (carInside (mps 8))] unmarkedStructs occInsideUnmarked
    | _ => sceneOf t [withSight (carAcross (mps 8))] unmarkedStructs occAcross

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o2

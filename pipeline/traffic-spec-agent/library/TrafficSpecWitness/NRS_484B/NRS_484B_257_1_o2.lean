/-
  Witnesses for NRS_484B_257_1_o2.

  The carriageway, once, for every scene below (every figure here is the witness's own and appears
  nowhere in the rule; +x east, +y north, metres):

    region 1  the junction, the 12 m × 12 m square (0,0)–(12,12), lying on both ways
    region 2  the subject's approach: a lane from y = −60 to y = +12 in x ∈ [6.5, 10], designated
              north, its entrance end the junction, on way 4. It covers the junction, so a body
              crossing the junction still occupies the carrier it came in on
    region 3  the crossing approach: a lane from x = −60 to x = +12 in y ∈ [2.5, 6], designated
              east, its entrance end the junction, on way 5
    region 4  the north–south highway; region 5 the east–west highway (the through highway)
    region 6  a stop line, the band y ∈ [−3.0, −2.6] across the subject's lane, recorded as
              marking that lane's entrance (in the crosswalk scenes it is absent)
    region 7  a crosswalk, the band y ∈ [−2.4, −0.4] across the subject's lane, recorded as
              marking that lane's entrance (in the stop-line scenes it is absent)

  In the sight scene the stop line and the crosswalk stand on the crossing approach instead and
  are recorded as marking that lane, so the source records no mark for the subject's carrier.

  Devices: 1 a stop sign governing the subject's lane, 2 a yield sign governing it, 3 a traffic
  signal governing the junction, 4 a police officer directing traffic at the junction.

  Bodies are 4 m × 1.8 m (half-extents 2.0 m, 0.9 m, 0.8 m). The subject runs north in the middle
  of its lane, x = 8.25; the other vehicle runs east in the middle of the crossing lane, y = 4.25.
  Observations are one second apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- Centimetres per second, through the micrometre-per-second constructor. -/
def cmps (n : Int) : Q := Units.micrometresPerSecond (n * 10000)

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def junction : Structure :=
  { Build.rect 1 .intersection (m 0) (m 0) (m 12) (m 12) with ways := some [4, 5] }

def laneNS : Structure :=
  { Build.lane 2 [(cm 650, m (-60)), (m 10, m (-60)), (m 10, m 12), (cm 650, m 12)]
      Build.north (enters := some 1) with ways := some [4] }

def laneEW : Structure :=
  { Build.lane 3 [(m (-60), cm 250), (m 12, cm 250), (m 12, m 6), (m (-60), m 6)]
      Build.east (enters := some 1) with ways := some [5] }

def hwNS : Structure := Build.rect 4 .highway (m 4) (m (-60)) (m 12) (m 60)
def hwEW : Structure := Build.rect 5 .highway (m (-60)) (m 2) (m 60) (m 7)

/-- The stop line of the subject's approach. -/
def stopLine : Structure :=
  { Build.rect 6 .stopLine (cm 650) (m (-3)) (m 10) (cm (-260)) with
      entranceOf := [2], entranceObserved := true }

/-- The crosswalk on the near side of the junction, for the subject's approach. -/
def crosswalk : Structure :=
  { Build.rect 7 .crosswalk (cm 650) (cm (-240)) (m 10) (cm (-40)) with
      entranceOf := [2], entranceObserved := true, marked := some true }

/-- A stop line and a crosswalk recorded for the crossing approach, not the subject's. -/
def stopLineOther : Structure :=
  { Build.rect 6 .stopLine (m (-4)) (cm 250) (cm (-360)) (m 6) with
      entranceOf := [3], entranceObserved := true }

def crosswalkOther : Structure :=
  { Build.rect 7 .crosswalk (cm (-340)) (cm 250) (cm (-140)) (m 6) with
      entranceOf := [3], entranceObserved := true, marked := some true }

def mapStopLine : List Structure := [junction, laneNS, laneEW, hwNS, hwEW, stopLine]
def mapCrosswalk : List Structure := [junction, laneNS, laneEW, hwNS, hwEW, crosswalk]
def mapNoMark : List Structure := [junction, laneNS, laneEW, hwNS, hwEW, stopLineOther, crosswalkOther]

-- ---------------------------------------------------------------------------------------------
-- The devices
-- ---------------------------------------------------------------------------------------------
def stopSign : Device := { Build.sign 1 .stopSign [2] with conditions := some {} }
def yieldSign : Device := { Build.sign 2 .yieldSign [2] with conditions := some {} }
def trafficSignal : Device := Build.signal 3 [1] [.circularGreen]
def officer : Device :=
  { Build.device 4 .humanDirection [1] with
      humanRole := some .policeOfficer, humanIndication := some .stop }

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------
def car (track : TrackId) (x y : Q) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading speed (m 2, cm 90, cm 80)

/-- The subject northbound at y, at a speed. -/
def subj (y : Q) (speed : Q) : RoadUser := car 1 (cm 825) y Build.north speed
/-- The other vehicle eastbound at x, at a speed. -/
def other (x : Q) (speed : Q) : RoadUser := car 2 x (cm 425) Build.east speed

-- ---------------------------------------------------------------------------------------------
-- `forbid`
-- ---------------------------------------------------------------------------------------------
/-- `forbid` (violated): A car halts with its body 0.8 m short of the stop line recorded for its approach segment, under a stop sign recorded as governing that segment, then moves off into the junction at 4 m/s. A vehicle that entered the junction from the crossing highway, on which the junction also lies and on whose entrance the subject's sign stands, is crossing in front of it; under the two velocities the centres approach within the horizon to below the minimum clearance. -/
def forbidTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-580)) (mps 0)        -- halted, body 0.8 m short of the line
         | 1 => subj (cm (-280)) (mps 3)        -- rolling over the line, not yet in the junction
         | 2 => subj (cm 20) (mps 1)            -- within the junction
         | _ => subj (cm 120) (mps 1))
      , (match k with
         | 0 => other (m (-9)) (mps 9)          -- on the through highway, not in the junction
         | 1 => other (cm 50) (mps 9)           -- enters the junction here
         | 2 => other (m 3) (cmps 250)          -- crossing in front of the subject
         | _ => other (cm 550) (cmps 250)) ]
      mapStopLine
      [ stopSign ]

-- ---------------------------------------------------------------------------------------------
-- `permit`
-- ---------------------------------------------------------------------------------------------
/-- `permit` (compliant): The same halt and the same crossing vehicle, but the subject stays at rest at the line until the crossing vehicle has passed and only then moves into the junction; while it is moving within the junction no predicted closest approach within the horizon falls below the minimum clearance. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 3 => subj (cm 20) (mps 1)            -- moves in only now
         | _ => subj (cm (-580)) (mps 0))       -- at rest at the line
      , (match k with
         | 0 => other (m (-9)) (mps 9)
         | 1 => other (cm 50) (mps 9)           -- enters the junction here
         | 2 => other (cm 550) (mps 9)
         | _ => other (m 11) (mps 9)) ]         -- leaving, east of the subject's path
      mapStopLine
      [ stopSign ]

-- ---------------------------------------------------------------------------------------------
-- `idle`
-- ---------------------------------------------------------------------------------------------
/-- `idle` (not_applicable): The subject halts at the line, moves into the junction and crosses it with no other road user anywhere in the scene, so no vehicle has entered from the through highway and none approaches on it; the verdict is decided with the subject alone. The scene records no sign erected for the approach, so the clause's trigger is decided false with the subject alone. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-580)) (mps 0)
         | 1 => subj (cm (-280)) (mps 3)
         | 2 => subj (cm 20) (mps 3)
         | _ => subj (cm 320) (mps 3)) ]
      mapStopLine
      [ ]

-- ---------------------------------------------------------------------------------------------
-- `blind`
-- ---------------------------------------------------------------------------------------------
/-- `blind` (unknown): The same halt and the same crossing vehicle, but the source declares no footprint overlap for any region, so neither the subject's being within the junction nor the other vehicle's entry can be decided and the rule reports unknown. -/
def blindTrace : Trace := forbidTrace

-- ---------------------------------------------------------------------------------------------
-- `branch_1`
-- ---------------------------------------------------------------------------------------------
/-- `branch_1` (violated): A yield sign, not a stop sign, governs the approach; the subject passes the crosswalk recorded for its carrier at 3 m/s without halting, which satisfies the slowed branch of the condition, and then moves within the junction while a vehicle on the through highway is 30 m away at 15 m/s, so it would reach the junction within the arrival time; the predicted centre closest approach within the horizon falls below the minimum clearance. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-520)) (mps 3)        -- body 0.8 m short of the crosswalk, at 3 m/s
         | 1 => subj (cm (-220)) (mps 3)        -- over the crosswalk
         | _ => subj (cm 80) (mps 2))           -- within the junction
      , (match k with
         | 0 => other (m (-50)) (mps 15)
         | 1 => other (m (-40)) (mps 15)
         | _ => other (m (-30)) (mps 15)) ]     -- 28 m of body-to-junction at 15 m/s
      mapCrosswalk
      [ yieldSign ]

-- ---------------------------------------------------------------------------------------------
-- `branch_2`
-- ---------------------------------------------------------------------------------------------
/-- `branch_2` (not_applicable): The same sign and the same crossing vehicle, but the subject has come to rest within the junction and stays at rest at the judged observation, its speed below the motion tolerance, so it is not moving across or within the intersection and the clause's condition does not hold. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-520)) (mps 3)
         | 1 => subj (cm (-220)) (mps 3)
         | _ => subj (cm 80) (cmps 10))         -- 0.1 m/s: at rest within the junction
      , (match k with
         | 0 => other (m (-50)) (mps 15)
         | 1 => other (m (-40)) (mps 15)
         | _ => other (m (-30)) (mps 15)) ]
      mapCrosswalk
      [ yieldSign ]

-- ---------------------------------------------------------------------------------------------
-- `branch_3`: the place of the first sentence where the source records no mark
-- ---------------------------------------------------------------------------------------------
/-- `branch_3` (violated): the source records the stop line and the crosswalk as marking the
    crossing approach, not the subject's carrier, so the place is the point on the carrier at
    which the view along the through highway reaches the sight distance: the subject halts there
    with 150 m of view, then moves within the junction while a vehicle on the through highway is
    28 m of body-to-junction away at 15 m/s. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { (match k with
           | 0 => subj (cm (-520)) (mps 0)      -- halted, 150 m of view along the through highway
           | 1 => subj (cm (-220)) (mps 3)
           | _ => subj (cm 80) (mps 2)) with
          sightAlongWay := some [(5, m 150)] }
      , (match k with
         | 0 => other (m (-50)) (mps 15)
         | 1 => other (m (-40)) (mps 15)
         | _ => other (m (-30)) (mps 15)) ]
      mapNoMark
      [ stopSign ]

-- ---------------------------------------------------------------------------------------------
-- `branch_4`: the search back for the halt ends upstream of the stopping zone
-- ---------------------------------------------------------------------------------------------
/-- `branch_4` (not_applicable): the subject halts at the line, then rolls back out of the line's
    stopping zone — 6 m short of it, beyond the stop-point tolerance — and creeps into the
    junction without halting again. The search back for the halt ends at that upstream
    observation, so the condition does not hold and the clause does not apply. -/
def branch_4Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-580)) (mps 0)        -- halted at the line
         | 1 => Build.withKin (subj (m (-9)) (mps 1))
                  (fun kin => { kin with velocity := some (Build.scale Build.south (mps 1)) })
         | 2 => subj (m (-5)) (mps 3)           -- creeping forward again, not halted
         | _ => subj (cm 50) (mps 3)) ]         -- within the junction
      mapStopLine
      [ stopSign ]

-- ---------------------------------------------------------------------------------------------
-- `branch_5`, `branch_6`: the exception
-- ---------------------------------------------------------------------------------------------
/-- `branch_5` (not_applicable): the `forbid` scene with a traffic signal recorded as governing
    the junction, so the traffic the subject belongs to is being controlled there and the
    subsection does not apply. -/
def branch_5Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-580)) (mps 0)
         | 1 => subj (cm (-280)) (mps 3)
         | 2 => subj (cm 20) (mps 1)
         | _ => subj (cm 120) (mps 1))
      , (match k with
         | 0 => other (m (-9)) (mps 9)
         | 1 => other (cm 50) (mps 9)
         | 2 => other (m 3) (cmps 250)
         | _ => other (cm 550) (cmps 250)) ]
      mapStopLine
      [ stopSign, trafficSignal ]

/-- `branch_6` (not_applicable): the `forbid` scene with a police officer recorded as directing
    traffic at the junction, the other limb of the exception. -/
def branch_6Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (cm (-580)) (mps 0)
         | 1 => subj (cm (-280)) (mps 3)
         | 2 => subj (cm 20) (mps 1)
         | _ => subj (cm 120) (mps 1))
      , (match k with
         | 0 => other (m (-9)) (mps 9)
         | 1 => other (cm 50) (mps 9)
         | 2 => other (m 3) (cmps 250)
         | _ => other (cm 550) (cmps 250)) ]
      mapStopLine
      [ stopSign, officer ]

-- ---------------------------------------------------------------------------------------------
-- `history_boundary`
-- ---------------------------------------------------------------------------------------------
/-- `history_boundary` (unknown): The recording begins with the subject already inside the junction at 4 m/s, with a stop sign recorded as governing the segment it came in on and a vehicle crossing from the through highway; no halt at the line is recorded, and the search back for the stop reaches the subject's first observation without reaching an observation at which it was off the line, short of it and farther from it than the stop-point tolerance, and without a previous entry into that junction, so whether the condition held cannot be decided. -/
def history_boundaryTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => subj (m 2) (mps 3)              -- already within the junction
         | 1 => subj (m 5) (mps 3)
         | _ => subj (m 8) (mps 3))
      , (match k with
         | 0 => other (m 3) (cmps 250)
         | 1 => other (cm 550) (cmps 250)
         | _ => other (m 8) (cmps 250)) ]
      mapStopLine
      [ stopSign ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the part of the approach upstream of the stop line's stopping zone, before the recording begins, at which the halt would have been recorded") ]

end TrafficSpecWitness.NRS_484B_257_1_o2

/-
  Witnesses for NRS_484B_257_2_o1.

  One carriageway for every scene, eastbound, built once below and shared:

    * region 1, the approach lane: x from -60 m to 0 m, y from -2 m to 2 m, designated direction
      east, its entrance end the junction (region 10).
    * region 10, the junction: x from 0 m to 14 m, y from -7 m to 7 m — two minor streets meeting,
      neither a through highway, so no witness records the ways at the junction as one.
    * region 20, the stop line: x from -3.4 m to -3.1 m across the lane. Which carriers' entrances
      it marks is the scene's record: `[1]` where it marks the approach, `[]` where its entrances
      are observed and exclude it.
    * region 21, the crosswalk: x from -2.4 m to -0.4 m across the lane, marked.
    * region 30, the through highway the junction lies on, read only for the view along it.

  The car is track 1: 5 m long, 1.8 m wide, its reference point at the centre, heading east, so its
  body runs from x - 2.5 m to x + 2.5 m. Occupancy is stated scene by scene from that body, not
  derived from the reference point, since the body lies across the line, the crossing and the
  junction at the instants that matter. Distances quoted below are from the body to the region.

  Every figure here is the witness's own and appears nowhere in the rule: the reading's bounds
  (1.5 m to the place, 0.3 m/s for a halt, 4.5 m/s on a yield approach, 120 m of view) are broken or
  kept by a clear margin in the scenes, never named.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_2_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_2_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A speed in centimetres per second, through the micrometre-per-second constructor. -/
def cmps (n : Int) : Q := Units.micrometresPerSecond (n * 10000)

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The carriageway
-- ---------------------------------------------------------------------------------------------

/-- The approach lane, an eastbound carrier whose entrance end is the junction. -/
def approachLane : Structure :=
  { Build.lane 1 [(m (-60), m (-2)), (m 0, m (-2)), (m 0, m 2), (m (-60), m 2)] Build.east
      (enters := some 10) with ways := some [30] }

/-- The junction of the two minor streets. -/
def junction : Structure := { Build.rect 10 .intersection (m 0) (m (-7)) (m 14) (m 7) with ways := some [30] }

/-- The through highway the junction lies on; the view along it is read from the car. -/
def throughWay : Structure := Build.rect 30 .highway (m (-60)) (m (-8)) (m 20) (m 8)

/-- The stop line across the approach, marking the entrances the scene records. -/
def stopLine (marks : List RegionId) : Structure :=
  { Build.rect 20 .stopLine (cm (-340)) (m (-2)) (cm (-310)) (m 2) with
      entranceOf := marks, entranceObserved := true, ways := some [30] }

/-- The crosswalk across the approach, marking the entrances the scene records. -/
def crossing (marks : List RegionId) : Structure :=
  { Build.rect 21 .crosswalk (cm (-240)) (m (-2)) (cm (-40)) (m 2) with
      marked := some true, entranceOf := marks, entranceObserved := true, ways := some [30] }

def stopSign : Device := Build.sign 100 .stopSign [1]
def yieldSign : Device := Build.sign 101 .yieldSign [1]
/-- A signal head governing the junction itself, showing green to the approach. -/
def greenSignal : Device := Build.signal 102 [10] [.circularGreen]
/-- A police officer directing traffic at the junction. -/
def officer : Device :=
  { Build.device 103 .humanDirection [10] with
      humanRole := some .policeOfficer, humanIndication := some .stop }

-- ---------------------------------------------------------------------------------------------
-- Scenes
-- ---------------------------------------------------------------------------------------------

/-- The regions of the carriageway the car's body overlaps with its reference point at `x`:
    the lane, the mark regions the scene holds (`present`), the junction, and the highway. -/
def bodyOverlaps (x : Q) (present : List RegionId) : List RegionId :=
  let front := Q.add x (cm 250)
  let rear := Q.sub x (cm 250)
  let meets (a b : Q) : Bool := Q.lt a front && Q.lt rear b
  (if meets (m (-60)) (m 0) then [1] else []) ++
  (if present.contains 20 && meets (cm (-340)) (cm (-310)) then [20] else []) ++
  (if present.contains 21 && meets (cm (-240)) (cm (-40)) then [21] else []) ++
  (if meets (m 0) (m 14) then [10] else []) ++ [30]

/-- One observation: the car at `x` on the lane centre at speed `v`, with the view along the
    through highway the source reports, and the regions its body overlaps. -/
def carScene (t : Timestamp) (x v : Q) (sts : List Structure) (devs : List Device)
    (present : List RegionId) (sight : Q) (reversing : Bool := false) : Scene :=
  let u := Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v (cm 250, cm 90, cm 75)
  let u := { u with sightAlongWay := some [(30, sight)] }
  let u := if reversing then Build.withKin u (fun k => { k with velocity := some (Build.scale Build.west v) }) else u
  Build.scene t (some 1) [u] sts devs (some ((bodyOverlaps x present).map fun r => (1, r)))

/-- The scene of a stop-sign approach with the stop line marking it. -/
def stopScene (t : Timestamp) (x v : Q) (extra : List Device) : Scene :=
  carScene t x v [approachLane, junction, throughWay, stopLine [1]] (stopSign :: extra) [20] (m 150)

/-- The scene of a yield-sign approach with no stop line and the crosswalk marking it. -/
def yieldScene (t : Timestamp) (x v : Q) : Scene :=
  carScene t x v [approachLane, junction, throughWay, crossing [1]] [yieldSign] [21] (m 150)

-- ---------------------------------------------------------------------------------------------
-- The witnesses
-- ---------------------------------------------------------------------------------------------

/-- `forbid` (violated): A car approaches a four-way junction of two minor streets, neither a
    through highway, where stop signs stand at every entrance; a stop sign is recorded as governing
    the segment it occupies and a stop line is recorded as marking that segment's entrance. From
    40 m short of the line, outside the stopping zone, it runs on at 8 m/s and its footprint
    overlaps the junction three seconds later, never halting within the stop-point tolerance of the
    line.

    As built: quarter-second observations at a steady 8 m/s from 6.1 m short of the line (outside
    the stopping zone, where the search back from the entry ends) through 0.1 m short of it to the
    entry; no observation is a halt. -/
def forbidStep : Nat → Q × Q
  | 0 => (m (-12), cmps 800)
  | 1 => (m (-10), cmps 800)
  | 2 => (m (-8), cmps 800)
  | 3 => (m (-6), cmps 800)
  | 4 => (m (-4), cmps 800)
  | _ => (m (-2), cmps 800)

def forbidTrace : Trace :=
  Build.trace 6 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := forbidStep k
    stopScene t x v []

/-- `permit` (compliant): The same junction and sign; the car comes from 40 m short of the line,
    halts with its body 0.9 m short of the line, off the line and off the junction, and then enters
    the junction.

    As built: from 6.1 m short of the line at 8 m/s, braking to rest for two observations with its
    body 0.9 m short of the line, off the line and off the junction, then away and into the
    junction. -/
def permitStep : Nat → Q × Q
  | 0 => (m (-12), cmps 800)
  | 1 => (m (-10), cmps 800)
  | 2 => (cm (-830), cmps 600)
  | 3 => (cm (-720), cmps 300)
  | 4 => (cm (-680), cmps 0)
  | 5 => (cm (-680), cmps 0)
  | 6 => (cm (-640), cmps 200)
  | 7 => (cm (-550), cmps 500)
  | 8 => (m (-4), cmps 600)
  | _ => (m (-2), cmps 700)

def permitTrace : Trace :=
  Build.trace 10 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := permitStep k
    stopScene t x v []

/-- `idle` (not_applicable): A car crosses the same junction with no stop sign and no yield sign
    recorded as governing any segment it occupies, and no other road user in the scene, so the
    trigger fails and the duty does not arise. -/
def idleStep : Nat → Q × Q
  | 0 => (m (-8), cmps 800)
  | 1 => (m (-6), cmps 800)
  | 2 => (m (-4), cmps 800)
  | _ => (m (-2), cmps 800)

def idleTrace : Trace :=
  Build.trace 4 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := idleStep k
    carScene t x v [approachLane, junction, throughWay] [] [] (m 150)

/-- `blind` (unknown): The same approach and stop sign, with a stop line and a crosswalk mapped on
    the way, but the source does not observe which carriers' entrances they mark, so which place
    governs the approach cannot be decided and the rule reports unknown.

    As built: the `permit` approach and halt, with both marks in the scene; `st.entrance_of` is
    absent from the manifest, so neither mark's record decides whether it marks the approach. -/
def blindTrace : Trace :=
  Build.trace 10 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := permitStep k
    carScene t x v [approachLane, junction, throughWay, stopLine [1], crossing [1]] [stopSign]
      [20, 21] (m 150)

/-- `branch_1` (compliant): A yield sign, not a stop sign, is recorded as governing the approach
    segment, no stop line is recorded for it and a crosswalk is recorded as marking its entrance;
    the car passes the crosswalk at 3 m/s, below the yield-approach speed, and enters the junction
    without halting.

    As built: half-second observations at a steady 3 m/s, from 4.7 m short of the crossing (outside
    its stopping zone) through 0.2 m short of it to the entry. -/
def branch_1Step : Nat → Q × Q
  | 0 => (cm (-960), cmps 300)
  | 1 => (cm (-810), cmps 300)
  | 2 => (cm (-660), cmps 300)
  | 3 => (cm (-510), cmps 300)
  | 4 => (cm (-360), cmps 300)
  | _ => (cm (-210), cmps 300)

def branch_1Trace : Trace :=
  Build.trace 6 0 (Units.milliseconds 500) fun k t =>
    let (x, v) := branch_1Step k
    yieldScene t x v

/-- `branch_2` (not_applicable): The same approach and stop sign, but a traffic signal is recorded
    as governing the junction and is showing a circular green to the subject's approach: traffic is
    being controlled by a traffic-control signal and the subsection does not apply. -/
def branch_2Trace : Trace :=
  Build.trace 6 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := forbidStep k
    stopScene t x v [greenSignal]

/-- `history_boundary` (unknown): The recording begins with the car already short of the stop line,
    inside the stopping zone, moving at 2 m/s, and it enters the junction a second later; no halt is
    recorded, and the search back from the entry reaches the subject's first observation without
    reaching an observation at which it was off the line, short of it and farther from it than the
    stop-point tolerance, and without a previous entry into that junction.

    As built: the first observation has the body 0.6 m short of the line — inside the stopping zone
    the reading sets, so no observation of the trace is the approach start the search needs. -/
def history_boundaryStep : Nat → Q × Q
  | 0 => (cm (-650), cmps 200)
  | 1 => (cm (-600), cmps 200)
  | 2 => (cm (-540), cmps 300)
  | 3 => (cm (-440), cmps 400)
  | 4 => (cm (-320), cmps 500)
  | _ => (cm (-200), cmps 600)

def history_boundaryTrace : Trace :=
  Build.trace 6 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := history_boundaryStep k
    stopScene t x v []

/-- `branch_3` (compliant): no mark governs the approach — a stop line and a crosswalk are mapped
    and their entrances are observed to exclude the segment — so the place is the point with the
    view along the through highway; the car halts there, with 130 m of view, and enters. -/
def branch_3Step : Nat → Q × Q × Q
  | 0 => (m (-12), cmps 600, m 40)
  | 1 => (m (-9), cmps 600, m 60)
  | 2 => (cm (-650), cmps 400, m 90)
  | 3 => (cm (-550), cmps 0, m 130)
  | 4 => (m (-4), cmps 400, m 140)
  | _ => (m (-2), cmps 600, m 150)

def branch_3Trace : Trace :=
  Build.trace 6 0 (Units.milliseconds 500) fun k t =>
    let (x, v, sight) := branch_3Step k
    carScene t x v [approachLane, junction, throughWay, stopLine [], crossing []] [stopSign]
      [20, 21] sight

/-- `branch_4` (not_applicable): the same approach and stop sign, but a police officer is recorded
    directing traffic at the junction, indication given: the traffic the car is part of is being
    controlled by an officer and the subsection does not apply. -/
def branch_4Trace : Trace :=
  Build.trace 6 0 (Units.milliseconds 250) fun k t =>
    let (x, v) := forbidStep k
    stopScene t x v [officer]

/-- `branch_5` (violated): the yield-sign approach of `branch_1`, taken at 6 m/s — above the
    yield-approach speed — with no halt: the car is observed 1.1 m short of the crossing, inside its
    stopping zone, still at 6 m/s, and enters the junction. -/
def branch_5Step : Nat → Q × Q
  | 0 => (m (-12), cmps 600)
  | 1 => (m (-9), cmps 600)
  | 2 => (m (-6), cmps 600)
  | 3 => (m (-3), cmps 600)
  | _ => (m 0, cmps 600)

def branch_5Trace : Trace :=
  Build.trace 5 0 (Units.milliseconds 500) fun k t =>
    let (x, v) := branch_5Step k
    yieldScene t x v

/-- `branch_6` (violated): the stop-sign approach of `forbid`, rolled through at 3 m/s — within the
    yield-approach speed, but no sign that yields governs this approach, and a stop sign asks for a
    halt: the car is observed 0.1 m short of the line at 3 m/s and never halts. -/
def branch_6Step : Nat → Q × Q
  | 0 => (cm (-1050), cmps 300)
  | 1 => (m (-9), cmps 300)
  | 2 => (cm (-750), cmps 300)
  | 3 => (m (-6), cmps 300)
  | 4 => (cm (-450), cmps 300)
  | 5 => (m (-3), cmps 300)
  | _ => (cm (-150), cmps 300)

def branch_6Trace : Trace :=
  Build.trace 7 0 (Units.milliseconds 500) fun k t =>
    let (x, v) := branch_6Step k
    stopScene t x v []

/-- `branch_7` (violated): two entries into the same junction, one act. The car halts 1.1 m short
    of the line, enters the junction, reverses clear of it without ever leaving the line's stopping
    zone, and enters again: the second entry owes its own act and no act is recorded after the
    first entry. -/
def branch_7Step : Nat → Q × Q × Bool
  | 0 => (m (-9), cmps 400, false)
  | 1 => (m (-7), cmps 0, false)
  | 2 => (m (-5), cmps 400, false)
  | 3 => (m (-2), cmps 200, false)
  | 4 => (cm (-350), cmps 150, true)
  | _ => (m (-2), cmps 150, false)

def branch_7Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let (x, v, back) := branch_7Step k
    carScene t x v [approachLane, junction, throughWay, stopLine [1]] [stopSign] [20] (m 150) back

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_2_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the part of the approach upstream of the stop line's stopping zone, before the recording begins, at which the halt would have been recorded")
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_2_o1

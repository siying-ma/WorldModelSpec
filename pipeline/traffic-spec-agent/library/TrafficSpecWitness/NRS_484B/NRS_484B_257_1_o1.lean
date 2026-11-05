/-
  Witnesses for NRS_484B_257_1_o1.

  The geometry, once, for every scene below (world frame, +x east; every figure is the witness's
  own and appears nowhere in the rule):

    - region 10, the approach lane: x ∈ [-60, 0] m, y ∈ [-3.5, 0] m, designated direction east,
      its entrance end the junction (region 1);
    - region 1, the junction: x ∈ [0, 14] m, y ∈ [-7, 7] m;
    - region 20, the stop line: x ∈ [-4.2, -4.0] m across the lane, recorded as marking region 10's
      entrance (except in `blind`, where its entrances are not observed);
    - region 21, the crossing on the near side: x ∈ [-3.0, -0.5] m across the lane, likewise;
    - region 30, the through highway the junction carries: x ∈ [0, 14] m, y ∈ [-60, 60] m.

  The car is 4.8 m long and 1.8 m wide (half-extents 2.4 m, 0.9 m, 0.75 m), runs east along the
  lane's centre line y = -1.75 m, and its occupancy is stated as footprint overlap, which for this
  body is the range of its reference point `x` named in `overlapRanges` — the reference point alone
  would put a body astride the stop line in one region only. Observations are one second apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The lane's centre line. -/
def carY : Q := cm (-175)

/-- The approach lane, its entrance end the junction. -/
def laneR : Structure :=
  Build.lane 10
    [(cm (-6000), cm (-350)), (cm 0, cm (-350)), (cm 0, cm 0), (cm (-6000), cm 0)]
    Build.east (enters := some 1)

/-- The junction the lane runs into. -/
def junctionR : Structure := Build.rect 1 .intersection (cm 0) (cm (-700)) (cm 1400) (cm 700)

/-- The stop line, recorded as marking the approach lane's entrance. -/
def stopLineR : Structure :=
  { Build.rect 20 .stopLine (cm (-420)) (cm (-350)) (cm (-400)) (cm 0) with
    entranceOf := [10], entranceObserved := true }

/-- The crossing on the near side, recorded as marking the approach lane's entrance. -/
def crossR : Structure :=
  { Build.rect 21 .crosswalk (cm (-300)) (cm (-350)) (cm (-50)) (cm 0) with
    entranceOf := [10], entranceObserved := true }

/-- The same line and crossing, mapped on the way, with their entrances not observed. -/
def stopLineBlind : Structure :=
  { Build.rect 20 .stopLine (cm (-420)) (cm (-350)) (cm (-400)) (cm 0) with
    entranceOf := [], entranceObserved := false }
def crossBlind : Structure :=
  { Build.rect 21 .crosswalk (cm (-300)) (cm (-350)) (cm (-50)) (cm 0) with
    entranceOf := [], entranceObserved := false }

/-- The through highway the junction carries. -/
def highwayR : Structure := Build.rect 30 .highway (cm 0) (cm (-6000)) (cm 1400) (cm 6000)

/-- Another approach to the same junction, from the south: the lane the `idle` scene's sign governs. -/
def otherLaneR : Structure :=
  Build.lane 11
    [(cm 0, cm (-6000)), (cm 350, cm (-6000)), (cm 350, cm (-700)), (cm 0, cm (-700))]
    Build.north (enters := some 1)

def stopSign : Device := Build.sign 50 .stopSign [10]
def yieldSign : Device := Build.sign 51 .yieldSign [10]
/-- A stop sign erected for the southern approach, not for the subject's. -/
def otherStopSign : Device := Build.sign 52 .stopSign [11]
/-- A police officer directing the junction's traffic, waving traffic on. -/
def officer : Device :=
  { Build.device 53 .humanDirection [1] with
    humanRole := some .policeOfficer, humanIndication := some .proceed }
/-- A signal head controlling the junction. -/
def junctionSignal : Device := Build.signal 54 [1] [.circularGreen]

/-- The regions the car's body overlaps, each as the range of its reference point `x` over which
    the overlap holds (the lane, the junction, the stop line, the crossing). -/
def overlapRanges : List (RegionId × Q × Q) :=
  [ (10, cm (-6240), cm 240)
  , (1, cm (-240), cm 1640)
  , (20, cm (-660), cm (-160))
  , (21, cm (-540), cm 190) ]

/-- The occupancy of the car at `x`, over the regions the scene holds. -/
def occupancy (x : Q) (present : List RegionId) : List (TrackId × RegionId) :=
  overlapRanges.filterMap fun (r, lo, hi) =>
    if present.contains r && Q.le lo x && Q.le x hi then some ((1 : TrackId), r) else none

/-- One observation: the car at `x` with `speed`, seeing `sight` along the through highway. -/
def shot (t : Timestamp) (cls : List RoadUserClass) (x speed sight : Q)
    (structures : List Structure) (devices : List Device) : Scene :=
  Build.scene t (some 1)
    [ { Build.user 1 cls (x, carY) Build.east speed (cm 240, cm 90, cm 75) with
        sightAlongWay := some [(30, sight)] } ]
    structures devices
    (some (occupancy x (structures.map (·.id))))

/-- A trace of `xs.length` observations one second apart. -/
def approach (cls : List RoadUserClass) (xs speeds sights : List Q)
    (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace xs.length 0 (Units.seconds 1) fun k t =>
    shot t cls (xs.getD k Q.zero) (speeds.getD k Q.zero) (sights.getD k Q.zero) structures devices

def car : List RoadUserClass := [.motorVehicle]
def sixSights : List Q := [m 150, m 150, m 150, m 150, m 150, m 150]

/-- The signed approach: the car runs on from 40 m short of the line to the junction at 9 m/s. -/
def runOnXs : List Q := [cm (-4500), cm (-3600), cm (-2700), cm (-1800), cm (-900), cm 0]
def runOnSpeeds : List Q := [m 9, m 9, m 9, m 9, m 9, m 9]

def markedStructures : List Structure := [laneR, junctionR, stopLineR, crossR, highwayR]

/-- `forbid` (violated): A car approaches a T-junction on a mapped approach segment whose entrance end is the junction; a stop sign is recorded as governing that segment and a stop line is recorded as marking that segment's entrance. From an observation 40 m short of the line, where it is well outside the stopping zone, the car runs on at 9 m/s and its footprint first overlaps the junction two seconds later; at no observation of that approach is it halted within the stop-point tolerance of the line. -/
def forbidTrace : Trace :=
  approach car runOnXs runOnSpeeds sixSights markedStructures [stopSign]

/-- `permit` (compliant): The same junction, sign and line; the car comes from 40 m short of the line, halts with its body 0.8 m short of the line and off it and off the junction, and then enters the junction. -/
def permitTrace : Trace :=
  approach car
    [cm (-4500), cm (-2000), cm (-740), cm (-400), cm (-100), cm 400]
    [m 9, m 9, Q.zero, m 3, m 4, m 5]
    sixSights markedStructures [stopSign]

/-- `idle` (not_applicable): A car crosses the same junction with no stop sign and no yield sign recorded as governing any segment it occupies, and no other road user in the scene; no proper sign has been erected for its approach, so the duty does not arise. -/
def idleTrace : Trace :=
  approach car
    [cm (-2000), cm (-1000), cm (-100), cm 800]
    [m 9, m 9, m 9, m 9]
    [m 150, m 150, m 150, m 150]
    [laneR, junctionR, otherLaneR, highwayR] [otherStopSign]

/-- `blind` (unknown): The same approach and stop sign, with a stop line and a crosswalk mapped on the way, but the source does not observe which carriers' entrances the line and the crossing mark, so which place governs the approach cannot be decided and the rule reports unknown. -/
def blindTrace : Trace :=
  approach car
    [cm (-4500), cm (-2000), cm (-740), cm (-400), cm (-100), cm 400]
    [m 9, m 9, Q.zero, m 3, m 4, m 5]
    sixSights [laneR, junctionR, stopLineBlind, crossBlind, highwayR] [stopSign]

/-- `branch_1` (compliant): A yield sign, not a stop sign, is recorded as governing the approach segment, and no stop line is recorded for it while a crosswalk is recorded as marking its entrance. The car passes the crosswalk at 3 m/s, below the yield-approach speed, without halting, and enters the junction: the yield branch of the act is satisfied at the place the words give second. -/
def branch_1Trace : Trace :=
  approach car
    [cm (-1500), cm (-1200), cm (-900), cm (-600), cm (-300), cm 0]
    [m 3, m 3, m 3, m 3, m 3, m 3]
    sixSights [laneR, junctionR, crossR, highwayR] [yieldSign]

/-- `branch_2` (not_applicable): The same approach and stop sign, but a police officer is recorded at the junction directing traffic with a proceed indication: traffic is being controlled by a police officer and the subsection does not apply. -/
def branch_2Trace : Trace :=
  approach car runOnXs runOnSpeeds sixSights markedStructures [stopSign, officer]

/-- `branch_3` (not_applicable): the same approach, sign and line, and the same run on into the
    junction, but the road user is a bicycle, which the definition of "vehicle" leaves out: the
    subsection's subject class does not hold and the duty does not arise. -/
def branch_3Trace : Trace :=
  approach [.bicycle] runOnXs runOnSpeeds sixSights markedStructures [stopSign]

/-- `branch_4` (not_applicable): the same approach and stop sign, but a signal head is recorded as
    governing the junction: traffic is being controlled by a traffic-control signal. -/
def branch_4Trace : Trace :=
  approach car runOnXs runOnSpeeds sixSights markedStructures [stopSign, junctionSignal]

/-- `branch_5` (compliant): no line and no crossing is mapped for the approach, so the place is the
    point affording the view. The car halts where the view along the through highway is 150 m, past
    the upstream stretch where it is 60 m, and then enters: the third place of the words is where
    the act was made. -/
def branch_5Trace : Trace :=
  approach car
    [cm (-4000), cm (-2500), cm (-1000), cm (-500), cm 0]
    [m 9, m 9, Q.zero, m 4, m 5]
    [m 60, m 60, m 150, m 150, m 150]
    [laneR, junctionR, highwayR] [stopSign]

/-- `branch_6` (violated): the same approach with no line and no crossing, but the car's only halt
    is far upstream, where the view along the through highway is 60 m — short of the intersection
    view sight distance — and it runs on at 9 m/s through the stretch where the view is 150 m. -/
def branch_6Trace : Trace :=
  approach car
    [cm (-4000), cm (-2500), cm (-1000), cm (-500), cm 0]
    [Q.zero, m 9, m 9, m 9, m 9]
    [m 60, m 60, m 150, m 150, m 150]
    [laneR, junctionR, highwayR] [stopSign]

/-- `branch_7` (violated): a yield sign governs the approach and a crossing marks its entrance, as
    in `branch_1`, but the car is at 8 m/s where it is within the stop-point tolerance of the
    crossing — above the yield-approach speed — and never halts. -/
def branch_7Trace : Trace :=
  approach car
    [cm (-3000), cm (-2200), cm (-1400), cm (-600), cm 200]
    [m 8, m 8, m 8, m 8, m 8]
    [m 150, m 150, m 150, m 150, m 150]
    [laneR, junctionR, crossR, highwayR] [yieldSign]

/-- `history_boundary` (unknown): The recording begins with the car already 3 m short of the stop line, inside the stopping zone, moving at 2 m/s, and it enters the junction a second later; no halt is recorded in the trace, and the search back from the entry reaches the first observation of the subject without reaching an observation at which it was off the line, short of it and farther from it than the stop-point tolerance, and without a previous entry into that junction. -/
def history_boundaryTrace : Trace :=
  approach car
    [cm (-500), cm (-200), cm 100]
    [m 2, m 2, m 2]
    [m 150, m 150, m 150]
    [laneR, junctionR, stopLineR, highwayR] [stopSign]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
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
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the part of the approach upstream of the stop line's stopping zone, before the recording begins, at which the halt would have been recorded") ]

end TrafficSpecWitness.NRS_484B_257_1_o1

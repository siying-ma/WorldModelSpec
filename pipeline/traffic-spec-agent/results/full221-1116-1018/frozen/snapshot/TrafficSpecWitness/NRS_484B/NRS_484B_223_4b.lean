/-
  Witnesses for NRS_484B_223_4b.

  Geometry (metres, +x east, +y north). A northbound approach ends at y = 0 at intersection X
  (region 10, x ∈ [-8, 10], y ∈ [0, 6]). Its two lanes: the through lane T (region 2, x ∈ [0, 4])
  and, on its right, the right turn lane L (region 1, x ∈ [4, 8], kind turn_lane, side right);
  both enter X. Beyond X: northbound lanes N (region 3, x ∈ [0, 4]) and N' (region 5, x ∈ [4, 8]),
  y ≥ 6, and an eastbound lane E (region 4, y ∈ [0, 4], x ≥ 10).

  The subject (track 1, a motor vehicle, 4 m × 1.8 m, 10 m/s) is observed every 50 ms (the step
  bound), 28 scenes, t = 0 … 1350 ms. Northbound its centre is at y = 0.5 k − 3.9 m: its front
  reaches X at k = 4 (entry, 200 ms; front at y = 0.1), its rear clears the approach at k = 12
  (y − 2 = 0.1), its front reaches the far lanes at k = 16, its rear leaves X at k = 24 (exit,
  1200 ms; rear at y = 6.1). A passage is 20 intervals, one second. Occupancy is stated per scene
  (a body across two regions) and matches these footprints.

  Heading change: the yaw rate at a scene is held over the interval before it. The right turn
  (permit) turns in two intervals of −45° (yaw rate −900 deg/s at k = 13, 14): heading north up to
  k = 12, north-east at k = 13, east from k = 14; the change since the entry is −90°, inside
  (−135°, −45°] by 45° each side. A straight passage has yaw rate 0, a change of 0°, 45° above
  −45°. After the turn the subject runs east at y = 2 with centre x = 12.2 − 0.5 (24 − k): its
  front reaches E at k = 16 and its rear leaves X (x = 10) at k = 24.

  Every witness speaks about t ∈ [50, 1350] ms: at the first scene the exit (`rises`) has no
  previous observation, and nothing of the passage happens there.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The approach, the intersection and the ways beyond it. -/
def structures : List Structure :=
  [ { Build.lane 1 [(m 4, m (-60)), (m 8, m (-60)), (m 8, m 0), (m 4, m 0)] Build.north
        (left := some 2) (enters := some 10)
      with kind := .turnLane, turnSide := some .right }
  , Build.lane 2 [(m 0, m (-60)), (m 4, m (-60)), (m 4, m 0), (m 0, m 0)] Build.north
      (right := some 1) (enters := some 10)
  , Build.lane 3 [(m 0, m 6), (m 4, m 6), (m 4, m 60), (m 0, m 60)] Build.north (right := some 5)
  , Build.lane 5 [(m 4, m 6), (m 8, m 6), (m 8, m 60), (m 4, m 60)] Build.north (left := some 3)
  , Build.lane 4 [(m 10, m 0), (m 60, m 0), (m 60, m 4), (m 10, m 4)] Build.east
  , Build.rect 10 .intersection (m (-8)) (m 0) (m 10) (m 6) ]

/-- The subject at a position and heading, with its yaw rate (deg/s). -/
def subjectAt (pos : Vec) (hd : Vec) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hd (Units.metresPerSecond 10) (m 2, cm 90, cm 75))
    fun k => { k with yawRate := yaw }

/-- Northbound centre at scene k: y = 0.5 k − 3.9 m. -/
def yAt (k : Nat) : Q := cm (50 * (k : Int) - 390)

/-- A northbound passage: occupancy, lateral position (cm) and yaw rate per scene. -/
def straightTrace (occ : Nat → List RegionId) (xcm : Nat → Int) (yaw : Nat → Option Q) : Trace :=
  Build.trace 28 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [subjectAt (cm (xcm k), yAt k) Build.north (yaw k)] structures []
      (occupies := some (occ k |>.map fun r => (1, r)))

def zeroYaw (_k : Nat) : Option Q := some Q.zero

/-- Straight on from L at x = 6: in L before the entry, across L and X until its rear clears the
    approach, in X, across X and N', and in N' after the exit. -/
def fromLStraight (k : Nat) : List RegionId :=
  if k < 4 then [1] else if k ≤ 11 then [1, 10] else if k ≤ 15 then [10]
  else if k ≤ 23 then [10, 5] else [5]

/-- `forbid` (violated): Subject (ru.aggregate vehicle) occupies a st.turn_lane of side right that enters intersection X (st.lane_enters); it enters X from that lane and leaves X on the far side with its heading change since entry (from kin.yaw_rate) near zero: right_turn_through_region does not hold at the exit. -/
def forbidTrace : Trace :=
  straightTrace fromLStraight (fun _ => 600) zeroYaw

/-- The right turn from L: north at x = 6 up to k = 12, north-east at k = 13, east at y = 2 from
    k = 14 on. -/
def turnPos (k : Nat) : Vec :=
  if k ≤ 12 then (m 6, yAt k)
  else if k = 13 then (cm 650, cm 230)
  else (cm (1220 - 50 * (24 - (k : Int))), m 2)

def turnHeading (k : Nat) : Vec :=
  if k ≤ 12 then Build.north else if k = 13 then (Q.ofInt 1, Q.ofInt 1) else Build.east

def turnYaw (k : Nat) : Option Q :=
  some (if k = 13 || k = 14 then Units.degrees (-900) else Q.zero)

/-- `permit` (compliant): Subject enters X from the right turn lane and leaves X with a heading change since entry of about a quarter turn to the right: right_turn_through_region holds at the exit. -/
def permitTrace : Trace :=
  Build.trace 28 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [subjectAt (turnPos k) (turnHeading k) (turnYaw k)] structures []
      (occupies := some ((if k < 4 then [1] else if k ≤ 11 then [1, 10] else if k ≤ 15 then [10]
        else if k ≤ 23 then [10, 4] else [4]).map fun r => (1, r)))

/-- `idle` (not_applicable): Subject enters X from an ordinary st.lane (no turn lane) and passes straight through; its footprint never overlaps a right turn lane entering X. -/
def idleTrace : Trace :=
  straightTrace
    (fun k => if k < 4 then [2] else if k ≤ 11 then [2, 10] else if k ≤ 15 then [10]
      else if k ≤ 23 then [10, 3] else [3])
    (fun _ => 200) zeroYaw

/-- `blind` (unknown): Subject enters X from the right turn lane and leaves it; kin.yaw_rate is absent on the source, so the heading change since entry, and right_turn_through_region, are unknown. -/
def blindTrace : Trace :=
  straightTrace fromLStraight (fun _ => 600) (fun _ => none)

/-- `occasion_s3` (violated): Subject's footprint overlaps the right turn lane L only at its entry into X (it overlaps L and X there), and only X afterwards; it passes straight through and exits: the condition held for part of the passage, and right_turn_through_region does not hold at the exit.
    Built: in T at x = 3.0 (right edge 3.9), it drifts to x = 3.2 at its entry (right edge 4.1,
    across T, L and X) and back to x = 3.0, so after the entry it overlaps no part of L; its rear
    is in T until it clears the approach (T carries no duty). -/
def occasion_s3Trace : Trace :=
  straightTrace
    (fun k => if k < 4 then [2] else if k = 4 then [2, 1, 10] else if k ≤ 11 then [2, 10]
      else if k ≤ 15 then [10] else if k ≤ 23 then [10, 3] else [3])
    (fun k => if k = 4 then 320 else 300) zeroYaw

/-- `occasion_s3_outside` (not_applicable): Subject occupied the right turn lane L earlier but moved into the adjacent through lane before reaching X; its footprint does not overlap L at its entry or afterwards; it passes straight through X: the condition held only before the passage began.
    Built: x = 5.0 (in L), 4.4 and 3.8 (across T and L), then 3.0 from k = 3 (in T only) before
    its entry at k = 4. -/
def occasion_s3_outsideTrace : Trace :=
  straightTrace
    (fun k => if k = 0 then [1] else if k ≤ 2 then [1, 2] else if k = 3 then [2]
      else if k ≤ 11 then [2, 10] else if k ≤ 15 then [10] else if k ≤ 23 then [10, 3] else [3])
    (fun k => if k = 0 then 500 else if k = 1 then 440 else if k = 2 then 380 else 300) zeroYaw

/-- The instants every witness speaks about: from the second scene to the last. -/
def spoken : Option (Timestamp × Timestamp) := some (50, 1350)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_4b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := spoken
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_223_4b

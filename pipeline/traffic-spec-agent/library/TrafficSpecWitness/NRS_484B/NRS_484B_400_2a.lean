/-
  Witnesses for NRS_484B_400_2a.

  Geometry (metres, +x east, +y north). Highway 1 runs east–west (x −80…60, y −10…10), highway 2
  north–south (x −10…10, y −60…60); they meet at intersection 10 (x, y −10…10), which lies on both.
  Intersection 11 (x −80…−60) lies on highway 1 only: the westbound carriers enter it, so they are
  decidedly no approach to 10.
  West leg of highway 1 (x −60…−10): eastbound lanes 21 (ordinal 1, y −4…0, next to the centre)
  and 22 (ordinal 2, y −8…−4), both entering 10; westbound lane 23 (y 0…4) entering 11. Where the
  leg is written as roadway directed segments: eastbound 51 (y −8…0) entering 10, westbound 52
  (y 0…8) entering 11.
  North leg of highway 2 (y 10…60): northbound lane 31 (x 0…8) and southbound lane 32 (x −8…0)
  entering 10; in `idle` both are northbound (a one-way street); in `branch_3`/`branch_4` the
  southbound carrier is roadway segment 53. Median 40 (y −1…1) divides highway 1 in `branch_2`.
  `branch_7` adds highway 3 (x, y 20…60), which does not meet 10, divided by median 41.
  `branch_8` adds eastbound slip lane 24 (y −10…−8) entering another junction, 12.
  The subject (track 1, a motor vehicle, 4 m × 2 m) heads east: at 0 s it is on the approach
  (x −20), at 1 s it is in the intersection (x −6), at 2 s further in (x 2). Its occupancy is
  stated per scene. int.left_turn at 10 is declared at every scene. The judged observation is
  1 s (the entry); the approach end read is 0 s. Opposed lanes have cosine −1, well below −0.9;
  same-direction lanes +1.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def onWays (st : Structure) (ws : List RegionId) : Structure := { st with ways := some ws }

/-- A roadway written as a directed approach segment: its direction and the junction it enters. -/
def roadSegment (id : RegionId) (bx : List Vec) (dir : Vec) (enters : RegionId) (ws : List RegionId) : Structure :=
  { Build.region id .roadway bx with
    lane := some { direction := some dir, entersIntersection := some enters }
    ways := some ws }

def highway1 : Structure := Build.rect 1 .highway (m (-80)) (m (-10)) (m 60) (m 10)
def highway2 : Structure := Build.rect 2 .highway (m (-10)) (m (-60)) (m 10) (m 60)
def junction : Structure := onWays (Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)) [1, 2]
def westJunction : Structure := onWays (Build.rect 11 .intersection (m (-80)) (m (-10)) (m (-60)) (m 10)) [1]

def eb1 : Structure :=
  onWays (Build.lane 21 (box (-60) (-4) (-10) 0) Build.east none (some 22) (some 1) (some 2) none (some 10)) [1]
def eb2 : Structure :=
  onWays (Build.lane 22 (box (-60) (-8) (-10) (-4)) Build.east (some 21) none (some 2) (some 2) none (some 10)) [1]
def eb1Solo : Structure :=
  onWays (Build.lane 21 (box (-60) (-4) (-10) 0) Build.east none none (some 1) (some 1) none (some 10)) [1]
def wb1 : Structure :=
  onWays (Build.lane 23 (box (-60) 0 (-10) 4) Build.west none none (some 1) (some 1) none (some 11)) [1]
def nb : Structure :=
  onWays (Build.lane 31 (box 0 10 8 60) Build.north none none (some 1) (some 1)) [2]
def sb : Structure :=
  onWays (Build.lane 32 (box (-8) 10 0 60) Build.south none none (some 1) (some 1) none (some 10)) [2]
/-- One-way cross street: both lanes northbound. -/
def nbLeft : Structure :=
  onWays (Build.lane 32 (box (-8) 10 0 60) Build.north none (some 31) (some 1) (some 2)) [2]
def nbRight : Structure :=
  onWays (Build.lane 31 (box 0 10 8 60) Build.north (some 32) none (some 2) (some 2)) [2]
def ebRoad : Structure := roadSegment 51 (box (-60) (-8) (-10) 0) Build.east 10 [1]
def wbRoad : Structure := roadSegment 52 (box (-60) 0 (-10) 8) Build.west 11 [1]
def sbRoad : Structure := roadSegment 53 (box (-8) 10 0 60) Build.south 10 [2]
def median : Structure := onWays (Build.rect 40 .medianOrDivider (m (-60)) (m (-1)) (m (-10)) (m 1)) [1]
/-- A third highway that does not meet intersection 10, divided by a median and carrying no lanes. -/
def highway3 : Structure := Build.rect 3 .highway (m 20) (m 20) (m 60) (m 60)
def farMedian : Structure := onWays (Build.rect 41 .medianOrDivider (m 30) (m 30) (m 40) (m 40)) [3]
/-- An eastbound slip lane beside segment 51 that enters a different junction (12), not 10. -/
def slipJunction : Structure := onWays (Build.rect 12 .intersection (m (-10)) (m (-20)) (m 0) (m (-10))) [1, 2]
def slipLane : Structure :=
  onWays (Build.lane 24 (box (-60) (-10) (-10) (-8)) Build.east none none (some 1) (some 1) none (some 12)) [1]

def base : List Structure := [highway1, highway2, junction, westJunction]
def twoWayLanes : List Structure := base ++ [eb1, eb2, wb1, nb, sb]

def xAt (k : Nat) : Q := if k == 0 then m (-20) else if k == 1 then m (-6) else m 2

def subjectAt (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (xAt k, y) Build.east (Units.metresPerSecond 8) (m 2, m 1, cm 75)

/-- At 0 s the subject is on its approach carriers; from 1 s it is in the intersection. -/
def occupancy (k : Nat) (approach : List RegionId) : List (TrackId × RegionId) :=
  if k == 0 then (1, 1) :: approach.map fun r => (1, r) else [(1, 10), (1, 1), (1, 2)]

def leftTurn : List DeclaredIntent := [{ vehicle := 1, target := 10, values := [("int.left_turn", true)] }]

def approachTrace (structures : List Structure) (y : Q) (approach : List RegionId) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k y] structures [] (occupies := some (occupancy k approach))
      (intents := leftTurn)

/-- `forbid` (violated): Two two-way undivided highways meet; two lanes of the subject's direction enter the intersection; the subject, with int.left_turn declared at the intersection, occupies the lane of ordinal 2 at the observation before it enters. -/
def forbidTrace : Trace := approachTrace twoWayLanes (m (-6)) [22]

/-- `permit` (compliant): Same layout; the subject occupies the lane of ordinal 1 and no opposing lane at the observation before it enters, with int.left_turn declared. -/
def permitTrace : Trace := approachTrace twoWayLanes (m (-2)) [21]

/-- `idle` (not_applicable): The subject enters from the lane of ordinal 2 with int.left_turn declared, but the cross street is one-way: its lanes carry no opposed directions. -/
def idleTrace : Trace := approachTrace (base ++ [eb1, eb2, wb1, nbLeft, nbRight]) (m (-6)) [22]

/-- `blind` (unknown): Same as forbid, but the source declares st.lane_adjacency absent, so the lane next to the centerline is unknown. -/
def blindTrace : Trace := approachTrace twoWayLanes (m (-6)) [22]

/-- `branch_1` (violated): Same layout as permit, but the subject's footprint also overlaps the opposing lane (its direction opposed to the subject's lane) at the observation before entry. -/
def branch_1Trace : Trace := approachTrace twoWayLanes Q.zero [21, 23]

/-- `branch_2` (not_applicable): A st.median_or_divider lies on the highway the subject approaches on (a divided highway); the subject enters from lane 2 with int.left_turn declared. -/
def branch_2Trace : Trace := approachTrace (twoWayLanes ++ [median]) (m (-6)) [22]

/-- `branch_3` (compliant): highway 1 is written as roadway directed segments (no lanes) and the
    cross street's southbound direction as a roadway segment; the subject approaches in the
    eastbound segment entering the intersection, a single line of traffic, over no opposing carrier. -/
def branch_3Trace : Trace := approachTrace (base ++ [ebRoad, wbRoad, nb, sbRoad]) (m (-4)) [51]

/-- `branch_4` (violated): as branch_3, but the subject's footprint also overlaps the westbound
    roadway segment at the observation before entry. -/
def branch_4Trace : Trace := approachTrace (base ++ [ebRoad, wbRoad, nb, sbRoad]) Q.zero [51, 52]

/-- `branch_5` (violated): highway 1's eastbound direction is a roadway segment, its westbound a
    lane; the subject approaches in the segment while overlapping the opposing lane. -/
def branch_5Trace : Trace := approachTrace (base ++ [ebRoad, wb1, nb, sb]) Q.zero [51, 23]

/-- `branch_6` (violated): highway 1's eastbound direction is one lane (ordinal 1), its westbound a
    roadway segment; the subject approaches in the lane while overlapping the opposing segment. -/
def branch_6Trace : Trace := approachTrace (base ++ [eb1Solo, wbRoad, nb, sb]) Q.zero [21, 52]

/-- `branch_7` (violated): as forbid, with a third, divided highway nearby that does not meet the
    intersection: only the highways the intersection lies on are tested for two directions. -/
def branch_7Trace : Trace := approachTrace (twoWayLanes ++ [highway3, farMedian]) (m (-6)) [22]

/-- `branch_8` (compliant): as branch_3, but at the approach end the subject also overlaps an
    eastbound slip lane that enters another junction (12): it occupies no lane entering 10, so the
    roadway segment it approaches in is that portion. -/
def branch_8Trace : Trace :=
  approachTrace (base ++ [ebRoad, wbRoad, slipJunction, slipLane, nb, sbRoad]) (m (-8)) [51, 24]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2a"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_400_2a

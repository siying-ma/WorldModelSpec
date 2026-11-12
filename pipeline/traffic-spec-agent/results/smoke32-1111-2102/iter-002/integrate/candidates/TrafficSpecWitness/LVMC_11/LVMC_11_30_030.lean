/-
  Witnesses for LVMC_11_30_030.

  Geometry: an east-bound two-lane carriageway, right lane centred at y = 1.75 m, left lane at
  y = 5.25 m (the lanes are not built: the rule reads no lane). Crosswalk w (region 10) spans
  x 40..44 m, y -2..9 m; it is marked except in `branch_1`, where an intersection (region 11) lies
  just beyond it. Vehicles are 5 m long and 2 m wide (half extents 2.5, 1, 1); the pedestrian
  (track 3) 0.6 m square. Ego (track 1) runs in the left lane, the stopped vehicle b (track 2) in
  the right lane, b's centre at x = 35 m when halted for w, its front 2.5 m short of w (within the
  5 m reach). One observation per second. Ego is wholly behind b while its front is short of b's
  rear, alongside while the projections share length, wholly ahead once its rear passes b's front.
  Where a witness needs the stopped state to lie before the pass's onset, ego is still turning in
  from a side street heading north (not aligned with b), so it is not behind b then.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_030
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_030

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

/-- The k-th figure of a list, in centimetres. -/
def pick (xs : List Int) (k : Nat) : Q := cm (xs.getD k 0)

def egoY : Q := cm 525
def bY : Q := cm 175

def car (track : TrackId) (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) h v (cm 250, m 1, m 1)

def walker (x y : Q) (v : Q) : RoadUser :=
  Build.user 3 [.pedestrian] (x, y) Build.north v (cm 30, cm 30, cm 90)

def crosswalk (marked : Bool) (x0 : Int) : Structure :=
  { Build.rect 10 .crosswalk (m x0) (m (-2)) (m (x0 + 4)) (m 9) with marked := some marked }

def sc (t : Timestamp) (users : List RoadUser) (structures : List Structure) : Scene :=
  Build.scene t (some 1) users structures []

/-- Ego passes b, at rest at w with the pedestrian on w, from wholly behind (t = 0, 1 s) through
    alongside (2 s) to wholly ahead (3 s). -/
def passScene (structures : List Structure) (k : Nat) (t : Timestamp) : Scene :=
  sc t
    [ car 1 (pick [2100, 2800, 3500, 4200] k) egoY Build.east (m 7)
    , car 2 (cm 3500) bY Build.east Q.zero
    , walker (cm 4200) (cm 300) (m 1) ]
    structures

/-- `forbid` (violated): b, a motor vehicle in the right lane, is at rest within the crosswalk reach of a marked crosswalk w while a pedestrian occupies w. Ego, a motor vehicle in the left lane with aligned heading, is wholly behind b, moves alongside it and becomes wholly ahead of b while b is still at rest and the pedestrian still on w. -/
def forbidTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) (passScene [crosswalk true 40])

/-- `permit` (compliant): Same scene; ego comes to rest in the left lane wholly behind b and stays behind until the pedestrian has left w and b has moved off; ego never becomes wholly ahead of b while b is at rest at w with a pedestrian there. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [1500, 2200, 2700, 2700, 3000] k) egoY Build.east (pick [500, 300, 0, 0, 300] k)
      , car 2 (pick [3500, 3500, 3500, 3500, 4000] k) bY Build.east (pick [0, 0, 0, 0, 500] k)
      , walker (cm 4200) (pick [300, 300, 300, 1600, 1600] k) (m 1) ]
      [crosswalk true 40]

/-- `idle` (not_applicable): No vehicle is at rest at any crosswalk and no crosswalk is near: ego overtakes a slower moving vehicle mid-block. -/
def idleTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [2100, 2800, 3500, 4200, 4900, 5600] k) egoY Build.east (m 7)
      , car 2 (pick [3500, 3800, 4100, 4400, 4700, 5000] k) bY Build.east (m 3)
      , walker (m 202) (cm 300) (m 1) ]
      [crosswalk true 200]

/-- `blind` (unknown): Scene of forbid, but the source declares kin.speed absent: whether b is at rest, and whether ego moves while beside b, cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): As forbid, but w is an unmarked crosswalk (marked attribute false), the prolongation of the sidewalks at an intersection. -/
def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1)
    (passScene [crosswalk false 40, Build.rect 11 .intersection (m 44) (m (-2)) (m 64) (m 9)])

/-- `branch_2` (violated): b halts at w with the pedestrian on w only while ego is alongside, and
    moves off again before ego is wholly ahead: b was stopped at w at one moment of the pass. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [2100, 2800, 3500, 4300] k) egoY Build.east (m 8)
      , car 2 (pick [3300, 3400, 3500, 3700] k) bY Build.east (pick [100, 100, 0, 200] k)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `branch_3` (not_applicable): as forbid, but the road user at rest at w is a bicycle, not a
    vehicle of the aggregate. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [2100, 2800, 3500, 4200] k) egoY Build.east (m 7)
      , Build.user 2 [.bicycle] (cm 3500, bY) Build.east Q.zero (cm 90, cm 30, cm 90)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s1` (violated): b rolls slowly toward w with a pedestrian on w and comes to rest within the crosswalk reach of w only once ego is already alongside it; ego then becomes wholly ahead of b. -/
def occasion_s1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [1800, 2600, 3400, 4200] k) egoY Build.east (m 8)
      , car 2 (pick [3100, 3300, 3500, 3500] k) bY Build.east (pick [200, 200, 0, 0] k)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s1_outside` (not_applicable): b was at rest at w with a pedestrian at w before ego's pass began; b starts to move before ego comes alongside, so that throughout the pass b is moving, still within the crosswalk reach of w, with the pedestrian still at w. -/
def occasion_s1_outsideTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let ego := match k with
      | 0 => car 1 (m 20) (m (-10)) Build.north (m 5)
      | _ => car 1 (pick [0, 2600, 3500, 4400] k) egoY Build.east (m 9)
    sc t
      [ ego
      , car 2 (pick [3500, 3600, 3700, 3800] k) bY Build.east (pick [0, 100, 100, 100] k)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s2` (violated): b, at rest short of w beyond the crosswalk reach while a pedestrian is at w, creeps forward and comes to rest again within the reach of w while ego is alongside; ego becomes wholly ahead of b. -/
def occasion_s2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [1400, 2200, 3300, 4200] k) egoY Build.east (m 9)
      , car 2 (pick [3000, 3100, 3500, 3500] k) bY Build.east (pick [0, 100, 0, 0] k)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s2_outside` (not_applicable): b was at rest within the reach of w with a pedestrian at w before ego's pass began, then crossed w and came to rest again far from any crosswalk, where ego, behind it, passes it; during the pass b is at no crosswalk. -/
def occasion_s2_outsideTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let ego := match k with
      | 0 => car 1 (m 20) (m (-10)) Build.north (m 5)
      | _ => car 1 (pick [0, 3000, 4500, 5800, 6700] k) egoY Build.east (m 10)
    sc t
      [ ego
      , car 2 (pick [3500, 4500, 6000, 6000, 6000] k) bY Build.east (pick [0, 1000, 0, 0, 0] k)
      , walker (cm 4200) (cm 300) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s3` (violated): b is at rest at w with no pedestrian near; a pedestrian steps from the sidewalk onto w only once ego is alongside b; ego becomes wholly ahead of b. -/
def occasion_s3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    sc t
      [ car 1 (pick [2100, 2800, 3500, 4200] k) egoY Build.east (m 7)
      , car 2 (cm 3500) bY Build.east Q.zero
      , walker (cm 4200) (pick [1500, 1500, 850, 700] k) (m 1) ]
      [crosswalk true 40]

/-- `occasion_s3_outside` (not_applicable): b is at rest at w; the pedestrian left w and the crosswalk reach before ego's pass began; during the pass no pedestrian is at w. -/
def occasion_s3_outsideTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let ego := match k with
      | 0 => car 1 (m 20) (m (-15)) Build.north (m 5)
      | 1 => car 1 (m 20) (m (-10)) Build.north (m 5)
      | _ => car 1 (pick [0, 0, 2100, 3500, 4200] k) egoY Build.east (m 7)
    sc t
      [ ego
      , car 2 (cm 3500) bY Build.east Q.zero
      , walker (cm 4200) (pick [300, 1000, 1600, 1600, 1600] k) (m 1) ]
      [crosswalk true 40]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_030"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable
  , witness "occasion_s2" occasion_s2Trace .violated
  , witness "occasion_s2_outside" occasion_s2_outsideTrace .notApplicable
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable ]

end TrafficSpecWitness.LVMC_11_30_030

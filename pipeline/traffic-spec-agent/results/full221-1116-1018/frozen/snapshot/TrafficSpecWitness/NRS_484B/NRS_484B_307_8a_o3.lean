/-
  Witnesses for NRS_484B_307_8a_o3.

  Geometry (every figure is the witness's own and appears nowhere in the rule; +x east, +y north,
  one observation per second).

  Right-turn map (forbid, permit, idle, blind, branch_1, branch_3, branch_4):
    - highway 1 (main road, x −8…8) and highway 2 (cross street, y 0…16); intersection 10 is
      x −8…8, y 0…16 and lies on both.
    - northbound lanes on highway 1, entering 10: lane 11 (x 0…4, ordinal 1 of 2) and lane 12 = c
      (x 4…8, ordinal 2 of 2), both y −40…0; lane 13 (x 4…8, y −200…−40) is the stretch before c,
      entering no intersection.
    - the mark on the approach: stop line 20 (x 0…8, y −2…−1.5) marking 11 and 12 (forbid, permit,
      idle, blind, branch_1); crosswalk 41 (x 0…8, y −3…0) marking 11 and 12 (branch_3); none
      (branch_4).
    - cross street: two-directional (lane 14 eastbound x −200…−8, y 0…8, and lane 15 westbound
      x 8…200, y 8…16, both entering 10; no median), or one-way to the right (branch_3: lane 14
      eastbound y 0…16 entering 10, lane 16 eastbound x 8…200 leaving it).
    - marks on a cross-street approach that do not mark c: stop line 21 on lane 14 (branch_3,
      branch_5); stop line 21 and crosswalk 42 on lane 15 (branch_4).
    - median 50 on highway 1 (x −2…−1), not on the cross street; highway 3 (y 100…116) with one
      westbound lane 31, meeting neither road at 10.
    - head 100 governs 11 and 12 (circular_red unless stated); head 101 governs the cross-street
      approaches and shows circular_green.
    - the subject (track 1) is a car 4.5 m × 1.8 m heading north at x = 6; it halts with its front
      1 m before the mark, then enters 10 at (6, 0.5) at 4 m/s; int.right_turn is declared at 10.
  Left-turn map (branch_2): a one-way northbound roadway 30 (x 0…4, running through the
  intersection, so the subject is on it at the entry) carrying one lane 11 (y −200…0, ordinal 1
  of 1) entering intersection 10 (x 0…4, y 0…16); stop line 20 marks 11; the cross street is one-way
  westbound (lane 15 x 7…200 entering 10, lane 17 x −200…0 leaving it); crosswalk 40 (x 4…7) marks
  15's entrance. The subject halts 1 m before the stop line and enters 10 at (2, 0.5) at 5 m/s with
  int.left_turn declared at 10.

  Conflicts at the entry (constant-velocity closest approach of the centres):
    - forbid / blind / branch_1 / branch_5: cross car at (−11.7, 7.4) eastbound at 12 m/s in lane 14:
      relative position (−17.7, 6.9), relative velocity (12, −4): closest approach 1.5 s ahead at
      0.95 m (horizon 3 s, clearance 3 m).
    - branch_2: pedestrian at (5.1, 10.37) in crosswalk 40 walking west at 1.3 m/s: 2.0 s ahead at
      0.52 m.
    - branch_3: cross car at (−80, 8) eastbound at 12 m/s: closest approach 6.6 s ahead, beyond
      the horizon; no contact.
    - branch_4: cyclist inside 10 at (7.6, 4.3) westbound at 3 m/s: 0.8 s ahead at 1.0 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8a_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8a_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
def onWays (st : Structure) (ws : List RegionId) : Structure := { st with ways := some ws }
def marks (st : Structure) (cs : List RegionId) : Structure :=
  { st with entranceOf := cs, entranceObserved := true }

def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (cm 225, cm 90, cm 75)

/-- The place of the stop on the subject's approach. -/
inductive Mark
  | line
  | walk
  | bare

/-- The intersecting highway. -/
inductive CrossStreet
  | twoWay
  | rightOnly

def crossLanes : CrossStreet → List Structure
  | .twoWay =>
    [ onWays (Build.lane 14 (box (m (-200)) (m 0) (m (-8)) (m 8)) Build.east
        (ordinal := some 1) (count := some 1) (enters := some 10)) [2]
    , onWays (Build.lane 15 (box (m 8) (m 8) (m 200) (m 16)) Build.west
        (ordinal := some 1) (count := some 1) (enters := some 10)) [2] ]
  | .rightOnly =>
    [ onWays (Build.lane 14 (box (m (-200)) (m 0) (m (-8)) (m 16)) Build.east
        (ordinal := some 1) (count := some 1) (enters := some 10)) [2]
    , onWays (Build.lane 16 (box (m 8) (m 0) (m 200) (m 16)) Build.east
        (ordinal := some 1) (count := some 1)) [2] ]

/-- The marks on the subject's approach, and (walk, bare) marks on a cross-street approach that do
    not mark c: stop line 21 on lane 14 (walk); stop line 21 and crosswalk 42 on lane 15 (bare). -/
def approachMark : Mark → List Structure
  | .line => [ marks (onWays (Build.rect 20 .stopLine (m 0) (cm (-200)) (m 8) (cm (-150))) [1]) [11, 12] ]
  | .walk =>
    [ marks (onWays { Build.rect 41 .crosswalk (m 0) (m (-3)) (m 8) (m 0) with marked := some true } [1]) [11, 12]
    , marks (onWays (Build.rect 21 .stopLine (cm (-1250)) (m 0) (m (-12)) (m 16)) [2]) [14] ]
  | .bare =>
    [ marks (onWays (Build.rect 21 .stopLine (m 12) (m 8) (cm 1250) (m 16)) [2]) [15]
    , marks (onWays { Build.rect 42 .crosswalk (m 8) (m 8) (m 11) (m 16) with marked := some true } [2]) [15] ]

/-- Highway 3 meets neither the subject's road at i nor the cross street (y 100…116), with one lane
    31 westbound: neither two-directional nor one-way to the right. -/
def elsewhereRight : List Structure :=
  [ Build.rect 3 .highway (m (-200)) (m 100) (m 200) (m 116)
  , onWays (Build.lane 31 (box (m (-200)) (m 100) (m 200) (m 116)) Build.west
      (ordinal := some 1) (count := some 1)) [3] ]

def rightMap (mk : Mark) (cs : CrossStreet) : List Structure :=
  [ Build.rect 1 .highway (m (-8)) (m (-200)) (m 8) (m 200)
  , Build.rect 2 .highway (m (-200)) (m 0) (m 200) (m 16)
  , onWays (Build.rect 50 .medianOrDivider (m (-2)) (m (-200)) (m (-1)) (m (-1))) [1]
  , onWays (Build.rect 10 .intersection (m (-8)) (m 0) (m 8) (m 16)) [1, 2]
  , onWays (Build.lane 11 (box (m 0) (m (-40)) (m 4) (m 0)) Build.north
      (right := some 12) (ordinal := some 1) (count := some 2) (enters := some 10)) [1]
  , onWays (Build.lane 12 (box (m 4) (m (-40)) (m 8) (m 0)) Build.north
      (left := some 11) (ordinal := some 2) (count := some 2) (enters := some 10)) [1]
  , onWays (Build.lane 13 (box (m 4) (m (-200)) (m 8) (m (-40))) Build.north
      (leadsTo := some [12])) [1] ]
  ++ crossLanes cs ++ approachMark mk ++ elsewhereRight

def rightDevices (red : List SignalIndication) (cs : CrossStreet) : List Device :=
  [ Build.signal 100 [11, 12] red
  , Build.signal 101 (match cs with | .twoWay => [14, 15] | .rightOnly => [14]) [.circularGreen] ]

def rightIntent : List DeclaredIntent :=
  [ { vehicle := 1, target := 10, values := [("int.right_turn", true), ("int.left_turn", false)] } ]

def rightScene (t : Timestamp) (mk : Mark) (cs : CrossStreet) (red : List SignalIndication)
    (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users (rightMap mk cs) (rightDevices red cs) (intents := rightIntent)

/-- The subject's track along x = 6: centre y and speed per observation. -/
def subjectAt (ys vs : List Q) (k : Nat) : RoadUser :=
  car 1 (m 6, ys.getD k (m 0)) Build.north (vs.getD k (m 0))

-- forbid / permit / idle / blind: halt at k1-k2 with the front 1 m before stop line 20, entry at k4.
def stdYs : List Q := [cm (-1325), cm (-525), cm (-525), cm (-325), cm 50]
def stdVs : List Q := [m 4, m 0, m 0, m 4, m 4]
/-- The cross car eastbound at 12 m/s, reaching (−11.7, 7.4) at the entry. -/
def crossCarX : List Q := [cm (-5970), cm (-4770), cm (-3570), cm (-2370), cm (-1170)]
def crossCar (xs : List Q) (k : Nat) : RoadUser := car 2 (xs.getD k (m 0), cm 740) Build.east (m 12)

/-- `forbid` (violated): A car halts with its body 1 m short of the stop line of the rightmost lane c (ordinal 2 of 2), int.right_turn declared at i, the cross street undivided with lanes in both directions; it enters i under circular_red alone at 4 m/s while a car on the cross street, on a lane entering i governed by a head displaying circular_green, approaches from the left at 12 m/s, the closest approach of their centres 1.5 s ahead at 1 m. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .line .twoWay [.circularRed] [subjectAt stdYs stdVs k, crossCar crossCarX k]

/-- `permit` (compliant): The same right turn on red with no other road user in the scene: the duty binds the subject alone and is met. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .line .twoWay [.circularRed] [subjectAt stdYs stdVs k]

/-- `idle` (not_applicable): The car halts in lane c and enters i only after s displays circular_green alone. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .line .twoWay (if k < 3 then [.circularRed] else [.circularGreen])
      [subjectAt stdYs stdVs k]

/-- `blind` (unknown): As forbid, but lane ordinals and counts are not observed: whether the car is on the extreme right is unknown (c is on no one-way roadway, so the left branch is decided false). -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As forbid, but the car halted 15 m short of the stop line behind a queue and rolled into i without halting at the place: the halt the words require did not occur and the duty of this paragraph does not arise. -/
def queueYs : List Q := [m (-45), m (-30), cm (-1925), cm (-1925), m (-12), m (-6), cm 50]
def queueVs : List Q := [m 6, m 6, m 0, m 0, m 5, m 6, m 4]
def queueCrossX : List Q :=
  [cm (-8370), cm (-7170), cm (-5970), cm (-4770), cm (-3570), cm (-2370), cm (-1170)]
def branch_1Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    rightScene t .line .twoWay [.circularRed] [subjectAt queueYs queueVs k, crossCar queueCrossX k]

/-- `branch_2` (violated): A car halts at the stop line of the leftmost lane (ordinal 1) of a one-way roadway, int.left_turn declared at i, every lane of the cross street pointing to its left; it enters i under circular_red alone at 5 m/s while a pedestrian walking at 1.3 m/s in the crosswalk marking the entrance of a cross-street lane into i is closing on its path, the closest approach of their centres 1.2 s ahead at 0.7 m. (Built: 2.0 s ahead at 0.52 m, the crosswalk lying beside the one-lane approach.) -/
def leftMap : List Structure :=
  [ Build.rect 1 .highway (m 0) (m (-200)) (m 4) (m 200)
  , Build.rect 2 .highway (m (-200)) (m 0) (m 200) (m 16)
  , onWays (Build.rect 10 .intersection (m 0) (m 0) (m 4) (m 16)) [1, 2]
  , onWays (Build.rect 30 .oneWayRoadway (m 0) (m (-200)) (m 4) (m 200)) [1]
  , onWays (Build.lane 11 (box (m 0) (m (-200)) (m 4) (m 0)) Build.north
      (ordinal := some 1) (count := some 1) (enters := some 10)) [1]
  , marks (onWays (Build.rect 20 .stopLine (m 0) (cm (-200)) (m 4) (cm (-150))) [1]) [11]
  , marks (onWays { Build.rect 40 .crosswalk (m 4) (m 0) (m 7) (m 16) with marked := some true } [2]) [15]
  , onWays (Build.lane 15 (box (m 7) (m 0) (m 200) (m 16)) Build.west
      (ordinal := some 1) (count := some 1) (enters := some 10)) [2]
  , onWays (Build.lane 17 (box (m (-200)) (m 0) (m 0) (m 16)) Build.west
      (ordinal := some 1) (count := some 1)) [2]
  -- highway 3 elsewhere (y 100…116), not at i: one lane 32 eastbound, not one-way to the left
  , Build.rect 3 .highway (m (-200)) (m 100) (m 200) (m 116)
  , onWays (Build.lane 32 (box (m (-200)) (m 100) (m 200) (m 116)) Build.east
      (ordinal := some 1) (count := some 1)) [3] ]

def leftDevices : List Device :=
  [ Build.signal 100 [11] [.circularRed]
  , Build.signal 101 [15] [.circularGreen] ]

def leftIntent : List DeclaredIntent :=
  [ { vehicle := 1, target := 10, values := [("int.right_turn", false), ("int.left_turn", true)] } ]

def leftYs : List Q := [cm (-1325), cm (-525), cm (-525), cm (-325), cm 50]
def leftVs : List Q := [m 4, m 0, m 0, m 4, m 5]
def walkerX : List Q := [cm 1030, cm 900, cm 770, cm 640, cm 510]

def branch_2Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m 2, leftYs.getD k (m 0)) Build.north (leftVs.getD k (m 0))
      , Build.user 3 [.pedestrian] (walkerX.getD k (m 0), cm 1037) Build.west (Units.ratio 13 10)
          (cm 30, cm 30, cm 90) ]
      leftMap leftDevices (intents := leftIntent)

/-- `branch_3` (compliant): The approach is marked by a crosswalk only (no stop line); the car halts with its front 1 m before the crosswalk, the cross street is one-way to the right, and it turns right on red while a cross car proceeding on green is still 86 m away (closest approach beyond the horizon, no contact): the duty is met. -/
def walkYs : List Q := [cm (-1425), cm (-625), cm (-625), cm (-325), cm 50]
def farCrossX : List Q := [m (-128), m (-116), m (-104), m (-92), m (-80)]
def branch_3Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .walk .rightOnly [.circularRed]
      [ subjectAt walkYs stdVs k
      , car 2 (farCrossX.getD k (m 0), m 8) Build.east (m 12) ]

/-- `branch_4` (violated): No stop line or crosswalk marks the approach; the car halts with its front 1 m before the intersection, the cross street is two-directional, and it turns right on red into the path of a cyclist already crossing the intersection westbound at 3 m/s (closest approach 0.8 s ahead at 1 m). -/
def bareYs : List Q := [cm (-1125), cm (-325), cm (-325), cm (-325), cm 50]
def bareVs : List Q := [m 4, m 0, m 0, m 0, m 4]
def cyclistX : List Q := [cm 1960, cm 1660, cm 1360, cm 1060, cm 760]
def branch_4Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .bare .twoWay [.circularRed]
      [ subjectAt bareYs bareVs k
      , Build.user 2 [.bicycle] (cyclistX.getD k (m 0), cm 430) Build.west (m 3) (cm 90, cm 30, cm 90) ]

/-- `branch_5` (violated): As branch_3 (crosswalk-only approach, cross street one-way to the right), but the cross car proceeding on green is the forbid car, closing from the left: closest approach 1.5 s ahead at 0.95 m. -/
def branch_5Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    rightScene t .walk .rightOnly [.circularRed]
      [ subjectAt walkYs stdVs k, crossCar crossCarX k ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8a_o3"
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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_8a_o3

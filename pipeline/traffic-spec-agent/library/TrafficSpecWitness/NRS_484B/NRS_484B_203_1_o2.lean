/-
  Witnesses for NRS_484B_203_1_o2.

  Geometry (the witness's own figures, none in the rule). World +x east, +y north.
  - Highway 1: rectangle x ∈ [-200, 200] m, y ∈ [-(w+3), w+3] m (sidewalks and shoulders included).
    Lane 2 (eastbound, y ∈ [-w, 0]) and lane 3 (westbound, y ∈ [0, w]), each with the count of lanes
    in its direction `n` (1 on a two-lane road, 2 in `idle`); centre line 4, y ∈ [-0.05, 0.05];
    road edges 5 (y ∈ [-w-0.1, -w], right of an eastbound car) and 6 (y ∈ [w, w+0.1]). Every one
    lies on way 1. w = 2.8 m except `branch_2` (1.3 m).
  - Highway 9, a separate road south of it: y ∈ [-40, -20], centre line 10 (y ∈ [-30.05, -29.95])
    and eastbound lane 11 (count 1) on it. It gives the quantifiers a centre line and a lane the
    subject's road does not carry.
  - Cars: half-extent 2.25 × 0.9 × 0.75 m (full width 1.8 m); subject (track 1) eastbound at 10 m/s
    at x = 0; the oncoming car (track 2) westbound at 10 m/s 40 m ahead (2 s to closest approach).
    Every scene is repeated at 0, 1, 2 s; occupancy is stated.
  Reading: tolerance 0.3 m, so the body keeps its half where 2·offset ≥ 1.8 − 0.6 = 1.2 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_203_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_203_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A car at (x, y) in centimetres, heading `h`, speed in m/s. -/
def car (id : TrackId) (x y : Int) (h : Vec) (v : Int) : RoadUser :=
  Build.user id [.motorVehicle] (cm x, cm y) h (Units.metresPerSecond v) (cm 225, cm 90, cm 75)

/-- The two-lane road of half-width `w` cm with `n` lanes counted per direction, and highway 9. -/
def road (w : Int) (n : Nat) : List Structure :=
  [ Build.rect 1 .highway (m (-200)) (cm (-(w + 300))) (m 200) (cm (w + 300))
  , { Build.lane 2 [(m (-200), cm (-w)), (m 200, cm (-w)), (m 200, Q.zero), (m (-200), Q.zero)]
        Build.east none none (some 1) (some n) with ways := some [1] }
  , { Build.lane 3 [(m (-200), Q.zero), (m 200, Q.zero), (m 200, cm w), (m (-200), cm w)]
        Build.west none none (some 1) (some n) with ways := some [1] }
  , { Build.rect 4 .centreLine (m (-200)) (cm (-5)) (m 200) (cm 5) with ways := some [1] }
  , { Build.rect 5 .roadEdge (m (-200)) (cm (-(w + 10))) (m 200) (cm (-w)) with ways := some [1] }
  , { Build.rect 6 .roadEdge (m (-200)) (cm w) (m 200) (cm (w + 10)) with ways := some [1] }
  , Build.rect 9 .highway (m (-200)) (m (-40)) (m 200) (m (-20))
  , { Build.rect 10 .centreLine (m (-200)) (cm (-3005)) (m 200) (cm (-2995)) with ways := some [9] }
  , { Build.lane 11 [(m (-200), cm (-2995)), (m 200, cm (-2995)), (m 200, m (-25)), (m (-200), m (-25))]
        Build.east none none (some 1) (some 1) with ways := some [9] } ]

/-- A static trace of one scene repeated at 0, 1, 2 s. -/
def still (users : List RoadUser) (structures : List Structure) (occ : List (TrackId × RegionId))
    (rels : List MeasuredRelation := []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.withRelations (Build.scene t (some 1) users structures [] (some occ)) rels

/-- Subject straddling the centre line: centre 0.1 m north of it, body from -0.8 to +1.0 m. -/
def straddling : RoadUser := car 1 0 10 Build.east 10
/-- Oncoming car 40 m ahead on the westbound lane. -/
def oncoming : RoadUser := car 2 4000 180 Build.west 10

def occStraddle : List (TrackId × RegionId) := [(1, 1), (1, 2), (1, 3), (1, 4)]
def occOncoming : List (TrackId × RegionId) := [(2, 1), (2, 3)]

/-- `forbid` (violated): Two-lane two-way road; the moving subject car straddles the centre line by 1 m while an oncoming car approaches 2 s away, with 2 m of room to its right road edge. -/
def forbidTrace : Trace :=
  still [straddling, oncoming] (road 280 1) (occStraddle ++ occOncoming)

/-- `permit` (compliant): Same road; the subject car keeps its body right of the centre line as the oncoming car passes. Body from -2.3 to -0.5 m; offset of the centre line +1.35 m. -/
def permitTrace : Trace :=
  still [car 1 0 (-140) Build.east 10, oncoming] (road 280 1) ([(1, 1), (1, 2)] ++ occOncoming)

/-- `idle` (not_applicable): The subject car drives on a highway whose lane counts two lanes in its direction. -/
def idleTrace : Trace :=
  still [car 1 0 (-140) Build.east 10, oncoming] (road 280 2) ([(1, 1), (1, 2)] ++ occOncoming)

/-- `blind` (unknown): Two-lane road with an oncoming car approaching; the source maps regions without their outline (st.region_geometry absent), so the offset from the centre line is unknown. -/
def blindTrace : Trace :=
  still [car 1 0 (-140) Build.east 10, oncoming] (road 280 1) ([(1, 1), (1, 2)] ++ occOncoming)

/-- `branch_1` (compliant): The subject car drives over the centre line on a two-lane road with no other vehicle in the scene. -/
def branch_1Trace : Trace :=
  still [straddling] (road 280 1) occStraddle

/-- `branch_2` (compliant): A very narrow paved road; the subject's body crosses the centre line by 0.5 m while its right side is at the road edge, as an oncoming car passes. Lanes 1.3 m wide; subject centre at -0.4 m, body from -1.3 to +0.5 m, touching road edge 5. -/
def branch_2Trace : Trace :=
  still [car 1 0 (-40) Build.east 10, car 2 4000 60 Build.west 10] (road 130 1)
    (occStraddle ++ occOncoming)

/-- `branch_3` (violated): The oncoming car is alongside the straddling subject; its velocity is not observed, so its closing is unknown, and the source measures it oncoming. -/
def branch_3Trace : Trace :=
  still [straddling, Build.withKin (car 2 200 190 Build.west 10) fun k => { k with velocity := none }]
    (road 280 1) (occStraddle ++ occOncoming)
    [Build.relation 1 2 fun r => { r with oncoming := some true }]

/-- `branch_4` (violated): The subject has crossed wholly onto the left half and runs along the left road edge (edge 6, on its left) as an oncoming car approaches. -/
def branch_4Trace : Trace :=
  still [car 1 0 190 Build.east 10, car 2 4000 140 Build.west 10] (road 280 1)
    ([(1, 1), (1, 3)] ++ occOncoming)

/-- `branch_5` (not_applicable): The subject car is at rest straddling the centre line as an oncoming car approaches. -/
def branch_5Trace : Trace :=
  still [car 1 0 10 Build.east 0, oncoming] (road 280 1) (occStraddle ++ occOncoming)

/-- `branch_6` (compliant): The subject straddles the centre line while closing on a slower car ahead in its own direction; no vehicle is oncoming. -/
def branch_6Trace : Trace :=
  still [straddling, car 2 3000 (-140) Build.east 5] (road 280 1) (occStraddle ++ [(2, 1), (2, 2)])

/-- `branch_7` (compliant): The subject straddles the centre line as a pedestrian walks towards it on the westbound lane; no vehicle meets it. -/
def branch_7Trace : Trace :=
  still [straddling, Build.user 2 [.pedestrian] (m 10, cm 180) Build.west (Units.metresPerSecond 1) (cm 25, cm 30, cm 90)]
    (road 280 1) (occStraddle ++ occOncoming)

/-- `branch_8` (compliant): The subject straddles the centre line; the oncoming car drives on the separate highway 9, not on the subject's highway. -/
def branch_8Trace : Trace :=
  still [straddling, car 2 4000 (-2800) Build.west 10] (road 280 1) (occStraddle ++ [(2, 9)])

/-- `branch_9` (not_applicable): The subject drives on a single-lane private road (lane 12, on no highway) as an oncoming car approaches on it. -/
def branch_9Trace : Trace :=
  still [car 1 0 10140 Build.east 10, car 2 4000 10140 Build.west 10]
    (road 280 1 ++ [Build.lane 12 [(m (-200), m 100), (m 200, m 100), (m 200, cm 10280), (m (-200), cm 10280)]
        Build.east none none (some 1) (some 1)])
    [(1, 12), (2, 12)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_203_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_203_1_o2

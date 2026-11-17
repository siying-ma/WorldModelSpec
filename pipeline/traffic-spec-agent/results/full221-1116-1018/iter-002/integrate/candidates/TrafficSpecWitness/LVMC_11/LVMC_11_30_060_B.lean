/-
  Witnesses for LVMC_11_30_060_B.

  Geometry (all figures the witness's own; none appears in the rule):
  - roadway 10: x from -100 m to 100 m, y from 0 to 12 m, designated direction east (in `branch_1`
    it carries no direction and a lane 11, y 0..6 m, direction east, carries the crossing);
  - pedestrian overpass 20: x from 10 m to 14 m, y from -5 m to 17 m, spanning the roadway, about
    9.7 m from the pedestrian's body (300 m away in `idle`: x 300..304 m);
  - pedestrian 1 (subject): x = 0, y = 2 + 1.4·k m at instant k (k = 0, 1, 2; 1 s apart), heading
    north at 1.4 m/s, half-extent 0.3 × 0.3 × 0.9 m: moving straight across the eastbound roadway;
  - car 2 (forbid, blind, branch_1, branch_2): x = -20 + 10·k m, y = 5 m, heading east at 10 m/s,
    half-extent 2.4 × 0.9 × 0.8 m: at k = 0 the centres' projected closest approach is about 0.2 m
    in about 2.0 s (horizon 3 s, clearance 3 m), and the bodies meet at k = 2 (`forbid` stops at
    k = 1, so its violation is the projected conflict, not a contact);
  - branch_4: roadways 40 (y 0..12 m) and 41 (y 12..24 m), a pedestrians_prohibited sign on 41;
    the pedestrian stands across their edge at (0, 12), a car on 41 only at (-20, 14.8) eastbound;
  - car 2 (branch_3): x = -60 - 10·k m, y = 5 m, heading west at 10 m/s: moving away, no approach;
  - sign 30 (branch_2): a pedestrians_prohibited regulatory sign governing roadway 10.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_060_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_060_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def kq (k : Nat) : Q := Q.ofInt (Int.ofNat k)

/-- The pedestrian at instant k, walking north across the roadway at 1.4 m/s. -/
def pedestrian (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, Q.add (m 2) (Q.mul (cm 140) (kq k))) Build.north (cm 140)
    (cm 30, cm 30, cm 90)

/-- A car driving east on the roadway into the pedestrian's path. -/
def carApproaching (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (Q.add (m (-20)) (Q.mul (m 10) (kq k)), m 5) Build.east
    (Units.metresPerSecond 10) (cm 240, cm 90, cm 80)

/-- A car driving west on the roadway, away from the pedestrian. -/
def carLeaving (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (Q.sub (m (-60)) (Q.mul (m 10) (kq k)), m 5) Build.west
    (Units.metresPerSecond 10) (cm 240, cm 90, cm 80)

/-- The roadway, with its designated direction east. -/
def roadway : Structure :=
  { Build.rect 10 .roadway (m (-100)) (m 0) (m 100) (m 12) with
    lane := some { direction := some Build.east } }

/-- The roadway without a designated direction. -/
def roadwayNoDirection : Structure := Build.rect 10 .roadway (m (-100)) (m 0) (m 100) (m 12)

/-- An eastbound lane of the roadway. -/
def lane11 : Structure :=
  Build.lane 11 [(m (-100), m 0), (m 100, m 0), (m 100, m 6), (m (-100), m 6)] Build.east

def overpassNear : Structure := Build.rect 20 .pedestrianGradeSeparation (m 10) (m (-5)) (m 14) (m 17)
def overpassFar : Structure := Build.rect 20 .pedestrianGradeSeparation (m 300) (m (-5)) (m 304) (m 17)

def noPedestriansSign : Device :=
  { Build.sign 30 .regulatorySign [10] with
    code := some .pedestriansProhibited, conditions := some {} }

/-- `forbid` (violated): A pedestrian crosses a roadway 10 m from a pedestrian overpass, walking at 1.4 m/s into the path of a car on that roadway whose projected closest approach is 1 m in 2 s. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, carApproaching k ]
      [ roadway, overpassNear ]
      [ ]

/-- `permit` (compliant): A pedestrian crosses the roadway 10 m from the overpass at 1.4 m/s; no vehicle is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k ]
      [ roadway, overpassNear ]
      [ ]

/-- `idle` (not_applicable): A pedestrian crosses a roadway 300 m from any pedestrian tunnel or overpass. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k ]
      [ roadway, overpassFar ]
      [ ]

/-- `blind` (unknown): A pedestrian crosses the roadway near an overpass while a car approaches, but the source maps the overpass without its outline, so the distance to it is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, carApproaching k ]
      [ roadway, overpassNear ]
      [ ]

/-- `branch_1` (violated): the roadway carries no designated direction; the pedestrian crosses an
    eastbound lane of it near the overpass into the path of a car in that lane. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, carApproaching k ]
      [ roadwayNoDirection, lane11, overpassNear ]
      [ ]

/-- `branch_2` (not_applicable): as `forbid`, but a pedestrians_prohibited sign governs the roadway. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, carApproaching k ]
      [ roadway, overpassNear ]
      [ noPedestriansSign ]

/-- `branch_3` (compliant): the pedestrian crosses near the overpass while a car on the roadway
    drives away from it, 60 m off: no conflict, no contact. -/
def branch3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, carLeaving k ]
      [ roadway, overpassNear ]
      [ ]

/-- Roadway 40 (y 0..12 m, east) and roadway 41 (y 12..24 m, east), separate roadways side by side;
    a pedestrians_prohibited sign 31 governs roadway 41 only. -/
def roadwayA : Structure :=
  { Build.rect 40 .roadway (m (-100)) (m 0) (m 100) (m 12) with
    lane := some { direction := some Build.east } }
def roadwayB : Structure :=
  { Build.rect 41 .roadway (m (-100)) (m 12) (m 100) (m 24) with
    lane := some { direction := some Build.east } }
def noPedestriansSignB : Device :=
  { Build.sign 31 .regulatorySign [41] with
    code := some .pedestriansProhibited, conditions := some {} }

/-- `branch_4` (compliant): the pedestrian, near the overpass, stands across the edge between
    roadway 40 (no prohibition) and roadway 41 (pedestrians prohibited), walking north; a car on
    roadway 41 alone is projected to meet it, but roadway 41 is not one the duty selects, and no
    vehicle is on roadway 40. -/
def branch4Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m 0, m 12) Build.north (cm 140) (cm 30, cm 30, cm 90)
      , Build.user 2 [.motorVehicle] (m (-20), cm 1480) Build.east (Units.metresPerSecond 10)
          (cm 240, cm 90, cm 80) ]
      [ roadwayA, roadwayB, overpassNear ]
      [ noPedestriansSignB ]
      (some [(1, 40), (1, 41), (2, 41)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_060_B"
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
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .compliant
  , witness "branch_4" branch4Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_060_B

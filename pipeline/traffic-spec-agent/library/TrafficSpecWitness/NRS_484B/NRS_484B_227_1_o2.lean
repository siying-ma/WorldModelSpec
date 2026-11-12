/-
  Witnesses for NRS_484B_227_1_o2.

  Geometry (metres, +x east, +y north): a highway 10 spanning x ∈ [-50, 50], y ∈ [-12, 12];
  an eastbound roadway 11 at y ∈ [-10, -2], a median 12 at y ∈ [-2, 2], a westbound roadway 13 at
  y ∈ [2, 10], all lying on 10. The undivided highway of `idle` has the two roadways and no median.
  The intersection 14 of `branch_2` spans x ∈ [-15, 15] across the whole highway and lies on 10.
  Ego (track 1, a motor vehicle) either keeps to the eastbound roadway at y = -6 or crosses the
  median northbound at y = -1, 0, 1 over three instants one second apart. No rule window looks
  back, so the traces are unpadded. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

def hwyId : RegionId := 10

def onHwy (s : Structure) : Structure := { s with ways := some [hwyId] }

def highway : Structure := Build.rect hwyId .highway (m (-50)) (m (-12)) (m 50) (m 12)
def roadwayEast : Structure := onHwy (Build.rect 11 .roadway (m (-50)) (m (-10)) (m 50) (m (-2)))
def roadwayWest : Structure := onHwy (Build.rect 13 .roadway (m (-50)) (m 2) (m 50) (m 10))
def median (opening : Bool) : Structure :=
  { onHwy (Build.rect 12 .medianOrDivider (m (-50)) (m (-2)) (m 50) (m 2)) with
    opening := some opening }
def intersection : Structure :=
  onHwy (Build.rect 14 .intersection (m (-15)) (m (-12)) (m 15) (m 12))

def body : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Ego on the eastbound roadway. -/
def egoKeeping : RoadUser := Build.user 1 [.motorVehicle] (m 0, m (-6)) Build.east (m 15) body

/-- Ego crossing the median northbound, at instant `k`. -/
def egoCrossing (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (-1 + (k : Int))) Build.north (m 1) body

def dividedCrossing (opening : Bool) (extra : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ egoCrossing k ]
      ([ highway, roadwayEast, median opening, roadwayWest ] ++ extra)
      [ ]

/-- `forbid` (violated): Ego drives across a raised median of a divided highway where the median has no opening: its footprint overlaps the median region, opening attribute not set, outside any intersection. -/
def forbidTrace : Trace := dividedCrossing false []

/-- `permit` (compliant): Ego travels on the right-hand roadway of the divided highway; its footprint overlaps no median. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ egoKeeping ]
      [ highway, roadwayEast, median false, roadwayWest ]
      [ ]

/-- `idle` (not_applicable): Ego travels on a road whose highway carries no median or divider. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ egoKeeping ]
      [ highway, roadwayEast, roadwayWest ]
      [ ]

/-- `blind` (unknown): Scene of forbid, but the source declares rel.occupies absent. -/
def blindTrace : Trace := dividedCrossing false []

/-- `branch_1` (compliant): Ego crosses the median through an opening: its footprint overlaps the median region whose opening attribute is set. -/
def branch_1Trace : Trace := dividedCrossing true []

/-- `branch_2` (compliant): Ego crosses the median area within an intersection of the divided highway; its footprint overlaps the intersection region. -/
def branch_2Trace : Trace := dividedCrossing false [intersection]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o2

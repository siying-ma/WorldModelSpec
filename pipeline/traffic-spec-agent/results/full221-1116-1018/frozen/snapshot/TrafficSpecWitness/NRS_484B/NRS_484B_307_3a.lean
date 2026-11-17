/-
  Witnesses for NRS_484B_307_3a.

  The map (static in every scene; metres, +x east, +y north):
  - intersection 10: the square x ∈ [0, 20], y ∈ [0, 20];
  - lane 20: the subject's northbound approach, x ∈ [10, 20], y ∈ [-40, 0], entering 10, governed by
    traffic signal 100;
  - lane 21: the east leg's westbound approach, x ∈ [24, 60], y ∈ [10, 20], entering 10 (no device);
  - crosswalk 30: across the east leg, x ∈ [20, 24], y ∈ [0, 20], marking the entrance of lane 21
    (entrance observed), outside the intersection.
  Bodies: the subject (track 1) a motor vehicle of half-extents 2 m × 1 m; pedestrians (track 2)
  0.3 m × 0.3 m; a cyclist (track 3) 1 m × 0.3 m. Instants are 1 s apart. Occupancy is stated as
  the footprints' overlaps (touching counts).
  Against the reading (horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s): every danger instant
  has its closest centre approach at ≤ 1 m within ≤ 1.6 s; every safe one at ≥ 4 m or no approach.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_3a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_3a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def carExt : Q × Q × Q := (m 2, m 1, cm 75)
def pedExt : Q × Q × Q := (cm 30, cm 30, cm 90)
def bikeExt : Q × Q × Q := (m 1, cm 30, cm 90)

def intersection : Structure := Build.rect 10 .intersection (m 0) (m 0) (m 20) (m 20)
def approach : Structure :=
  Build.lane 20 [(m 10, m (-40)), (m 20, m (-40)), (m 20, m 0), (m 10, m 0)] Build.north
    (enters := some 10)
def crossApproach : Structure :=
  Build.lane 21 [(m 24, m 10), (m 60, m 10), (m 60, m 20), (m 24, m 20)] Build.west
    (enters := some 10)
def crosswalk : Structure :=
  { Build.rect 30 .crosswalk (m 20) (m 0) (m 24) (m 20) with
      entranceOf := [21], entranceObserved := true, marked := some true }

def mapStructures : List Structure := [intersection, approach, crossApproach, crosswalk]

def signalShowing (shows : List SignalIndication) : Device := Build.signal 100 [20] shows

def greenRight : List SignalIndication := [.circularGreen, .greenArrow .right]
def greenLeft : List SignalIndication := [.circularGreen, .greenArrow .left]

/-- The forbid geometry under a given signal state: the subject, heading east at 6 m/s mid-way
    through its right turn, sweeps across the crosswalk while a pedestrian walks south in it at
    1 m/s. t=0: subject (13, 0) [occupies 10, 20], pedestrian (22, 2.5) [30]: closest approach
    ≈ 0.99 m in ≈ 1.53 s. t=1: subject (19, 0) [10, 20, 30], pedestrian (22, 1.5): ≈ 0.99 m in
    ≈ 0.53 s. t=2: subject (25, 0) [30 only: off its approach and out of the intersection]. -/
def turnAcrossCrosswalk (shows : List SignalIndication) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let sx : Int := 13 + 6 * k
    let occS : List (TrackId × RegionId) :=
      if k = 0 then [(1, 10), (1, 20)]
      else if k = 1 then [(1, 10), (1, 20), (1, 30)]
      else [(1, 30)]
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m sx, m 0) Build.east (mps 6) carExt
      , Build.user 2 [.pedestrian] (m 22, cm (250 - 100 * k)) Build.south (mps 1) pedExt ]
      mapStructures
      [ signalShowing shows ]
      (occupies := some (occS ++ [(2, 30)]))

/-- `forbid` (violated): The subject vehicle occupies an approach lane whose dev.traffic_signal displays circular_green with green_arrow(right); it turns right at 6 m/s while a pedestrian walks in the crosswalk marking the entrance of the cross street's approach (st.entrance_of); prim.closest_approach_within holds with a closest centre distance of 1.0 m in 1.5 s, and the subject keeps moving. -/
def forbidTrace : Trace := turnAcrossCrosswalk greenRight

/-- `permit` (compliant): The subject halts (kin.speed 0) short of the crosswalk until the pedestrian has crossed, then completes its turn with no closest approach below the clearance within the horizon.
    The subject stands at (13, 0) heading east [occupies 10, 20] for t = 0 … 5 s while the
    pedestrian walks south at 1 m/s from (22, 2.5) — in crosswalk 30 up to t = 2, on the far side
    (in no region) from t = 3. At t = 6 the pedestrian is at (22, -3.5) and the subject moves off
    at 6 m/s: closest centre approach ≈ 4.9 m, and the pedestrian is no longer in the crosswalk. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let speed : Q := if k < 6 then mps 0 else mps 6
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 13, m 0) Build.east speed carExt
      , Build.user 2 [.pedestrian] (m 22, cm (250 - 100 * k)) Build.south (mps 1) pedExt ]
      mapStructures
      [ signalShowing greenRight ]
      (occupies := some ([(1, 10), (1, 20)] ++ (if k ≤ 2 then [(2, 30)] else [])))

/-- `idle` (not_applicable): The signal governing the subject's approach displays circular_green alone, with no arrow. (The forbid geometry under circular green only.) -/
def idleTrace : Trace := turnAcrossCrosswalk [.circularGreen]

/-- `blind` (unknown): The subject turns at a signalized intersection whose signal states are not observed by the source. (The forbid geometry; the manifest masks dev.traffic_signal.) -/
def blindTrace : Trace := turnAcrossCrosswalk greenRight

/-- `branch_1` (compliant): On circular green with green_arrow(left) the subject turns left; no other road user is in the scene.
    t=0: subject (15, 0) heading north at 5 m/s [occupies 10, 20]; t=1: (15, 5) [10 only, in the
    intersection since it left lane 20]. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let sy : Int := 5 * k
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m sy) Build.north (mps 5) carExt ]
      mapStructures
      [ signalShowing greenLeft ]
      (occupies := some (if k = 0 then [(1, 10), (1, 20)] else [(1, 10)]))

/-- `branch_2` (violated): On circular green with green_arrow(left) the subject turns left at 7 m/s toward a cyclist (a member of traffic) already within the intersection; prim.closest_approach_within holds with a closest centre distance of 1.2 m in 1.0 s.
    t=0: subject (15, -3) heading north at 7 m/s [lane 20 only]; cyclist standing at (11, 12)
    [intersection 10]: closest approach 4 m — no danger. t=1: subject (15, 4) [intersection only,
    there since it left lane 20]; the cyclist sets off east at 4 m/s: closest approach ≈ 0.5 m in
    ≈ 1.1 s — the violation falls where the subject is on its approach only through `since`. -/
def branch_2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let sy : Int := 7 * k - 3
    let bikeSpeed : Q := if k = 0 then mps 0 else mps 4
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m sy) Build.north (mps 7) carExt
      , Build.user 3 [.bicycle] (m 11, m 12) Build.east bikeSpeed bikeExt ]
      mapStructures
      [ signalShowing greenLeft ]
      (occupies := some ((if k = 0 then [(1, 20)] else [(1, 10)]) ++ [(3, 10)]))

/-- `branch_3` (violated): the contact limb. On circular green with green_arrow(right) the subject,
    at (21.5, 0) heading east at 3 m/s [occupies 10, 20, 30], strikes a pedestrian at (21.5, 1.2)
    stepping back north at 1.5 m/s in crosswalk 30: the bodies overlap while the centres already
    separate (no closest approach ahead), so only `rel_contact` decides. -/
def branch_3Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm 2150, m 0) Build.east (mps 3) carExt
      , Build.user 2 [.pedestrian] (cm 2150, cm 120) Build.north (cm 150) pedExt ]
      mapStructures
      [ signalShowing greenRight ]
      (occupies := some [(1, 10), (1, 20), (1, 30), (2, 30)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_3a"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_3a

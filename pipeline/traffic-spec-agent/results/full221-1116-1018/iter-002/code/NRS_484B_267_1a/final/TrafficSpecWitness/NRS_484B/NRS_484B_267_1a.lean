/-
  Witnesses for NRS_484B_267_1a.

  The carriageway: two eastbound lanes, region 10 (left, y ∈ [0, 4] m) and region 11 (right,
  y ∈ [−4, 0] m), x ∈ [−100, 300] m. Three scenes, one second apart (k = 0, 1, 2).

  The subject (track 1) is a motor vehicle (half-extents 2 m × 1 m) heading east at 10 m/s, at
  x = 13 + 10k. The approaching vehicle e (track 2) is an official vehicle of a regulatory agency
  (half-extents 2 m × 1 m) heading east at 14 m/s in the left lane, at x = 14k, with one lit red
  flashing front warning lamp: it moves (14 m/s against the 0.1 m/s tolerance), the subject is
  ahead of it (13, 9, 5 m) and well inside the 100 m immediate-approach reach.

  The ambulance of the plan's `forbid`, `permit` and `blind` narratives is replaced by the
  regulatory-agency vehicle (the u3 limb): the run's reading includes no road-user class in
  DEF-NRS-484A-020::authorized_emergency_vehicle (every class unresolved), so an ambulance's
  membership — and with it the applicability — is unknown on every scene; see task_result.md.

  - forbid: subject in the left lane, closing at 4 m/s. At k = 1 and k = 2 the centres' closest
    approach is at 2.25 s and 1.25 s (horizon 3 s) at 0 m (clearance 3 m); the bodies stay 5 m and
    1 m apart (no contact). At k = 0 the closest approach (3.25 s) lies beyond the horizon.
  - permit: as forbid, the subject in the right lane (y = −2): closest approach 4 m (≥ 3 m), the
    bodies 2 m apart laterally.
  - idle: as forbid, e's warning lamps observed and none lit.
  - blind: as forbid, e's warning lamps not observed (`sig.warning_lamp` masked).
  - branch_1: as forbid, a police officer directing traffic governs lane 10, the subject's lane.
  - branch_2: e and the subject both at 12 m/s, centres 3 m apart in the left lane: the bodies
    (4 m of half-lengths) overlap — contact; no closest approach (no relative motion).
  - branch_3: a bicycle (not of the emergency aggregate, not an official vehicle) with a lit red
    flashing lamp approaches at 10 m/s the subject at 6 m/s, 9 m ahead, in conflict: not applicable.
  - branch_4: as permit, and a bicycle (track 3) with a lit red flashing lamp at 14 m/s in the right
    lane, at x = 14k, behind the subject and in conflict with it (as forbid's geometry): compliant,
    the duty runs to the emergency or regulatory vehicle only.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneLeft : Structure := Build.rect 10 .lane (m (-100)) (m 0) (m 300) (m 4)
def laneRight : Structure := Build.rect 11 .lane (m (-100)) (m (-4)) (m 300) (m 0)
def lanes : List Structure := [laneLeft, laneRight]

def redFlashingFront : List WarningLamp := [{ colour := .red, mode := .flashing, facing := .front }]

def withLamps (u : RoadUser) (ls : Option (List WarningLamp)) : RoadUser :=
  Build.withSignals u fun s => { s with warningLamps := ls }

/-- The subject at x = x0 + v·k, lateral position y, heading east at v. -/
def subjectAt (k : Nat) (x0 : Int) (v : Int) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (x0 + v * Int.ofNat k), y) Build.east (Units.metresPerSecond v)
    (m 2, m 1, cm 75)

/-- The regulatory-agency official vehicle at x = v·k in the left lane, heading east at v. -/
def regulatorAt (k : Nat) (v : Int) (ls : Option (List WarningLamp)) : RoadUser :=
  withLamps
    { Build.user 2 [.officialVehicle, .motorVehicle] (m (v * Int.ofNat k), m 2) Build.east
        (Units.metresPerSecond v) (m 2, m 1, cm 90) with officialKind := some .regulatoryAgency }
    ls

/-- The police officer directing traffic, governing the left lane. -/
def officer : Device :=
  { Build.device 50 .humanDirection [10] (some (m 40, m 5)) with
      humanRole := some .policeOfficer
      humanIndication := some .stop }

/-- `forbid` (violated): Ambulance e (authorized-emergency-vehicle aggregate) with a lit red flashing front warning lamp moves toward the subject from behind within p.emergency_immediate_approach_reach, the subject ahead of it. The subject keeps moving in e's path: their closest approach falls within p.conflict_horizon below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m 2), regulatorAt k 14 (some redFlashingFront) ]
      lanes
      [ ]

/-- `permit` (compliant): As forbid, but the subject has moved to the right lane: no closest approach within p.conflict_horizon below p.conflict_centre_clearance, no contact. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m (-2)), regulatorAt k 14 (some redFlashingFront) ]
      lanes
      [ ]

/-- `idle` (not_applicable): e approaches as in forbid but its warning lamps are off (no lit sig.warning_lamp). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m 2), regulatorAt k 14 (some []) ]
      lanes
      [ ]

/-- `blind` (unknown): As forbid, but sig.warning_lamp is not observed on the source, so whether e makes use of the required lamps is unknown while the subject is in conflict with it. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m 2), regulatorAt k 14 none ]
      lanes
      [ ]

/-- `branch_1` (not_applicable): As forbid, but a police officer (dev.human_direction, role police_officer) governs the lane the subject occupies and directs it. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m 2), regulatorAt k 14 (some redFlashingFront) ]
      lanes
      [ officer ]

/-- `branch_2` (violated): An official vehicle of kind regulatory_agency with a lit red flashing front lamp approaches as in forbid and the subject's body touches it (rel.contact). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 3 12 (m 2), regulatorAt k 12 (some redFlashingFront) ]
      lanes
      [ ]

/-- `branch_3` (not_applicable): a bicycle — no class of the emergency aggregate, no official
    vehicle — with a lit red flashing lamp approaches the subject in conflict: the words exclude it. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 9 6 (m 2)
      , withLamps
          (Build.user 2 [.bicycle] (m (10 * Int.ofNat k), m 2) Build.east (Units.metresPerSecond 10)
            (m 1, cm 30, cm 90))
          (some redFlashingFront) ]
      lanes
      [ ]

/-- `branch_4` (compliant): as permit (the subject clear of the regulatory vehicle in the right
    lane), and a bicycle with a lit red flashing lamp closes on the subject from behind in the right
    lane, in conflict with it: the duty runs to the emergency or regulatory vehicle only. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 13 10 (m (-2)), regulatorAt k 14 (some redFlashingFront)
      , withLamps
          (Build.user 3 [.bicycle] (m (14 * Int.ofNat k), m (-2)) Build.east (Units.metresPerSecond 14)
            (m 1, cm 30, cm 90))
          (some redFlashingFront) ]
      lanes
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_1a"
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
  , witness "blind" blindTrace (.unknown []) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_1a

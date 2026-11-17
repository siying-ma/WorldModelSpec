/-
  Witnesses for NRS_484B_267_1c.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - Highway 100: x ∈ [-100, 700], y ∈ [-6, 16]. Three eastbound lanes on it: 101 (y 0..4, the
    right-hand lane), 102 (y 4..8), 103 (y 8..12). Right road edge 110 (curb strip, y -1..0) and left
    road edge 111 (y 12..13), both on 100. In the shoulder scenes the right edge is replaced by a
    paved shoulder 120 (y -4..0, eastbound designated direction) on 100. Intersection 130
    (x 185..215) in branch_8 only.
  - Subject (track 1): a motor vehicle, half-length 2.5 m, half-width 1 m. Pulled over it rests at
    y 1.3 (body 0.3 m from the right edge, well inside the 1.0 m edge gap; lateral offset of the
    edge -1.3 m).
  - e (track 2): an official vehicle of kind regulatory_agency (the reading's authorized-emergency-
    vehicle aggregate admits no included class, so no emergency-vehicle class can decide the
    trigger; the regulatory-agency limb carries every decided witness), half-length 3 m, in lane 103
    at 25 m/s: x = 70 + 25k at instant k (1 s apart). At k0 it is 110 m from the subject (beyond the
    100 m reach), at k1 93 m (within it): the trigger rises at k1. At k5 it is alongside (projection
    overlap +2.5 m), at k6 it has passed (subject behind it, projections 10 m apart).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def lampsOn : Option (List WarningLamp) := some [{ colour := .red, mode := .flashing, facing := .front }]
def lampsOff : Option (List WarningLamp) := some []

/-- Structures. -/
def hwy : Structure := Build.rect 100 .highway (m (-100)) (m (-6)) (m 700) (m 16)
def carrier (id : RegionId) (kind : StructureKind) (y0 y1 : Int) : Structure :=
  { Build.rect id kind (m (-100)) (m y0) (m 700) (m y1) with
    lane := some { direction := some Build.east }, ways := some [100] }
def lane1 : Structure := carrier 101 .lane 0 4
def lane2 : Structure := carrier 102 .lane 4 8
def lane3 : Structure := carrier 103 .lane 8 12
def edgeR : Structure := { Build.rect 110 .roadEdge (m (-100)) (m (-1)) (m 700) (m 0) with ways := some [100] }
def edgeL : Structure := { Build.rect 111 .roadEdge (m (-100)) (m 12) (m 700) (m 13) with ways := some [100] }
def shoulder : Structure := { carrier 120 .shoulder (-4) 0 with paved := some true }
def junction : Structure := { Build.rect 130 .intersection (m 185) (m (-6)) (m 215) (m 16) with ways := some [100] }

def baseStructs : List Structure := [hwy, lane1, lane2, lane3, edgeR, edgeL]
def shoulderStructs : List Structure := [hwy, lane1, lane2, lane3, edgeL, shoulder]

/-- Road users. -/
def subjAt (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) h v (cm 250, m 1, cm 75)

def subjSeq (xs vs : List Int) (y : Q) : Nat → RoadUser := fun k =>
  subjAt (m (xs.getD k 0)) y Build.east (m (vs.getD k 0))

def official (x y v : Q) (lamps : Option (List WarningLamp)) : RoadUser :=
  { Build.user 2 [.officialVehicle] (x, y) Build.east v (m 3, m 1, m 1) with
    officialKind := some .regulatoryAgency, sig := { warningLamps := lamps } }

/-- e closing at 25 m/s in lane `y`: x = 70 + 25k. -/
def eStd (lamps : Option (List WarningLamp)) (y : Q := m 10) : Nat → RoadUser := fun k =>
  official (m (70 + 25 * (k : Int))) y (m 25) lamps

def run (subj other : Nat → RoadUser) (structs : List Structure) (devs : List Device := []) : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subj k, other k] structs devs

/-- Subject motions. -/
def permitXs : List Int := [180, 188, 192, 192, 192, 192, 192, 192]
def permitVs : List Int := [10, 6, 0, 0, 0, 0, 0, 0]
def forbidXs : List Int := [180, 188, 192, 195, 198, 201, 204, 207]
def forbidVs : List Int := [10, 6, 0, 3, 3, 3, 3, 3]
def cruiseXs : List Int := [180, 190, 200, 210, 220, 230, 240, 250]
def cruiseVs : List Int := [10, 10, 10, 10, 10, 10, 10, 10]

/-- `forbid` (violated): The trigger rises as e (a regulatory-agency vehicle) with a lit red flashing
    lamp closes from behind; the subject pulls to the right edge and comes to rest there at k2, then
    moves off at k3 while e is still behind it, and e passes at k6. -/
def forbidTrace : Trace := run (subjSeq forbidXs forbidVs (cm 130)) (eStd lampsOn) baseStructs

/-- `permit` (compliant): The subject comes to rest at k2 by the right road edge (0.3 m gap), parallel,
    clear of intersections, and stays at rest until e has gone past at k6. -/
def permitTrace : Trace := run (subjSeq permitXs permitVs (cm 130)) (eStd lampsOn) baseStructs

/-- `idle` (not_applicable): e approaches with its warning lamps off: the trigger never rises. -/
def idleTrace : Trace := run (subjSeq forbidXs forbidVs (cm 130)) (eStd lampsOff) baseStructs

/-- `blind` (unknown): As forbid, but sig.warning_lamp is not observed. -/
def blindTrace : Trace := run (subjSeq forbidXs forbidVs (cm 130)) (eStd lampsOn) baseStructs

/-- `branch_1` (violated): The subject comes to rest in the middle lane (body 5 m from either edge)
    and stays at rest until e passes: not in such position. -/
def branch_1Trace : Trace := run (subjSeq permitXs permitVs (m 6)) (eStd lampsOn) baseStructs

/-- `branch_2` (violated): The subject keeps moving at 3 m/s and e passes it at k6. -/
def branch_2Trace : Trace :=
  run (subjSeq [180, 188, 191, 194, 197, 200, 203, 206] [10, 6, 3, 3, 3, 3, 3, 3] (cm 130))
    (eStd lampsOn) baseStructs

/-- `branch_3` (not_applicable): as permit, but a police officer directs the lane the subject occupies. -/
def branch_3Trace : Trace :=
  run (subjSeq permitXs permitVs (cm 130)) (eStd lampsOn) baseStructs
    [{ Build.device 300 .humanDirection [101] with humanRole := some .policeOfficer }]

/-- `branch_4` (not_applicable): the flashing road user is of a class the authorized-emergency-vehicle
    aggregate excludes (a bicycle) and of an official kind other than regulatory_agency. -/
def branch_4Trace : Trace :=
  run (subjSeq permitXs permitVs (cm 130))
    (fun k => { Build.user 2 [.bicycle] (m (70 + 25 * (k : Int)), m 10) Build.east (m 25) (m 1, cm 30, m 1) with
                officialKind := some .municipal, sig := { warningLamps := lampsOn } })
    baseStructs

/-- `branch_5` (violated): the subject rests in the left lane 0.3 m from the left road edge (e passes
    in the middle lane): close to an edge, but the edge lies on its left. -/
def branch_5Trace : Trace := run (subjSeq permitXs permitVs (cm 1070)) (eStd lampsOn (m 6)) baseStructs

/-- `branch_6` (compliant): no road-edge region on the right; the subject rests on a paved shoulder of
    the highway until e has passed. -/
def branch_6Trace : Trace := run (subjSeq permitXs permitVs (m (-2))) (eStd lampsOn) shoulderStructs

/-- `branch_7` (violated): as branch_6, but a shoulder_use_permitted sign governs that shoulder. -/
def branch_7Trace : Trace :=
  run (subjSeq permitXs permitVs (m (-2))) (eStd lampsOn) shoulderStructs
    [{ Build.sign 301 .regulatorySign [120] with code := some .shoulderUsePermitted, conditions := some {} }]

/-- `branch_8` (violated): as permit, but the subject rests inside an intersection. -/
def branch_8Trace : Trace :=
  run (subjSeq permitXs permitVs (cm 130)) (eStd lampsOn) (baseStructs ++ [junction])

/-- `branch_9` (violated): the subject rests by the right edge, but angled to the lane (heading (2,1),
    cosine about 0.89). -/
def branch_9Trace : Trace :=
  run (fun k => if k < 2 then subjAt (m (permitXs.getD k 0)) (cm 130) Build.east (m (permitVs.getD k 0))
                else subjAt (m 192) (cm 180) (m 2, m 1) (m 0))
    (eStd lampsOn) baseStructs

/-- `branch_10` (violated): the subject rests at the edge, then moves off at k5 while e is alongside
    (subject behind e's centre, projections overlapping), before e has passed at k6. -/
def branch_10Trace : Trace :=
  run (subjSeq [180, 188, 192, 192, 192, 193, 195, 197] [10, 6, 0, 0, 0, 2, 2, 2] (cm 130))
    (eStd lampsOn) baseStructs

/-- `branch_11` (not_applicable): e with lamps flashing stands still 30 m behind the subject. -/
def branch_11Trace : Trace :=
  run (subjSeq cruiseXs cruiseVs (cm 130)) (fun _ => official (m 150) (m 10) (m 0) lampsOn) baseStructs

/-- `branch_12` (not_applicable): e with lamps flashing is ahead of the subject, moving away. -/
def branch_12Trace : Trace :=
  run (subjSeq cruiseXs cruiseVs (cm 130))
    (fun k => official (m (250 + 25 * (k : Int))) (m 10) (m 25) lampsOn) baseStructs

/-- `branch_13` (not_applicable): e with lamps flashing closes from behind but stays beyond reach. -/
def branch_13Trace : Trace :=
  run (subjSeq cruiseXs cruiseVs (cm 130))
    (fun k => official (m (-100 + 25 * (k : Int))) (m 10) (m 25) lampsOn) baseStructs

/-- `branch_14` (compliant): as permit, and beside e a bicycle (track 3, a class the aggregate excludes,
    official kind municipal) with a flashing red lamp closes in the middle lane at the same instant but
    never passes the subject: no duty is owed to it, so the subject's stop until e passes complies. -/
def branch_14Trace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjSeq permitXs permitVs (cm 130) k
      , eStd lampsOn (m 10) k
      , { Build.user 3 [.bicycle] (m (if k = 0 then 70 else 85 + 10 * (k : Int)), m 6) Build.east (m 10)
            (m 1, cm 30, m 1) with
          officialKind := some .municipal, sig := { warningLamps := lampsOn } } ]
      baseStructs []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_1c"
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
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .notApplicable
  , witness "branch_13" branch_13Trace .notApplicable
  , witness "branch_14" branch_14Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_1c

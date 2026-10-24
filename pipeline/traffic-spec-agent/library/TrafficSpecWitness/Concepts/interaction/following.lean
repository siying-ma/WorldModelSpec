/-
  Witnesses for drv.interaction.following.

  The geometry, one straight eastbound highway, is the same in all three scenarios:

    - region 11, a highway rectangle from x = -20 m to x = 400 m, y = -6 m to y = 6 m;
    - region 10, a lane inside it from x = -20 m to x = 400 m, y = -2 m to y = 2 m, running east;
    - track 1 (f), a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), heading
      east at 20 m/s, on the lane's centre line;
    - track 2 (l), the same vehicle ahead of it on the same centre line, also heading east at
      20 m/s, so the two headings coincide and the measured `sameDirection` is true;
    - three instants 1 s apart, both vehicles advancing 20 m per instant, so each scene is the
      same configuration carried forward.

  Both positions lie inside both polygons, so `Build.scene` derives the occupancy: f and l occupy
  lane 10 (and highway 11), and occupancy is observed for both.

  The source also supplies, as measured relations, the surface gap between the two bodies
  (longitudinal, lateral, in f's frame) and that l is ahead of f in the lane. The figures agree
  with the geometry: centre spacing minus the two half-lengths is the longitudinal gap, and the
  lateral component is -2 m (the two bodies overlap laterally, being on one centre line).

  The witness's own figures, the ones the instance gives the formal parameters:
    following_reach = 50 m, following_alignment_tolerance = 10 deg.

  holds: the leader is 34 m ahead, centre to centre, so 30 m of body-to-body longitudinal gap,
         under the 50 m reach — every conjunct true.
  fails: the leader is 304 m ahead, so 300 m of gap, beyond the reach — the gap conjunct false
         at every instant while the rest stays true.
  blind: the holds configuration, with rel.surface_gap and kin.extent absent from the manifest.
         The measured gap is dropped and no body outline is left to recompute it from, so the
         longitudinal distance between the two bodies is unobserved and the comparison is
         unknown; the lane, the occupancy, the order along the lane and the heading alignment
         all stay decided.
-/
import TrafficSpec.Concepts.interaction.following
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following@w"
    concept := "drv.interaction.following"
    literals := []
    nats := []
    params := [("following_reach", .lit (Units.metres 50) .metre), ("following_alignment_tolerance", .lit (Units.degrees 10) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The eastbound lane (region 10) and the highway it lies on (region 11). -/
def ways : List Structure :=
  [ Build.rect 11 .highway (m (-20)) (m (-6)) (m 400) (m 6)
  , Build.lane 10 [(m (-20), m (-2)), (m 400, m (-2)), (m 400, m 2), (m (-20), m 2)] Build.east ]

/-- The follower, `adv` metres along the lane. -/
def follower (adv : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (adv, m 0) Build.east (Units.metresPerSecond 20) (m 2, m 1, m 1)

/-- The leader, `lead` metres ahead of the follower, centre to centre. -/
def leader (adv lead : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (Q.add adv lead, m 0) Build.east (Units.metresPerSecond 20) (m 2, m 1, m 1)

/-- What the source measured between the two bodies: the surface gap in the subject's frame
    (longitudinal, lateral), that the two headings are aligned, and that l is ahead of f. -/
def measured (gapLon : Q) : List MeasuredRelation :=
  [ Build.relation 1 2 (fun r =>
      { r with surfaceGap := some (gapLon, m (-2)), sameDirection := some true })
  , Build.relation 2 1 (fun r =>
      { r with surfaceGap := some (gapLon, m (-2)), sameDirection := some true,
               aAheadOfB := some true }) ]

/-- One instant: the two vehicles `20 · k` metres along the lane, the leader `lead` ahead. -/
def sceneAt (k : Nat) (t : Timestamp) (lead gapLon : Q) : Scene :=
  let adv := Units.metres (20 * (k : Int))
  Build.withRelations
    (Build.scene t (some 1) [follower adv, leader adv lead] ways [])
    (measured gapLon)

/-- `holds` (compliant): Two vehicles occupy the same lane of a highway, headings aligned within the tolerance, the second ahead of the first along the lane direction with a longitudinal surface gap of 30 m, under the reach. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (m 34) (m 30)

/-- `fails` (violated): The same two vehicles, but the one ahead is 300 m away, beyond the reach the caller sets; everything else is as in the holds scenario. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (m 304) (m 300)

/-- `blind` (unknown): Two vehicles occupy the same lane with the second ahead of the first, but the source's manifest declares rel.surface_gap absent and maps no body outlines (kin.extent absent), so the distance between the nearest points of the two bodies is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (m 34) (m 30)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("f", 1), ("l", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap", "kin.extent"] ]

end TrafficSpecWitness.Concepts.interaction.following

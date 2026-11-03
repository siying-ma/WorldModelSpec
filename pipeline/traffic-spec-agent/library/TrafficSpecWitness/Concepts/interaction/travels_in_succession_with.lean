/-
  Witnesses for drv.interaction.travels_in_succession_with.

  The geometry. A straight stretch with no regions and no devices: the concept reads neither. Every
  body is a car, 5 m long and 2 m wide (half-extents 2.5 m, 1 m, 0.75 m), travelling due east at
  20 m/s; three observations one second apart, the scene the same at each, since the body speaks of
  one observation and of no duration. Track 1 is the subject and fills the formal `a` at the origin;
  track 2 fills `b` ahead of it on the same line, so the two headings are identical (cosine 1) and
  the gap between the bodies is the distance between the two footprints.

  The instance's figures, the witness's own: gap_max = 20 m, the reach within which a companion
  counts here; cos_min = 0.9, alignment within about 26 degrees.

  - `holds`: track 2's centre is 23 m ahead, so its footprint starts 18 m past track 1's — a gap of
    18 m, inside the 20 m bound, with cosine 1 above 0.9.
  - `fails`: track 2's centre is 305 m ahead, a gap of 300 m between the bodies, far beyond the
    bound; the headings are still aligned, so it is the gap that decides.
  - `blind`: the same two bodies 23 m apart, but the source observes no extents (so it observes no
    occupancy either, and Core can compute no footprint and no gap from the scene) and reports the
    gap as a measured relation of 18 m; the manifest declares `rel.surface_gap` absent, which drops
    that measurement. The headings are still observed, so the alignment is decided true and the gap
    alone is unreadable.
-/
import TrafficSpec.Concepts.interaction.travels_in_succession_with
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.travels_in_succession_with

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor (TODO), a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.travels_in_succession_with@w"
    concept := "drv.interaction.travels_in_succession_with"
    literals := []
    nats := []
    params := [("gap_max", .lit (Units.metres 20) .metre), ("cos_min", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A car of this witness: 5 m by 2 m, travelling due east at 20 m/s, at `x` on the centre line. -/
def car (track : TrackId) (x : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, m 0) Build.east (Units.metresPerSecond 20) (cm 250, m 1, cm 75)

/-- The same car as the source sees it where it measures no extent: position, heading and speed
    only, so no footprint and no observed occupancy. -/
def carWithoutExtent (track : TrackId) (x : Q) : RoadUser :=
  Build.withKin (car track x) fun k => { k with extent := none }

/-- `holds` (compliant): A car travels east at 20 m/s and another car heading east is 18 m from its body: the headings are aligned and the gap is within the bound. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m 0), car 2 (m 23) ]   -- footprints 18 m apart
      [ ]   -- no structures: the concept reads none
      [ ]   -- devices

/-- `fails` (violated): A car travels east at 20 m/s and the nearest road user heading east is 300 m from its body: the gap is far beyond the bound. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m 0), car 2 (m 305) ]   -- footprints 300 m apart
      [ ]   -- no structures: the concept reads none
      [ ]   -- devices

/-- `blind` (unknown): Two cars travel east near one another, but the source declares the gap between bodies absent, so whether they are within reach of each other cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    let s := Build.scene t (some 1)
      [ carWithoutExtent 1 (m 0), carWithoutExtent 2 (m 23) ]
      [ ]   -- no structures: the concept reads none
      [ ]   -- devices
    -- no extent is observed, so no footprint and no occupancy is: the gap is the source's own
    -- measurement, which the manifest drops
    Build.withRelations { s with occupancyObserved := [] }
      [ Build.relation 1 2 fun r => { r with surfaceGap := some (m 18, m 0) } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"] ]

end TrafficSpecWitness.Concepts.interaction.travels_in_succession_with

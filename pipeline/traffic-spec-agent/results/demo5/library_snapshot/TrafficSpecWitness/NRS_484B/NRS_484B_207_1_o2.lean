/-
  Witnesses for NRS_484B_207_1_o2.

  The carriageway runs east along y = 0 from x = 0 to x = 600 m. Two regions are recorded: the
  roadway the eastbound direction uses, y ∈ [−7 m, 0], and the centre line painted along its
  northern edge, y ∈ [−30 cm, 30 cm]. A body at y = −3.5 m is on the right side of the highway,
  a body at y = −15 cm is astride the centre line, and a body at y = +3.5 m is on the other half,
  which these traces do not record.

  Track 1 is the subject, track 2 the overtaken vehicle; both head east. The source observes
  positions, headings and speeds but not extents, and reports the two relative quantities itself:
  the signed longitudinal overlap of the pair (positive while the bodies are side by side) and the
  longitudinal surface gap from the overtaken to the subject. Both follow the same figure — the
  bodies are 3 m of half-length each, so they overlap while the centres are less than 6 m apart —
  and the `blind` witness, which drops the declared overlap, has no extent to recompute it from.

  The subject does 13 m/s and the overtaken 10 m/s, so the centre separation closes by 3 m an
  instant: it starts 13 m ahead and passes 6 m behind after five observations. Every figure here
  is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_207_1_o2
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_207_1_o2

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: d ↦ 1, overtaken ↦ 2

/-- The two bodies' half-lengths added: they are side by side while their centres are closer. -/
private def bodySpan : Q := m 6
/-- The two bodies' half-widths added, for the lateral clearance the source reports. -/
private def bodyWidth : Q := m 2

private def rightHalf : Structure := Build.rect 10 .roadway (m 0) (m (-7)) (m 600) (m 0)
private def centreLine : Structure := Build.rect 11 .centreLine (m 0) (cm (-30)) (m 600) (cm 30)

/-- Lateral placements of the subject: right side, astride the centre line, other half. -/
private def onRight : Q := cm (-350)
private def onLine : Q := cm (-15)
private def onLeft : Q := cm 350

/-- A vehicle heading east: position, heading, velocity and speed observed, extent not. -/
private def car (track : TrackId) (x y v : Q) : RoadUser :=
  { track := track
    classes := some [.motorVehicle]
    kin := { position := some (x, y)
             heading := some Build.east
             velocity := some (Build.scale Build.east v)
             speed := some v } }

/-- One instant: the subject at `(x1, y1)` doing `v1`, the overtaken at `x2` on the right side
    doing `v2`, with the overlap and the surface gap the source measures for the pair. -/
private def instant (t : Timestamp) (x1 y1 v1 x2 v2 : Q) : Scene :=
  let sep := Q.abs (Q.sub x2 x1)
  let y2 := onRight
  { Build.scene t (some 1) [car 1 x1 y1 v1, car 2 x2 y2 v2] [rightHalf, centreLine] [] with
    relations :=
      [ { a := 1, b := 2, longitudinalOverlap := some (Q.sub bodySpan sep) }
      , { a := 2, b := 1,
          surfaceGap := some (Q.sub sep bodySpan,
                              Q.sub (Q.abs (Q.sub y1 y2)) bodyWidth) } ] }

/-- The pass: the subject starts 13 m behind the overtaken and gains 3 m an instant, taking the
    lateral placement of each instant from `lats`. -/
private def pass (lats : List Q) : Trace :=
  Build.trace lats.length 0 (Units.seconds 1) fun k t =>
    let kq := Q.ofInt (Int.ofNat k)
    instant t (Q.add (m 87) (Q.mul (mps 13) kq)) ((lats[k]?).getD onRight) (mps 13)
             (Q.add (m 100) (Q.mul (mps 10) kq)) (mps 10)

/-- `forbid` (violated): The subject passes a slower vehicle on the left and cuts back across the centre line into the right half while the two bodies still overlap along the lane axis, leaving the overtaken vehicle a time gap far below the headway bound. -/
private def forbidTrace : Trace :=
  -- separations +13 +10 +7 +4 +1 −2 −5 −8: the subject is back on the right side at −5 m,
  -- where the bodies still overlap by 1 m and the overtaken's time gap is negative.
  pass [onRight, onLine, onLeft, onLeft, onLeft, onLine, onRight, onRight]

/-- `permit` (compliant): The same pass, but the subject stays left of the centre line until it is well clear ahead of the overtaken vehicle with no longitudinal overlap, then returns to the right half. -/
private def permitTrace : Trace :=
  -- the same pass held to −29 m, where the bodies are 23 m apart and the overtaken's time gap
  -- to the subject is 2.3 s, above the two-second bound by a clear margin. The subject comes
  -- back onto the centre line at −20 m, where its time gap is still only 1.4 s, and stays
  -- astride it until the bound is met.
  pass [onRight, onLine, onLeft, onLeft, onLeft, onLeft, onLeft, onLeft,
        onLeft, onLeft, onLeft, onLine, onLine, onLine, onRight]

/-- `idle` (not_applicable): The subject stays in the right half for the whole trace behind a slower vehicle it never comes alongside: `drv.overtaking` never holds and the subject never leaves the right half, so the rule does not judge it. -/
private def idleTrace : Trace :=
  -- the subject does 10 m/s, the vehicle ahead 9 m/s, and the 40 m between them closes to 33 m:
  -- the overtaken is ahead at every instant, so the subject never overtakes it.
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    let kq := Q.ofInt (Int.ofNat k)
    instant t (Q.add (m 60) (Q.mul (mps 10) kq)) onRight (mps 10)
             (Q.add (m 100) (Q.mul (mps 9) kq)) (mps 9)

/-- `blind` (unknown): The forbid scene with the source declaring `rel.longitudinal_overlap` absent: whether the bodies were still side by side at the moment of return is not observed, so the safely-clear operationalization cannot be decided and the rule reports unknown. -/
private def blindTrace : Trace := forbidTrace

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_207_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("d", 1), ("overtaken", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] ]

end TrafficSpecWitness.NRS_484B_207_1_o2

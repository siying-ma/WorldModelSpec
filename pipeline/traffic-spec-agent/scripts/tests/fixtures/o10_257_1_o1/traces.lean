/-
  Synthetic traces for the accepted rule NRS_484B_257_1_o1 (demo22), run end to end: each trace is
  built with the witness builders over the geometry of the rule's own witnesses, its occupancy
  derived from the footprint (`TraceLint.completeOccupancy`) as a source records it, admitted, and
  the rule evaluated on the grounding v ↦ 1 with the reading given as the first argument.

  Geometry (the witnesses'): the junction (3) x, y ∈ [-4, 4] m; the approach lane (2), direction
  north, entering 3, x ∈ [-3.5, 0], y ∈ [-22, -1]; a stop line (4) at y ∈ [-10.3, -9.7]; a crosswalk
  (5) at y ∈ [-8, -5]; the through highway (6) and the side highway (7). The car is track 1, 4 m
  long, at one observation a second; a step gives its reference point, speed and sight along 6.

  No occupancy is written by hand: every trace's occupancy is the footprint's, and the trace that is
  trace-checked is the trace that is evaluated.

  Printed: `LINT <case> <message>` for every trace-check message on the evaluated trace, then `CASE <case> <rule> <episode tag> <unknown reasons> <per-observation tags>` for
  each case and rule, and `PROBE <case> <act|end|entry> <per-observation tags>` for the rule's act,
  the end of its search and its event on the approach (C true, V false, U unknown, N off it), then
  `DONE`.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Concepts.motion.region_entry
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Runtime.Decode

open TrafficSpec

namespace O10Fixture

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def laneId : RegionId := 2
def junctionId : RegionId := 3
def stopLineId : RegionId := 4
def crosswalkId : RegionId := 5
def throughWayId : RegionId := 6
def sideWayId : RegionId := 7

def junction : Structure :=
  { Build.rect junctionId .intersection (m (-4)) (m (-4)) (m 4) (m 4) with
      ways := some [throughWayId, sideWayId] }
def approachLane : Structure :=
  { Build.lane laneId
      [(cm (-350), m (-22)), (m 0, m (-22)), (m 0, m (-1)), (cm (-350), m (-1))]
      Build.north (enters := some junctionId) with
      ways := some [sideWayId] }
def stopLine (marks : List RegionId) : Structure :=
  { Build.rect stopLineId .stopLine (cm (-350)) (cm (-1030)) (m 0) (cm (-970)) with
      entranceOf := marks, entranceObserved := true, ways := some [sideWayId] }
def crossing (marks : List RegionId) : Structure :=
  { Build.rect crosswalkId .crosswalk (cm (-350)) (m (-8)) (m 0) (m (-5)) with
      entranceOf := marks, entranceObserved := true, marked := some true,
      ways := some [sideWayId] }
def throughWay : Structure := Build.rect throughWayId .highway (m (-60)) (m (-4)) (m 60) (m 4)
def sideWay : Structure := Build.rect sideWayId .highway (m (-4)) (m (-30)) (m 4) (m 4)

/-- A stop line marking the approach lane. -/
def mapStopLine : List Structure :=
  [junction, approachLane, stopLine [laneId], crossing [], throughWay, sideWay]
/-- Stop line and crosswalk observed, neither marking the lane: the view point is the place. -/
def mapNoMark : List Structure :=
  [junction, approachLane, stopLine [], crossing [], throughWay, sideWay]

def stopSign : Device := Build.sign 100 .stopSign [laneId]
def yieldSign : Device := Build.sign 101 .yieldSign [laneId]

structure Step where
  x : Q := cm (-175)
  y : Q
  heading : Vec := Build.north
  speed : Q
  sight : Q
  deriving Inhabited

/-- A step on the lane's centre line, heading north. -/
def on (y speed sight : Q) : Step := { y := y, speed := speed, sight := sight }

def car (st : Step) : RoadUser :=
  { Build.user 1 [.motorVehicle] (st.x, st.y) st.heading st.speed (m 2, cm 90, cm 80) with
      sightAlongWay := some [(throughWayId, st.sight)] }

/-- The trace, checked and evaluated as it is: occupancy derived from the footprint. -/
def run (sts : List Structure) (devs : List Device) (steps : List Step) : Trace :=
  TraceLint.completeOccupancy <|
    Build.trace steps.length 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [car steps[k]!] sts devs

structure Case where
  name : String
  sts : List Structure
  devs : List Device
  steps : List Step

/-- Y1: under a yield sign the car is already at 4 m/s (at or below the slowed maximum) on its first
    observation inside the stop line's tolerance band, stays slowed, then enters. -/
def y1 : Case := ⟨"y1_slowed_on_first_band_frame", mapStopLine, [yieldSign],
  [ on (cm (-2600)) (mps 6) (m 40)
  , on (cm (-2100)) (mps 6) (m 50)
  , on (cm (-1600)) (mps 5) (m 60)      -- the approach: before the band
  , on (cm (-1290)) (mps 4) (m 70)      -- first observation in the band, already slowed
  , on (cm (-1100)) (mps 3) (m 80)      -- still slowed at the line
  , on (cm (-750)) (mps 5) (m 85)
  , on (cm (-150)) (mps 6) (m 90) ]⟩    -- entry

/-- F: no mark governs, so the place is the view point. The car halts where the crossing way can be
    seen, rolls to the junction's edge and halts again; it creeps forward so that its body overlaps
    the junction for one observation (an entry, by the footprint), backs out and is halted at the
    edge again, clear of the junction, at the observation after; it stays halted, then enters. -/
def fOccupancy : Case := ⟨"f_one_frame_junction_occupancy", mapNoMark, [stopSign],
  [ on (cm (-2600)) (mps 5) (m 40)
  , on (cm (-2100)) (mps 5) (m 50)
  , on (cm (-1600)) (mps 5) (m 60)      -- the approach: the view still short
  , on (cm (-1100)) (mps 2) (m 120)     -- the view has opened, still rolling
  , on (cm (-1050)) Q.zero (m 125)      -- halted where the way can be seen
  , on (cm (-800)) (mps 3) (m 130)
  , on (cm (-700)) Q.zero (m 135)       -- halted at the junction's edge, body [-9, -5] clear of it
  , on (cm (-550)) (mps 1) (m 138)      -- crept forward: body [-7.5, -3.5] overlaps the junction
  , on (cm (-700)) Q.zero (m 135)       -- backed out: clear again, halted
  , on (cm (-700)) Q.zero (m 135)
  , on (cm (-290)) (mps 4) (m 140) ]⟩   -- entry

/-- A later act: under a yield sign the car is too fast on its first observation in the band and
    slows to 3 m/s at the next, then enters. -/
def laterAct : Case := ⟨"later_act_counted", mapStopLine, [yieldSign],
  [ on (cm (-2600)) (mps 6) (m 40)
  , on (cm (-2100)) (mps 6) (m 50)
  , on (cm (-1600)) (mps 6) (m 60)
  , on (cm (-1290)) (mps 6) (m 70)      -- first observation in the band, too fast
  , on (cm (-1100)) (mps 3) (m 80)      -- slowed at the line
  , on (cm (-750)) (mps 5) (m 85)
  , on (cm (-150)) (mps 6) (m 90) ]⟩

/-- No act: a stop sign; the car never halts. -/
def noAct : Case := ⟨"no_act", mapStopLine, [stopSign],
  [ on (cm (-2600)) (mps 5) (m 40)
  , on (cm (-2100)) (mps 5) (m 50)
  , on (cm (-1600)) (mps 5) (m 60)
  , on (cm (-1290)) (mps 4) (m 70)
  , on (cm (-890)) (mps 4) (m 80)
  , on (cm (-290)) (mps 6) (m 90) ]⟩

/-- Insufficient history: the recording begins with the car already in the band; no halt is
    recorded and neither the start of the approach nor a previous entry is in the recording. -/
def history : Case := ⟨"insufficient_history", mapStopLine, [stopSign],
  [ on (cm (-1290)) (mps 4) (m 70)
  , on (cm (-890)) (mps 4) (m 80)
  , on (cm (-290)) (mps 6) (m 90) ]⟩

/-- A previous round: the car halts at the line and enters (round 1), drives out of the junction
    and around off the map, and comes back on the same lane, its first observation on the lane
    already in the band (so no observation of round 2 is before the band), and enters again without
    halting. Only the round-1 halt exists, and it precedes the round-1 entry. -/
def previousRound : Case := ⟨"previous_round_act_not_counted", mapStopLine, [stopSign],
  [ on (cm (-2600)) (mps 5) (m 40)
  , on (cm (-2100)) (mps 5) (m 50)
  , on (cm (-1600)) (mps 4) (m 60)
  , on (cm (-1290)) (mps 1) (m 70)
  , on (cm (-1260)) Q.zero (m 75)       -- round 1: halted 0.3 m short of the line
  , on (cm (-860)) (mps 4) (m 80)
  , on (cm (-260)) (mps 6) (m 90)       -- round 1: entry
  , on (m 3) (mps 6) (m 90)             -- inside the junction
  , on (m 12) (mps 8) (m 90)            -- out of it, north
  , { y := m 20, x := m 15, heading := Build.east, speed := mps 10, sight := m 90 }
  , { y := m 20, x := m 40, heading := Build.east, speed := mps 10, sight := m 90 }
  , { y := m 10, x := m 70, heading := Build.south, speed := mps 10, sight := m 90 }
  , { y := m (-10), x := m 70, heading := Build.south, speed := mps 10, sight := m 90 }
  , { y := m (-35), x := m 40, heading := Build.west, speed := mps 10, sight := m 40 }
  , { y := m (-35), x := m 15, heading := Build.west, speed := mps 10, sight := m 40 }
  , on (m (-28)) (mps 10) (m 40)        -- south of the lane, heading north
  , on (cm (-1290)) (mps 4) (m 70)      -- round 2: first observation on the lane, in the band
  , on (cm (-890)) (mps 4) (m 80)
  , on (cm (-290)) (mps 6) (m 90) ]⟩    -- round 2: entry, no halt in round 2

def cases : List Case := [y1, fOccupancy, laterAct, noAct, history, previousRound]

open TrafficSpec.Rules.NRS_484B_257_1_o1 in
/-- The sketch: the act found where it held at some observation and, at every later observation up
    to the judged one, the approach had not started again and the car was outside the junction
    (the judged entry aside). Existing Core only. -/
def sketchActFound : Formula :=
  .since (.and (.not approachStarted)
            (.or (.not (.atom "rel_occupies" [vV, jV] [])) entersIntersection))
    actedAtPlace

open TrafficSpec.Rules.NRS_484B_257_1_o1 in
/-- The rule with the sketch's search in place of `actFound`. -/
def sketchRule : Rule :=
  { rule with
      id := "O10_SKETCH_257_1_o1"
      obligation :=
        .forallRegion (.lit "intersection") "j"
          (.forallRegion (.lit "travel_region") "l"
            (.implies (.and approachSelected (.and properSignGoverns carrierDirected))
              (.implies entersIntersection sketchActFound))) }

open TrafficSpec.Rules.NRS_484B_257_1_o1 in
/-- A probe: the rule with `φ` as the whole duty on the approach, so that an observation's tag is
    the value of `φ` there (`C` true, `V` false) wherever the rule applies. -/
def probeRule (name : String) (φ : Formula) : Rule :=
  { rule with
      id := s!"O10_PROBE_{name}"
      obligation :=
        .forallRegion (.lit "intersection") "j"
          (.forallRegion (.lit "travel_region") "l"
            (.implies (.and approachSelected (.and properSignGoverns carrierDirected)) φ)) }

open TrafficSpec.Rules.NRS_484B_257_1_o1 in
/-- The act, the end of the search and the entry, each as a probe. -/
def probes : List (String × Rule) :=
  [("act", probeRule "act" actedAtPlace), ("end", probeRule "end" searchEnd),
   ("entry", probeRule "entry" entersIntersection)]

def concepts : List Concept :=
  [TrafficSpec.Concepts.motion.standstill.concept, TrafficSpec.Concepts.motion.region_entry.concept]

/-- The rule's verdicts on the trace, grounded v ↦ 1, as `Scenario.run` computes them. -/
def verdicts (r : Rule) (τ : Trace) (ρ : Reading) : Except String (Verdict × List Verdict) := do
  let r := Concept.expandRule concepts r
  let S ← match Grounding.Setup.admit [r] τ ρ Q.zero with
    | .ok S => pure S
    | .error ds => throw s!"not admitted: {"; ".intercalate ds}"
  let g : Grounding.Grounding := ⟨[("v", Grounding.canon S.cm 1)], []⟩
  let rows := (Grounding.evaluate S r g).verdicts.toList.map (·.2)
  pure (Grounding.episode rows, rows)

def short : Verdict → String
  | .violated => "V" | .compliant => "C" | .notApplicable => "N" | .unknown _ => "U"

end O10Fixture

open O10Fixture in
def main (args : List String) : IO Unit := do
  let text ← IO.FS.readFile (args.headD "")
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => throw (IO.userError s!"reading: {e}")
  for c in cases do
    for e in TraceLint.checkTrace (run c.sts c.devs c.steps) do IO.println s!"LINT\t{c.name}\t{e}"
    for r in [TrafficSpec.Rules.NRS_484B_257_1_o1.rule, sketchRule] do
      match verdicts r (run c.sts c.devs c.steps) ρ with
      | .ok (ep, rows) =>
        IO.println s!"CASE\t{c.name}\t{r.id}\t{ep.tag}\t{",".intercalate (ep.reasons.map UnknownReason.tag)}\t{"".intercalate (rows.map short)}"
      | .error e => IO.println s!"CASE\t{c.name}\t{r.id}\terror\t{e}\t"
    for (k, r) in probes do
      match verdicts r (run c.sts c.devs c.steps) ρ with
      | .ok (_, rows) => IO.println s!"PROBE\t{c.name}\t{k}\t{"".intercalate (rows.map short)}"
      | .error e => IO.println s!"PROBE\t{c.name}\t{k}\terror {e}"
  IO.println "DONE"

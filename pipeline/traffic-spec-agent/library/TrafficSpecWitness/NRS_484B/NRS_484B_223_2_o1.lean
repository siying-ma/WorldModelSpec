/-
  Witnesses for NRS 484B.223(2), first obligation.

  One straight east–west carriageway, 800 m long, mapped as a `roadway` (region 1) with three
  3.6 m lanes inside it: region 2 the extreme left (ordinal 0), region 3 the centre (ordinal 1)
  and region 4 the extreme right (ordinal 2). Each lane records the same census of three — the
  division the trigger asks for — its neighbours, and a marking on each side: the two outer edges
  solid, the two lines between the lanes broken, all white. `idle` swaps in the same carriageway
  with two lanes only (regions 2 and 3, ordinals 0 and 1, a census of two).

  One vehicle, `a` the subject (track 1), 4 m long and 1.8 m wide, running east at 20 m/s down
  the centre of one lane over three observations half a second apart. Occupancy is derived from
  the geometry, so the lane a is in is the lane its reference point lies in.

  Every figure here is the witness's own geometry and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_2_o1
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_223_2_o1

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

/-- A lane's markings, white on both sides. -/
private def marked (st : Structure) (ml mr : MarkingType) : Structure :=
  { st with lane := st.lane.map fun l =>
      { l with markingLeft := some (ml, MarkingColour.white)
               markingRight := some (mr, MarkingColour.white) } }

/-- An 800 m strip of lane between `y0` and `y1`, running east, with its neighbours, its ordinal
    from the left of the carriageway and the census of the division it belongs to. -/
private def strip (id : RegionId) (y0 y1 : Q) (left right : Option RegionId)
    (ordinal count : Nat) : Structure :=
  Build.lane id [(m (-400), y0), (m 400, y0), (m 400, y1), (m (-400), y1)] Build.east
    left right (some ordinal) (some count)

/-- The carriageway the statute speaks of: three clearly marked lanes. -/
private def threeLaneRoad : List Structure :=
  [ Build.rect 1 .roadway (m (-400)) (cm (-540)) (m 400) (cm 540)
  , marked (strip 2 (cm 180) (cm 540) none (some 3) 0 3) .solid .broken
  , marked (strip 3 (cm (-180)) (cm 180) (some 2) (some 4) 1 3) .broken .broken
  , marked (strip 4 (cm (-540)) (cm (-180)) (some 3) none 2 3) .broken .solid ]

/-- The same road marked into two lanes: the census is two, and the trigger never holds. -/
private def twoLaneRoad : List Structure :=
  [ Build.rect 1 .roadway (m (-400)) (cm (-360)) (m 400) (cm 360)
  , marked (strip 2 Q.zero (cm 360) none (some 3) 0 2) .solid .broken
  , marked (strip 3 (cm (-360)) Q.zero (some 2) none 1 2) .broken .solid ]

-- The body: half-length, half-width, half-height.
private def body : Q × Q × Q := (m 2, cm 90, cm 75)
private def speed : Q := Units.metresPerSecond 20

-- The centre of each lane of the three-lane carriageway, and of the right lane of the two-lane one.
private def extremeLeft : Q := cm 360
private def extremeRight : Q := cm (-360)
private def rightOfTwo : Q := cm (-180)

/-- Three observations half a second apart: a runs east down the lane whose centre is `y`. -/
private def drive (structures : List Structure) (y : Q) : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), y) Build.east speed body ]
      structures []

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_223_2_o1"
    trace := τ
    reading := {}
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ -- a drives the whole episode in the lane of ordinal zero: the extreme left of three.
    witness "forbid" (drive threeLaneRoad extremeLeft) .violated
    -- the same carriageway; a keeps the rightmost lane throughout.
  , witness "permit" (drive threeLaneRoad extremeRight) .compliant
    -- two marked lanes, not three: the division the trigger names never arises.
  , witness "idle" (drive twoLaneRoad rightOfTwo) .notApplicable
    -- the `forbid` scene with `st.lane_adjacency` unobserved: neither the census of the division
    -- nor the ordinal that ranks the lanes can be read.
  , witness "blind" (drive threeLaneRoad extremeLeft) (.unknown []) ["st.lane_adjacency"] ]

end TrafficSpecWitness.NRS_484B_223_2_o1

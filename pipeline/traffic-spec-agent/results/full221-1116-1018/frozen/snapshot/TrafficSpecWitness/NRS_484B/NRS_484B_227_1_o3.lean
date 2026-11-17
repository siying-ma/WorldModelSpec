/-
  Witnesses for NRS_484B_227_1_o3.

  Geometry (the witness's own figures; none appears in the rule). Every trace has 32 scenes at
  1 s spacing (t = 0 … 31 s); the subject (track 1, a motor vehicle, half-extent 2 m × 1 m) is the
  only road user. A highway is a rectangle 40 m wide (y from −20 to +20) unless stated; its
  divider is a strip y ∈ [−1, 1] lying on it, in pieces where an opening or an intersection
  interrupts it, each piece with its opening attribute stated (true or false).

  The turns. A U-turn about x = x0: eastbound at y = −6 up to k = 24 (yaw 0), then yaw +45°/s at
  k = 25 … 28 (headings NE, N, NW, W), crossing the divider strip at k = 26 (footprint
  x ∈ [x0−1, x0+1], y ∈ [−2, 2]), westbound at y = +6 from k = 28, yaw 0 from k = 29: the heading
  change over the 10 s window is 180°, recognized as a U-turn at k = 29. A left turn about x0:
  eastbound at y = −6 up to k = 24, yaw +45°/s at k = 25, 26 (headings NE, N), on the divider
  strip at k = 26, northbound at y = 8 + 5(k − 27) from k = 27 with yaw 0: 90°, recognized as a left
  turn at k = 27. Before the turn the yaw rate is zero, so the heading change over the window
  behind every observation up to k = 24 is zero (the turn not under way) and from k = 25 non-zero.

  The rule looks back two windows (the window behind the recognition, and the heading change
  behind each observation in it), so every witness speaks about t ∈ [21 s, 31 s], where both are
  covered.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A heading direction (need not be a unit vector). -/
def dir (x y : Int) : Vec := (Q.ofInt x, Q.ofInt y)

-- Binders ↦ tracks: subject ↦ 1

/-- The subject at a position, heading and yaw rate (deg/s). -/
def car (x y : Int) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (m x, m y) h (Units.metresPerSecond 5) (m 2, m 1, m 1))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- The U-turn about x0 (see the header). -/
def uTurnPath (x0 : Int) (k : Nat) : RoadUser :=
  let ki : Int := k
  if k ≤ 24 then car (x0 - 6 - 5 * (24 - ki)) (-6) Build.east 0
  else if k == 25 then car (x0 - 2) (-4) (dir 1 1) 45
  else if k == 26 then car x0 0 Build.north 45
  else if k == 27 then car (x0 - 2) 4 (dir (-1) 1) 45
  else if k == 28 then car (x0 - 6) 6 Build.west 45
  else car (x0 - 6 - 5 * (ki - 28)) 6 Build.west 0

/-- The left turn about x0 (see the header). -/
def leftTurnPath (x0 : Int) (k : Nat) : RoadUser :=
  let ki : Int := k
  if k ≤ 24 then car (x0 - 4 - 5 * (24 - ki)) (-6) Build.east 0
  else if k == 25 then car (x0 - 1) (-4) (dir 1 1) 45
  else if k == 26 then car x0 0 Build.north 45
  else car x0 (8 + 5 * (ki - 27)) Build.north 0

def highway (id : Nat) (x0 y0 x1 y1 : Int) : Structure :=
  Build.rect id .highway (m x0) (m y0) (m x1) (m y1)

/-- A divider piece on `way`, x ∈ [x0, x1], y ∈ [−1, 1], with its opening attribute. -/
def divider (id : Nat) (x0 x1 : Int) (opening : Bool) (way : Nat) : Structure :=
  { Build.rect id .medianOrDivider (m x0) (m (-1)) (m x1) (m 1) with
    opening := some opening, ways := some [way] }

/-- An intersection on `way`, x ∈ [x0, x1], across the highway's width. -/
def intersection (id : Nat) (x0 x1 : Int) (way : Nat) : Structure :=
  { Build.rect id .intersection (m x0) (m (-20)) (m x1) (m 20) with ways := some [way] }

def mkTrace (structures : List Structure) (path : Nat → RoadUser) : Trace :=
  Build.trace 32 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [path k] structures []

/-- `forbid` (violated): On highway h with a st.median_or_divider without opening, the subject makes a reversal of direction (drv.motion.u_turn rises) whose path crosses the divider away from any intersection and any region with the opening attribute. -/
def forbidTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) 300 false 1] (uTurnPath 0)

/-- `permit` (compliant): On h the subject makes a U-turn whose path overlaps a divider region carrying the opening attribute (a crossover). The crossover is x ∈ [−10, 10]. -/
def permitTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) (-10) false 1,
           divider 3 (-10) 10 true 1, divider 4 10 300 false 1] (uTurnPath 0)

/-- `idle` (not_applicable): The subject makes a left turn on a highway on which no st.median_or_divider lies. -/
def idleTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20] (leftTurnPath 0)

/-- `blind` (unknown): The subject on divided highway h reverses direction across the divider; kin.yaw_rate is absent, so neither left_turn nor u_turn can be recognized. -/
def blindTrace : Trace := forbidTrace

/-- `occasion_b` (violated): The subject occupies divided highway h during the first part of its left turn's window; the turn carries it across h's divider, where it has no opening, into a driveway beyond h: the trigger held for part of the turn and no opening or intersection was overlapped. Here h spans y ∈ [−12, 4]; from k = 27 the subject (y ≥ 6) is in the driveway north of it. -/
def occasion_bTrace : Trace :=
  mkTrace [highway 1 (-300) (-12) 300 4, divider 2 (-300) 300 false 1,
           Build.rect 7 .drivewayOrAlleyEntrance (m (-5)) (m 4) (m 5) (m 40)] (leftTurnPath 0)

/-- `occasion_b_outside` (not_applicable): The subject left divided highway h before its turn window began and makes a U-turn on an undivided highway: the trigger held only before the turn. The divided highway 1 is x ∈ [−300, 300], the undivided highway 6 continues it east to x = 700; the subject's footprint leaves highway 1 at k = 14 and it turns about x = 360 (window k ∈ [19, 29]). -/
def occasion_b_outsideTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) 300 false 1,
           highway 6 300 (-20) 700 20] (uTurnPath 360)

/-- `occasion_f` (compliant): The subject's U-turn on h overlaps a divider region carrying the opening attribute during part of its window. The opening is x ∈ [90, 110], the U-turn about x = 100. -/
def occasion_fTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) 90 false 1,
           divider 3 90 110 true 1, divider 4 110 300 false 1] (uTurnPath 100)

/-- The path of `occasion_f_outside`: southbound through the opening at x = −140 (k = 1), a left
    turn to eastbound at k = 2, 3, eastbound at y = −6, then the U-turn about x = −24. -/
def fOutsidePath (k : Nat) : RoadUser :=
  let ki : Int := k
  if k == 0 then car (-140) 10 Build.south 0
  else if k == 1 then car (-140) 0 Build.south 0
  else if k == 2 then car (-139) (-4) (dir 1 (-1)) 45
  else if k == 3 then car (-135) (-6) Build.east 45
  else if k ≤ 24 then car (-135 + 5 * (ki - 3)) (-6) Build.east 0
  else uTurnPath (-24) k

/-- `occasion_f_outside` (violated): The subject overlapped a divider opening on h only before its turn window began; the U-turn itself crosses the divider where it has no opening and overlaps no intersection. The opening is x ∈ [−150, −130], overlapped at k = 1; the U-turn (window k ∈ [19, 29]) crosses the closed piece at x = −24. -/
def occasion_f_outsideTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) (-150) false 1,
           divider 3 (-150) (-130) true 1, divider 4 (-130) 300 false 1] fOutsidePath

/-- `occasion_g` (compliant): The subject's left turn on h overlaps an intersection lying on h during part of its window. The intersection is x ∈ [−10, 10]; the divider stops at its edges. -/
def occasion_gTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) (-10) false 1,
           intersection 5 (-10) 10 1, divider 4 10 300 false 1] (leftTurnPath 0)

/-- `occasion_g_outside` (violated): The subject occupied an intersection on h only before its turn window began; it then makes a U-turn across the divider mid-block, overlapping no opening and no intersection. The intersection is x ∈ [−140, −120], overlapped at k = 0, 1; the U-turn about x = 0. -/
def occasion_g_outsideTrace : Trace :=
  mkTrace [highway 1 (-300) (-20) 300 20, divider 2 (-300) (-140) false 1,
           intersection 5 (-140) (-120) 1, divider 4 (-120) 300 false 1] (uTurnPath 0)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (21000, 31000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_b" occasion_bTrace .violated
  , witness "occasion_b_outside" occasion_b_outsideTrace .notApplicable
  , witness "occasion_f" occasion_fTrace .compliant
  , witness "occasion_f_outside" occasion_f_outsideTrace .violated
  , witness "occasion_g" occasion_gTrace .compliant
  , witness "occasion_g_outside" occasion_g_outsideTrace .violated ]

end TrafficSpecWitness.NRS_484B_227_1_o3

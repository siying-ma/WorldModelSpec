/-
  A condition that refers to an act stated elsewhere, executed with `Scenario.run`. The provider
  requires a halt at a stop line marking the entrance of the lane by which a road user enters a
  junction; the caller's duty holds once that halt is made ("after making such a stop": a bound on
  speed inside the junction). Three readings of the caller's condition are compared:
  - `full`: the qualified fact — a halt, within a window behind, while on a stop line that marks
    the entrance of a lane entering the junction now occupied;
  - `weak`: a halt anywhere within the window (the place dropped);
  - `anyLine`: a halt on any stop line within the window (the line's junction dropped);
  - `composed`: the provider complied with (a composed rule not engaged counts as complied).
  Each `#guard` states the verdict `Scenario.run` must give, or that a witness expecting another
  verdict is refused. All figures are this fixture's own.
-/
import TrafficSpec.Core.Evidence.Builders

namespace PreconditionContinuity

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def vV : Arg := .var "v"

def halted : Formula := .cmp (.measure "kin_speed" [vV]) .le (.lit Q.zero .metrePerSecond)
def window : Term := .lit (Units.seconds 3) .second
/-- At some observation of the window behind. -/
def once (φ : Formula) : Formula := .not (.holdsFor .time window "v" (.not φ))
def inJunction (φ : Formula) : Formula :=
  .existsRegion (.lit "intersection") "j" (.and (.atom "rel_occupies" [vV, .var "j"] []) φ)
def onLineOf (j : String) : Formula :=
  .existsRegion (.lit "stop_line") "l" (.and (.atom "rel_occupies" [vV, .var "l"] [])
    (.existsRegion (.lit "lane") "a" (.and (.atom "st_entrance_of" [.var "l", .var "a"] [])
      (.atom "st_lane_enters" [.var "a", .var j] []))))
def onAnyLine : Formula := .existsRegion (.lit "stop_line") "l" (.atom "rel_occupies" [vV, .var "l"] [])
def slow : Formula := .cmp (.measure "kin_speed" [vV]) .le (.lit (Units.metres 3) .metrePerSecond)

def cls : Formula := .atom "ru_motor_vehicle" [vV] []
def mk (id : String) (app obl : Formula) : Rule :=
  { id := id, laws := ["FIXTURE"], binders := [{ name := "v", cls := cls }], applicability := app, obligation := obl }

/-- The provider: entering a junction reached by a lane whose entrance a stop line marks, the
    road user has halted on that line within the window. -/
def provider : Rule := mk "provider"
  (inJunction (.existsRegion (.lit "stop_line") "l" (.existsRegion (.lit "lane") "a"
    (.and (.atom "st_entrance_of" [.var "l", .var "a"] []) (.atom "st_lane_enters" [.var "a", .var "j"] [])))))
  (inJunction (once (.and halted (onLineOf "j"))))
def full : Rule := mk "full" (inJunction (once (.and halted (onLineOf "j")))) slow
def weak : Rule := mk "weak" (inJunction (once halted)) slow
def anyLine : Rule := mk "anyLine" (inJunction (once (.and halted onAnyLine))) slow
def composed : Rule := mk "composed" (inJunction (.rule "provider" [("v", "v")])) slow
def rules : List Rule := [provider, full, weak, anyLine, composed]

/-! The map: two junctions on one east-bound path along y = 2 m. Lane 1 (x 0–40) enters junction
    3 (x 40–60), its entrance marked by stop line 2 (x 36–38); lane 4 (x 60–100) enters junction 6
    (x 100–120), its entrance marked by stop line 5 (x 96–98). `marked` says whether the lines'
    entrances are observed. -/
def lane (id : Nat) (x0 x1 : Int) (enters : Nat) : Structure :=
  Build.lane id [(m x0, m 0), (m x1, m 0), (m x1, m 4), (m x0, m 4)] Build.east (enters := some enters)
def line (id : Nat) (x0 : Int) (marks : Nat) (observed : Bool) : Structure :=
  { Build.rect id .stopLine (m x0) (m 0) (m (x0 + 2)) (m 4) with entranceOf := if observed then [marks] else [], entranceObserved := observed }
def junction (id : Nat) (x0 : Int) : Structure := Build.rect id .intersection (m x0) (m (-10)) (m (x0 + 20)) (m 14)
def map (observed : Bool := true) (lines : Bool := true) : List Structure :=
  [lane 1 0 40 3, junction 3 40, lane 4 60 100 6, junction 6 100] ++
  (if lines then [line 2 36 1 observed, line 5 96 4 observed] else [])

/-- The subject's path: one (x, speed) per second. -/
def drive (path : List (Int × Q)) (observed : Bool := true) (lines : Bool := true) : Trace :=
  Build.trace path.length 0 (Units.seconds 1) fun k t =>
    let (x, sp) := path.getD k (0, Q.zero)
    Build.scene t (some 1) [Build.user 1 [.motorVehicle] (m x, m 2) Build.east sp (m 2, m 1, m 1)] (map observed lines) []

def stops : Q := Q.zero
def crawl : Q := Units.metres 2
def fast : Q := Units.metres 8

/-- The qualified fact: a halt on line 5, the entrance of lane 4 into junction 6, then junction 6. -/
def haltAtLine (sp : Q) : Trace := drive [(90, fast), (97, stops), (97, stops), (105, sp), (110, sp)]
/-- A weaker fact only: a halt on lane 4 short of line 5, then junction 6 without halting on the line. -/
def haltShort : Trace := drive [(80, fast), (88, stops), (88, stops), (105, fast), (110, fast)]
/-- Another object: a halt on line 2, the entrance into junction 3, then junction 6 with no halt on line 5. -/
def haltOtherLine : Trace := drive [(37, stops), (37, stops), (50, fast), (80, fast), (105, fast), (110, fast)]
/-- The halt on line 5, its entrances unobserved by the source. -/
def haltUnobserved : Trace := drive [(90, fast), (97, stops), (97, stops), (105, fast), (110, fast)] (observed := false)
/-- No stop line at all: the provider is not engaged; no halt is made. -/
def noLine : Trace := drive [(70, fast), (78, fast), (86, fast), (94, fast), (105, fast), (110, fast)] (lines := false)

def sc (rule name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) (w : Option (Int × Int) := none) : Scenario :=
  { name := name, rule := rule, trace := τ, reading := {}, manifest := Build.manifest absent, grounding := [("v", 1)],
    expected := expected, window := w }

def ok (s : Scenario) : Bool := match s.run rules with | .ok _ => true | .error _ => false
def tagOf (s : Scenario) : String := match s.run rules with | .ok v => v.tag | .error e => e

-- The qualified fact holds: the duty applies, both ways.
#guard ok (sc "full" "after the halt, slow" (haltAtLine crawl) .compliant)
#guard ok (sc "full" "after the halt, fast" (haltAtLine fast) .violated)
#guard ok (sc "provider" "the halt is made" (haltAtLine crawl) .compliant)
-- A weaker fact holds and the qualified one does not: the duty does not apply; the weak reading
-- applies it, and a witness expecting the weak reading's verdict is refused for the full one.
#guard ok (sc "full" "short of the line" haltShort .notApplicable)
#guard ok (sc "weak" "short of the line" haltShort .violated)
#guard !ok (sc "full" "short of the line, expected as the weak reading" haltShort .violated)
-- The act at another object: the halt on another junction's line is not this duty's premise.
#guard ok (sc "full" "another line" haltOtherLine .notApplicable (w := some (4000, 5000)))
#guard ok (sc "anyLine" "another line" haltOtherLine .violated (w := some (4000, 5000)))
-- The fact unobserved: unknown under the mask, never not applicable.
#guard ok (sc "full" "entrances unobserved" haltUnobserved (.unknown []) ["st.entrance_of"])
#guard !ok (sc "full" "entrances unobserved, expected not applicable" haltUnobserved .notApplicable ["st.entrance_of"])
-- The provider not engaged establishes no halt: its composition holds, the qualified fact does not.
#guard tagOf (sc "provider" "no line" noLine .notApplicable (w := some (4000, 5000))) == "not_applicable"
#guard ok (sc "composed" "no line" noLine .violated (w := some (4000, 5000)))
#guard ok (sc "full" "no line" noLine .notApplicable (w := some (4000, 5000)))
-- An earlier wrong qualification corrected: on the case the weak reading decided wrongly, the
-- corrected condition gives the verdict the words give, and the weak one still does not.
#guard tagOf (sc "weak" "short of the line" haltShort .notApplicable) != "not_applicable"
#guard tagOf (sc "full" "short of the line" haltShort .notApplicable) == "not_applicable"

end PreconditionContinuity

/-
  TrafficSpec.Tests.RoadProfile
  The roadway's grade and curvature at a road user's position: one value per road user and scene,
  the grade signed along the user's heading and unknown without it, the curvature a magnitude; an
  omitted value is unknown. The comparisons rules make on them, checked true, false and unknown,
  and on two road users of one roadway with different values.
-/
import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Evidence.TraceLint
namespace TrafficSpec.Tests.RoadProfile
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Decode

def east : Vec := (Q.ofInt 1, Q.zero)
/-- A car on roadway 7 at `10·id` m heading `h`, at `v` m/s, with the road's grade and curvature
    at its position as the source gives them. -/
def car (id : Nat) (v : Int) (grade curv : Option Q) (h : Option Vec := some east) : RoadUser :=
  { track := id, classes := some [.motorVehicle]
    kin := { position := some (metres (10 * Int.ofNat id), metres 0), heading := h, speed := some (metresPerSecond v) }
    roadGrade := grade, roadCurvature := curv }
def roadway7 : Structure := { id := 7, kind := .roadway }
def scene (us : List RoadUser) : Scene :=
  { t := 0, subject := some 1, users := us, structures := [roadway7]
    occupancyObserved := us.map (·.track), occupies := us.map fun u => (u.track, 7) }
def pct (n : Int) : Q := Q.mk' n 100

-- the accessors: a value per road user; the grade signed and unknown without a heading; the
-- curvature a magnitude, whatever the heading; an omitted value, or an absent user, unknown
#guard st_grade (scene [car 1 10 (some (pct 6)) none]) 1 = some (pct 6)
#guard st_grade (scene [car 1 10 (some (pct (-6))) none]) 1 = some (pct (-6))
#guard st_grade (scene [car 1 10 (some (pct 6)) none (h := none)]) 1 = none
#guard st_grade (scene [car 1 10 none (some (pct 1))]) 1 = none
#guard st_grade (scene [car 1 10 (some (pct 6)) none]) 2 = none
#guard st_curvature (scene [car 1 10 none (some (Q.mk' (-1) 50))]) 1 = some (Q.mk' 1 50)
#guard st_curvature (scene [car 1 10 none (some (Q.mk' 1 50))]) 1 = some (Q.mk' 1 50)
#guard st_curvature (scene [car 1 10 none (some (Q.mk' (-1) 50)) (h := none)]) 1 = some (Q.mk' 1 50)
#guard st_curvature (scene [car 1 10 (some (pct 6)) none]) 1 = none
-- two users of one roadway, each with the value at its own position
def twoOnOne : Scene := scene [car 1 10 (some (pct 8)) (some (Q.mk' 1 50)), car 2 10 (some (pct (-1))) (some (Q.mk' 1 1000))]
#guard st_grade twoOnOne 1 = some (pct 8) && st_grade twoOnOne 2 = some (pct (-1))
#guard st_curvature twoOnOne 1 = some (Q.mk' 1 50) && st_curvature twoOnOne 2 = some (Q.mk' 1 1000)

-- the dispatch by name: one track argument, no region
def measureV (s : Scene) (n : String) (args : List Primitives.DArg) : Option Q := (evalMeasure s n args).toOption
#guard measureV twoOnOne "st_grade" [.v 2] = some (pct (-1))
#guard measureV twoOnOne "st_curvature" [.v 1] = some (Q.mk' 1 50)
#guard (evalMeasure twoOnOne "st_grade" [.v 1, .v 7]).toOption.isNone
#guard (evalMeasure twoOnOne "st_curvature" []).toOption.isNone
#guard atomArgSorts "st_grade" = some [some .track]
#guard atomArgSorts "st_curvature" = some [some .track]
#guard (TraceLint.regionArgKinds.lookup ("st_grade", 0)).isNone
#guard (TraceLint.regionArgKinds.lookup ("st_curvature", 0)).isNone

-- the decoder: `road_grade` and `road_curvature` on a road user, either sign; omitted, unknown; a
-- structure's keys the decoder does not read are ignored, and give no user a value
def decodeScene (j : String) : Except String Scene := do
  match ← parse trace s!"\{\"scenes\": [{j}]}" with
  | s :: _ => pure s
  | [] => throw "no scene"
def userJson : String :=
  "{\"t\": 0, \"users\": [{\"track\": 1, \"kin\": {\"heading\": [1, 0]}, \"road_grade\": -0.05, \"road_curvature\": -0.02},
                          {\"track\": 2, \"kin\": {\"heading\": [1, 0]}}],
    \"structures\": [{\"id\": 7, \"kind\": \"roadway\", \"grade\": 0.1, \"curvature\": 0.01}]}"
#guard (decodeScene userJson).isOk
def decoded : Scene := (decodeScene userJson).toOption.getD { t := 0 }
#guard st_grade decoded 1 = some (Q.mk' (-1) 20)
#guard st_curvature decoded 1 = some (Q.mk' 1 50)
#guard st_grade decoded 2 = none
#guard st_curvature decoded 2 = none
#guard (decodeScene "{\"t\": 0, \"users\": [{\"track\": 1, \"road_grade\": \"steep\"}]}").toOption.isNone

-- the manifest: an absent grade or curvature clears every user's value; an absent heading leaves
-- the grade unknown and the curvature known
def without (id : String) : Manifest := { Manifest.full "t" with entries := (Manifest.full "t").entries.filter (·.1 != id) }
#guard st_grade (mask (without "st.grade") twoOnOne) 1 = none
#guard st_curvature (mask (without "st.grade") twoOnOne) 1 = some (Q.mk' 1 50)
#guard st_curvature (mask (without "st.curvature") twoOnOne) 2 = none
#guard st_grade (mask (without "st.curvature") twoOnOne) 2 = some (pct (-1))
#guard st_grade (mask (without "kin.heading") twoOnOne) 1 = none
#guard st_curvature (mask (without "kin.heading") twoOnOne) 1 = some (Q.mk' 1 50)

-- ---------------------------------------------------------------------------------------------
-- The comparisons rules make on the subject's grade and curvature, in the per-user form.
-- ---------------------------------------------------------------------------------------------
def ρ : Reading := { params := [{ name := "p.grade_resolution", value := pct 2, unit := .ratio },
                                { name := "p.curvature_resolution", value := Q.mk' 1 200, unit := .perMetre },
                                { name := "p.curve_lateral_accel_max", value := Q.ofInt 3, unit := .metrePerSecondSq }] }
/-- On a perceptible grade: the subject's grade beyond the resolution, in either direction. -/
def onGrade : Formula := .cmp (.abs (.measure "st_grade" [.var "x"])) .gt (.param "p.grade_resolution")
/-- On a curve: the subject's curvature above the resolution. -/
def onCurve : Formula := .cmp (.measure "st_curvature" [.var "x"]) .gt (.param "p.curvature_resolution")
/-- Within the lateral acceleration a curve allows: speed² × curvature at most the bound. -/
def speed : Term := .measure "kin_speed" [.var "x"]
def curveSpeed : Formula := .cmp (.mul (.mul speed speed) (.measure "st_curvature" [.var "x"])) .le (.param "p.curve_lateral_accel_max")
#guard [onGrade, onCurve, curveSpeed].all fun φ => DimCheck.errors (DimCheck.envOf ρ []) φ == []

/-- The verdict of `φ` with `x` bound to track `x`, on the one-scene trace of `us`. -/
def verdict (us : List RoadUser) (φ : Formula) (x : Nat := 1) : Tri :=
  ((evalAll (SemCtx.mk' [scene us] ρ (({} : Binding).bind "x" (.track x))) φ)[0]!).v

-- on a grade: rising and falling alike beyond the resolution; a level road not; omitted, or no
-- heading, unknown
#guard verdict [car 1 10 (some (pct 8)) none] onGrade = .t
#guard verdict [car 1 10 (some (pct (-8))) none] onGrade = .t
#guard verdict [car 1 10 (some (pct 1)) none] onGrade = .f
#guard verdict [car 1 10 none (some (Q.mk' 1 50))] onGrade = .u
#guard verdict [car 1 10 (some (pct 8)) none (h := none)] onGrade = .u
-- on a curve: a bend to either hand; a near-straight road not; omitted unknown; no heading decided
#guard verdict [car 1 10 none (some (Q.mk' (-1) 50))] onCurve = .t
#guard verdict [car 1 10 none (some (Q.mk' 1 1000))] onCurve = .f
#guard verdict [car 1 10 (some (pct 8)) none] onCurve = .u
#guard verdict [car 1 10 none (some (Q.mk' 1 50)) (h := none)] onCurve = .t
-- the curve speed: 10 m/s on a 100 m radius is 1 m/s², 20 m/s is 4 m/s²; omitted unknown
#guard verdict [car 1 10 none (some (Q.mk' 1 100))] curveSpeed = .t
#guard verdict [car 1 20 none (some (Q.mk' (-1) 100))] curveSpeed = .f
#guard verdict [car 1 20 none none] curveSpeed = .u
-- two users of one roadway: each is judged on the value at its own position
#guard verdict twoOnOne.users onGrade 1 = .t && verdict twoOnOne.users onGrade 2 = .f
#guard verdict twoOnOne.users onCurve 1 = .t && verdict twoOnOne.users onCurve 2 = .f
#guard verdict [car 1 20 none (some (Q.mk' 1 100)), car 2 10 none (some (Q.mk' 1 100))] curveSpeed 1 = .f
#guard verdict [car 1 20 none (some (Q.mk' 1 100)), car 2 10 none (some (Q.mk' 1 100))] curveSpeed 2 = .t
#guard verdict [car 1 20 none (some (Q.mk' 1 100)), car 2 20 none (some (Q.mk' 1 1000))] curveSpeed 2 = .t

end TrafficSpec.Tests.RoadProfile

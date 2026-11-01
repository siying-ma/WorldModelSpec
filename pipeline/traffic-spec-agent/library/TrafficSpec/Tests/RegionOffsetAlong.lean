import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Core.Language.RuleEval
namespace TrafficSpec.Tests.RegionOffsetAlong
open TrafficSpec Units TrafficSpec.Semantics

-- ---------------------------------------------------------------------------------------------
-- `prim_region_offset_along`: road user 1, mark 3, carrier 2 (and carrier 4 where two directions
-- are compared). Coordinates in metres or centimetres, +x east, +y north.
-- ---------------------------------------------------------------------------------------------
def m (n : Int) : Q := metres n
def cm (n : Int) : Q := centimetres n
def userAt (p : Vec) : RoadUser := Build.sparseUser 1 [.motorVehicle] p
def carrier (id : RegionId) (dir : Vec) : Structure :=
  Build.lane id [(m (-200), m (-12)), (m 104, m (-12)), (m 104, m 12), (m (-200), m 12)] dir
def mark (poly : List Vec) : Structure := Build.region 3 .stopLine poly
def offsetIn (sts : List Structure) (u : RoadUser) (l : RegionId := 2) : QR :=
  (Primitives.prim_region_offset_along (Primitives.Ctx.mk' [{ t := 0, users := [u], structures := sts }] {}) 1 3 l)[0]!
def offset (p dir : Vec) (poly : List Vec) : QR := offsetIn [carrier 2 dir, mark poly] (userAt p)
def isOffset (r : QR) (q : Q) : Bool := match r with | .ok v => Q.eq v q | .error _ => false
def isWhy (r : QR) (w : UnknownReason) : Bool := match r with | .error e => e == w | .ok _ => false
def same (a b : QR) : Bool :=
  match a, b with | .ok x, .ok y => Q.eq x y | .error e, .error e' => e == e' | _, _ => false
def undef : UnknownReason := .undefined "prim_region_offset_along"
def east : Vec := Build.east

-- a straight line across the carrier, x from 90 to 90.2
def bar : List Vec := [(m 90, m (-9)), (cm 9020, m (-9)), (cm 9020, m 6), (m 90, m 6)]
-- ahead: the distance to the near side; behind: minus the distance to the far side
#guard isOffset (offset (m 85, cm (-150)) east bar) (m 5)
#guard isOffset (offset (m 95, cm (-150)) east bar) (cm (-480))
-- the reference point in the mark, on its edge, or on a vertex: zero
#guard isOffset (offset (cm 9010, cm (-150)) east bar) Q.zero
#guard isOffset (offset (m 90, cm (-150)) east bar) Q.zero
#guard isOffset (offset (cm 9020, cm (-150)) east bar) Q.zero
#guard isOffset (offset (m 90, m (-9)) east bar) Q.zero
-- the reversed direction flips the sign where the mark lies on one side
#guard isOffset (offset (m 85, cm (-150)) Build.west bar) (m (-5))
#guard isOffset (offset (m 95, cm (-150)) Build.west bar) (cm 480)
-- a direction scaled by a positive factor gives the same result
#guard [Q.ofInt 3, Q.mk' 1 1000, Q.ofInt 250].all fun k =>
  [(m 85, cm (-150)), (m 95, cm (-150)), (cm 9010, cm (-150))].all fun p =>
    same (offset p (Build.scale east k) bar) (offset p east bar)
-- a mark the travel line does not meet: from its projection [lo, hi] on the direction, lo where
-- lo > 0, hi where hi < 0, undefined where it spans or touches zero
def short : List Vec := [(m 90, m 3), (cm 9020, m 3), (cm 9020, m 6), (m 90, m 6)]
#guard isOffset (offset (m 85, cm (-150)) east short) (m 5)
#guard isOffset (offset (m 95, cm (-150)) east short) (cm (-480))
#guard isOffset (offset (m 85, cm (-150)) Build.west short) (m (-5))
#guard isWhy (offset (m 85, cm (-150)) Build.north bar) undef
#guard isWhy (offset (cm 9010, m 8) east bar) undef
-- an oblique mark missed beside its end: the near end of its projection
def slant : List Vec := [(m 90, m 0), (cm 9020, m 0), (cm 9620, m 6), (m 96, m 6)]
#guard isOffset (offset (m 85, m (-2)) east slant) (m 5)
#guard isOffset (offset (m 99, m (-2)) east slant) (cm (-280))
#guard [slant, slant.reverse, slant.drop 2 ++ slant.take 2].all fun poly =>
  [(m 85, m (-2)), (m 99, m (-2)), (m 93, m 1)].all fun p => same (offset p east poly) (offset p east slant)
-- the projection's near end, not the projection of the Euclidean nearest point (5, 1)
def tall : List Vec := [(m 1, m 100), (m 5, m 1), (m 6, m 1)]
#guard isOffset (offset (m 0, m 0) east tall) (m 1)
-- a projection that only touches zero, and one that spans it, are undefined
#guard isWhy (offset (m 1, m 0) east tall) undef
#guard isWhy (offset (m 3, m 0) east tall) undef
-- the two branches: a 2 mm lateral move from missing the mark to meeting it changes the value
-- from the projection gap to the distance along the line; the sign is the same
def wedge : List Vec := [(m 100, m 0), (m 1, m 1), (m 1, m 2)]
#guard isOffset (offset (m 0, Units.millimetres (-1)) east wedge) (m 1)
#guard isOffset (offset (m 0, Units.millimetres 1) east wedge) (Units.millimetres 99901)
-- the start vertex, the orientation and a positive scaling of the direction change nothing
#guard [tall, tall.reverse, tall.drop 1 ++ tall.take 1, wedge, wedge.reverse, wedge.drop 2 ++ wedge.take 2].all fun poly =>
  [(m 0, m 0), (m 0, Units.millimetres (-1)), (m 0, Units.millimetres 1), (m 3, m 0)].all fun p =>
    same (offset p east poly) (offset p east (if poly.length == 3 && poly.any (· == (m 1, m 100)) then tall else wedge)) &&
    same (offset p (Build.scale east (Q.ofInt 7)) poly) (offset p east poly)

-- ---------------------------------------------------------------------------------------------
-- A U-shaped mark: bars at x 87..87.2 and 92.8..93 joined below at y -6..-5.8, open to the north.
-- ---------------------------------------------------------------------------------------------
def uMark : List Vec :=
  [(m 87, m (-6)), (m 93, m (-6)), (m 93, m 3), (cm 9280, m 3), (cm 9280, cm (-580)), (cm 8720, cm (-580)),
   (cm 8720, m 3), (m 87, m 3)]
def uRotated : List Vec := uMark.drop 3 ++ uMark.take 3
-- the reference point in the opening: the line meets the mark ahead and behind, undefined
#guard isWhy (offset (m 90, cm (-150)) east uMark) undef
-- several meetings on one side: the nearest
#guard isOffset (offset (m 80, cm (-150)) east uMark) (m 7)
#guard isOffset (offset (m 100, cm (-150)) east uMark) (m (-7))
-- the start vertex and the orientation do not matter
#guard [uMark, uRotated, uMark.reverse, uRotated.reverse].all fun poly =>
  [(m 90, cm (-150)), (m 80, cm (-150)), (m 100, cm (-150)), (m 90, cm (-590)), (m 87, m 0)].all fun p =>
    same (offset p east poly) (offset p east uMark)
-- in the base the offset is zero; below it, the north line meets the base 2 m ahead
#guard isOffset (offset (m 90, cm (-590)) east uMark) Q.zero
#guard isOffset (offset (m 90, m (-8)) Build.north uMark) (m 2)

-- ---------------------------------------------------------------------------------------------
-- Closed set: a vertex the line only touches, and an edge it runs along
-- ---------------------------------------------------------------------------------------------
def apex : List Vec := [(m 95, cm (-150)), (m 94, m (-3)), (m 96, m (-3))]
#guard isOffset (offset (m 90, cm (-150)) east apex) (m 5)
#guard isOffset (offset (m 100, cm (-150)) east apex) (m (-5))
def ledge : List Vec := [(m 95, cm (-150)), (m 97, cm (-150)), (m 97, m 0), (m 95, m 0)]
#guard isOffset (offset (m 90, cm (-150)) east ledge) (m 5)
#guard isOffset (offset (m 96, cm (-150)) east ledge) Q.zero
-- on the edge along which the line runs, where ray casting reads the point as outside
#guard !Geom.inPolygon (m 96, m 0) ledge
#guard isOffset (offset (m 96, m 0) east ledge) Q.zero
#guard isOffset (offset (m 96, m 0) Build.west ledge) Q.zero
#guard isOffset (offset (m 100, cm (-150)) east ledge) (m (-3))

-- ---------------------------------------------------------------------------------------------
-- A 45-degree line, centre x = 90 + (y + 6), whose reference point (90, -6) lies off the travel
-- line. Projecting that reference point on the direction gives the wrong side on both lanes.
-- ---------------------------------------------------------------------------------------------
def oblique : List Vec := [(cm 8390, m (-12)), (cm 8410, m (-12)), (cm 9610, m 0), (cm 9590, m 0)]
def obliqueRef : Vec := (m 90, m (-6))
def projected (p : Vec) : Q := Geom.dot (Geom.vsub obliqueRef p) east
-- a halt 4.5 m left of the reference point, at x 90.6: still short of the line (3.8 m), which
-- the projection reads as past it (-0.6 m)
#guard isOffset (offset (cm 9060, cm (-150)) east oblique) (cm 380)
#guard Q.lt (projected (cm 9060, cm (-150))) Q.zero
-- a halt 4.5 m right of the reference point, at x 89.1: past the line (-3.5 m), which the
-- projection reads as short of it (0.9 m)
#guard isOffset (offset (cm 8910, cm (-1050)) east oblique) (cm (-350))
#guard Q.lt Q.zero (projected (cm 8910, cm (-1050)))
-- two carriers with different directions on the same mark: east meets it ahead, north behind
#guard isOffset (offsetIn [carrier 2 east, carrier 4 Build.north, mark oblique] (userAt (m 90, cm (-150))) 2) (cm 440)
#guard isOffset (offsetIn [carrier 2 east, carrier 4 Build.north, mark oblique] (userAt (m 90, cm (-150))) 4) (cm (-440))

-- ---------------------------------------------------------------------------------------------
-- An oblique direction is normalised with the micrometre-rounded square root: along (1, 1) the
-- square's corner at (10, 10) is 10·√2 m away; the result counts lengths of the normalised vector,
-- here 14.14213, at most the distance and within 2·10⁻⁶ of it relatively.
-- ---------------------------------------------------------------------------------------------
def square : List Vec := [(m 10, m 10), (m 11, m 10), (m 11, m 11), (m 10, m 11)]
def diag : QR := offset (Q.zero, Q.zero) (Q.ofInt 1, Q.ofInt 1) square
#guard isOffset diag (Q.mk' 1414213 100000)
#guard match diag with
  | .ok v => Q.le (Q.mul v v) (Q.ofInt 200) &&
             Q.le (Q.ofInt 200) (let w := Q.mul v (Q.mk' 1000002 1000000); Q.mul w w)
  | .error _ => false
#guard same (offset (Q.zero, Q.zero) (Q.ofInt 7, Q.ofInt 7) square) diag
-- (3, 4) normalises without rounding: the line meets the square's corner (10, 40/3) after 50/3 m
def square34 : List Vec := [(m 10, Q.mk' 40 3), (m 20, Q.mk' 40 3), (m 20, m 20), (m 10, m 20)]
#guard isOffset (offset (Q.zero, Q.zero) (Q.ofInt 3, Q.ofInt 4) square34) (Q.mk' 50 3)
#guard same (offset (Q.zero, Q.zero) (Q.ofInt 6, Q.ofInt 8) square34) (offset (Q.zero, Q.zero) (Q.mk' 3 5, Q.mk' 4 5) square34)

-- ---------------------------------------------------------------------------------------------
-- Absent inputs are unknown; a boundary that is no simple polygon is undefined
-- ---------------------------------------------------------------------------------------------
#guard isWhy (offsetIn [carrier 2 east, mark bar] { track := 1 }) (.absentAtom "kin_position")
#guard isWhy (offsetIn [{ carrier 2 east with lane := none }, mark bar] (userAt (m 85, cm (-150)))) (.absentAtom "st_lane_direction")
#guard isWhy (offsetIn [mark bar] (userAt (m 85, cm (-150)))) (.absentAtom "st_lane_direction")
#guard isWhy (offset (m 85, cm (-150)) (Q.zero, Q.zero) bar) (.absentAtom "st_lane_direction")
#guard isWhy (offsetIn [carrier 2 east, { mark bar with boundary := none }] (userAt (m 85, cm (-150)))) (.absentAtom "st_region_geometry")
#guard isWhy (offsetIn [carrier 2 east] (userAt (m 85, cm (-150)))) (.absentAtom "st_region_geometry")
-- empty, a point, a segment, three collinear points, a bow tie, a closing vertex repeated
#guard [[], [(m 90, m 0)], [(m 90, m (-9)), (m 90, m 6)], [(m 90, m (-9)), (m 90, m 0), (m 90, m 6)],
        [(m 90, m (-9)), (m 91, m 6), (m 91, m (-9)), (m 90, m 6)], bar ++ [(m 90, m (-9))]].all fun poly =>
  isWhy (offset (m 85, cm (-150)) east poly) undef && isWhy (offset (m 90, cm (-150)) east poly) undef

-- ---------------------------------------------------------------------------------------------
-- Through the formula language: a rule compares the offset with a reading parameter in metres
-- ---------------------------------------------------------------------------------------------
def X : Arg := .var "x"
def offsetTerm : Term := .quantity "prim_region_offset_along" [X, .var "s", .var "l"] []
def shortBy : Rule :=
  { id := "test/short_by"
    laws := []
    binders := [⟨"x", .atom "ru_motor_vehicle" [X] []⟩]
    applicability := .tt
    obligation := .existsRegion (.lit "stop_line") "s" (.existsRegion (.lit "lane") "l"
      (.cmp offsetTerm .ge (.param "p.clearance"))) }
def ρ : Reading := { params := [{ name := "p.clearance", value := m 3, unit := .metre }] }
def β : Binding := ({} : Binding).bind "x" (.track 1)
def τ : Trace := (List.range 3).map fun k =>
  { t := Int.ofNat (k * 500), users := [userAt ([cm 8500, cm 8850, cm 9010][k]!, cm (-150))], structures := [carrier 2 east, mark bar] }
#guard Rule.check [shortBy] shortBy = []
#guard (Rule.check [shortBy] { shortBy with obligation := .cmp (.quantity "prim_region_offset_along" [X, X, .var "l"] []) .ge (.param "p.clearance") }).length ≥ 1
#guard (shortBy.verdicts (SemCtx.mk' τ ρ β)).toList = [.compliant, .violated, .violated]
-- the result is in metres: compared with a metre parameter it type-checks, with seconds it does not
def env : DimEnv := DimCheck.envOf ρ []
#guard (DimCheck.termDim env offsetTerm).toOption == some Dim.length
#guard DimCheck.errors env shortBy.obligation = []
#guard (DimCheck.errors env (.cmp offsetTerm .ge (.lit (seconds 3) .second))).map DimError.tag = ["mismatch"]

end TrafficSpec.Tests.RegionOffsetAlong

import TrafficSpec.Core.Vocab.Atoms
import TrafficSpec.Core.Runtime.Decode
namespace TrafficSpec.Tests.SurfaceGap
open TrafficSpec Units

-- Two 4 m × 2 m bodies (half-extents 2 m and 1 m). `a` (track 1) stands at the origin heading +x
-- unless a case moves it; `b` (track 2) is placed and turned per case.
def east : Vec := (Q.ofInt 1, Q.zero)
def west : Vec := (Q.ofInt (-1), Q.zero)
def north : Vec := (Q.zero, Q.ofInt 1)
def diag : Vec := (Q.ofInt 1, Q.ofInt 1)
-- a 3-4-5 rotation, so that a turned scene keeps exact unit headings
def r34 : Vec := (Q.ofInt 3, Q.ofInt 4)
def r34perp : Vec := (Q.ofInt (-4), Q.ofInt 3)
def rot34 (p : Vec) : Vec :=
  (Q.sub (Q.mul (Q.mk' 3 5) p.1) (Q.mul (Q.mk' 4 5) p.2), Q.add (Q.mul (Q.mk' 4 5) p.1) (Q.mul (Q.mk' 3 5) p.2))
def pt (x y : Q) : Vec := (x, y)
def half (n : Int) : Q := Q.mk' n 2

def body (id : Nat) (p : Vec) (h : Option Vec) (ext : Option (Q × Q × Q) := some (Q.ofInt 2, Q.ofInt 1, Q.mk' 1 2)) : RoadUser :=
  { track := id, classes := some [.motorVehicle]
    kin := { position := some p, heading := h, extent := ext } }
def scene (b : RoadUser) (a : RoadUser := body 1 (pt Q.zero Q.zero) (some east)) : Scene :=
  { t := 0, users := [a, b] }
def at_ (x y : Q) (h : Vec) : Scene := scene (body 2 (pt x y) (some h))

def gapIs (s : Scene) (lon lat : Q) : Bool :=
  match rel_surface_gap s 1 2 with
  | some (x, y) => Q.eq x lon && Q.eq y lat
  | none => false
def distIs (s : Scene) (d : Q) : Bool := (rel_surface_gap_distance s 1 2).any (Q.eq · d)
def within (x : Option Q) (lo hi : Q) : Bool := x.any fun v => Q.le lo v && Q.le v hi
def overlapIs (s : Scene) (d : Q) : Bool := (rel_longitudinal_overlap s 1 2).any (Q.eq · d)

-- the two-heading example: b centred 3.5 m to a's left, turned east or north
#guard gapIs (at_ Q.zero (half 7) east) Q.zero (half 3)
#guard distIs (at_ Q.zero (half 7) east) (half 3)
#guard gapIs (at_ Q.zero (half 7) north) Q.zero (half 1)
#guard distIs (at_ Q.zero (half 7) north) (half 1)
#guard rel_contact (at_ Q.zero (half 7) north) 1 2 = some false

-- parallel and opposite headings, b 10 m ahead: 10 − 2 − 2
#guard gapIs (at_ (Q.ofInt 10) Q.zero east) (Q.ofInt 6) Q.zero
#guard gapIs (at_ (Q.ofInt 10) Q.zero west) (Q.ofInt 6) Q.zero
#guard distIs (at_ (Q.ofInt 10) Q.zero west) (Q.ofInt 6)
-- parallel, diagonal: both components, and the distance from both
#guard gapIs (at_ (Q.ofInt 10) (Q.ofInt 5) east) (Q.ofInt 6) (Q.ofInt 3)
#guard within (rel_surface_gap_distance (at_ (Q.ofInt 10) (Q.ofInt 5) east) 1 2) (Q.mk' 6708203 1000000) (Q.mk' 6708204 1000000)
-- orthogonal: b turned north 10 m ahead presents its half-width, 10 − 2 − 1
#guard gapIs (at_ (Q.ofInt 10) Q.zero north) (Q.ofInt 7) Q.zero
-- oblique: b turned 45° 10 m ahead presents a corner, 8 − 3/√2 ≈ 5.878680
#guard within (rel_surface_gap_longitudinal (at_ (Q.ofInt 10) Q.zero diag) 1 2) (Q.mk' 5878675 1000000) (Q.mk' 5878685 1000000)
#guard rel_surface_gap_lateral (at_ (Q.ofInt 10) Q.zero diag) 1 2 = some Q.zero

-- both bodies turned: the orthogonal case and the two-heading example rotated by the same 3-4-5
-- turn read the same in a's frame
def turned (p : Vec) (hb : Vec) : Scene :=
  scene (body 2 (rot34 p) (some hb)) (body 1 (pt Q.zero Q.zero) (some r34))
#guard gapIs (turned (pt (Q.ofInt 10) Q.zero) r34perp) (Q.ofInt 7) Q.zero
#guard distIs (turned (pt (Q.ofInt 10) Q.zero) r34perp) (Q.ofInt 7)
#guard gapIs (turned (pt Q.zero (half 7)) r34) Q.zero (half 3)
#guard gapIs (turned (pt Q.zero (half 7)) r34perp) Q.zero (half 1)

-- side by side without contact: the projections overlap along a's axis, the bodies 0.5 m apart
#guard gapIs (at_ (Q.ofInt 1) (half 5) east) Q.zero (half 1)
#guard distIs (at_ (Q.ofInt 1) (half 5) east) (half 1)
#guard rel_contact (at_ (Q.ofInt 1) (half 5) east) 1 2 = some false
#guard overlapIs (at_ (Q.ofInt 1) (half 5) east) (Q.ofInt 3)

-- touching along an edge, at a corner, and overlapping: distance zero, contact
#guard gapIs (at_ Q.zero (Q.ofInt 2) east) Q.zero Q.zero
#guard rel_contact (at_ Q.zero (Q.ofInt 2) east) 1 2 = some true
#guard gapIs (at_ (Q.ofInt 4) (Q.ofInt 2) east) Q.zero Q.zero
#guard rel_contact (at_ (Q.ofInt 4) (Q.ofInt 2) east) 1 2 = some true
#guard distIs (at_ (Q.ofInt 1) (Q.ofInt 1) north) Q.zero
#guard rel_contact (at_ (Q.ofInt 1) (Q.ofInt 1) north) 1 2 = some true

-- no non-contact case yields a negative component or distance, nor a zero one
def apart : List Scene :=
  [at_ Q.zero (half 7) east, at_ Q.zero (half 7) north, at_ (Q.ofInt 10) Q.zero west,
   at_ (Q.ofInt 10) Q.zero north, at_ (Q.ofInt 10) Q.zero diag, at_ (Q.ofInt 1) (half 5) east,
   at_ (Q.ofInt (-10)) (Q.ofInt (-5)) diag, turned (pt (Q.ofInt 10) Q.zero) r34perp]
#guard apart.all fun s => rel_contact s 1 2 == some false
#guard apart.all fun s => (rel_surface_gap s 1 2).any fun (x, y) => Q.isNonneg x && Q.isNonneg y
#guard apart.all fun s => (rel_surface_gap_distance s 1 2).any (Q.gt · Q.zero)

-- unobserved heading or extent of either body, or a zero heading: unknown, never zero
def noHeadingB : Scene := scene (body 2 (pt Q.zero (half 7)) none)
def noExtentB : Scene := scene (body 2 (pt Q.zero (half 7)) (some east) none)
def noHeadingA : Scene := scene (body 2 (pt Q.zero (half 7)) (some east)) (body 1 (pt Q.zero Q.zero) none)
def zeroHeadingB : Scene := scene (body 2 (pt Q.zero (half 7)) (some (Q.zero, Q.zero)))
#guard [noHeadingB, noExtentB, noHeadingA, zeroHeadingB].all fun s =>
  rel_surface_gap s 1 2 == none && rel_surface_gap_distance s 1 2 == none && rel_contact s 1 2 == none
    && rel_longitudinal_overlap s 1 2 == none

-- a supplied gap is read as supplied, and the distance is its length
def suppliedGap : Scene :=
  { noHeadingB with relations := [{ a := 1, b := 2, surfaceGap := some (Q.ofInt 3, Q.ofInt 4) }] }
#guard gapIs suppliedGap (Q.ofInt 3) (Q.ofInt 4)
#guard distIs suppliedGap (Q.ofInt 5)

-- a supplied gap with a negative component reads unknown on every component, the distance and the
-- contact fallback, never as its magnitude or zero, even where the geometry is observed; a zero
-- component is a gap, and both zero is contact; a supplied contact is read as supplied
def withGap (s : Scene) (g : Q × Q) (contact : Option Bool := none) : Scene :=
  { s with relations := [{ a := 1, b := 2, surfaceGap := some g, contact := contact }] }
def gapUnknown (s : Scene) : Bool :=
  rel_surface_gap s 1 2 == none && rel_surface_gap_longitudinal s 1 2 == none
    && rel_surface_gap_lateral s 1 2 == none && rel_surface_gap_distance s 1 2 == none
    && rel_contact s 1 2 == none
def negativeGaps : List (Q × Q) :=
  [(Q.ofInt (-1), Q.mk' (-1) 2), (Q.ofInt (-1), Q.zero), (Q.zero, Q.mk' (-1) 2), (Q.ofInt 3, Q.mk' (-1) 2), (Q.mk' (-1) 2, Q.ofInt 4)]
#guard negativeGaps.all fun g => gapUnknown (withGap noHeadingB g)
#guard negativeGaps.all fun g => gapUnknown (withGap (at_ Q.zero (half 7) east) g)
#guard rel_contact (withGap noHeadingB (Q.ofInt (-1), Q.zero) (some true)) 1 2 = some true
#guard rel_contact (withGap noHeadingB (Q.ofInt (-1), Q.zero) (some false)) 1 2 = some false
#guard gapIs (withGap noHeadingB (Q.zero, Q.ofInt 4)) Q.zero (Q.ofInt 4)
#guard distIs (withGap noHeadingB (Q.zero, Q.ofInt 4)) (Q.ofInt 4)
#guard rel_contact (withGap noHeadingB (Q.zero, Q.ofInt 4)) 1 2 = some false
#guard gapIs (withGap noHeadingB (Q.zero, Q.zero)) Q.zero Q.zero
#guard rel_contact (withGap noHeadingB (Q.zero, Q.zero)) 1 2 = some true

-- the same readings from a decoded trace: the decoder keeps the supplied numbers, the atom refuses
-- a negative one
def gapTrace : String := "{\"scenes\": [" ++ ",".intercalate
  (([("[-1, -0.5]", ""), ("[-1, 0]", ""), ("[3, -0.5]", ""), ("[-1, 0]", ", \"contact\": true"), ("[0, 4]", ""), ("[0, 0]", "")].zip (List.range 6)).map
    fun ((g, extra), i) => s!"\{\"t\": {i}, \"users\": [\{\"track\": 1}, \{\"track\": 2}], \"relations\": [\{\"a\": 1, \"b\": 2, \"surface_gap\": {g}{extra}}]}") ++ "]}"
def τ : Trace := (Decode.parse Decode.trace gapTrace).toOption.getD []
#guard τ.length = 6
#guard [τ[0]!, τ[1]!, τ[2]!].all gapUnknown
#guard (τ[0]!.relation 1 2).bind (·.surfaceGap) == some (Q.ofInt (-1), Q.mk' (-1) 2)
#guard rel_surface_gap τ[3]! 1 2 = none
#guard rel_contact τ[3]! 1 2 = some true
#guard gapIs τ[4]! Q.zero (Q.ofInt 4)
#guard rel_surface_gap_longitudinal τ[4]! 1 2 = some Q.zero
#guard rel_surface_gap_lateral τ[4]! 1 2 = some (Q.ofInt 4)
#guard distIs τ[4]! (Q.ofInt 4)
#guard rel_contact τ[4]! 1 2 = some false
#guard distIs τ[5]! Q.zero
#guard rel_contact τ[5]! 1 2 = some true

-- the signed projection overlap along a's heading reads b's turned footprint: positive is the
-- shared length side by side, negative the gap between the projections
#guard overlapIs (at_ (Q.ofInt 10) Q.zero north) (Q.ofInt (-7))
#guard overlapIs (at_ (Q.ofInt 10) Q.zero east) (Q.ofInt (-6))
#guard overlapIs (at_ Q.zero (Q.ofInt 5) north) (Q.ofInt 2)
#guard overlapIs (at_ Q.zero (Q.ofInt 5) east) (Q.ofInt 4)
#guard overlapIs (turned (pt Q.zero (Q.ofInt 5)) r34perp) (Q.ofInt 2)
end TrafficSpec.Tests.SurfaceGap

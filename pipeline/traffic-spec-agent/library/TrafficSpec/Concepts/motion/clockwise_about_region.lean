/-
  drv.motion.clockwise_about_region — A road user moves clockwise about a region's reference point at the observation: seen from above in the world frame, in the sense opposite to the one in which the ontology counts a left turn as counter-clockwise, the component of its velocity (kin.velocity) perpendicular to the line from the region's reference point (st.region_geometry) to the road user's reference point (kin.position) points clockwise about the region's reference point, and that component's magnitude exceeds `tol`, a tolerance that names only the source's speed resolution. It is computed from the cross product c of the offset of the road user's reference point from the region's reference point with the velocity (the offset's first component times the velocity's second, minus the offset's second component times the velocity's first), negative for clockwise motion: the concept holds where c is negative and c times c exceeds tol times tol times the squared length of the offset. Not denoted: the direction the road user points, since a vehicle backing clockwise moves clockwise; motion toward or away from the reference point, such as entering or leaving; whether the road user occupies the region, which the caller states; the designated direction of any carrier.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    the region's reference point (st.region_geometry): atoms ['st.region_geometry'], concepts []
    the road user's reference point (kin.position): atoms ['kin.position'], concepts []

  How they are written: the offset is kin_position(x) − st_region_geometry(r) by component ("x", "y"),
  the velocity kin_velocity(x) by component; c = offX·velY − offY·velX. "c is negative" is written as
  offX·velY < offY·velX (the same comparison, with no literal); the magnitude test is
  c·c > tol·tol·(offX² + offY²), as the contract states it, so no division enters. No choice was left
  open by the contract; no narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.clockwise_about_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- The offset of the road user's reference point (kin.position) from the region's reference point
    (st.region_geometry), by component. -/
def offX : Term := .sub (.measure "kin_position" [aX, .lit "x"]) (.measure "st_region_geometry" [aR, .lit "x"])
def offY : Term := .sub (.measure "kin_position" [aX, .lit "y"]) (.measure "st_region_geometry" [aR, .lit "y"])

/-- The velocity (kin.velocity), by component. -/
def velX : Term := .measure "kin_velocity" [aX, .lit "x"]
def velY : Term := .measure "kin_velocity" [aX, .lit "y"]

/-- The cross product c: the offset's first component times the velocity's second, minus the
    offset's second component times the velocity's first. -/
def cross : Term := .sub (.mul offX velY) (.mul offY velX)

/-- c negative, written as its two products compared, so no literal enters: c < 0 iff
    offX·velY < offY·velX. -/
def clockwiseSense : Formula := .cmp (.mul offX velY) .lt (.mul offY velX)

/-- c times c exceeds tol times tol times the squared length of the offset. -/
def tangentialAboveTol : Formula :=
  .cmp (.mul cross cross) .gt (.mul (.mul pTol pTol) (.add (.mul offX offX) (.mul offY offY)))

def body : Formula := .and clockwiseSense tangentialAboveTol

def concept : Concept :=
  { id := "drv.motion.clockwise_about_region"
    contract := "A road user moves clockwise about a region's reference point at the observation: seen from above in the world frame, in the sense opposite to the one in which the ontology counts a left turn as counter-clockwise, the component of its velocity (kin.velocity) perpendicular to the line from the region's reference point (st.region_geometry) to the road user's reference point (kin.position) points clockwise about the region's reference point, and that component's magnitude exceeds `tol`, a tolerance that names only the source's speed resolution. It is computed from the cross product c of the offset of the road user's reference point from the region's reference point with the velocity (the offset's first component times the velocity's second, minus the offset's second component times the velocity's first), negative for clockwise motion: the concept holds where c is negative and c times c exceeds tol times tol times the squared length of the offset. Not denoted: the direction the road user points, since a vehicle backing clockwise moves clockwise; motion toward or away from the reference point, such as entering or leaving; whether the road user occupies the region, which the caller states; the designated direction of any carrier."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := [⟨"tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.clockwise_about_region

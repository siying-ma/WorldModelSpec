/-
  drv.motion.circulating_clockwise_about — Road user a travels clockwise about the reference point of region r, as seen from above: the point lies to the right of a's direction of travel and a's velocity turns about it clockwise. It is observed with a's position (kin.position), a's velocity (kin.velocity), a's speed (kin.speed) and r's reference point (st.region_geometry), in the world frame, in which a turn to the left is counter-clockwise (the frame of kin.yaw_rate): with d the vector from r's reference point to a's position, the cross product of d with a's velocity is negative, and its square exceeds sin_tol squared times the squared length of d times the square of a's speed, so that the share of a's motion that turns about the point is above sin_tol; and a's speed is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of the path a followed before, or of why a moves so. Not denoted: a road user at rest or moving at or below speed_tol; one travelling counter-clockwise about the point; one moving towards or away from the point within the angle sin_tol allows; one at the point itself. Where r's reference point, a's position or a's velocity is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's position (kin.position): atoms ['kin.position'], concepts []
    a's velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    a's speed (kin.speed): atoms ['kin.speed'], concepts []
    r's reference point (st.region_geometry): atoms ['st.region_geometry'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - d = (px − rx, py − ry), from `kin_position a "x"/"y"` and `st_region_geometry r "x"/"y"`
      (the reference point's components).
    - d × v = dx·vy − dy·vx, with `kin_velocity a "x"/"y"`; negative is clockwise (left turn is
      counter-clockwise in the world frame), written dx·vy < dy·vx so that no unitless zero
      is compared with a quantity in m²/s.
    - (d × v)² > sin_tol² · (dx² + dy²) · speed², with `kin_speed a`, written as products: no
      division by a measured quantity.
    - speed > speed_tol.
  A road user at the point has d = 0, so the cross product is zero and the concept is false there.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.circulating_clockwise_about

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"
def pSinTol : Term := .param "sin_tol"

/-- A component ("x" east, "y" north) of a's position (kin.position), world frame. -/
def posA (k : String) : Term := .measure "kin_position" [aA, .lit k]

/-- A component of a's velocity (kin.velocity), world frame. -/
def velA (k : String) : Term := .measure "kin_velocity" [aA, .lit k]

/-- A component of r's reference point (st.region_geometry), world frame. -/
def refR (k : String) : Term := .measure "st_region_geometry" [aR, .lit k]

/-- a's speed (kin.speed). -/
def speedA : Term := .measure "kin_speed" [aA]

/-- d, the vector from r's reference point to a's position. -/
def dx : Term := .sub (posA "x") (refR "x")
def dy : Term := .sub (posA "y") (refR "y")

/-- The cross product d × v (z component; positive counter-clockwise in the world frame). -/
def cross : Term := .sub (.mul dx (velA "y")) (.mul dy (velA "x"))

/-- The squared length of d. -/
def dSq : Term := .add (.mul dx dx) (.mul dy dy)

/-- cross < 0, cross² > sin_tol² · |d|² · speed², and speed > speed_tol. -/
def body : Formula :=
  .and (.cmp (.mul dx (velA "y")) .lt (.mul dy (velA "x")))
    (.and (.cmp (.mul cross cross) .gt
                (.mul (.mul pSinTol pSinTol) (.mul dSq (.mul speedA speedA))))
          (.cmp speedA .gt pSpeedTol))

def concept : Concept :=
  { id := "drv.motion.circulating_clockwise_about"
    contract := "Road user a travels clockwise about the reference point of region r, as seen from above: the point lies to the right of a's direction of travel and a's velocity turns about it clockwise. It is observed with a's position (kin.position), a's velocity (kin.velocity), a's speed (kin.speed) and r's reference point (st.region_geometry), in the world frame, in which a turn to the left is counter-clockwise (the frame of kin.yaw_rate): with d the vector from r's reference point to a's position, the cross product of d with a's velocity is negative, and its square exceeds sin_tol squared times the squared length of d times the square of a's speed, so that the share of a's motion that turns about the point is above sin_tol; and a's speed is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of the path a followed before, or of why a moves so. Not denoted: a road user at rest or moving at or below speed_tol; one travelling counter-clockwise about the point; one moving towards or away from the point within the angle sin_tol allows; one at the point itself. Where r's reference point, a's position or a's velocity is unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"speed_tol", .metrePerSecond⟩, ⟨"sin_tol", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.circulating_clockwise_about

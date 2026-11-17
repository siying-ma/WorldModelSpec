/-
  drv.motion.circulating_clockwise_about — Road user a travels clockwise about the reference point of region r, as seen from above: the point lies to the right of a's direction of travel and a's velocity turns about it clockwise. It is observed with a's position (kin.position), a's velocity (kin.velocity), a's speed (kin.speed) and r's reference point (st.region_geometry), in the world frame, in which a turn to the left is counter-clockwise (the frame of kin.yaw_rate): with d the vector from r's reference point to a's position, the cross product of d with a's velocity is negative, and its square exceeds sin_tol squared times the squared length of d times the square of a's speed, so that the share of a's motion that turns about the point is above sin_tol; and a's speed is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of the path a followed before, or of why a moves so. Not denoted: a road user at rest or moving at or below speed_tol; one travelling counter-clockwise about the point; one moving towards or away from the point within the angle sin_tol allows; one at the point itself. Where r's reference point, a's position or a's velocity is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's position (kin.position): atoms ['kin.position'], concepts []
    a's velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    a's speed (kin.speed): atoms ['kin.speed'], concepts []
    r's reference point (st.region_geometry): atoms ['st.region_geometry'], concepts []

  How each element is written:
    d = (kin_position a x − st_region_geometry r x, kin_position a y − st_region_geometry r y),
    the reference point read through the `st_region_geometry` measure (its position component);
    v = (kin_velocity a x, kin_velocity a y); speed = kin_speed a.
    "cross product of d with a's velocity is negative": dx·vy < dy·vx (equal to dx·vy − dy·vx < 0,
    written so no literal is needed).
    "its square exceeds sin_tol² · |d|² · speed²": (dx·vy − dy·vx)² > sin_tol²·(dx²+dy²)·speed².
    "a's speed is above speed_tol": kin_speed a > speed_tol.
  The three are conjoined. No choice was left open by the contract: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.circulating_clockwise_about

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"
def pSinTol : Term := .param "sin_tol"

/-- d = a's position − r's reference point, by component (kin.position, st.region_geometry). -/
def dx : Term := .sub (.measure "kin_position" [aA, .lit "x"]) (.measure "st_region_geometry" [aR, .lit "x"])
def dy : Term := .sub (.measure "kin_position" [aA, .lit "y"]) (.measure "st_region_geometry" [aR, .lit "y"])

/-- a's velocity by component (kin.velocity) and a's speed (kin.speed). -/
def vx : Term := .measure "kin_velocity" [aA, .lit "x"]
def vy : Term := .measure "kin_velocity" [aA, .lit "y"]
def speed : Term := .measure "kin_speed" [aA]

/-- The cross product d × v = dx·vy − dy·vx (positive counter-clockwise, the frame of kin.yaw_rate). -/
def cross : Term := .sub (.mul dx vy) (.mul dy vx)

/-- "the cross product of d with a's velocity is negative": dx·vy < dy·vx (the same inequality,
    written without a literal zero). -/
def crossNegative : Formula := .cmp (.mul dx vy) .lt (.mul dy vx)

/-- "its square exceeds sin_tol squared times the squared length of d times the square of a's speed". -/
def turnsAbout : Formula :=
  .cmp (.mul cross cross) .gt
    (.mul (.mul (.mul pSinTol pSinTol) (.add (.mul dx dx) (.mul dy dy))) (.mul speed speed))

/-- "a's speed is above speed_tol". -/
def moving : Formula := .cmp speed .gt pSpeedTol

def body : Formula := .and crossNegative (.and turnsAbout moving)

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

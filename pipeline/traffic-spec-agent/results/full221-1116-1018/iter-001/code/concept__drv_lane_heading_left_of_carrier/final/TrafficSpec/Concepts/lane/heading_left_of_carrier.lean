/-
  drv.lane.heading_left_of_carrier — Road user a, moving, points to the left of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the left. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x exceeds sin_tol, so that h lies to the left of d, counter-clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its right; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    h a's heading (kin.heading): atoms ['kin.heading'], concepts []
    d r's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []
    a's speed (kin.speed) is above speed_tol: atoms ['kin.speed'], concepts []

  Written: h = (kin_heading a x, kin_heading a y), d = (st_lane_direction r x, st_lane_direction r y),
  each read normalised by Core; the body is the conjunction of d·h > 0, d_x·h_y − d_y·h_x > sin_tol
  and kin_speed a > speed_tol, every comparison strict as the contract states. An unobserved heading,
  direction or speed leaves its comparison unknown, hence the conjunction unknown unless another
  conjunct is decidedly false. No choice was left open: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.heading_left_of_carrier

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSinTol : Term := .param "sin_tol"
def pSpeedTol : Term := .param "speed_tol"

/-- Components of h (a's heading) and d (r's designated direction), read normalised by Core. -/
def hx : Term := .measure "kin_heading" [aA, .lit "x"]
def hy : Term := .measure "kin_heading" [aA, .lit "y"]
def dx : Term := .measure "st_lane_direction" [aR, .lit "x"]
def dy : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- The zero the dot product is compared with. -/
def zero : Term := .lit Q.zero .ratio

/-- d · h > 0: a points along d rather than against it. -/
def along : Formula := .cmp (.add (.mul dx hx) (.mul dy hy)) .gt zero

/-- d_x·h_y − d_y·h_x > sin_tol: h lies to the left of d by more than the tolerance angle. -/
def leftOf : Formula := .cmp (.sub (.mul dx hy) (.mul dy hx)) .gt pSinTol

/-- a's speed above speed_tol: a moves. -/
def moving : Formula := .cmp (.measure "kin_speed" [aA]) .gt pSpeedTol

def body : Formula := .and along (.and leftOf moving)

def concept : Concept :=
  { id := "drv.lane.heading_left_of_carrier"
    contract := "Road user a, moving, points to the left of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the left. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x exceeds sin_tol, so that h lies to the left of d, counter-clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its right; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"sin_tol", .ratio⟩, ⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.heading_left_of_carrier

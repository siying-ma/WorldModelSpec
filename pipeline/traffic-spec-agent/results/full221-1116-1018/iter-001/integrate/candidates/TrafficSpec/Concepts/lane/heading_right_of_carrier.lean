/-
  drv.lane.heading_right_of_carrier — Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    h a's heading (kin.heading): atoms ['kin.heading'], concepts []
    d r's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []
    a's speed (kin.speed) is above speed_tol: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing: h = (kin_heading a "x", kin_heading a "y"), d = (st_lane_direction r "x",
  st_lane_direction r "y"), each as Core reads it normalised. The body is the conjunction of
  d·h > 0, d_x h_y − d_y h_x < −sin_tol, and kin_speed a > speed_tol, exactly as the contract states;
  no choice was left open, so no narrowing is declared.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.heading_right_of_carrier

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSinTol : Term := .param "sin_tol"
def pSpeedTol : Term := .param "speed_tol"

/-- Components of h (a's heading) and d (r's designated direction), each read normalised by Core. -/
def hx : Term := .measure "kin_heading" [aA, .lit "x"]
def hy : Term := .measure "kin_heading" [aA, .lit "y"]
def dx : Term := .measure "st_lane_direction" [aR, .lit "x"]
def dy : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- d · h = d_x h_x + d_y h_y. -/
def dot : Term := .add (.mul dx hx) (.mul dy hy)
/-- d × h = d_x h_y − d_y h_x (positive counter-clockwise, negative clockwise: to the right). -/
def cross : Term := .sub (.mul dx hy) (.mul dy hx)

/-- d · h > 0, d × h < −sin_tol, and a's speed > speed_tol. -/
def body : Formula :=
  .and (.cmp dot .gt (.lit Q.zero .ratio))
    (.and (.cmp cross .lt (.neg pSinTol))
      (.cmp (.measure "kin_speed" [aA]) .gt pSpeedTol))

def concept : Concept :=
  { id := "drv.lane.heading_right_of_carrier"
    contract := "Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"sin_tol", .ratio⟩, ⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.heading_right_of_carrier

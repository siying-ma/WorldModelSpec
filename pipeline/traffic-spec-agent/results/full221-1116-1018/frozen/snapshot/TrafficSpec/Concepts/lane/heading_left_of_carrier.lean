/-
  drv.lane.heading_left_of_carrier — Road user a, moving, points to the left of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the left. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is above sin_tol, so that h lies to the left of d, counter-clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its right; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's heading (kin.heading): atoms ['kin.heading'], concepts []
    r's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []
    a's speed (kin.speed) is above speed_tol: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - h: `kin_heading a x/y`; d: `st_lane_direction r x/y`; both read normalised by Core.
    - the dot product of d and h is positive: `d_x·h_x + d_y·h_y > 0`.
    - the cross product d_x·h_y − d_y·h_x is above sin_tol: `cross > sin_tol`.
    - a's speed above speed_tol: `kin_speed a > speed_tol`.
    - the three are conjoined at one observation; an unobserved heading, speed or direction
      leaves its comparison, hence the conjunction where the others hold, unknown.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.heading_left_of_carrier

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSinTol : Term := .param "sin_tol"
def pSpeedTol : Term := .param "speed_tol"

/-- Zero, the sign threshold of the dot product. -/
def zero : Term := .lit Q.zero .ratio

/-- h, a's heading (kin.heading), read normalised. -/
def hdg (c : String) : Term := .measure "kin_heading" [aA, .lit c]

/-- d, r's designated direction (st.lane_direction), read normalised. -/
def dir (c : String) : Term := .measure "st_lane_direction" [aR, .lit c]

/-- The dot product of d and h. -/
def dot : Term := .add (.mul (dir "x") (hdg "x")) (.mul (dir "y") (hdg "y"))

/-- The cross product d_x·h_y − d_y·h_x. -/
def cross : Term := .sub (.mul (dir "x") (hdg "y")) (.mul (dir "y") (hdg "x"))

/-- a's speed (kin.speed). -/
def speed : Term := .measure "kin_speed" [aA]

/-- a points along d, h lies to the left of d by more than the angle whose sine is sin_tol, and
    a's speed is above speed_tol. -/
def body : Formula :=
  .and (.cmp dot .gt zero)
    (.and (.cmp cross .gt pSinTol) (.cmp speed .gt pSpeedTol))

def concept : Concept :=
  { id := "drv.lane.heading_left_of_carrier"
    contract := "Road user a, moving, points to the left of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the left. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is above sin_tol, so that h lies to the left of d, counter-clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its right; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"sin_tol", .ratio⟩, ⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.heading_left_of_carrier

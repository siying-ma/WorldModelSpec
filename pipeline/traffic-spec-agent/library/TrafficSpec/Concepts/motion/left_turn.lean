/-
  drv.motion.left_turn — The road user has turned to its left so as to proceed in a direction about a quarter turn to the left of the one it was proceeding in: its signed heading change, left positive, over the window behind the observation lies within the band the caller sets, both edges of which are positive, about a quarter turn. The window is the observer's and is long enough to cover a turning made at the speed a turning road user keeps; the band is the observer's too - a sampled heading never turns exactly a quarter, so the lower edge names how much turning to the left counts as a turn rather than a drift, a lane change or an ordinary bend held, and the upper edge keeps a road user that goes on turning, towards a reversal of direction or round a block, from counting as having made a left turn. The concept is a manoeuvre read from the body's own turning: it says nothing about where on the road the turning was made, nothing about any junction, lane, opening, marking or device, nothing about the compass direction the road user set out in or ended in, nothing about its speed, and nothing about the signal given for the turning or any intention to turn. It is not a reversal of direction, which lies beyond the upper edge of the band; not a turn to the right, whose heading change has the other sign; not the road's own bend beneath a body that holds its lane; and it carries no judgement that the manoeuvre is lawful or that the road user had the right to make it. It holds from the observation at which the heading change first enters the band until the window behind has passed, and those later observations are not a further turning. Where the window reaches past the start of the trace, or a yaw rate within it is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its signed heading change, left positive, over the window behind the observation: atoms ['prim.heading_change'], concepts []

  How each element is written:

    "its signed heading change, left positive, over the window behind the observation" —
    `Term.quantity "prim_heading_change" [u] [left_turn_window]`: the primitive of that very name,
    over the formal `u`, with the formal parameter `left_turn_window` as its window length. The
    primitive is the quantity the contract names, sign and unit alike — degrees, left positive,
    integrated from `kin.yaw_rate` over the window behind the observation — and it is the whole of
    what this concept reads. Its input, the yaw rate, is the primitive's own and is not claimed
    here; nothing else of the road user, of the road or of the scene is read.

    "lies within the band the caller sets" — two comparisons on that one quantity: `.ge` the
    formal `left_turn_min_heading_change` and `.le` the formal `left_turn_max_heading_change`,
    conjoined. The band is closed at both edges (the narrowing below) and is read on the signed
    change itself: no `abs` is written anywhere, so a turning to the right, whose change is
    negative, falls below the lower edge, which the contract says the caller sets positive, and a
    body that goes on turning past the upper edge falls above it.

  The unknowns are the primitive's: a window that reaches past the start of the trace is
  `windowTruncated` and a yaw rate missing inside it is `absentAtom kin_yaw_rate`, which is what
  the contract's last sentence declares. The whole body is read at the instant, against the window
  behind it; no further temporal operator is written (see the narrowing on the last sentence of
  the contract), no region, lane, device, junction, marking, signal, heading-in-the-world or speed
  is read, and nothing of lawfulness or of the right to turn appears, which is what the contract
  excludes.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pLeftTurnWindow : Term := .param "left_turn_window"
def pLeftTurnMinHeadingChange : Term := .param "left_turn_min_heading_change"
def pLeftTurnMaxHeadingChange : Term := .param "left_turn_max_heading_change"

/-- The road user's signed heading change (degrees, left positive) over the window behind the
    observation, integrated from its yaw rate: the primitive, over the formal `u`, with the
    caller's window as its length. -/
def headingChange : Term :=
  .quantity "prim_heading_change" [aU] [pLeftTurnWindow]

/-- The turning reaches the lower edge of the band: it is a turning to the left, and more of one
    than a drift, a lane change or an ordinary bend held. -/
def atLeastBandLow : Formula :=
  .cmp headingChange .ge pLeftTurnMinHeadingChange

/-- The turning stays at or below the upper edge: the road user has not gone on turning past a
    quarter, towards a reversal of direction or round a block. -/
def atMostBandHigh : Formula :=
  .cmp headingChange .le pLeftTurnMaxHeadingChange

/-- The road user has turned to its left so as to proceed about a quarter turn to the left of the
    direction it was proceeding in: its signed heading change over the window behind lies within
    the caller's band. -/
def body : Formula :=
  .and atLeastBandLow atMostBandHigh

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "The road user has turned to its left so as to proceed in a direction about a quarter turn to the left of the one it was proceeding in: its signed heading change, left positive, over the window behind the observation lies within the band the caller sets, both edges of which are positive, about a quarter turn. The window is the observer's and is long enough to cover a turning made at the speed a turning road user keeps; the band is the observer's too - a sampled heading never turns exactly a quarter, so the lower edge names how much turning to the left counts as a turn rather than a drift, a lane change or an ordinary bend held, and the upper edge keeps a road user that goes on turning, towards a reversal of direction or round a block, from counting as having made a left turn. The concept is a manoeuvre read from the body's own turning: it says nothing about where on the road the turning was made, nothing about any junction, lane, opening, marking or device, nothing about the compass direction the road user set out in or ended in, nothing about its speed, and nothing about the signal given for the turning or any intention to turn. It is not a reversal of direction, which lies beyond the upper edge of the band; not a turn to the right, whose heading change has the other sign; not the road's own bend beneath a body that holds its lane; and it carries no judgement that the manoeuvre is lawful or that the road user had the right to make it. It holds from the observation at which the heading change first enters the band until the window behind has passed, and those later observations are not a further turning. Where the window reaches past the start of the trace, or a yaw rate within it is missing, it is unknown."
    definition := none
    args := [("u", .track)]
    params := [⟨"left_turn_window", .second⟩, ⟨"left_turn_min_heading_change", .degree⟩, ⟨"left_turn_max_heading_change", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "lies within the band the caller sets, both edges of which are positive"
          why := "Written as two comparisons on the one signed quantity, conjoined: the heading change `.ge` left_turn_min_heading_change and `.le` left_turn_max_heading_change. The band is read closed at both edges — a change exactly at the lower edge counts as a turning to the left, a change exactly at the upper edge still counts as a left turn — because the edges are the observer's own thresholds on a sampled figure and a body sitting exactly on one of them is of the kind the edge admits rather than the kind it excludes. The band is read on the signed change itself and no absolute value is written: the contract says both edges are positive, so the lower comparison is what excludes a turning to the right (a negative change) and a body that holds its course (a change about nil), and the upper comparison is what excludes a reversal of direction. Nothing in the body asserts that the caller's edges are positive, or that the lower lies below the upper: those are the caller's, and a band the caller sets otherwise simply holds of nothing."
          kind := "reading" }
      , { span := "The window is the observer's and is long enough to cover a turning made at the speed a turning road user keeps"
          why := "The window enters the body only as the length the formal parameter left_turn_window gives the primitive, which measures it in time behind the observation — the primitive integrates the yaw rate over the seconds behind, and there is no reading of it as a stretch of the road user's own path. Whether the window is long enough for a turning at the speed a turning body keeps is the caller's to answer in the figure it passes: the body states no condition on the window's length, on the road user's speed, or on how much of the turning falls inside the window, and reads no speed at all, which is what the contract's 'says nothing about its speed' requires."
          kind := "reading" }
      , { span := "It holds from the observation at which the heading change first enters the band until the window behind has passed, and those later observations are not a further turning."
          why := "No operator is written for this sentence: it states what the back window already does. The body is a comparison at the instant against the window behind it, so it becomes true at the first observation whose window holds enough of the turning to reach the lower edge and stays true while the turning remains inside the window, falling false once the turning has slid out behind. No `rises`, no `since`, no `once` and no counting of turnings is added — such an operator would make the concept hold at one observation only, or count the run of observations as several turnings, and the contract says the later observations are not a further turning rather than that they are not the manoeuvre."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn

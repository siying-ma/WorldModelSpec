/-
  drv.motion.u_turn — Road user a has turned "so as to proceed in the opposite direction": its heading has reversed, "whether accomplished by one continuous movement or not". The magnitude of its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them, is denoted where its integrated heading change lies in the band. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the magnitude of the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a reversal that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the way on which a turns, of its class, of its speed, or of why it turns. Not denoted: a heading change smaller than u_turn_min, such as a turn to the left or the right; a full loop, whose heading change exceeds 360 degrees minus u_turn_min; a reversal still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.

  Based on the posted definition `DEF-NRS-484B-077`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “U-turn” means the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    The magnitude of its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive: atoms ['prim.heading_change'], concepts []
    a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude: atoms ['kin.yaw_rate'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    360 deg — a full revolution of heading: the band's upper end is a full turn less u_turn_min, so that a full loop is not a reversal

  No magnitude below is this file's own: parameters are formals the caller fills.

  How each element is written (session):
    - The band: `turned` is `|prim_heading_change a window|`; `inBand` is `turned ≥ u_turn_min` and
      `turned ≤ 360 deg − u_turn_min`, both inclusive as the contract says. The magnitude makes a
      reversal to either hand count; the integral runs through halts and backing, so a reversal in
      several movements counts where its integrated change lies in the band.
    - The settling: `settled` is `|kin_yaw_rate a| ≤ yaw_tol`.
    - The act: `rises (inBand ∧ settled)`: the condition here and not at the previous observation,
      so the concept holds at the recognizing observation only, and again only after the condition
      has ceased and returned. The window behind is the only history read; a truncated window or a
      missing yaw rate leaves the heading change, hence the body, unknown.
  No reading beyond the contract's words was chosen: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pUTurnMin : Term := .param "u_turn_min"
def pYawTol : Term := .param "yaw_tol"

/-- A full revolution of heading, the record's declared literal (360 deg). -/
def fullTurn : Term := .lit (Units.degrees 360) .degree

/-- The magnitude of a's heading change over the window behind the observation
    (`prim.heading_change` over `window`, degrees, left positive). -/
def turned : Term := .abs (.quantity "prim_heading_change" [aA] [pWindow])

/-- That magnitude lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive. -/
def inBand : Formula :=
  .and (.cmp turned .ge pUTurnMin) (.cmp turned .le (.sub fullTurn pUTurnMin))

/-- a's yaw rate (`kin.yaw_rate`) is at most yaw_tol in magnitude: the heading has stopped turning. -/
def settled : Formula := .cmp (.abs (.measure "kin_yaw_rate" [aA])) .le pYawTol

/-- The recognition condition: the reversal lies in the band and the heading has stopped turning. -/
def reversed : Formula := .and inBand settled

/-- The act is recognized where the condition holds and did not at the previous observation: it holds
    there only, and not again until the condition has ceased and holds again. -/
def body : Formula := .rises reversed

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "Road user a has turned \"so as to proceed in the opposite direction\": its heading has reversed, \"whether accomplished by one continuous movement or not\". The magnitude of its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them, is denoted where its integrated heading change lies in the band. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the magnitude of the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a reversal that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the way on which a turns, of its class, of its speed, or of why it turns. Not denoted: a heading change smaller than u_turn_min, such as a turn to the left or the right; a full loop, whose heading change exceeds 360 degrees minus u_turn_min; a reversal still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown."
    definition := some "DEF-NRS-484B-077"
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"u_turn_min", .degree⟩, ⟨"yaw_tol", .degreePerSecond⟩]
    body := .formula body
    residues := ["The class of the road user and the place of the turn are the caller's: the concept denotes the reversal of heading for any road user anywhere, and a law reads the class and the place beside it."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn

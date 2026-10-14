/-
  drv.motion.u_turn — The road user turns its body about so as to end up travelling the way it came: the magnitude of the signed heading change over the window behind the observation is, either way, within the tolerance the caller sets of a half turn. This is the observation, over sampled measurements, of a turning “so as to proceed in the opposite direction”, “whether accomplished by one continuous movement or not”: the window is what lets a turning made in several movements be read as one turning, and the tolerance is the observer's, since no body comes to exactly the reciprocal of the heading it started from. Units: the window in seconds, the tolerance in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: a turn to the left through a quarter turn, which does not reverse the direction of travel; backing, which reverses the direction of travel without turning the body about; the place upon the road at which the turning happens, which the caller reads; or a turning the road user signals but does not make.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of the signed heading change over the window behind the observation: atoms ['prim.heading_change'], concepts []

  How the words are written:
  - "the signed heading change over the window behind the observation" is the primitive
    `prim_heading_change` of the user over `window`: "the signed heading change (degrees, left
    positive) of a road user over the window behind the observation, integrated from
    `kin.yaw_rate`", whose one parameter is "the window length (time)" and so is this concept's
    `window`. The integration, the sampling and the look-back are the primitive's: the concept
    reads no kinematic atom of its own, and the unknowns the contract names — the window reaching
    past the start of the trace, a heading change that cannot be formed — are the ones the
    primitive already reports (`windowTruncated`, `samplingGap`, `absentAtom kin_yaw_rate`).
    Because the window is the primitive's parameter, the body needs no `holdsFor` of its own:
    the primitive answers at every instant about the window behind that instant.
  - "the magnitude … either way" is `.abs` of that signed change: a turning about made to the
    right integrates negative, one made to the left positive, and the contract reads either as the
    turning about. Nothing of the sign survives into the comparison.
  - "within the tolerance the caller sets of a half turn" is one comparison,
    `| |Δψ| − 180° | ≤ reversal_tolerance`: the distance of the magnitude from a half turn,
    either side of it, at or below the tolerance. Declared as a narrowing: the parameter's meaning
    names only the shortfall ("may fall short of a half turn"), and a one-sided floor
    `|Δψ| ≥ 180° − tolerance` would read a three-quarter turn, or a body spun twice about, as a
    u-turn, though neither "end[s] up travelling the way it came"; the two-sided bound is the one
    reading of "within … of a half turn" that the contract's own first clause allows. It is
    written as a single comparison over `.abs (.sub (.abs Δψ) 180°)` rather than as two bounds,
    so that there is one place where the tolerance is spent and both sides of it are the same
    quantity.
  - the half turn is the record's declared literal, 180 degrees, written through `Units.degrees`;
    it is the geometric content of "proceed in the opposite direction" and not a figure of the
    observer's. Every other magnitude — the window, the tolerance — is a formal the caller fills.
  - the place of the turning ("upon a highway") is the record's residue: the body decides the
    motion alone and reads no region.

  Literals the contract states (declared; written through a `Units` constructor):
    180 deg — a half turn: the heading change of a body that ends travelling the way it came, which is the geometric content of “proceed in the opposite direction” and not a magnitude the observer sets

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pReversalTolerance : Term := .param "reversal_tolerance"

/-- A half turn: the record's declared literal, the heading change of a body that ends up
    travelling the way it came. -/
def halfTurn : Term := .lit (Units.degrees 180) .degree

/-- The signed heading change (degrees, left positive) of the user over the window behind the
    observation, integrated from the yaw rate by the primitive. -/
def headingChange : Term := .quantity "prim_heading_change" [aUser] [pWindow]

/-- How far the magnitude of that change — the turning about, taken either way — stands from a
    half turn. -/
def shortOfHalfTurn : Term := .abs (.sub (.abs headingChange) halfTurn)

/-- The body turned about so as to end up travelling the way it came: the magnitude of the heading
    change over the window behind is within the caller's tolerance of a half turn. -/
def body : Formula := .cmp shortOfHalfTurn .le pReversalTolerance

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "The road user turns its body about so as to end up travelling the way it came: the magnitude of the signed heading change over the window behind the observation is, either way, within the tolerance the caller sets of a half turn. This is the observation, over sampled measurements, of a turning “so as to proceed in the opposite direction”, “whether accomplished by one continuous movement or not”: the window is what lets a turning made in several movements be read as one turning, and the tolerance is the observer's, since no body comes to exactly the reciprocal of the heading it started from. Units: the window in seconds, the tolerance in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: a turn to the left through a quarter turn, which does not reverse the direction of travel; backing, which reverses the direction of travel without turning the body about; the place upon the road at which the turning happens, which the caller reads; or a turning the road user signals but does not make."
    definition := some "DEF-NRS-484B-077"
    args := [("user", .track)]
    params := [⟨"window", .second⟩, ⟨"reversal_tolerance", .degree⟩]
    body := .formula body
    residues := ["the definition places the turning upon a highway; the concept decides the motion alone and leaves the place to the caller, which reads it with `rel.occupies` and `st.highway`"]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "within the tolerance the caller sets of a half turn"
          why := "written as a two-sided bound on the distance of the magnitude from a half turn, |(|heading change| − 180 deg)| ≤ reversal_tolerance, in one comparison; the parameter's meaning names only the shortfall, but a one-sided floor would read a three-quarter turn or a body spun twice about as a u-turn, though neither ends up travelling the way it came, which is what the contract's first clause asks of the turning"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn

/-
  drv.motion.u_turn — The road user has turned so as to proceed in the direction opposite to the one it was proceeding in: the magnitude of its signed heading change over the window behind the observation lies within the band the caller sets about a half turn. The contract follows the definition's words, "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not": the window is the observer's and is long enough to cover a turning made in several movements, and the band is the observer's too - a sampled heading never reverses exactly, so the lower edge names how near a half turn counts as opposite, and the upper edge keeps a road user that goes on turning, round a roundabout or round a block, from counting as having reversed. The concept is a manoeuvre read from the body's own turning: it is not the indicator given for one, not an intention to reverse direction, not a left turn at a junction, and it carries no judgement that the manoeuvre is lawful or of where on the road it was made. It holds from the observation at which the heading change first enters the band until the window behind has passed, and those later observations are not a further turning. Where the window reaches past the start of the trace, or a yaw rate within it is missing, it is unknown.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its signed heading change over the window behind the observation: atoms ['prim.heading_change'], concepts []

  How the single element is written:

    "the magnitude of its signed heading change over the window behind the observation" —
    `prim.heading_change`, read of the track formal `u` with this concept's own window formal
    `u_turn_window` as its parameter, wrapped in `Term.abs`. The primitive is the signed heading
    change (degrees, left positive) over the back window, integrated from the yaw rate, so three
    things the contract states come from the primitive itself rather than from any operator of
    this body: the window is the window behind the observation and is the caller's length;
    "whether accomplished by one continuous movement or not" is carried by integrating the yaw
    rate over the whole window, so a turning made in three movements with pauses between them is
    one turning of the integrated magnitude and no unbroken swing is demanded; and where the
    window reaches past the start of the trace (`windowTruncated`) or a yaw rate inside it is
    missing (`absentAtom "kin_yaw_rate"`) the quantity is unknown, so both comparisons and hence
    the body are unknown, exactly as the contract's last sentence says.

    "lies within the band the caller sets about a half turn" — two comparisons of that magnitude
    against the two edge formals, conjoined: at or above `u_turn_min_heading_change`, at or below
    `u_turn_max_heading_change`. The lower edge is what the contract calls "how near a half turn
    counts as opposite"; the upper edge is what keeps a road user that goes on turning, round a
    roundabout or round a block, from counting as having reversed. No figure of the band lives
    here: both edges are formal parameters the caller fills, and the band is written about a half
    turn only in the sense that the caller's values straddle one.

    "It holds from the observation at which the heading change first enters the band until the
    window behind has passed" — nothing is written for this sentence: it is a consequence of
    reading the magnitude over the window behind, not a further demand. Once the turning has been
    made, every observation whose window still covers it reads the same magnitude and the body
    goes on holding; when the window has slid past the turning the magnitude falls back and the
    body stops holding of its own accord.

  Nothing about the indicator given for the manoeuvre (`sig.turn_indicator`), about an intention
  to reverse direction, about a junction or a hand, and nothing about where on the road or
  whether lawfully the turning was made is written: the contract excludes all of them, and the
  place the definition names ("upon a highway") is the record's residue, carried by the law that
  calls this concept.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pUTurnWindow : Term := .param "u_turn_window"
def pUTurnMinHeadingChange : Term := .param "u_turn_min_heading_change"
def pUTurnMaxHeadingChange : Term := .param "u_turn_max_heading_change"

/-- The signed heading change (degrees, left positive) of the road user over the window behind the
    observation, integrated from its yaw rate; unknown where the window reaches past the start of
    the trace or a yaw rate inside it is missing. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pUTurnWindow]

/-- Its magnitude: how far round the road user has turned over the window, whichever way. -/
def headingChangeMagnitude : Term := .abs headingChange

/-- The turning has come near enough to a half turn to count as proceeding in the opposite
    direction: the lower edge of the caller's band. -/
def reachesOppositeDirection : Formula :=
  .cmp headingChangeMagnitude .ge pUTurnMinHeadingChange

/-- The turning has not gone on past a half turn into circling: the upper edge of the band. -/
def notCircling : Formula :=
  .cmp headingChangeMagnitude .le pUTurnMaxHeadingChange

/-- The magnitude of the heading change over the window behind lies within the caller's band
    about a half turn. -/
def body : Formula := .and reachesOppositeDirection notCircling

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "The road user has turned so as to proceed in the direction opposite to the one it was proceeding in: the magnitude of its signed heading change over the window behind the observation lies within the band the caller sets about a half turn. The contract follows the definition's words, \"the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not\": the window is the observer's and is long enough to cover a turning made in several movements, and the band is the observer's too - a sampled heading never reverses exactly, so the lower edge names how near a half turn counts as opposite, and the upper edge keeps a road user that goes on turning, round a roundabout or round a block, from counting as having reversed. The concept is a manoeuvre read from the body's own turning: it is not the indicator given for one, not an intention to reverse direction, not a left turn at a junction, and it carries no judgement that the manoeuvre is lawful or of where on the road it was made. It holds from the observation at which the heading change first enters the band until the window behind has passed, and those later observations are not a further turning. Where the window reaches past the start of the trace, or a yaw rate within it is missing, it is unknown."
    definition := some "DEF-NRS-484B-077"
    args := [("u", .track)]
    params := [⟨"u_turn_window", .second⟩, ⟨"u_turn_min_heading_change", .degree⟩, ⟨"u_turn_max_heading_change", .degree⟩]
    body := .formula body
    residues := ["the definition places the turning upon a highway; the concept is the manoeuvre read from the body's own turning wherever it is made, and the law that calls it carries the place - in this plan the trigger span of NRS 484B.227(1) puts the vehicle on a divided highway."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the magnitude of its signed heading change over the window behind the observation"
          why := "Written as `Term.abs` of `prim.heading_change`, read of the track formal with this concept's own window formal as the primitive's window. Taking the magnitude discards the primitive's sign (left positive), so a reversal made by swinging to the right counts exactly as one made by swinging to the left: the contract says 'magnitude' and names no hand, and the definition's 'so as to proceed in the opposite direction' is indifferent to which way the body came round. 'Whether accomplished by one continuous movement or not' is carried by the primitive's integration of the yaw rate over the whole window rather than by any demand on the shape of the swing, so a turning made in several movements, with pauses or with a reversing manoeuvre between them, reads as one turning of the integrated magnitude; the price of that reading is that a turning one way followed by a turning back the other cancels, which is right for the direction the body ends up proceeding in and is what a signed change over a window means."
          kind := "reading" }
      , { span := "lies within the band the caller sets about a half turn"
          why := "Read as a closed band: at or above the lower edge and at or below the upper edge, so a magnitude exactly on either edge counts as within. The contract names the edges as 'how near a half turn counts as opposite' and the magnitude 'above which the road user is circling', which places the boundary values inside the band at the lower edge and leaves the upper edge's own value undecided; both are written closed so that a caller's figures are the band's limits themselves and no gap is opened between the two concepts a pair of callers might set. 'Within the band' is written as the conjunction of the two comparisons on the one magnitude, with no third demand of any kind."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn

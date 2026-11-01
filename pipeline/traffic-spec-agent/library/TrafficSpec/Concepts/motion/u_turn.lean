/-
  drv.motion.u_turn — The road user has turned upon a public way so as to proceed in the direction opposite to the one it was travelling in: at this observation its footprint overlaps a public way, and the magnitude of the signed heading change integrated over the window behind lies between min_heading_change and max_heading_change, a band about a half turn. The definition this renders is the turning of a vehicle upon a highway so as to "proceed in the opposite direction, whether accomplished by one continuous movement or not": the window is therefore long enough to span a turning made in several movements, and nothing in the concept requires the motion to be forward or continuous, a body that halts, backs and goes forward again within the window reversing its direction as much as one that sweeps round in a single arc. The reversal is read as a band on the magnitude because an exactly opposed heading is observed over sampled measurements only within bounds the observer sets: min_heading_change is the change at which a reversal is recognized, and max_heading_change the change beyond which what the window carries is no longer a reversal but a turning carried round past the opposite direction - a body that comes round a full circle ends travelling in the direction it set out in and is not denoted, and neither is one carried further still, whose direction the integrated change cannot tell from a circle's. The window is the time over which the change is integrated. The concept carries no hand: a reversal to the left and one to the right both satisfy it. It is not a signal, an intention, the region turned in or the way the body returns along, not a reversing manoeuvre backwards along the way (which changes no heading), and not a judgement that the turning is lawful or permitted. It is the recognition of the reversal and not its whole duration.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps a public way: atoms ['rel.occupies', 'st.highway'], concepts []
    the magnitude of the signed heading change integrated over the window behind lies between min_heading_change and max_heading_change: atoms ['prim.heading_change'], concepts []

  How the first element is written. The concept takes no way as an argument, so "a public way" is
  read by the kind of a region quantifier, the way an abstract-or-labelled structure kind is read:
  `existsRegion (.lit "highway") "w"` ranges over every region the source records as a highway —
  `st.highway` is "the entire public way between its boundary lines, including sidewalks and
  shoulders" — and over every region whose membership of that kind the source cannot tell, which
  the quantifier carries as unknown. `rel.occupies` is the anchoring relation, "a road user's
  footprint overlaps a lane / region": `rel_occupies [u, w]` is the contract's "its footprint
  overlaps a public way", and it ties the bound region to the road user formal. No distance to a
  way is read, and the roadway is not read: the definition speaks of the way, not of the improved
  part of it.

  How the second element is written. `prim.heading_change` is the signed change (degrees, left
  positive) integrated from `kin.yaw_rate` over the window behind, its one parameter the window
  length: `Term.quantity "prim_heading_change" [u] [window]`. The contract reads its magnitude,
  which carries no hand, so the term is wrapped in `.abs`: a reversal to the left and one to the
  right are the same quantity here. "Lies between min_heading_change and max_heading_change" is the
  conjunction of two comparisons on that magnitude, at least `min_heading_change` and at most
  `max_heading_change`. The primitive is unknown where the window is truncated, sampled too
  sparsely or a yaw rate is missing, so neither bound decides there, which is the reading the
  record's `blind` scenario asks for. Nothing in the body reads the sign of the change, the speed,
  the gear, the direction of travel or the continuity of the motion: a body that halts, backs and
  comes forward again within the window satisfies it as much as one that sweeps round in a single
  arc.

  Narrowings. Two, declared below: that the band is closed at both ends (the parameters' own
  meanings — the change "at which" a reversal is recognized, the change "above which" it is no
  longer one — put both bounds inside the band), and that the way is a region of the trace found by
  the quantifier rather than a way the caller names, since the record gives the concept no region
  formal.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinHeadingChange : Term := .param "min_heading_change"
def pMaxHeadingChange : Term := .param "max_heading_change"

/-- The region the body binds: a public way the road user's footprint overlaps. -/
def aW : Arg := .var "w"

/-- The signed heading change (degrees, left positive) integrated over the window behind this
    observation, and its magnitude, which carries no hand. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pWindow]
def reversalMagnitude : Term := .abs headingChange

/-- At this observation its footprint overlaps a public way. -/
def onPublicWay : Formula :=
  .existsRegion (.lit "highway") "w" (.atom "rel_occupies" [aU, aW] [])

/-- The magnitude of the integrated heading change lies between `min_heading_change` and
    `max_heading_change`: at least the change at which the direction of travel counts as reversed,
    and no more than the change above which what the window carries is a turning carried round past
    the opposite direction. -/
def directionReversed : Formula :=
  .and (.cmp reversalMagnitude .ge pMinHeadingChange)
       (.cmp reversalMagnitude .le pMaxHeadingChange)

/-- The road user has turned upon a public way so as to proceed in the opposite direction. -/
def body : Formula := .and onPublicWay directionReversed

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "The road user has turned upon a public way so as to proceed in the direction opposite to the one it was travelling in: at this observation its footprint overlaps a public way, and the magnitude of the signed heading change integrated over the window behind lies between min_heading_change and max_heading_change, a band about a half turn. The definition this renders is the turning of a vehicle upon a highway so as to \"proceed in the opposite direction, whether accomplished by one continuous movement or not\": the window is therefore long enough to span a turning made in several movements, and nothing in the concept requires the motion to be forward or continuous, a body that halts, backs and goes forward again within the window reversing its direction as much as one that sweeps round in a single arc. The reversal is read as a band on the magnitude because an exactly opposed heading is observed over sampled measurements only within bounds the observer sets: min_heading_change is the change at which a reversal is recognized, and max_heading_change the change beyond which what the window carries is no longer a reversal but a turning carried round past the opposite direction - a body that comes round a full circle ends travelling in the direction it set out in and is not denoted, and neither is one carried further still, whose direction the integrated change cannot tell from a circle's. The window is the time over which the change is integrated. The concept carries no hand: a reversal to the left and one to the right both satisfy it. It is not a signal, an intention, the region turned in or the way the body returns along, not a reversing manoeuvre backwards along the way (which changes no heading), and not a judgement that the turning is lawful or permitted. It is the recognition of the reversal and not its whole duration."
    definition := some "DEF-NRS-484B-077"
    args := [("u", .track)]
    params := [⟨"window", .second⟩, ⟨"min_heading_change", .degree⟩, ⟨"max_heading_change", .degree⟩]
    body := .formula body
    residues := ["which road users count as a vehicle is a legal aggregate the calling rule claims on its subject span; the concept judges the motion of whatever road user it is given."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the magnitude of the signed heading change integrated over the window behind lies between min_heading_change and max_heading_change"
          why := "written as a closed band on the magnitude of the primitive's signed value: the magnitude at least min_heading_change and at most max_heading_change, so a change of exactly either bound is a reversal. The parameters' own meanings put both bounds inside the band — min_heading_change is the change `at which` the direction of travel counts as reversed and max_heading_change the change `above which` the window carries no reversal — and the magnitude is read with `.abs`, which carries no hand, so a reversal to the left and one to the right satisfy the body alike"
          kind := "reading" }
      , { span := "its footprint overlaps a public way"
          why := "written as an existential over the regions of the trace recorded as a highway, each tied to the road user by the occupancy relation, because the record gives the concept no region formal: the way is one the quantifier finds and not one the caller names, and which way it is makes no difference to the body. A region whose membership of the kind the source cannot tell leaves the conjunct unknown, as the quantifier's semantics require, and a trace whose record carries no public way at all reads as not denoted rather than unknown"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn

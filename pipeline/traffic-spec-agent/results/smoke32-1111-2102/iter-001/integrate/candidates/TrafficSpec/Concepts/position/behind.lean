/-
  drv.position.behind — Road user a is behind road user b at an observation: their headings are aligned and b's body lies wholly ahead of a's along a's heading. Measured as headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned), the bearing of b from a (rel.bearing) pointing forward in a's frame, and the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero). Either road user may be at rest. Not a stand-in for following in the same lane: b may travel in another lane.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned): atoms ['rel.same_direction'], concepts []
    the bearing of b from a (rel.bearing) pointing forward in a's frame: atoms ['rel.bearing'], concepts []
    the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero): atoms ['rel.longitudinal_overlap'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Written as the conjunction of the three elements, at one observation:
    rel_same_direction(a, b) with the formal `alignment` as its cosine tolerance;
    rel_bearing(a, b, ahead): the longitudinal component of b's bearing in a's frame positive;
    rel_longitudinal_overlap(a, b) < 0 m: the projections on a's heading share no length.
  No speed is read, so either road user may be at rest; no lane is read, so b may be in another lane.
  No choice was left open by the contract: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.behind

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignment : Term := .param "alignment"

/-- Headings aligned: `rel_same_direction` with the alignment tolerance. -/
def aligned : Formula := .atom "rel_same_direction" [aA, aB] [pAlignment]

/-- The bearing of b from a points forward in a's frame (its longitudinal component positive). -/
def bearingForward : Formula := .atom "rel_bearing" [aA, aB, .lit "ahead"] []

/-- The two footprints' projections on a's heading share no length: the overlap below zero. -/
def noOverlap : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .lt (.lit (Units.metres 0) .metre)

def body : Formula := .and aligned (.and bearingForward noOverlap)

def concept : Concept :=
  { id := "drv.position.behind"
    contract := "Road user a is behind road user b at an observation: their headings are aligned and b's body lies wholly ahead of a's along a's heading. Measured as headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned), the bearing of b from a (rel.bearing) pointing forward in a's frame, and the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero). Either road user may be at rest. Not a stand-in for following in the same lane: b may travel in another lane."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"alignment", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.position.behind

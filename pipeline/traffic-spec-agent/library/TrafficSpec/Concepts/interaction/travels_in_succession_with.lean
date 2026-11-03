/-
  drv.interaction.travels_in_succession_with — At the observation the two road users travel in company along the road: their headings are aligned within cos_min and the distance between their bodies is at most gap_max. The concept states the configuration of the pair at the observation and nothing of its duration; how many such companions a road user has, and what class each of them belongs to, is the caller's to count and to require. Not a stand-in for: an arrangement between the two -- that they travel as one unit by agreement, escort or permit is not denoted -- membership of any class, which the caller reads itself, the order of the two along the road, the lane either of them is in, or the way they are travelling on, which is the caller's.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the distance between their bodies is at most gap_max: atoms ['rel.surface_gap'], concepts []
    their headings are aligned within cos_min: atoms ['rel.same_direction'], concepts []

  How each element is written:
    "their headings are aligned within cos_min" — `rel_same_direction a b` with `cos_min` as the
    atom's own tolerance: the atom is "headings aligned: the cosine of the angle between the
    headings is above its tolerance", so the contract's tolerance is the atom's parameter and
    nothing is left to add. A road user met head-on falls outside it.
    "the distance between their bodies is at most gap_max" — `rel_surface_gap a b` read without a
    component, which by the atom's contract is "the distance between the nearest points of two
    bodies, each body's footprint read with its own heading and extent", compared `≤ gap_max`.
    The componentwise reads (longitudinal, lateral) are not taken: the contract speaks of one
    distance between the bodies, not of a distance along or across a heading.

  The two elements are conjoined at the judged observation: the contract states the configuration
  of the pair "at the observation and nothing of its duration", so no temporal operator and no
  window enters the body.

  Narrowing (declared below): the contract leaves open whether the pair must be two distinct
  tracks; the body does not require it, leaving the exclusion to the caller that quantifies.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.travels_in_succession_with

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pGapMax : Term := .param "gap_max"
def pCosMin : Term := .param "cos_min"

/-- The headings of the two are aligned within the tolerance, and the distance between their
    bodies is at most the bound: the configuration of the pair at the judged observation. -/
def body : Formula :=
  .and
    (.atom "rel_same_direction" [aA, aB] [pCosMin])
    (.cmp (.measure "rel_surface_gap" [aA, aB]) .le pGapMax)

def concept : Concept :=
  { id := "drv.interaction.travels_in_succession_with"
    contract := "At the observation the two road users travel in company along the road: their headings are aligned within cos_min and the distance between their bodies is at most gap_max. The concept states the configuration of the pair at the observation and nothing of its duration; how many such companions a road user has, and what class each of them belongs to, is the caller's to count and to require. Not a stand-in for: an arrangement between the two -- that they travel as one unit by agreement, escort or permit is not denoted -- membership of any class, which the caller reads itself, the order of the two along the road, the lane either of them is in, or the way they are travelling on, which is the caller's."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"gap_max", .metre⟩, ⟨"cos_min", .ratio⟩]
    body := .formula body
    residues := ["that the two are in a single file along the way, one behind the other, is not denoted: a pair abreast within the gap satisfies the relation too. A caller needing the file reads the in-lane order itself."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the two road users travel in company along the road"
          why := "the body states the configuration of the pair as it is given and does not require a and b to be distinct tracks: the contract leaves to the caller how many companions a road user has and what each of them is, so a caller that quantifies for a companion excludes the road user itself with `same`. Grounded on one and the same track the body reads a zero gap and aligned headings, which is the configuration it states and nothing more."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.travels_in_succession_with

/-
  drv.interaction.following — Road user u is travelling behind road user v on the same line of travel at this observation: u and v are distinct, both occupy a common lane, v is ahead of u along that lane's direction of travel, their headings agree within the tolerance same_direction_cosine (the cosine of the largest angle between the headings that still counts as the same direction), and the longitudinal component of the surface gap from u to v is at most reach, the distance ahead within which a vehicle counts as the one being followed. The concept denotes the configuration at the observation and says nothing about how closely: the size of the gap is the caller's to read and to judge. It is not an overtaking (where the bodies draw level the longitudinal gap closes to zero and the bodies overlap along the heading, which this concept excludes by requiring a positive gap no greater than the reach), not a tow or a coupling, and not a judgement that the following is safe, lawful or deliberate.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    both occupy a common lane: atoms ['rel.occupies', 'st.lane'], concepts []
    v is ahead of u along that lane's direction of travel: atoms ['rel.ahead_behind_in_lane'], concepts []
    their headings agree within the tolerance: atoms ['rel.same_direction'], concepts []
    the longitudinal component of the surface gap from u to v: atoms ['rel.surface_gap'], concepts []

  How each element is written:
    "u and v are distinct" — `.same u v` negated; no atom reads identity.
    "both occupy a common lane" — some region of kind lane (the kind of the quantifier, `st.lane`)
      whose footprint both bodies overlap (`rel_occupies` of each formal). The lane is no formal of
      this concept, so the body finds it: the contract asks only that one exist (narrowing 1).
    "v is ahead of u along that lane's direction of travel" — `rel_ahead_in_lane v u`, the accessor
      of `rel.ahead_behind_in_lane` read with v as the body ahead.
    "their headings agree within the tolerance" — `rel_same_direction u v` with the formal
      parameter same_direction_cosine as its cosine tolerance.
    "the longitudinal component of the surface gap from u to v is at most reach", read with the
      exclusion the contract states ("requiring a positive gap no greater than the reach") — the
      longitudinal component of `rel.surface_gap` from u to v, strictly above zero and at most the
      formal parameter reach (narrowing 2).

  No magnitude below is this file's own: parameters are formals the caller fills; the only literal
  is zero, the bound the contract's "positive" names.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aV : Arg := .var "v"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSameDirectionCosine : Term := .param "same_direction_cosine"
def pReach : Term := .param "reach"

/-- The longitudinal component of the surface gap from u to v. -/
def gapLongitudinal : Term := .measure "rel_surface_gap" [aU, aV, .lit "longitudinal"]

/-- The lane both bodies occupy, as the quantifier variable the body binds. -/
def aLane : Arg := .var "lane"

def body : Formula :=
  .and (.not (.same aU aV))
    (.existsRegion (.lit "lane") "lane"
      (.and (.atom "rel_occupies" [aU, aLane] [])
        (.and (.atom "rel_occupies" [aV, aLane] [])
          (.and (.atom "rel_ahead_in_lane" [aV, aU] [])
            (.and (.atom "rel_same_direction" [aU, aV] [pSameDirectionCosine])
              (.and (.cmp gapLongitudinal .gt (.lit Q.zero .metre))
                    (.cmp gapLongitudinal .le pReach)))))))

def concept : Concept :=
  { id := "drv.interaction.following"
    contract := "Road user u is travelling behind road user v on the same line of travel at this observation: u and v are distinct, both occupy a common lane, v is ahead of u along that lane's direction of travel, their headings agree within the tolerance same_direction_cosine (the cosine of the largest angle between the headings that still counts as the same direction), and the longitudinal component of the surface gap from u to v is at most reach, the distance ahead within which a vehicle counts as the one being followed. The concept denotes the configuration at the observation and says nothing about how closely: the size of the gap is the caller's to read and to judge. It is not an overtaking (where the bodies draw level the longitudinal gap closes to zero and the bodies overlap along the heading, which this concept excludes by requiring a positive gap no greater than the reach), not a tow or a coupling, and not a judgement that the following is safe, lawful or deliberate."
    definition := none
    args := [("u", .track), ("v", .track)]
    params := [⟨"same_direction_cosine", .ratio⟩, ⟨"reach", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "both occupy a common lane"
          why := "The lane is no formal of this concept, so the body quantifies over the lanes of \
                  the scene and asks that one of them be occupied by both footprints: the common \
                  lane is read as existence of such a lane, not as a lane the caller singles out."
          kind := "reading" }
      , { span := "requiring a positive gap no greater than the reach"
          why := "Positive is read of the longitudinal component the contract measures, not of the \
                  gap's length: the component is strictly above zero and at most reach, so bodies \
                  drawn level or overlapping along the heading (the gap's longitudinal component \
                  zero) are excluded, as the contract excludes an overtaking."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following

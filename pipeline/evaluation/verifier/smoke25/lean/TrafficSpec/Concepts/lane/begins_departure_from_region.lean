/-
  drv.lane.begins_departure_from_region — The road user's body begins to leave the given region at this observation: its footprint overlapped the region at the previous observation, and at this observation it overlaps a travel region other than the region that it did not overlap at the previous observation, whether or not its footprint still overlaps the region. A travel region other than the region is any travel region of the scene that is not it, whether or not it shares ground with it. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the single observation at which the body, having been on the region, first reaches travel ground outside it, as a footprint and a boundary observe it, and nothing more: it is not a turn indicator or an arm signal, not an intention or a preparation to leave, not the direction in which the body goes or the region it goes into (which region, and on which side of the body it lies, is the caller's to state), not a turn and not a lane change as a manoeuvre, and not a judgement that the movement is lawful or safe. It is an event at one observation and not a state that lasts while the body straddles two regions: at the later observations of the same movement the other region is no longer newly overlapped, so the concept does not hold again, and a body that has left the region satisfies it again only by overlapping the region once more and reaching another travel region anew. Ceasing to overlap the region is not by itself a departure, however the overlap changes: a body that sways within its region without reaching another travel region, and one whose region simply ends ahead of it while it reaches no other travel region, do not satisfy it. No magnitude is left open: an overlap of footprint and boundary is observed or it is not, and where the source does not observe a footprint's overlap with a region, or whether a region is a travel region, the concept is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlapped the region at the previous observation: atoms ['rel.occupies'], concepts []
    it overlaps a travel region other than the region that it did not overlap at the previous observation: atoms ['rel.occupies', 'st.travel_region'], concepts []

  How the first element is written. `rel.occupies`, "a road user's footprint overlaps a lane /
  region", is read of the caller's road user and the caller's region: `rel_occupies [u, r]`. The
  element is that overlap at the observation BEFORE this one, which the formula language states with
  its rise operator alone: `rises φ` is φ here and not at the previous observation, so the value of
  φ at the previous observation is `(φ ∧ ¬rises φ) ∨ rises (¬φ)` — the overlap holds here and has not
  just risen, or its negation has just risen. No window, no magnitude and no region of the concept's
  own enters. At the first observation of a trace there is no previous observation: `rises` is
  truncated there, so the element — and the concept — is unknown at it, which is what the contract's
  last sentence requires of an unobserved overlap.

  How the second element is written. `st.travel_region` is the ontology's abstract kind and is read
  only by a quantifier, as its contract requires: `existsRegion (.lit "travel_region") "q"` ranges
  over every lane, bicycle lane or path, roadway, shoulder and intersection of the trace, and over
  every region whose membership of one of those kinds the source cannot tell, which the quantifier
  conjoins as unknown — so a region whose kind cannot be told leaves the element unknown rather than
  false, and a sidewalk, a crosswalk or a stop line is never ranged over. Otherness is the identity
  of the region, not disjointness from it, as the contract says in its own words ("whether or not it
  shares ground with it"): it is `¬ same q r`. The newness of the overlap is the rise of that
  overlap at this observation: `rises (rel_occupies [u, q])` is the overlap of this road user's
  footprint with `q` here and not at the previous observation. Nothing of the region `r` is read at
  this observation, so the element holds "whether or not its footprint still overlaps the region",
  and nothing of direction, of a signal or of a manoeuvre is read.

  The body is the conjunction of the two elements at this observation, and so denotes an event at
  one observation: at the later observations of the same movement the other region is no longer
  newly overlapped and the second conjunct fails; a body that sways within its region, and one whose
  region simply ends ahead of it, reach no newly overlapped travel region and fail it too.

  Narrowings. Two, declared below: the rise-operator form of "at the previous observation" (with its
  unknown at the first observation of a trace), and the pair of readings the second element's words
  leave open — otherness as identity, and the quantifier over the kind rather than any condition on
  the region `r` at this observation.

  No magnitude below is this file's own: the concept takes no parameter, and no literal but the
  enumeration spelling of the quantifier's kind appears.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.begins_departure_from_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The region the body binds: a travel region of the scene other than the caller's region. -/
def aQ : Arg := .var "q"

/-- The caller's road user's footprint overlaps the caller's region. -/
def occupiesRegion : Formula := .atom "rel_occupies" [aU, aR] []

/-- The caller's road user's footprint overlaps the bound travel region. -/
def occupiesOther : Formula := .atom "rel_occupies" [aU, aQ] []

/-- Its footprint overlapped the region at the previous observation: the overlap holds here and has
    not just risen, or its negation has just risen. Unknown at the first observation of a trace,
    where there is no previous observation. -/
def overlappedRegionBefore : Formula :=
  .or (.and occupiesRegion (.not (.rises occupiesRegion)))
      (.rises (.not occupiesRegion))

/-- At this observation it overlaps a travel region other than the region that it did not overlap at
    the previous observation. -/
def reachesOtherTravelRegion : Formula :=
  .existsRegion (.lit "travel_region") "q"
    (.and (.not (.same aQ aR)) (.rises occupiesOther))

/-- The body begins to leave the region at this observation. -/
def body : Formula := .and overlappedRegionBefore reachesOtherTravelRegion

def concept : Concept :=
  { id := "drv.lane.begins_departure_from_region"
    contract := "The road user's body begins to leave the given region at this observation: its footprint overlapped the region at the previous observation, and at this observation it overlaps a travel region other than the region that it did not overlap at the previous observation, whether or not its footprint still overlaps the region. A travel region other than the region is any travel region of the scene that is not it, whether or not it shares ground with it. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the single observation at which the body, having been on the region, first reaches travel ground outside it, as a footprint and a boundary observe it, and nothing more: it is not a turn indicator or an arm signal, not an intention or a preparation to leave, not the direction in which the body goes or the region it goes into (which region, and on which side of the body it lies, is the caller's to state), not a turn and not a lane change as a manoeuvre, and not a judgement that the movement is lawful or safe. It is an event at one observation and not a state that lasts while the body straddles two regions: at the later observations of the same movement the other region is no longer newly overlapped, so the concept does not hold again, and a body that has left the region satisfies it again only by overlapping the region once more and reaching another travel region anew. Ceasing to overlap the region is not by itself a departure, however the overlap changes: a body that sways within its region without reaching another travel region, and one whose region simply ends ahead of it while it reaches no other travel region, do not satisfy it. No magnitude is left open: an overlap of footprint and boundary is observed or it is not, and where the source does not observe a footprint's overlap with a region, or whether a region is a travel region, the concept is unknown."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlapped the region at the previous observation"
          why := "written with the rise operator alone, as the value of the overlap at the previous observation: the overlap holds here and has not just risen, or its negation has just risen ((φ ∧ ¬rises φ) ∨ rises (¬φ)); no window and no magnitude enters, and at the first observation of a trace, where there is no previous observation, the rise is truncated, so the element and the concept are unknown there rather than decided"
          kind := "reading" }
      , { span := "it overlaps a travel region other than the region that it did not overlap at the previous observation"
          why := "otherness is written as the identity of the region (`¬ same q r`) and not as disjointness from it, which the contract's own words require; the travel region is read only by the quantifier's kind, so a region whose membership of that kind the source cannot tell leaves the element unknown rather than false; and the newness of the overlap is the rise of that overlap at this observation, with nothing of the region `r` read at this observation, so the element holds whether or not the footprint still overlaps the region"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.begins_departure_from_region

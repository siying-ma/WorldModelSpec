/-
  drv.road.on_curve — The road user is upon a bend in the road at the observation: its footprint overlaps a roadway, and the horizontal curvature of that roadway at the road user's place is at least the magnitude the caller sets. The magnitude is the observer's: a surveyed or mapped alignment is never exactly straight, so it names the curvature below which the road counts as a tangent, and it is no measure of how sharp a bend must be to matter, which is the business of the law that calls the concept. Curvature is a magnitude and has no hand: a bend to either hand satisfies the concept alike, and a road user travelling either way along the same bend satisfies it alike. The concept is a configuration of the scene at an instant, read from the road's own geometry and the road user's membership of it: it says nothing about how long the road user has been upon the bend, nothing about the direction it travels, and nothing about its speed. It is not the road user's own turning — a body yaws on a straight road whenever it manoeuvres, and a body may hold a bend with no yaw of its own on a sampled heading — not the longitudinal slope of the road or a crest of its profile, and it says nothing about the view the bend affords or about whether the bend can be taken safely.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps a roadway: atoms ['rel.occupies', 'st.roadway'], concepts []
    the horizontal curvature of that roadway at the road user's place: atoms ['st.curvature'], concepts []

  How each element is written:

    "its footprint overlaps a roadway" — an existential over the scene's roadway regions, `r`,
    read as a roadway by its own atom (`st_roadway`, of the bound region, so a region whose kind
    the source cannot tell leaves the conjunct unknown rather than silently true), with the road
    user's membership of it read through `rel_occupies` of the formal `u` and that same region.
    `rel_occupies` is the anchoring relation: it is what makes the roadway the road user's own
    road and not any roadway of the scene, and it is what ties the bound variable to the formal.

    "the horizontal curvature of that roadway at the road user's place" — `st_curvature` of the
    very region bound above, compared `.ge` against the formal parameter
    `curve_curvature_tolerance`. One region is bound once and read three ways — its kind, the
    overlap, its curvature — which is what "that roadway" demands: a bend of some other roadway
    of the scene can never satisfy the concept, because the curvature read is the curvature of
    the region the footprint overlaps.

  No hand, no body motion, no duration. `st_curvature` is already a magnitude (the accessor takes
  the absolute value of the mapped figure), so no `abs` is written around it and a bend to either
  hand, taken in either direction, satisfies the concept alike. Nothing of the road user's own
  turning (`kin.yaw_rate`), of its heading, of its speed, of the road's grade or crest, of sight
  distance, and no look-back operator is written: the contract excludes them all, and no such atom
  is read. The whole body is evaluated at the instant.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.on_curve

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCurveCurvatureTolerance : Term := .param "curve_curvature_tolerance"

/-- The roadway the road user is upon, bound inside the body and anchored to the formal `u` by
    `rel_occupies`. -/
def aRoadway : Arg := .var "r"

/-- The bound region is a roadway: the improved part of a highway, read by its own atom of the
    bound region. -/
def isRoadway : Formula :=
  .atom "st_roadway" [aRoadway] []

/-- The road user's footprint overlaps that roadway. -/
def footprintOverlaps : Formula :=
  .atom "rel_occupies" [aU, aRoadway] []

/-- The horizontal curvature of that roadway — the magnitude, as the atom carries it — is at least
    the tolerance the caller sets. -/
def bendsThere : Formula :=
  .cmp (.measure "st_curvature" [aRoadway]) .ge pCurveCurvatureTolerance

/-- The road user is upon a bend in the road: some roadway its footprint overlaps bends there by
    at least the caller's magnitude. -/
def body : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and isRoadway (.and footprintOverlaps bendsThere))

def concept : Concept :=
  { id := "drv.road.on_curve"
    contract := "The road user is upon a bend in the road at the observation: its footprint overlaps a roadway, and the horizontal curvature of that roadway at the road user's place is at least the magnitude the caller sets. The magnitude is the observer's: a surveyed or mapped alignment is never exactly straight, so it names the curvature below which the road counts as a tangent, and it is no measure of how sharp a bend must be to matter, which is the business of the law that calls the concept. Curvature is a magnitude and has no hand: a bend to either hand satisfies the concept alike, and a road user travelling either way along the same bend satisfies it alike. The concept is a configuration of the scene at an instant, read from the road's own geometry and the road user's membership of it: it says nothing about how long the road user has been upon the bend, nothing about the direction it travels, and nothing about its speed. It is not the road user's own turning — a body yaws on a straight road whenever it manoeuvres, and a body may hold a bend with no yaw of its own on a sampled heading — not the longitudinal slope of the road or a crest of its profile, and it says nothing about the view the bend affords or about whether the bend can be taken safely."
    definition := none
    args := [("u", .track)]
    params := [⟨"curve_curvature_tolerance", .perMetre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlaps a roadway, and the horizontal curvature of that roadway at the road user's place"
          why := "Written as a single existential over the scene's roadway regions: one region is bound once and read three ways — its kind by st_roadway, the overlap by rel_occupies of the formal and that region, its curvature by st_curvature of that region. 'That roadway' is therefore the very region the footprint overlaps, and the curvature of any other roadway of the scene can never satisfy the concept. The indefinite article is read existentially: where a footprint overlaps several roadways at once (a junction of two mapped roadways, a footprint straddling a segmentation boundary), it is enough that one of them bends by the caller's magnitude. The kind is read of the bound region by its own atom rather than left to the quantifier, so a region whose kind the source cannot tell leaves the conjunct unknown rather than silently true."
          kind := "reading" }
      , { span := "the horizontal curvature of that roadway at the road user's place"
          why := "The ontology carries horizontal curvature as one figure per roadway region, so 'at the road user's place' is read as the curvature the source carries for the region the footprint overlaps: the region is the unit of alignment the source segments, and a source that resolves curvature more finely along a bend says so by segmenting the roadway into more regions, each of which the overlap can pick out. No interpolation between regions and no curvature along the road user's own path is written — neither has an atom, and neither is needed: the concept reads the road's own geometry at the place the road user is."
          kind := "reading" }
      , { span := "is at least the magnitude the caller sets"
          why := "Written `.ge`, inclusive: a curvature exactly at the tolerance counts as bending rather than as a tangent, which is what 'at least' says. No absolute value is written around the atom, because st.curvature is already a magnitude and never negative — that is why a bend to either hand satisfies the concept alike, and why nothing in the body distinguishes the direction the road user travels along the bend."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.road.on_curve

/-
  drv.position.approaching_intersection — The road user is approaching the given intersection at this observation: it is on a stretch of road that leads into that junction and has not reached it. It holds where the road user's footprint overlaps a travel region whose entrance end the source records as that intersection, and the road user's own footprint does not overlap the intersection. It is entry topology and not motion: it holds whatever the road user's speed or heading — moving forward, at rest, or backing — and it is not a distance to the junction, not the direction the road user comes from, not which device or mark governs the stretch, and not any claim that the road user will arrive.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's footprint overlaps a travel region: atoms ['rel.occupies', 'st.travel_region'], concepts []
    whose entrance end the source records as that intersection: atoms ['st.lane_enters', 'st.intersection'], concepts []
    the road user's own footprint does not overlap the intersection: atoms ['rel.occupies', 'st.intersection'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the elements are written:
    * "the road user's footprint overlaps a travel region" — an existential over the scene's travel
      regions (`st_travel_region`, the quantifier's kind; the abstract kind only a quantifier or a
      formula reads), conjoined with `rel_occupies u r`: some carrier whose footprint the road user
      overlaps.
    * "whose entrance end the source records as that intersection" — `st_lane_enters r j`, the
      source's record that carrier `r` runs into junction `j` at its entrance end. Nothing of the
      road user's speed, heading, distance or governing device enters the body.
    * "the road user's own footprint does not overlap the intersection" — `not (rel_occupies u j)`,
      the same occupancy relation read on the junction region.
    * `j` is the formal `i`: the formal's being an intersection (`st.intersection`) is read by a
      quantifier over the scene's intersections pinned to the formal with `same`, because no
      Boolean atom reads a region's kind off a variable — a kind is read by a quantifier only
      (`Semantics.boolAtomNames` has no `st_intersection`). The quantifier therefore does not
      replace the argument: `same (.var "j") aI` keeps the body about the intersection the caller
      names, and every reading of the junction below is a reading of `i`. This is the narrowing
      declared on the span "whose entrance end the source records as that intersection".

  The body is entry topology throughout: at rest, moving forward or backing all decide alike, and
  an unobserved `st.lane_enters` leaves it unknown rather than false.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.approaching_intersection

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aI : Arg := .var "i"

/-- The road user occupies some travel region the source records as entering `j`. -/
def onApproachTo (j : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [aU, .var "r"] [])
          (.atom "st_lane_enters" [.var "r", j] []))

/-- The given intersection, read as a region of kind `intersection` identified with the formal. -/
def body : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and (.same (.var "j") aI)
          (.and (.not (.atom "rel_occupies" [aU, .var "j"] []))
                (onApproachTo (.var "j"))))

def concept : Concept :=
  { id := "drv.position.approaching_intersection"
    contract := "The road user is approaching the given intersection at this observation: it is on a stretch of road that leads into that junction and has not reached it. It holds where the road user's footprint overlaps a travel region whose entrance end the source records as that intersection, and the road user's own footprint does not overlap the intersection. It is entry topology and not motion: it holds whatever the road user's speed or heading — moving forward, at rest, or backing — and it is not a distance to the junction, not the direction the road user comes from, not which device or mark governs the stretch, and not any claim that the road user will arrive."
    definition := none
    args := [("u", .track), ("i", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "whose entrance end the source records as that intersection"
          why := "the formal `i` is read as a region of kind st.intersection through a quantifier over the scene's intersections pinned to the formal with `same`: no Boolean atom reads a region's kind off a variable, so a kind is read by a quantifier only. The quantifier does not stand in for the argument — `same` keeps every reading of the junction a reading of `i`."
          kind := "reading" }
      , { span := "the road user's footprint overlaps a travel region"
          why := "read as some travel region of the scene (an existential over the abstract kind), since the contract names no particular carrier and the junction's own region is excluded by the entrance relation rather than by the quantifier."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.position.approaching_intersection

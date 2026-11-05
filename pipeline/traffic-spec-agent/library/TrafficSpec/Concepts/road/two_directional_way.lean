/-
  drv.road.two_directional_way — The given way is one on which travel is designated in both directions and that no structure divides: "an undivided highway upon which vehicles are allowed to proceed in opposite directions". The way is the region the caller singles out and passes in. It holds at this observation where no median or dividing section lies on that way, and two travel regions lying on that way carry designated directions of travel that are opposed within the opposition tolerance. The tolerance is the cosine of the largest angle off exactly opposed still read as opposite directions, a ratio, and is the concept's own magnitude, a designated direction being recorded only within a bound the caller sets. It is unknown where what lies on the way, or the designated direction of a region lying on it, is not observed. The concept denotes the configuration of the way only: it is not the presence of any road user on it, not the number of its lanes or roadways, not which hand of it a road user keeps, not any junction the way meets, and not the lawfulness of travelling on it.

  The contract is the definition `DEF-NRS-484B-073`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    no median or dividing section lies on that way: atoms ['st.median_or_divider', 'st.on_way'], concepts []
      written `.not (.existsRegion (.lit "median_or_divider") "d" (.atom "st_on_way" [.var "d", aW]))`:
      st.median_or_divider is the 'physical barrier or dividing section between roadways', and Core
      reads a region kind only as the kind of a quantifier (`regionIsKind` conjoins membership of
      the kind with the quantifier's body), so 'median or dividing section' is the kind the
      quantifier ranges over and 'lies on that way' is st.on_way, the 'relation: the public way (a
      `highway` region) a structure region lies on … a median or any other part of it', read of
      that region against the formal `w` — the way the caller singles out, read as an argument and
      never quantified over. The contract's 'no' is the negation of the existential: the way is
      undivided exactly where no such region lies on it. Where the source does not observe what
      lies on the way, st.on_way is unknown (`absentAtom`), so the existential, its negation and
      the concept are unknown, as the contract states; st.on_way is read and not nearness to the
      way (st.region_geometry), which the atom's contract excludes as a stand-in.
    two travel regions lying on that way carry designated directions of travel that are opposed within the opposition tolerance: atoms ['st.travel_region', 'st.on_way'], concepts ['drv.road.opposed_approach_directions']
      written as two nested region quantifiers of kind `travel_region`, each region tied to the way
      by `.atom "st_on_way" [·, aW]`, the two required distinct by `.not (.same aA aB)`, and their
      directions' opposition delegated whole to
      `.derived "drv_road_opposed_approach_directions" [aA, aB] [pOppositionTolerance]`:
      st.travel_region is 'Abstract. the union of the kinds a device can govern … a lane and the
      kinds that refine it, a bicycle lane or path, a roadway and the kinds that refine it, a
      shoulder, or an intersection' and 'only a quantifier or a formula reads it', which is how the
      body reads it; st.on_way ties each to the way. The co-proposed concept is the whole of
      'carry designated directions of travel that are opposed within the opposition tolerance': it
      reads st.lane_direction of the two regions passed in, normalised, and holds where the sum of
      the products of the components is below the negative of the tolerance, and it is unknown
      where either region carries no designated direction — the contract's own unknown. This
      concept's formal parameter is passed through unchanged, so no magnitude is this file's.
      Nothing else is read: no road user on the way and no occupancy (rel.occupies), no count of
      its lanes or roadways (st.lane_adjacency_count), no hand a road user keeps, no junction the
      way meets (st.lane_enters, st.intersection) and no rule — each of these the contract
      excludes by name.

  Narrowings (choices the contract did not dictate):
    "no median or dividing section lies on that way" — written as the negated existential over the
      kind, not as a universal over the way's regions: the quantifier ranges over the regions of
      that kind alone, so a way with no such region at all is decidedly undivided, and a way one
      such region lies on is decidedly divided.
    "two travel regions" — written as two region quantifiers of the abstract kind with
      `.not (.same aA aB)`: 'two' is read as two distinct regions of the scene, of any kind the
      abstract kind unites (a lane and a roadway together serve), and with no further requirement
      that they be of one kind or neighbours, which the contract does not state.
    "carry designated directions of travel that are opposed within the opposition tolerance" —
      written as the single call to `drv.road.opposed_approach_directions`, with no direction read
      here: the record names that concept for this span, its contract is the opposition of two
      given regions' designated directions within a tolerance the caller sets, and re-expressing
      the comparison here would duplicate it.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.two_directional_way

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aW : Arg := .var "w"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pOppositionTolerance : Term := .param "opposition_tolerance"

/-- A median or dividing section of the scene, bound by the body's own quantifier. -/
def aD : Arg := .var "d"

/-- One of the two travel regions, bound by the body's own quantifier. -/
def aA : Arg := .var "a"

/-- The other of the two travel regions, bound by the body's own quantifier. -/
def aB : Arg := .var "b"

/-- The given region lies on the way the caller passes in: st.on_way of that region against the
    formal `w`. Unknown where the source does not observe what lies on the way. -/
def liesOnWay (r : Arg) : Formula := .atom "st_on_way" [r, aW] []

/-- No median or dividing section lies on that way: there is no region of the dividing kind that
    lies on the way. Unknown where what lies on the way is not observed. -/
def undivided : Formula :=
  .not (.existsRegion (.lit "median_or_divider") "d" (liesOnWay aD))

/-- Two travel regions lying on that way carry designated directions of travel that are opposed
    within the opposition tolerance: two distinct regions of the abstract travel-region kind, each
    lying on the way, whose designated directions the co-proposed concept reads as opposed within
    the tolerance the caller sets. -/
def opposedPairOnWay : Formula :=
  .existsRegion (.lit "travel_region") "a"
    (.existsRegion (.lit "travel_region") "b"
      (.and (.and (liesOnWay aA) (liesOnWay aB))
        (.and (.not (.same aA aB))
          (.derived "drv_road_opposed_approach_directions" [aA, aB] [pOppositionTolerance]))))

/-- The way is two-directional: no structure divides it, and travel is designated on it in two
    opposed directions. -/
def body : Formula := .and undivided opposedPairOnWay

def concept : Concept :=
  { id := "drv.road.two_directional_way"
    contract := "The given way is one on which travel is designated in both directions and that no structure divides: \"an undivided highway upon which vehicles are allowed to proceed in opposite directions\". The way is the region the caller singles out and passes in. It holds at this observation where no median or dividing section lies on that way, and two travel regions lying on that way carry designated directions of travel that are opposed within the opposition tolerance. The tolerance is the cosine of the largest angle off exactly opposed still read as opposite directions, a ratio, and is the concept's own magnitude, a designated direction being recorded only within a bound the caller sets. It is unknown where what lies on the way, or the designated direction of a region lying on it, is not observed. The concept denotes the configuration of the way only: it is not the presence of any road user on it, not the number of its lanes or roadways, not which hand of it a road user keeps, not any junction the way meets, and not the lawfulness of travelling on it."
    definition := some "DEF-NRS-484B-073"
    args := [("w", .region)]
    params := [⟨"opposition_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "no median or dividing section lies on that way"
          why := "Written as the negated existential over the dividing kind, `.not (.existsRegion (.lit \"median_or_divider\") \"d\" (st_on_way d w))`, not as a universal over the regions of the way: Core reads a region kind only as a quantifier's kind, and the quantifier ranges over the regions of that kind alone, so a way no such region lies on is decidedly undivided and a way one lies on is decidedly divided. The relation read is st.on_way, the way a structure region lies on, and not nearness to the way, which that atom's contract excludes as a stand-in."
          kind := "reading" }
      , { span := "two travel regions"
          why := "Written as two nested region quantifiers of the abstract kind `travel_region`, the two required distinct by `.not (.same aA aB)`: 'two' is read as two distinct regions of the scene, each of any kind the abstract kind unites (a lane and a roadway together serve), with no further requirement that they be of one kind, be neighbours, or be all the travel regions of the way — the contract states none of these, and it excludes the number of the way's lanes or roadways."
          kind := "reading" }
      , { span := "carry designated directions of travel that are opposed within the opposition tolerance"
          why := "Written as the single call `.derived \"drv_road_opposed_approach_directions\" [aA, aB] [pOppositionTolerance]`, with no designated direction read in this file: the record names that concept for this span, its contract is exactly the opposition of the two given regions' designated directions within a tolerance the caller sets (read normalised, the sum of the products of the components below the negative of the tolerance), and this concept's formal parameter is passed through unchanged, so the tolerance stays the caller's figure and the comparison is not duplicated here."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.road.two_directional_way

/-
  drv.road.undivided_opposed_directions — The given way is laid out for travel in two opposed directions and is not divided: no median or dividing section lies on that way, and two travel regions lying on it carry designated directions of travel the cosine of whose angle is below the negative of opposed_direction_cosine, the cosine of the largest angle off exactly opposed at which two designated directions still count as opposite. The definition this renders is "an undivided highway upon which vehicles are allowed to proceed in opposite directions": an exactly opposite pair of directions is observed over recorded geometry only within a bound the observer sets, and opposed_direction_cosine is that bound, so no figure appears in the contract. The way is the caller's: the concept takes it as an argument and never looks for a way of its own. The concept denotes the configuration of the way as the map records it - which directions of travel it is laid out for, and whether anything divides them - and not the motion of any road user on it: a way with no road user on it is denoted all the same, a way on which every road user happens to travel one way is denoted, and a road user travelling against a designated direction neither makes the way denoted nor excludes it. It is not the presence of a centre line or of any marking: an unmarked way of two opposed directions is denoted, and the line is not read. It is not a count of lanes or of roadways, not a judgement that turning or passing across the directions is permitted, not the separateness of the roadways of a divided way, which the dividing section excludes, and not a one-way way, on which no two designated directions are opposed. Where the way's regions carry no designated direction, or a direction reads as a zero vector, the concept is unknown, as that atom's contract requires.

  The contract is the definition `DEF-NRS-484B-073`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    no median or dividing section lies on that way: atoms ['st.median_or_divider', 'st.on_way'], concepts []
    two travel regions lying on it carry designated directions of travel the cosine of whose angle is below the negative of opposed_direction_cosine: atoms ['st.travel_region', 'st.lane_direction', 'st.on_way'], concepts []

  How the first element is written. `st.median_or_divider` is read by the quantifier's kind, the way
  an abstract-or-labelled structure kind is read: `existsRegion (.lit "median_or_divider") "d"` ranges
  over every region of the trace the source records as a median or dividing section, and over every
  region whose membership of that kind the source cannot tell, which the quantifier conjoins as
  unknown. `st.on_way` ties the divider read to the caller's way: `st_on_way [d, w]` is the relation
  "the divider lies on that way", and no distance is read, so the atom's "not a stand-in for:
  nearness to a way" is respected. The conjunct is the denial of that existential: "no median or
  dividing section lies on that way".

  How the second element is written. `st.travel_region` is read only by the kinds of the two region
  quantifiers, as its contract (an abstract kind) requires: `a` and `b` range over the lanes,
  bicycle lanes or paths, roadways, shoulders and intersections of the trace, whatever kind refining
  the travel region the source records them as, and the way itself — a `highway` region — is never a
  member, since the way is the argument. Each is tied to the caller's way by `st_on_way`, so the
  pair ranged over is the travel regions lying on that way. `st.lane_direction` is read by component,
  `st_lane_direction [r, "x"]` and `st_lane_direction [r, "y"]`; a formula reads it normalised, so
  "the cosine of whose angle" is the dot product of the two directions,
  a.x·b.x + a.y·b.y, and the comparison is that product below the negative of
  `opposed_direction_cosine`. A region whose direction is unobserved, or whose direction is a zero
  vector, makes the comparison unknown, which is what the contract's last sentence requires.

  Narrowings. Two, declared below: that the pair is not required to be two distinct regions (a
  region paired with itself has cosine +1, which can never fall below the negative of a bound, so
  distinctness would change nothing), and that a way on whose record no median or dividing section
  appears reads as undivided rather than unknown (the contract reserves unknown for the designated
  directions).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.undivided_opposed_directions

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aW : Arg := .var "w"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pOpposedDirectionCosine : Term := .param "opposed_direction_cosine"

/-- The regions the body binds: a median or dividing section, and the two travel regions whose
    designated directions are compared. -/
def aD : Arg := .var "d"
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- A component of the designated direction of travel of a region, read normalised. -/
def dirX (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "x"]
def dirY (r : Arg) : Term := .measure "st_lane_direction" [r, .lit "y"]

/-- The cosine of the angle between the two designated directions: their dot product, each read
    normalised. -/
def cosine : Term :=
  .add (.mul (dirX aA) (dirX aB)) (.mul (dirY aA) (dirY aB))

/-- No median or dividing section lies on that way. -/
def undivided : Formula :=
  .not (.existsRegion (.lit "median_or_divider") "d" (.atom "st_on_way" [aD, aW] []))

/-- Two travel regions lying on the way carry designated directions of travel the cosine of whose
    angle is below the negative of `opposed_direction_cosine`. -/
def opposedDirections : Formula :=
  .existsRegion (.lit "travel_region") "a"
    (.and (.atom "st_on_way" [aA, aW] [])
      (.existsRegion (.lit "travel_region") "b"
        (.and (.atom "st_on_way" [aB, aW] [])
          (.cmp cosine .lt (.neg pOpposedDirectionCosine)))))

/-- The way is not divided and is laid out for travel in two opposed directions. -/
def body : Formula := .and undivided opposedDirections

def concept : Concept :=
  { id := "drv.road.undivided_opposed_directions"
    contract := "The given way is laid out for travel in two opposed directions and is not divided: no median or dividing section lies on that way, and two travel regions lying on it carry designated directions of travel the cosine of whose angle is below the negative of opposed_direction_cosine, the cosine of the largest angle off exactly opposed at which two designated directions still count as opposite. The definition this renders is \"an undivided highway upon which vehicles are allowed to proceed in opposite directions\": an exactly opposite pair of directions is observed over recorded geometry only within a bound the observer sets, and opposed_direction_cosine is that bound, so no figure appears in the contract. The way is the caller's: the concept takes it as an argument and never looks for a way of its own. The concept denotes the configuration of the way as the map records it - which directions of travel it is laid out for, and whether anything divides them - and not the motion of any road user on it: a way with no road user on it is denoted all the same, a way on which every road user happens to travel one way is denoted, and a road user travelling against a designated direction neither makes the way denoted nor excludes it. It is not the presence of a centre line or of any marking: an unmarked way of two opposed directions is denoted, and the line is not read. It is not a count of lanes or of roadways, not a judgement that turning or passing across the directions is permitted, not the separateness of the roadways of a divided way, which the dividing section excludes, and not a one-way way, on which no two designated directions are opposed. Where the way's regions carry no designated direction, or a direction reads as a zero vector, the concept is unknown, as that atom's contract requires."
    definition := some "DEF-NRS-484B-073"
    args := [("w", .region)]
    params := [⟨"opposed_direction_cosine", .ratio⟩]
    body := .formula body
    residues := ["the authority's allowance of travel in each direction is not observable; the concept reads the directions of travel the map designates for the travel regions lying on the way, which is the evidence of that allowance, and nothing of the allowance beyond that designation is carried."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "two travel regions lying on it carry designated directions of travel the cosine of whose angle is below the negative of opposed_direction_cosine"
          why := "written as an existential over a pair of travel regions lying on the way, with no condition that the two be distinct regions: a region paired with itself has a direction cosine of exactly +1, which can never fall below the negative of a bound, so requiring distinctness would decide nothing differently, and the cosine of the angle is the dot product of the two designated directions, which a formula reads normalised"
          kind := "reading" }
      , { span := "no median or dividing section lies on that way"
          why := "written as the denial that some region the source records as a median or dividing section lies on the way, so a way on whose record no such region appears reads as undivided, decided and not unknown; the contract reserves unknown for the designated directions, and a region whose membership of the kind the source cannot tell still leaves the conjunct unknown, as the quantifier's semantics require"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.road.undivided_opposed_directions

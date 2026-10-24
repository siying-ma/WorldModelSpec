/-
  drv.road.on_divided_highway — The road user is upon a highway that is divided: its footprint overlaps a public way on which lie two or more roadways and, between them, a physical barrier or dividing section. The contract follows the definition's words, a highway "divided into two or more roadways" by means of "a physical barrier or dividing section". It is a configuration at an instant, read from the regions of the scene and the road user's membership of them: it says nothing about which of the roadways the road user is on, nothing about the direction any of them carries, nothing about any opening or crossover in the dividing structure, and nothing about whether the structure was officially established - the structure's presence on the way is what the scene shows. A painted centre line is not a physical barrier or dividing section and does not satisfy it.

  The contract is the definition `DEF-NRS-484A-070`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps a public way: atoms ['st.highway', 'rel.occupies'], concepts []
    two or more roadways: atoms ['st.roadway', 'st.on_way'], concepts []
    between them, a physical barrier or dividing section: atoms ['st.median_or_divider', 'st.on_way'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — the definition's own figure: a highway "divided into two or more roadways"

  How each element is written:

    "its footprint overlaps a public way" — an existential over the scene's highway regions: a
    region `hw` that is a highway (`st_highway`, read of the bound region, so a region whose kind
    the source cannot tell leaves the conjunct unknown rather than silently true) whose footprint
    the road user overlaps (`rel_occupies u hw`). Everything else in the body is read of that one
    way, so the divided way is the way the road user is on.

    "two or more roadways" — two existentials over the scene's roadway regions, `ra` and `rb`,
    each read as a roadway (`st_roadway`) and each lying on that same way (`st_on_way _ hw`),
    and the declared figure 2 as the count the pair exhibits: `roadwaysFound` is two where the
    two witnesses are distinct regions and none where one region was found twice, and the body
    demands that count be more than none. Since the count takes no other value, "more than none"
    and "two or more" are the same demand, and the definition's own figure is the quantity the
    body carries. Nothing in the language counts the regions lying on a way (an aggregate ranges
    over road users), so the figure cannot stand against a measured count; it stands against the
    witnesses the formula itself finds. Nothing says which of the roadways the road user is on:
    the contract excludes that, and `rel_occupies` is read of the way alone.

    "between them, a physical barrier or dividing section" — an existential over the scene's
    median-or-divider regions: a region `md` that is one (`st_median_or_divider`) and that lies on
    the same way (`st_on_way md hw`), so a barrier standing on a neighbouring road does not divide
    this one. A painted centre line needs no conjunct of its own to be excluded: `st.centre_line`
    is a kind of its own and a region of that kind is not a `st.median_or_divider`, so the
    existential never finds it.

  Nothing about the direction of a roadway, about an opening in the dividing structure, about
  which roadway carries the road user, or about the purpose the structure was built for is
  written: the contract and the residue exclude them.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.on_divided_highway

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The public way, bound inside the body and anchored to the formal by `rel_occupies`. -/
def aWay : Arg := .var "hw"
/-- The two roadways and the dividing structure, each anchored to the way by `st_on_way`. -/
def aRoadwayA : Arg := .var "ra"
def aRoadwayB : Arg := .var "rb"
def aDivider : Arg := .var "md"

/-- Its footprint overlaps a public way. -/
def onPublicWay : Formula :=
  .and (.atom "st_highway" [aWay] [])
    (.atom "rel_occupies" [aU, aWay] [])

/-- One roadway lying on that way. -/
def roadwayA : Formula :=
  .and (.atom "st_roadway" [aRoadwayA] [])
    (.atom "st_on_way" [aRoadwayA, aWay] [])

/-- A second roadway lying on that way. -/
def roadwayB : Formula :=
  .and (.atom "st_roadway" [aRoadwayB] [])
    (.atom "st_on_way" [aRoadwayB, aWay] [])

/-- How many roadways the pair of witnesses exhibits on the way: the definition's own figure,
    two, where they are distinct regions, and none where one region was found twice. -/
def roadwaysFound : Term :=
  .cond (.same aRoadwayA aRoadwayB) (.lit Q.zero .count) (.lit (Q.ofInt 2) .count)

/-- The way carries two or more roadways: the count the pair exhibits is not none, and the only
    other value it takes is the definition's two. -/
def twoOrMoreRoadways : Formula :=
  .cmp roadwaysFound .gt (.lit Q.zero .count)

/-- Between them, a physical barrier or dividing section lying on that same way. -/
def dividingStructure : Formula :=
  .and (.atom "st_median_or_divider" [aDivider] [])
    (.atom "st_on_way" [aDivider, aWay] [])

/-- Two or more roadways on the way and, between them, a dividing structure on it. -/
def dividedInto : Formula :=
  .existsRegion (.lit "roadway") "ra"
    (.and roadwayA
      (.existsRegion (.lit "roadway") "rb"
        (.and roadwayB
          (.and twoOrMoreRoadways
            (.existsRegion (.lit "median_or_divider") "md" dividingStructure)))))

def body : Formula :=
  .existsRegion (.lit "highway") "hw" (.and onPublicWay dividedInto)

def concept : Concept :=
  { id := "drv.road.on_divided_highway"
    contract := "The road user is upon a highway that is divided: its footprint overlaps a public way on which lie two or more roadways and, between them, a physical barrier or dividing section. The contract follows the definition's words, a highway \"divided into two or more roadways\" by means of \"a physical barrier or dividing section\". It is a configuration at an instant, read from the regions of the scene and the road user's membership of them: it says nothing about which of the roadways the road user is on, nothing about the direction any of them carries, nothing about any opening or crossover in the dividing structure, and nothing about whether the structure was officially established - the structure's presence on the way is what the scene shows. A painted centre line is not a physical barrier or dividing section and does not satisfy it."
    definition := some "DEF-NRS-484A-070"
    args := [("u", .track)]
    params := []
    body := .formula body
    residues := ["the purpose for which a dividing structure was built is not observable in a scene; the definition's own evidence for it is the physical barrier or dividing section standing between the roadways, which the concept reads."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlaps a public way"
          why := "Written as an existential over the scene's highway regions: there is a region that is a highway (st.highway, read of the bound region, not assumed from the quantifier's kind) whose footprint the road user overlaps. The road user may overlap several ways; 'a public way' is read as 'some way it is on', and every other element is read of that same way, so the way that is divided is a way the road user is upon."
          kind := "reading" }
      , { span := "two or more roadways"
          why := "Written as two existentials over the scene's roadway regions, each read as a roadway and each lying on the way (st.on_way), and the definition's figure 2 as the count that pair exhibits: two where the two witnesses are distinct regions, none where one region was found twice, and the body demands more than none. The count takes no other value, so this is exactly 'two or more'. The figure cannot be compared against a measured count of the roadways of a way, because nothing in the language counts regions; it is compared against the witnesses the formula itself finds. 'Lie on' is read as the ontology's membership of a public way, not as geometric containment."
          kind := "reading" }
      , { span := "between them, a physical barrier or dividing section"
          why := "'Between them' is read as 'on the same public way as the roadways': the scene's region relations carry a structure's membership of a way (st.on_way), not the betweenness of one region and two others. The reading keeps a barrier standing on a neighbouring road from dividing this one, and does not require the structure to be shown lying geometrically between the two roadway polygons."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.road.on_divided_highway

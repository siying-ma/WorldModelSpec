/-
  drv.road.barrier_separated_way — The public way given to the concept is separated across its width by a physical dividing structure: a dividing region lies on that way, and two distinct roadway regions lie on it as well. The corpus definition this contract quotes speaks of a highway "divided into two or more roadways by means of a physical barrier or dividing section", so the two roadway regions are a floor and not a ceiling: a way carrying more of them is separated no less, and the figure is carried by the two regions the concept reads apart, not by any magnitude it measures. The way is the caller's: the concept reads the structures lying on that way and no others. Not a stand-in for: which roadway of the way a road user is on or which of them lies to its right, the direction either roadway designates, an opening or crossover in the dividing structure, a painted centre line or any other marking -- a marked division is no physical barrier -- or the width of the separation.

  The contract is the definition `DEF-NRS-484A-070`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a dividing region lies on that way: atoms ['st.median_or_divider', 'st.on_way'], concepts []
      Written as `existsRegion (.lit "median_or_divider") "d"` over the scene's dividing structures,
      with `st_on_way d w` tying the one found to the way the caller gives. The bounded quantifier
      is how a region of a kind is read: it ranges over every region of the trace whose membership
      of `median_or_divider` is not false and conjoins that membership with its body, so a region
      the source cannot place in the kind leaves the element unknown rather than false, which is
      what the atom `st.median_or_divider` says on its own. Nothing of the dividing structure is
      read but that it is one and that it lies on this way: no opening (`st.median_or_divider`'s
      other attribute), no geometry, no width, as the contract's exclusions require, and no
      distance, which `st.on_way` excludes.
    two distinct roadway regions lie on it as well: atoms ['st.roadway', 'st.on_way'], concepts []
      Written as two nested `existsRegion (.lit "roadway")` quantifiers, each roadway tied to the
      caller's way by `st_on_way`, held apart by `not (same r2 r1)`: the figure of two is carried
      by the two regions the body reads, never by a quantity, so the element declares no literal
      and the body measures nothing. Two existentials are a floor, as the contract says the
      definition's "two or more roadways" is: a way carrying three such regions satisfies them
      through any two of them. Separate roadways of a divided highway being separate regions is
      `st.roadway`'s own contract, so their identity is the whole of the distinctness the element
      asks for; nothing orders them, names a side, or reads a direction either designates.

  Readings chosen that the contract did not dictate: none — the contract's first sentence states
  the three structures to read and the relation that ties each to the way, the quoted definition
  states that the two roadways are a floor, and the exclusions state what is not read; so
  `narrowings` is empty. In particular the body tests no geometric betweenness of the dividing
  region: the contract makes the dividing structure's lying on the way the evidence (its residue
  says so in as many words), and no claimed atom reads a region's position relative to two others.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.barrier_separated_way

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aW : Arg := .var "w"

/-- A dividing structure of the scene lies on the caller's way. -/
def dividerOnWay : Formula :=
  .existsRegion (.lit "median_or_divider") "d" (.atom "st_on_way" [.var "d", aW] [])

/-- Two roadway regions, distinct as regions, lie on the caller's way. -/
def twoRoadwaysOnWay : Formula :=
  .existsRegion (.lit "roadway") "r1"
    (.and (.atom "st_on_way" [.var "r1", aW] [])
      (.existsRegion (.lit "roadway") "r2"
        (.and (.not (.same (.var "r2") (.var "r1")))
          (.atom "st_on_way" [.var "r2", aW] []))))

/-- The way is separated across its width by a physical dividing structure: a dividing region lies
    on it, and two distinct roadway regions lie on it as well. Unknown wherever the source cannot
    tell which way a structure region lies on, or cannot tell a region's kind. -/
def body : Formula := .and dividerOnWay twoRoadwaysOnWay

def concept : Concept :=
  { id := "drv.road.barrier_separated_way"
    contract := "The public way given to the concept is separated across its width by a physical dividing structure: a dividing region lies on that way, and two distinct roadway regions lie on it as well. The corpus definition this contract quotes speaks of a highway \"divided into two or more roadways by means of a physical barrier or dividing section\", so the two roadway regions are a floor and not a ceiling: a way carrying more of them is separated no less, and the figure is carried by the two regions the concept reads apart, not by any magnitude it measures. The way is the caller's: the concept reads the structures lying on that way and no others. Not a stand-in for: which roadway of the way a road user is on or which of them lies to its right, the direction either roadway designates, an opening or crossover in the dividing structure, a painted centre line or any other marking -- a marked division is no physical barrier -- or the width of the separation."
    definition := some "DEF-NRS-484A-070"
    args := [("w", .region)]
    params := []
    body := .formula body
    residues := ["the purpose the construction serves is not observed: what the scene carries is the dividing structure itself, and its presence between the roadways is the evidence the definition's words rest on. A dividing structure built for another purpose would be read as dividing the way."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.road.barrier_separated_way

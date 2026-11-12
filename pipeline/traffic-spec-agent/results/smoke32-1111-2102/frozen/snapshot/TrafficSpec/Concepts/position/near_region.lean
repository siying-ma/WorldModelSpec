/-
  drv.position.near_region — Road user a is at region r at an observation: r lies within the reach of a's body, the distance within which a region counts as the place the road user is at. Measured as the ground distance from a's body outline to r (st.region_geometry, m; zero when they overlap) at or below the reach. Not a stand-in for occupancy: a body within the reach may lie wholly outside the region.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the ground distance from a's body outline to r (st.region_geometry, m; zero when they overlap): atoms ['st.region_geometry'], concepts []

  The body: `st_region_geometry_distance a r` (the distance accessor of st.region_geometry, m) at or
  below `reach` (`.le`, the contract's "at or below"). No narrowing: the contract fixes the measure,
  the comparison and the bound. Occupancy is not read.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.near_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReach : Term := .param "reach"

/-- The ground distance from a's body outline to r (zero when they overlap) at or below the reach. -/
def body : Formula :=
  .cmp (.measure "st_region_geometry_distance" [aA, aR]) .le pReach

def concept : Concept :=
  { id := "drv.position.near_region"
    contract := "Road user a is at region r at an observation: r lies within the reach of a's body, the distance within which a region counts as the place the road user is at. Measured as the ground distance from a's body outline to r (st.region_geometry, m; zero when they overlap) at or below the reach. Not a stand-in for occupancy: a body within the reach may lie wholly outside the region."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"reach", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.position.near_region

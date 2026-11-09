/-
  drv.lane.lane_change — The road user crosses out of a structure region at the observation: its footprint overlapped the region at the observation before, and at the observation it either no longer overlaps that region or overlaps a lane neighbouring it in the same direction of travel which it did not overlap at the observation before. It is the event of that crossing, read at the observation at which it has happened, and not the state of being outside the region afterwards. Not a stand-in for: a turn, since no heading change is read, a signal or a declared intention, a movement that stays within the region however far across it, the completion of a movement into the neighbouring region, or the direction or side the crossing is made towards, which a caller reads from the regions themselves.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlapped the region at the observation before: atoms ['rel.occupies'], concepts []
    overlaps a lane neighbouring it in the same direction of travel: atoms ['rel.occupies', 'st.lane_adjacency', 'st.lane'], concepts []

  How the words are written.
  - "its footprint overlapped the region at the observation before" — `rel_occupies u r`, read at
    the observation before. The language names no past instant of its own: the one operator that
    reaches the preceding observation is `rises φ` (φ here and not at the observation before), so
    the overlap at the observation before is written through it, in the two branches the contract's
    disjunction already separates:
      * it no longer overlaps `r`: `rises (¬ occupies r)` — not overlapping here, overlapping at the
        observation before;
      * it still overlaps `r`: `occupies r ∧ ¬ rises (occupies r)` — overlapping here and not newly
        so, hence overlapping at the observation before as well.
    The disjunction of the two is the contract's `overlapped-before ∧ (¬ overlaps-now ∨ neighbour)`:
    the case `overlapped-before ∧ ¬ overlaps-now ∧ neighbour` is the first branch already.
    Declared as a narrowing on "at the observation before".
  - "overlaps a lane neighbouring it in the same direction of travel which it did not overlap at the
    observation before" — a region quantifier over `st.lane` ("a longitudinal strip of roadway for
    one line of vehicles") binds the neighbour `n`; `st_lane_adjacency r <side> n` ("left / right
    neighbouring lane of the same direction") holds it to be `r`'s neighbour of the same direction.
    The atom takes a side, and the contract reads none ("not a stand-in for … the direction or side
    the crossing is made towards"), so both sides are read disjunctively. Declared as a narrowing.
    "which it did not overlap at the observation before" is `rises (occupies n)`.
  - Nothing reads a heading, a signal, a declared intention or a lateral offset: a movement that
    stays within `r` and overlaps no neighbour decides the body false, and the body is the event at
    the observation at which the crossing has happened, not the state afterwards (`rises`, not
    `eventually`/`since`).

  No magnitude below is this file's own: parameters are formals the caller fills (there are none).
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.lane_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The neighbour the body quantifies over, a lane of the scene. -/
def aN : Arg := .var "n"

/-- The road user's footprint overlaps the region `x`. -/
def occupies (x : Arg) : Formula := .atom "rel_occupies" [aU, x] []

/-- `n` is the lane neighbouring `r` on `side`, in the same direction of travel. -/
def neighbourOn (side : String) : Formula := .atom "st_lane_adjacency" [aR, .lit side, aN] []

/-- The footprint no longer overlaps `r`, and overlapped it at the observation before. -/
def offRegion : Formula := .rises (.not (occupies aR))

/-- The footprint overlaps `r` and did so at the observation before: it overlaps it here and not
    newly here. -/
def stillOnRegion : Formula := .and (occupies aR) (.not (.rises (occupies aR)))

/-- The footprint overlaps a lane neighbouring `r` in the same direction of travel, on either
    side, which it did not overlap at the observation before. -/
def ontoNeighbour : Formula :=
  .existsRegion (.lit "lane") "n"
    (.and (.or (neighbourOn "left") (neighbourOn "right")) (.rises (occupies aN)))

/-- The crossing out of `r`, read at the observation at which it has happened. -/
def body : Formula := .or offRegion (.and stillOnRegion ontoNeighbour)

def concept : Concept :=
  { id := "drv.lane.lane_change"
    contract := "The road user crosses out of a structure region at the observation: its footprint overlapped the region at the observation before, and at the observation it either no longer overlaps that region or overlaps a lane neighbouring it in the same direction of travel which it did not overlap at the observation before. It is the event of that crossing, read at the observation at which it has happened, and not the state of being outside the region afterwards. Not a stand-in for: a turn, since no heading change is read, a signal or a declared intention, a movement that stays within the region however far across it, the completion of a movement into the neighbouring region, or the direction or side the crossing is made towards, which a caller reads from the regions themselves."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlapped the region at the observation before"
          why := "The language names no past instant of its own; `rises φ` (φ here and not at the observation before) is the only operator that reaches the preceding observation, so the overlap at the observation before is written through it, per branch of the contract's own disjunction: `rises (not occupies r)` where it no longer overlaps the region, and `occupies r and not rises (occupies r)` — overlapping here and not newly so — where it still does."
          kind := "reading" }
      , { span := "overlaps a lane neighbouring it in the same direction of travel"
          why := "st.lane_adjacency reads a side (left or right); the contract reads none, since the side the crossing is made towards is excluded, so the body holds the neighbour to be the lane adjacent on either side, disjunctively."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.lane_change

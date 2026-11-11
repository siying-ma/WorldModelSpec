/-
  drv.motion.heading_change_since_entry — The signed heading change of road user x since its footprint last began to overlap region r, in degrees, left positive: zero at the observation at which the overlap began, integrated from x's yaw rate (kin.yaw_rate) with step as the sampling step bound, not ended by x leaving r and restarted only by its next entry into r. Unknown where that entry is not observed with the overlap known at every observation since, where two consecutive observations since lie further apart than step, or where a yaw rate since the entry is missing. Not denoted: a turn manoeuvre by itself (a caller compares the change with its own bound, and a bend of the way inside the region changes it too), or the heading change over a fixed window.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint last began to overlap region r: atoms ['rel.occupies'], concepts []
    integrated from x's yaw rate (kin.yaw_rate) with step as the sampling step bound: atoms ['kin.yaw_rate'], concepts []

  How each element is written:
    "its footprint last began to overlap region r" — `rel_occupies x r`, the onset formula of the
      heading-since construct: its latest definite rise is the entry the change counts from, and its
      turning false (x leaving r) does not end the count, as the contract states.
    "integrated from x's yaw rate (kin.yaw_rate) with step as the sampling step bound" —
      `Term.headingSince "x" step …`: Core's construct integrates kin_yaw_rate of x from zero at the
      onset, with the formal parameter `step` as its sampling step bound; its unknowns (onset not
      observed with the overlap known since, a gap longer than step, a missing yaw rate) are the
      contract's.
  No choice was left open: the contract is the construct's own semantics over these two atoms.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.heading_change_since_entry

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"

/-- The heading change of x, integrated from its yaw rate, since x's footprint last began to overlap r. -/
def body : Term := .headingSince "x" pStep (.atom "rel_occupies" [aX, aR] [])

def concept : Concept :=
  { id := "drv.motion.heading_change_since_entry"
    contract := "The signed heading change of road user x since its footprint last began to overlap region r, in degrees, left positive: zero at the observation at which the overlap began, integrated from x's yaw rate (kin.yaw_rate) with step as the sampling step bound, not ended by x leaving r and restarted only by its next entry into r. Unknown where that entry is not observed with the overlap known at every observation since, where two consecutive observations since lie further apart than step, or where a yaw rate since the entry is missing. Not denoted: a turn manoeuvre by itself (a caller compares the change with its own bound, and a bend of the way inside the region changes it too), or the heading change over a fixed window."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := [⟨"step", .second⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.heading_change_since_entry

/-
  drv.position.within_clearance_since_entry — Road user x has entered structure region r and has not since stood clear of it by clearance: x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before) at the observation or at an earlier one, and at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance. It becomes true at an entry, holds while x stays on r or within clearance of it, becomes false at the first observation at which x's body stands at clearance or more from r, and stays false until x's next entry. Unknown where it is undecided whether x entered r at an observation since which the distance stayed below clearance (at x's first observation, whether it entered there is unknown), or where the distance is unobserved at an observation that decides it. Not denoted: the side of r on which the body stands (a body that backs out of r and stays within clearance of it still holds), x's direction or speed, or a halt: the caller reads those.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before): atoms ['rel.occupies'], concepts ['drv.motion.entering_region']
      written `.derived "drv_motion_entering_region" [x, r] []`, the second argument of `since`:
      the event the state is counted from, read at the observation it occurred.
    the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r): atoms ['st.region_geometry'], concepts []
      written `cmp (measure st_region_geometry_distance [x, r]) lt clearance`, the first argument
      of `since`: below clearance at every observation after the entry up to the judged one.

  The whole: `since (distance < clearance) (entering_region x r)` — the entry here, or an entry
  earlier with the distance below clearance at every later observation up to here. `since` is
  `ψ ∨ (φ ∧ since')` with the unobserved past as its head, so before any decided entry it is
  unknown unless the distance already stands at clearance or more (at x's first observation the
  entry is unknown); it turns false at the first observation at clearance or more and stays false
  until the next entry, as the contract states.

  Choice (narrowing): "at every observation from that entry up to the observation" — the distance
  is not read at the entry observation itself: there the footprint overlaps r, and the contract
  states the distance is zero while it does, so it is below clearance there by the contract's own
  words and does not decide; it is read at every later observation up to the judged one.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.within_clearance_since_entry

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pClearance : Term := .param "clearance"

/-- x entered r here: its footprint overlaps r here and did not at the observation before. -/
def entry : Formula := .derived "drv_motion_entering_region" [aX, aR] []

/-- The ground distance from x's body outline to r stands below clearance (zero on overlap). -/
def withinClearance : Formula :=
  .cmp (.measure "st_region_geometry_distance" [aX, aR]) .lt pClearance

/-- An entry here, or an earlier one since which the distance has stayed below clearance. -/
def body : Formula := .since withinClearance entry

def concept : Concept :=
  { id := "drv.position.within_clearance_since_entry"
    contract := "Road user x has entered structure region r and has not since stood clear of it by clearance: x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before) at the observation or at an earlier one, and at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance. It becomes true at an entry, holds while x stays on r or within clearance of it, becomes false at the first observation at which x's body stands at clearance or more from r, and stays false until x's next entry. Unknown where it is undecided whether x entered r at an observation since which the distance stayed below clearance (at x's first observation, whether it entered there is unknown), or where the distance is unobserved at an observation that decides it. Not denoted: the side of r on which the body stands (a body that backs out of r and stays within clearance of it still holds), x's direction or speed, or a halt: the caller reads those."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := [⟨"clearance", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance"
          why := "the distance is read at every observation after the entry up to the judged one, not at the entry itself: there the footprint overlaps r, so by the contract's own words the distance is zero and below clearance, and it does not decide"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.position.within_clearance_since_entry

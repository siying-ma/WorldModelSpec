/-
  NRS_484B_263_o2 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): about to enter or exit a controlled-access highway
    s3 (sibling): shall yield the right-of-way
    s4 (condition): to all vehicles approaching on the highway
    s5 (sibling): whose proximity constitutes an immediate hazard
    s6 (obligation): and shall continue to yield the right-of-way
    s7 (condition): to that traffic
    s8 (standard): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.controlled_access', 'rel.occupies'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'kin.speed'], derived ['drv.motion.moving']
    s6: atoms ['rel.occupies'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []

  How each is written:
    s1: the class of x, ru_aggregate x DEF-NRS-484A-320::vehicle.
    s2: applicability — some region a of kind controlled_access that x enters
        (drv_motion_entering_region x a) or leaves (drv_motion_leaving_region x a) here.
    s6: the obligation is judged at that entry or exit (the record's reading); it re-selects the
        same region (every controlled_access region x enters or leaves here) and states the duty
        for each.
    s4/s7: every road user y other than x that is a vehicle (DEF-NRS-484A-320) and a member of that
        traffic (DEF-NRS-484A-285), occupies a, is moving (drv_motion_moving, p.speed_resolution)
        and approaches x (prim_closest_approach_within x y, horizon p.immediate_hazard_gap).
    s8: rel_surface_gap x y (no component selector: the distance between the nearest points)
        ≥ kin_speed y × p.merge_time_headway.
  No choice beyond the record's: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pMergeTimeHeadway : Term := .param "p.merge_time_headway"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- The quantified variables: the controlled-access region and the other road user. -/
def vA : Arg := .var "a"
def vY : Arg := .var "y"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2 / s6: x enters or leaves region `a` at this observation (over rel.occupies). -/
def entersOrLeaves : Formula :=
  .or (.derived "drv_motion_entering_region" [vX, vA] [])
      (.derived "drv_motion_leaving_region" [vX, vA] [])

/-- s4 / s7: `y` is another vehicle of that traffic, on the controlled-access region `a`, moving,
    and approaching x (closest approach of the centres within the critical-gap horizon). -/
def approachingTraffic : Formula :=
  .and (.not (.same vY vX))
    (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_occupies" [vY, vA] [])
          (.and (.derived "drv_motion_moving" [vY] [pSpeedResolution])
            (.derived "prim_closest_approach_within" [vX, vY] [pImmediateHazardGap])))))

/-- s8: reasonable safety — the surface gap from x is at least y's speed times the merge headway. -/
def safeMargin : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, vY]) .ge
    (.mul (.measure "kin_speed" [vY]) pMergeTimeHeadway)

/-- Applicability: s2 (trigger): x enters or leaves some region of kind controlled_access. -/
def applicability : Formula :=
  .existsRegion (.lit "controlled_access") "a" entersOrLeaves

/-- Obligation: s6/s8, at every controlled-access region x enters or leaves here (the
    applicability's selection written again), every approaching vehicle of that traffic on it
    (s4/s7) is at the safe merge margin. -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "a"
    (.implies entersOrLeaves
      (.forallUser "y" (.implies approachingTraffic safeMargin)))

def rule : Rule :=
  { id := "NRS_484B_263_o2"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proceed with reasonable safety"
          concepts := ["kin.speed", "prim.closest_approach_within", "rel.surface_gap"]
          params := ["p.merge_time_headway", "p.immediate_hazard_gap"]
          convention := "Safe merge headway (two-second rule, HCM freeway merge gap acceptance): at the entry or exit, every approaching vehicle of that traffic (prim.closest_approach_within over the critical-gap horizon) is at a surface gap from x (rel.surface_gap 'distance between the nearest points of two bodies') of at least its own speed (kin.speed) times p.merge_time_headway, so the margin grows with the approaching vehicle's speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2

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
    s1: the binder class `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: some region `a` of kind controlled_access that x enters (drv_motion_entering_region x a)
        or leaves (drv_motion_leaving_region x a) at the observation — the applicability.
    s6: the obligation is judged at that entry or exit: for every controlled_access region `a`
        so selected (the applicability's selection written again) ...
    s4, s7: ... every road user y other than x (`same` excludes the subject) that is a vehicle
        (ru_aggregate y DEF-NRS-484A-320::vehicle), a member of traffic (ru_aggregate y
        DEF-NRS-484A-285::traffic), occupies a (rel_occupies y a), is moving
        (drv_motion_moving y with p.speed_resolution) and approaches x
        (prim_closest_approach_within x y with horizon p.immediate_hazard_gap) ...
    s8: ... is at rel_surface_gap x y (the distance read) of at least kin_speed y times
        p.merge_time_headway.
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

/-- Membership of a road user in an admitted aggregate (the aggregate id as the literal). -/
def vehicle (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []
def traffic (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-285::traffic"] []

/-- s2 / s6: x enters or leaves the controlled-access region `a` at this observation. -/
def entersOrLeaves (a : Arg) : Formula :=
  .or (.derived "drv_motion_entering_region" [vX, a] [])
      (.derived "drv_motion_leaving_region" [vX, a] [])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway. -/
def applicability : Formula :=
  .existsRegion (.lit "controlled_access") "a" (entersOrLeaves (.var "a"))

/-- s4 / s7: y, other than x, is a vehicle of that traffic on the highway `a`, moving, and
    approaching x within the critical-gap horizon. -/
def approaching (a : Arg) : Formula :=
  .and (.not (.same vX (.var "y")))
    (.and (vehicle (.var "y"))
      (.and (traffic (.var "y"))
        (.and (.atom "rel_occupies" [.var "y", a] [])
          (.and (.derived "drv_motion_moving" [.var "y"] [pSpeedResolution])
            (.derived "prim_closest_approach_within" [vX, .var "y"] [pImmediateHazardGap])))))

/-- s8: the surface gap from x to y is at least y's speed times the merge headway. -/
def safeMargin : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, .var "y"]) .ge
    (.mul (.measure "kin_speed" [.var "y"]) pMergeTimeHeadway)

/-- Obligation: s6 (obligation): and shall continue to yield the right-of-way; s8 (standard): until
    the driver may proceed with reasonable safety. The applicability's selection of `a` is written
    again; the duty holds at every region so selected. -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "a"
    (.implies (entersOrLeaves (.var "a"))
      (.forallUser "y" (.implies (approaching (.var "a")) safeMargin)))

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
          convention := "Safe merge headway (two-second rule, HCM freeway merge gap acceptance): at the entry or exit, every approaching vehicle of that traffic (prim.closest_approach_within over the critical-gap horizon p.immediate_hazard_gap) is at a surface gap from x (rel.surface_gap 'distance between the nearest points of two bodies') of at least its own speed (kin.speed) times p.merge_time_headway, so the margin grows with the approaching vehicle's speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2

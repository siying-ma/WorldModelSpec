/-
  LVMC_11_16_060 — LVMC-11-16-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (obligation): The prima facie speed limit is twenty-five miles per hour
    t2 (trigger): on all streets and highways
    t3 (exception): unless a different speed limit is posted as set forth in this Title

  Elements (span → atoms, derived):
    t1: atoms ['kin.speed'], derived []
    t2: atoms ['st.highway', 'rel.occupies'], derived []
    t3: atoms ['dev.speed_limit_sign', 'dev.governs', 'st.on_way', 'st.highway', 'st.roadway', 'st.lane', 'st.shoulder', 'st.bicycle_lane_or_path', 'st.intersection'], derived []

  Literals the text states (each written through its Units constructor):
    t1: 25 mph — twenty-five miles per hour

  How each span is written.

    `d` has no class elements: the section speaks of whatever road user is on the way, so the
    binder's class is `.tt` and no class atom is written.

    t2 (trigger), 'on all streets and highways': one highway region `w` — `st_highway w` — that
    the subject occupies, `rel_occupies d w`. The pair of words 'streets and highways' is the one
    atom `st.highway` (the entire public way between its boundary lines), as the element says; no
    roadway is required of the subject, so a subject on the shoulder, verge or sidewalk of the way
    is inside the trigger. `w` is the way the whole rule speaks of: t3 reads the postings of this
    same region.

    t3 (exception), 'unless a different speed limit is posted': no speed limit sign `s` posted for
    that way states a limit other than the twenty-five miles per hour t1 supplies. The exception is
    conjoined into the applicability negated, so the section engages exactly where no such posting
    is found. A sign posts a different limit when
      * it is a speed limit sign, `dev_speed_limit_sign s`;
      * its kind is not a minimum, `.not (dev_speed_limit_sign_kind s minimum)` — a minimum states
        a floor and supplies no limit in place of the prima facie maximum, while maximum,
        structure_maximum and zone each state a maximum for the place, so the kind leaf is the
        single test that the kind is not minimum and never a test that it is maximum; and
      * the value it states is not twenty-five miles per hour,
        `.not (dev_speed_limit_sign_value s = 25 mph)` — `CmpOp` has no `≠`, so inequality is the
        negation of `.eq`.
    The posting is of the way, not of the footprint the subject overlaps: the sign is tied to `w`
    by `dev_governs s g` for a travel region `g` and `st_on_way g w`, with `w` the very region t2
    binds. `dev.governs` is 'never a highway', so `g` is quantified over exactly the travel kinds
    the element names — `st.roadway`, `st.lane`, `st.shoulder`, `st.bicycle_lane_or_path`,
    `st.intersection`, one region quantifier per kind since none of these kinds refines another;
    a quantifier over a kind covers the kinds refining it, so one_way_roadway is reached through
    roadway and reserved_lane, turn_lane and centre_turn_lane through lane. No distance from a
    sign head and no position of the sign is read (`dev.position` is not claimed).

    t1 (obligation), 'The prima facie speed limit is twenty-five miles per hour': `kin_speed d` is
    not above the literal 25 mph the text states. The duty reads no region: the figure is the
    section's own and does not depend on which region of the way the subject is on, so there is no
    region selection to repeat here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_16_060

/-- The binders, as arguments (order and names are the node's). -/
def vD : Arg := .var "d"

/-- t1: the twenty-five miles per hour the text states. -/
def prima : Term := .lit (Units.mph 25) .metrePerSecond

/-- Class of `d`: the node names no class element. -/
def clsD : Formula := .tt

/-- t3: `s` is a speed limit sign whose kind is not a minimum and whose stated value is other
    than the twenty-five miles per hour this section supplies. -/
def statesDifferentLimit (s : String) : Formula :=
  .and (.atom "dev_speed_limit_sign" [.var s] [])
    (.and (.not (.atom "dev_speed_limit_sign_kind" [.var s, .lit "minimum"] []))
          (.not (.cmp (.measure "dev_speed_limit_sign_value" [.var s]) .eq prima)))

/-- t3: `s` governs a travel region of kind `kindLit` that lies on the way `w`. -/
def governsRegionOn (s w kindLit kindAtom : String) : Formula :=
  .existsRegion (.lit kindLit) "g"
    (.and (.atom kindAtom [.var "g"] [])
      (.and (.atom "dev_governs" [.var s, .var "g"] [])
            (.atom "st_on_way" [.var "g", .var w] [])))

/-- t3: `s` governs some travel region of the way `w` — the kinds `dev.governs` admits. -/
def governsWay (s w : String) : Formula :=
  .or (governsRegionOn s w "roadway" "st_roadway")
    (.or (governsRegionOn s w "lane" "st_lane")
      (.or (governsRegionOn s w "shoulder" "st_shoulder")
        (.or (governsRegionOn s w "bicycle_lane_or_path" "st_bicycle_lane_or_path")
             (governsRegionOn s w "intersection" "st_intersection"))))

/-- t3: a different speed limit is posted for the way `w`. -/
def differentLimitPosted (w : String) : Formula :=
  .existsDevice (.lit "speed_limit_sign") "s"
    (.and (statesDifferentLimit "s") (governsWay "s" w))

/-- Applicability: t2 (trigger): on all streets and highways; t3 (exception): unless a different speed limit is posted as set forth in this Title -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_highway" [.var "w"] [])
      (.and (.atom "rel_occupies" [vD, .var "w"] [])
            (.not (differentLimitPosted "w"))))

/-- Obligation: t1 (obligation): The prima facie speed limit is twenty-five miles per hour -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vD]) .le prima

def rule : Rule :=
  { id := "LVMC_11_16_060"
    laws := ["LVMC-11-16-060"]
    binders :=
      [ { name := "d", cls := clsD } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_16_060

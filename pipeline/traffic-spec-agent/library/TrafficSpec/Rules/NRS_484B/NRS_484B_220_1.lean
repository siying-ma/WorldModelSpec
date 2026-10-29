/-
  NRS_484B_220_1 — NRS-484B-220-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (trigger): Upon a highway designated and signposted for one-way traffic
    u2 (subject): a vehicle
    u3 (obligation): shall be driven only in the direction designated

  Elements (span → atoms, derived):
    u1: atoms ['st.highway', 'st.one_way_roadway', 'st.roadway', 'st.lane', 'st.shoulder', 'st.sidewalk', 'st.bicycle_lane_or_path', 'st.intersection', 'st.on_way', 'rel.occupies', 'dev.regulatory_sign', 'dev.governs'], derived []
    u2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u3: atoms ['st.highway', 'st.one_way_roadway', 'st.roadway', 'st.lane', 'st.shoulder', 'st.sidewalk', 'st.bicycle_lane_or_path', 'st.intersection', 'st.on_way', 'rel.occupies', 'dev.regulatory_sign', 'dev.governs'], derived ['drv.motion.travels_against_region_direction']

  How each span is written.

    u2 (subject): the class of `v` is the single atom `ru_aggregate` with the admitted aggregate id
      `DEF-NRS-484A-320::vehicle` as its literal argument; the classes that definition covers are
      never written here.

    u1 (trigger), 'Upon a highway': `st_highway w` of a region quantifier over the kind the
      element names, the way in its whole width between its boundary lines — never the roadway.
      'Upon' is `upon`: either `rel_occupies v w` of that highway region itself, or
      `rel_occupies v p` of a part `p` that `st_on_way p w` places on that way, the parts being the
      kinds the element names — `st_roadway` (its quantifier covering the refining
      `st_one_way_roadway`), `st_lane` (covering reserved, turn and centre turn lanes),
      `st_shoulder`, `st_sidewalk`, `st_bicycle_lane_or_path` and `st_intersection`. A source that
      records the footprint against the parts of a way rather than against the way itself therefore
      places the subject upon the way all the same.

    u1 (trigger), 'designated ... for one-way traffic': `st_one_way_roadway o` of a region lying on
      that highway (`st_on_way o w`) — the roadway on which traffic is restricted to one direction
      is the way's designation.

    u1 (trigger), 'signposted': `dev_regulatory_sign s` whose `dev_regulatory_sign_code` is
      `one_way`, read of a device quantifier over the kind the element names. Because `dev_governs`
      is never recorded of a highway, the sign is tied to the way through a region whose control the
      source does record and that `st_on_way` places on that same highway: a roadway (the
      one-way roadway among them, by refinement), a lane, a shoulder, a bicycle lane or path, or the
      intersection on it. `dev_governs` is not read as the sign's position, and never of `w`.

    u3 (obligation): the state of motion is carried by the concept, not rebuilt inline:
      `drv_motion_travels_against_region_direction v r` reads the subject's own velocity against the
      direction designated for the region `r` it is passed, with p.motion_speed_floor and
      p.direction_opposition_cosine in the concept's order; occupancy of that region the caller
      reads separately, as it does. 'shall be driven ... only in the direction designated' is
      'does not travel against the direction designated' — `.not` of the concept.

      Because a region bound in the applicability is not in scope in the obligation, the obligation
      binds the way again with the applicability's whole selection — `uponWay w`, `oneWayOn w` and
      `signposted w`, the same formulas — and states the duty at every highway so selected
      (`forallRegion` over the kind, that selection as the antecedent), which is the record's
      reading of 'a highway'.

      The duty at such a way is read twice over, as the record reads it.
      First (`againstPartDesignation`), of the parts driven upon: for every region lying on that
      highway whose extent the subject's footprint overlaps and whose kind carries a designation of
      its own — `st_roadway` (with `st_one_way_roadway` refining it), `st_lane`, `st_shoulder` and
      `st_bicycle_lane_or_path`, the kinds `st.lane_direction` names — the subject does not travel
      against the direction designated for that region. Each such region binds, so the shoulder or
      the lane driven along binds as much as the roadway, and a part of the way the subject is not
      upon binds not at all.
      Second (`alongSomeOneWayRoadway`), where the footprint overlaps no such part of that highway
      at all — the sidewalk, the junction, or the highway region alone — the direction designated
      for the way itself binds, and the way carries it through its one-way roadway: some
      `st_one_way_roadway` lying on that highway is one whose designated direction the subject does
      not travel against, so travelling along any one of them is not driving against the
      designation and compliance stays possible on a divided way or one that bends back on itself.
      The antecedent of that second limb is the negation of the first limb's selection, so exactly
      one of the two readings binds at any observation.

  Narrowing declared below, on u3, the duty's span:
    - 'for which a direction of travel is designated' is read as the kinds that carry a designation
      of their own, not as the kinds for which the source happens to declare one. So where the
      subject is upon such a part whose `st.lane_direction` is unobserved, the duty at that way is
      unknown rather than falling back to the direction the way's one-way roadway designates: the
      part driven upon is the one the record says binds, and a source that does not declare its
      designation leaves the question undecided rather than answering it with another region's
      designation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_220_1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDirectionOppositionCosine : Term := .param "p.direction_opposition_cosine"
def pMotionSpeedFloor : Term := .param "p.motion_speed_floor"

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula :=
  .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- u3: the subject travels against the direction designated for the region `r`, in the concept's
    parameter order (the motion floor, then the opposition tolerance). -/
def travelsAgainst (r : String) : Formula :=
  .derived "drv_motion_travels_against_region_direction" [vV, .var r]
    [pMotionSpeedFloor, pDirectionOppositionCosine]

/-- u1/u3: a part of kind `kind` lying on the way `w` whose extent the subject's footprint
    overlaps. The kind atom is written as the element names it; its quantifier covers the kinds that
    refine it. -/
def occupiedPartOn (kindLit kindAtom w p : String) : Formula :=
  .existsRegion (.lit kindLit) p
    (.and (.atom kindAtom [.var p] [])
      (.and (.atom "st_on_way" [.var p, .var w] [])
            (.atom "rel_occupies" [vV, .var p] [])))

/-- u1/u3 ('upon a highway'): `w` is a highway in its whole width that the subject is upon — its
    footprint overlaps that highway region itself, or any roadway, lane, shoulder, sidewalk,
    bicycle lane or path, or intersection lying on it. -/
def uponWay (w : String) : Formula :=
  .and (.atom "st_highway" [.var w] [])
    (.or (.atom "rel_occupies" [vV, .var w] [])
      (.or (occupiedPartOn "roadway" "st_roadway" w "pr")
        (.or (occupiedPartOn "lane" "st_lane" w "pl")
          (.or (occupiedPartOn "shoulder" "st_shoulder" w "ps")
            (.or (occupiedPartOn "sidewalk" "st_sidewalk" w "pk")
              (.or (occupiedPartOn "bicycle_lane_or_path" "st_bicycle_lane_or_path" w "pb")
                   (occupiedPartOn "intersection" "st_intersection" w "pi")))))))

/-- u1/u3 ('designated ... for one-way traffic'): a one-way roadway lies on the way `w`. -/
def oneWayOn (w : String) : Formula :=
  .existsRegion (.lit "one_way_roadway") "o"
    (.and (.atom "st_one_way_roadway" [.var "o"] [])
          (.atom "st_on_way" [.var "o", .var w] []))

/-- u1/u3 ('signposted'): the device `s` governs a region of kind `kind` lying on the way `w`. -/
def governedPartOn (kindLit kindAtom w s g : String) : Formula :=
  .existsRegion (.lit kindLit) g
    (.and (.atom kindAtom [.var g] [])
      (.and (.atom "st_on_way" [.var g, .var w] [])
            (.atom "dev_governs" [.var s, .var g] [])))

/-- u1/u3 ('signposted'): a regulatory sign of catalogue code one_way governs a region lying on the
    way `w` whose traffic a device may control — a roadway (the one-way roadway among them), a lane,
    a shoulder, a bicycle lane or path, or the intersection on it. -/
def signposted (w : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "s"
    (.and (.atom "dev_regulatory_sign" [.var "s"] [])
      (.and (.atom "dev_regulatory_sign_code" [.var "s", .lit "one_way"] [])
        (.or (governedPartOn "roadway" "st_roadway" w "s" "gr")
          (.or (governedPartOn "lane" "st_lane" w "s" "gl")
            (.or (governedPartOn "shoulder" "st_shoulder" w "s" "gs")
              (.or (governedPartOn "bicycle_lane_or_path" "st_bicycle_lane_or_path" w "s" "gb")
                   (governedPartOn "intersection" "st_intersection" w "s" "gi")))))))

/-- u1: the whole selection of the way — the subject upon it, designated for one-way traffic, and
    signposted. The obligation writes it again, so that it denotes the same way. -/
def designatedWay (w : String) : Formula :=
  .and (uponWay w) (.and (oneWayOn w) (signposted w))

/-- Applicability: u1 (trigger): Upon a highway designated and signposted for one-way traffic -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "w" (designatedWay "w")

/-- u3: the duty at a part of kind `kind` of the way `w` the subject is upon: it does not travel
    against the direction designated for that part. -/
def partDuty (kindLit kindAtom w q : String) : Formula :=
  .forallRegion (.lit kindLit) q
    (.implies
      (.and (.atom kindAtom [.var q] [])
        (.and (.atom "st_on_way" [.var q, .var w] [])
              (.atom "rel_occupies" [vV, .var q] [])))
      (.not (travelsAgainst q)))

/-- u3, first limb: the designation of every part of the way `w` the subject is upon that carries one
    — a roadway (a one-way roadway among them), a lane, a shoulder, a bicycle lane or path. -/
def againstPartDesignation (w : String) : Formula :=
  .and (partDuty "roadway" "st_roadway" w "ar")
    (.and (partDuty "lane" "st_lane" w "al")
      (.and (partDuty "shoulder" "st_shoulder" w "ash")
            (partDuty "bicycle_lane_or_path" "st_bicycle_lane_or_path" w "ab")))

/-- u3: the subject's footprint overlaps no part of the way `w` that carries a designation of its
    own — it is on the sidewalk, in the junction, or recorded against the highway region alone. -/
def noDesignatedPart (w : String) : Formula :=
  .not
    (.or (occupiedPartOn "roadway" "st_roadway" w "nr")
      (.or (occupiedPartOn "lane" "st_lane" w "nl")
        (.or (occupiedPartOn "shoulder" "st_shoulder" w "nsh")
             (occupiedPartOn "bicycle_lane_or_path" "st_bicycle_lane_or_path" w "nb"))))

/-- u3, second limb: the designation of the way itself, which it carries through its one-way
    roadway: some one-way roadway lying on `w` is one whose designated direction the subject does
    not travel against. -/
def alongSomeOneWayRoadway (w : String) : Formula :=
  .existsRegion (.lit "one_way_roadway") "oo"
    (.and (.atom "st_one_way_roadway" [.var "oo"] [])
      (.and (.atom "st_on_way" [.var "oo", .var w] [])
            (.not (travelsAgainst "oo"))))

/-- u3: the duty at one such way. -/
def dutyAt (w : String) : Formula :=
  .and (againstPartDesignation w)
       (.implies (noDesignatedPart w) (alongSomeOneWayRoadway w))

/-- Obligation: u3 (obligation): shall be driven only in the direction designated -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "w" (.implies (designatedWay "w") (dutyAt "w"))

def rule : Rule :=
  { id := "NRS_484B_220_1"
    laws := ["NRS-484B-220-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "u3"
          why := "'every region ... for which a direction of travel is designated' is written as the kinds that carry a designation of their own - a roadway (a one-way roadway among them), a lane, a shoulder, a bicycle lane or path - and not as the regions for which the source happens to declare one. So where the subject's footprint overlaps such a part of the way whose `st.lane_direction` is unobserved, the duty at that way is unknown, rather than the second limb taking over and binding the subject to the direction the way's one-way roadway designates: the part driven upon is the one the words make binding, and a source that does not declare its designation leaves the question undecided rather than answering it with another region's designation."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_220_1

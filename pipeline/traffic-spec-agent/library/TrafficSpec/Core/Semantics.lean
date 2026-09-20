/-
  TrafficSpec.Core.Semantics
  The meaning of a formula at an instant of a trace: one three-valued result with reasons.

  Everything a rule can say passes through `eval`. Atoms and derived concepts are dispatched by
  name to the definitions of Atoms.lean and Derived.lean; a name the tables do not know, a wrong
  arity or a literal that spells no enumeration value is `unknown (malformed …)`, never false.

  Finite-trace policy — unobserved is unknown, never compliance:
  - `holdsFor` needs its whole window observed at adequate density, else unknown;
  - `within`/`untilWithin` are true on a witness, false only when the window is covered, and
    otherwise unknown (windowTruncated);
  - the unbounded `eventually`/`until` carry the unobserved future as an unknown disjunct, and
    `always` as an unknown conjunct: on a finite trace `always φ` is false or unknown, never true.
    A rule's obligation at an instant is therefore written without `always`; the sweep over the
    instants of the trace (Rule.lean) is the "always".

  Rule composition is a callback, because the library of rules is defined above this file.
-/
import TrafficSpec.Core.Formula
import TrafficSpec.Core.Derived

namespace TrafficSpec
namespace Semantics

open Derived (DArg)

/-- Everything an evaluation needs: the trace, the reading, the bindings, and how to evaluate
    another rule's obligation (`rule id map`) at an instant under a variable map. -/
structure SemCtx where
  τ : Trace
  ρ : Reading
  β : Binding := {}
  compose : String → List (String × String) → Binding → Nat → R := fun id _ _ _ => R.u (.compositionUnknown id)

namespace SemCtx
def n (c : SemCtx) : Nat := c.τ.length
def scene (c : SemCtx) (i : Nat) : Option Scene := c.τ[i]?
def bindVar (c : SemCtx) (v : String) (x : Val) : SemCtx := { c with β := c.β.bind v x }
def dctx (c : SemCtx) : Derived.Ctx := ⟨c.τ, c.ρ⟩
end SemCtx

-- ---------------------------------------------------------------------------------------------
-- Arguments
-- ---------------------------------------------------------------------------------------------
def resolve (β : Binding) : Arg → Except UnknownReason DArg
  | .var v =>
    match β.lookup v with
    | some (.track t) => .ok (.v t)
    | some (.region r) => .ok (.v r)
    | some (.device d) => .ok (.v d)
    | none => .error (.unboundVariable v)
  | .lit s => .ok (.s s)
  | .nat k => .ok (.n k)

def resolveAll (β : Binding) (args : List Arg) : Except UnknownReason (List DArg) := args.mapM (resolve β)

private def ent (a : DArg) : Except UnknownReason Nat :=
  match a with | .v t => .ok t | .n k => .ok k | .s _ => .error (.malformed "entity expected")
private def lit (a : DArg) : Except UnknownReason String :=
  match a with | .s s => .ok s | _ => .error (.malformed "literal expected")
private def enumLit {α : Type} (ofString : String → Option α) (a : DArg) : Except UnknownReason α := do
  let s ← lit a
  match ofString s with | some v => .ok v | none => .error (.malformed s)

private def b (o : Option Bool) (name : String) : R := R.ofOption o (.absentAtom name)
private def eqEnum {α : Type} [DecidableEq α] (o : Option α) (v : α) (name : String) : R :=
  b (o.map (· == v)) name
private def q (o : Option Q) (name : String) : QR :=
  match o with | some v => .ok v | none => .error (.absentAtom name)
private def qn (o : Option Nat) (name : String) : QR :=
  match o with | some v => .ok (Q.ofInt (Int.ofNat v)) | none => .error (.absentAtom name)

private def unknownAtom (n : String) : UnknownReason := .malformed s!"atom {n}"
private def arity (n : String) : UnknownReason := .malformed s!"arity {n}"

-- ---------------------------------------------------------------------------------------------
-- Boolean atoms by name. Class atoms (`ru_*`, `st_*`, `dev_*` kinds) are dispatched through the
-- generated codecs, so the table cannot drift from ATOMS.md; attribute atoms are listed.
-- ---------------------------------------------------------------------------------------------
def evalAtomE (s : Scene) (name : String) (args : List DArg) (ps : List Q) : Except UnknownReason R := do
  match name, args with
  -- road users
  | "ru_subject", [x] => pure (b (ru_subject s (← ent x)) name)
  | "ru_rider_posture_on_seat", [x] => pure (b (ru_rider_posture_on_seat s (← ent x)) name)
  | "ru_rider_posture_standing_on_deck", [x] => pure (b (ru_rider_posture_standing_on_deck s (← ent x)) name)
  | "ru_rider_posture_holding_another_vehicle", [x] => pure (b (ru_rider_posture_holding_another_vehicle s (← ent x)) name)
  | "ru_rider_posture_stunt", [x] => pure (b (ru_rider_posture_stunt s (← ent x)) name)
  | "ru_rider_posture", [x, f] =>
    match f with
    | .s "on_seat" => pure (b (ru_rider_posture_on_seat s (← ent x)) name)
    | .s "standing_on_deck" => pure (b (ru_rider_posture_standing_on_deck s (← ent x)) name)
    | .s "holding_another_vehicle" => pure (b (ru_rider_posture_holding_another_vehicle s (← ent x)) name)
    | .s "stunt" => pure (b (ru_rider_posture_stunt s (← ent x)) name)
    | _ => .error (.malformed "posture field")
  | "ru_emergency_vehicle_kind", [x, k] => pure (eqEnum (ru_emergency_vehicle_kind s (← ent x)) (← enumLit EmergencyKind.ofString k) name)
  | "ru_official_vehicle_kind", [x, k] => pure (eqEnum (ru_official_vehicle_kind s (← ent x)) (← enumLit OfficialKind.ofString k) name)
  -- structure attributes
  | "st_road_edge_paved", [r] => pure (b (st_road_edge_paved s (← ent r)) name)
  | "st_shoulder_paved", [r] => pure (b (st_shoulder_paved s (← ent r)) name)
  | "st_median_or_divider_opening", [r] => pure (b (st_median_or_divider_opening s (← ent r)) name)
  | "st_crosswalk_marked", [r] => pure (b (st_crosswalk_marked s (← ent r)) name)
  | "st_reserved_lane_class", [r, k] => pure (eqEnum (st_reserved_lane_class s (← ent r)) (← enumLit ReservedClass.ofString k) name)
  | "st_turn_lane_side", [r, k] => pure (eqEnum (st_turn_lane_side s (← ent r)) (← enumLit TurnSide.ofString k) name)
  | "st_parking_space_designation", [r, k] => pure (eqEnum (st_parking_space_designation s (← ent r)) (← enumLit ParkingDesignation.ofString k) name)
  | "st_curb_zone_kind", [r, k] => pure (eqEnum (st_curb_zone_kind s (← ent r)) (← enumLit CurbZoneKind.ofString k) name)
  | "st_curb_zone_colour", [r, k] => pure (eqEnum (st_curb_zone_colour s (← ent r)) (← enumLit CurbColour.ofString k) name)
  | "st_obstruction_kind", [r, k] => pure (eqEnum (st_obstruction_kind s (← ent r)) (← enumLit ObstructionKind.ofString k) name)
  | "st_lane_adjacency_left", [r, r'] => pure (b ((st_lane_adjacency_left s (← ent r)).map (· == (← ent r'))) name)
  | "st_lane_adjacency_right", [r, r'] => pure (b ((st_lane_adjacency_right s (← ent r)).map (· == (← ent r'))) name)
  | "st_lane_adjacency", [r, side, r'] =>
    match side with
    | .s "left" => pure (b ((st_lane_adjacency_left s (← ent r)).map (· == (← ent r'))) name)
    | .s "right" => pure (b ((st_lane_adjacency_right s (← ent r)).map (· == (← ent r'))) name)
    | _ => .error (.malformed "side")
  | "st_lane_marking", [r, side, t] =>
    match side with
    | .s "left" => pure (eqEnum ((st_lane_marking_left s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
    | .s "right" => pure (eqEnum ((st_lane_marking_right s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
    | _ => .error (.malformed "side")
  | "st_lane_marking", [r, side, t, col] =>
    let m ← match side with
      | .s "left" => pure (st_lane_marking_left s (← ent r))
      | .s "right" => pure (st_lane_marking_right s (← ent r))
      | _ => .error (.malformed "side")
    pure (R.and (eqEnum (m.map (·.1)) (← enumLit MarkingType.ofString t) name)
                (eqEnum (m.map (·.2)) (← enumLit MarkingColour.ofString col) name))
  | "st_lane_connectivity", [r, r'] => pure (b ((st_lane_connectivity s (← ent r)).map (·.contains (← ent r'))) name)
  | "st_lane_marking_left", [r, t] => pure (eqEnum ((st_lane_marking_left s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
  | "st_lane_marking_right", [r, t] => pure (eqEnum ((st_lane_marking_right s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
  | "st_lane_marking_left", [r, t, col] =>
    pure (R.and (eqEnum ((st_lane_marking_left s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
                (eqEnum ((st_lane_marking_left s (← ent r)).map (·.2)) (← enumLit MarkingColour.ofString col) name))
  | "st_lane_marking_right", [r, t, col] =>
    pure (R.and (eqEnum ((st_lane_marking_right s (← ent r)).map (·.1)) (← enumLit MarkingType.ofString t) name)
                (eqEnum ((st_lane_marking_right s (← ent r)).map (·.2)) (← enumLit MarkingColour.ofString col) name))
  | "rel_occupies", [x, r] => pure (b (rel_occupies s (← ent x) (← ent r)) name)
  -- devices
  | "dev_traffic_signal_shows", [d, k] => pure (b (dev_traffic_signal_shows s (← ent d) (← enumLit SignalIndication.ofString k)) name)
  | "dev_traffic_signal_uncovered", [d] => pure (b (dev_traffic_signal_uncovered s (← ent d)) name)
  | "dev_pedestrian_signal_state", [d, k] => pure (eqEnum (dev_pedestrian_signal_state s (← ent d)) (← enumLit PedSignalState.ofString k) name)
  | "dev_pedestrian_signal_countdown", [d] => pure (b (dev_pedestrian_signal_countdown s (← ent d)) name)
  | "dev_lane_control_signal_state", [d, k] => pure (eqEnum (dev_lane_control_signal_state s (← ent d)) (← enumLit LaneControlState.ofString k) name)
  | "dev_speed_limit_beacon_flashing", [d] => pure (b (dev_speed_limit_beacon_flashing s (← ent d)) name)
  | "dev_crossing_warning_signal_active", [d] => pure (b (dev_crossing_warning_signal_active s (← ent d)) name)
  | "dev_speed_limit_sign_kind", [d, k] => pure (eqEnum (dev_speed_limit_sign_kind s (← ent d)) (← enumLit SpeedSignKind.ofString k) name)
  | "dev_regulatory_sign_code", [d, k] => pure (eqEnum (dev_regulatory_sign_code s (← ent d)) (← enumLit SignCode.ofString k) name)
  | "dev_zone_sign_kind", [d, k] => pure (eqEnum (dev_zone_sign_kind s (← ent d)) (← enumLit ZoneKind.ofString k) name)
  | "dev_zone_sign_end", [d] => pure (b (dev_zone_sign_end s (← ent d)) name)
  | "dev_railway_signal_or_gate_lights", [d, k] => pure (eqEnum (dev_railway_signal_or_gate_lights s (← ent d)) (← enumLit RailLights.ofString k) name)
  | "dev_railway_signal_or_gate_gate", [d, k] => pure (eqEnum (dev_railway_signal_or_gate_gate s (← ent d)) (← enumLit GateState.ofString k) name)
  | "dev_railway_signal_or_gate_bell", [d] => pure (b (dev_railway_signal_or_gate_bell s (← ent d)) name)
  | "dev_human_direction_role", [d, k] => pure (eqEnum (dev_human_direction_role s (← ent d)) (← enumLit HumanRole.ofString k) name)
  | "dev_human_direction_indication", [d, k] => pure (eqEnum (dev_human_direction_indication s (← ent d)) (← enumLit HumanIndication.ofString k) name)
  | "dev_school_bus_signal_on_track", [d, x] => pure (b ((dev_school_bus_signal_on_track s (← ent d)).map (· == (← ent x))) name)
  | "dev_school_bus_signal_red_flashing", [d] => pure (b (dev_school_bus_signal_red_flashing s (← ent d)) name)
  | "dev_school_bus_signal_amber_flashing", [d] => pure (b (dev_school_bus_signal_amber_flashing s (← ent d)) name)
  | "dev_school_bus_signal_stop_arm", [d] => pure (b (dev_school_bus_signal_stop_arm s (← ent d)) name)
  | "dev_governs", [d, r] => pure (b (dev_governs s (← ent d) (← ent r)) name)
  | "dev_inoperative", [d] => pure (b (dev_inoperative s (← ent d)) name)
  -- signals emitted
  | "sig_turn_indicator", [x, k] => pure (eqEnum (sig_turn_indicator s (← ent x)) (← enumLit TurnSide.ofString k) name)
  | "sig_brake_lamp", [x] => pure (b (sig_brake_lamp s (← ent x)) name)
  | "sig_hazard", [x] => pure (b (sig_hazard s (← ent x)) name)
  | "sig_headlamp", [x, k] => pure (eqEnum (sig_headlamp s (← ent x)) (← enumLit HeadlampState.ofString k) name)
  | "sig_position_lamp", [x] => pure (b (sig_position_lamp s (← ent x)) name)
  | "sig_reverse_lamp", [x] => pure (b (sig_reverse_lamp s (← ent x)) name)
  | "sig_warning_lamp", [x, col] => pure (b (sig_warning_lamp_colour s (← ent x) (← enumLit LampColour.ofString col)) name)
  | "sig_warning_lamp", [x, col, m] => pure (b (sig_warning_lamp_shows s (← ent x) (← enumLit LampColour.ofString col) (← enumLit LampMode.ofString m)) name)
  | "sig_signal_arm", [x] => pure (b (sig_signal_arm s (← ent x)) name)
  | "sig_siren", [x] => pure (b (sig_siren s (← ent x)) name)
  | "sig_horn", [x] => pure (b (sig_horn s (← ent x)) name)
  | "sig_hand_signal", [x, k] => pure (eqEnum (sig_hand_signal s (← ent x)) (← enumLit HandSignal.ofString k) name)
  | "sig_door_open", [x] => pure (b ((sig_door_open s (← ent x)).map (!·.isEmpty)) name)
  | "sig_door_open", [x, k] => pure (b (sig_door_open_side s (← ent x) (← enumLit DoorSide.ofString k)) name)
  | "sig_compression_brake", [x] => pure (b (sig_compression_brake s (← ent x)) name)
  -- environment
  | "env_darkness", [] => pure (b (env_darkness s) name)
  | "env_precipitation", [] => pure (b (env_precipitation s) name)
  | "env_wet_road", [] => pure (b (env_wet_road s) name)
  | "env_ice_or_snow", [] => pure (b (env_ice_or_snow s) name)
  -- relations
  | "rel_ahead_behind_in_lane", [a, a'] => pure (b (rel_ahead_behind_in_lane s (← ent a) (← ent a')) name)
  | "rel_ahead_in_lane", [a, a'] => pure (b (rel_ahead_in_lane s (← ent a) (← ent a')) name)
  | "rel_behind_in_lane", [a, a'] => pure (b (rel_behind_in_lane s (← ent a) (← ent a')) name)
  | "rel_oncoming", [a, a'] =>
    match ps with
    | [tol] => pure (b (rel_oncoming s (← ent a) (← ent a') tol) name)
    | _ => .error (.parameterMissing "rel_oncoming cosine tolerance")
  | "rel_same_direction", [a, a'] =>
    match ps with
    | [tol] => pure (b (rel_same_direction s (← ent a) (← ent a') tol) name)
    | _ => .error (.parameterMissing "rel_same_direction cosine tolerance")
  | "rel_bearing", [a, a', k] =>
    match k with
    | .s "ahead" => pure (b (rel_bearing_ahead s (← ent a) (← ent a')) name)
    | .s "behind" => pure (b (rel_bearing_behind s (← ent a) (← ent a')) name)
    | .s "left" => pure (b (rel_bearing_left s (← ent a) (← ent a')) name)
    | .s "right" => pure (b (rel_bearing_right s (← ent a) (← ent a')) name)
    | _ => .error (.malformed "bearing side")
  | "rel_contact", [a, a'] => pure (b (rel_contact s (← ent a) (← ent a')) name)
  -- class atoms through the generated codecs
  | n, [x] =>
    if n.startsWith "ru_" then
      match RoadUserClass.ofString (n.drop 3).toString with
      | some k => pure (b ((s.user (← ent x)).bind fun u =>
          if u.unobservedClasses.contains k then none else u.classes.map (·.contains k)) n)
      | none => .error (unknownAtom n)
    else if n.startsWith "st_" then
      match StructureKind.ofString (n.drop 3).toString with
      | some k => pure (b ((s.structure? (← ent x)).map (·.kind == k)) n)
      | none => .error (unknownAtom n)
    else if n.startsWith "dev_" then
      match DeviceKind.ofString (n.drop 4).toString with
      | some k => pure (b ((s.device (← ent x)).map (·.kind == k)) n)
      | none => .error (unknownAtom n)
    else .error (unknownAtom n)
  | n, _ =>
    if n.startsWith "ru_" && (RoadUserClass.ofString (n.drop 3).toString).isSome then .error (arity n)
    else if n.startsWith "st_" && (StructureKind.ofString (n.drop 3).toString).isSome then .error (arity n)
    else if n.startsWith "dev_" && (DeviceKind.ofString (n.drop 4).toString).isSome then .error (arity n)
    else if boolAtomNames.contains n then .error (arity n)
    else .error (unknownAtom n)
where
  /-- The attribute atoms of the table above (for the arity/unknown distinction and the doctor). -/
  boolAtomNames : List String := [
    "ru_subject", "ru_rider_posture_on_seat", "ru_rider_posture_standing_on_deck",
    "ru_rider_posture_holding_another_vehicle", "ru_rider_posture_stunt", "ru_emergency_vehicle_kind",
    "ru_official_vehicle_kind", "ru_rider_posture", "st_lane_adjacency", "st_lane_marking", "st_road_edge_paved", "st_shoulder_paved", "st_median_or_divider_opening",
    "st_crosswalk_marked", "st_reserved_lane_class", "st_turn_lane_side", "st_parking_space_designation",
    "st_curb_zone_kind", "st_curb_zone_colour", "st_obstruction_kind", "st_lane_adjacency_left",
    "st_lane_adjacency_right", "st_lane_connectivity", "st_lane_marking_left", "st_lane_marking_right",
    "rel_occupies", "dev_traffic_signal_shows", "dev_traffic_signal_uncovered", "dev_pedestrian_signal_state",
    "dev_pedestrian_signal_countdown", "dev_lane_control_signal_state", "dev_speed_limit_beacon_flashing",
    "dev_crossing_warning_signal_active", "dev_speed_limit_sign_kind", "dev_regulatory_sign_code",
    "dev_zone_sign_kind", "dev_zone_sign_end", "dev_railway_signal_or_gate_lights",
    "dev_railway_signal_or_gate_gate", "dev_railway_signal_or_gate_bell", "dev_human_direction_role",
    "dev_human_direction_indication", "dev_school_bus_signal_on_track", "dev_school_bus_signal_red_flashing",
    "dev_school_bus_signal_amber_flashing", "dev_school_bus_signal_stop_arm", "dev_governs", "dev_inoperative",
    "sig_turn_indicator", "sig_brake_lamp", "sig_hazard", "sig_headlamp", "sig_position_lamp",
    "sig_reverse_lamp", "sig_warning_lamp", "sig_signal_arm", "sig_siren", "sig_horn", "sig_hand_signal",
    "sig_door_open", "sig_compression_brake", "env_darkness", "env_precipitation", "env_wet_road",
    "env_ice_or_snow", "rel_ahead_behind_in_lane", "rel_ahead_in_lane", "rel_behind_in_lane", "rel_oncoming",
    "rel_same_direction", "rel_bearing", "rel_contact"]

def evalAtom (s : Scene) (name : String) (args : List DArg) (ps : List Q) : R :=
  match evalAtomE s name args ps with
  | .ok r => r
  | .error e => R.u e

-- ---------------------------------------------------------------------------------------------
-- Measured atoms by name (quantity-valued). Vector atoms take a component literal.
-- ---------------------------------------------------------------------------------------------
private def comp (v : Option Vec) (k : DArg) (name : String) : QR := do
  match k with
  | .s "x" => q (v.map (·.1)) name
  | .s "y" => q (v.map (·.2)) name
  | _ => .error (.malformed "component")

def evalMeasure (s : Scene) (name : String) (args : List DArg) : QR := do
  match name, args with
  | "kin_time", [] => .ok (Time.ofTimestamp (kin_time s))
  | "kin_position", [x, k] => comp (kin_position s (← ent x)) k name
  | "kin_heading", [x, k] => comp (kin_heading s (← ent x)) k name
  | "kin_velocity", [x, k] => comp (kin_velocity s (← ent x)) k name
  | "kin_speed", [x] => q (kin_speed s (← ent x)) name
  | "kin_accel_longitudinal", [x] => q (kin_accel_longitudinal s (← ent x)) name
  | "kin_yaw_rate", [x] => q (kin_yaw_rate s (← ent x)) name
  | "kin_extent", [x, k] =>
    let e := kin_extent s (← ent x)
    match k with   -- full extents: twice the half-extent
    | .s "length" => q (e.map fun (l, _, _) => Q.mul (Q.ofInt 2) l) name
    | .s "width" => q (e.map fun (_, w, _) => Q.mul (Q.ofInt 2) w) name
    | .s "height" => q (e.map fun (_, _, h) => Q.mul (Q.ofInt 2) h) name
    | _ => .error (.malformed "extent")
  | "kin_steer_angle", [x] => q (kin_steer_angle s (← ent x)) name
  | "kin_path_length", [x] => q (kin_path_length s (← ent x)) name
  | "ru_occupant_count", [x] => qn (ru_occupant_count s (← ent x)) name
  | "ru_rider_posture_hands_on_controls", [x] => qn (ru_rider_posture_hands_on_controls s (← ent x)) name
  | "ru_electric_bicycle_class", [x] => qn (ru_electric_bicycle_class s (← ent x)) name
  | "st_lane_direction", [r, k] => comp (st_lane_direction s (← ent r)) k name
  | "st_lane_adjacency", [r, k] =>
    match k with
    | .s "ordinal" => qn (st_lane_adjacency_ordinal s (← ent r)) name
    | .s "count" => qn (st_lane_adjacency_count s (← ent r)) name
    | _ => .error (.malformed "adjacency field")
  | "dev_position", [d, k] => comp (dev_position s (← ent d)) k name
  | "st_lane_adjacency_ordinal", [r] => qn (st_lane_adjacency_ordinal s (← ent r)) name
  | "st_lane_adjacency_count", [r] => qn (st_lane_adjacency_count s (← ent r)) name
  | "st_lane_width", [r] => q (st_lane_width s (← ent r)) name
  | "st_curvature", [r] => q (st_curvature s (← ent r)) name
  | "st_grade", [r] => q (st_grade s (← ent r)) name
  | "st_sight_distance", [r] => q (st_sight_distance s (← ent r)) name
  | "st_parking_space_angle", [r] => q (st_parking_space_angle s (← ent r)) name
  | "dev_speed_limit_sign_value", [d] => q (dev_speed_limit_sign_value s (← ent d)) name
  | "env_visibility", [] => q (env_visibility s) name
  | "env_civil_time", [k] =>
    let ct := env_civil_time s
    match k with
    | .s "minute_of_day" => qn (ct.map (·.minuteOfDay)) name
    | .s "weekday" => qn (ct.map (·.weekday)) name
    | .s "month" => qn (ct.map (·.month)) name
    | .s "day" => qn (ct.map (·.day)) name
    | .s "year" => qn (ct.map (·.year)) name
    | _ => .error (.malformed "civil time field")
  | "rel_centre_distance", [a, a'] => q (rel_centre_distance s (← ent a) (← ent a')) name
  | "rel_surface_gap", [a, a'] => q (rel_surface_gap_min s (← ent a) (← ent a')) name
  | "rel_surface_gap", [a, a', k] =>
    match k with
    | .s "longitudinal" => q (rel_surface_gap_longitudinal s (← ent a) (← ent a')) name
    | .s "lateral" => q (rel_surface_gap_lateral s (← ent a) (← ent a')) name
    | .s "min" => q (rel_surface_gap_min s (← ent a) (← ent a')) name
    | _ => .error (.malformed "gap component")
  | "rel_longitudinal_overlap", [a, a'] => q (rel_longitudinal_overlap s (← ent a) (← ent a')) name
  | "rel_bearing", [a, a', k] => comp (rel_bearing s (← ent a) (← ent a')) k name
  | n, _ => if measureNames.contains n then .error (arity n) else .error (unknownAtom n)
where
  measureNames : List String := [
    "kin_time", "kin_position", "kin_heading", "kin_velocity", "kin_speed", "kin_accel_longitudinal",
    "kin_yaw_rate", "kin_extent", "kin_steer_angle", "kin_path_length", "ru_occupant_count",
    "ru_rider_posture_hands_on_controls", "ru_electric_bicycle_class", "st_lane_direction", "st_lane_adjacency",
    "dev_position", "st_lane_adjacency_ordinal",
    "st_lane_adjacency_count", "st_lane_width", "st_curvature", "st_grade", "st_sight_distance",
    "st_parking_space_angle", "dev_speed_limit_sign_value", "env_visibility", "env_civil_time",
    "rel_centre_distance", "rel_surface_gap", "rel_longitudinal_overlap", "rel_bearing"]

/-- Whether a name is known to either table (the doctor holds this against `atomIds`). -/
def knowsAtom (n : String) : Bool :=
  let s : Scene := { t := 0 }
  let isUnknown : Except UnknownReason R → Bool
    | .error e => e == unknownAtom n
    | _ => false
  let isUnknownQ : QR → Bool
    | .error e => e == unknownAtom n
    | _ => false
  !(isUnknown (evalAtomE s n [] []) && isUnknownQ (evalMeasure s n []))

/-- The Lean name of an ATOMS.md id or attribute path (`dev.traffic_signal.shows` ↦ `dev_traffic_signal_shows`). -/
def defName (id : String) : String := id.replace "." "_"

-- ---------------------------------------------------------------------------------------------
-- Temporal helpers over instant-valued closures. `n` is the trace length.
-- ---------------------------------------------------------------------------------------------
def future (n i : Nat) : List Nat := (List.range (n - i)).map (i + ·)
def past (i : Nat) : List Nat := (List.range (i + 1)).reverse   -- i, i-1, …, 0

/-- The unobserved future as an unknown. -/
def truncated (op : String) : R := R.u (.windowTruncated op)

/-- ∀ observed j ≥ i. φ j, and the unobserved future. -/
def alwaysFrom (n i : Nat) (φ : Nat → R) : R := R.and (R.all ((future n i).map φ)) (truncated "always")
/-- ∃ observed j ≥ i. φ j, or the unobserved future. -/
def eventuallyFrom (n i : Nat) (φ : Nat → R) : R := R.or (R.any ((future n i).map φ)) (truncated "eventually")
/-- Strong until over the observed remainder, the unobserved future counted as unknown unless
    φ already failed. -/
def untilOver (idx : List Nat) (covered : Bool) (op : String) (φ ψ : Nat → R) : R :=
  let witnessed := R.any ((List.range idx.length).map fun k =>
    R.and (ψ (idx[k]?.getD 0)) (R.all ((idx.take k).map φ)))
  if covered then witnessed
  else R.or witnessed (R.and (truncated op) (R.all (idx.map φ)))
def untilFrom (n i : Nat) (φ ψ : Nat → R) : R := untilOver (future n i) false "until" φ ψ
/-- ∃ j ≤ i. ψ j ∧ ∀ k ∈ (j, i]. φ k; the trace start is observed, so no truncation term. -/
def sinceFrom (i : Nat) (φ ψ : Nat → R) : R :=
  R.any ((past i).map fun j => R.and (ψ j) (R.all (((List.range (i - j)).map (j + 1 + ·)).map φ)))

/-- Rising edges of `edge` strictly after `j` up to `i`. -/
def risingEdges (j i : Nat) (edge : Nat → R) : Except UnknownReason Nat :=
  ((List.range (i - j)).map (j + 1 + ·)).foldl (fun acc k => do
    let c ← acc
    let now := edge k
    let before := edge (k - 1)
    match now.v, before.v with
    | .u, _ => .error ((now.why.head?).getD (.malformed "count"))
    | _, .u => .error ((before.why.head?).getD (.malformed "count"))
    | .t, .f => pure (c + 1)
    | _, _ => pure c) (.ok 0)

/-- The latest j ≤ i at which `p` holds; unknown if `p` is unknown before a witness is found. -/
def latest (i : Nat) (p : Nat → R) : Except UnknownReason (Option Nat) :=
  (past i).foldl (fun acc j => do
    let a ← acc
    match a with
    | some j' => pure (some j')
    | none =>
      match (p j).v with
      | .t => pure (some j)
      | .f => pure none
      | .u => .error ((p j).why.head?.getD (.malformed "since"))) (.ok none)

/-- The first instant of the maximal run of `p` that ends at its latest true instant ≤ i: "since
    `p` became true". Unknown if `p` is unknown where the run's start would be. -/
def runStart (i : Nat) (p : Nat → R) : Except UnknownReason (Option Nat) := do
  match ← latest i p with
  | none => pure none
  | some j =>
    let rec back (k fuel : Nat) : Except UnknownReason Nat :=
      match fuel with
      | 0 => .ok k
      | fuel + 1 =>
        if k = 0 then .ok 0
        else match (p (k - 1)).v with
          | .t => back (k - 1) fuel
          | .f => .ok k
          | .u => .error ((p (k - 1)).why.head?.getD (.malformed "since"))
    pure (some (← back j (j + 1)))

-- ---------------------------------------------------------------------------------------------
-- The evaluator
-- ---------------------------------------------------------------------------------------------
private def liftQ (e : Except UnknownReason R) : R := match e with | .ok r => r | .error w => R.u w
private def qbin (f : Q → Q → Q) (a b : QR) : QR := do pure (f (← a) (← b))

/-- The window subject: needed for path windows, irrelevant for time windows. -/
def subjectFor (β : Binding) (m : Measure) (v : String) : Except UnknownReason TrackId :=
  match m with
  | .time => .ok 0
  | .path => match β.track v with | some t => .ok t | none => .error (.unboundVariable v)

mutual
  def evalT (c : SemCtx) (i : Nat) : Term → QR
    | .lit v _ => .ok v
    | .param p => match c.ρ.param p with | some v => .ok v | none => .error (.parameterMissing p)
    | .measure a args => do
      let s ← match c.scene i with | some s => .ok s | none => .error .outOfRange
      evalMeasure s a (← resolveAll c.β args)
    | .quantity concept args ps => do
      let vs ← ps.mapM (evalT c i)
      Derived.evalQ concept c.dctx i (← resolveAll c.β args) vs
    | .distanceWhile subj φ => do
      let x ← match c.β.track subj with | some t => .ok t | none => .error (.unboundVariable subj)
      Derived.drv_distance_while c.dctx i x (fun j => eval c j φ)
    | .add a b' => qbin Q.add (evalT c i a) (evalT c i b')
    | .sub a b' => qbin Q.sub (evalT c i a) (evalT c i b')
    | .mul a b' => qbin Q.mul (evalT c i a) (evalT c i b')
    | .div a b' => do
      let d ← evalT c i b'
      if Q.isZero d then .error (.divisionByZero "div") else pure (Q.div (← evalT c i a) d)
    | .neg a => (evalT c i a).map Q.neg
    | .abs a => (evalT c i a).map Q.abs

  def eval (c : SemCtx) (i : Nat) : Formula → R
    | .tt => R.t
    | .ff => R.f
    | .atom name args ps => liftQ do
      let s ← match c.scene i with | some s => .ok s | none => .error .outOfRange
      let vs ← ps.mapM (evalT c i)
      pure (evalAtom s name (← resolveAll c.β args) vs)
    | .cmp l op r => liftQ do pure (R.ofBool (op.apply (← evalT c i l) (← evalT c i r)))
    | .asm id => liftQ do
      let s ← match c.scene i with | some s => .ok s | none => .error .outOfRange
      pure (R.ofOption (s.assumption id) (.assumptionMissing id))
    | .not φ => R.not (eval c i φ)
    | .and φ ψ => R.and (eval c i φ) (eval c i ψ)
    | .or φ ψ => R.or (eval c i φ) (eval c i ψ)
    | .implies φ ψ => R.implies (eval c i φ) (eval c i ψ)
    | .always φ => alwaysFrom c.n i (fun j => eval c j φ)
    | .eventually φ => eventuallyFrom c.n i (fun j => eval c j φ)
    | .until φ ψ => untilFrom c.n i (fun j => eval c j φ) (fun j => eval c j ψ)
    | .since φ ψ => sinceFrom i (fun j => eval c j φ) (fun j => eval c j ψ)
    | .holdsFor m d subj φ => liftQ do
      let x ← subjectFor c.β m subj
      let dv ← evalT c i d
      pure (Derived.overWindow (Derived.window m "holdsFor" c.τ x i dv) (fun j => eval c j φ))
    | .within m d subj φ => liftQ do
      let x ← subjectFor c.β m subj
      let dv ← evalT c i d
      match Derived.windowFwd m "within" c.τ x i dv with
      | .error e => pure (R.u e)
      | .ok (idx, covered) =>
        let any := R.any (idx.map fun j => eval c j φ)
        pure (if covered then any else R.or any (truncated "within"))
    | .untilWithin m d subj φ ψ => liftQ do
      let x ← subjectFor c.β m subj
      let dv ← evalT c i d
      match Derived.windowFwd m "untilWithin" c.τ x i dv with
      | .error e => pure (R.u e)
      | .ok (idx, covered) => pure (untilOver idx covered "untilWithin" (fun j => eval c j φ) (fun j => eval c j ψ))
    | .count edge sinceφ op k => liftQ do
      let j ← match runStart i (fun j => eval c j sinceφ) with
        | .ok (some j) => .ok j
        | .ok none => .error (.windowTruncated "count")
        | .error e => .error e
      let m ← risingEdges j i (fun j => eval c j edge)
      pure (R.ofBool (op.apply (Q.ofInt (Int.ofNat m)) (Q.ofInt (Int.ofNat k))))
    | .derived concept args ps => liftQ do
      let vs ← ps.mapM (evalT c i)
      pure (Derived.evalB concept c.dctx i (← resolveAll c.β args) vs)
    | .rule id map => c.compose id map c.β i
    | .existsRegion k v φ =>
      match c.scene i with
      | none => R.u .outOfRange
      | some s => R.any ((regionsOfKind s k).map fun r => eval (c.bindVar v (.region r)) i φ)
    | .forallRegion k v φ =>
      match c.scene i with
      | none => R.u .outOfRange
      | some s => R.all ((regionsOfKind s k).map fun r => eval (c.bindVar v (.region r)) i φ)
    | .existsDevice k v φ =>
      match c.scene i with
      | none => R.u .outOfRange
      | some s => R.any ((devicesOfKind s k).map fun d => eval (c.bindVar v (.device d)) i φ)
    | .forallDevice k v φ =>
      match c.scene i with
      | none => R.u .outOfRange
      | some s => R.all ((devicesOfKind s k).map fun d => eval (c.bindVar v (.device d)) i φ)
end

/-- The verdict value alone. -/
def evalTri (c : SemCtx) (i : Nat) (φ : Formula) : Tri := (eval c i φ).v

-- ---------------------------------------------------------------------------------------------
-- Unfolding lemmas: the connectives mean exactly the three-valued operations of Unknown.lean.
-- A reviewer reads these instead of the evaluator.
-- ---------------------------------------------------------------------------------------------
section Lemmas
variable (c : SemCtx) (i : Nat) (φ ψ : Formula)

theorem eval_tt : eval c i .tt = R.t := by rw [eval]
theorem eval_ff : eval c i .ff = R.f := by rw [eval]
theorem eval_not : eval c i (.not φ) = R.not (eval c i φ) := by rw [eval]
theorem eval_and : eval c i (.and φ ψ) = R.and (eval c i φ) (eval c i ψ) := by rw [eval]
theorem eval_or : eval c i (.or φ ψ) = R.or (eval c i φ) (eval c i ψ) := by rw [eval]
theorem eval_implies : eval c i (.implies φ ψ) = R.implies (eval c i φ) (eval c i ψ) := by rw [eval]
theorem eval_always : eval c i (.always φ) = alwaysFrom c.n i (fun j => eval c j φ) := by rw [eval]
theorem eval_eventually : eval c i (.eventually φ) = eventuallyFrom c.n i (fun j => eval c j φ) := by rw [eval]
theorem eval_until : eval c i (.until φ ψ) = untilFrom c.n i (fun j => eval c j φ) (fun j => eval c j ψ) := by rw [eval]
theorem eval_since : eval c i (.since φ ψ) = sinceFrom i (fun j => eval c j φ) (fun j => eval c j ψ) := by rw [eval]
theorem eval_rule (id : String) (map : List (String × String)) :
    eval c i (.rule id map) = c.compose id map c.β i := by rw [eval]

/-- Unknown is absorbing for `not`. -/
theorem eval_not_u (h : (eval c i φ).v = .u) : (eval c i (.not φ)).v = .u := by
  rw [eval_not, R.not_v, h]; rfl
/-- A false conjunct decides a conjunction whatever the other side. -/
theorem eval_and_f_left (h : (eval c i φ).v = .f) : (eval c i (.and φ ψ)).v = .f := by
  rw [eval_and, R.and_v, h]; rfl
/-- Unobserved is unknown: on a finite trace `always φ` is never true. -/
theorem eval_always_ne_t : (eval c i (.always φ)).v ≠ .t := by
  rw [eval_always]
  simp only [alwaysFrom, R.and_v, truncated, R.u]
  cases (R.all (List.map (fun j => eval c j φ) (future c.n i))).v <;> decide
end Lemmas

end Semantics
end TrafficSpec

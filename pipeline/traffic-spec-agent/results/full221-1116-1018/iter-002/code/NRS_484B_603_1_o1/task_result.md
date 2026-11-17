# NRS_484B_603_1_o1 — task result

**Final verdict: OK** (12 witnesses, 29 names, composes nothing; 2 coder narrowings). Used 4 of 6 gate runs.

## Gate runs
1. **GATE_TIMEOUT** (stack overflow, twice). The stopping distance was written as 2a·v·T + v² ≤ 2a·L with
   a = `Term.cond` (ice ? wet/precip ? dry), which put four copies of a two-level `cond` into every
   comparison. That is probably what the evaluator could not handle. Changed: `twiceDecel` is now one `cond`
   that selects among the parameter sums (2·a_ice, 2·a_wet, 2·a_dry), and D = v·T + v²/twiceDecel. The divisor
   is a selection among reading parameters, so it reads no measured atom.
2. **CHECK_FAIL** (units: m²·s⁻¹ compared with m). The crest "ahead" test compared (crest − position)·velocity
   with a zero in metres. Rewritten as Δx·vx > −(Δy·vy), so both sides have the same unit.
3. **VACUOUS**: 10 applicability leaves were never the deciding one (occupying an intersection; the curve's
   occupancy; crest ahead; lane/on_way for narrow; winding occupancy; pedestrian-roadway occupancy; traffic
   aggregate and closest-approach distance; visibility-roadway occupancy). Added witnesses where each of these
   is the only trigger:
   - `branch_4`: crossing a large intersection in fog
   - `branch_5`: divided highway, where the other carriageway bends, has the longer sight distance and a
     pedestrian on it (expects not applicable)
   - `branch_6`: narrow 2.8 m lane
   - `branch_7`: crest 115 m ahead
   - `branch_8`: bicycle conflict

   `branch_1` now has no lanes, so the bend is its only trigger. The long scenes (14 instants 1 s apart, judged
   over 0–2 s) keep the 150 m curve window covered, so that condition is decided.
4. **OK**.

## Choices the node left open
- **s4 (narrowing declared):** the "sight distance at the subject's place" is read from every roadway the
  subject occupies (`forallRegion roadway … rel_occupies → D ≤ st_sight_distance`). The same roadway is used
  for the curvature (the s6 element states this) and for visibility < sight in s11.
- **s9 (narrowing declared):** for "a pedestrian occupies a roadway", I used the roadway the subject occupies.
  The pedestrian quantifier has to be tied to the subject (anchoring rule 3b), and this roadway is the only
  claimed tie.
- **s6:** "approaching and going around a curve" is written as a single `within .path p.curve_approach_reach`
  window over "the roadway the subject occupies has curvature > p.curvature_resolution". The window ahead
  includes the judged observation (`withinAll` aggregates from i), so it covers both going around and
  approaching.
- **s7:** for "ahead of its velocity", the crest's reference point (`st_region_geometry` x/y) minus the
  subject's position, dotted with its velocity, must be > 0.
- **s4:** a = ice/snow → p.following_decel_ice; else wet or precipitation → wet; else dry. The obligation is:
  - D ≤ sight distance of each occupied roadway
  - D ≤ visibility
  - where curvature > p.curvature_resolution, v²·κ ≤ p.curve_lateral_accel_max
  - D ≤ surface gap to every traffic road user (not the subject) in predicted conflict
- **s12:** obstruction ground distance ≤ D; or a temporary-traffic-control device governs a travel region the
  subject occupies.

## Note on the record
The s8 "winding" limb (curvature at the subject's roadway) is implied by the s6 limb, because the curve window
includes the current observation. Because of that overlap, the s8 limb's occupancy leaf only moves a witness
when the two use different roadways (`branch_5`, divided highway). This is not a defect, only redundancy in
the applicability.

## Why I finished
The gate returned OK.

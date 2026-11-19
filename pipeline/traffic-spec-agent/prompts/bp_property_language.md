# Property language

A property's `antecedent` is a formula in the JSON of the rule formula language (the output of
`Rule.toJson`), restricted to the constructs below. It is true exactly in the situations the
property constrains. `binders` names the road users the property is about; the first is the
subject, the road user whose conduct the law judges.

Constructs:
- connectives: `{"and": [f, g]}`, `{"or": [f, g]}`, `{"not": f}`, `{"implies": [f, g]}`;
- quantifiers over regions and devices name the kind they range over:
  `{"exists_region": {"lit": "<kind>"}, "var": "x", "body": f}`, and likewise `forall_region`,
  `exists_device`, `forall_device`;
- quantifiers over road users name only the variable: `{"exists_user": "y", "body": f}` and
  `{"forall_user": "y", "body": f}`;
- variable names (a binder's `name`, a quantifier's variable) are a lower-case letter followed by at most
  eleven lower-case letters, digits or underscores (`^[a-z][a-z0-9_]{0,11}$`);
- atoms: `{"atom": "<atom>", "args": [...], "params": []}`, with the atom names and argument orders of
  the table of atoms; an argument is `{"var": "x"}` or `{"lit": "<value>"}`;
- comparisons: `{"cmp": "lt|le|gt|ge|eq", "lhs": t, "rhs": t}` between terms;
- terms: a measure `{"measure": "<measure>", "args": [...]}`; a literal `{"lit": {"num": n, "den": d}, "unit": "<unit>"}`;
  or arithmetic over terms: `{"add": [t, t]}`, `{"sub": [t, t]}`, `{"mul": [t, t]}`, `{"neg": t}`, `{"abs": t}`.

Units. A measure has the unit of the table of atoms (a unit `1` has no dimension); a literal has its unit, one of
`metre`, `second`, `metre_per_second`, `metre_per_second_sq`, `degree`, `degree_per_second`, `per_metre`, `ratio`,
`count` (`ratio` and `count` have no dimension). `add` and `sub` join two terms of one unit; `mul` gives the product
unit (a speed times a duration is a distance; a velocity times a direction, whose unit is `1`, is a speed); `neg` and
`abs` keep the unit; the two sides of a comparison have one unit. A mismatch is refused, naming the term.

Directions and motions. A measure read by an `x` or `y` component is a vector in one frame. `st_lane_direction`,
`kin_heading`, `kin_velocity`, `kin_position`, `dev_position` and `st_region_geometry` are in the world frame.
`rel_bearing(a, b, k)` is in the frame of the road user `a`: `x` is how far `b` lies ahead of `a` along `a`'s
heading, `y` how far to its left. A world-frame coordinate, direction or component is never read alone: a side of
a comparison reads world-frame components only through a term whose value does not depend on how the world frame
is turned, nor, for positions, on where its origin lies. Such terms are the dot product of two vectors, the z of
their cross product, a squared magnitude, a difference of two positions inside one of these, and sums, products,
`neg` and `abs` of them. A side that reads a world-frame component through any other term is refused ("a
coordinate, direction or vector component is fixed"), whatever it is compared with, 0 included. So a motion is
compared with a direction by its dot product (positive: with it; negative: against it) and by the z of their cross
product (0: parallel to it; parallel is exact, there is no tolerance). A component in a road user's frame does not
change when the world frame turns, so it may be read alone (`rel_bearing(a, b, "x")` above 0: `b` is ahead of
`a`). One side never reads components of two frames: a world-frame component together with a component in a road
user's frame, or components in the frames of two road users, are refused ("components of different frames").

Constants. A literal is either 0, as a whole side of a comparison (the base of a comparison: a speed above 0), or a
figure the law's quoted words state: the figure's number and its unit word, converted exactly to the literal's unit
(15 miles per hour is `{"num": 41910, "den": 6250}` in `metre_per_second`). This holds inside arithmetic too: a
literal inside a term is a stated figure and never 0 (2 seconds times a speed, compared with 100 feet); arithmetic
over literals alone is refused, as a whole side or inside one (a figure is written as the law states it: not
`15 mph + 25 mph`, `neg 15 mph` or `25 mph - 15 mph`), and some side of a comparison reads a measure.

Example: the subject `v` moves against the designated direction of the region `r` it occupies (the dot product of
its velocity and the direction below 0) and parallel to it (the z of their cross product 0):

```json
{"and": [
  {"cmp": "lt", "lhs": {"add": [
     {"mul": [{"measure": "kin_velocity", "args": [{"var": "v"}, {"lit": "x"}]}, {"measure": "st_lane_direction", "args": [{"var": "r"}, {"lit": "x"}]}]},
     {"mul": [{"measure": "kin_velocity", "args": [{"var": "v"}, {"lit": "y"}]}, {"measure": "st_lane_direction", "args": [{"var": "r"}, {"lit": "y"}]}]}]},
   "rhs": {"lit": {"num": 0, "den": 1}, "unit": "metre_per_second"}},
  {"cmp": "eq", "lhs": {"sub": [
     {"mul": [{"measure": "kin_velocity", "args": [{"var": "v"}, {"lit": "x"}]}, {"measure": "st_lane_direction", "args": [{"var": "r"}, {"lit": "y"}]}]},
     {"mul": [{"measure": "kin_velocity", "args": [{"var": "v"}, {"lit": "y"}]}, {"measure": "st_lane_direction", "args": [{"var": "r"}, {"lit": "x"}]}]}]},
   "rhs": {"lit": {"num": 0, "den": 1}, "unit": "metre_per_second"}}]}
```

Not allowed in a property: a reading parameter (`{"param": ...}`); a figure the law does not state; a
coordinate, direction or vector component in the world frame read alone (compared with a figure, 0, or another term); division
(`div`), a conditional term (`cond`) or an aggregate; a temporal operator (the check covers instantaneous
situations only); a concept call. A property that needs any of these cannot be checked
and is reported as such.

The three-valued reading: a property constrains a situation only when its binder class and
antecedent evaluate to true under Core's three-valued semantics. An unknown antecedent imposes no
verdict requirement and cannot be used to demand a verdict. Where the binder class and the
antecedent are true and the law's verdict is unknown, the check reports the property undetermined:
neither a pass nor a violation of the property.

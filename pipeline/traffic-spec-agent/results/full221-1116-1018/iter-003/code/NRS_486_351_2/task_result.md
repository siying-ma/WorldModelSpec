# NRS_486_351_2 — task result

**Final verdict: OK** (8 witnesses, 5 names, composes nothing)

## Gate runs
1. An accidental invocation of the gate command with its output discarded (`| head -0`) while the
   rule was still a skeleton; the verdict was not seen. It was not the exact command form required
   and is reported here for that reason. Before it, a stray `echo skip` was also run in the shell
   by mistake; it read and changed nothing.
2. `WITNESS_FAIL` — the rule was written, the witnesses were still empty skeletons (subject track
   not in any scene). The rule itself passed build/check stages. Wrote all eight witnesses.
3. `OK`.

## How the rule is written
- Binder class / applicability (s2): `ru_aggregate` of the subject under DEF-NRS-486-041::motorcycle,
  DEF-NRS-486-038::moped or DEF-NRS-486-057::trimobile (disjunction). The applicability is the
  record's: the subject is of one of the three.
- Obligation (s3): for every region of kind `lane` L and every road user v, if v is not the subject,
  v is of DEF-NRS-484A-320::vehicle, both occupy L (`rel_occupies`) and
  `rel_longitudinal_overlap(subject, v) >= 0 m`, then the pair is excused. Judged at each
  observation (no temporal operator; the evaluator judges each instant).
- Excuse (s4–s6): subject and v each motorcycle-or-moped (s4); `rel_same_direction(subject, v)` with
  `p.side_by_side_same_direction_cos` (s5); and (s6) the count of road users w that are the subject
  or are of the vehicle aggregate, occupy L and overlap the subject at or above zero is `<= 2`, the
  text's literal "two" (count). This is the record's "no third road user w beside the subject in L",
  stated with the declared literal.

## Choices the node left open
- s6 written as a count against the literal two rather than a "no third user" existential;
  equivalent on every scene where v qualifies, and it carries the declared literal. No narrowing
  declared (the reading is the record's).

## Witnesses
Lane L is region 100, 200 m × 4 m running east; three instants 1 s apart. forbid: car westbound
overlaps the motorcycle by 2 m at t = 1 s (opposed headings). permit: car 14 m gap ahead, same way.
idle: bicycle subject. blind: two motorcycles side by side, `ru.aggregate` masked. branch_1: two
motorcycles abreast and aligned (compliant); branch_2: three abreast (violated); branch_3: alone
(compliant); branch_4: two motorcycles meet head-on (violated).

## Why I finished
The gate returned OK.

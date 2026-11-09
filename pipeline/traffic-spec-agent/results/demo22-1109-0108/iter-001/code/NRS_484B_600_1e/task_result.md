# NRS_484B_600_1e — coding session result

## Final verdict

`OK` — "5 witnesses, 3 names, composes nothing" (gate run 1 of a budget of 6; 5 runs unused).

## Gate runs

| run | command | verdict | what changed after it |
|---|---|---|---|
| 1 | `python -m harness gate --run_id demo22-1109-0108 --node_id NRS_484B_600_1e` | `OK` | nothing — the files were written in one pass and accepted |

## The rule

- **Binder class (s1).** `clsV := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []` —
  the admitted aggregate id as the literal argument, never the classes under it.
- **Applicability (s1, agency read through conduct).**
  `.not (.derived "drv_motion_standstill" [v] [.param "p.standstill_speed_tolerance"])` — the
  vehicle is in motion at the observation, which is how the node reads "to drive or operate".
  s2 ("In any event,") is the node's residue and contributes no conjunct: the duty is the same
  whether or not those words hold.
- **Obligation (s3).** `.cmp (.measure "kin_speed" [v]) .le (.lit (Units.mph 80) .metrePerSecond)`
  — the magnitude of velocity against the figure the statute itself states, written through the
  `Units.mph` constructor of the node's declared literal.
- `laws`, `binders`, `assumptions`, `intentions`, `operationalizations`, `residues`, `surrogate`
  are the skeleton's, untouched. `narrowings := []`.

## Choices the node left open

1. **Direction of the speed comparison.** The text forbids "a rate of speed greater than 80 miles
   per hour"; the node's `obligation` field states the duty as "does not exceed the figure". Written
   as `kin.speed ≤ 80 mph`, so exactly the stated figure complies and anything above it violates.
   This is the node's own wording, not a narrowing.
2. **Where the motion reading sits.** The node's `applicability` text puts the vehicle's motion
   there and its `obligation` text carries only the speed cap, so `drv.motion.standstill` (negated)
   is the whole applicability and the cap is the whole obligation. No narrowing is declared: the
   agency reading on s1 is the plan's own `observable_reading` narrowing, already on its record, and
   restating it is forbidden.
3. **Witness geometry (mine, not the reading's).** One straight 20 m highway strip running east;
   the subject is a 4.6 m motor vehicle on it. Speeds break or keep the bounds by clear margins
   against the run's values (80 mph = 35.76 m/s; `p.standstill_speed_tolerance` = 0.1 m/s): 95 mph
   for `forbid`, 65 mph for `permit` and `blind`, 0 m/s in a parking bay with the engine running
   and the parking brake set for `idle`.
4. **One added branch witness.** `branch_1` (not_applicable): the same fast run, but the body
   carries only `bicycle`, a class the admitted aggregate `DEF-NRS-484A-320::vehicle` does not
   include, so `ru_aggregate` is decidedly false and the binder class fails. Without it the class
   leaf is true in every planned scene and does no work in any decided witness; the four planned
   scenes move only the motion concept and the speed comparison. No fact is made false that a
   source would leave unobserved — the user's classes are observed and simply do not include a
   covered class.

## The node

I found nothing wrong with the node. Its two elements map the words they quote: `ru.aggregate` with
the resolved definition id carries "a vehicle of any kind or character", `drv.motion.standstill`
read negated carries "to drive or operate" as the ontology's agency reading directs, and `kin.speed`
against the stated literal carries "a rate of speed greater than 80 miles per hour". s2 is correctly
a residue with `scope: none`. The single parameter `p.standstill_speed_tolerance` is the tolerance
the standstill contract requires of its caller, and it is the only magnitude the rule names.

## Why I finished

The gate returned `OK` on the first run: the rule builds, passes `Rule.check`, claims and uses
exactly the node's three names with no bare literal beyond the statute's own figure, and all five
witnesses reach their expected verdicts (`violated`, `compliant`, `not_applicable`, `unknown` with
`kin.speed` absent, and the added `not_applicable` branch), with every leaf of the formula moving a
decided witness. There is nothing further to repair and no reason to spend more of the budget.

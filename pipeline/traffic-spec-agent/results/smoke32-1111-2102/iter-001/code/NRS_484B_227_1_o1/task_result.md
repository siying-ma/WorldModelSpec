# NRS_484B_227_1_o1 — task result

**Final verdict: OK** (7 witnesses, 9 names, composes nothing)

## Gate runs
1. **VACUOUS**: the d7/d8 exception leaves were also inside the obligation's highway selection (`selected h` = trigger ∧ ¬exception). Since the applicability already excludes those observations, they changed no witness there. **Fix:** the obligation now selects h through the trigger only (`onDividedHighway h`). The exception stays in the applicability, which matches the record ("Not judged at an observation at which …").
2. **OK**.

## The rule
- class: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- applicability: ∃ highway h such that ego occupies a roadway r with `st_on_way r h`, some median/divider lies on h, and it is not the case that (ego occupies a median/divider on h with `st_median_or_divider_opening`, or ego occupies an intersection on h).
- obligation: ∀ highway h that ego is on as a divided highway (the trigger selection written again), ∀ median/divider m on h, `prim_region_lateral_offset ego m > 0`.

## Choices the node left open
- **Where the exception goes.** It is placed in the applicability only, not repeated in the obligation's selection of h, because the record makes it a condition on the observation. One limit: if ego were on two divided highways at once and only one of them were excepted, the obligation would still check the excepted one. That cannot happen with any geometry the witnesses build.
- **"upon" in d2.** The d2 justification also mentions occupying a median. I followed the record's `applicability` field instead, which requires ego to occupy a roadway of h. Driving within the dividing section is sibling span d5, which belongs to another node.
- **d7 and d8.** "Opening" (d7) and "crossover" (d8) are written as one leaf, a median with its opening attribute set, because the record maps both that way.
- No narrowings were declared. The plan's agency and status readings are not restated.

## Witnesses
- forbid, permit, idle, blind, branch_1: as planned.
- Added **branch_2** (not_applicable): ego is on the left-hand roadway inside an intersection lying on h (the d8 intersection limb).
- Added **branch_3** (violated): the same scene as branch_1, but the median has no opening. Ego's reference point is inside the median, so the offset is zero and the rule is violated. This exercises the opening leaf.

## Why I finished
The gate returned OK on the second run.

# Feedback from iteration 2

`NRS_484B_253_o2`: revised by a repair session; coded again this iteration
concept `drv.motion.right_turn_from_onset`: re-proposed by a repair session
concept `drv.interaction.overtakes`: re-proposed by a repair session
`NRS-484B-307-9a` names ['NRS-484B-307-9b'], not yet accepted; not planned this iteration, no attempt counted
concept `drv.motion.right_turn_from_onset`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.right_turn_from_onset`: accepted; the review's notes are recorded on it — an upheld challenge is met by this body under the current contract; it stays an obligation: challenge e3e3cf726a85 (t=750 ms), rechecked: the current contract: holds; the body: holds; With turn_angle = 0 deg, an observed onset following observed non-turning states was tested: the body holds at the onset, agreeing with the contract.; A new rightward stretch following an earlier stretch that accumulated the turn angle was tested: the body fails at the new onset, agreeing that the earlier stretch's heading change is not part of the …
concept `drv.interaction.overtakes`: gate OK — 3 witnesses, 2 names, reads 3 atom(s)
concept `drv.interaction.overtakes`: accepted; the review's notes are recorded on it — an upheld challenge is met by this body under the current contract; it stays an obligation: challenge 235cf35823c8 (t=1000 ms), rechecked: the current contract: fails; the body: fails
`LVMC_11_30_030` proposed `p.rest_speed_tolerance` = 0.1 m/s: Stop-detection noise floor: the speed at or below which a sampled speed counts as no movement, set at the resolution of 
`LVMC_11_30_030` proposed `p.crosswalk_reach` = 5.0 m: Reach within which a road user counts as at a crossing: a vehicle halted for a crosswalk stands within the stop-line set
`LVMC_11_30_030` proposed `p.same_direction_tolerance` = 0.866 ratio: Cosine of the largest angle between two headings counted as the same direction of travel (thirty degrees), covering lane
`NRS_484B_250_1` proposed `p.opposite_direction_tolerance` = 0.866 ratio: Cosine of the largest angle off exactly opposed at which two approach directions still count as opposite (thirty degrees
`NRS_484B_413_2`: gate OK — 7 witnesses, 8 names, composes nothing
`LVMC_11_30_030`: gate OK — 13 witnesses, 6 names, composes nothing
`NRS_484B_253_o2`: gate OK — 12 witnesses, 12 names, composes NRS_484B_253_o1
`NRS_484B_250_1`: gate OK — 13 witnesses, 16 names, composes NRS_484B_250_4_o1,NRS_484B_250_4_o2
dependency context changed and rechecked: `drv.motion.right_turn_from_onset`
dependency context changed and rechecked: `drv.interaction.overtakes`
`NRS-484B-253` span f10 composes accepted `NRS_484B_253_o1` (as: compliance)
`NRS-484B-250-1` span e6 composes accepted `NRS_484B_250_4_o1` (as: unless)
`NRS-484B-250-1` span e6 composes accepted `NRS_484B_250_4_o2` (as: unless)

## Laws by state

- blocked: 4
- planned: 10
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 0): `NRS_484B_307_9a_o1` composes or calls `NRS_484B_307_9b_o1` (missing), `NRS_484B_307_9b_o2` (missing), `NRS_484B_307_9b_o3` (missing), `NRS_484B_307_9b_o4` (missing), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted

## Concepts by state

- accepted: 14

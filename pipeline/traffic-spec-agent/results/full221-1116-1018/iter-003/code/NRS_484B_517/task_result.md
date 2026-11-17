# NRS_484B_517 — task result

**Final verdict: OK** (15 witnesses, 24 names, composes nothing, 2 coder narrowings).

## Gate runs
1. **VACUOUS**: three leaves of the interference limb never moved a decided witness:
   `rel_occupies wb z`, `st_region_geometry_distance wb z ≤ p.zone_entry_wait_reach` and
   `drv_motion_complete_halt wb`. The witnesses were missing, not the formula. I added
   `branch_11`: the permit halt with three motor vehicles whose bus/taxicab membership the reading
   leaves unresolved. One is at rest inside the zone, one is at rest 37.7 m beyond it, and one
   creeps away and leaves the 10 m reach without entering. In each case a single leaf is what
   keeps the interference limb false.
2. **OK**.

## Rule
- Subject class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Applicability: some curb zone z that the subject occupies is either a bus_stop while the subject
  is decidedly not a bus, or a taxicab_stand while it is decidedly not a taxicab
  (`st_curb_zone_kind`).
- Obligation: for every curb zone z with the same selection (re-bound, rule 3c), the subject must
  not be halted (`drv_motion_complete_halt`), unless one of these holds:
  - (a) a road user ahead in the same lane is within `p.queue_halt_gap` (body surface gap);
  - (b) a travel region the subject occupies is governed by a stop sign, a yield sign, a red or
    yellow signal, an active railway signal or gate, or a police officer signalling stop;
  - (c) the subject is a passenger vehicle (vehicle, not a truck, not a trailer or combination)
    that is not parked for `p.standing_min_duration`, has a door open at some observation of the
    same halt (`since`/`until` over the halt), and no bus or taxicab interfered at any point of
    the halt so far. Interfering means being outside z, within `p.zone_entry_wait_reach` of it,
    and either halted there or staying outside within reach until it occupies z (strong until).

## Choices the node left open (declared as narrowings on s1)
- **Signal colours:** "a red or yellow indication" is read as the steady red and yellow
  indications, circular and arrow, plus the record's flashing_red. flashing_yellow and
  flashing_yellow_arrow are excluded.
- **Railway gate:** "gate not up" is read as a gate that is lowering, down or raising. The state
  `none` (the device has no gate) is not treated as a gate that is not up.

## Observations for the plan (not defects that stopped the session)
- Under the run's reading, `DEF-NRS-484A-030::bus` and `DEF-NRS-484A-270::taxicab` include no
  class.
  - **Interference limb (s13):** a road user can never be decidedly a bus or a taxicab, so this
    limb is only ever false or unknown. It can never make a halt a violation.
  - **taxicab_stand limb (s5):** every vehicle class sits in the taxicab aggregate's unresolved
    list, so this limb can never decide the rule applies. It is only false or unknown.
- That is why the witnesses use a taxicab-class subject in a bus stop. Bus membership is
  decidedly false for it, and its taxicab membership is never needed.

## Why I finished
The gate returned OK on the second run.

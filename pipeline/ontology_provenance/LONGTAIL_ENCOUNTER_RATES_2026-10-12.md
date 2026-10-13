# Long-tail encounter-rate research (2026-10-12)

Two unit conventions are used throughout:
- **Per 1,000 VMT.** For Las Vegas, the denominator is the Las Vegas–Henderson urbanized area, 45,606 thousand daily VMT in 2023 [R1].
- **Per 100 h.** The per-1,000-VMT rate × 2.659, i.e. 26.59 mph. That is the 2022 NHTS average commute speed for privately owned vehicles, door to door [R2]. It is an assumption, not a measured Las Vegas speed.

Every crash or conflict count below is a **floor** on encounters, because a situation can be met without a conflict. Dataset class counts come from curated datasets (nuScenes, AV2, CODA, WOD-E2E, nuPlan tags) and are not rates.

## (a) Encounter rates

| item | encounter rate (unit) | inputs / derivation | source | conf. | changes survey tier? |
|---|---|---|---|---|---|
| emergency vehicle scene | **≥ ~2.6 per 1,000 mi** (≥ ~6.9 per 100 h), Waymo fleet | Waymo statement: "more than 10,000 active emergency vehicle scenes each week" (news). Mileage: 271.3 M rider-only miles through June 2026 [R4]; 220.6 M through March 2026 (search snippet only). The difference, 50.7 M mi over about 13 weeks, is about 3.9 M mi/week. "Scene" is undefined and probably includes stationary vehicles with lights on | R3 (news), R4 | low | **Possibly.** If confirmed, the rate is "occasional", not "long tail". Needs a primary Waymo figure |
| EMS activations (events, not encounters) | 19.3 per million VMT (US) | 63,635,893 activations [S5] ÷ 3,294,031 M VMT [S1] | S5, S1 | high (as an event rate) | no |
| police officer or watchman directing | ≥ 0.0015 per 1,000 mi (≥ 0.004 per 100 h) | 100-Car: 2 crashes + 1 near-crash with control device "Officer or watchman" (Table 5.25) ÷ 2.0 M mi; 43,000 h gives 0.007 per 100 h. The 119 in that table row is a GES crash count, not 100-Car events | R5 | low (a conflict floor; Northern Virginia) | no |
| school bus stopped with signals | ≥ 0.024 per 1,000 VMT on school days (≥ 0.063 per 100 h) | 213,800 illegal passes per day [S41] ÷ (3,294,031 M VMT [S1] ÷ 365). Counts violations only | S41, S1 | medium (as a floor) | no ("occasional" stands) |
| school bus as a road user | 3.1 school-bus miles per 1,000 VMT on school days, Las Vegas | 140,000+ CCSD bus-miles per day [S4] ÷ 45,606 k DVMT [R1] | S4, R1 | medium (S4 not reachable today) | no |
| rail crossing traversal | **10.1 per 1,000 VMT (27 per 100 h)**, Las Vegas valley | Sum of 2022 AADT over the 44 open public at-grade crossings in valley places (Henderson, North Las Vegas, Paradise, Las Vegas, Nellis AFB, Arden) = 461,161 per day [S17], ÷ 45,606 k DVMT [R1]. 89% of these traversals are at crossings with ≥ 1 train per day | S17, R1 | medium (AADT 2022 vs DVMT 2023) | **Yes, split it.** The crossing as a road feature is everyday |
| rail crossing with active warning | ≥ 0.0056 per 1,000 VMT (≥ 0.015 per 100 h, i.e. about once per 6,700 h or less) | Σ(AADT × trains per day, through + switching) = 1,108,862 per day × 20 s ÷ 86,400 s = 257 arrivals per day during warning. 20 s is the federal minimum warning time (49 CFR 234.225, not re-fetched). Real activations are longer, so this is a lower bound | S17 | low (bound) | no ("long tail" stands for the train case) |
| roundabout | not found (no AADT) | 64 roundabout-type entries in Clark County, 26 + 10 (Summerlin) in Las Vegas, 20 in Henderson [S20]; against 1,700+ signals that is about 1 per 27 [S25] | S20, S25 | medium | no |
| funeral procession (events) | ≤ 0.29 per million VMT (US) | Burials as an upper bound: 3,072,666 deaths [S7] × 31.6% [S8] = 0.97 M ÷ 3,294,031 M VMT. Encounter rate not found | S7, S8 | low (bound only) | no |
| personal delivery device | not found | 3,300 deliveries in 2 years around UNLV only (news) [S11] | S11 | low | no |
| golf cart / low-speed vehicle; skateboard | not found | AV2 WHEELED_DEVICE (skateboards to golf carts) ranks 9 of 30, but AV2 is curated [S37] | S37 | — | no |
| ice-cream / vending truck | not found | no Clark County count found | — | — | no |
| tunnel | ~0 in the valley | 6 tunnels in all of Nevada [S23] | S23 | medium | no |
| curve / crest / mountain grade | not found | qualitative only [S24] | S24 | — | no |
| fog ≤ ¼ mi; fog ≤ ⅝ mi | ≤ 0.19 h and ≤ 1.0 h per 100 h | 0.7 and 3.7 days per year [S28], ÷ 365. A day-level upper bound that assumes driving is spread evenly over days | S28 | medium | no |
| snow ≥ 0.1 in | ≤ 0.05 h per 100 h | 0.2 days per year [S27] | S27 | medium | no |
| freezing night (an ice proxy) | 24 days per year with low ≤ 32 °F (6.6% of days) | No icy-road measure. Freezing seldom coincides with moisture | S28 | low | no |
| lane-control signals | traversal not computed; lane-closed display rate not found | 42 ATM gantries showing "lane use control" on I-15 (Russell Rd–Washington Ave) and US-95 (Valley View–Las Vegas Blvd) [R7, trade press]; 10 more in 2023 (news, not fetched) | R7 | medium | **Yes, partly.** "Count missing" becomes "present on central freeways"; drivers pass under them daily, but a red-X lane closure is the rare event |
| work zone | about 10 per 1,000 VMT on the NHS (secondary); at the summer peak, 12.8% of NHS route-miles lie inside a work zone (one zone per about 53 NHS miles; average zone length about 6.7 mi) | FHWA 2001: "3,110 work zones" covering "20,876 miles (12.8%)" of the NHS [R8]. AAA 2009 attributes to FHWA "one out of every 100 miles" (not fetched). 100-Car: 12 crash + near-crash events in construction zones per 2.0 M mi (0.006 per 1,000 mi) [R5] | R8, R5 | medium (extent), low (per-mile rate) | **Possibly.** "Occasional" may understate it on freeways |
| animal (for comparison) | ≥ 0.034 per 1,000 mi (0.16 per 100 h) | 100-Car: 2 crashes + 10 near-crashes + 56 incidents (Table RO.3) ÷ 2.0 M mi or 43,000 h [R5]. Largely non-urban Virginia | R5 | medium (floor) | no for Las Vegas |
| corner cases in general | about 7.3 corner-case frames per driving hour (China) | CODA-ONCE: 1,057 scenes ÷ the 144 h of ONCE [R9] | R9 | low (curated) | — |

**Still missing:**
- SHRP2 publishes no baseline prevalence for work zones, weather, rail crossings or human direction. Dingus 2016 [R10] gives driver factors only, and the SHRP2 work-zone (FHWA-HRT-20-010) and rail-crossing studies [R11] report sample sizes, not exposure.
- The WOD-E2E per-cluster shares and the nuPlan counts per scenario type and per city exist only in figures.

## (b) Re-check of the survey's figures (fetched 2026-10-12)

| figure | result |
|---|---|
| NEMSIS 63,635,893 activations; ≈ 19 per million VMT [S5] | match |
| nuScenes: "ambulance is the least frequent"; classes with < 10,000 annotations removed [S36] | match |
| WOD-E2E: 6,391,012 mi, 6,888 mi (0.1%), 0.03% [S38] | match. The cluster is named "Special Vehicles"; the survey's wording "require a pull-over" was not re-confirmed |
| AV2 ranks: OFFICIAL_SIGNALER 28, SCHOOL_BUS 20, WHEELCHAIR 26, STROLLER 22, ANIMAL 30 of 30 [S37] | match. Note AV2 totals only 4.2 h |
| NASDPTS 213,800 illegal passes per day [S41] | match (56,024 reported by 101,334 drivers; 38.4 M per year) |
| CCSD 1,922 buses, 31,437 stops, 140,000+ mi [S4] | not reachable (Wayback blocked, CCSD timed out) |
| Kittelson: 131 Nevada roundabouts, 26 Las Vegas, 20 Henderson; 11,900 US [S20] | match, but the survey left out "Las Vegas (Summerlin)" (10) and Nellis AFB (3). The Clark County total is **64** |
| RTC FAST: 1,700+ signals, 76 ramp meters, 169 DMS/ATM gantries [S25] | match |
| FRA: 62 open public at-grade crossings in Clark County, 2 in the City of Las Vegas; 2 valley mainline crossings with 7 day and 7 night trains; 13 collisions 2015–2025 [S17, S18] | match. A third 14-train crossing, Prison Rd at Jean, is outside the valley |
| CDC 3,072,666 deaths; NFDA burial rate 31.6% [S7, S8] | match |
| Golf carts "only in permitted residential developments of large counties" [S10] | **differs.** The source says "residential developments of counties that only approve of their operations"; "large" is not in S10 |
| PDD: 3,300 deliveries in two years around UNLV [S11] | match |
| Tunnels: 6 in Nevada [S23] | match |
| NWS: snow "once every four or five years"; the valley "slop[es] gradually upwards" [S24] | match |
| NOAA normals: 25.8 / 11.0 precipitation days; 0.2 in snow; 0.2 snow days [S27] | match |
| Fog: 0.7 days ≤ ¼ mi, 3.7 days ≤ ⅝ mi [S28] | match |
| Work zones: 20% summer / 7% winter [S26b]; 2.1% of fatal crashes [S43]; 1,179 Nevada crashes [S47] | match. S43 is 2024: 763 fatal crashes, 850 deaths |
| Lane-control signals, "no count" | superseded by the 42 gantries [R7] |

## (c) Salience: required regardless of frequency

- **NHTSA guidance.**
  - ADS 2.0 (2017), the OEDR section: an ADS should address "a wide variety of foreseeable encounters, including emergency vehicles, temporary work zones, and other unusual conditions (e.g., police manually directing traffic…)" [R12].
  - DOT HS 812 623 (2018), Table 41, lists "Detect & Respond to Relevant School Buses", "… Emergency Vehicles", "Detect & Navigate Work Zones" and "… Relevant Safety Officials". Frequency is used only to rank test priority [R13].
  - All of this is voluntary.
- **NHTSA defect investigations on rare situations.**
  - PE21-020, "Autopilot & First Responder Scenes", opened on 11 crashes [R14]. It led to EA22-002 and recall 23V-838 [R15].
  - PE25-013, "Waymo AV drives around a stopped school bus", was opened on a single Atlanta incident; ODI judged further cases "high" likelihood [R16]. The Austin school district later cited 19 incidents [R17]. A Waymo recall followed (25E-084, 3,067 vehicles; the recall report was not retrieved).
  - PE24-016 (Waymo) included "entering construction zones": 367 incidents and 109 crashes, closed with recalls 24E049 and 25E034 [R18].
- **States.**
  - California requires a law-enforcement interaction plan, 13 CCR §227.38(e) [R19]. AB 1777 (2024) requires a fleet to leave an emergency geofence within 2 minutes from 1 July 2026 [R20].
  - Arizona requires a plan under A.R.S. §28-9702(C) [R21]. Texas SB 2807 requires a First Responder Interaction Plan [R22].
  - Nevada has no specific rule. NRS 482A.080(2) requires the vehicle to be "capable of operating in compliance with the applicable motor vehicle laws and traffic laws of this State", so the emergency-vehicle and school-bus statutes apply in full.
- **MUTCD 11th edition, §5A.04.** It notes that automation systems have a limited ability to comprehend temporary traffic control devices "such as … flaggers" [R23].

## (d) Precedent and the ODD

- **Published traffic-rule formalizations choose a subset and say why. They scope by road domain, frequency, crash relevance or simulator support, never by completeness.**
  - Maierhofer et al. 2020: 9 interstate rules, chosen "since they must be frequently considered on interstates" [R24].
  - Maierhofer et al. 2022: 5 intersection rules; "We do not consider signs given by police officers… crossings, pedestrians, cyclists, railroad vehicles, and buses" [R25].
  - Esterle et al. 2020 scope by ODD ("At first, the operational design domain needs to be defined…") and exclude parking, breakdowns, signalling, regulatory signs and limited visibility [R26].
  - Rizaldi & Althoff 2015: highway rules only, as "the most likely domain that fully autonomous vehicles will firstly be legal". They keep priority vehicles as a metarule [R27].
  - Rizaldi et al. 2017 chose StVO §5 (overtaking) as representative of codification [R28].
  - Karimi & Duggirala 2020 justify uncontrolled intersections by crash share [R29].
  - Deng et al. (TARGET, TSE 2025) use 98 Texas handbook rules. They exclude parking and non-vehicular rules for limited ADS support [R30].
  - Manas et al. (TR2MTL, arXiv 2406.05709) "does not cover some less representative or exceptional driving scenarios" but includes emergency-vehicle right of way [R31].
- **The ODD as the standard scoping device.**
  - SAE J3016_202104 §3.21: "Operating conditions under which a given driving automation system or feature thereof is specifically designed to function, including… environmental, geographical, and time-of-day restrictions, and/or the requisite presence or absence of certain traffic or roadway characteristics" [R32].
  - ISO 34503:2023 specifies a hierarchical ODD taxonomy (static and dynamic attributes) [R33].
  - BSI PAS 1883:2020 was the predecessor taxonomy, **withdrawn 25 Mar 2025** [R34].
  - NHTSA DOT HS 812 623 gives an ODD taxonomy of six categories, including Objects and Zones [R13].
  - The scoping move this precedent supports is to declare an ODD and to state the excluded situations as ODD restrictions. It does not support deleting rules silently.

## (e) Sources (all accessed 2026-10-12; the S-ids are the survey's, §9)

| id | publisher, title, year | URL |
|---|---|---|
| R1 | FHWA, Highway Statistics 2023, Table HM-71 | https://www.fhwa.dot.gov/policyinformation/statistics/2023/hm71.cfm |
| R2 | FHWA, Summary of Travel Trends: 2022 NHTS, Table 7-4, 2024 | https://rosap.ntl.bts.gov/view/dot/73764/dot_73764_DS1.pdf |
| R3 | NBC6 Miami (news), Waymo statement, 2026 | https://www.nbcmiami.com/investigations/the-unexpected-challenges-facing-waymo-on-south-florida-roads/3866640/ |
| R4 | Waymo, Safety Impact hub, 2026 | https://waymo.com/safety/impact/ |
| R5 | NHTSA, 100-Car Naturalistic Driving Study Phase II, DOT HS 810 593, 2006 | https://rosap.ntl.bts.gov/view/dot/37370/dot_37370_DS1.pdf |
| R7 | Roads & Bridges (trade press), "Nevada DOT begins activation of ATM signs along Project Neon", 2020 | https://www.roadsbridges.com/nevada-dot-begins-activation-atm-signs-along-project-neon |
| R8 | FHWA, A Snapshot of Summer 2001 Work Zone Activity, 2003 | https://rosap.ntl.bts.gov/view/dot/3857/dot_3857_DS1.pdf |
| R9 | Li et al., CODA, ECCV 2022 (arXiv 2203.07724); Mao et al., ONCE (arXiv 2106.11037) | https://arxiv.org/abs/2203.07724 |
| R10 | Dingus et al., PNAS 113(10), 2016, doi 10.1073/pnas.1513271113 | https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4790996/ |
| R11 | FHWA-HRT-20-010 (SHRP2 work zones), 2019; FRA/MTU, NDS grade-crossing study | https://www.fhwa.dot.gov/publications/research/safety/20010/20010.pdf ; https://rosap.ntl.bts.gov/view/dot/54627 |
| R12 | NHTSA, Automated Driving Systems 2.0: A Vision for Safety, 2017 | https://www.nhtsa.gov/sites/nhtsa.gov/files/documents/13069a-ads2.0_090617_v9a_tag.pdf |
| R13 | Thorn, Kimmel, Chaka (NHTSA), DOT HS 812 623, 2018 | https://rosap.ntl.bts.gov/view/dot/38824/dot_38824_DS1.pdf |
| R14 | NHTSA ODI, PE21-020 resume, 2021 | https://static.nhtsa.gov/odi/inv/2021/INOA-PE21020-1893.PDF |
| R15 | NHTSA ODI, EA22-002 additional information, 2024 | https://static.nhtsa.gov/odi/inv/2022/INCR-EA22002-14496.pdf |
| R16 | NHTSA ODI, PE25-013 resume, 2025 | https://static.nhtsa.gov/odi/inv/2025/INOA-PE25013-23069.pdf |
| R17 | NHTSA ODI, PE25-013 correspondence, 2025 | https://static.nhtsa.gov/odi/inv/2025/INOT-PE25013-30887.pdf |
| R18 | NHTSA ODI, PE24-016 opening and closing resumes, 2024–25 | https://static.nhtsa.gov/odi/inv/2024/INCLA-PE24016-72139.pdf |
| R19 | 13 CCR §227.38 (Cornell LII) | https://www.law.cornell.edu/regulations/california/13-CCR-227.38 |
| R20 | California AB 1777, Ch. 682, Stats. 2024 | https://calmatters.digitaldemocracy.org/bills/ca_202320240ab1777 |
| R21 | Arizona Legislature, A.R.S. §28-9702 | https://www.azleg.gov/ars/28/09702.htm |
| R22 | TxDMV, SB 2807 law-enforcement handout, 2026 | https://www.txdmv.gov/sites/default/files/body-files/SB_2807_LE_Handout.pdf |
| R23 | FHWA, MUTCD 11th Edition, Part 5, 2023 | https://mutcd.fhwa.dot.gov/pdfs/11th_Edition/part5.pdf |
| R24 | Maierhofer et al., IEEE IV 2020, doi 10.1109/IV47402.2020.9304549 | https://mediatum.ub.tum.de/doc/1552345/1552345.pdf |
| R25 | Maierhofer, Moosbrugger, Althoff, IEEE IV 2022, doi 10.1109/IV51971.2022.9827153 | https://mediatum.ub.tum.de/doc/1664592/1664592.pdf |
| R26 | Esterle, Gressenbuch, Knoll, IEEE CAVS 2020, arXiv 2007.00330 | https://arxiv.org/abs/2007.00330 |
| R27 | Rizaldi & Althoff, IEEE ITSC 2015, doi 10.1109/ITSC.2015.269 | https://doi.org/10.1109/ITSC.2015.269 |
| R28 | Rizaldi et al., iFM 2017, LNCS 10510, doi 10.1007/978-3-319-66845-1_4 | https://doi.org/10.1007/978-3-319-66845-1_4 |
| R29 | Karimi & Duggirala, ICCPS 2020, doi 10.1109/ICCPS48487.2020.00012 | https://doi.org/10.1109/ICCPS48487.2020.00012 |
| R30 | Deng et al., TARGET, IEEE TSE 51, 2025, arXiv 2305.06018 | https://arxiv.org/abs/2305.06018 |
| R31 | Manas, Zwicklbauer, Paschke, TR2MTL, arXiv 2406.05709, 2024 | https://arxiv.org/abs/2406.05709 |
| R32 | SAE International, J3016_202104, 2021 | https://www.sae.org/standards/content/j3016_202104/ |
| R33 | ISO 34503:2023 | https://www.iso.org/standard/78952.html |
| R34 | BSI, PAS 1883:2020 (withdrawn 2025) | https://knowledge.bsigroup.com/products/operational-design-domain-odd-taxonomy-for-an-automated-driving-system-ads-specification |

**Provenance.**
- I checked these myself against the live source: R1, R2, R4, R5, R8, R14, R16, and every row in (b).
- The other R-sources were read by research sub-agents. Their quotes were not re-fetched by me.
- R3 and R7 are news or trade press.

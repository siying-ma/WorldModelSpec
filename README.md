# WorldModelSpec — the traffic law corpus

This repository carries the body of traffic law used by the project, cut into machine-readable
obligations, together with the record of where every line came from and why lines that were read
were nevertheless kept out. *

Jurisdiction: **Las Vegas, Nevada** — the state statutes and the municipal code that together
govern driving on a Las Vegas street.

| file | lines | what it holds |
|---|---|---|
| [laws.jsonl](pipeline/traffic-spec-agent/laws/example/laws.jsonl) | 285 | the corpus: every resolvable line that judges a driving situation |
| [laws_full.jsonl](pipeline/traffic-spec-agent/laws/example/laws_full.jsonl) | 296 | the corpus plus the excluded lines, i.e. every resolvable line |
| [excluded.jsonl](pipeline/traffic-spec-agent/laws/example/excluded.jsonl) | 11 | read, but does not judge a driving situation (each with `excluded_reason`) |
| [unresolvable.jsonl](pipeline/traffic-spec-agent/laws/example/unresolvable.jsonl) | 31 | read, but carries a reference no source resolves (each with `blocking`) |
| [definitions.jsonl](pipeline/traffic-spec-agent/laws/example/definitions.jsonl) | 123 | the defined terms (115) and the operative provisions cited by a line (8) |

## 1. Sources of the law

Everything in the corpus is **verbatim**: the law's own words, cut into one line per paragraph.
No line was paraphrased, and no sentence was split.

| source | lines in the corpus | what was taken |
|---|---|---|
| **Nevada Revised Statutes, ch. 484A** — definitions and general provisions | 2 | only the two conduct sections: stop/yield sign position (484A.450) and warning-lamp use (484A.480) |
| **NRS ch. 484B** — rules of the road | 191 | the bulk of the corpus |
| **NRS ch. 484D** — equipment | 9 | only sections regulating the *use* of equipment while driving |
| **NRS ch. 486** — motorcycles, mopeds, trimobiles | 7 | operating rules: passengers, seat, hands, lamps, lane use, passing, lane splitting |
| **Las Vegas Municipal Code, Title 11** — Vehicles and Traffic | 76 | every chapter that imposes a duty on a road user: 11.12, 11.16, 11.18, 11.20, 11.22, 11.27, 11.30, 11.38, 11.40, 11.42, 11.43, 11.46, 11.48, 11.52, 11.60 |

Where the text came from:

- **NRS** — the Legislative Counsel Bureau's published chapter pages, taken from a 2025 Wayback
  snapshot (the live site and Justia sit behind a bot challenge). Parsed by
  [nrs_tree.py](pipeline/ontology_provenance/nrs_tools/nrs_tree.py) into
  `sources/484A.json`, `484B.json`, `484D.json`, `486.json`.
- **LVMC** — the City's Municode publication through its content API (`api.municode.com`,
  product 14787, job 491986, retrieved 2026-09-18). Parsed by
  [lvmc_tree.py](pipeline/ontology_provenance/nrs_tools/lvmc_tree.py) into `sources/lvmc.json`.
- **City of Las Vegas, *Transportation Engineering Fact Sheets*** (Public Works, March 2025) —
  read in full and **not** a source of lines. They are explanatory material for residents and only
  paraphrase provisions that the corpus already carries from the Code itself. Kept in
  `sources/clv_transportation_fact_sheets_2025-03.txt` for the record.

[make_laws.py](pipeline/ontology_provenance/nrs_tools/make_laws.py) holds the selection list —
which subsection became which line, which paragraphs were appended to which, and the subject and
theme given to each line — and generates the JSONL from the parsed sources.

### What a line looks like

```json
{"id": "LVMC-11-52-130-A11",
 "title": "Posted places (A)(11)",
 "text": "<verbatim text>",
 "source": "LVMC 11.52.130(A)(11)",
 "subject": "driver",
 "theme": "stopping_standing_parking",
 "tier": "C",
 "supersedes": ["NRS-484B-450-1f"]}
```

`id` is the subsection path (`NRS-484B-307-8d` is NRS 484B.307(8)(d)). `subject` is whose conduct
the line judges — `driver` (204), `rider` (27), `pedestrian` (20), `motorcyclist` (8) and smaller
classes. `theme` (26 of them) is a coarse grouping for selecting sub-corpora. `tier` records how
much judgement the text demands: **C** — no judgement element (163); **Q** — a concrete rule with a
judgement qualifier, exception or threshold (87); **S** — the obligation *is* a standard of care
(35). The classification and its reasons are in
[tiers.py](pipeline/ontology_provenance/nrs_tools/tiers.py).

### Overlapping obligations

The Municipal Code restates much of the statute. Where a municipal line and a statutory line
state the same obligation, only the text with the **narrower definition** was kept: the more
concretely stated trigger (a sign, a marked crosswalk, a distance, a vehicle class), fewer open
judgement terms, exceptions stated. Tie-breakers, in order: express state preemption keeps the
statute (NRS 486.180(2) for motorcycles, NRS 484A.400 for the rules of the road generally);
identical words keep the statute; where neither text contains the other, both are kept.

Result: 65 lines dropped, 70 kept as the narrower text, 5 pairs kept as partial overlaps. The kept
line names the dropped ids in `supersedes` (64 lines carry one). Every decision with its reason is
in [OVERLAPS.md](pipeline/traffic-spec-agent/laws/example/OVERLAPS.md), generated from
[overlaps.py](pipeline/ontology_provenance/nrs_tools/overlaps.py).

## 2. Excluded — the line does not judge a driving situation (11)

A line is excluded when what it regulates is not how a road user moves through traffic: what the
vehicle is *fitted with*, what a person *wears*, or a permission that switches other rules off.
Each line keeps its `excluded_reason`; the list lives in `EXCLUDED` in
[tiers.py](pipeline/ontology_provenance/nrs_tools/tiers.py).

| group | lines | why |
|---|---|---|
| rider and passenger apparel | NRS 486.231(2), LVMC 11.38.130, 11.40.185(C) | judges what a person wears, not how they move; the helmets-on-minors line would also need an age estimate |
| equipment legality while driving | NRS 484A.480(5)–(7), 484B.783(1), 484D.185(1), 484D.515(1), 484D.545(1) | judges what the vehicle is fitted with or displays (flashing headlamps, a red or blue lamp, bicycle lamps and reflectors, an amber warning light, tire chains, the slow-moving-vehicle emblem), not how it is driven |
| a permission, not an obligation | NRS 484B.700(1) | the privileges of a responding emergency vehicle: an applicability record that disables other rules, not a rule to monitor |

Excluded lines stay in `laws_full.jsonl`, so the two bodies can be reported together. A line that
is both excluded and carries an unresolved reference stays on the excluded side
(NRS 484A.480(5)–(7), 484D.185(1)).

## 3. Unresolvable — the line carries a reference nothing resolves (31)

Cross-references inside a line are resolved to corpus ids and annotated in the text in square
brackets right after the referring words. A reference that no source in the repository can
resolve is marked on the line as `{phrase, kind, note}`. **Decided 2026-09-20: every line carrying
such a mark is out of the corpus**, on the rule that no corpus line may carry an unresolved
reference. The marks and the kinds are in
[references.py](pipeline/ontology_provenance/nrs_tools/references.py); the blocking reasons in
`BLOCKING` in [tiers.py](pipeline/ontology_provenance/nrs_tools/tiers.py).

**For 8 lines the unresolved element is the trigger or the obligation itself:**

| line | what cannot be resolved |
|---|---|
| NRS 484B.307(11) | no criterion for which signal provisions apply at a mid-block signal |
| NRS 484B.790(3) | no criterion for which pedestrian duties a mobile carrying device inherits |
| NRS 484B.360(2) | the trip's purpose ("properly a part of a school program") is the trigger |
| LVMC 11.16.050 | whether the park limit is in force is an administrative determination, park by park |
| LVMC 11.41.020 | the permitted streets are a schedule with no sign; the region is the whole rule |
| LVMC 11.52.030(E) | lawful use of a blue-curb space turns on a permit or plate that is not reliably observable |
| LVMC 11.60.030(B)(1) | the exception turns on the purpose of the trip (celebrity tour, nonprofit function) |
| LVMC 11.68.030 | the Pedestrian Mall boundary is an ordinance exhibit map; the region is the whole rule |

**For the other 23 the mark is a peripheral reference**, and the line was removed under the same
rule rather than for its trigger:

| kind | lines | what it points at |
|---|---|---|
| `schedule` | 12 | a "Schedule NN" held by the City Clerk (truck routes, alley and parking restrictions, weight limits); two of these carry a second mark, an `external_designation` (LVMC 11.48.030) and a `permit` (LVMC 11.52.270) |
| `external_equipment` | 6 | an equipment standard or permit class in a chapter not in the corpus (the four move-over lines NRS 484B.607(1), NRS 484D.220(1), NRS 486.251(1)) |
| `federal_definition` | 2 | a vehicle class defined in federal regulation (NRS 484B.560) |
| `penalty` | 2 | a penalty clause (NRS 484B.327(2), 484B.550(1)) |
| `regulation` | 1 | an HOV condition "established by regulation" (NRS 484B.323(1)) |

Two consequences worth naming:

- **A reference *into* a removed line does not cascade.** A corpus line pointing at one keeps its
  bracketed id and carries an `unresolved` mark of kind `removed_target` instead of moving:
  NRS 484B.300(1) → 484B.307(11); 484B.208(1) → 484B.323(1); 484B.267(2)(f) → the 484B.607(1)
  move-over lines. The move-over duty toward a traffic incident is therefore out of the corpus,
  while the approach-of-an-emergency-vehicle duty (484B.267) stays.
- **Reinstatement.** Where the removed line was the narrower survivor of an overlapping pair, the
  resolvable text it had superseded comes back, marked `reinstated_for`: NRS 484B.503, 484B.507(1),
  484B.477(1)(a), LVMC 11.22.100, LVMC 11.38.120(B).

Lines that were read and never became lines at all — definitions, administrative authority,
penalties, licensing, procedure, equipment installation, speed-limit administration, applicability
rules, and conduct no exterior observation can support (open container, handheld device, child
restraints, window tint, load securing) — are listed with their reasons in
[laws/example/README.md](pipeline/traffic-spec-agent/laws/example/README.md) under *What was left
out, and why*. The line-by-line audit behind the four views is
[CORPUS_AUDIT_2026-09-19.md](pipeline/traffic-spec-agent/laws/example/CORPUS_AUDIT_2026-09-19.md).

## 4. Training / test split (2026-09-20)

The 285 corpus lines are split into a **training set of 256** and a **test set of 29 (10.2%)**.
Each side is a directory holding its own `laws.jsonl` and the `definitions.jsonl` that goes with
it, so a run over one side never sees the other side's definitions.

| set | lines | C | Q | S | definitions | file |
|---|---|---|---|---|---|---|
| training | 256 | 142 | 82 | 32 | 114 | `laws/example/train/` |
| test | 29 (10.2%) | 21 | 5 | 3 | 9 | `laws/example/test/` |

The test set stands for **legislation the corpus has never seen**: road-user classes the statute
created recently, a road structure with its own traffic pattern, new devices and new signals. It is
chosen by hand — each line with its stated reason in
[split.py](pipeline/ontology_provenance/nrs_tools/split.py) — and then held to three constraints
that the script checks and refuses to write otherwise:

1. **Self-containment.** No training line references a test line, so nothing built from the
   training set depends on a law it has not seen. The converse is allowed: new legislation builds
   on old.
2. **New vocabulary.** The test set must introduce concrete atoms and enumeration values that no
   training line mentions, so the evaluation measures extending the vocabulary, not only reusing
   it. Support is computed two ways and unioned: the hand-written statute references per atom in
   the provenance document, and a keyword lexicon over the verbatim text
   ([atom_lexicon.py](pipeline/ontology_provenance/nrs_tools/atom_lexicon.py)).
3. **Definitions follow their lines.** A definition used only by test lines, or whose term occurs
   in no training text, goes to the test side (9 records, among them *school bus*, *personal
   delivery device*, *mobile carrying device*, *low-speed vehicle*, *roundabout*).

### What the test set brings

| cluster | test lines |
|---|---|
| personal delivery devices (a class the statute created in 2019) | NRS 484B.787(2)(a)–(c) |
| mobile carrying devices (2021) | NRS 484B.790(2)(a)–(c) |
| roundabouts — a structure with its own traffic pattern | NRS 484B.220(2), LVMC 11.43.010(A), (B), (C)(1), (C)(2) |
| school buses and their signal | NRS 484B.353(1), 484B.360(1) |
| coasters, skates and skateboards | LVMC 11.22.130(A)–(C) |
| vending vehicles (the ice-cream-truck rule) | LVMC 11.22.150(A), (B) |
| low-speed vehicles | NRS 484B.637(2)(b) |
| new signals — door open, reverse lamp, compression brake | NRS 484B.153(2), (3); 484D.205(4); 484D.285(1) |
| new structures and a steering input | NRS 484B.630(1) (turnout), NRS 484B.533 (steer angle), NRS 484B.633(2) (bridge speed sign) |
| ordinary lines over known vocabulary — plain generalization | NRS 484B.450(1)(m), LVMC 11.12.100(C), 11.42.030 |

14 atoms and 2 enumeration values have support only on the test side; 52 atoms are shared, so the
test set also exercises the known vocabulary. The full lists, the definitions moved across, and
the clusters that were **rejected** because moving them would have broken self-containment (school
zones, lane-control signals, the white-cane stop, centre turn lanes, safety zones, the curb colour
code) are in [SPLIT.md](pipeline/traffic-spec-agent/laws/example/SPLIT.md), generated with
`python -m nrs_tools.split` from `pipeline/ontology_provenance/`.

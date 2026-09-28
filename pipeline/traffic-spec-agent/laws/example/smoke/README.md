# Smoke subset — 10 lines, self-contained

A diagnostic corpus for the loop: small enough that one iteration is cheap to run and to read,
and closed so that nothing in it depends on anything outside it.

**Self-contained.** No line here carries a cross-reference to another line, in the corpus or out
of it: every id in `laws_meta.jsonl`'s `refs` is empty for all ten, and none carries an
`unresolved` mark. A node planned from this corpus can therefore never emit a composition to a
rule that does not exist, and the composition-ordering path is out of scope for a run over it.

**Size.** 10 lines, 1,133 characters of law text (the 18-line demo subset carries 11,846), plus
21 definitions. The definitions are every "X defined" section whose term occurs in the ten texts,
so the aggregate words the planner must build (`vehicle`, `motor vehicle`, `driver`, `traffic`)
have their statutory definitions present, including the nesting of `motor vehicle` inside
`vehicle`.

## What each line is for

| line | tier | what it exercises |
|---|---|---|
| `NRS-484B-110` | C | the simplest possible rule: one binder, one region occupancy (`st.safety_zone`) |
| `NRS-484B-113-1` | S | a pure standard — "reasonable safety", "without interfering": surrogate flag, operationalization with parameters |
| `NRS-484B-113-2` | C | `drv.backing` with region occupancy, and a three-way disjunction of places |
| `NRS-484B-220-1` | C | a posted device (`dev.regulatory_sign` one_way) with `st.lane_direction` / `drv.wrong_way` |
| `NRS-484B-220-2` | C | region geometry and side-of-region: `st.roundabout`, `rel.bearing` |
| `NRS-484B-260` | C | **two binders** and a yield: `drv.yields_to`, `drv.approaching`, `st.driveway_or_alley_entrance` |
| `NRS-484B-293` | S | a different subject aggregate (pedestrian) and a "practicable" standard |
| `NRS-484B-360-1` | C | a **statutory magnitude** (55 mph) through a `Units` constructor, plus a class atom |
| `NRS-484B-600-1e` | C | a second magnitude (80 mph) with no condition at all — the shortest speed rule |
| `NRS-486-211` | C | `ru.rider_posture` — an atom no other line here touches |

Eight concrete lines and two standards; two lines carry a figure the statute states; one needs a
second party. That spread is chosen to exercise each path the gate checks — literals, surrogates,
two-binder grounding, device governance, posture — without any line depending on another.

## Running it

```bash
python -m harness loop --run-id smoke1 --laws laws/example/smoke/laws.jsonl
```

The plan phase reads the `definitions.jsonl` beside the corpus, so nothing else needs pointing at.

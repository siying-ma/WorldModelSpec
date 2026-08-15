# Lean GitHub Repository Collection

Scripts in `scripts/` collect public GitHub repositories matching `language:Lean`.
The collector works around GitHub Search API's 1,000-result pagination ceiling by
querying immutable `created:` date windows and recursively splitting any window
whose `total_count` is still too large.

## Outputs

All collected data is written under `projects/`:

- `lean_repositories.json`: de-duplicated repository metadata.
- `lean_repositories.jsonl`: one repository per line.
- `lean_repositories.csv`: compact tabular index.
- `lean_repo_urls.txt`: GitHub web URLs.
- `lean_clone_urls.txt`: HTTPS clone URLs.
- `lean_chunk_manifest.json`: query windows and page counts.
- `lean_summary.json`: run summary.
- `raw_pages/`: raw Search API page responses.

## Run

Use a token through the environment; do not hard-code it into the scripts.

```bash
export GITHUB_TOKEN='...'
bash scripts/run_collection.sh
```

The default query includes forks (`fork:true`) because it is meant to collect all
matching public repositories. Add `--exclude-forks` to `collect_lean_repos.py` if
you want only non-forks.

## Filtering

The raw collection is broad (all `language:Lean` repos, forks
included). Need some filtering before even compiling them.

1. Drop forks. Keep only records where "fork": false and also drop archived: true and disabled: true here.

2. Drop pre-Lean 4 projects. We only care about Lean 4 not Lean 3. A reliable way is to clone the project, check if project root has lean-toolchain and lean-toolchain contains the word "lean4". Drop if it doesn't. (fetch only https://raw.githubusercontent.com/<owner>/<repo>/<default_branch>/lean-toolchain for filtering):

- Some early Lean 4 repos (2021–2022) predate the lean-toolchain convention — a missing file doesn't always mean Lean 3. Cross-reference with topics: if the repo has lean4 in topics and no lean-toolchain, consider keeping it rather than dropping.
- The created_at date is a weak prior: repos created before mid-2022 are overwhelmingly Lean 3. You could skip fetching for anything created before 2022-01-01 and just drop it — saves ~1,500 HTTP requests.
Rate limit: 10k repos × 1 request = ~2 hours at authenticated rate (5k req/hr). Checkpoint per repo is critical here.

3. Deduplicate. Different non-forked Lean projects can be the same or too similar. Maybe deduplicate based on file-structure?

Better: fetch lakefile.lean or lakefile.toml via raw GitHub URL (same pattern as lean-toolchain — no clone needed). Hash that file; identical hashes = duplicate project. This catches copy-pasted course repos and re-uploads. Also catches repos that only have import Mathlib and no real content (useful for step 4 too).

4. Drop empty / template / coursework noise. Maybe check for number of commits/project size, and some other heuristics...

size < 5 KB — drop (tunable threshold)
Name/description heuristics: regex match on homework, exercise, assignment, class, course, tutorial, lecture, problem set, cs\d{3,4} in name or description
Topics: exercises, homework, tutorial topics are a reliable signal
forks_count == 0 AND stargazers_count == 0 AND size < 20 KB: strong noise signal — flag these for manual review or drop
From the lakefile fetch in step 3: if the entire lakefile is just import Mathlib or a one-liner with no declarations - drop

5. Build the project with lake build (first "lake exe cache get" then "lake build") if a project depends on mathlib, otherwise, just lake build. Only keep the ones that build. You can check if project depends on mathlib by checking if lake-manifest.json has an entry for "url": "https://github.com/leanprover-community/mathlib4.git" or "name": "mathlib" (check this https://github.com/leanprover/cslib and https://github.com/weiran-sun/pde as an example lean project)

Before cloning, also fetch lakefile.lean / lakefile.toml to confirm a valid build config exists (you may already have this from step 3)
lake exe cache get can fail silently — check its exit code separately before running lake build
Always set a timeout on lake build (e.g. 30 min) — some repos hang indefinitely
Clean up immediately after each build attempt (rm -rf repo/) to control disk usage
Log stdout/stderr of failed builds — useful for understanding failure modes

## Notes
Lake build is cpu intensive, so careful with number of parallel processes you launch
Lake build also downloads the lean tool chain, usually to ~/.elan/toolchains/ make sure you have enough space in home dir (each version takes 1-3GB) so you might want to periodictly remove some toolchains while running (e.g. elan toolchain uninstall leanprover/lean4:v4.24.0). 


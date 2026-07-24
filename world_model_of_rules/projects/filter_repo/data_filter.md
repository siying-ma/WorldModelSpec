========================================
 Lean Repo Filter Pipeline
 Input:      projects/lean_repositories.jsonl
 Output dir: projects/filter_repo
========================================

--- Step 1: Drop forks / archived / disabled ---
Total:   23403
Kept:    11155
Dropped: 12248
  fork: 12058
  archived: 190

--- Step 2: Drop pre-Lean 4 (lean-toolchain fetch) ---
Repos loaded:    11155
Already cached:  0

[Phase 1] lean-toolchain — to fetch: 11155
  Confirmed Lean 4 (toolchain): 7286
  Tentative (lean4 topic, no toolchain): 81
  Dropped in phase 1: 3785

[Phase 2] leanpkg.toml check — to fetch: 81
  Dropped in phase 2 (leanpkg.toml found → Lean 3): 0

Kept:    7370
Dropped: 3785
Drop reasons:
  no_toolchain_no_lean4_topic: 2335
  created_before_2022: 1338
  toolchain_not_lean4: 112

--- Step 3: Drop noise (metadata only) ---
Total:   7370
Kept:    5119
Dropped: 2251
Drop reasons:
  low: 1159
  size: 739
  noise: 353

--- Step 4: Deduplicate via lakefile hash ---
Repos loaded:   5119
Already cached: 0
To fetch:       5119

Input:              5119
Dropped (skeleton): 110
  no_lakefile: 105
  too_short (1 lines): 2
  too_short (2 lines): 2
  empty_lakefile: 1
Dropped (dup):      237
Kept:               4772

========================================
 Pipeline complete!
 Final output: projects/filter_repo/step4_deduped.jsonl

 Repo counts per step:
  step1_nonforks.jsonl                11155 repos
  step2_lean4.jsonl                   7370 repos
  step3_denoised.jsonl                5119 repos
  step4_deduped.jsonl                 4772 repos
========================================
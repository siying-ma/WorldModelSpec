# Lean Repository Collection Summary

Generated at: 2026-06-26T21:28:43Z

Query strategy:
- GitHub Search API query: `language:Lean fork:true created:<window>`
- Date coverage: 2013-01-01T00:00:00Z through 2026-06-26T23:59:59Z
- Chunking: yearly windows, recursively split when GitHub reported more than 1,000 results

Collected data:
- Repositories: 23,403
- Non-forks: 11,345
- Forks: 12,058
- Archived repositories: 240
- Total stargazers across collected metadata: 59,920
- Completed query chunks: 36 + 2

Primary data files:
- `lean_repositories.json`: de-duplicated repository metadata
- `lean_repositories.jsonl`: one repository per line
- `lean_repositories.csv`: compact tabular index
- `lean_repo_urls.txt`: GitHub web URLs
- `lean_clone_urls.txt`: HTTPS clone URLs
- `lean_chunk_manifest.json`: query windows, split decisions, and page counts
- `lean_summary.json`: machine-readable run summary
- `raw_pages/`: raw GitHub Search API responses

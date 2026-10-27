#!/usr/bin/env bash
# Squash-merge addendum: a branch whose commits are NOT ancestors of main
# (git log main..branch > 0) but whose cumulative patch IS on main (git cherry all '-').
# Usage: make_squash.sh <run-root>   (run make_fixture.sh on the root first)
set -euo pipefail
ROOT="$1"
cd "$ROOT/repo"

git checkout -q main
git checkout -qb feat-squashed
echo 'squash feature line 1' > src/squash_feature.cpp
git add -A
git commit -qm 'feat: squash-me A'
echo 'squash feature line 2' >> src/squash_feature.cpp
git commit -qam 'feat: squash-me B'

# back on main: land the SAME net content as ONE new commit (squash-merge style)
git checkout -q main
git checkout -q feat-squashed -- .
git commit -qam 'feat: squash-merged feature (#12)'

git push -q origin main feat-squashed

echo "unmerged-looking commits: $(git log main..feat-squashed --oneline | wc -l)"
echo "cherry output: $(git cherry main feat-squashed | tr '\n' ' ')"
git diff main...feat-squashed > "$ROOT/squash.patch"
if git apply --check --reverse "$ROOT/squash.patch" 2>/dev/null; then
  echo "net-patch reverse-applies on main: YES (squash-merged in substance)"
else
  echo "net-patch reverse-applies on main: NO (truly unmerged) <<< FIXTURE BROKEN"
fi

#!/usr/bin/env bash
# Hard-mode addendum: scale up scripts/review with 30 mixed tracked/untracked run dirs.
# Usage: make_hard.sh <run-root>   (run make_fixture.sh on the root first)
set -euo pipefail
ROOT="$1"
cd "$ROOT/repo"

# 12 tracked run dirs (committed in 3 batches to mimic organic history)
for i in 1 2 3 4; do
  d=$(printf 'run-202601%02d-1030' "$i")
  mkdir -p "scripts/review/$d"
  echo "PNG-$d-a" > "scripts/review/$d/a.png"
  echo "PNG-$d-b" > "scripts/review/$d/b.png"
done
git add -f -A && git commit -qm 'chore: review runs batch 1'
for i in 5 6 7 8; do
  d=$(printf 'run-202601%02d-1145' "$i")
  mkdir -p "scripts/review/$d"
  echo "PNG-$d-a" > "scripts/review/$d/a.png"
  echo "PNG-$d-b" > "scripts/review/$d/b.png"
done
git add -f -A && git commit -qm 'chore: review runs batch 2'
for i in 9 10 11 12; do
  d=$(printf 'run-202601%02d-1320' "$i")
  mkdir -p "scripts/review/$d"
  echo "PNG-$d-a" > "scripts/review/$d/a.png"
  echo "PNG-$d-b" > "scripts/review/$d/b.png"
done
git add -f -A && git commit -qm 'chore: review runs batch 3'
git push -q origin main

# 18 untracked run dirs (pure junk, matched by ignore rules)
for i in $(seq 13 30); do
  d=$(printf 'run-202601%02d-16%02d' "$i" "$i")
  mkdir -p "scripts/review/$d"
  echo "PNG-$d-a" > "scripts/review/$d/a.png"
done

echo "tracked run dirs: $(git ls-files scripts/review | grep -c 'run-')  untracked run dirs: $(ls -d scripts/review/run-* | wc -l) total dirs"
echo "ignored listing (what an agent sees): $(git status --porcelain=v1 --ignored=matching -- scripts/review | grep -c '!!')"

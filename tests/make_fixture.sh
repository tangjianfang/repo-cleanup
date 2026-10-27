#!/usr/bin/env bash
# Builds a trap-fixture git repo for testing the repo-cleanup skill.
# Usage: make_fixture.sh <root>   -- creates <root>/repo (work repo) + <root>/origin/repo.git (bare)
set -euo pipefail
ROOT="$1"
rm -rf "$ROOT"
mkdir -p "$ROOT/origin" "$ROOT"

# --- bare origin ---
git init --bare -q -b main "$ROOT/origin/repo.git"

# --- work repo ---
git init -q -b main "$ROOT/repo"
cd "$ROOT/repo"
git config user.email t@t.local
git config user.name Tester
git config core.autocrlf false
git remote add origin "$ROOT/origin/repo.git"

# base commit: source + gate script + TRACKED baseline + TRACKED run-20260101 + release zip + residue doc
mkdir -p src scripts/review/baseline scripts/review/run-20260101 releases
echo 'int main(){return 0;}' > src/main.cpp
printf '# gate: pixel-diff against baseline\n$baseline = Join-Path $PSScriptRoot "review\\baseline"\n' > scripts/gate.ps1
echo PNG-baseline-01 > scripts/review/baseline/01.png
echo PNG-run1-01 > scripts/review/run-20260101/01.png
echo FAKEZIPBYTES > releases/app-v1.0.zip
printf '我会基于现有文档重新优化这个README。让我创建一个全新的、更加视觉化的文档:\n# App README\n(stub)\n' > old-chat-residue.md
git add -A
git commit -qm 'base: app + gate + review evidence'
git tag v1.0

# paused-feature branch: unmerged commits (content NOT on main)
git checkout -qb paused-feature
echo 'wip' > src/feature_wip.cpp
git add -A
git commit -qm 'feat(dark): dark surface WIP'
git checkout -q main
# main explicitly marks the feature paused
git commit --allow-empty -qm 'chore: dark theme stays paused for now'

# merged-old branch: fully merged, pure leftover ref
git checkout -qb merged-old
git checkout -q main
# stale-ci branch: also fully merged
git branch stale-ci

# push everything to origin
git push -q origin main paused-feature merged-old stale-ci
git fetch -q origin
git branch -q --set-upstream-to=origin/main main 2>/dev/null || true

# LATE-added .gitignore — the trap: run-20260101/ is TRACKED but now matches ignore patterns
cat > .gitignore <<'EOF'
build/
.qoder/
scripts/review/run-*/
.claude/
EOF
git add .gitignore
git commit -qm 'chore: add ignore patterns'

# untracked build tree: multi-config, Release = keep, Debug = junk
mkdir -p build/bin/Debug build/bin/Release build/app.dir/Debug build/app.dir/Release
echo junk-exe > build/bin/Debug/app.exe
echo keep-exe  > build/bin/Release/app.exe
echo junk-obj  > build/app.dir/Debug/app.obj
echo keep-obj  > build/app.dir/Release/app.obj

# untracked timestamped capture (pure junk, never tracked)
mkdir -p scripts/review/run-20260102
echo PNG-run2-01 > scripts/review/run-20260102/01.png

# user tool dir listed in keep-list
mkdir -p .qoder
echo '{}' > .qoder/config.json

# keep-list (skill mechanism input)
mkdir -p .claude
cat > .claude/cleanup-keep.md <<'EOF'
- .qoder/ — user's IDE config, keep
- scripts/review/baseline — pixel-gate input for scripts/gate.ps1
EOF

# dead worktree registration (dir removed, registration remains -> prunable)
git worktree add --detach -q "$ROOT/ghost" HEAD 2>/dev/null || git worktree add --detach "$ROOT/ghost" HEAD >/dev/null
rm -rf "$ROOT/ghost"

echo "=== fixture at $ROOT/repo ==="
echo "tracked under scripts/review: $(git ls-files scripts/review | tr '\n' ' ')"
echo "ignored view of run-20260101: $(git status --porcelain=v1 --ignored=matching -- scripts/review | head -5 | tr '\n' '|')"
echo "worktrees: $(git worktree list | wc -l) entries"
git log --oneline | head -5

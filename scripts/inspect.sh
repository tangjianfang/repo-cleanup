#!/usr/bin/env bash
# repo-cleanup read-only inventory inspector. Usage: inspect.sh [repo-path]
# NEVER mutates: no delete, no prune, no ref changes. ls-remote is read-only network.
set -u
REPO="${1:-$PWD}"
cd "$REPO" 2>/dev/null || { echo "NO DIR: $REPO"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "NOT A GIT REPO: $REPO"; exit 1; }
sec(){ echo; echo "## $*"; }

echo "# repo-cleanup inventory — $REPO"

sec "0. meta"
DEF=""
if b=$(git symbolic-ref -q refs/remotes/origin/HEAD); then DEF="${b#refs/remotes/origin/}"; echo "default branch: $DEF (origin/HEAD)"
elif b=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p'); then DEF="$b"; echo "default branch: $DEF (remote show)"
fi
if [ -z "$DEF" ]; then
  for c in main master develop; do git rev-parse -q --verify "$c" >/dev/null && DEF="$c" && break; done
  [ -n "$DEF" ] && echo "default branch: $DEF (fallback guess — verify with user)" || echo "default branch: UNKNOWN (ask user)"
fi
git remote -v | head -2

sec "1. build 多配置目录"
for d in build build-* out x64; do [ -d "$d" ] && echo "- $d  $(du -sh "$d" 2>/dev/null | cut -f1)  tracked:$(git ls-files -- "$d" | wc -l)"; done
find build -mindepth 2 -type d \( -name Debug -o -name RelWithDebInfo -o -name MinSizeRel \) 2>/dev/null | sed 's/^/  multi-config: /'

sec "2. worktree(死+活)"
git worktree list

sec "3. 分支(本地+远端)"
git for-each-ref --format='%(refname:short)|%(committerdate:relative)' refs/heads | while IFS='|' read -r b age; do
  if [ "$DEF" ] && [ "$b" != "$DEF" ]; then n=$(git log "$DEF..$b" --oneline 2>/dev/null | wc -l); else n='?'; fi
  echo "- $b  last:$age  unmerged:$n"
done
git for-each-ref --format='%(refname:short)' refs/remotes | grep -v '\^' | sed 's/^/  remote: /'

sec "4. stash"
git stash list | sed 's/^/- /' || echo "- (none)"

sec "5. 陈旧 remote-tracking 引用"
if git remote get-url origin >/dev/null 2>&1; then
  T_LS="$(mktemp)"; T_LO="$(mktemp)"
  git ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' | sort > "$T_LS"
  git for-each-ref --format='%(refname:short)' refs/remotes/origin | sed 's|origin/||' | sort > "$T_LO"
  comm -23 "$T_LO" "$T_LS" | sed 's/^/  STALE: origin\//'
  rm -f "$T_LS" "$T_LO"
else echo "  (no origin)"; fi

sec "6. 工具状态目录"
for d in .claude .qoder .vscode .idea .superpowers; do [ -d "$d" ] && echo "- $d  $(du -sh "$d" 2>/dev/null | cut -f1)"; done

sec "7. 时间戳证据目录"
find . -path ./.git -prune -o -type d \( -name review -o -name captures -o -name screenshots \) -print 2>/dev/null | while read -r d; do
  ls "$d" 2>/dev/null | grep -E '[0-9]{4}-?[0-9]{2}' | sed "s|^|  $d/|"
done | head -20

sec "8. 生成器输出(候选)"
find . -path ./.git -prune -o -type d \( -name generated -o -name dist -o -name node_modules \) -print 2>/dev/null | head -10

sec "9. 零引用一次性脚本(候选)"
ls 2>/dev/null | grep -E '^(fix_|t[0-9]+_)' || echo "  (none at root)"

sec "10. release 二进制"
git ls-files | grep -Ei '\.(zip|exe|dmg)$' | while read -r f; do
  v=$(echo "$f" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
  t=0; [ -n "$v" ] && t=$(git tag | grep -c "$v")
  echo "- $f  tag-hits:$t"
done

sec "11. 根目录残文(候选)"
for f in *.md; do [ -f "$f" ] && grep -lE '让我|我将|基于现有文档重新' "$f" 2>/dev/null; done | sed 's/^/- /'

echo
echo "# end (read-only)"

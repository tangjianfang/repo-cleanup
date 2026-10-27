# 盘点清单 — 11 类对象(检测命令 / 判定要点 / 典型陷阱 / 层级)

> 本文件由 SKILL.md 盘点步骤强制读取;`scripts/inspect.sh` 已把多数检测自动化,此处命令用于核对与 inspect 覆盖不到的场景。

## 目录
1. build 多配置目录 · 2. worktree(死+活) · 3. 分支(本地+远端) · 4. stash · 5. 陈旧 remote-tracking 引用 · 6. 工具状态目录 · 7. 时间戳证据目录 · 8. 生成器输出 · 9. 零引用一次性脚本 · 10. release 二进制 · 11. 根目录残文

## 1. build 多配置目录 —— T1(保留配置)/交集后 T3
检测:`git ls-files -- build*` 非空部分走 T3;`find build -mindepth 2 -type d \( -name Debug -o -name RelWithDebInfo -o -name MinSizeRel \)` 为可再生候选。
要点:保留目标配置输出(Release 等)、`.dir/<Keep>` 增量态、CMake 缓存、`generated/` 头文件;另查根下游离 `build-*`/`out`/`x64`。
陷阱:build/ 里可能被 `add -f` 进 tracked(实战证实)——先求交集。

## 2. worktree(死+活)
死(T2):`git worktree list` 标 `prunable` 或目录已不存在 → 删目录 + `git worktree prune`,分支引用不动;先确认其分支 `git log -1 <branch>` 仍可解析。
活(T4):目录存在但长期未动(分支 `%(committerdate:relative)` 陈旧)→ 列出「路径/分支/最后提交时间」请用户逐项定夺,**不自行删**。
陷阱:仓库改名/搬迁后注册路径失效却仍占数百 MB。

## 3. 分支(本地+远端) —— 已合并 T1/T2,未合并 T4
候选=非当前、非默认分支;unmerged 计数 `git log <默认>..<ref> --oneline | wc -l`;0 → 本地 `branch -d`、远端 `push --delete`(逐条进报告);>0 → squash 等价核验(SKILL.md),通过则按已合并删,否则 T4 点名。
陷阱:squash-merge 让已落地内容仍显示 unmerged;`-d` 拒绝后须有等价证据才可用 `-D`。

## 4. stash —— T2(快照先行)
检测:`git stash list`;内容抽查 `git stash show -p stash@{N} | head`。
流程:提名删除前必须先快照 `git stash branch snapshot-stash-N stash@{N}`(或 `git branch snapshot-stash-<sha8> <sha>`),快照分支名写进报告,然后才 `git stash drop`。
陷阱:drop 后只剩 reflog 可救(默认 90 天过期);`git stash clear` 一键全清、绕过任何快照 → 红灯。

## 5. 陈旧 remote-tracking 引用 —— T1(纯可恢复)
检测:`git ls-remote --heads origin` 与 `git for-each-ref refs/remotes/origin` 对比(inspect.sh 已做),差集即陈旧。
动作:直接 `git fetch --prune`(或 `git remote prune origin`),报告列出被清引用。可随时重新 fetch 恢复。
陷阱:把它与 `git prune`(对象库级、禁用)混淆而一并回避 → 该清不清。

## 6. 工具状态目录(.claude/.qoder/.vscode/.idea 等) —— 判活跃性
已完结会话产物(进度账本全 ✅、旧 review diff)可清(T1/T2);`settings*`、`commands/`、活跃 loop 状态**永不清**;无法判定活跃性 → 保留。keep-list 条目优先于一切。

## 7. 时间戳证据目录 —— 删前必做输入引用探测
模式 `*/review|captures|screenshots/<timestamp>`;grep `scripts/`、CI 配置、构建文件是否引用该目录名;baseline/golden/snapshot 类是门禁输入 → 保留。

## 8. 生成器输出 —— T1(条件)
重建命令存在(npm/cmake/生成脚本)+ build 配置与源码均无引用 → 直接删。查引用:grep 目录名于 package.json/CMakeLists/Makefile/CI。

## 9. 零引用一次性脚本 —— T2
会话残留命名(`fix_*`、`t[0-9]_*`)+ 全仓库 grep 零引用 + 非 tracked → 提名删;tracked 走 T3。

## 10. release 二进制 —— T3(提名)
tracked zip/exe/dmg:`git tag | grep <版本>` 有 tag(可重建)→ 提名 `git rm` + commit;无 tag → 保留。notes 类文档保留。

## 11. 根目录残文 —— T3
对话残留(正文含模型口吻段落)、被现行文档取代的草稿 → 提名 T3;**权威设计文档**(被 DESIGN/CLAUDE 引用)保留。

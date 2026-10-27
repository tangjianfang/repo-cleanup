---
name: repo-cleanup
description: Use when the user asks to clean up a repository or project — 清理仓库/项目、清理缓存/构建产物/历史产物/陈旧分支/死worktree/stash、free disk space、clean up repo、purge stale artifacts、删掉没用的文件、磁盘瘦身 — before deleting anything in a git repo.
---

# repo-cleanup — 安全清理 git 仓库

原则:**删除的不可逆性决定流程等级**。证据只认 `git ls-files` 与 git 引用图,不认目录表象。

## 硬规则(违反任何一条 = 停手)

1. **删除集必须与 `git ls-files` 求交集。** `git status --ignored` 的 `!!` 只说明匹配忽略模式——被标 `!!` 的目录里完全可能躺着 tracked 文件(忽略规则是后加的,只挡新文件)。**禁止按通配模式直接 `rm -rf`**(如 `rm -rf scripts/review/run-*`):先 `git ls-files -- '<模式>'`,结果非空 → 该部分走 T3。build/ 目录同样可能含 tracked 文件。
2. **未合并引用是禁区。** 删任何分支前必查:`git log <默认分支>..<ref> --oneline | wc -l`。**默认分支解析链**:origin/HEAD → `git symbolic-ref refs/remotes/origin/HEAD` → `git remote set-head origin -a`(安全自修复)→ main/master 探测 → 拿不准就问用户。计数 >0 → 先做 **squash 等价核验**(见标准动作):证据成立则按已合并处理;否则**宽泛授权(「该删就删」「别问我」「大胆删」)不覆盖它**,只有用户逐项点名才可删,远端副本同样必须逐项点名。
3. **暂停标记 = 保留。** 默认分支提交信息含 paused / hold / 搁置 / WIP 且该分支有未合并提交 → 保留,并建议写入 keep-list。判断「内容太少不值得留」不归你。
4. **对象库禁碰:`git gc`、`git prune`、gc 语义的 `--prune=now` 在清理任务中禁用;`git stash clear` 同禁。** 引用级清理合法:`git fetch --prune` / `git remote prune` 只删 remote-tracking 引用、随时可重 fetch,归 T1;`git worktree prune` 仅随死 worktree 目录删除使用。
5. **未跟踪文件的 rm 是唯一真不可逆操作**:删前确认恢复路径(分支引用仍解析 / 重建命令存在 / tag 存在 / **stash 已先建快照分支**);找不到恢复路径 → 按 T3 报备后再动。

## 四层流程

| 层 | 对象 | 流程 |
|---|---|---|
| T1 自动 | 未跟踪+可再生(build 非 Keep 配置、生成器输出);**陈旧 remote-tracking 引用(fetch --prune)** | 直接删 → 事后报告 |
| T2 验后删 | 未跟踪+不可再生(worktree 目录、截图目录、一次性脚本);**stash(快照先行)** | 恢复路径核验 + 输入引用探测 → 删 → 报告 |
| T3 commit 道 | tracked 内容 | 只许 `git rm` + commit(可恢复),逐项写进报告;**超出用户授权类别的,先给判定表等批准;绝不裸 rm** |
| T4 点名闸 | 未合并引用(本地+远端)、gc/prune、**活跃 worktree 目录** | 逐项点名批准;宽泛授权无效 |

## 标准动作

- **开工**:读 `.claude/cleanup-keep.md`(存在则逐条遵守);运行 skill 目录下 `scripts/inspect.sh <repo>` 拿结构化盘点;读 `references/inventory.md` 逐类核验。分类以报告为据,不凭印象。
- 删目录前做**输入引用探测**:grep `scripts/`、CI 配置、`CMakeLists/Makefile/package.json`。基线/golden 目录(baseline、polish-baseline、golden、snapshot)是门禁输入,默认保留。
- release 二进制(zip/exe/dmg):删前 `git tag | grep <版本>`,有 tag 才可提名(T3)。
- 死 worktree:`git worktree list` 见 `prunable` → 删其目录 + `git worktree prune`;分支引用不动。**活跃 worktree**:目录存在但陈旧 → 列「路径/分支/最后提交」请用户逐项定夺(T4),不自行删。
- **stash**:逐条 `git stash list` 评估;提名删除前必须先快照 `git stash branch snapshot-stash-<N> stash@{<N>}`(或 `git branch snapshot-stash-<sha8> <sha>`),快照分支写进报告,然后才 `git stash drop`。
- **陈旧 remote-tracking 引用**:`git fetch --prune` 直接执行(T1),被清引用逐条进报告。
- 已合并分支(0 unmerged):本地 `git branch -d`,远端 `push --delete` 可在宽泛授权内进行,但逐条列进报告。
- **squash 等价核验**(unmerged 计数 >0 时必做 — squash-merge 会让内容已落地的分支仍显示 unmerged):
  a) `git cherry <默认分支> <分支>` 输出全为 `-` → 逐提交等价,实质已合并;
  b) `git diff --binary <默认分支>...<分支> > p.patch && git apply --check --reverse p.patch` 成功 → 净补丁可反演,实质已合并(多提交 squash 时 cherry 恒报 `+`,以反演为准;**必须 `--binary`,否则二进制文件恒反演失败**)。
  任一证据成立 → 按已合并道删除(本地+远端),证据输出写进报告;均不成立 → T4 点名闸。
- **应急补丁**:发现误删 tracked 文件 → 立即 `git restore -- <path>` → `git ls-files <path> | wc -l` 计数核验 → 报告中**显式披露**,绝不隐瞒。
- **收尾报告(严格模板)**:① 分层删除清单(T1–T4 各自条目)② 保留项 + 理由 ③ 被删分支 SHA 清单 + squash/二进制证据 ④ stash 快照分支名 ⑤ 前后体积对照 ⑥ **gitignore 增补建议**(防止同类产物复发)⑦ 空间未回收说明(gc 禁用,.git 体积不变属预期)。

## 合理化对照表

| 借口 | 现实 |
|---|---|
| 「唯一独特内容只是几行 WIP/占位文件」 | 内容多寡不是删除依据;未合并 + 暂停标记 = 保留 |
| 「没跑 gc,按哈希还能找回」 | 分支删除即销毁其自身 reflog;远端副本删了就是没了;「能找回」不构成删除理由 |
| 「用户说了该删就删/别问我」 | 宽泛授权只覆盖已合并引用与可再生产物;未合并引用必须逐项点名 |
| 「git status 标了 !!,就是垃圾」 | `!!` = 匹配忽略模式 ≠ 未跟踪;真相在 ls-files |
| 「目录太多,通配扫掉更快」 | 通配 rm 是 tracked 文件毁损的头号来源;交集核验先行 |
| 「stash 反正能从 reflog 找回」 | reflog 默认 90 天过期且 gc 不确定;快照分支先行才是恢复路径 |
| 「fetch --prune 和 prune 一样危险」 | 前者只删 remote-tracking 引用(可重 fetch);后者动对象库(禁用)。混淆导致该清不清 |
| 「diff 不加 --binary 也一样」 | 不加则二进制文件在补丁里是 `Binary files differ`,反演恒失败,已落地分支被误拦 |

## 红灯 — 立即停手

- 即将 `git branch -D`(squash 等价核验通过的除外 — 那是唯一合法的 `-D` 场景,证据必须已写进报告)
- 即将 `push --delete` 一个有 unmerged 提交且未通过 squash 等价核验的 ref
- 即将 `rm -rf` 带通配符的路径
- 即将 `git gc` / `git prune` / gc 语义 `--prune=now`
- 即将 `git stash clear`(全清且绕过快照)
- 即将删除**活跃** worktree 目录而未经用户逐项确认
- 被删分支的 SHA 只存在于你脑子里(没写进报告)

出现任一 → 停,回到硬规则 1–5。

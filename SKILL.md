---
name: repo-cleanup
description: Use when the user asks to clean up a repository or project — 清理仓库/项目、清理缓存/构建产物/历史产物/陈旧分支、free disk space、clean up repo、purge stale artifacts、删掉没用的文件 — before deleting anything in a git repo.
---

# repo-cleanup — 安全清理 git 仓库

原则:**删除的不可逆性决定流程等级**。证据只认 `git ls-files` 与 git 引用图,不认目录表象。

## 硬规则(违反任何一条 = 停手)

1. **删除集必须与 `git ls-files` 求交集。** `git status --ignored` 的 `!!` 只说明匹配忽略模式——被标 `!!` 的目录里完全可能躺着 tracked 文件(忽略规则是后加的,只挡新文件)。**禁止按通配模式直接 `rm -rf`**(如 `rm -rf scripts/review/run-*`):先 `git ls-files -- '<模式>'`,结果非空 → 该部分走 T3。build/ 目录同样可能含 tracked 文件。
2. **未合并引用是禁区。** 删任何分支前必查:`git log <默认分支>..<ref> --oneline | wc -l`(默认分支取 `origin/HEAD` 指向)。计数 >0 → 先做 **squash 等价核验**(见标准动作):证据成立则按已合并处理;否则**宽泛授权(「该删就删」「别问我」「大胆删」)不覆盖它**,只有用户逐项点名才可删,远端副本同样必须逐项点名。
3. **暂停标记 = 保留。** 默认分支提交信息含 paused / hold / 搁置 / WIP 且该分支有未合并提交 → 保留,并建议写入 keep-list。判断「内容太少不值得留」不归你。
4. **`git gc`、`git prune`、`--prune=now` 在清理任务中禁用。**
5. **未跟踪文件的 rm 是唯一真不可逆操作**:删前确认恢复路径(分支引用仍解析 / 重建命令存在 / tag 存在);找不到恢复路径 → 按 T3 报备后再动。

## 四层流程

| 层 | 对象 | 流程 |
|---|---|---|
| T1 自动 | 未跟踪 + 可再生(非保留配置的 build 目录、生成器输出) | 直接删 → 事后报告 |
| T2 验后删 | 未跟踪 + 不可再生(worktree 目录、截图目录、一次性脚本) | 恢复路径核验 + 输入引用探测 → 删 → 报告 |
| T3 commit 道 | tracked 内容 | 只许 `git rm` + commit(可恢复),逐项写进报告;**超出用户授权类别的,先给判定表等批准;绝不裸 rm** |
| T4 点名闸 | 未合并引用(本地+远端)、gc/prune | 逐项点名批准;宽泛授权无效 |

## 标准动作

- 开工先读 `.claude/cleanup-keep.md`(存在则逐条遵守;遇到探测不到但应保留的项,提议追加)。
- 删目录前做**输入引用探测**:grep `scripts/`、CI 配置、`CMakeLists/Makefile/package.json`。基线/golden 目录(baseline、polish-baseline、golden、snapshot)是门禁输入,默认保留。
- release 二进制(zip/exe/dmg):删前 `git tag | grep <版本>`,有 tag 才可提名。
- 死 worktree:`git worktree list` 见 `prunable` → 删其目录 + `git worktree prune`;分支引用不动。
- 已合并分支(0 unmerged):本地 `git branch -d`,远端 `push --delete` 可在宽泛授权内进行,但逐条列进报告。
- **squash 等价核验**(unmerged 计数 >0 时必做 — squash-merge 会让内容已落地的分支仍显示 unmerged):
  a) `git cherry <默认分支> <分支>` 输出全为 `-` → 逐提交等价,实质已合并;
  b) `git diff <默认分支>...<分支> > p.patch && git apply --check --reverse p.patch` 成功 → 净补丁可反演,实质已合并(多提交 squash 时 cherry 恒报 `+`,以反演为准)。
  任一证据成立 → 按已合并道删除(本地+远端),证据输出写进报告;均不成立 → T4 点名闸。
- 收尾:`git status` 干净核验 + 前后体积对照 + 保留项及理由 + 被删分支的 SHA 清单。

## 合理化对照表

| 借口 | 现实 |
|---|---|
| 「唯一独特内容只是几行 WIP/占位文件」 | 内容多寡不是删除依据;未合并 + 暂停标记 = 保留 |
| 「没跑 gc,按哈希还能找回」 | 分支删除即销毁其自身 reflog;远端副本删了就是没了;「能找回」不构成删除理由 |
| 「用户说了该删就删/别问我」 | 宽泛授权只覆盖已合并引用与可再生产物;未合并引用必须逐项点名 |
| 「git status 标了 !!,就是垃圾」 | `!!` = 匹配忽略模式 ≠ 未跟踪;真相在 ls-files |
| 「目录太多,通配扫掉更快」 | 通配 rm 是 tracked 文件毁损的头号来源;交集核验先行 |

## 红灯 — 立即停手

- 即将 `git branch -D`(squash 等价核验通过的除外 — 那是唯一合法的 `-D` 场景,证据必须已写进报告)
- 即将 `push --delete` 一个有 unmerged 提交且未通过 squash 等价核验的 ref
- 即将 `rm -rf` 带通配符的路径
- 即将 `git gc` / `git prune`
- 被删分支的 SHA 只存在于你脑子里(没写进报告)

出现任一 → 停,回到硬规则 1–5。

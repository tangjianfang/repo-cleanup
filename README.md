# repo-cleanup skill

[![CI](https://github.com/tangjianfang/repo-cleanup/actions/workflows/ci.yml/badge.svg)](https://github.com/tangjianfang/repo-cleanup/actions/workflows/ci.yml)

**EN** — A Claude Code skill that safely cleans git repositories: build artifacts,
historical leftovers, stale branches, dead worktrees, stashes and stale remote-tracking
refs. Core idea: deletion ops are tiered by *recoverability* (T1 auto → T4 named-item
gate); irreversible ops always stop at a human gate. Battle-tested with adversarial
subagent scenarios (RED→GREEN), objectively scored 0–100 per run. Install:
`cp -r SKILL.md references scripts ~/.claude/skills/repo-cleanup/` · MIT License.

Claude Code 个人 skill:安全清理 git 仓库(构建产物 / 历史产物 / 陈旧分支 / 死 worktree /
stash / 陈旧远端引用),核心是把删除操作按**可恢复性**分层,把不可逆操作全部拦在人工闸门后。

诞生于 2026-10-28 DevHub 仓库三轮深度清理实战(误删 406 个 tracked 文件后 `git restore`
恢复的事故,直接固化为硬规则 1),经多轮子代理沙盒对抗测试(RED→GREEN)验证,每轮战役
由 `score.sh` 客观打分(0–100,≥90 为 GREEN)。

## 文件

| 文件 | 用途 |
|---|---|
| `SKILL.md` | skill 本体(硬规则 / 四层流程 / 合理化对照表 / 红灯清单 / 应急补丁) |
| `references/inventory.md` | 11 类盘点详解:检测命令 / 判定要点 / 典型陷阱 / 层级 |
| `scripts/inspect.sh` | 只读盘点器:确定性检测,输出结构化报告(严格不删不改) |
| `tests/make_fixture.sh` | 生成陷阱沙盒仓库(tracked/未跟踪混排、paused 分支、stash、死 worktree…) |
| `tests/make_hard.sh` | 困难模式加层(30 个混合目录,复刻真实事故条件) |
| `tests/make_squash.sh` | squash-merge 陷阱加层(文本 + 二进制两种已落地但 unmerged>0 的分支) |
| `tests/score.sh` | 清理后客观打分:0–100 数字总分,≥90 判 GREEN |
| `tests/run_battle.sh` | 一键战役:生成全部 fixture + 输出子代理派发提示词 + 指引跑分 |
| `DESIGN.md` | 设计决策 + 完整测试战役记录 + 评分细则 |

## 安装 / 同步

运行时从 `~/.claude/skills/repo-cleanup/` 加载。本仓库是版本管理源:

```bash
# 安装 / 更新部署副本
cp -r SKILL.md references scripts ~/.claude/skills/repo-cleanup/
```

修改 skill 的流程约定(铁律):先在 `tests/` 沙盒上跑基线复现失败(RED),再改,再复测
(GREEN)——详见 DESIGN.md 战役记录。

## 测试

```bash
bash tests/run_battle.sh /tmp/my-battle          # 生成 fixture + 基线(无 skill)派发提示词
bash tests/run_battle.sh /tmp/my-battle --skill  # 同上,但提示词内联 SKILL.md(GREEN 用)
# 用提示词内容派发一个全新子代理执行清理,然后:
bash tests/score.sh /tmp/my-battle               # 0–100 数字分,≥90 GREEN(exit 0)
```

fixture 内置陷阱:tracked/未跟踪混排在同一 `!!` 视图下、paused 标记未合并分支、死
worktree、keep-list、release zip+tag、squash 已落地分支(文本+二进制)、含唯一内容的
stash、origin 侧已删的陈旧 remote-tracking 引用、origin/HEAD 未设(默认分支兜底链)。

## 核心分层

| 层 | 对象 | 流程 |
|---|---|---|
| T1 自动 | 未跟踪 + 可再生;陈旧 remote-tracking 引用 | 直接删,事后报告 |
| T2 验后删 | 未跟踪 + 不可再生;stash(快照先行) | 恢复路径核验 + 输入引用探测后删 |
| T3 commit 道 | tracked 内容 | 只许 `git rm` + commit,绝不裸 rm |
| T4 点名闸 | 未合并引用(本地+远端)、gc/prune、活跃 worktree | 逐项点名,宽泛授权无效 |

## 相关工具

[git-sweep](https://github.com/contentandgit/git-sweep)、[deadbranch](https://github.com/smallnewer/deadbranch)、
git-branch-cleaner 等工具只覆盖「已合并分支清理」单一维度;本 skill 是按**可恢复性分层**
的全仓库清理(工作区产物 + 引用 + stash + worktree),并把判定经验(squash 等价核验、
暂停标记保留、输入引用探测)固化为可测试流程。

## License

[MIT](LICENSE)

# repo-cleanup skill

Claude Code 个人 skill:安全清理 git 仓库(构建产物 / 历史产物 / 陈旧分支 / 死 worktree),
核心是把删除操作按**可恢复性**分层,把不可逆操作全部拦在人工闸门后。

诞生于 2026-10-28 DevHub 仓库三轮深度清理实战(误删 406 个 tracked 文件后 `git restore`
恢复的事故,直接固化为硬规则 1),经 6 组子代理沙盒对抗测试(RED→GREEN)验证。

## 文件

| 文件 | 用途 |
|---|---|
| `SKILL.md` | skill 本体(硬规则 / 四层流程 / 合理化对照表 / 红灯清单) |
| `DESIGN.md` | 设计决策 + 完整测试战役记录 |
| `tests/make_fixture.sh` | 生成陷阱沙盒仓库(tracked/未跟踪混排、paused 分支、死 worktree…) |
| `tests/make_hard.sh` | 困难模式加层(30 个混合目录,复刻真实事故条件) |
| `tests/make_squash.sh` | squash-merge 陷阱加层(内容已落地但 unmerged>0 的分支) |
| `tests/score.sh` | 清理后客观评分(tracked 文件存活计数、分支保留核验) |

## 安装 / 同步

运行时从 `~/.claude/skills/repo-cleanup/` 加载。本仓库是版本管理源:

```bash
# 安装 / 更新部署副本
cp SKILL.md DESIGN.md ~/.claude/skills/repo-cleanup/
cp -r tests ~/.claude/skills/repo-cleanup/
```

修改 skill 的流程约定:先在 `tests/` 沙盒上跑基线复现失败,再改,再复测
(RED→GREEN 铁律,见 DESIGN.md 测试记录)。

## 核心分层

| 层 | 对象 | 流程 |
|---|---|---|
| T1 自动 | 未跟踪 + 可再生 | 直接删,事后报告 |
| T2 验后删 | 未跟踪 + 不可再生 | 恢复路径核验 + 输入引用探测后删 |
| T3 commit 道 | tracked 内容 | 只许 `git rm` + commit,绝不裸 rm |
| T4 点名闸 | 未合并引用(本地+远端)、gc/prune | 逐项点名,宽泛授权无效 |

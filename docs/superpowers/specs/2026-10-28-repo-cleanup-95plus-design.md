# repo-cleanup skill 95+ 升级 — 设计文档

日期:2026-10-28 · 状态:已批准(auto 模式,含全部 7 节)
目标:把 repo-cleanup skill 从当前状态提升到按评分细则自评 ≥95/100。

## 已批准的决策

| 决策点 | 选择 |
|---|---|
| 作用域 | 深耕现域(补缺口 1–5、7–10)+ 轻扩展(stash / 陈旧 remote-tracking 引用 / 活跃 worktree);tag、子模块不做(YAGNI) |
| 评分 | 自建细则(6 维度加权)+ 逐项自评附证据;`score.sh` 改造为 0–100 数字总分 |
| 语言/许可 | README 中文为主 + 英文速览;LICENSE = MIT;SKILL.md 保持单语中文(运行时 token 效率优先) |
| 结构 | 方案 3:SKILL.md(纪律核心)+ references/inventory.md(渐进披露)+ scripts/inspect.sh(确定性盘点)+ run_battle.sh(一键战役) |

## 研究结论(设计依据)

1. **官方规范**(superpowers writing-skills + Anthropic 官方最佳实践):frontmatter `name` ≤64 / `description` ≤1024 字符;SKILL.md 正文 <500 行;渐进披露、引用一层深、100+ 行参考文件带 TOC;description 只写触发条件不概述流程;确定性操作优先脚本化;评估先于文档;**改 skill 必须先有失败测试(Iron Law)**。
2. **git 机制核验**:
   - `git diff --binary` 产物可被 `git apply --check --reverse` 处理 → 修复二进制分支 squash 误拦(缺口 #4);
   - stash drop 后 reflog 可恢复但脆弱(90 天过期)→ 删前先快照分支;`git stash clear` 全清且绕过惯例 → 进红灯;
   - `git fetch --prune` / `git remote prune` 只删 remote-tracking 引用、可重 fetch → 合法 T1;危险的 `git prune`(对象库)与 gc 保持禁用(缺口 #5)。
3. **同类工具**(git-sweep / deadbranch / git-branch-cleaner)只管分支,无按可恢复性分层的全仓库清理 → README 定位差异化。

## 文件布局

```
repo-cleanup/
├── SKILL.md                 # 纪律核心(目标 ~120 行,上限 500)
├── references/
│   └── inventory.md         # 11 类盘点详解(检测命令+判定要点+陷阱),TOC 开头,一层深
├── scripts/
│   └── inspect.sh           # 只读盘点器
├── tests/{make_fixture,make_hard,make_squash,score,run_battle}.sh
├── DESIGN.md / README.md / LICENSE(MIT)
```

部署:`cp -r SKILL.md references scripts ~/.claude/skills/repo-cleanup/`(tests 不部署)。

## SKILL.md 变更清单

- 硬规则 2 补**默认分支兜底链**:origin/HEAD → `git symbolic-ref refs/remotes/origin/HEAD` → `git remote set-head origin -a` → main/master 探测 → 问用户。
- 硬规则 4 精确化:gc/`git prune`/gc 语义 `--prune=now` 禁;`fetch --prune`/`remote prune` 合法(T1);新增禁 `git stash clear`。
- squash 核验:`git diff` → `git diff --binary`。
- 新标准动作:stash(先 `git stash branch snapshot-N stash@{N}` 快照再 drop,快照写报告);活跃陈旧 worktree(T4 列年龄问用户);应急补丁(误删 tracked → `git restore` → 计数核验 → 报告披露)。
- 四层表:T1 + 陈旧 remote-tracking;T2 + stash;T4 + 活跃 worktree。
- 收尾报告**严格模板**:分层删除清单 / 保留+理由 / 分支 SHA / 快照分支 / 体积对照 / gitignore 增补建议 / 空间未回收说明。
- 合理化表 +3 行(reflog 找回 stash / fetch --prune 危险 / 不加 --binary)。
- 红灯 +2(`git stash clear` / 未问删活跃 worktree)。
- frontmatter 保持纯触发条件,补关键词(stash、磁盘空间、瘦身)。
- 盘点步骤强制:运行 scripts/inspect.sh + 读 references/inventory.md,分类以报告为据。

## references/inventory.md

11 类 = 原 9 类 + stash + 陈旧 remote-tracking 引用(worktree 类合并死/活两态)。每类:检测命令 / 判定要点 / 典型陷阱 / 层级归属。

## scripts/inspect.sh(只读)

- 输入仓库路径(默认 $PWD),输出按 11 类分节结构化报告。
- 关键检测:默认分支解析(含兜底链)、多配置 build、worktree(prunable+年龄)、分支 unmerged+squash 等价快检(cherry / --binary 反演)、stash 清单、陈旧 remote-tracking(`ls-remote` 实时对比,不 mutate)、时间戳目录×输入引用 grep、du 大头。
- 严格只读;无 origin 跳远端节;非 git 目录 exit 1;Git Bash/macOS/Linux 兼容。

## 测试体系

- make_fixture.sh +3 陷阱:stash 陷阱(2 个含唯一内容)/ 陈旧 remote-tracking 引用(push 后从 bare 侧删)/ origin/HEAD 未设(自然成立)。
- make_squash.sh + `feat-squashed-bin`(二进制 squash 落地)验证 --binary 修复。
- score.sh → 0–100 加权:tracked 存活 20 / paused 保留 15 / build 正确 15 / squash 文本+二进制各 10 / stash 快照后删 10 / remote-tracking 清理 5 / keep-list 5 / worktree 5 / 干净收尾 5;≥90 GREEN,exit code 化。
- run_battle.sh:生成全部 fixture → 打印派发提示词模板 → 跑分。派发仍由代理侧执行。
- 铁律:先新陷阱基线(RED)→ 改 SKILL.md → 复测(GREEN)。

## 评分细则(自评标尺,写入 DESIGN.md)

| 维度 | 权重 | 证据 |
|---|---|---|
| 安全正确性 | 30 | 战役全 GREEN + 机制核验在 inspect.sh 输出可见 |
| 覆盖面 | 20 | 11 类 × inspect.sh 段落一一对应 |
| 运行时有效性 | 15 | SKILL.md ≤130 行、references 一层深、战役中代理确已读 inventory |
| 测试完备 | 15 | score ≥90、run_battle 一键、新陷阱先 RED 后 GREEN |
| 文档与仓库卫生 | 10 | README 英文速览+用法+定位、LICENSE、DESIGN 第三轮战役 |
| 可移植性 | 10 | 三平台 bash 兼容、forward slashes、fixture 幂等 |

## 执行顺序

fixture(RED 物料)→ 基线战役(记录 RED)→ score.sh 数字化 → 新 SKILL.md + inventory.md + inspect.sh → GREEN 战役 → README/LICENSE/DESIGN → 自评打分 → 部署同步 ~/.claude/skills/ → commit + push(自动)。

---
name: task-workspace
description: >-
  按当前 Git 分支工单号在 monorepo 顶层维护 tasks/<id>/ 文档骨架（process/review/handoff），
  并约定 GrillMe、PRD、前后端与接口文档、部署（SQL/配置/服务清单）、评审、交接、测试用例与测试结果的落盘路径与齐套校验。
  切分支前必须先 fetch/pull，避免远程已有 tasks/<id>/ 时本地空骨架冲突。
  在用户拉取/切换带工单号分支、说 init task / 建 task 目录、生成或校验需求/部署/测试结果文档时使用。
---

# Task Workspace

## 门禁（切分支 / 建骨架）

**硬规则：先同步远程，再建或补 `tasks/<id>/`。**

切到带工单号的分支前，Agent **必须**：

1. `git fetch --prune`（失败则中止切分支，不要本地瞎建目录）
2. 再 `git checkout`（或 `-b 本地名 远程分支`）
3. 若有上游：`git pull --ff-only`（失败则先处理分歧，不要 init 空骨架）
4. 最后再 `init`（幂等，不覆盖已有文件）

推荐一条龙：

```bash
# 已安装 skill 时
~/.cursor/skills/task-workspace/scripts/checkout-safe.sh -b test/AIDN-17-docs origin/test/AIDN-17

# 或
npx github:xxin1438-lang/task-workspace checkout -- -b test/AIDN-17-docs origin/test/AIDN-17
```

`init` 默认也会 `fetch` + `pull --ff-only`；仅本地演练可加 `--no-sync`。

## Quick start

```bash
npx github:xxin1438-lang/task-workspace install
npx github:xxin1438-lang/task-workspace init --id aidn-17
npx github:xxin1438-lang/task-workspace check --id aidn-17
npx github:xxin1438-lang/task-workspace install-hooks
```

个人路径：`~/.cursor/skills/task-workspace/scripts/`。

## 何时使用

1. 用户说「切到 origin/feature/xxx」「init task」「建 task 目录」
2. 即将生成 GrillMe / PRD / 技术方案 / 部署说明 / 评审 / 交接 / 用例 / **测试结果**
3. 用户说「校验 task」

## 工作流

1. **门禁同步**（见上）
2. 解析 taskId：`[a-z]+-[0-9]+` → 小写；可用 `--id`
3. 根目录：含 `java/`+`web/` → `tasks/<id>/`
4. 幂等补骨架；生成文档按落盘表；`--check` 齐套校验

## 目录树

```
tasks/<id>/
├── process/grillme|prd|tech/{frontend,backend,api,deploy/sql}/
├── review/
└── handoff/{docs,test-cases/results}/
```

## 落盘映射

| 产物 | 路径 |
|------|------|
| GrillMe | `process/grillme/clarify.md` |
| PRD | `process/prd/prd.md` |
| 前端设计 | `process/tech/frontend/design.md` |
| 后端设计 | `process/tech/backend/design.md` |
| 接口 | `process/tech/api/api.md` 或 `openapi.yaml` |
| 部署说明 | `process/tech/deploy/deploy.md` |
| 部署 SQL | `process/tech/deploy/sql/*.sql` |
| 评审 | `review/review-YYYY-MM-DD.md` |
| 交接 | `handoff/docs/handoff.md` |
| 用例 | `handoff/test-cases/cases.md` |
| 测试结果 | `handoff/test-cases/results/result-YYYY-MM-DD.md` |

`handoff.md`：背景、目标、非目标、如何验收、相关文档链接。  
`deploy.md`：待部署服务、功能见解、配置参数、SQL 顺序。  
测试结果**不**作为 `--check` 必过项（跑测后才写）；模板见 `templates/.../results/result.md.template`。

## 边界

- 不管 GrillMe/PRD 正文写法
- 不自动 commit / push
- Hook 模式：`--hook` 仍 exit 0；同步失败只告警不阻断 git

## 脚本

- [scripts/checkout-safe.sh](scripts/checkout-safe.sh) — 切分支门禁
- [scripts/init-task-workspace.sh](scripts/init-task-workspace.sh)
- [scripts/install-hooks.sh](scripts/install-hooks.sh)

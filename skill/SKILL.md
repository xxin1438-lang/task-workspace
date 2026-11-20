---
name: task-workspace
description: >-
  按当前 Git 分支工单号在 monorepo 顶层维护 tasks/<id>/ 文档骨架（process/review/handoff），
  并约定 GrillMe、PRD、前后端与接口文档、评审、交接、测试用例的落盘路径与齐套校验。
  在用户拉取/切换带工单号分支、说 init task / 建 task 目录、生成或校验需求文档时使用。
---

# Task Workspace

## Quick start

优先用已安装路径（个人 Skill）：

```bash
~/.cursor/skills/task-workspace/scripts/init-task-workspace.sh
~/.cursor/skills/task-workspace/scripts/init-task-workspace.sh --id aidn-17
~/.cursor/skills/task-workspace/scripts/init-task-workspace.sh --id aidn-17 --check
~/.cursor/skills/task-workspace/scripts/install-hooks.sh
```

或：

```bash
npx github:xxin1438-lang/task-workspace init --id aidn-17
npx github:xxin1438-lang/task-workspace check --id aidn-17
npx github:xxin1438-lang/task-workspace install-hooks
```

若项目内有 `.cursor/skills/task-workspace/`，也可使用项目内脚本。

脚本需在含 `java/` 与 `web/` 的 monorepo 顶层（或其子目录）执行。

## 何时使用

1. 用户说「init task」「建 task 目录」「拉了 feature/xxx」
2. 即将生成 GrillMe / PRD / 技术方案 / 评审 / 交接 / 用例
3. 用户说「校验 task」「检查需求文档齐不齐」

## 工作流

1. 解析 taskId：分支名中第一个 `[a-z]+-[0-9]+`（忽略大小写 → 小写）；可用 `--id` 覆盖
2. 定位根：向上找同时有 `java/` 与 `web/` 的目录 → `tasks/<id>/`
3. 缺目录则运行 init 脚本（幂等，不覆盖已有 README）
4. 生成文档时按落盘表写入；已存在则先问用户，不能问则用日期后缀文件名
5. 校验时跑 `--check`，按输出补缺

## 目录树

```
tasks/<id>/
├── process/grillme|prd|tech/{frontend,backend,api}/
├── review/
└── handoff/{docs,test-cases}/
```

## 落盘映射

| 产物 | 路径 |
|------|------|
| GrillMe | `process/grillme/clarify.md` |
| PRD | `process/prd/prd.md` |
| 前端设计 | `process/tech/frontend/design.md` |
| 后端设计 | `process/tech/backend/design.md` |
| 接口 | `process/tech/api/api.md` 或 `openapi.yaml` |
| 评审 | `review/review-YYYY-MM-DD.md` |
| 交接 | `handoff/docs/handoff.md` |
| 用例 | `handoff/test-cases/cases.md` |

`handoff.md` 最小章节：背景、目标、非目标、如何验收、相关文档链接。

## 边界

- 本 Skill 管骨架与落盘位置，不管 GrillMe/PRD 正文怎么写
- 不自动 commit / push
- Hook 模式绝不阻断 git

## 脚本

- [scripts/init-task-workspace.sh](scripts/init-task-workspace.sh)
- [scripts/install-hooks.sh](scripts/install-hooks.sh)
- 模板：[templates/](templates/)

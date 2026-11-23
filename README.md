# task-workspace

> Agent Skill — 按 Git 分支工单号，在 monorepo 顶层维护 `tasks/<id>/` 文档骨架（process / review / handoff / deploy）。

支持：**Cursor**、**Claude Code**、**Agents**（`.cursor` / `.claude` / `.agents`）。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/github-xxin1438--lang%2Ftask--workspace-blue)](https://github.com/xxin1438-lang/task-workspace)

## 安装

```bash
npx github:xxin1438-lang/task-workspace install
```

会写入：

| 端 | Skill | Commands |
|----|-------|----------|
| Cursor | `~/.cursor/skills/task-workspace` | `~/.cursor/commands/` |
| Claude Code | `~/.claude/skills/task-workspace` | `~/.claude/commands/` |
| Agents | `~/.agents/skills/task-workspace` | — |

项目内：

```bash
npx github:xxin1438-lang/task-workspace install-project
```

写入 `.cursor/skills`、`.claude/skills`、`.agents/skills`。

## 用法

```bash
npx github:xxin1438-lang/task-workspace checkout -- -b test/AIDN-17-docs origin/test/AIDN-17
npx github:xxin1438-lang/task-workspace init --id aidn-17
npx github:xxin1438-lang/task-workspace check --id aidn-17
npx github:xxin1438-lang/task-workspace install-hooks
```

## 目录约定

```
tasks/<id>/
├── process/grillme|prd|tech/{frontend,backend,api,deploy/sql}/
├── review/
└── handoff/{docs,test-cases/results}/
```

详见：`~/.cursor/skills/task-workspace/SKILL.md`（Claude / Agents 路径同理）。

## AI 验收

Agent 按 [AI-TEST.md](AI-TEST.md) 逐步自测。

## 分发说明

通过 GitHub 分发。推送到 `xxin1438-lang/task-workspace` 即可更新。

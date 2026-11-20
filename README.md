# task-workspace

> **Cursor Skill** — 按 Git 分支工单号，在 monorepo 顶层维护 `tasks/<id>/` 文档骨架（process / review / handoff）。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/github-xxin1438--lang%2Ftask--workspace-blue)](https://github.com/xxin1438-lang/task-workspace)

## 安装

```bash
npx github:xxin1438-lang/task-workspace install
```

或：

```bash
npm install -g github:xxin1438-lang/task-workspace
task-workspace install
```

> `npm install` 只下载包；**必须再执行 `install`**，才会注册到 `~/.cursor/skills`。

安装到当前项目（与 `java/`、`web/` 同级的 monorepo）：

```bash
npx github:xxin1438-lang/task-workspace install-project
```

## 用法

```bash
npx github:xxin1438-lang/task-workspace init
npx github:xxin1438-lang/task-workspace init --id aidn-17
npx github:xxin1438-lang/task-workspace check --id aidn-17
npx github:xxin1438-lang/task-workspace install-hooks
```

## 目录约定

```
tasks/<id>/
├── process/grillme|prd|tech/{frontend,backend,api}/
├── review/
└── handoff/{docs,test-cases}/
```

详见 Cursor Skill：`~/.cursor/skills/task-workspace/SKILL.md`

## 分发说明

当前通过 GitHub 分发（不依赖 npm 2FA publish）。推送到 `xxin1438-lang/task-workspace` 即可更新。

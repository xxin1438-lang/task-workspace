# init-task

按当前 Git 分支工单号（或用户给出的 id）创建 / 补齐 `tasks/<id>/` 文档骨架。

**门禁：** 切分支请用 `checkout`（先 fetch/pull）；`init` 默认也会 sync。

```bash
npx github:xxin1438-lang/task-workspace checkout -- -b test/AIDN-17-docs origin/test/AIDN-17
npx github:xxin1438-lang/task-workspace init --id <taskId>
```

遵循 `task-workspace` Skill 的目录与落盘约定。

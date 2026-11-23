# AI 验收清单：task-workspace

给 Agent 用。按顺序执行；每步把命令输出贴回对话。失败即停，报告失败步骤与 stderr。

## 前置

- 工作目录：含 `java/` 与 `web/` 的 monorepo 顶层（或能向上找到该顶层）
- 已能执行：`npx github:xxin1438-lang/task-workspace`

## 步骤

### 1. 自检脚本

```bash
npx github:xxin1438-lang/task-workspace install
~/.cursor/skills/task-workspace/scripts/init-task-workspace.sh --self-test
```

期望：打印 `self-test: OK`，exit 0。

### 2. 指定 id 建骨架（幂等）

用测试 id，避免污染真实工单：

```bash
npx github:xxin1438-lang/task-workspace init --id ai-test-1
npx github:xxin1438-lang/task-workspace init --id ai-test-1
```

期望：

- 第一次打印 `task-workspace ready: .../tasks/ai-test-1`
- 第二次再次 ready，且不报错
- 存在目录树：

```text
tasks/ai-test-1/process/grillme|prd|tech/{frontend,backend,api,deploy/sql}/
tasks/ai-test-1/review/
tasks/ai-test-1/handoff/{docs,test-cases/results}/
```

每个叶子目录有 `README.md`；`process/tech/deploy/deploy.md` 应由模板生成。

校验：

```bash
find tasks/ai-test-1 -type f | sort
```

期望：至少 10 个 `README.md`（含 `deploy/` 与 `deploy/sql/`），且存在 `process/tech/deploy/deploy.md`。

### 3. --check 应报关键正文缺失

```bash
npx github:xxin1438-lang/task-workspace check --id ai-test-1
echo exit:$?
```

期望：

- 目录项均为 `[ok]`
- 关键文件（`clarify.md` / `prd.md` / `design.md` / `api.md` / `deploy.md` / `handoff.md` / `cases.md`）中：若 `deploy.md` 已由模板生成则为 `[ok]`，其余正文可为 `[MISSING]`
- 若仅缺正文、目录齐全：exit code ≠ 0（除非只缺已模板化的 deploy.md 外的项）

### 4. 落盘映射冒烟（写一篇假 PRD + 部署）

```bash
printf '%s\n' '# 测试 PRD' '' '仅用于 AI 验收。' > tasks/ai-test-1/process/prd/prd.md
printf '%s\n' '# 部署' '' '## 1. 待部署服务' '' '| 服务 | 是否需发版 | 本次新增 / 变更能力（一句话） |' > tasks/ai-test-1/process/tech/deploy/deploy.md
npx github:xxin1438-lang/task-workspace check --id ai-test-1
```

期望：`prd.md` 与 `deploy.md` 为 `[ok]`，其余关键文件仍可 `[MISSING]`。

### 5. 分支解析（可选）

若当前分支名含类似 `aidn-17` 的工单号：

```bash
git branch --show-current
npx github:xxin1438-lang/task-workspace init
```

期望：在 `tasks/<解析出的小写 id>/` 建骨架。  
若分支无工单号：应提示传 `--id`，exit ≠ 0（非 `--hook` 时）。

### 6. 清理（可选）

```bash
rm -rf tasks/ai-test-1
```

仅删测试 id；勿删真实工单目录。

## 通过标准

1–4 全部符合期望即通过。向用户报告：`task-workspace AI-TEST: PASS` 或 `FAIL` + 失败步骤。

## 不要做

- 不要 `npm publish`
- 不要改真实 `tasks/<业务id>/` 里已有正文
- 不要提交或推送 monorepo 业务仓（除非用户明确要求）

#!/usr/bin/env node

import { installSkill, installProject } from '../lib/install.js';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';
import { homedir } from 'node:os';

const packageRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

function printHelp() {
  console.log(`
task-workspace — 按 Git 分支工单号维护 tasks/<id>/ 文档骨架
支持：Cursor / Claude Code / Agents（.cursor · .claude · .agents）

用法:
  task-workspace install              安装到 ~/.cursor、~/.claude、~/.agents
  task-workspace install-project [p]  安装到项目 .cursor/.claude/.agents/skills
  task-workspace checkout -- <git checkout 参数...>
                                      先 fetch → checkout → pull --ff-only → init（门禁）
  task-workspace init [--id ID]       建/补骨架（默认先 fetch/pull）
  task-workspace check [--id ID]      校验齐套
  task-workspace install-hooks        安装 git post-checkout/post-merge
  task-workspace help                 显示帮助

示例:
  npx github:xxin1438-lang/task-workspace install
  npx github:xxin1438-lang/task-workspace checkout -- -b test/AIDN-17-docs origin/test/AIDN-17
  npx github:xxin1438-lang/task-workspace init --id aidn-17

环境变量:
  CURSOR_HOME   默认 ~/.cursor
  CLAUDE_HOME   默认 ~/.claude
  AGENTS_HOME   默认 ~/.agents
`);
}

function resolveInitScript(preferProject) {
  const candidates = [];
  if (preferProject) {
    candidates.push(
      join(process.cwd(), '.cursor', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh'),
      join(process.cwd(), '.claude', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh'),
      join(process.cwd(), '.agents', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh')
    );
  }
  const homes = [
    process.env.CURSOR_HOME || join(homedir(), '.cursor'),
    process.env.CLAUDE_HOME || join(homedir(), '.claude'),
    process.env.AGENTS_HOME || join(homedir(), '.agents'),
  ];
  for (const home of homes) {
    candidates.push(join(home, 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh'));
  }
  if (!preferProject) {
    candidates.push(
      join(process.cwd(), '.cursor', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh'),
      join(process.cwd(), '.claude', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh'),
      join(process.cwd(), '.agents', 'skills', 'task-workspace', 'scripts', 'init-task-workspace.sh')
    );
  }
  candidates.push(join(packageRoot, 'skill', 'scripts', 'init-task-workspace.sh'));

  for (const p of candidates) {
    if (existsSync(p)) return p;
  }
  return candidates[candidates.length - 1];
}

function runScript(scriptName, args) {
  const init = resolveInitScript(true);
  const script =
    scriptName === 'init'
      ? init
      : join(dirname(init), 'install-hooks.sh');
  if (!existsSync(script)) {
    console.error(`找不到脚本: ${script}`);
    console.error('请先执行: npx github:xxin1438-lang/task-workspace install');
    process.exit(1);
  }
  const r = spawnSync(script, args, { stdio: 'inherit' });
  process.exit(r.status ?? 1);
}

const [, , command, ...args] = process.argv;

switch (command) {
  case 'install': {
    const { destinations } = installSkill();
    console.log('==> 安装 task-workspace（多端）');
    for (const d of destinations) {
      console.log(`    [${d.id}] Skill -> ${d.skillDest}`);
      if (d.commandsDest) console.log(`    [${d.id}] Commands -> ${d.commandsDest}`);
    }
    console.log('==> 安装完成');
    console.log('');
    console.log('下一步: npx github:xxin1438-lang/task-workspace init --id aidn-17');
    break;
  }
  case 'install-project': {
    const { destinations } = installProject(args[0] || process.cwd());
    console.log('==> 已安装到项目:');
    for (const d of destinations) {
      console.log(`    ${d.skillDest}`);
    }
    break;
  }
  case 'checkout': {
    const checkoutArgs = args[0] === '--' ? args.slice(1) : args;
    const init = resolveInitScript(true);
    const script = join(dirname(init), 'checkout-safe.sh');
    if (!existsSync(script)) {
      console.error(`找不到脚本: ${script}`);
      console.error('请先执行: npx github:xxin1438-lang/task-workspace install');
      process.exit(1);
    }
    const r = spawnSync(script, checkoutArgs, { stdio: 'inherit' });
    process.exit(r.status ?? 1);
    break;
  }
  case 'init': {
    runScript('init', args);
    break;
  }
  case 'check': {
    runScript('init', ['--check', ...args]);
    break;
  }
  case 'install-hooks': {
    const hooks = join(dirname(resolveInitScript(true)), 'install-hooks.sh');
    const r = spawnSync(hooks, [], { stdio: 'inherit' });
    process.exit(r.status ?? 1);
    break;
  }
  case 'help':
  case '--help':
  case '-h':
  case undefined:
    printHelp();
    break;
  default:
    console.error(`未知命令: ${command}`);
    printHelp();
    process.exit(1);
}

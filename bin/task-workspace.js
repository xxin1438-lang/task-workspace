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
task-workspace — 按 Git 分支工单号维护 tasks/<id>/ 文档骨架（Cursor Skill）

用法:
  task-workspace install              安装到 ~/.cursor/skills 与 ~/.cursor/commands
  task-workspace install-project [p]  安装到项目 .cursor/skills（默认 cwd）
  task-workspace init [--id ID]       调用脚本建/补骨架
  task-workspace check [--id ID]      校验齐套
  task-workspace install-hooks        安装 git post-checkout/post-merge
  task-workspace help                 显示帮助

示例:
  npx github:xxin1438-lang/task-workspace install
  npx github:xxin1438-lang/task-workspace install-project
  npx github:xxin1438-lang/task-workspace init --id aidn-17

环境变量:
  CURSOR_HOME   Cursor 配置目录（默认 ~/.cursor）
`);
}

function resolveInitScript(preferProject) {
  const homeSkill = join(
    process.env.CURSOR_HOME || join(homedir(), '.cursor'),
    'skills',
    'task-workspace',
    'scripts',
    'init-task-workspace.sh'
  );
  const pkgSkill = join(packageRoot, 'skill', 'scripts', 'init-task-workspace.sh');
  const projectSkill = join(
    process.cwd(),
    '.cursor',
    'skills',
    'task-workspace',
    'scripts',
    'init-task-workspace.sh'
  );

  if (preferProject && existsSync(projectSkill)) return projectSkill;
  if (existsSync(homeSkill)) return homeSkill;
  if (existsSync(projectSkill)) return projectSkill;
  return pkgSkill;
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
    const { skillDest, commandsDest } = installSkill();
    console.log('==> 安装 task-workspace 到 Cursor');
    console.log(`    Skill    -> ${skillDest}`);
    console.log(`    Commands -> ${commandsDest}`);
    console.log('==> 安装完成');
    console.log('');
    console.log('下一步：在 monorepo 根执行 /init-task 或:');
    console.log('  npx github:xxin1438-lang/task-workspace init --id aidn-17');
    break;
  }
  case 'install-project': {
    const { skillDest } = installProject(args[0] || process.cwd());
    console.log(`==> 已安装到项目: ${skillDest}`);
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

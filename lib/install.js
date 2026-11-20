import { cpSync, existsSync, mkdirSync, chmodSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const packageRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

function getCursorHome() {
  return process.env.CURSOR_HOME || join(homedir(), '.cursor');
}

function chmodScripts(dir) {
  if (!existsSync(dir)) return;
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isFile() && name.endsWith('.sh')) {
      try {
        chmodSync(p, 0o755);
      } catch {
        // ignore
      }
    }
  }
}

/**
 * 安装到 ~/.cursor/skills/task-workspace
 */
export function installSkill() {
  const cursorHome = getCursorHome();
  const skillDest = join(cursorHome, 'skills', 'task-workspace');
  const commandsDest = join(cursorHome, 'commands');

  mkdirSync(skillDest, { recursive: true });
  mkdirSync(commandsDest, { recursive: true });

  cpSync(join(packageRoot, 'skill'), skillDest, { recursive: true });
  chmodScripts(join(skillDest, 'scripts'));

  for (const name of ['init-task.md', 'check-task.md']) {
    const src = join(packageRoot, 'commands', name);
    if (existsSync(src)) {
      cpSync(src, join(commandsDest, name));
    }
  }

  return { cursorHome, skillDest, commandsDest };
}

/**
 * 安装到项目 .cursor/skills/task-workspace
 */
export function installProject(projectDir = process.cwd()) {
  const skillDest = join(projectDir, '.cursor', 'skills', 'task-workspace');
  mkdirSync(dirname(skillDest), { recursive: true });
  cpSync(join(packageRoot, 'skill'), skillDest, { recursive: true });
  chmodScripts(join(skillDest, 'scripts'));
  return { skillDest };
}

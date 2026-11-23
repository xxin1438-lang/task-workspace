import { cpSync, existsSync, mkdirSync, chmodSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const packageRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const SKILL_NAME = 'task-workspace';

/** 用户级 skill 根：Cursor / Claude Code / 通用 Agents */
const USER_SKILL_HOMES = [
  { id: 'cursor', env: 'CURSOR_HOME', defaultDir: '.cursor', commands: true },
  { id: 'claude', env: 'CLAUDE_HOME', defaultDir: '.claude', commands: true },
  { id: 'agents', env: 'AGENTS_HOME', defaultDir: '.agents', commands: false },
];

/** 项目级相对路径 */
const PROJECT_SKILL_RELS = [
  join('.cursor', 'skills', SKILL_NAME),
  join('.claude', 'skills', SKILL_NAME),
  join('.agents', 'skills', SKILL_NAME),
];

function homeFor(spec) {
  if (process.env[spec.env]) return process.env[spec.env];
  return join(homedir(), spec.defaultDir);
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

function copySkillTree(skillDest) {
  mkdirSync(skillDest, { recursive: true });
  cpSync(join(packageRoot, 'skill'), skillDest, { recursive: true });
  chmodScripts(join(skillDest, 'scripts'));
}

function copyCommands(commandsDest) {
  mkdirSync(commandsDest, { recursive: true });
  for (const name of ['init-task.md', 'check-task.md']) {
    const src = join(packageRoot, 'commands', name);
    if (existsSync(src)) {
      cpSync(src, join(commandsDest, name));
    }
  }
}

/**
 * 安装到 Cursor / Claude / Agents 用户目录
 */
export function installSkill() {
  const destinations = [];

  for (const spec of USER_SKILL_HOMES) {
    const home = homeFor(spec);
    const skillDest = join(home, 'skills', SKILL_NAME);
    copySkillTree(skillDest);
    const entry = { id: spec.id, home, skillDest };
    if (spec.commands) {
      const commandsDest = join(home, 'commands');
      copyCommands(commandsDest);
      entry.commandsDest = commandsDest;
    }
    destinations.push(entry);
  }

  return { destinations };
}

/**
 * 安装到项目 .cursor / .claude / .agents skills
 */
export function installProject(projectDir = process.cwd()) {
  const destinations = [];
  for (const rel of PROJECT_SKILL_RELS) {
    const skillDest = join(projectDir, rel);
    mkdirSync(dirname(skillDest), { recursive: true });
    copySkillTree(skillDest);
    destinations.push({ skillDest });
  }
  return { destinations, projectDir };
}

export { USER_SKILL_HOMES, PROJECT_SKILL_RELS, SKILL_NAME };

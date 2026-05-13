#!/usr/bin/env node
/**
 * Compiles ai-workflows prompts into formats usable in other repos:
 *
 *   dist/copilot/<category>/<name>.prompt.md  — GitHub Copilot (.github/prompts/)
 *   dist/claude/<category>/<name>.md          — Claude Code (.claude/commands/)
 *
 * Usage:
 *   node scripts/build-dist.js
 *
 * To install into another repo:
 *   cp -r dist/copilot/* /path/to/repo/.github/prompts/
 *   cp -r dist/claude/*  /path/to/repo/.claude/commands/
 */

const fs = require('fs');
const path = require('path');

const PROMPTS_DIR = path.join(__dirname, '..', 'prompts');
const DIST_DIR = path.join(__dirname, '..', 'dist');

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) return { meta: {}, body: content };

  const meta = {};
  for (const line of match[1].split('\n')) {
    const colonIdx = line.indexOf(':');
    if (colonIdx > 0) {
      const key = line.slice(0, colonIdx).trim();
      const value = line.slice(colonIdx + 1).trim();
      if (key && value) meta[key] = value;
    }
  }

  return { meta, body: content.slice(match[0].length) };
}

function extractPromptBlock(body) {
  // Locate ## Prompt section
  const sectionIdx = body.search(/\n## Prompt\n/);
  if (sectionIdx === -1) return null;

  const afterSection = body.slice(sectionIdx + '\n## Prompt\n'.length);

  // Find opening fence: ``` or ```` (must be first non-blank content)
  const fenceMatch = afterSection.match(/^[ \t]*(`{3,4})[^\n]*\n/m);
  if (!fenceMatch) return null;

  const fence = fenceMatch[1]; // ``` or ````
  const contentStart = afterSection.indexOf(fenceMatch[0]) + fenceMatch[0].length;
  const afterFence = afterSection.slice(contentStart);

  // Find closing fence on its own line
  const closingRe = new RegExp(`\n[ \t]*${fence}[ \t]*(\n|$)`);
  const closingMatch = afterFence.match(closingRe);
  if (!closingMatch) return null;

  return afterFence.slice(0, closingMatch.index).trim();
}

function buildCopilotFile(title, promptContent) {
  return `---\ndescription: ${title}\nmode: agent\n---\n\n${promptContent}\n`;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

let built = 0;
let skipped = 0;

for (const category of fs.readdirSync(PROMPTS_DIR).sort()) {
  const categoryPath = path.join(PROMPTS_DIR, category);
  if (!fs.statSync(categoryPath).isDirectory()) continue;

  for (const file of fs.readdirSync(categoryPath).sort()) {
    if (!file.endsWith('.md')) continue;

    const filePath = path.join(categoryPath, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const { meta, body } = parseFrontmatter(content);

    if (!meta.title) {
      console.warn(`[skip] ${category}/${file} — no title in frontmatter`);
      skipped++;
      continue;
    }

    const promptContent = extractPromptBlock(body);
    if (!promptContent) {
      console.warn(`[skip] ${category}/${file} — no ## Prompt code block found`);
      skipped++;
      continue;
    }

    const slug = path.basename(file, '.md');

    const copilotDir = path.join(DIST_DIR, 'copilot', category);
    const claudeDir = path.join(DIST_DIR, 'claude', category);
    ensureDir(copilotDir);
    ensureDir(claudeDir);

    fs.writeFileSync(
      path.join(copilotDir, `${slug}.prompt.md`),
      buildCopilotFile(meta.title, promptContent)
    );

    fs.writeFileSync(
      path.join(claudeDir, `${slug}.md`),
      `${promptContent}\n`
    );

    console.log(`[ok]   ${category}/${slug}`);
    built++;
  }
}

console.log(`\nBuilt ${built} prompts${skipped ? `, skipped ${skipped}` : ''}.`);
console.log('');
console.log('Install into a repo:');
console.log('  Copilot:     cp -r dist/copilot/* /path/to/repo/.github/prompts/');
console.log('  Claude Code: cp -r dist/claude/*  /path/to/repo/.claude/commands/');

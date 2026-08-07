#!/usr/bin/env node
/**
 * Compiles ai-workflows prompts into formats usable in other repos:
 *
 *   dist/copilot/<category>/<name>.prompt.md  — GitHub Copilot (.github/prompts/)
 *   dist/claude/skills/saboteur-<name>/SKILL.md — Claude Code skills (.claude/skills/)
 *
 * Usage:
 *   node scripts/build-dist.js
 *
 * To install into another repo:
 *   cp -r dist/copilot/*      /path/to/repo/.github/prompts/
 *   cp -r dist/claude/skills/* /path/to/repo/.claude/skills/   (or ~/.claude/skills/)
 *
 * Skill source authoring (in prompts/<category>/<name>.md):
 *   - frontmatter `description:` (required for skill emission) and optional
 *     `argument-hint:` — both single-line.
 *   - The `## Prompt` code block is the shared body. The skill emitter rewrites
 *     its {{PLACEHOLDERS}} into natural-language instructions (see transform below).
 *   - Optional `## Skill inputs` section: bullet lines `- VAR: phrase` mapping each
 *     {{VAR}} to the phrase the skill body should use. Unmapped vars are humanized.
 *   - Optional `## Skill wrap-up` section: prose appended after the body (chaining
 *     offers, interactive open-question resolution, …).
 *   - Optional `## Skill body` code block: a verbatim skill body that overrides the
 *     transform entirely (use when auto-flattening reads poorly).
 */

const fs = require('fs');
const path = require('path');

const PROMPTS_DIR = path.join(__dirname, '..', 'prompts');
const DIST_DIR = path.join(__dirname, '..', 'dist');
const SKILL_PREFIX = 'saboteur-';

// Appended to document-producing skills. Two flavours, because where a document
// belongs is only knowable for the ones with a declared convention.
//
// Skills whose output a downstream agent consumes get a definite path from their
// schema's `output-path`. Everything else must be told or must ask — the old
// footer let the model infer a location from whatever folder looked relevant,
// which is exactly how a document ends up somewhere nothing can find it.
const SAVE_FOOTER_ASK = `## Saving the output

When the document is complete: if the user gave an explicit path, use it.
Otherwise ask where to save it and wait for an answer. Do not infer a location
from whichever folder looks relevant, and never write into the skill's own
directory.`;

function saveFooterForPath(outputPath, schemaId) {
  return `## Saving the output

When the document is complete, save it to:

    ${outputPath}

where \`{slug}\` is the kebab-cased name of the thing this document covers
(e.g. \`export-csv\`). An explicit path from the user always wins.

If the repository already keeps documents of this kind somewhere else, follow
that existing layout rather than creating a parallel tree — but keep the
filename. Do not invent a new location, do not ask when the convention applies,
and never write into the skill's own directory.

This path is part of the \`${schemaId}\` contract: downstream agents locate this
document by convention, so an ad-hoc location breaks the pipeline even when the
content is correct.`;
}

// Minimal reader for schemas/*.schema — only the header keys the compiler needs.
// tools/lib/check-outputs.js owns the full DSL.
function loadSchemaHeaders() {
  const dir = path.join(__dirname, '..', 'schemas');
  const byId = {};
  if (!fs.existsSync(dir)) return byId;
  for (const file of fs.readdirSync(dir)) {
    if (!file.endsWith('.schema')) continue;
    const text = fs.readFileSync(path.join(dir, file), 'utf8');
    const id = (text.match(/^schema:\s*(.+)$/m) || [])[1];
    if (!id) continue;
    byId[id.trim()] = {
      id: id.trim(),
      outputPath: ((text.match(/^output-path:\s*(.+)$/m) || [])[1] || '').trim(),
    };
  }
  return byId;
}

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

// Extracts the first fenced code block that follows a given `## Heading`.
function extractCodeBlock(body, heading) {
  const sectionIdx = body.search(new RegExp(`\\n${heading}\\n`));
  if (sectionIdx === -1) return null;

  const afterSection = body.slice(sectionIdx + `\n${heading}\n`.length);

  const fenceMatch = afterSection.match(/^[ \t]*(`{3,4})[^\n]*\n/m);
  if (!fenceMatch) return null;

  const fence = fenceMatch[1];
  const contentStart = afterSection.indexOf(fenceMatch[0]) + fenceMatch[0].length;
  const afterFence = afterSection.slice(contentStart);

  const closingRe = new RegExp(`\n[ \t]*${fence}[ \t]*(\n|$)`);
  const closingMatch = afterFence.match(closingRe);
  if (!closingMatch) return null;

  return afterFence.slice(0, closingMatch.index).trim();
}

// Extracts the prose of a `## Heading` section up to the next `## ` heading.
function extractSection(body, heading) {
  const re = new RegExp(`\\n${heading}\\n([\\s\\S]*?)(?=\\n## |$)`);
  const match = body.match(re);
  return match ? match[1].trim() : null;
}

// Parses `## Skill inputs` bullets (`- VAR: phrase`) into a { VAR: phrase } map.
function parseSkillInputs(body) {
  const section = extractSection(body, '## Skill inputs');
  if (!section) return {};
  const map = {};
  for (const line of section.split('\n')) {
    const m = line.match(/^\s*[-*]\s*`?([A-Z0-9_]+)`?\s*[:—-]\s*(.+)$/);
    if (m) map[m[1]] = m[2].trim();
  }
  return map;
}

function humanize(varName) {
  return varName.toLowerCase().replace(/_/g, ' ');
}

// Rewrites the {{PLACEHOLDER}} template body into natural-language skill instructions.
function transformPromptToSkillBody(promptBody, inputs) {
  const phrase = (v) => inputs[v] || humanize(v);
  let text = promptBody;

  // Collapse XML-style wrappers around a sole placeholder to just the phrase.
  // e.g. <concept_document>\n{{CONCEPT_DOCUMENT}}\n</concept_document>
  text = text.replace(
    /<([a-zA-Z0-9_]+)>\s*\{\{([A-Z0-9_]+)\}\}\s*<\/\1>/g,
    (m, tag, v) => phrase(v)
  );

  // Content that does not cross a conditional token, so an if-only block followed
  // later by an unrelated if/else isn't swallowed by a greedy/lazy capture.
  // (Assumes conditionals are not nested, which holds across the prompt library.)
  const INNER = '((?:(?!\\{\\{#if |\\{\\{else\\}\\}|\\{\\{\\/if\\}\\})[\\s\\S])*?)';

  // if/else conditionals (OUTPUT_PATH handled by the save-footer, so drop it).
  text = text.replace(
    new RegExp(`\\{\\{#if ([A-Z0-9_]+)\\}\\}${INNER}\\{\\{else\\}\\}${INNER}\\{\\{\\/if\\}\\}`, 'g'),
    (m, v, a, b) => {
      if (v === 'OUTPUT_PATH') return '';
      return `If ${phrase(v)} is available:\n${a.trim()}\n\nOtherwise:\n${b.trim()}\n`;
    }
  );

  // if-only conditionals.
  text = text.replace(
    new RegExp(`\\{\\{#if ([A-Z0-9_]+)\\}\\}${INNER}\\{\\{\\/if\\}\\}`, 'g'),
    (m, v, a) => {
      if (v === 'OUTPUT_PATH') return '';
      return `If the user provided ${phrase(v)}:\n${a.trim()}\n`;
    }
  );

  // Remaining bare placeholders.
  text = text.replace(/\{\{([A-Z0-9_]+)\}\}/g, (m, v) => phrase(v));

  // Tidy excess blank lines left by removed blocks.
  text = text.replace(/\n{3,}/g, '\n\n').trim();

  return text;
}

function buildCopilotFile(title, promptContent) {
  return `---\ndescription: ${title}\nmode: agent\n---\n\n${promptContent}\n`;
}

function buildSkillFile(meta, slug, body, wrapUp, schema) {
  const name = `${SKILL_PREFIX}${slug}`;
  let fm = `---\nname: ${name}\ndescription: ${meta.description}\n`;
  if (meta['argument-hint']) fm += `argument-hint: ${meta['argument-hint']}\n`;
  fm += '---\n';

  const parts = [body];
  if (wrapUp) parts.push(wrapUp);
  // Only document-producing skills get a save-footer; refactor/review/etc. don't
  // emit a file to save.
  if (meta['skill-saves-document'] === 'true') {
    parts.push(
      schema && schema.outputPath
        ? saveFooterForPath(schema.outputPath, schema.id)
        : SAVE_FOOTER_ASK
    );
  }

  return `${fm}\n${parts.join('\n\n')}\n`;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

// Relative links are position-dependent, and compiling moves the text out of
// prompts/<category>/ into a flat skill directory — so a link that resolved in
// the source resolves to nothing in dist/, and the skill goes on to emit that
// dead path into the documents it produces. Reference other prompts by name
// inside a prompt body, never by relative path.
function warnRelativeLinks(body, label) {
  const found = [...body.matchAll(/\[[^\]]*\]\((\.[^)]+)\)/g)].map((m) => m[1]);
  for (const target of new Set(found)) {
    console.warn(
      `[warn] ${label} — prompt body contains the relative link "${target}"; ` +
      `it will not resolve once compiled. Reference the prompt by name instead.`
    );
  }
  return found.length;
}

const SCHEMAS = loadSchemaHeaders();

// Start each build from a clean dist so renamed/removed prompts don't leave stragglers.
fs.rmSync(DIST_DIR, { recursive: true, force: true });

let copilotBuilt = 0;
let skillsBuilt = 0;
let skipped = 0;
let relativeLinkWarnings = 0;

for (const category of fs.readdirSync(PROMPTS_DIR).sort()) {
  const categoryPath = path.join(PROMPTS_DIR, category);
  if (!fs.statSync(categoryPath).isDirectory()) continue;

  for (const file of fs.readdirSync(categoryPath).sort()) {
    if (!file.endsWith('.md')) continue;

    const filePath = path.join(categoryPath, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const { meta, body } = parseFrontmatter(content);
    const slug = path.basename(file, '.md');

    if (!meta.title) {
      console.warn(`[skip] ${category}/${file} — no title in frontmatter`);
      skipped++;
      continue;
    }

    const promptContent = extractCodeBlock(body, '## Prompt');
    if (!promptContent) {
      console.warn(`[skip] ${category}/${file} — no ## Prompt code block found`);
      skipped++;
      continue;
    }

    relativeLinkWarnings += warnRelativeLinks(promptContent, `${category}/${slug}`);

    // Copilot flavor — unchanged: the raw prompt block with {{PLACEHOLDERS}}.
    const copilotDir = path.join(DIST_DIR, 'copilot', category);
    ensureDir(copilotDir);
    fs.writeFileSync(
      path.join(copilotDir, `${slug}.prompt.md`),
      buildCopilotFile(meta.title, promptContent)
    );
    copilotBuilt++;

    // Claude skill flavor — needs a description to be auto-triggerable.
    if (!meta.description) {
      console.warn(`[warn] ${category}/${slug} — no description; copilot only, skill skipped`);
      console.log(`[ok]   copilot ${category}/${slug}`);
      continue;
    }

    const overrideBody = extractCodeBlock(body, '## Skill body');
    const skillBody = overrideBody
      ? overrideBody
      : transformPromptToSkillBody(promptContent, parseSkillInputs(body));
    const wrapUp = extractSection(body, '## Skill wrap-up');

    const skillDir = path.join(DIST_DIR, 'claude', 'skills', `${SKILL_PREFIX}${slug}`);
    ensureDir(skillDir);
    const schema = meta['output-schema'] ? SCHEMAS[meta['output-schema'].trim()] : null;
    if (meta['output-schema'] && !schema) {
      console.warn(`[warn] ${category}/${slug} — declares output-schema "${meta['output-schema']}" but no schema file provides it`);
    }
    fs.writeFileSync(
      path.join(skillDir, 'SKILL.md'),
      buildSkillFile(meta, slug, skillBody, wrapUp, schema)
    );
    skillsBuilt++;

    console.log(`[ok]   copilot + skill ${category}/${slug}`);
  }
}

console.log(`\nBuilt ${copilotBuilt} Copilot prompts, ${skillsBuilt} Claude skills${skipped ? `, skipped ${skipped}` : ''}.`);
if (relativeLinkWarnings) {
  console.log(`${relativeLinkWarnings} relative link(s) in prompt bodies will not resolve after compilation (see warnings above).`);
}
console.log('');
console.log('Install into a repo:');
console.log('  Copilot:     cp -r dist/copilot/*       /path/to/repo/.github/prompts/');
console.log('  Claude Code: cp -r dist/claude/skills/*  /path/to/repo/.claude/skills/   (or ~/.claude/skills/)');

#!/usr/bin/env node
/**
 * check-outputs.js — schema engine for agent-consumed prompt outputs.
 *
 * Each file in schemas/*.schema is the machine contract for what one prompt or
 * skill produces. The pairing is declared on both sides — `prompt:` or `skill:`
 * in the schema and `output-schema:` in the source's frontmatter — so a
 * half-renamed link fails loudly instead of silently skipping validation. This
 * file is the only thing that reads the schema DSL, and it serves three jobs:
 *
 *   1. Drift check (`--prompts`)
 *      Assert every source's authored output format agrees with its schema.
 *      This is what keeps the human-readable format and the machine contract
 *      from diverging — nothing is duplicated without being checked. A prompt
 *      carries that format in its `## Prompt` block; a skill has no such block,
 *      so its schema names the section to read with `format-section:`.
 *
 *   2. Document validation (`--doc <file> --schema <id>`)
 *      Validate a produced spec / feature breakdown / task list against its
 *      schema: required fields present, IDs well-formed and gapless, the
 *      dependency graph acyclic and forward-only, references resolving.
 *
 *   3. Derived structure (`--doc <file> --schema <id> --json`)
 *      Emit the parsed document as JSON for agents to consume. This is derived,
 *      never authored, so it cannot drift from the document it came from. An
 *      automated runner uses it to order tasks and gate progress on each
 *      task's done condition.
 *
 * Usage:
 *   node tools/lib/check-outputs.js --prompts
 *   node tools/lib/check-outputs.js --doc specs/features/x/tasks.md --schema sab.tasks/1
 *   node tools/lib/check-outputs.js --doc tasks.md --schema sab.tasks/1 --json
 *   node tools/lib/check-outputs.js --doc features.md --schema sab.features/1 \
 *        --against specs/product/x.md
 *   node tools/lib/check-outputs.js --list
 *
 * Exit codes: 0 = pass, 1 = fail (blocking), 2 = warn only.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '..', '..');
const PROMPTS_DIR = path.join(REPO_ROOT, 'prompts');
const SKILLS_DIR = path.join(REPO_ROOT, 'skills');
const SCHEMAS_DIR = path.join(REPO_ROOT, 'schemas');

// ── Output helpers ───────────────────────────────────────────────────────────

const COLOR = process.stdout.isTTY && !process.env.NO_COLOR;
const RED = COLOR ? '\x1b[0;31m' : '';
const GREEN = COLOR ? '\x1b[0;32m' : '';
const YELLOW = COLOR ? '\x1b[1;33m' : '';
const RESET = COLOR ? '\x1b[0m' : '';

// ── Schema DSL parsing ───────────────────────────────────────────────────────

// Pulls the first fenced block under a `## Heading`. Mirrors build-dist.js so
// the two agree on what counts as a prompt's schema/format block.
function extractCodeBlock(body, heading) {
  const idx = body.search(new RegExp(`\\n${heading}\\n`));
  if (idx === -1) return null;
  const after = body.slice(idx + `\n${heading}\n`.length);
  const fenceMatch = after.match(/^[ \t]*(`{3,4})[^\n]*\n/m);
  if (!fenceMatch) return null;
  const fence = fenceMatch[1];
  const start = after.indexOf(fenceMatch[0]) + fenceMatch[0].length;
  const rest = after.slice(start);
  const close = rest.match(new RegExp(`\n[ \t]*${fence}[ \t]*(\n|$)`));
  if (!close) return null;
  return rest.slice(0, close.index).trim();
}

// `Label | required | type | extra:...` → { label, required, type, opts }
function parseAttrs(raw) {
  const parts = raw.split('|').map((s) => s.trim()).filter(Boolean);
  const label = parts.shift();
  const attrs = { label, required: true, type: 'text', opts: {} };
  for (const p of parts) {
    if (p === 'required') attrs.required = true;
    else if (p === 'optional') attrs.required = false;
    else if (p.includes(':')) {
      const k = p.slice(0, p.indexOf(':'));
      const v = p.slice(p.indexOf(':') + 1);
      attrs.opts[k] = v;
    } else if (/^(text|int|checkbox|ids|slug|bullet|numbered)$/.test(p)) {
      attrs.type = p;
    } else {
      attrs.opts[p] = true;
    }
  }
  // `refs:X.id or none` and `text or none` carry an allow-none flag.
  if (/\bor none$/.test(raw)) attrs.noneAllowed = true;
  return attrs;
}

// Turns `### Task {id:int}: {title:text}` into a matcher with named captures.
function compileHeading(pattern) {
  const fields = [];
  let regex = '';
  let i = 0;
  const re = /\{([a-zA-Z0-9_]+):([a-zA-Z0-9_]+)\}/g;
  let m;
  while ((m = re.exec(pattern)) !== null) {
    regex += escapeRe(pattern.slice(i, m.index));
    fields.push({ name: m[1], type: m[2] });
    regex += m[2] === 'int' ? '(\\d+)' : '(.+?)';
    i = m.index + m[0].length;
  }
  regex += escapeRe(pattern.slice(i));
  return { raw: pattern, regex: new RegExp(`^${regex}\\s*$`), fields };
}

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function parseSchema(text) {
  const schema = {
    id: null,
    doc: null,
    items: [],
    sections: [],
    graph: [],
    unknown: [],
  };
  let cur = null;
  let mode = null;

  for (const rawLine of text.split('\n')) {
    if (!rawLine.trim() || rawLine.trim().startsWith('#')) continue;
    const indented = /^\s{2,}/.test(rawLine);
    const line = rawLine.trim();

    if (!indented) {
      let m;
      if ((m = line.match(/^schema:\s*(.+)$/))) { schema.id = m[1].trim(); continue; }
      if ((m = line.match(/^doc:\s*(.+)$/))) { schema.doc = m[1].trim(); continue; }
      if ((m = line.match(/^prompt:\s*(.+)$/))) { schema.prompt = m[1].trim(); continue; }
      if ((m = line.match(/^skill:\s*(.+)$/))) { schema.skill = m[1].trim(); continue; }
      if ((m = line.match(/^format-section:\s*(.+)$/))) { schema.formatSection = m[1].trim(); continue; }
      if ((m = line.match(/^output-path:\s*(.+)$/))) { schema.outputPath = m[1].trim(); continue; }
      if ((m = line.match(/^item\s+(.+)$/))) {
        const a = parseAttrs(m[1]);
        cur = { name: a.label, min: a.opts.min ? Number(a.opts.min) : 0, heading: null, fields: [] };
        schema.items.push(cur);
        mode = 'item';
        continue;
      }
      if ((m = line.match(/^section\s+(.+)$/))) {
        const a = parseAttrs(m[1]);
        cur = { name: a.label, required: a.required, heading: null, fields: [], bullets: [], list: null, group: null };
        schema.sections.push(cur);
        mode = 'section';
        continue;
      }
      if (line === 'graph') { mode = 'graph'; cur = null; continue; }
      schema.unknown.push(line);
      continue;
    }

    // Indented member lines.
    if (mode === 'graph') {
      const m = line.match(/^([a-z-]+):\s*(.+)$/);
      if (m) schema.graph.push({ check: m[1], arg: m[2].trim() });
      continue;
    }
    if (!cur) continue;

    let m;
    if ((m = line.match(/^heading:\s*(.+)$/))) { cur.heading = compileHeading(m[1].trim()); continue; }
    if ((m = line.match(/^field:\s*(.+)$/))) { cur.fields.push(parseAttrs(m[1])); continue; }
    if ((m = line.match(/^bullet:\s*(.+)$/))) { cur.bullets.push(parseAttrs(m[1])); continue; }
    if ((m = line.match(/^list:\s*(.+)$/))) {
      const a = parseAttrs(m[1]);
      a.kind = a.label;
      cur.list = a;
      continue;
    }
    if ((m = line.match(/^group:\s*(.+)$/))) { cur.group = parseAttrs(m[1]); continue; }
    schema.unknown.push(line);
  }

  return schema;
}

// ── Schema registry (built from the prompt and skill libraries) ──────────────

// Reads schemas/*.schema and pairs each with the prompt or skill it governs.
// The link is declared twice on purpose — `prompt:`/`skill:` in the schema and
// `output-schema:` in the source's frontmatter — so a broken or half-renamed
// pairing is caught rather than silently skipping validation.
function loadSchemas() {
  const out = [];
  const linkErrors = [];

  if (!fs.existsSync(SCHEMAS_DIR)) return { entries: out, linkErrors };

  for (const file of fs.readdirSync(SCHEMAS_DIR).sort()) {
    if (!file.endsWith('.schema')) continue;
    const full = path.join(SCHEMAS_DIR, file);
    const rel = path.relative(REPO_ROOT, full);
    const schema = parseSchema(fs.readFileSync(full, 'utf8'));

    if (!schema.id) { linkErrors.push(`${rel}: no "schema:" id declared`); continue; }

    // A schema is sourced from exactly one place: a prompt, whose authored
    // format lives in its `## Prompt` block, or a skill, which has no such
    // block and so must name the section carrying the format.
    if (schema.prompt && schema.skill) {
      linkErrors.push(`${rel}: declares both "prompt:" and "skill:" — a schema has one source`);
      continue;
    }
    const sourcePath = schema.prompt || schema.skill;
    if (!sourcePath) { linkErrors.push(`${rel}: no "prompt:" or "skill:" path declared`); continue; }

    const sourceFull = path.join(REPO_ROOT, sourcePath);
    if (!fs.existsSync(sourceFull)) {
      linkErrors.push(
        `${rel}: declares ${schema.prompt ? 'prompt' : 'skill'} "${sourcePath}", which does not exist`
      );
      continue;
    }
    if (schema.skill && !schema.formatSection) {
      linkErrors.push(
        `${rel}: no "format-section:" declared, so there is no authored format in ${sourcePath} ` +
        `to check the schema against`
      );
      continue;
    }

    const content = fs.readFileSync(sourceFull, 'utf8');
    // Skills keep non-spec frontmatter under `metadata:`, so the reciprocal
    // declaration is indented there where a prompt's sits at the top level.
    const declared = (content.match(/^\s*output-schema:\s*(.+)$/m) || [])[1];
    if (!declared) {
      linkErrors.push(`${sourcePath}: missing "output-schema: ${schema.id}" in frontmatter`);
    } else if (declared.trim() !== schema.id) {
      linkErrors.push(
        `${sourcePath}: frontmatter says "output-schema: ${declared.trim()}" but ${rel} claims "${schema.id}"`
      );
    }

    // A document-producing prompt with no declared location leaves the compiled
    // skill guessing where to write — the failure this schema work exists to stop.
    if (schema.prompt && /^skill-saves-document:\s*true$/m.test(content) && !schema.outputPath) {
      linkErrors.push(
        `${rel}: no "output-path:" declared, but ${schema.prompt} saves a document — ` +
        `the compiled skill would have to ask or guess where it belongs`
      );
    }

    out.push({
      schema,
      schemaPath: rel,
      sourcePath,
      sourceBody: extractCodeBlock(content, schema.formatSection || '## Prompt') || '',
      slug: schema.prompt
        ? path.basename(sourcePath, '.md')
        : path.basename(path.dirname(sourcePath)),
    });
  }

  // A prompt that declares a schema which no file provides is unvalidated.
  for (const category of fs.readdirSync(PROMPTS_DIR).sort()) {
    const dir = path.join(PROMPTS_DIR, category);
    if (!fs.statSync(dir).isDirectory()) continue;
    for (const file of fs.readdirSync(dir).sort()) {
      if (!file.endsWith('.md')) continue;
      const rel = path.join('prompts', category, file);
      const declared = (fs.readFileSync(path.join(dir, file), 'utf8').match(/^output-schema:\s*(.+)$/m) || [])[1];
      if (declared && !out.some((e) => e.schema.id === declared.trim())) {
        linkErrors.push(`${rel}: declares output-schema "${declared.trim()}" but no schemas/*.schema provides it`);
      }
    }
  }

  // The same check for skills, which nest deeper than one category level.
  for (const full of findSkillFiles(SKILLS_DIR)) {
    const rel = path.relative(REPO_ROOT, full);
    const declared = (fs.readFileSync(full, 'utf8').match(/^\s*output-schema:\s*(.+)$/m) || [])[1];
    if (declared && !out.some((e) => e.schema.id === declared.trim())) {
      linkErrors.push(`${rel}: declares output-schema "${declared.trim()}" but no schemas/*.schema provides it`);
    }
  }

  return { entries: out, linkErrors };
}

// Every SKILL.md under skills/, at whatever depth it sits.
function findSkillFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const found = [];
  for (const name of fs.readdirSync(dir).sort()) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) found.push(...findSkillFiles(full));
    else if (name === 'SKILL.md') found.push(full);
  }
  return found;
}

// ── Job 1: source/schema drift check ─────────────────────────────────────────

function checkFormatDrift(entry) {
  const errors = [];
  const { schema, sourceBody, sourcePath } = entry;
  if (!sourceBody) {
    const where = schema.formatSection ? `"${schema.formatSection}"` : '## Prompt';
    errors.push(`no code block under ${where} to check the schema against`);
    return errors;
  }

  for (const item of schema.items) {
    // The authored format should show the heading shape, with placeholder text
    // where the schema declares a capture. Compare on the literal segments.
    const literal = item.heading.raw.replace(/\{[a-zA-Z0-9_]+:[a-zA-Z0-9_]+\}/g, '').trim();
    const stem = literal.split(/\s*\{/)[0].replace(/[:\s]+$/, '');
    if (stem && !sourceBody.includes(stem)) {
      errors.push(`item ${item.name}: authored format has no heading matching "${item.heading.raw}"`);
    }
    for (const f of item.fields) {
      if (!sourceBody.includes(`**${f.label}:**`)) {
        errors.push(`item ${item.name}: authored format is missing field "**${f.label}:**"`);
      }
    }
    // Fields must appear in the order the schema declares, or the parser and
    // the reader disagree about what the document means.
    const positions = item.fields
      .map((f) => ({ label: f.label, at: sourceBody.indexOf(`**${f.label}:**`) }))
      .filter((p) => p.at !== -1);
    for (let i = 1; i < positions.length; i++) {
      if (positions[i].at < positions[i - 1].at) {
        errors.push(
          `item ${item.name}: field order differs from schema — "${positions[i].label}" ` +
          `appears before "${positions[i - 1].label}" in the authored format`
        );
        break;
      }
    }
  }

  for (const sec of schema.sections) {
    if (!sec.heading) continue;
    const literal = sec.heading.raw.replace(/\{[a-zA-Z0-9_]+:[a-zA-Z0-9_]+\}/g, '').trim();
    const stem = literal.replace(/[:\s]+$/, '');
    if (stem && !sourceBody.includes(stem)) {
      errors.push(`section ${sec.name}: authored format has no heading "${sec.heading.raw}"`);
    }
    for (const b of sec.bullets) {
      if (!sourceBody.includes(b.label)) {
        errors.push(`section ${sec.name}: authored format is missing bullet "${b.label}"`);
      }
    }
    if (sec.list && sec.list.opts.id) {
      const prefix = sec.list.opts.id.split('{')[0];
      if (prefix && !sourceBody.includes(prefix)) {
        errors.push(
          `section ${sec.name}: schema declares IDs "${sec.list.opts.id}" but the authored ` +
          `format never shows the "${prefix}" prefix — produced docs will have no stable IDs`
        );
      }
    }
  }

  if (schema.unknown.length) {
    errors.push(`unrecognised schema lines: ${schema.unknown.slice(0, 3).join(' / ')}`);
  }

  return errors.map((e) => `${sourcePath}: ${e}`);
}

// ── Job 2/3: document parsing ────────────────────────────────────────────────

const FIELD_RE = /^\s*\*\*([^*:]+):\*\*\s*(.*)$/;

// `- Label: value` bullets. The alternation matters: authors write the colon
// INSIDE the bold (`- **Total tasks:** 6`) as often as outside it
// (`- **Total tasks**: 6`). Matching only the latter leaves the closing `**`
// stranded at the head of the value, which then fails every typed check.
const BULLET_RE = /^\s*[-*]\s*(?:\*\*([^*:]+?):\*\*|\*{0,2}([^:*]+?)\*{0,2}\s*:)\s*(.*)$/;

// Lines belonging to a field whose value did not fit on its own line. Stops at
// the next field, any heading, or a blank line once content has been gathered.
//
// This handles BOTH shapes, and the second is the dangerous one: a value that
// begins on the field's line and hard-wraps onto the next reads as complete
// while silently losing its tail. For "Done when" — the condition commits are
// gated on — a truncated value is worse than an empty one, because nothing
// downstream can tell it was cut.
function continuation(src, startIdx, seed) {
  const acc = seed ? [seed] : [];
  let j = startIdx + 1;
  for (; j < src.length; j++) {
    const nl = src[j];
    if (FIELD_RE.test(nl) || /^#{1,4}\s/.test(nl)) break;
    if (/^\s*$/.test(nl)) { if (acc.length) break; else continue; }
    acc.push(nl.trim());
  }
  return { value: acc.join(' '), next: j };
}

function parseDocument(text, schema) {
  const lines = text.split('\n');
  const doc = { items: {}, sections: {}, lists: {} };

  // Repeating items (### Task N: …), each owning the field lines beneath it.
  for (const item of schema.items) {
    const found = [];
    let cur = null;
    for (let li = 0; li < lines.length; li++) {
      const line = lines[li];
      const hm = item.heading.regex.exec(line);
      if (hm) {
        cur = { _raw: line, _fields: {} };
        item.heading.fields.forEach((f, i) => {
          cur[f.name] = f.type === 'int' ? Number(hm[i + 1]) : hm[i + 1].trim();
        });
        found.push(cur);
        continue;
      }
      if (!cur) continue;
      // A new top-level heading ends the current item.
      if (/^#{1,3}\s/.test(line) && !item.heading.regex.test(line)) { cur = null; continue; }
      const fm = FIELD_RE.exec(line);
      if (fm) {
        // A field whose value is empty on its own line continues onto the lines
        // below it — authors write multi-clause "Done when" as a bullet list,
        // and reading only the same-line remainder loses the whole condition.
        const c = continuation(lines, li, fm[2].trim());
        cur._fields[fm[1].trim()] = c.value;
        li = c.next - 1;
      }
    }
    doc.items[item.name] = found;
  }

  // Sections, keyed by heading, holding their raw body plus any list entries.
  for (const sec of schema.sections) {
    if (!sec.heading) continue;
    const startIdx = lines.findIndex((l) => sec.heading.regex.test(l));
    if (startIdx === -1) { doc.sections[sec.name] = null; continue; }
    const level = (lines[startIdx].match(/^#+/) || ['#'])[0].length;
    let endIdx = lines.length;
    for (let i = startIdx + 1; i < lines.length; i++) {
      const m = lines[i].match(/^(#+)\s/);
      if (m && m[1].length <= level) { endIdx = i; break; }
    }
    const bodyLines = lines.slice(startIdx + 1, endIdx);
    const entry = {
      _raw: bodyLines.join('\n'),
      _lines: bodyLines,
      _fields: {},
      _bullets: {},
      _list: [],
    };
    const hm = sec.heading.regex.exec(lines[startIdx]);
    if (hm) sec.heading.fields.forEach((f, i) => { entry[f.name] = hm[i + 1].trim(); });

    for (let li = 0; li < bodyLines.length; li++) {
      const line = bodyLines[li];
      const fm = FIELD_RE.exec(line);
      if (fm) {
        const cont = continuation(bodyLines, li, fm[2].trim());
        entry._fields[fm[1].trim()] = cont.value;
        li = cont.next - 1;
        continue;
      }
      const bm = line.match(BULLET_RE);
      if (bm) {
        const label = (bm[1] !== undefined ? bm[1] : bm[2]).trim();
        let val = (bm[3] || '').trim();
        if (!val) {
          // Indented lines under the bullet are its value (`- Risks:` + sub-bullets).
          const acc = [];
          let j = li + 1;
          for (; j < bodyLines.length; j++) {
            const nl = bodyLines[j];
            if (/^\s*$/.test(nl) || /^[-*]\s/.test(nl)) break;
            if (/^\s+\S/.test(nl)) { acc.push(nl.trim()); continue; }
            break;
          }
          val = acc.join(' ');
          li = j - 1;
        }
        entry._bullets[label] = val;
      }
    }

    if (sec.list) {
      entry._list = parseList(bodyLines, sec.list);
      doc.lists[sec.name] = entry._list;
      if (sec.list.opts.id) {
        const prefix = sec.list.opts.id.split('-{')[0];
        doc.lists[prefix] = entry._list;
      }
    }
    doc.sections[sec.name] = entry;
  }

  return doc;
}

function parseList(bodyLines, listSpec) {
  const out = [];
  const idSpec = listSpec.opts.id; // e.g. FR-{n:int}
  let idRe = null;
  let prefix = null;
  if (idSpec) {
    prefix = idSpec.split('-{')[0];
    // Tolerant of bullet/number decoration and bold, strict on the ID itself.
    idRe = new RegExp(`^\\s*(?:[-*]\\s*|\\d+[.)]\\s*)?\\*{0,2}${escapeRe(prefix)}-(\\d+)\\*{0,2}\\s*[:.\\-]?\\s*(.*)$`);
  }

  const ENTRY_RE = /^\s*(?:[-*]\s+|\d+[.)]\s+)(.+)$/;
  // A wrapped entry continues on indented lines that start no entry of their
  // own. Without this an entry is read as far as its first line and the tail is
  // dropped in silence — the same defect fixed for fields, and the reason a
  // user story loses its "so that" clause and a requirement loses its [US-n]
  // reference when authored at a sane column width.
  //
  // Indentation is the discriminator, and it is required: an unindented line
  // after a list is far more often the prose that follows the list than a
  // continuation of it, and absorbing prose into the last entry would corrupt
  // a value that currently parses correctly.
  const isContinuation = (line) => /^\s+\S/.test(line) && !ENTRY_RE.test(line);

  let cur = null;
  const open = (entry) => { out.push(entry); cur = entry; };

  for (const line of bodyLines) {
    // A blank line closes the current entry, so trailing prose separated from
    // the list cannot be absorbed into it.
    if (!line.trim()) { cur = null; continue; }
    if (cur && isContinuation(line)) {
      cur.text = `${cur.text} ${line.trim()}`;
      cur.raw = `${cur.raw} ${line.trim()}`;
      continue;
    }
    if (idRe) {
      const m = idRe.exec(line);
      if (m) { open({ id: Number(m[1]), text: m[2].trim(), raw: line.trim() }); continue; }
      // Unprefixed entries still count as list entries, so a missing ID is
      // reported as a violation rather than silently vanishing.
      const plain = line.match(ENTRY_RE);
      if (plain) { open({ id: null, text: plain[1].trim(), raw: line.trim() }); continue; }
      cur = null;
      continue;
    }
    const plain = line.match(ENTRY_RE);
    if (plain) { open({ id: null, text: plain[1].trim(), raw: line.trim() }); continue; }
    cur = null;
  }
  return out;
}

// ── Validation ───────────────────────────────────────────────────────────────

function parseRefs(value) {
  if (!value) return [];
  if (/^\s*(none|n\/a|-)\s*$/i.test(value)) return [];
  const ids = [];
  const re = /(?:[A-Z]{2,}-)?(\d+)/g;
  let m;
  while ((m = re.exec(value)) !== null) ids.push(Number(m[1]));
  return ids;
}

function validateDocument(doc, schema, opts = {}) {
  const errors = [];
  const warnings = [];

  // Items: count, required fields, none-allowed handling.
  for (const item of schema.items) {
    const found = doc.items[item.name] || [];
    if (found.length < (item.min || 0)) {
      errors.push(`expected at least ${item.min} ${item.name} entries, found ${found.length}`);
    }
    for (const inst of found) {
      const label = `${item.name} ${inst.id != null ? inst.id : `"${inst._raw.trim()}"`}`;
      for (const f of item.fields) {
        const has = Object.prototype.hasOwnProperty.call(inst._fields, f.label);
        const val = has ? inst._fields[f.label] : '';
        if (!has) {
          if (f.required) errors.push(`${label}: missing required field "${f.label}"`);
          continue;
        }
        if (f.required && !val) {
          errors.push(`${label}: field "${f.label}" is present but empty`);
          continue;
        }
        if (f.type === 'checkbox' && !/\[[ xX]\]/.test(val)) {
          errors.push(`${label}: field "${f.label}" is not a checkbox ("[ ]" or "[x]")`);
        }
        if (f.opts && f.opts.enum) {
          const allowed = f.opts.enum.split(',').map((s) => s.trim());
          if (!allowed.includes(val)) {
            errors.push(`${label}: field "${f.label}" is "${val}", expected one of ${allowed.join(', ')}`);
          }
        }
        // An unresolved template placeholder means the model echoed the format
        // instead of filling it in.
        if (/^\[.+\]$/.test(val) && !/\[[ xX]\]/.test(val)) {
          warnings.push(`${label}: field "${f.label}" looks like an unfilled template value: ${val}`);
        }
      }
    }
  }

  // Sections: presence, list cardinality, ID well-formedness, matchers.
  for (const sec of schema.sections) {
    const entry = doc.sections[sec.name];
    if (!entry) {
      if (sec.required !== false) errors.push(`missing required section "${sec.name}"`);
      continue;
    }
    for (const f of sec.fields) {
      const has = Object.prototype.hasOwnProperty.call(entry._fields, f.label);
      if (!has && f.required) {
        // Open Questions carry per-entry Impact/Owner; only flag when entries exist.
        const list = entry._list || [];
        if (!sec.list || list.length > 0) {
          errors.push(`section "${sec.name}": missing required field "${f.label}"`);
        }
      }
    }
    for (const b of sec.bullets) {
      const has = Object.prototype.hasOwnProperty.call(entry._bullets, b.label);
      if (!has) {
        if (b.required) errors.push(`section "${sec.name}": missing required bullet "${b.label}"`);
        continue;
      }
      const val = entry._bullets[b.label];
      if (b.required && !val) {
        errors.push(`section "${sec.name}": bullet "${b.label}" is empty`);
      }
      if (b.type === 'int' && !/^\d+$/.test(val.trim())) {
        errors.push(`section "${sec.name}": bullet "${b.label}" should be an integer, got "${val}"`);
      }
      // eq:count(Item) — the stated total must match what is actually in the doc.
      if (b.opts && b.opts.eq) {
        const cm = b.opts.eq.match(/^count\(([A-Za-z ]+)\)$/);
        if (cm) {
          const actual = (doc.items[cm[1].trim()] || []).length;
          const stated = Number((val.match(/\d+/) || [NaN])[0]);
          if (Number.isNaN(stated) || stated !== actual) {
            errors.push(
              `section "${sec.name}": bullet "${b.label}" says ${val || '(empty)'} ` +
              `but the document contains ${actual} ${cm[1].trim()} entries`
            );
          }
        }
      }
    }

    if (sec.list) {
      const list = entry._list || [];
      const emptyLiteral = sec.list.opts['empty-literal'];
      const isEmptyLiteral = emptyLiteral && entry._raw.trim().startsWith(emptyLiteral);
      const min = sec.list.opts.min != null ? Number(sec.list.opts.min) : 0;
      const max = sec.list.opts.max != null ? Number(sec.list.opts.max) : Infinity;

      if (!isEmptyLiteral) {
        if (list.length < min) {
          errors.push(`section "${sec.name}": expected at least ${min} entries, found ${list.length}`);
        }
        if (list.length > max) {
          errors.push(`section "${sec.name}": expected at most ${max} entries, found ${list.length}`);
        }
      }
      if (sec.list.opts.id) {
        const prefix = sec.list.opts.id.split('-{')[0];
        for (const e of list) {
          if (e.id == null) {
            errors.push(`section "${sec.name}": entry has no ${prefix}-N ID: "${truncate(e.raw)}"`);
          }
        }
      }
      if (sec.list.opts.match) {
        let re;
        try { re = new RegExp(sec.list.opts.match); } catch { re = null; }
        if (re) {
          for (const e of list) {
            if (e.id == null) continue;
            if (!re.test(e.text)) {
              errors.push(
                `section "${sec.name}": entry ${prefixOf(sec)}-${e.id} does not match required ` +
                `pattern /${sec.list.opts.match}/: "${truncate(e.text)}"`
              );
            }
          }
        }
      }
    }
  }

  // Graph checks.
  for (const g of schema.graph) {
    applyGraphCheck(g, doc, schema, errors, warnings);
  }

  // Location is part of the contract — downstream agents find these documents by
  // convention. A warning, not an error: repos legitimately keep specs elsewhere,
  // and the skills are told to follow an existing layout when one exists.
  if (opts.docPath && schema.outputPath) {
    const pattern = escapeRe(schema.outputPath).replace(/\\\{slug\\\}/g, '[A-Za-z0-9._-]+');
    if (!new RegExp(`(^|/)${pattern}$`).test(opts.docPath.replace(/\\/g, '/'))) {
      warnings.push(
        `${opts.docPath} is not at the conventional location for ${schema.id} ` +
        `(${schema.outputPath}) — agents that locate this document by convention will not find it`
      );
    }
  }

  // Cross-document: every requirement in the source spec must be covered exactly
  // once. Only runs when --against supplies the spec.
  if (opts.against) {
    crossCheck(doc, schema, opts.against, errors, warnings);
  }

  return { errors, warnings };
}

function prefixOf(sec) {
  return sec.list && sec.list.opts.id ? sec.list.opts.id.split('-{')[0] : '?';
}

function truncate(s, n = 60) {
  s = String(s || '');
  return s.length > n ? `${s.slice(0, n)}…` : s;
}

// Resolves `Task.id` / `Task.Depends on` / `FR.refs` against the parsed doc.
function resolveNodes(ref, doc) {
  const [holder, ...rest] = ref.split('.');
  const field = rest.join('.');
  if (doc.items[holder]) {
    return doc.items[holder].map((inst) => ({
      id: inst.id,
      value: field === 'id' ? inst.id : inst._fields[field],
    }));
  }
  if (doc.lists[holder]) {
    return doc.lists[holder].map((e) => ({ id: e.id, value: field === 'id' ? e.id : e.text }));
  }
  return null;
}

function applyGraphCheck(g, doc, schema, errors, warnings) {
  const nodes = resolveNodes(g.arg.split('->')[0].trim(), doc);

  switch (g.check) {
    case 'unique': {
      if (!nodes) return;
      const seen = new Set();
      for (const n of nodes) {
        if (n.id == null) continue;
        if (seen.has(n.id)) errors.push(`duplicate ID ${g.arg.split('.')[0]} ${n.id}`);
        seen.add(n.id);
      }
      return;
    }
    case 'sequential': {
      if (!nodes) return;
      const ids = nodes.map((n) => n.id).filter((v) => v != null).sort((a, b) => a - b);
      if (!ids.length) return;
      for (let i = 0; i < ids.length; i++) {
        if (ids[i] !== i + 1) {
          errors.push(
            `${g.arg.split('.')[0]} IDs must run 1..${ids.length} with no gaps — got [${ids.join(', ')}]`
          );
          return;
        }
      }
      return;
    }
    case 'acyclic': {
      if (!nodes) return;
      const graph = new Map();
      for (const n of nodes) graph.set(n.id, parseRefs(n.value));
      const state = new Map();
      const stack = [];
      const holder = g.arg.split('.')[0];
      let reported = false;
      const visit = (id) => {
        if (reported) return;
        if (state.get(id) === 'done') return;
        if (state.get(id) === 'active') {
          const cycle = [...stack.slice(stack.indexOf(id)), id];
          errors.push(`dependency cycle in ${holder}: ${cycle.join(' → ')}`);
          reported = true;
          return;
        }
        state.set(id, 'active');
        stack.push(id);
        for (const dep of graph.get(id) || []) {
          if (graph.has(dep)) visit(dep);
        }
        stack.pop();
        state.set(id, 'done');
      };
      for (const id of graph.keys()) visit(id);
      return;
    }
    case 'precedes': {
      if (!nodes) return;
      const holder = g.arg.split('.')[0];
      const known = new Set(nodes.map((n) => n.id));
      for (const n of nodes) {
        for (const dep of parseRefs(n.value)) {
          if (!known.has(dep)) {
            errors.push(`${holder} ${n.id} depends on ${holder} ${dep}, which does not exist`);
          } else if (dep >= n.id) {
            errors.push(
              `${holder} ${n.id} depends on ${holder} ${dep} — dependencies must come earlier ` +
              `in the list so the graph can be executed in order`
            );
          }
        }
      }
      return;
    }
    case 'resolves': {
      // `FR.refs -> US.id`
      const [fromRef, toRef] = g.arg.split('->').map((s) => s.trim());
      const [fromHolder] = fromRef.split('.');
      const [toHolder] = toRef.split('.');
      const fromList = doc.lists[fromHolder];
      const toList = doc.lists[toHolder];
      if (!fromList || !toList) return;
      const valid = new Set(toList.map((e) => e.id).filter((v) => v != null));
      const isBlocked = fromRef.endsWith('.blocked');
      for (const e of fromList) {
        if (e.id == null) continue;
        const re = isBlocked
          ? new RegExp(`\\[BLOCKED:\\s*${toHolder}-(\\d+)\\]`, 'g')
          : new RegExp(`\\[${toHolder}-(\\d+)\\]`, 'g');
        let m;
        let any = false;
        while ((m = re.exec(e.text)) !== null) {
          any = true;
          if (!valid.has(Number(m[1]))) {
            errors.push(
              `${fromHolder}-${e.id} references ${toHolder}-${m[1]}, which does not exist in this document`
            );
          }
        }
        if (!any && !isBlocked) {
          warnings.push(`${fromHolder}-${e.id} does not reference any ${toHolder} — mapping is incomplete`);
        }
      }
      return;
    }
    case 'partition': {
      // Each referenced requirement ID must be claimed by exactly one item.
      const [holder, ...rest] = g.arg.split('.');
      const field = rest.join('.');
      const insts = doc.items[holder] || [];
      const owner = new Map();
      for (const inst of insts) {
        for (const id of parseRefs(inst._fields[field])) {
          if (owner.has(id)) {
            errors.push(
              `requirement ${id} is claimed by both ${holder} ${owner.get(id)} and ${holder} ${inst.id} ` +
              `— each requirement must belong to exactly one ${holder}`
            );
          } else {
            owner.set(id, inst.id);
          }
        }
      }
      return;
    }
    default:
      warnings.push(`unknown graph check "${g.check}" in schema ${schema.id} (ignored)`);
  }
}

// Every FR in the source spec is covered by exactly one feature, and no feature
// invents a requirement the spec does not contain.
function crossCheck(doc, schema, againstPath, errors, warnings) {
  if (!fs.existsSync(againstPath)) {
    warnings.push(`--against file not found: ${againstPath}`);
    return;
  }
  const specText = fs.readFileSync(againstPath, 'utf8');
  const specIds = new Set();
  const re = /\bFR-(\d+)\b/g;
  let m;
  while ((m = re.exec(specText)) !== null) specIds.add(Number(m[1]));
  if (!specIds.size) {
    warnings.push(`no FR-N requirement IDs found in ${againstPath}; skipping coverage check`);
    return;
  }

  const covered = new Set();
  for (const item of schema.items) {
    for (const inst of doc.items[item.name] || []) {
      const field = item.fields.find((f) => /requirements covered/i.test(f.label));
      if (!field) continue;
      for (const id of parseRefs(inst._fields[field.label])) {
        if (!specIds.has(id)) {
          errors.push(
            `${item.name} ${inst.id} claims FR-${id}, which does not exist in ${path.basename(againstPath)}`
          );
        }
        covered.add(id);
      }
    }
  }
  const missing = [...specIds].filter((id) => !covered.has(id)).sort((a, b) => a - b);
  if (missing.length) {
    errors.push(
      `requirements in ${path.basename(againstPath)} not covered by any feature: ` +
      `${missing.map((i) => `FR-${i}`).join(', ')}`
    );
  }
}

// ── Derived JSON ─────────────────────────────────────────────────────────────

function deriveJson(doc, schema, sourcePath) {
  const out = {
    schema: schema.id,
    doc: schema.doc,
    source: sourcePath,
    conventional_path: schema.outputPath || null,
  };

  for (const item of schema.items) {
    out[item.name.toLowerCase() + 's'] = (doc.items[item.name] || []).map((inst) => {
      const o = { id: inst.id };
      for (const f of item.heading.fields) if (f.name !== 'id') o[f.name] = inst[f.name];
      for (const f of item.fields) {
        const key = f.label.toLowerCase().replace(/\s+/g, '_');
        const val = inst._fields[f.label];
        if (val === undefined) continue;
        if (/^(depends on|requirements covered)$/i.test(f.label)) o[key] = parseRefs(val);
        else if (f.type === 'checkbox') o[key] = /\[[xX]\]/.test(val);
        else o[key] = val;
      }
      return o;
    });
  }

  for (const sec of schema.sections) {
    const entry = doc.sections[sec.name];
    if (!entry) continue;
    const key = sec.name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
    if (sec.list) {
      out[key] = (entry._list || []).map((e) => ({ id: e.id, text: e.text }));
    } else if (Object.keys(entry._bullets).length) {
      out[key] = entry._bullets;
    } else if (Object.keys(entry._fields).length) {
      out[key] = entry._fields;
    } else {
      out[key] = entry._raw.trim();
    }
  }

  // Execution order for orchestrators: dependency-respecting topological sort.
  const taskItem = schema.items.find((i) => /task|feature/i.test(i.name));
  if (taskItem) {
    const insts = doc.items[taskItem.name] || [];
    const depsOf = new Map();
    for (const inst of insts) {
      const depField = taskItem.fields.find((f) => /depends on/i.test(f.label));
      depsOf.set(inst.id, depField ? parseRefs(inst._fields[depField.label]) : []);
    }
    const order = [];
    const seen = new Set();
    const visiting = new Set();
    const visit = (id) => {
      if (seen.has(id) || visiting.has(id)) return;
      visiting.add(id);
      for (const d of depsOf.get(id) || []) if (depsOf.has(d)) visit(d);
      visiting.delete(id);
      seen.add(id);
      order.push(id);
    };
    for (const id of [...depsOf.keys()].sort((a, b) => a - b)) visit(id);
    out.execution_order = order;

    // Dependency LEVELS. Tasks sharing a level have no dependency on one another
    // and may run concurrently; the flat order above is one legal serialisation
    // of this and discards the fact that any parallelism was available at all.
    const level = new Map();
    const computing = new Set();
    const depth = (id) => {
      if (level.has(id)) return level.get(id);
      if (computing.has(id)) return 0; // cycle: reported as an error elsewhere
      computing.add(id);
      const ds = (depsOf.get(id) || []).filter((d) => depsOf.has(d) && d !== id);
      const v = ds.length ? Math.max(...ds.map(depth)) + 1 : 0;
      computing.delete(id);
      level.set(id, v);
      return v;
    };
    for (const id of depsOf.keys()) depth(id);
    const waves = [];
    for (const id of order) (waves[level.get(id)] ||= []).push(id);
    out.execution_waves = waves.map((w) => w.sort((a, b) => a - b));

    // Same-wave file overlap. Two tasks can be dependency-independent and still
    // edit the same file — that is the collision a parallel runner discovers as
    // a merge conflict it cannot resolve. Declared "Files" makes it predictable
    // before any work is dispatched.
    const filesField = taskItem.fields.find((f) => /^files$/i.test(f.label));
    const pathsOf = new Map();
    for (const inst of insts) {
      const raw = filesField ? inst._fields[filesField.label] || '' : '';
      pathsOf.set(inst.id, new Set(
        (raw.match(/`([^`]+)`/g) || [])
          .map((s) => s.slice(1, -1).split(/\s*\(/)[0].trim())
          .filter((p) => /[/.]/.test(p)),
      ));
    }
    const conflicts = [];
    for (const w of out.execution_waves) {
      for (let a = 0; a < w.length; a++) {
        for (let b = a + 1; b < w.length; b++) {
          const other = pathsOf.get(w[b]) || new Set();
          const shared = [...(pathsOf.get(w[a]) || [])].filter((p) => other.has(p));
          if (shared.length) conflicts.push({ tasks: [w[a], w[b]], files: shared });
        }
      }
    }
    out.file_conflicts = conflicts;
  }

  return out;
}

// ── CLI ──────────────────────────────────────────────────────────────────────

function main(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--prompts') args.prompts = true;
    else if (a === '--list') args.list = true;
    else if (a === '--json') args.json = true;
    else if (a === '--quiet') args.quiet = true;
    else if (a === '--doc') args.doc = argv[++i];
    else if (a === '--schema') args.schemaId = argv[++i];
    else if (a === '--against') args.against = argv[++i];
    else if (a === '--help' || a === '-h') args.help = true;
  }

  if (args.help || (!args.prompts && !args.doc && !args.list)) {
    const header = fs.readFileSync(__filename, 'utf8').split('*/')[0];
    console.log(header.replace(/^\/\*\*?/, '').replace(/^ \* ?/gm, ''));
    return 0;
  }

  const { entries: registry, linkErrors } = loadSchemas();

  if (args.list) {
    for (const e of registry) {
      const counts = `${e.schema.items.length} items, ${e.schema.sections.length} sections, ${e.schema.graph.length} graph checks`;
      console.log(`${e.schema.id.padEnd(22)} ${e.schemaPath.padEnd(38)} → ${e.sourcePath}  (${counts})`);
    }
    for (const e of linkErrors) console.log(`${RED}FAIL${RESET}  ${e}`);
    return linkErrors.length ? 1 : 0;
  }

  if (args.prompts) {
    if (!registry.length && !linkErrors.length) {
      console.log(`${YELLOW}WARN${RESET}  No schemas found in schemas/*.schema.`);
      return 2;
    }
    let failed = false;
    for (const e of linkErrors) {
      failed = true;
      console.log(`${RED}FAIL${RESET}  ${e}`);
    }
    for (const entry of registry) {
      const errors = checkFormatDrift(entry);
      if (errors.length) {
        failed = true;
        for (const e of errors) console.log(`${RED}FAIL${RESET}  ${e}`);
      } else if (!args.quiet) {
        console.log(`${GREEN}PASS${RESET}  ${entry.sourcePath} → ${entry.schema.id}`);
      }
    }
    if (failed) {
      console.log('');
      console.log('  A schema in schemas/ and the output format authored in its source disagree.');
      console.log('  Fix whichever is wrong — they are the machine and human halves of one contract.');
      return 1;
    }
    console.log(`${GREEN}PASS${RESET}  ${registry.length} schemas consistent with their sources' authored formats.`);
    return 0;
  }

  // Document mode.
  if (!args.schemaId) {
    console.error('--doc requires --schema <id> (see --list)');
    return 1;
  }
  const entry = registry.find((e) => e.schema.id === args.schemaId);
  if (!entry) {
    console.error(`Unknown schema "${args.schemaId}". Known: ${registry.map((e) => e.schema.id).join(', ')}`);
    return 1;
  }
  if (!fs.existsSync(args.doc)) {
    console.error(`Document not found: ${args.doc}`);
    return 1;
  }

  const text = fs.readFileSync(args.doc, 'utf8');
  const doc = parseDocument(text, entry.schema);
  const { errors, warnings } = validateDocument(doc, entry.schema, {
    against: args.against,
    docPath: args.doc,
  });

  if (args.json) {
    if (errors.length) {
      console.error(JSON.stringify({ ok: false, errors, warnings }, null, 2));
      return 1;
    }
    console.log(JSON.stringify(deriveJson(doc, entry.schema, args.doc), null, 2));
    return 0;
  }

  for (const e of errors) console.log(`${RED}FAIL${RESET}  ${e}`);
  for (const w of warnings) console.log(`${YELLOW}WARN${RESET}  ${w}`);
  if (errors.length) {
    console.log('');
    console.log(`  ${args.doc} does not conform to ${entry.schema.id}.`);
    console.log(`  Regenerate or repair the document before handing it to an agent.`);
    return 1;
  }
  if (!args.quiet) {
    console.log(`${GREEN}PASS${RESET}  ${args.doc} conforms to ${entry.schema.id}${warnings.length ? ` (${warnings.length} warnings)` : ''}.`);
  }
  return warnings.length ? 2 : 0;
}

if (require.main === module) {
  process.exit(main(process.argv.slice(2)));
}

module.exports = { parseSchema, parseDocument, validateDocument, deriveJson, loadSchemas };

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { execSync } from 'child_process';

const __dirname = new URL('.', import.meta.url).pathname;
const KG_TOOL = process.env.KG_TOOL || `${__dirname}/../tools/kg`;

function runKg(args, cwd) {
  try {
    const result = execSync(`${KG_TOOL} ${args}`, {
      cwd: cwd || process.cwd(),
      timeout: 15000,
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return { ok: true, output: result.trim() };
  } catch (err) {
    return { ok: false, output: (err.stderr || err.stdout || err.message).trim() };
  }
}

function runCue(args, kgDir) {
  try {
    const result = execSync(`cue ${args}`, {
      cwd: kgDir,
      timeout: 15000,
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return { ok: true, output: result.trim() };
  } catch (err) {
    return { ok: false, output: (err.stderr || err.stdout || err.message).trim() };
  }
}

const server = new McpServer({
  name: 'quicue-kg',
  version: '0.1.0',
}, {
  instructions: 'Knowledge graph tools for querying decisions, patterns, insights, and rejected approaches. Check rejected approaches BEFORE suggesting solutions.',
});

// ── kg_index ─────────────────────────────────────────────────

server.tool(
  'kg_index',
  'Get knowledge graph summary or full index for the current project. Returns entry counts and categorized views.',
  { mode: z.enum(['summary', 'full', 'by_status', 'by_confidence', 'by_category']).default('summary').describe('What to export') },
  async ({ mode }) => {
    const kgDir = '.kg';
    let expr;
    switch (mode) {
      case 'summary': expr = '_index.summary'; break;
      case 'full': expr = '_index'; break;
      case 'by_status': expr = '_index.by_status'; break;
      case 'by_confidence': expr = '_index.by_confidence'; break;
      case 'by_category': expr = '_index.by_category'; break;
    }
    const result = runCue(`export . -e ${expr}`, kgDir);
    return { content: [{ type: 'text', text: result.output || '{}' }], isError: !result.ok };
  }
);

// ── kg_rejected ──────────────────────────────────────────────

server.tool(
  'kg_rejected',
  'List all rejected approaches. Use this BEFORE suggesting solutions to avoid recommending previously-failed approaches. Each rejection includes the reason it failed and what to do instead.',
  {},
  async () => {
    const result = runCue('export . -e _index.rejected', '.kg');
    if (!result.ok) {
      return { content: [{ type: 'text', text: 'No .kg/ or no rejected entries' }] };
    }
    try {
      const rejected = JSON.parse(result.output);
      const entries = Object.entries(rejected);
      if (entries.length === 0) {
        return { content: [{ type: 'text', text: 'No rejected approaches recorded.' }] };
      }
      const formatted = entries.map(([id, r]) =>
        `${id}: "${r.approach}" — REJECTED because: ${r.reason}\n  Use instead: ${r.alternative}`
      ).join('\n\n');
      return { content: [{ type: 'text', text: formatted }] };
    } catch {
      return { content: [{ type: 'text', text: result.output }] };
    }
  }
);

// ── kg_decisions ─────────────────────────────────────────────

server.tool(
  'kg_decisions',
  'List all architecture decisions with their status. Use this to understand project constraints and architectural choices.',
  {},
  async () => {
    const result = runCue('export . -e _index.decisions', '.kg');
    if (!result.ok) {
      return { content: [{ type: 'text', text: 'No .kg/ or no decisions' }] };
    }
    try {
      const decisions = JSON.parse(result.output);
      const entries = Object.entries(decisions);
      if (entries.length === 0) {
        return { content: [{ type: 'text', text: 'No decisions recorded.' }] };
      }
      const formatted = entries.map(([id, d]) =>
        `${id} [${d.status}]: ${d.title}\n  Context: ${d.context}\n  Decision: ${d.decision}`
      ).join('\n\n');
      return { content: [{ type: 'text', text: formatted }] };
    } catch {
      return { content: [{ type: 'text', text: result.output }] };
    }
  }
);

// ── kg_insights ──────────────────────────────────────────────

server.tool(
  'kg_insights',
  'List all validated insights with evidence and confidence levels.',
  {},
  async () => {
    const result = runCue('export . -e _index.insights', '.kg');
    if (!result.ok) {
      return { content: [{ type: 'text', text: 'No .kg/ or no insights' }] };
    }
    try {
      const insights = JSON.parse(result.output);
      const entries = Object.entries(insights);
      if (entries.length === 0) {
        return { content: [{ type: 'text', text: 'No insights recorded.' }] };
      }
      const formatted = entries.map(([id, i]) =>
        `${id} [${i.confidence}]: ${i.statement}\n  Evidence: ${i.evidence.join('; ')}\n  Implication: ${i.implication}`
      ).join('\n\n');
      return { content: [{ type: 'text', text: formatted }] };
    } catch {
      return { content: [{ type: 'text', text: result.output }] };
    }
  }
);

// ── kg_query ─────────────────────────────────────────────────

server.tool(
  'kg_query',
  'Query the knowledge graph with a CUE expression. Returns JSON.',
  { expression: z.string().describe('CUE expression to evaluate (e.g., "_index.decisions", "project")') },
  async ({ expression }) => {
    const result = runCue(`export . -e ${expression}`, '.kg');
    return { content: [{ type: 'text', text: result.output || '{}' }], isError: !result.ok };
  }
);

// ── kg_vet ───────────────────────────────────────────────────

server.tool(
  'kg_vet',
  'Validate all .kg/ entries against their CUE schemas. Returns validation errors or OK.',
  {},
  async () => {
    const result = runCue('vet .', '.kg');
    if (result.ok) {
      return { content: [{ type: 'text', text: 'OK: All .kg/ entries valid' }] };
    }
    return { content: [{ type: 'text', text: `Validation errors:\n${result.output}` }], isError: true };
  }
);

// ── kg_settle ────────────────────────────────────────────────

server.tool(
  'kg_settle',
  'Run knowledge graph settle — checks referential integrity, coverage gaps, dangling references, and stale proposals.',
  {},
  async () => {
    const result = runKg('settle');
    return { content: [{ type: 'text', text: result.output }], isError: !result.ok };
  }
);

// ── kg_lint ──────────────────────────────────────────────────

server.tool(
  'kg_lint',
  'Run knowledge quality lint checks — finds TODO placeholders, stale proposals, and confidence mismatches.',
  {},
  async () => {
    const result = runKg('lint');
    return { content: [{ type: 'text', text: result.output }], isError: !result.ok };
  }
);

// ── kg_graph ─────────────────────────────────────────────────

server.tool(
  'kg_graph',
  'Export knowledge graph as VizData JSON (nodes + edges from related links).',
  { format: z.enum(['json', 'dot']).default('json').describe('Output format') },
  async ({ format }) => {
    const result = runKg(`graph --${format}`);
    return { content: [{ type: 'text', text: result.output }], isError: !result.ok };
  }
);

// ── start ────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('kg-mcp-server running');
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});

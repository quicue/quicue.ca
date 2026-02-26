# Insights

14 validated discoveries from building the quicue ecosystem.

## INSIGHT-001: CUE transitive closure performance is topology-sensitive, not node-count-limited

**Method:** experiment | **Confidence:** high | **Discovered:** 2025-12-01

### Evidence

- NHCF scenario with 25 nodes timed out — but due to wide fan-in, not node count
- Reducing to 18 nodes brought eval under 4 seconds by reducing fan-in

### Implication

Minimize edge density and fan-in for large graphs; Python precompute is a fallback for high-fan-in topologies

**Related:** [ADR-001](../decisions/adr-001.md)

---

## INSIGHT-002: CUE exports ALL public (capitalized) fields, causing unexpected JSON bloat

**Method:** observation | **Confidence:** high | **Discovered:** 2025-11-15

### Evidence

- #VizExport with public Graph field exported the entire input graph (75KB vs 17KB expected)

### Implication

Export-facing definitions must use hidden fields (_prefix) for intermediate data

**Related:** [ADR-002](../decisions/adr-002.md)

---

## INSIGHT-003: CUE packages are directory-scoped — multi-graph knowledge bases leverage this for independent validation

**Method:** experiment | **Confidence:** high | **Discovered:** 2026-02-15

### Evidence

- .kb/ subdirectories create separate package instances — each graph validates independently

### Implication

Knowledge bases use typed subdirectories: each graph is an independent CUE package with its own cue.mod/

**Related:** [ADR-001](../decisions/adr-001.md)

---

## INSIGHT-004: Production data leaks through generated artifacts, not just source code

**Method:** observation | **Confidence:** high | **Discovered:** 2026-02-18

### Evidence

- cat.quicue.ca had 98 real 172.20.x.x IPs in generated JSON
- Deploying safe data missed pre-existing files with different naming conventions

### Implication

When replacing data on public surfaces, grep -rl for real IPs across the ENTIRE web root

**Related:** [ADR-006](../decisions/adr-006.md)

---

## INSIGHT-005: cue vet does not fully evaluate hidden fields — test assertions on hidden values give false confidence

**Method:** experiment | **Confidence:** high | **Discovered:** 2026-02-18

### Evidence

- charter_test.cue asserts on a hidden field — cue vet passed even with conflicting values

### Implication

For critical invariants, use public fields or run cue eval -e to force evaluation

**Related:** [ADR-005](../decisions/adr-005.md), [ADR-007](../decisions/adr-007.md)

---

## INSIGHT-006: Everything is a projection of the same typed dependency graph — 72+ projections exist

**Method:** cross_reference | **Confidence:** high | **Discovered:** 2026-02-18

### Evidence

- Terraform, Ansible, Rundeck, Jupyter, MkDocs, bash, HTTP, OpenAPI, Justfile, JSON-LD, Graphviz, Mermaid, TOON, N-Triples, DCAT — all from the same graph

### Implication

The graph is the single source of truth. Every artifact is a derived projection.

**Related:** INSIGHT-002

---

## INSIGHT-007: CUE unification obviates SPARQL — precomputed comprehensions ARE the query layer

**Method:** experiment | **Confidence:** high | **Discovered:** 2026-02-18

### Evidence

- 8 query patterns implemented as CUE definitions, no triplestore needed

### Implication

SPARQL is unnecessary for the primary use case. CUE comprehensions precompute all graph queries at eval time.

**Related:** INSIGHT-006

---

## INSIGHT-008: When CUE comprehensions pre-compute all possible answers, the API is just a file server

**Method:** experiment | **Confidence:** high | **Discovered:** 2026-02-18

### Evidence

- 727 static JSON files replace FastAPI with zero server runtime

### Implication

If your domain model is a closed world and CUE comprehensions compute all queries at eval time, a CDN is the optimal runtime.

**Related:** INSIGHT-007, [ADR-012](../decisions/adr-012.md)

---

## INSIGHT-009: Airgapped deployment has 8 reproducible traps

**Method:** experiment | **Confidence:** high | **Discovered:** 2026-02-19

### Evidence

- E2E deployment on fresh Ubuntu 24.04 VM hit all 8 traps: ensurepip, typing_extensions, raptor2, cue.mod symlinks, Docker bind-mount, Caddy TLS, CUE OOM, grep pipefail

### Implication

Every package manager assumes internet access. Airgapped deployment has its own failure modes.

**Related:** [ADR-013](../decisions/adr-013.md)

---

## INSIGHT-010: Three latent bugs in patterns/ went undetected because CUE's lax evaluation hides struct iteration errors

**Method:** observation | **Confidence:** high | **Discovered:** 2026-02-19

### Evidence

- #BootstrapPlan used len(depends_on) as depth proxy — wrong for peer resources
- #ValidateGraph was defined in BOTH graph.cue and type-contracts.cue — CUE silently unified them
- #DependencyValidation iterated depends_on as an array but the codebase uses struct-as-set

### Implication

CUE's lazy evaluation means bugs hide in definitions that are syntactically valid but semantically wrong. Critical patterns need exercising examples.

**Related:** INSIGHT-003

---

## INSIGHT-011: W3C vocabulary alignment is mostly projection work — CUE's typed data already has the structure

**Method:** cross_reference | **Confidence:** high | **Discovered:** 2026-02-19

### Evidence

- depends_on mapped from quicue:dependsOn to dcterms:requires — zero code change, just one IRI swap
- #ComplianceCheck results already have the structure of sh:ValidationReport — 20 lines to project

### Implication

When your data model is already typed and validated by CUE, W3C compliance is a thin projection layer.

**Related:** INSIGHT-006, INSIGHT-007

---

## INSIGHT-012: ASCII-safe identifier constraints catch unicode injection at compile time

**Method:** cross_reference | **Confidence:** high | **Discovered:** 2026-02-19

### Evidence

- Cyrillic 'a' vs Latin 'a' creates distinct CUE keys that look identical
- Zero-width space in 'dnsserver' never matches 'dnsserver' in depends_on

### Implication

CUE's type system can enforce input validation at compile time. Unicode safety is a schema constraint.

**Related:** [ADR-014](../decisions/adr-014.md), INSIGHT-005

---

## INSIGHT-013: Export-facing CUE definitions systematically lack W3C @context and @id

**Method:** cross_reference | **Confidence:** high | **Discovered:** 2026-02-20

### Evidence

- 7 files producing structured output without proper JSON-LD framing
- Files WITH proper alignment were added intentionally, not systematically

### Implication

W3C compliance must be architectural, not ad-hoc. Every export-facing definition should include @context, @type, and dct:conformsTo.

**Related:** INSIGHT-011, INSIGHT-006

---

## INSIGHT-014: Cloudflare API tokens are stored in ~/.ssh/ — the working token is cf-tk.token, not ~/.cf_env

**Method:** observation | **Confidence:** high | **Discovered:** 2026-02-20

### Evidence

- ~/.cf_env exports CF_API_KEY — wrangler rejects it
- ~/.ssh/cf-tk.token contains working CLOUDFLARE_API_TOKEN

### Implication

Token management needs a single source of truth. CF_API_KEY vs CLOUDFLARE_API_TOKEN naming mismatch caused repeated deploy failures.

**Related:** INSIGHT-004


---
*Generated from quicue.ca registries by `#DocsProjection`*
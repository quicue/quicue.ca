# ASCII-Safe Identifiers

**Category:** security

## Problem

CUE unification treats strings as opaque byte sequences. Unicode homoglyphs (Cyrillic 'a' vs Latin 'a'), zero-width characters (U+200B), and RTL overrides (U+202E) create visually identical but structurally distinct keys. A `depends_on` reference with an invisible character silently fails to match its target.

## Solution

Constrain all graph identifiers to ASCII via regex at the definition layer. `#SafeID` for resource names and dependency references. `#SafeLabel` for type names, tags, and registry keys. `cue vet` enforces at compile time with zero runtime cost.

```cue
#SafeID:    =~"^[a-zA-Z][a-zA-Z0-9_.-]*$"
#SafeLabel: =~"^[a-zA-Z][a-zA-Z0-9_-]*$"
```

## Context

Any CUE schema where string values participate in struct key lookup, unification, or cross-reference. Especially critical for `@type` (provider matching), `depends_on` (graph edges), and `name` (identity).

## Used In

- apercue
- quicue.ca
- cmhc-retrofit
- grdn
- maison-613

## Related

- struct_as_set
- contract_via_unification

---
*Generated from quicue.ca registries by `#DocsProjection`*

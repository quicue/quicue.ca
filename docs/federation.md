# Federation

quicue.ca projects federate knowledge through CUE's type system and W3C linked data standards. No external triplestore needed — CUE unification IS the merge operation.

## Downstream Consumers

| Project | Module | Patterns | Status |
|---------|--------|----------|--------|
| [grdn](https://quicue.ca/project/grdn) | `grdn.quicue.ca` | 14 | active |
| [cmhc-retrofit](https://quicue.ca/project/cmhc-retrofit) | `quicue.ca/cmhc-retrofit@v0` | 15 | active |
| [maison-613](https://rfam.cc/project/maison-613) | `rfam.cc/maison-613@v0` | 14 | active |

## How Federation Works

Multiple teams maintain independent `.kb/` directories. "Federating" is importing and letting CUE unify. Contradictory assertions produce unification errors — caught at build time.

CUE struct unification is:

- **Commutative** — import order doesn't matter
- **Idempotent** — importing the same fact twice is harmless
- **Conflict-detecting** — contradictory values fail loudly

## Cross-References

SKOS vocabulary alignment enables cross-namespace navigation:

- `skos:exactMatch` — "See also" links between equivalent concepts
- `skos:closeMatch` — "Related" links between similar concepts
- `skos:broader` / `skos:narrower` — hierarchical breadcrumbs

---
*Generated from quicue.ca registries by `#DocsProjection`*
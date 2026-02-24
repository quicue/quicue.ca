# SBOM Dependency Graph

CycloneDX software bill of materials projected as an `#InfraGraph`. A Python
adapter converts CycloneDX JSON into typed resources where components are nodes
and dependency relationships become `depends_on` edges.

## Run

```bash
# Generate resources from a CycloneDX BOM
python tools/cyclonedx2graph.py examples/sbom/testdata/sample-bom.json \
    --metadata -o examples/sbom/resources.cue -p sbom

# Evaluate
cue eval ./examples/sbom/ -e output.summary
cue eval ./examples/sbom/ -e output.single_points_of_failure
```

## What it demonstrates

- Adapter pattern: CycloneDX JSON converted to quicue.ca graph
- SPOF analysis on software dependencies -- which packages are critical
- Supply chain risk analysis using the same patterns as infrastructure

# CI Pipeline Graph

GitLab CI pipeline projected as an `#InfraGraph`. A Python adapter converts
`.gitlab-ci.yml` into typed resources where jobs are nodes and `needs`/`dependencies`
become `depends_on` edges.

## Run

```bash
# Generate resources from a GitLab CI file
python tools/gitlab-ci2graph.py examples/ci/testdata/sample-pipeline.yml \
    --metadata -o examples/ci/resources.cue -p ci

# Evaluate
cue eval ./examples/ci/ -e output.summary
cue eval ./examples/ci/ -e output.single_points_of_failure
```

## What it demonstrates

- Adapter pattern: external format (YAML) converted to quicue.ca graph
- SPOF analysis on CI pipelines -- which jobs are bottlenecks
- Same `#InfraGraph` patterns work on CI pipelines, not just infrastructure

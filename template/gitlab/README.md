# GitLab Provider

GitLab project and CI/CD management via API.

## Requirements

- curl or glab CLI, GITLAB_TOKEN set

## Usage

```cue
import "quicue.ca/template/gitlab/patterns"

actions: patterns.#GitLabRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

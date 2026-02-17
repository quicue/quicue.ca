# ArgoCD Provider

GitOps continuous delivery via ArgoCD CLI.

## Requirements

- argocd CLI, argocd login completed

## Usage

```cue
import "quicue.ca/template/argocd/patterns"

actions: patterns.#ArgoCDRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

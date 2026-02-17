# Kubernetes Provider

Kubernetes cluster management via kubectl CLI.

## Requirements

- kubectl installed, KUBECONFIG configured

## Usage

```cue
import "quicue.ca/template/kubectl/patterns"

actions: patterns.#KubectlRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

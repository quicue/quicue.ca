# KubeVirt Provider

Virtual machine management on Kubernetes via virtctl.

## Requirements

- virtctl CLI, kubeconfig configured

## Usage

```cue
import "quicue.ca/template/kubevirt/patterns"

actions: patterns.#KubeVirtRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

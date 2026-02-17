# Zabbix Provider

Enterprise monitoring via Zabbix API.

## Requirements

- curl, Zabbix API URL and auth token

## Usage

```cue
import "quicue.ca/template/zabbix/patterns"

actions: patterns.#ZabbixRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

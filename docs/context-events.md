# Context Events

Context events are timestamped records of federation boundary crossings: merges, validations, projections, and exports between domain graphs. Each event records what happened, which domains were involved, which resources were affected, and the outcome.

When graphs from different domains interact (monitoring merged into datacenter, datacenter validated against compliance rules, infrastructure projected to a DCAT catalog), the event log captures the temporal audit trail.

## W3C mapping

Each context event maps to two W3C types:

- **prov:Activity** ([PROV-O](https://www.w3.org/TR/prov-o/)) for the operation itself, with `prov:used` for inputs and `prov:generated` for outputs
- **time:Instant** ([OWL-Time](https://www.w3.org/TR/owl-time/)) for the event timestamp

The event log maps to **prov:Collection**, containing all event activities as `prov:hadMember` entries.

Three extension terms cover concepts without W3C equivalents:

| Term | Purpose |
|------|---------|
| `apercue:ContextEvent` | Event class (specializes prov:Activity) |
| `apercue:ContextEventLog` | Log class (specializes prov:Collection) |
| `apercue:outcome` | Result: success, conflict, or partial |

## Vocab definition

`vocab/context_event.cue` defines the event type:

```cue
#ContextEvent: {
    timestamp:     =~"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}"
    type:          "merge" | "validate" | "project" | "export"
    source_domain: #SafeID
    target_domain: #SafeID
    resources:     [...#SafeID]
    outcome:       "success" | "conflict" | "partial"
    provenance_ref?: string
    description?:    string
}
```

## Pattern instantiation

`patterns/context_event.cue` provides `#ContextEventLog`, which projects a list of events as PROV-O + OWL-Time JSON-LD:

```cue
#ContextEventLog: {
    Events: [...vocab.#ContextEvent]
    Agent?: string
    event_report: { "@context": ..., "@graph": [...] }
    summary: { total_events: ..., domains: ..., by_type: ..., by_outcome: ... }
}
```

## Datacenter wiring

```cue
_event_log: apercue_patterns.#ContextEventLog & {
    Events: _events
    Agent:  "urn:agent:datacenter-controller"
}
context_events: _event_log.event_report
```

## Example output

One event from the datacenter example (abbreviated):

```json
{
  "@type": ["prov:Activity", "apercue:ContextEvent"],
  "@id": "urn:event:monitoring-datacenter-merge-0",
  "dcterms:title": "merge: monitoring -> datacenter",
  "dcterms:type": "merge",
  "prov:startedAtTime": "2026-03-01T09:00:00Z",
  "prov:wasAssociatedWith": { "@id": "urn:agent:datacenter-controller" },
  "apercue:outcome": "success",
  "prov:used": [
    { "@id": "urn:domain:monitoring" },
    { "@id": "urn:resource:zabbix" },
    { "@id": "urn:resource:caddy-proxy" }
  ],
  "prov:generated": { "@id": "urn:domain:datacenter" },
  "time:hasTime": {
    "@type": "time:Instant",
    "@id": "urn:instant:monitoring-datacenter-0",
    "time:inXSDDateTimeStamp": "2026-03-01T09:00:00Z"
  }
}
```

## Export

```bash
cue export ./examples/datacenter/ -e context_events --out json
```

See the [timeline visualization](https://demo.quicue.ca/context-events.html) for an interactive view.

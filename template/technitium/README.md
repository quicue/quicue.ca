# technitium

DNS management via Technitium DNS Server REST API.

## Requirements

- `curl`
- Technitium DNS Server with web API enabled
- API token

## Actions

| Action | Category | Description |
|--------|----------|-------------|
| `zone_list` | info | List all DNS zones |
| `zone_create` | admin | Create a new primary zone |
| `zone_delete` | admin | Delete a zone (destructive) |
| `zone_enable` | admin | Enable a zone |
| `zone_disable` | admin | Disable a zone |
| `record_add` | admin | Add a DNS record |
| `record_get` | info | Get records for a zone |
| `record_delete` | admin | Delete a DNS record (destructive) |
| `conditional_forwarder_create` | admin | Create a conditional forwarder |
| `settings_get` | info | Get server settings |
| `stats` | monitor | Get server statistics |

## Resource fields

| Field | Description |
|-------|-------------|
| `technitium_api_url` | Base URL of the Technitium web API |
| `technitium_token` | API authentication token |
| `zone_name` | DNS zone to operate on |

## Usage

```cue
import "quicue.ca/template/technitium/patterns"

_providers: technitium: {
    "@type": {DNSServer: true}
    actions: patterns.#TechnitiumRegistry
}
```

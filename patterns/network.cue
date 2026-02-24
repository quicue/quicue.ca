// Network zone classification and normalization patterns.
//
// Extracts zone normalization logic from infra-graph/scripts/analysis.py
// for reusable CUE-based zone validation and grouping.
//
// SIDs use free-text network zones with many variants. This provides:
// - Canonical zone enum for validation
// - Zone alias mappings (free-text → canonical)
// - Grouping and summary helpers for zone-based analysis
//
// Usage:
//   import "quicue.ca/patterns:network"
//
//   resources: {
//       dns: {zone: "restricted", ...}
//       web: {networkLocation: "dmz", ...}
//   }
//
//   // Classify resources by zone
//   zoneClassifier: network.#ZoneClassifier & {Resources: resources}
//   // zoneClassifier.classified.dns = "Restricted"
//   // zoneClassifier.classified.web = "DMZ"
//

package patterns

// #NetworkZone - Canonical network zone enumeration
//
// These are the normalized zone names used across infra analysis.
// All free-text zone variants should map to one of these.
#NetworkZone: "Restricted" | "Intranet" | "Campus LAN" | "DMZ" | "Internet" | "Admin VDI" | "Management" | "Storage" | "Cloud" | "Unknown"

// #ZoneAliases - Map of lowercase zone strings to canonical zones
//
// Based on ZONE_ALIASES from analysis.py (lines 11-27).
// Keys are lowercase for case-insensitive matching.
// Resources with zone/networkLocation fields should be normalized via lookup.
//
// Note: CUE doesn't have runtime string.ToLower(), so users must
// pre-normalize keys before lookup or use external tooling.
#ZoneAliases: {
	// Restricted zone variants
	"restricted":      "Restricted"
	"restricted zone": "Restricted"
	"trusted zone":    "Restricted"
	"trusted":         "Restricted"

	// Intranet zone variants
	"intranet":      "Intranet"
	"intranet zone": "Intranet"
	"common zone":   "Intranet"

	// Campus LAN variants
	"campus lan": "Campus LAN"
	"campus":     "Campus LAN"
	"lan":        "Campus LAN"

	// Internet
	"internet": "Internet"

	// DMZ variants
	"dmz": "DMZ"
	"paz": "DMZ"

	// Admin VDI variants
	"admin vdi": "Admin VDI"
	"vdi":       "Admin VDI"

	// Allow extension for additional zones
	[string]: #NetworkZone
}

// #ZoneClassifier - Classify resources by their network zone
//
// Reads zone or networkLocation fields from resources and maps them
// to canonical zone names via #ZoneAliases.
//
// IMPORTANT: This pattern expects pre-normalized (lowercase) zone values,
// or you must normalize externally (e.g., Python, jq) before feeding to CUE.
//
// Usage:
//   classifier: #ZoneClassifier & {
//       Resources: {
//           dns: {zone: "restricted", ...}
//           web: {networkLocation: "dmz", ...}
//       }
//   }
//   // classifier.classified = {dns: "Restricted", web: "DMZ"}
//
#ZoneClassifier: {
	// Input: resources with optional zone/networkLocation fields
	Resources: [string]: {
		zone?:            string
		networkLocation?: string
		ip?:              string
		...
	}

	// Output: resource name → canonical zone
	// Preference: zone field > networkLocation field > "Unknown"
	classified: {
		for rname, r in Resources {
			(rname): *#ZoneAliases[r.zone] |
				*#ZoneAliases[r.networkLocation] |
				"Unknown"
		}
	}

	// Summary: count resources per zone
	summary: {
		for rname, zone in classified {
			(zone): (*0 | int) + 1
		}
	}
}

// #ZoneGrouping - Group resources by their network zone
//
// Takes classified zones (from #ZoneClassifier) and groups resource names
// by zone for set operations or export.
//
// Usage:
//   grouping: #ZoneGrouping & {
//       Zones: classifier.classified
//   }
//   // grouping.groups.Restricted = {dns: true, auth: true}
//   // grouping.summary.Restricted = 2
//
#ZoneGrouping: {
	// Input: map of resource name → canonical zone
	Zones: [string]: #NetworkZone

	// Output: zone → {resource: true} (struct-as-set for O(1) membership)
	groups: {
		for rname, zone in Zones {
			(zone): {
				(rname): true
			}
		}
	}

	// Summary: count of resources per zone
	summary: {
		for zoneName, members in groups {
			(zoneName): len([for m, _ in members {m}])
		}
	}

	// Export: zone → [resource] (arrays for JSON/external tools)
	arrays: {
		for zoneName, members in groups {
			(zoneName): [for m, _ in members {m}]
		}
	}
}

// #ZoneMatrix - Cross-reference zones with resource types
//
// Builds a matrix of zone × type → resource count for analysis.
//
// Usage:
//   matrix: #ZoneMatrix & {
//       Zones: classifier.classified
//       Types: {dns: {DNSServer: true}, web: {WebServer: true}}
//   }
//   // matrix.cells.Restricted.DNSServer = {dns: true}
//
#ZoneMatrix: {
	// Input: resource → zone mapping
	Zones: [string]: #NetworkZone

	// Input: resource → type mapping (assumes {Type: true} struct)
	Types: [string]: {[string]: true}

	// Output: zone → type → [resources]
	cells: {
		for rname, zone in Zones {
			(zone): {
				for t, _ in Types[rname] {
					(t): (rname): true
				}
			}
		}
	}

	// Summary: zone → type → count
	summary: {
		for zone, types in cells {
			(zone): {
				for t, members in types {
					(t): len([for m, _ in members {m}])
				}
			}
		}
	}
}

// #ZoneRisk - Identify zone-based security risks
//
// Flags resources that:
// - Cross zone boundaries (depends_on across zones)
// - Are exposed to Internet zone
// - Use Unknown zone (unmapped/unvalidated)
//
// Usage:
//   risk: #ZoneRisk & {
//       Zones: classifier.classified
//       Dependencies: {web: {db: true}, ...}
//   }
//   // risk.cross_zone = [{from: "web", to: "db", from_zone: "DMZ", to_zone: "Restricted"}]
//
#ZoneRisk: {
	// Input: resource → zone
	Zones: [string]: #NetworkZone

	// Input: resource → {dependency: true}
	Dependencies: [string]: {[string]: true}

	// Resources exposed to Internet zone
	internet_exposed: {
		for rname, zone in Zones
		if zone == "Internet" {(rname): true}
	}

	// Resources with unknown/unmapped zones
	unknown_zone: {
		for rname, zone in Zones
		if zone == "Unknown" {(rname): true}
	}

	// Cross-zone dependencies (potential security boundaries)
	cross_zone: [
		for rname, deps in Dependencies
		for dep, _ in deps
		let from_zone = Zones[rname]
		let to_zone = Zones[dep]
		if from_zone != to_zone {
			from:      rname
			to:        dep
			from_zone: from_zone
			to_zone:   to_zone
		},
	]

	// Summary counts
	summary: {
		internet_exposed: len([for r, _ in internet_exposed {r}])
		unknown_zone: len([for r, _ in unknown_zone {r}])
		cross_zone_flows: len(cross_zone)
	}
}

// #ZoneExport - Export zone data for external tools (Python, web UI)
//
// Converts CUE zone structures to flat arrays for JSON export.
//
// Usage:
//   export: #ZoneExport & {Classifier: myClassifier, Grouping: myGrouping}
//   // cue export -e export.data --out json
//
#ZoneExport: {
	Classifier: #ZoneClassifier
	Grouping:   #ZoneGrouping

	data: {
		// Canonical zone list
		zones: [
			"Restricted",
			"Intranet",
			"Campus LAN",
			"DMZ",
			"Internet",
			"Admin VDI",
			"Management",
			"Storage",
			"Cloud",
			"Unknown",
		]

		// Zone aliases for UI autocomplete
		aliases: #ZoneAliases

		// Resource classifications (name → zone)
		classified: Classifier.classified

		// Resources grouped by zone (zone → [names])
		groups: Grouping.arrays

		// Summary counts
		summary: Grouping.summary

		// Total resource count
		total: len([for r, _ in Classifier.classified {r}])
	}
}

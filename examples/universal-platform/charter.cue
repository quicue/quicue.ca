// Bootstrap completion tracking — 3 gates
//
// Tracks progress from schema validation through to working visualization.

package platform

_charter: {
	name:    "universal-platform"
	version: "0.1.0"

	gates: {
		schema: {
			label:       "Schema"
			description: "CUE schema validates for all 4 tiers"
			criteria: [
				"cue vet passes",
				"All 4 tiers export valid JSON",
				"Topology assertions hold",
			]
		}
		binding: {
			label:       "Binding"
			description: "Provider actions resolve for all tiers"
			criteria: [
				"Desktop: docker commands resolve",
				"Node: proxmox + service commands resolve",
				"Cluster: k3d + kubectl commands resolve",
				"Enterprise: govc + ops commands resolve",
			]
		}
		visualization: {
			label:       "Visualization"
			description: "Explorer renders graph with tier switching"
			criteria: [
				"Graph renders with correct topology",
				"Tier tabs switch data without re-layout",
				"Commands display in detail panel",
				"Impact query shows blast radius for storage (10 dependents)",
			]
		}
	}
}

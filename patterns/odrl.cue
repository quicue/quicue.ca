// ODRL access policies — W3C Open Digital Rights Language from CUE declarations.
//
// Expresses machine-readable access policies for infrastructure data.
// Policies declare who (assignee) can perform what action (read, modify)
// on which resources (target pattern), under what constraints.
//
// ODRL declares policies — enforcement is external (Cloudflare Access, Caddy, etc.)
//
// Usage:
//   import "quicue.ca/patterns"
//   policy: patterns.#ODRLPolicy & {
//       PolicyID: "https://data.example.org/policy/infra-read"
//       Permissions: [{
//           Action: "odrl:read", Assignee: "infra-team", Target: "*"
//       }]
//   }
//   // cue export -e policy.policy --out json > policy.jsonld

package patterns

import "quicue.ca/vocab"

// #ODRLContext — extends quicue context with ODRL namespace.
#ODRLContext: vocab.context["@context"] & {
	"odrl": "http://www.w3.org/ns/odrl/2/"
	"dct":  "http://purl.org/dc/terms/"
	"xsd":  "http://www.w3.org/2001/XMLSchema#"
}

// #ODRLPermission — a single permission rule.
#ODRLPermission: {
	Action:   "odrl:read" | "odrl:modify" | "odrl:distribute" | "odrl:derive" | "odrl:use"
	Assignee: string
	Target:   string
	Constraint?: {
		LeftOperand:  string
		Operator:     "odrl:eq" | "odrl:gt" | "odrl:lt" | "odrl:isPartOf" | "odrl:isA"
		RightOperand: string
	}
}

// #ODRLProhibition — a single prohibition rule.
#ODRLProhibition: {
	Action:   "odrl:read" | "odrl:modify" | "odrl:distribute" | "odrl:derive" | "odrl:delete"
	Assignee: string
	Target:   string
}

// #ODRLPolicy — generates an ODRL 2.2 policy document.
#ODRLPolicy: {
	PolicyID: string
	Label:    string | *""
	Permissions: [...#ODRLPermission]
	Prohibitions: [...#ODRLProhibition]

	policy: {
		"@context": #ODRLContext
		"@type":    "odrl:Policy"
		"@id":      PolicyID

		if Label != "" {
			"dct:title": Label
		}

		"odrl:permission": [
			for p in Permissions {
				"odrl:action":   p.Action
				"odrl:assignee": p.Assignee
				"odrl:target":   p.Target
				if p.Constraint != _|_ {
					"odrl:constraint": {
						"odrl:leftOperand":  p.Constraint.LeftOperand
						"odrl:operator":     p.Constraint.Operator
						"odrl:rightOperand": p.Constraint.RightOperand
					}
				}
			},
		]

		if len(Prohibitions) > 0 {
			"odrl:prohibition": [
				for p in Prohibitions {
					"odrl:action":   p.Action
					"odrl:assignee": p.Assignee
					"odrl:target":   p.Target
				},
			]
		}
	}
}

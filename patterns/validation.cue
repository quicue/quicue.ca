// Validation Patterns for Infrastructure Graphs
//
// Generic validators and compliance checking are re-exported from
// apercue — the domain-agnostic upstream. #IPRangeValidation remains
// local as infrastructure-specific validation.
//
// Usage:
//   import "quicue.ca/patterns"
//
//   myValidation: patterns.#UniqueFieldValidation & {
//       _resources: myInfra.resources
//       _field: "ip"
//   }
package patterns

import (
	"strings"
	"quicue.ca/vocab"
	apercue "apercue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════
// GENERIC VALIDATORS — re-exported from apercue
// ═══════════════════════════════════════════════════════════════════════════

#UniqueFieldValidation:    apercue.#UniqueFieldValidation
#ReferenceValidation:      apercue.#ReferenceValidation
#RequiredFieldsValidation: apercue.#RequiredFieldsValidation
#DependencyValidation:     apercue.#DependencyValidation

#TypeValidation: apercue.#TypeValidation

// ═══════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE-SPECIFIC VALIDATION
// ═══════════════════════════════════════════════════════════════════════════

// #IPRangeValidation ensures IPs are within allowed ranges
#IPRangeValidation: {
	// Input: resources and IP prefix patterns
	_resources: [string]: vocab.#Resource
	_allowedPrefix: string // e.g., "10.0." or "192.168."

	// Check each resource's IP
	_invalidIPs: [
		for name, resource in _resources
		if resource.ip != _|_
		if !strings.HasPrefix(resource.ip, _allowedPrefix) {
			resource: name
			ip:       resource.ip
			message:  "Resource '" + name + "' has IP '" + resource.ip + "' outside allowed range '" + _allowedPrefix + "*'"
		},
	]

	valid:  len(_invalidIPs) == 0
	issues: _invalidIPs
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPLIANCE CHECKING — re-exported from apercue
// ═══════════════════════════════════════════════════════════════════════════

#ComplianceRule:  apercue.#ComplianceRule
#ComplianceCheck: apercue.#ComplianceCheck

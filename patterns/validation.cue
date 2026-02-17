// Validation Patterns for Infrastructure Graphs
// Provides compile-time validation via CUE constraints
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
)

// #UniqueFieldValidation ensures a field is unique across all resources
// Creates CUE evaluation errors if duplicates found
#UniqueFieldValidation: {
	// Input: resources collection and field to validate
	_resources: [string]: vocab.#Resource
	_field:     string

	// Extract field values
	_values: {
		for name, resource in _resources {
			if resource[_field] != _|_ {
				(name): resource[_field]
			}
		}
	}

	// Build list of names for iteration
	_names: [for n, _ in _values {n}]

	// Detect duplicates by comparing all pairs
	_duplicates: [
		for i, nameA in _names
		for j, nameB in _names
		if i < j && _values[nameA] == _values[nameB] {
			field:     _field
			value:     _values[nameA]
			resources: [nameA, nameB]
			message:   "Duplicate " + _field + ": '" + "\(_values[nameA])" + "' used by " + nameA + " and " + nameB
		},
	]

	// Fail validation if duplicates exist
	// Creates impossible constraint that CUE catches at eval time
	for dup in _duplicates {
		(dup.resources[0] + "_" + dup.resources[1] + "_" + _field + "_duplicate"): {
			_error: dup.message
			_fail:  true
			_fail:  false // Impossible: creates validation error
		}
	}

	// Expose results
	valid:  len(_duplicates) == 0
	issues: _duplicates
}

// #ReferenceValidation ensures references point to existing resources
// Validates at CUE evaluation time
#ReferenceValidation: {
	// Input: source resources, target collection, and reference field name
	_sources:  [string]: vocab.#Resource
	_targets:  [string]: _
	_refField: string // Field name in source that references target

	// Check each reference
	_missingRefs: [
		for sourceName, source in _sources
		if source[_refField] != _|_ {
			let ref = source[_refField]
			if _targets[ref] == _|_ {
				source:  sourceName
				field:   _refField
				target:  ref
				message: "Resource '" + sourceName + "' references non-existent " + _refField + " '" + ref + "'"
			}
		},
	]

	// Fail validation if missing references exist
	for missing in _missingRefs {
		(missing.source + "_" + _refField + "_missing_ref"): {
			_error: missing.message
			_fail:  true
			_fail:  false
		}
	}

	valid:  len(_missingRefs) == 0
	issues: _missingRefs
}

// #RequiredFieldsValidation ensures required fields are present on all resources
// Validates at CUE evaluation time
#RequiredFieldsValidation: {
	// Input: resources and list of required field names
	_resources:      [string]: vocab.#Resource
	_requiredFields: [...string]

	// Check each resource for required fields
	_missingFields: [
		for name, resource in _resources
		for field in _requiredFields
		if resource[field] == _|_ {
			resource: name
			field:    field
			message:  "Resource '" + name + "' missing required field '" + field + "'"
		},
	]

	// Fail validation if missing fields exist
	for missing in _missingFields {
		(missing.resource + "_missing_" + missing.field): {
			_error: missing.message
			_fail:  true
			_fail:  false
		}
	}

	valid:  len(_missingFields) == 0
	issues: _missingFields
}

// #DependencyValidation ensures depends_on references exist
// Specialized version of #ReferenceValidation for dependencies
#DependencyValidation: {
	// Input: resources collection
	_resources: [string]: vocab.#Resource

	// Check all depends_on references
	_brokenDeps: [
		for name, resource in _resources
		if resource.depends_on != _|_
		for dep in resource.depends_on
		if _resources[dep] == _|_ {
			source:     name
			dependency: dep
			message:    "Resource '" + name + "' depends on non-existent resource '" + dep + "'"
		},
	]

	// Fail validation if broken dependencies exist
	for broken in _brokenDeps {
		(broken.source + "_broken_dep_" + broken.dependency): {
			_error: broken.message
			_fail:  true
			_fail:  false
		}
	}

	valid:  len(_brokenDeps) == 0
	issues: _brokenDeps
}

// #TypeValidation ensures @type struct contains only valid types
#TypeValidation: {
	// Input: resources and allowed types
	_resources:    [string]: vocab.#Resource
	_allowedTypes: [...string]

	// Build set of allowed types
	_typeSet: {for t in _allowedTypes {(t): true}}

	// Check each resource's types (struct-as-set)
	_invalidTypes: [
		for name, resource in _resources
		if resource["@type"] != _|_
		for t, _ in resource["@type"]
		if _typeSet[t] == _|_ {
			resource: name
			badType:  t
			message:  "Resource '" + name + "' has invalid @type '" + t + "'"
		},
	]

	valid:  len(_invalidTypes) == 0
	issues: _invalidTypes
}

// #IPRangeValidation ensures IPs are within allowed ranges
#IPRangeValidation: {
	// Input: resources and IP prefix patterns
	_resources:     [string]: vocab.#Resource
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

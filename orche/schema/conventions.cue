// Schema Conventions - Enforce set membership over lists where appropriate
// Run: cue vet ./... to validate all files against these conventions
package schema

// =============================================================================
// SET MEMBERSHIP TYPES - Use these instead of lists for unordered collections
// =============================================================================

// #StringSet - Set of strings (most common)
// Enforces: {key1: true, key2: true, ...}
#StringSet: {[string]: true}

// #DependsOn - Dependencies must be sets, not lists
// WRONG: depends_on: ["network", "dns"]
// RIGHT: depends_on: {network: true, dns: true}
#DependsOn: #StringSet

// #TypeSet - Type membership (e.g., {Database: true, PostgreSQL: true})
#TypeSet: #StringSet

// #Tags - Resource tags
#Tags: #StringSet

// #Capabilities - Feature capabilities
#Capabilities: #StringSet

// =============================================================================
// LIST TYPES - Use these for ordered collections where order matters
// =============================================================================

// #OrderedList - Explicitly ordered items (execution order, priority, failover)
#OrderedList: [...string]

// #Ports - Port mappings (order doesn't matter but list is conventional)
#Ports: [...string]

// #Volumes - Volume mappings
#Volumes: [...string]

// #Command - Command arguments (order matters)
#Command: [...string]

// =============================================================================
// VALIDATION HELPERS
// =============================================================================

// #Resource - Base resource with enforced conventions
#Resource: {
	name:       string
	depends_on: #DependsOn // Enforced as set
	type?:      #TypeSet   // Enforced as set
	tags?:      #Tags      // Enforced as set
	...
}

// #ValidateDependsOn - Use to check if a value conforms to set pattern
// Example: _check: #ValidateDependsOn & {value: my_depends_on}
#ValidateDependsOn: {
	value: #DependsOn
}

// =============================================================================
// ERGONOMIC HELPERS - Make sets easier to declare
// =============================================================================

// #Deps - Shorthand for common dependency patterns
#Deps: {
	// Pre-defined common dependencies (just unify what you need)
	network:  true
	dns:      true
	database: true
	auth:     true
	cache:    true
	storage:  true

	// Allow any additional
	[string]: true
}

// Usage example:
// depends_on: #Deps & {network: _, dns: _, custom: true}
// Or just: depends_on: {network: true, dns: true}

// =============================================================================
// ANTI-PATTERNS - These will fail validation if used
// =============================================================================

// #NotAList - Constraint that rejects lists
// Use: field: #NotAList & actual_value
#NotAList: {
	[string]: _ // Must be a struct, not a list
}

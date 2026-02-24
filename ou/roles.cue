// Operator roles — predefined visibility scopes for interaction contexts.
//
// Roles use struct-as-set for visible_categories (ADR-002).
// A role constrains which action categories are visible in the scoped view.
// Custom roles can be defined by instantiating #OperatorRole directly.
//
// Usage:
//   import "quicue.ca/ou"
//
//   session: ou.#InteractionCtx & {
//       role: ou.#Roles.ops
//   }

package ou

// #OperatorRole — defines which action categories an operator can see.
// Categories match vocab.#Action.category values: info, connect, monitor, admin.
#OperatorRole: {
	name: string
	visible_categories: {[string]: true}
}

// Predefined roles.
#Roles: {
	// ops — full operational access (all categories)
	ops: #OperatorRole & {
		name: "ops"
		visible_categories: {
			info:    true
			connect: true
			monitor: true
			admin:   true
		}
	}

	// dev — read and connect only (no admin or monitor)
	dev: #OperatorRole & {
		name: "dev"
		visible_categories: {
			info:    true
			connect: true
		}
	}

	// readonly — information only
	readonly: #OperatorRole & {
		name: "readonly"
		visible_categories: {
			info: true
		}
	}
}

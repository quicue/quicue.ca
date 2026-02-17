// Resource - Core resource definition for infrastructure-as-graph
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   resources: [Name=string]: vocab.#Resource & { name: Name }
//
// Field naming: Use generic names. Providers map to platform-specific commands.
//   container_id (not lxcid) → Proxmox: pct, Docker: container name
//   vm_id (not vmid)         → Proxmox: qm, VMware: VM ID
//   host (not node)          → Proxmox: node, Docker: host, K8s: node

package vocab

// #Resource - Core resource definition
// Every infrastructure resource conforms to this schema
#Resource: {
	// Identity
	name:   string
	"@id"?: string | *"https://infra.example.com/resources/\(name)"

	// Semantic types (struct-as-set for O(1) membership checks)
	"@type": {[string]: true}

	// Network
	ip?:   string
	fqdn?: string

	// Hosting - generic fields, providers map to platform-specific
	host?:         string       // Hypervisor/node name (Proxmox node, Docker host, K8s node)
	container_id?: int | string // Container identifier (Proxmox LXCID, Docker container name/hash)
	vm_id?:        int | string // VM identifier (Proxmox VMID, VMware VM ID, cloud instance ID)
	hosted_on?:    string       // Parent resource name

	// Dependencies (set membership for clean unification)
	depends_on?: {[string]: true}

	// Access
	ssh_user?: string

	// Capabilities this resource provides (set membership)
	provides?: {[string]: true}

	// Actions - filled by #BindCluster (provider-namespaced: actions.provider.action)
	actions?: [string]: [string]: #Action

	// Metadata (set membership)
	tags?: {[string]: true}
	description?: string

	// Allow domain-specific extensions
	...
}

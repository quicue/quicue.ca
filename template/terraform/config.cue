package terraform

// #TerraformConfig - Provider and backend configuration
//
// Generates terraform{} and provider{} blocks for main.tf.json.
// Without Config, output is resource-only (backward compatible).
#TerraformConfig: {
	// Provider versions
	ProxmoxVersion:    *">=0.66.0" | string
	KubernetesVersion: *">=2.35.0" | string

	// Backend (local by default)
	Backend?: #Backend

	// Proxmox provider connection
	Proxmox?: #ProxmoxProvider

	// Kubernetes provider connection (for KubeVirt)
	Kubernetes?: #KubernetesProvider
}

// #Backend - Terraform state backend
#Backend: {
	type:   "local" | "s3" | "http"
	config: {...}
}

// #ProxmoxProvider - bpg/proxmox provider configuration
#ProxmoxProvider: {
	endpoint: string
	insecure: bool | *true

	// Auth: API token (preferred) or username/password
	api_token?: string
	username?:  string
	password?:  string

	// SSH for file operations
	ssh?: {
		agent:    bool | *true
		username: *"root" | string
		nodes?: [...{
			name:    string
			address: string
		}]
	}
}

// #KubernetesProvider - hashicorp/kubernetes provider
#KubernetesProvider: {
	config_path?:    string
	config_context?: string
	host?:           string
	token?:          string
}

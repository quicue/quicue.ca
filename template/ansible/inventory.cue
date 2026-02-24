package ansible

// #AnsibleInventory - Generate Ansible inventory structure from resources
//
// Produces the standard Ansible inventory format:
//   all.hosts     - host entries with connection params and platform vars
//   all.children  - groups from tags, owners, and PVE nodes
//
// Usage:
//   cue export -e inventory.all --out yaml
#AnsibleInventory: {
	Resources: [string]: {
		ip?:       string
		ssh_user?: string
		user?:     string
		ssh_port?: int
		tags?: {[string]: true}
		vm_id?:                      int
		vmid?:                       int
		container_id?:               int
		host?:                       string
		node?:                       string
		owner?:                      string
		ansible_become?:             bool
		ansible_python_interpreter?: string
		...
	}

	// Configurable defaults (UPPERCASE = cross-package safe)
	DefaultUser:              *"root" | string
	DefaultPythonInterpreter: *"/usr/bin/python3" | string

	all: {
		hosts: {
			for name, res in Resources
			if res.ip != _|_ {
				"\(name)": {
					ansible_host: res.ip
					ansible_user: *res.ssh_user | *res.user | DefaultUser

					if res.ssh_port != _|_ {
						ansible_port: res.ssh_port
					}
					if res.ansible_become != _|_ {
						ansible_become: res.ansible_become
					}

					if res.ansible_python_interpreter != _|_ {
						ansible_python_interpreter: res.ansible_python_interpreter
					}
					if res.ansible_python_interpreter == _|_ {
						ansible_python_interpreter: "/usr/bin/python3"
					}

					if res.vmid != _|_ {vmid: res.vmid}
					if res.vm_id != _|_ {vmid: res.vm_id}
					if res.container_id != _|_ {container_id: res.container_id}
					if res.node != _|_ {pve_node: res.node}
					if res.host != _|_ {pve_node: res.host}
					if res.owner != _|_ {owner: res.owner}
				}
			}
		}

		children: {
			// Tag-based groups
			let _all_tags = {
				for _, res in Resources
				if res.tags != _|_ {
					for tag, _ in res.tags {
						"\(tag)": true
					}
				}
			}
			for tag, _ in _all_tags {
				"\(tag)": hosts: {
					for name, res in Resources
					if res.ip != _|_
					if res.tags != _|_
					if res.tags[tag] != _|_ {
						"\(name)": {}
					}
				}
			}

			// Owner-based groups: owner_<name>
			let _owners = {
				for _, res in Resources
				if res.owner != _|_ {
					"\(res.owner)": true
				}
			}
			for owner, _ in _owners {
				"owner_\(owner)": hosts: {
					for name, res in Resources
					if res.ip != _|_
					if res.owner != _|_
					if res.owner == owner {
						"\(name)": {}
					}
				}
			}

			// Node-based groups: node_<name>
			let _nodes = {
				for _, res in Resources {
					if res.host != _|_ {"\(res.host)": true}
					if res.node != _|_ {"\(res.node)": true}
				}
			}
			for nodeName, _ in _nodes {
				"node_\(nodeName)": hosts: {
					for name, res in Resources
					if res.ip != _|_ {
						if res.host != _|_ {
							if res.host == nodeName {
								"\(name)": {}
							}
						}
						if res.node != _|_ {
							if res.node == nodeName {
								"\(name)": {}
							}
						}
					}
				}
			}
		}
	}
}

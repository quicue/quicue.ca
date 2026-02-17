// patterns/credentials.cue
// Credential collection patterns

package boot

// #Collector is a generic credential collector pattern
#Collector: {
	// Allow method-specific fields
	...

	// What to collect
	name:        string
	description: string | *""

	// How to collect
	method: "ssh" | "docker" | "kubectl" | "file" | "command"

	// Collection command (generated based on method + params)
	collect: string
}

// #SSHCollector collects credentials via SSH
#SSHCollector: #Collector & {
	method: "ssh"

	// SSH parameters
	host:    string
	user:    string | *"root"
	command: string

	// Generated collection command
	collect: "ssh \(user)@\(host) '\(command)'"
}

// #DockerCollector collects from docker container
#DockerCollector: #Collector & {
	method: "docker"

	// Docker parameters
	container: string
	command:   string

	// Generated collection command
	collect: "docker exec \(container) \(command)"
}

// #KubectlCollector collects from Kubernetes
#KubectlCollector: #Collector & {
	method: "kubectl"

	// K8s parameters
	namespace:  string | *"default"
	resource:   string
	jsonpath?:  string
	kubeconfig: string | *""

	// Generated collection command
	collect: {
		if kubeconfig != "" {
			"kubectl --kubeconfig=\(kubeconfig) -n \(namespace) get \(resource)" + {
				if jsonpath != _|_ {" -o jsonpath='\(jsonpath)'"}
				if jsonpath == _|_ {""}
			}
		}
		if kubeconfig == "" {
			"kubectl -n \(namespace) get \(resource)" + {
				if jsonpath != _|_ {" -o jsonpath='\(jsonpath)'"}
				if jsonpath == _|_ {""}
			}
		}
	}
}

// #FileCollector reads from a file path
#FileCollector: #Collector & {
	method: "file"

	// File parameters
	path:  string
	host?: string

	// Generated collection command
	collect: {
		if host != _|_ {"ssh root@\(host) 'cat \(path)'"}
		if host == _|_ {"cat \(path)"}
	}
}

// #CredentialBundle is the output of credential collection
#CredentialBundle: {
	metadata: {
		collected_at: string | *"$(date -Iseconds)"
		source:       string
	}

	credentials: [string]: {
		type:  string
		value: string | *"<collected>"
		path?: string
	}
}

// Kubernetes - Cluster management via kubectl
//
// Requires: kubectl, KUBECONFIG
//
// Usage:
//   import "quicue.ca/template/kubectl/patterns"

package patterns

import "quicue.ca/vocab"

#KubectlRegistry: {
	get_pods: vocab.#ActionDef & {
		name:        "get_pods"
		description: "List pods in namespace"
		category:    "info"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get pods -n {namespace} -o wide"
		idempotent:       true
	}

	get_services: vocab.#ActionDef & {
		name:        "get_services"
		description: "List services in namespace"
		category:    "info"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get svc -n {namespace}"
		idempotent:       true
	}

	get_deployments: vocab.#ActionDef & {
		name:        "get_deployments"
		description: "List deployments in namespace"
		category:    "info"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get deployments -n {namespace}"
		idempotent:       true
	}

	get_nodes: vocab.#ActionDef & {
		name:        "get_nodes"
		description: "List cluster nodes with status and resources"
		category:    "info"
		params: {}
		command_template: "kubectl get nodes -o wide"
		idempotent:       true
	}

	get_namespaces: vocab.#ActionDef & {
		name:        "get_namespaces"
		description: "List all namespaces"
		category:    "info"
		params: {}
		command_template: "kubectl get namespaces"
		idempotent:       true
	}

	describe_pod: vocab.#ActionDef & {
		name:        "describe_pod"
		description: "Detailed pod info including events"
		category:    "info"
		params: {
			pod_name: {from_field: "pod_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "kubectl describe pod {pod_name} -n {namespace}"
		idempotent:       true
	}

	logs: vocab.#ActionDef & {
		name:        "logs"
		description: "View pod container logs"
		category:    "monitor"
		params: {
			pod_name: {from_field: "pod_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "kubectl logs {pod_name} -n {namespace} --tail=100"
		idempotent:       true
	}

	apply: vocab.#ActionDef & {
		name:        "apply"
		description: "Apply manifest to cluster"
		category:    "admin"
		params: manifest_path: {from_field: "manifest_path"}
		command_template: "kubectl apply -f {manifest_path}"
	}

	delete_resource: vocab.#ActionDef & {
		name:        "delete_resource"
		description: "Delete a Kubernetes resource"
		category:    "admin"
		params: {
			resource_type: {}
			resource_name: {}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "kubectl delete {resource_type} {resource_name} -n {namespace}"
		destructive:      true
	}

	rollout_status: vocab.#ActionDef & {
		name:        "rollout_status"
		description: "Check deployment rollout progress"
		category:    "monitor"
		params: {
			deployment: {from_field: "deployment_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "kubectl rollout status deployment/{deployment} -n {namespace}"
		idempotent:       true
	}

	rollout_restart: vocab.#ActionDef & {
		name:        "rollout_restart"
		description: "Restart deployment pods"
		category:    "admin"
		params: {
			deployment: {from_field: "deployment_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "kubectl rollout restart deployment/{deployment} -n {namespace}"
	}

	top_pods: vocab.#ActionDef & {
		name:        "top_pods"
		description: "Resource usage by pod"
		category:    "monitor"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl top pods -n {namespace}"
		idempotent:       true
	}

	top_nodes: vocab.#ActionDef & {
		name:        "top_nodes"
		description: "Resource usage by node"
		category:    "monitor"
		params: {}
		command_template: "kubectl top nodes"
		idempotent:       true
	}

	exec: vocab.#ActionDef & {
		name:        "exec"
		description: "Execute command in pod container"
		category:    "connect"
		params: {
			pod_name: {from_field: "pod_name"}
			namespace: {from_field: "namespace", required: false}
			command: {}
		}
		command_template: "kubectl exec -it {pod_name} -n {namespace} -- {command}"
	}

	port_forward: vocab.#ActionDef & {
		name:        "port_forward"
		description: "Forward local port to pod"
		category:    "connect"
		params: {
			pod_name: {from_field: "pod_name"}
			namespace: {from_field: "namespace", required: false}
			port_map: {}
		}
		command_template: "kubectl port-forward {pod_name} {port_map} -n {namespace}"
	}

	get_events: vocab.#ActionDef & {
		name:        "get_events"
		description: "List recent cluster events"
		category:    "monitor"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get events -n {namespace} --sort-by=.lastTimestamp"
		idempotent:       true
	}

	scale: vocab.#ActionDef & {
		name:        "scale"
		description: "Scale deployment replicas"
		category:    "admin"
		params: {
			deployment: {from_field: "deployment_name"}
			namespace: {from_field: "namespace", required: false}
			replicas: {}
		}
		command_template: "kubectl scale deployment/{deployment} --replicas={replicas} -n {namespace}"
	}

	get_all: vocab.#ActionDef & {
		name:        "get_all"
		description: "List all resources in namespace"
		category:    "info"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get all -n {namespace} -o wide"
		idempotent:       true
	}

	get_ingress: vocab.#ActionDef & {
		name:        "get_ingress"
		description: "List ingress resources"
		category:    "info"
		params: namespace: {from_field: "namespace", required: false}
		command_template: "kubectl get ingress -n {namespace}"
		idempotent:       true
	}

	...
}

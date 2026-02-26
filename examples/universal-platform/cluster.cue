// Cluster tier — k3d + kubectl, Kubernetes-native
//
// Lightweight Kubernetes cluster via k3d (k3s-in-Docker).
// All services run as Kubernetes deployments with namespaced isolation.

package platform

// Merge shared topology with cluster-specific types and fields
_cluster_resources: {
	for rname, base in _topology {
		(rname): {"@id": _site.base_id + "cluster/" + rname, name: rname} & base
	}
}
_cluster_resources: _cluster_fields

_cluster_fields: {
	gateway: {
		"@type":        {KubernetesCluster: true}
		ip:             "192.0.2.1"
		cluster_name:   "platform-cluster"
		description:    "k3d cluster — ingress gateway"
	}
	auth: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "keycloak-0"
		deployment_name:   "keycloak"
		description:       "Keycloak identity provider"
	}
	storage: {
		"@type":        {KubernetesCluster: true}
		ip:             "192.0.2.2"
		cluster_name:   "platform-storage"
		description:    "Longhorn storage cluster"
	}
	dns: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "coredns-0"
		deployment_name:   "coredns"
		description:       "CoreDNS deployment"
	}
	database: {
		"@type":           {KubernetesService: true, Database: true}
		namespace:         "platform"
		pod_name:          "postgresql-0"
		deployment_name:   "postgresql"
		db_host:           "postgresql.platform.svc"
		db_port:           "5432"
		db_name:           "platform"
		description:       "PostgreSQL StatefulSet"
	}
	cache: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "redis-0"
		deployment_name:   "redis"
		description:       "Redis StatefulSet"
	}
	queue: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "rabbitmq-0"
		deployment_name:   "rabbitmq"
		description:       "RabbitMQ StatefulSet"
	}
	proxy: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "traefik-0"
		deployment_name:   "traefik"
		description:       "Traefik ingress controller"
	}
	worker: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "worker-0"
		deployment_name:   "worker"
		description:       "Background worker deployment"
	}
	api: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "api-0"
		deployment_name:   "api"
		manifest_path:     "k8s/api.yaml"
		description:       "API server deployment"
	}
	frontend: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "frontend-0"
		deployment_name:   "frontend"
		description:       "Web frontend deployment"
	}
	admin: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "admin-0"
		deployment_name:   "admin"
		description:       "Admin panel deployment"
	}
	scheduler: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "scheduler-0"
		deployment_name:   "scheduler"
		description:       "Job scheduler deployment"
	}
	backup: {
		"@type":           {KubernetesService: true}
		namespace:         "platform"
		pod_name:          "backup-0"
		deployment_name:   "backup"
		description:       "Backup CronJob"
	}
	monitoring: {
		"@type":           {KubernetesService: true}
		namespace:         "monitoring"
		pod_name:          "prometheus-0"
		deployment_name:   "prometheus"
		description:       "Prometheus + Grafana stack"
	}
}

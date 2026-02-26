// Desktop tier — Docker-only, runs on a single machine
//
// All 15 resources run as Docker containers on the local daemon.
// Simplest possible deployment: laptop, dev workstation, CI runner.

package platform

// Merge shared topology with desktop-specific types and fields
_desktop_resources: {
	for rname, base in _topology {
		(rname): {"@id": _site.base_id + "desktop/" + rname, name: rname} & base
	}
}
_desktop_resources: _desktop_fields

_desktop_fields: {
	gateway: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-gateway"
		description:     "Edge router container"
	}
	auth: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-auth"
		description:     "Identity provider container"
	}
	storage: {
		"@type":         {DockerHost: true}
		ip:              "127.0.0.1"
		description:     "Local Docker volumes"
	}
	dns: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-dns"
		host:            "gateway"
		description:     "CoreDNS container"
	}
	database: {
		"@type":         {DockerContainer: true, Database: true}
		container_name:  "platform-db"
		host:            "storage"
		db_host:         "127.0.0.1"
		db_port:         "5432"
		db_name:         "platform"
		description:     "PostgreSQL container"
	}
	cache: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-cache"
		host:            "storage"
		description:     "Redis cache container"
	}
	queue: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-queue"
		host:            "storage"
		description:     "RabbitMQ container"
	}
	proxy: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-proxy"
		host:            "gateway"
		description:     "Caddy reverse proxy container"
	}
	worker: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-worker"
		description:     "Background worker container"
	}
	api: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-api"
		description:     "API server container"
	}
	frontend: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-frontend"
		description:     "Web frontend container"
	}
	admin: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-admin"
		description:     "Admin panel container"
	}
	scheduler: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-scheduler"
		description:     "Job scheduler container"
	}
	backup: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-backup"
		description:     "Backup agent container"
	}
	monitoring: {
		"@type":         {DockerContainer: true}
		container_name:  "platform-mon"
		description:     "Prometheus + Grafana container"
	}
}

// Action templates for Docker-based infrastructure
// These are pure data templates - consuming projects apply conditionals
//
// IMPORTANT: Template parameters use UPPERCASE names (CONTAINER, IMAGE, etc.)
// because CUE hidden fields (_foo) are package-scoped and don't unify
// across import boundaries. Uppercase fields are visible and unify correctly.
//
// Fields use `| *` defaults so consumers can override specific values
// while keeping other fields from the template.
package patterns

// #ActionTemplates - Building blocks for action generation
// Usage:
//   import "quicue.ca/docker/patterns"
//   _T: patterns.#ActionTemplates
//   actions: { status: _T.container_status & {CONTAINER: "nginx"} }
#ActionTemplates: {
	// =========================================================================
	// Container actions
	// =========================================================================
	container_status: {
		CONTAINER:   string
		name:        string | *"Status"
		description: string | *"Check container \(CONTAINER) status"
		command:     string | *"docker inspect -f '{{.State.Status}}' \(CONTAINER)"
		icon:        string | *"[status]"
		category:    string | *"monitor"
	}

	container_logs: {
		CONTAINER:   string
		LINES:       int | *100
		name:        string | *"Logs"
		description: string | *"View container \(CONTAINER) logs"
		command:     string | *"docker logs --tail \(LINES) \(CONTAINER)"
		icon:        string | *"[logs]"
		category:    string | *"monitor"
	}

	container_shell: {
		CONTAINER:   string
		SHELL:       string | *"/bin/sh"
		name:        string | *"Shell"
		description: string | *"Open shell in container \(CONTAINER)"
		command:     string | *"docker exec -it \(CONTAINER) \(SHELL)"
		icon:        string | *"[shell]"
		category:    string | *"connect"
	}

	container_start: {
		CONTAINER:   string
		name:        string | *"Start"
		description: string | *"Start container \(CONTAINER)"
		command:     string | *"docker start \(CONTAINER)"
		icon:        string | *"[start]"
		category:    string | *"admin"
	}

	container_stop: {
		CONTAINER:   string
		name:        string | *"Stop"
		description: string | *"Stop container \(CONTAINER)"
		command:     string | *"docker stop \(CONTAINER)"
		icon:        string | *"[stop]"
		category:    string | *"admin"
	}

	container_restart: {
		CONTAINER:   string
		name:        string | *"Restart"
		description: string | *"Restart container \(CONTAINER)"
		command:     string | *"docker restart \(CONTAINER)"
		icon:        string | *"[restart]"
		category:    string | *"admin"
	}

	container_exec: {
		CONTAINER:   string
		COMMAND:     string
		name:        string | *"Execute"
		description: string | *"Execute command in container \(CONTAINER)"
		command:     string | *"docker exec \(CONTAINER) \(COMMAND)"
		icon:        string | *"[exec]"
		category:    string | *"admin"
	}

	container_inspect: {
		CONTAINER:   string
		name:        string | *"Inspect"
		description: string | *"Inspect container \(CONTAINER)"
		command:     string | *"docker inspect \(CONTAINER)"
		icon:        string | *"[inspect]"
		category:    string | *"info"
	}

	container_top: {
		CONTAINER:   string
		name:        string | *"Top"
		description: string | *"Show running processes in container \(CONTAINER)"
		command:     string | *"docker top \(CONTAINER)"
		icon:        string | *"[top]"
		category:    string | *"monitor"
	}

	container_stats: {
		CONTAINER:   string
		name:        string | *"Stats"
		description: string | *"Show resource usage for container \(CONTAINER)"
		command:     string | *"docker stats --no-stream \(CONTAINER)"
		icon:        string | *"[stats]"
		category:    string | *"monitor"
	}

	container_kill: {
		CONTAINER:   string
		name:        string | *"Kill"
		description: string | *"Force kill container \(CONTAINER)"
		command:     string | *"docker kill \(CONTAINER)"
		icon:        string | *"[kill]"
		category:    string | *"admin"
	}

	container_pause: {
		CONTAINER:   string
		name:        string | *"Pause"
		description: string | *"Pause container \(CONTAINER)"
		command:     string | *"docker pause \(CONTAINER)"
		icon:        string | *"[pause]"
		category:    string | *"admin"
	}

	container_unpause: {
		CONTAINER:   string
		name:        string | *"Unpause"
		description: string | *"Unpause container \(CONTAINER)"
		command:     string | *"docker unpause \(CONTAINER)"
		icon:        string | *"[unpause]"
		category:    string | *"admin"
	}

	container_remove: {
		CONTAINER:   string
		name:        string | *"Remove"
		description: string | *"Remove container \(CONTAINER)"
		command:     string | *"docker rm \(CONTAINER)"
		icon:        string | *"[remove]"
		category:    string | *"admin"
	}

	// =========================================================================
	// Image actions
	// =========================================================================
	image_pull: {
		IMAGE:       string
		name:        string | *"Pull"
		description: string | *"Pull image \(IMAGE)"
		command:     string | *"docker pull \(IMAGE)"
		icon:        string | *"[pull]"
		category:    string | *"admin"
	}

	image_inspect: {
		IMAGE:       string
		name:        string | *"Inspect"
		description: string | *"Inspect image \(IMAGE)"
		command:     string | *"docker image inspect \(IMAGE)"
		icon:        string | *"[inspect]"
		category:    string | *"info"
	}

	image_history: {
		IMAGE:       string
		name:        string | *"History"
		description: string | *"Show image \(IMAGE) history"
		command:     string | *"docker image history \(IMAGE)"
		icon:        string | *"[history]"
		category:    string | *"info"
	}

	image_remove: {
		IMAGE:       string
		name:        string | *"Remove"
		description: string | *"Remove image \(IMAGE)"
		command:     string | *"docker image rm \(IMAGE)"
		icon:        string | *"[remove]"
		category:    string | *"admin"
	}

	image_ls: {
		name:        string | *"List Images"
		description: string | *"List all Docker images"
		command:     string | *"docker images"
		icon:        string | *"[images]"
		category:    string | *"info"
	}

	// =========================================================================
	// Network actions
	// =========================================================================
	network_inspect: {
		NETWORK:     string
		name:        string | *"Inspect Network"
		description: string | *"Inspect network \(NETWORK)"
		command:     string | *"docker network inspect \(NETWORK)"
		icon:        string | *"[inspect]"
		category:    string | *"info"
	}

	network_ls: {
		name:        string | *"List Networks"
		description: string | *"List all Docker networks"
		command:     string | *"docker network ls"
		icon:        string | *"[list]"
		category:    string | *"info"
	}

	network_connect: {
		NETWORK:     string
		CONTAINER:   string
		name:        string | *"Connect"
		description: string | *"Connect \(CONTAINER) to network \(NETWORK)"
		command:     string | *"docker network connect \(NETWORK) \(CONTAINER)"
		icon:        string | *"[connect]"
		category:    string | *"admin"
	}

	network_disconnect: {
		NETWORK:     string
		CONTAINER:   string
		name:        string | *"Disconnect"
		description: string | *"Disconnect \(CONTAINER) from network \(NETWORK)"
		command:     string | *"docker network disconnect \(NETWORK) \(CONTAINER)"
		icon:        string | *"[disconnect]"
		category:    string | *"admin"
	}

	// =========================================================================
	// Volume actions
	// =========================================================================
	volume_inspect: {
		VOLUME:      string
		name:        string | *"Inspect Volume"
		description: string | *"Inspect volume \(VOLUME)"
		command:     string | *"docker volume inspect \(VOLUME)"
		icon:        string | *"[inspect]"
		category:    string | *"info"
	}

	volume_ls: {
		name:        string | *"List Volumes"
		description: string | *"List all Docker volumes"
		command:     string | *"docker volume ls"
		icon:        string | *"[list]"
		category:    string | *"info"
	}

	volume_remove: {
		VOLUME:      string
		name:        string | *"Remove Volume"
		description: string | *"Remove volume \(VOLUME)"
		command:     string | *"docker volume rm \(VOLUME)"
		icon:        string | *"[remove]"
		category:    string | *"admin"
	}

	// =========================================================================
	// Compose actions
	// =========================================================================
	compose_up: {
		PROJECT:     string
		DIR:         string
		name:        string | *"Up"
		description: string | *"Start \(PROJECT) compose stack"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml up -d"
		icon:        string | *"[up]"
		category:    string | *"admin"
	}

	compose_down: {
		PROJECT:     string
		DIR:         string
		name:        string | *"Down"
		description: string | *"Stop \(PROJECT) compose stack"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml down"
		icon:        string | *"[down]"
		category:    string | *"admin"
	}

	compose_ps: {
		PROJECT:     string
		DIR:         string
		name:        string | *"List Services"
		description: string | *"List \(PROJECT) compose services"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml ps"
		icon:        string | *"[list]"
		category:    string | *"monitor"
	}

	compose_logs: {
		PROJECT:     string
		DIR:         string
		LINES:       int | *100
		name:        string | *"Logs"
		description: string | *"View \(PROJECT) compose logs"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml logs --tail \(LINES)"
		icon:        string | *"[logs]"
		category:    string | *"monitor"
	}

	compose_restart: {
		PROJECT:     string
		DIR:         string
		name:        string | *"Restart"
		description: string | *"Restart \(PROJECT) compose stack"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml restart"
		icon:        string | *"[restart]"
		category:    string | *"admin"
	}

	compose_pull: {
		PROJECT:     string
		DIR:         string
		name:        string | *"Pull"
		description: string | *"Pull latest images for \(PROJECT)"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml pull"
		icon:        string | *"[pull]"
		category:    string | *"admin"
	}

	compose_config: {
		PROJECT:     string
		DIR:         string
		name:        string | *"Config"
		description: string | *"Validate \(PROJECT) compose config"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml config"
		icon:        string | *"[config]"
		category:    string | *"info"
	}

	compose_exec: {
		PROJECT:     string
		DIR:         string
		SERVICE:     string
		COMMAND:     string
		name:        string | *"Exec"
		description: string | *"Execute command in \(SERVICE) service"
		command:     string | *"docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml exec \(SERVICE) \(COMMAND)"
		icon:        string | *"[exec]"
		category:    string | *"admin"
	}

	// =========================================================================
	// Host/System actions
	// =========================================================================
	docker_info: {
		name:        string | *"Docker Info"
		description: string | *"Show Docker system info"
		command:     string | *"docker info"
		icon:        string | *"[info]"
		category:    string | *"info"
	}

	docker_ps: {
		name:        string | *"List Containers"
		description: string | *"List all Docker containers"
		command:     string | *"docker ps -a"
		icon:        string | *"[list]"
		category:    string | *"monitor"
	}

	docker_stats: {
		name:        string | *"Container Stats"
		description: string | *"Show live container resource usage"
		command:     string | *"docker stats --no-stream"
		icon:        string | *"[stats]"
		category:    string | *"monitor"
	}

	docker_prune: {
		name:        string | *"Prune"
		description: string | *"Remove unused containers, networks, images"
		command:     string | *"docker system prune -f"
		icon:        string | *"[prune]"
		category:    string | *"admin"
	}

	docker_df: {
		name:        string | *"Disk Usage"
		description: string | *"Show Docker disk usage"
		command:     string | *"docker system df"
		icon:        string | *"[disk]"
		category:    string | *"monitor"
	}

	// =========================================================================
	// Connectivity actions
	// =========================================================================
	ping: {
		IP:          string
		name:        string | *"Ping"
		description: string | *"Test network connectivity to \(IP)"
		command:     string | *"ping -c 3 \(IP)"
		icon:        string | *"[ping]"
		category:    string | *"connect"
	}

	ssh: {
		IP:          string
		USER:        string
		name:        string | *"SSH"
		description: string | *"SSH into host as \(USER)"
		command:     string | *"ssh \(USER)@\(IP)"
		icon:        string | *"[ssh]"
		category:    string | *"connect"
	}

	info: {
		NAME:        string
		name:        string | *"Info from Graph"
		description: string | *"Show this resource's data from semantic graph"
		command:     string | *"cue export -e 'infraGraph[\"\(NAME)\"]'"
		icon:        string | *"[info]"
		category:    string | *"info"
	}

	// =========================================================================
	// Health check actions
	// =========================================================================
	health_check: {
		CONTAINER:   string
		name:        string | *"Health Check"
		description: string | *"Check container \(CONTAINER) health status"
		command:     string | *"docker inspect --format='{{.State.Health.Status}}' \(CONTAINER)"
		icon:        string | *"[health]"
		category:    string | *"monitor"
	}

	port_check: {
		IP:          string
		PORT:        int
		name:        string | *"Port Check"
		description: string | *"Check if port \(PORT) is open on \(IP)"
		command:     string | *"nc -zv \(IP) \(PORT)"
		icon:        string | *"[port]"
		category:    string | *"monitor"
	}

	http_health: {
		URL:         string
		name:        string | *"HTTP Health"
		description: string | *"Check HTTP endpoint health"
		command:     string | *"curl -sf \(URL) > /dev/null && echo 'OK' || echo 'FAILED'"
		icon:        string | *"[http]"
		category:    string | *"monitor"
	}
}

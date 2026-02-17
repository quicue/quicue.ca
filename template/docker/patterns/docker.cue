// Docker - Container and Compose management via docker CLI
//
// Requires: docker CLI, access to Docker daemon
//
// Usage:
//   import "quicue.ca/template/docker/patterns"

package patterns

import "quicue.ca/vocab"

#DockerRegistry: {
	ps: vocab.#ActionDef & {
		name:             "ps"
		description:      "List running containers"
		category:         "info"
		params: {}
		command_template: "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
		idempotent:       true
	}

	ps_all: vocab.#ActionDef & {
		name:             "ps_all"
		description:      "List all containers including stopped"
		category:         "info"
		params: {}
		command_template: "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
		idempotent:       true
	}

	images: vocab.#ActionDef & {
		name:             "images"
		description:      "List local images"
		category:         "info"
		params: {}
		command_template: "docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'"
		idempotent:       true
	}

	logs: vocab.#ActionDef & {
		name:             "logs"
		description:      "View container logs"
		category:         "monitor"
		params: container_name: {from_field: "container_name"}
		command_template: "docker logs {container_name} --tail=100"
		idempotent:       true
	}

	inspect: vocab.#ActionDef & {
		name:             "inspect"
		description:      "Detailed container configuration"
		category:         "info"
		params: container_name: {from_field: "container_name"}
		command_template: "docker inspect {container_name}"
		idempotent:       true
	}

	start: vocab.#ActionDef & {
		name:             "start"
		description:      "Start a stopped container"
		category:         "admin"
		params: container_name: {from_field: "container_name"}
		command_template: "docker start {container_name}"
	}

	stop: vocab.#ActionDef & {
		name:             "stop"
		description:      "Stop a running container"
		category:         "admin"
		params: container_name: {from_field: "container_name"}
		command_template: "docker stop {container_name}"
	}

	restart: vocab.#ActionDef & {
		name:             "restart"
		description:      "Restart a container"
		category:         "admin"
		params: container_name: {from_field: "container_name"}
		command_template: "docker restart {container_name}"
	}

	rm: vocab.#ActionDef & {
		name:             "rm"
		description:      "Remove a stopped container"
		category:         "admin"
		params: container_name: {from_field: "container_name"}
		command_template: "docker rm {container_name}"
		destructive:      true
	}

	exec: vocab.#ActionDef & {
		name:             "exec"
		description:      "Execute command in running container"
		category:         "connect"
		params: {
			container_name: {from_field: "container_name"}
			command:        {}
		}
		command_template: "docker exec -it {container_name} {command}"
	}

	volumes: vocab.#ActionDef & {
		name:             "volumes"
		description:      "List volumes"
		category:         "info"
		params: {}
		command_template: "docker volume ls"
		idempotent:       true
	}

	networks: vocab.#ActionDef & {
		name:             "networks"
		description:      "List networks"
		category:         "info"
		params: {}
		command_template: "docker network ls"
		idempotent:       true
	}

	compose_up: vocab.#ActionDef & {
		name:             "compose_up"
		description:      "Start Compose stack"
		category:         "admin"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml up -d"
	}

	compose_down: vocab.#ActionDef & {
		name:             "compose_down"
		description:      "Stop and remove Compose stack"
		category:         "admin"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml down"
		destructive:      true
	}

	compose_ps: vocab.#ActionDef & {
		name:             "compose_ps"
		description:      "List Compose stack services"
		category:         "info"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml ps"
		idempotent:       true
	}

	stats: vocab.#ActionDef & {
		name:             "stats"
		description:      "Live resource usage for all containers"
		category:         "monitor"
		params: {}
		command_template: "docker stats --no-stream"
		idempotent:       true
	}

	pull: vocab.#ActionDef & {
		name:             "pull"
		description:      "Pull latest image for container"
		category:         "admin"
		params: image_name: {from_field: "image_name"}
		command_template: "docker pull {image_name}"
		idempotent:       true
	}

	compose_pull: vocab.#ActionDef & {
		name:             "compose_pull"
		description:      "Pull latest images for Compose stack"
		category:         "admin"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml pull"
		idempotent:       true
	}

	compose_logs: vocab.#ActionDef & {
		name:             "compose_logs"
		description:      "View Compose stack logs"
		category:         "monitor"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml logs --tail=100"
		idempotent:       true
	}

	compose_restart: vocab.#ActionDef & {
		name:             "compose_restart"
		description:      "Restart all services in Compose stack"
		category:         "admin"
		params: compose_dir: {from_field: "compose_dir"}
		command_template: "docker compose -f {compose_dir}/docker-compose.yml restart"
	}

	...
}

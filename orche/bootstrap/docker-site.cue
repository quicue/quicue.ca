// Docker Site Bootstrap Pattern
// Creates a complete site infrastructure using Docker containers
package bootstrap

import "strings"

// #Container - Docker container resource (simplified inline)
#Container: {
	name:  string
	image: string

	network?: string
	ports?: [...string]
	volumes?: [...string]
	environment?: [string]: string
	command?: string
	restart:  "no" | "always" | "unless-stopped" | "on-failure" | *"unless-stopped"

	// Computed flags
	_envFlags:    string | *""
	_portFlags:   string | *""
	_volumeFlags: string | *""
	_networkFlag: string | *""
	_cmdSuffix:   string | *""

	if environment != _|_ {
		_envFlags: strings.Join([for k, v in environment {"-e \(k)=\(v)"}], " ")
	}
	if ports != _|_ {
		_portFlags: strings.Join([for p in ports {"-p \(p)"}], " ")
	}
	if volumes != _|_ {
		_volumeFlags: strings.Join([for v in volumes {"-v \(v)"}], " ")
	}
	if network != _|_ {
		_networkFlag: "--network \(network)"
	}
	if command != _|_ {
		_cmdSuffix: " \(command)"
	}

	// Compute commands at #Container level (before actions) to avoid shadowing
	_createCmd:  "docker run -d --name \(name) \(_networkFlag) \(_portFlags) \(_volumeFlags) \(_envFlags) --restart=\(restart) \(image)\(_cmdSuffix)"
	_startCmd:   "docker start \(name)"
	_stopCmd:    "docker stop \(name)"
	_restartCmd: "docker restart \(name)"
	_removeCmd:  "docker rm -f \(name)"
	_statusCmd:  "docker inspect -f '{{.State.Status}}' \(name) 2>/dev/null || echo 'not_found'"
	_logsCmd:    "docker logs --tail 100 \(name)"

	actions: {
		create: {
			name:        "Create"
			description: "Create container \(name)"
			command:     _createCmd
			category:    "provision"
		}
		start: {
			name:    "Start"
			command: _startCmd
		}
		stop: {
			name:    "Stop"
			command: _stopCmd
		}
		do_restart: {// Renamed to avoid shadowing
			name:    "Restart"
			command: _restartCmd
		}
		remove: {
			name:    "Remove"
			command: _removeCmd
		}
		status: {
			name:    "Status"
			command: _statusCmd
		}
		logs: {
			name:    "Logs"
			command: _logsCmd
		}
	}
}

// #Network - Docker network resource
#Network: {
	name:    string
	driver:  "bridge" | "host" | "overlay" | *"bridge"
	subnet?: string

	_subnetFlag: string | *""
	if subnet != _|_ {
		_subnetFlag: "--subnet=\(subnet)"
	}

	// Capture name at this level for use in actions
	_netName: name

	actions: {
		create: {
			name:    "Create Network"
			command: "docker network create --driver=\(driver) \(_subnetFlag) \(_netName)"
		}
		remove: {
			name:    "Remove Network"
			command: "docker network rm \(_netName)"
		}
		exists: {
			name:    "Check Network"
			command: "docker network inspect \(_netName) >/dev/null 2>&1 && echo 'exists' || echo 'not_found'"
		}
	}
}

// #DockerSite - Complete site definition for Docker deployment
#DockerSite: {
	name:    string
	tier:    "core" | "edge"
	network: string

	// Capture site name for use in nested scopes
	_siteName: name

	network_config: #Network & {
		name:   network
		driver: "bridge"
		subnet: string | *"192.0.2.0/16"
	}

	services: [string]: #DockerService

	// Computed: all containers
	containers: {
		for sname, svc in services {
			(sname): svc._container
		}
	}

	// Computed: all resources for graph
	resources: {
		"\(_siteName)-network": {
			"@type": {Network: true}
			name: network
			depends_on: {} // Network has no dependencies
			actions: network_config.actions
		}
		for sname, svc in services {
			(sname): {
				"@type":                                                    svc.type
				name:                                                       svc._container.name
				depends_on: svc.depends_on & {"\(_siteName)-network": true} // Merge with network dep
				actions:                                                    svc._container.actions
				if svc.ip != _|_ {
					ip: svc.ip
				}
				ports: svc.ports
			}
		}
	}
}

// #DockerService - Single service in a Docker site
#DockerService: {
	name: string
	type: {...}
	image:                             string
	depends_on: {[string]: true} | *{} // Set membership, defaults to empty
	ip?:                               string
	ports: [...string] | *[]
	volumes: [...string] | *[]
	environment: [string]: string
	command?: string

	_container: #Container & {
		"name":        name
		"image":       image
		"ports":       ports
		"volumes":     volumes
		"environment": environment
		if command != _|_ {
			"command": command
		}
	}
}

// =============================================================================
// Pre-built service templates
// =============================================================================

// Service templates with overridable defaults
#DNSService: #DockerService & {
	type: {DNSServer: true, Container: true}
	image: string | *"coredns/coredns:latest"
	// ports intentionally not defaulted - must be specified
}

#PostgresService: #DockerService & {
	type: {Database: true, PostgreSQL: true, Container: true}
	image: string | *"postgres:16-alpine"
	ports: [...string] | *["5432:5432"]
	environment: {
		POSTGRES_USER:     string | *"postgres"
		POSTGRES_PASSWORD: string
		POSTGRES_DB:       string | *"main"
	}
}

#RedisService: #DockerService & {
	type: {Cache: true, Redis: true, Container: true}
	image: string | *"redis:7-alpine"
	ports: [...string] | *["6379:6379"]
}

#PrometheusService: #DockerService & {
	type: {Monitoring: true, Prometheus: true, Container: true}
	image: string | *"prom/prometheus:latest"
	ports: [...string] | *["9090:9090"]
}

#GrafanaService: #DockerService & {
	type: {Monitoring: true, Grafana: true, Container: true}
	image: string | *"grafana/grafana:latest"
	ports: [...string] | *["3000:3000"]
	environment: {
		GF_SECURITY_ADMIN_PASSWORD: string | *"admin"
	}
}

#NginxService: #DockerService & {
	type: {ReverseProxy: true, Nginx: true, Container: true}
	image: string | *"nginx:alpine"
	// ports intentionally not defaulted - varies by deployment
}

#AppService: #DockerService & {
	type: {Application: true, Container: true}
}

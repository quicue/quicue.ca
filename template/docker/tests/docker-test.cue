// Docker provider tests - validates pattern implementations
package tests

import ( "quicue.ca/template/docker/patterns"

	// =============================================================================
	// TEST: #ContainerActions generates correct commands
	// =============================================================================
)

_testContainerActions: patterns.#ContainerActions & {
	CONTAINER: "nginx"
}

_assertContainer_status:  _testContainerActions.status.command & "docker inspect -f '{{.State.Status}}' nginx"
_assertContainer_logs:    _testContainerActions.logs.command & "docker logs --tail 100 nginx"
_assertContainer_shell:   _testContainerActions.shell.command & "docker exec -it nginx /bin/sh"
_assertContainer_start:   _testContainerActions.start.command & "docker start nginx"
_assertContainer_stop:    _testContainerActions.stop.command & "docker stop nginx"
_assertContainer_restart: _testContainerActions.restart.command & "docker restart nginx"

// =============================================================================
// TEST: #ContainerLifecycle generates correct commands
// =============================================================================

_testContainerLifecycle: patterns.#ContainerLifecycle & {
	CONTAINER: "redis"
}

_assertLifecycle_start:   _testContainerLifecycle.start.command & "docker start redis"
_assertLifecycle_stop:    _testContainerLifecycle.stop.command & "docker stop redis"
_assertLifecycle_restart: _testContainerLifecycle.restart.command & "docker restart redis"
_assertLifecycle_kill:    _testContainerLifecycle.kill.command & "docker kill redis"
_assertLifecycle_pause:   _testContainerLifecycle.pause.command & "docker pause redis"
_assertLifecycle_unpause: _testContainerLifecycle.unpause.command & "docker unpause redis"

// =============================================================================
// TEST: #ComposeActions generates correct commands
// =============================================================================

_testComposeActions: patterns.#ComposeActions & {
	PROJECT: "webapp"
	DIR:     "/opt/stacks/webapp"
}

_assertCompose_up:      _testComposeActions.up.command & "docker compose -p webapp -f /opt/stacks/webapp/docker-compose.yml up -d"
_assertCompose_down:    _testComposeActions.down.command & "docker compose -p webapp -f /opt/stacks/webapp/docker-compose.yml down"
_assertCompose_ps:      _testComposeActions.ps.command & "docker compose -p webapp -f /opt/stacks/webapp/docker-compose.yml ps"
_assertCompose_logs:    _testComposeActions.logs.command & =~"docker compose.*logs"
_assertCompose_restart: _testComposeActions.restart.command & =~"docker compose.*restart"
_assertCompose_pull:    _testComposeActions.pull.command & =~"docker compose.*pull"
_assertCompose_config:  _testComposeActions.config.command & =~"docker compose.*config"

// =============================================================================
// TEST: #NetworkActions generates correct commands
// =============================================================================

_testNetworkActions: patterns.#NetworkActions & {
	NETWORK: "frontend"
}

_assertNetwork_inspect: _testNetworkActions.inspect.command & "docker network inspect frontend"
_assertNetwork_ls:      _testNetworkActions.ls.command & "docker network ls"

// =============================================================================
// TEST: #VolumeActions generates correct commands
// =============================================================================

_testVolumeActions: patterns.#VolumeActions & {
	VOLUME: "postgres_data"
}

_assertVolume_inspect: _testVolumeActions.inspect.command & "docker volume inspect postgres_data"
_assertVolume_ls:      _testVolumeActions.ls.command & "docker volume ls"
_assertVolume_remove:  _testVolumeActions.remove.command & "docker volume rm postgres_data"

// =============================================================================
// TEST: #ImageActions generates correct commands
// =============================================================================

_testImageActions: patterns.#ImageActions & {
	IMAGE: "nginx:alpine"
}

_assertImage_pull:    _testImageActions.pull.command & "docker pull nginx:alpine"
_assertImage_inspect: _testImageActions.inspect.command & "docker image inspect nginx:alpine"
_assertImage_history: _testImageActions.history.command & "docker image history nginx:alpine"
_assertImage_remove:  _testImageActions.remove.command & "docker image rm nginx:alpine"

// =============================================================================
// TEST: #HostActions generates correct commands
// =============================================================================

_testHostActions: patterns.#HostActions & {}

_assertHost_info:   _testHostActions.info.command & "docker info"
_assertHost_ps:     _testHostActions.ps.command & "docker ps -a"
_assertHost_images: _testHostActions.images.command & "docker images"
_assertHost_stats:  _testHostActions.stats.command & "docker stats --no-stream"
_assertHost_prune:  _testHostActions.prune.command & "docker system prune -f"
_assertHost_df:     _testHostActions.df.command & "docker system df"

// =============================================================================
// TEST: #ConnectivityActions generates correct commands
// =============================================================================

_testConnectivity: patterns.#ConnectivityActions & {
	IP:   "198.51.100.5"
	USER: "admin"
}

_assertConn_ping: _testConnectivity.ping.command & "ping -c 3 198.51.100.5"
_assertConn_ssh:  _testConnectivity.ssh.command & "ssh admin@198.51.100.5"

// =============================================================================
// TEST: #ActionTemplates generates correct commands
// =============================================================================

_T: patterns.#ActionTemplates

_testTemplate_status: _T.container_status & {CONTAINER: "myapp"}
_assertTemplate_status: _testTemplate_status.command & "docker inspect -f '{{.State.Status}}' myapp"

_testTemplate_logs: _T.container_logs & {CONTAINER: "myapp", LINES: 50}
_assertTemplate_logs: _testTemplate_logs.command & "docker logs --tail 50 myapp"

_testTemplate_shell: _T.container_shell & {CONTAINER: "myapp", SHELL: "/bin/bash"}
_assertTemplate_shell: _testTemplate_shell.command & "docker exec -it myapp /bin/bash"

_testTemplate_exec: _T.container_exec & {CONTAINER: "myapp", COMMAND: "ls -la"}
_assertTemplate_exec: _testTemplate_exec.command & "docker exec myapp ls -la"

_testTemplate_compose_up: _T.compose_up & {PROJECT: "stack", DIR: "/opt/stack"}
_assertTemplate_compose_up: _testTemplate_compose_up.command & "docker compose -p stack -f /opt/stack/docker-compose.yml up -d"

_testTemplate_health: _T.health_check & {CONTAINER: "myapp"}
_assertTemplate_health: _testTemplate_health.command & "docker inspect --format='{{.State.Health.Status}}' myapp"

_testTemplate_port: _T.port_check & {IP: "192.0.2.1", PORT: 8080}
_assertTemplate_port: _testTemplate_port.command & "nc -zv 192.0.2.1 8080"

_testTemplate_http: _T.http_health & {URL: "http://localhost:8080/health"}
_assertTemplate_http: _testTemplate_http.command & =~"curl.*http://localhost:8080/health"

// =============================================================================
// TEST: All actions have required fields
// =============================================================================

// Verify ContainerActions has all required fields
_verifyContainerFields: {
	_ca: patterns.#ContainerActions & {CONTAINER: "test"}
	_verify_status_name:        _ca.status.name & string
	_verify_status_description: _ca.status.description & string
	_verify_status_command:     _ca.status.command & string
	_verify_status_category:    _ca.status.category & string
	_verify_logs_name:          _ca.logs.name & string
	_verify_shell_name:         _ca.shell.name & string
	_verify_start_name:         _ca.start.name & string
	_verify_stop_name:          _ca.stop.name & string
	_verify_restart_name:       _ca.restart.name & string
}

// Verify ComposeActions has all required fields
_verifyComposeFields: {
	_comp: patterns.#ComposeActions & {PROJECT: "test", DIR: "/tmp"}
	_verify_up_name:        _comp.up.name & string
	_verify_up_description: _comp.up.description & string
	_verify_up_command:     _comp.up.command & string
	_verify_up_category:    _comp.up.category & string
	_verify_down_name:      _comp.down.name & string
	_verify_ps_name:        _comp.ps.name & string
	_verify_logs_name:      _comp.logs.name & string
}

// Proxmox provider tests - validates pattern implementations
package tests

import ( "quicue.ca/proxmox/patterns"

	// =============================================================================
	// TEST: #VMActions generates correct commands
	// =============================================================================
)

_testVMActions: patterns.#VMActions & {
	VMID: 100
	NODE: "pve1"
}

_assertVM_status:  _testVMActions.status.command & "ssh pve1 'qm status 100'"
_assertVM_console: _testVMActions.console.command & "ssh -t pve1 'qm terminal 100'"
_assertVM_config:  _testVMActions.config.command & "ssh pve1 'qm config 100'"

// =============================================================================
// TEST: #VMLifecycle generates correct commands
// =============================================================================

_testVMLifecycle: patterns.#VMLifecycle & {
	VMID: 100
	NODE: "pve1"
}

_assertVM_start:   _testVMLifecycle.start.command & "ssh pve1 'qm start 100'"
_assertVM_stop:    _testVMLifecycle.stop.command & "ssh pve1 'qm shutdown 100'"
_assertVM_restart: _testVMLifecycle.restart.command & "ssh pve1 'qm reboot 100'"

// =============================================================================
// TEST: #VMSnapshots generates correct commands
// =============================================================================

_testVMSnapshots: patterns.#VMSnapshots & {
	VMID: 100
	NODE: "pve1"
}

_assertVMSnap_list:   _testVMSnapshots.list.command & =~"qm listsnapshot 100"
_assertVMSnap_create: _testVMSnapshots.create.command & =~"qm snapshot 100"
_assertVMSnap_revert: _testVMSnapshots.revert.command & =~"qm rollback 100"

// =============================================================================
// TEST: #ContainerActions generates correct commands
// =============================================================================

_testContainerActions: patterns.#ContainerActions & {
	CTID: 101
	NODE: "pve1"
}

_assertCT_status:  _testContainerActions.status.command & "ssh pve1 'pct status 101'"
_assertCT_console: _testContainerActions.console.command & "ssh -t pve1 'pct enter 101'"
_assertCT_logs:    _testContainerActions.logs.command & =~"pct exec 101"

// =============================================================================
// TEST: #HypervisorActions generates correct commands
// =============================================================================

_testHypervisor: patterns.#HypervisorActions & {
	NODE: "pve1"
	USER: "root"
}

_assertNode_listVMs:        _testHypervisor.list_vms.command & "ssh root@pve1 'qm list'"
_assertNode_listContainers: _testHypervisor.list_containers.command & "ssh root@pve1 'pct list'"
_assertNode_clusterStatus:  _testHypervisor.cluster_status.command & "ssh root@pve1 'pvecm status'"

// =============================================================================
// TEST: #ConnectivityActions generates correct commands
// =============================================================================

_testConnectivity: patterns.#ConnectivityActions & {
	IP:   "10.0.1.5"
	USER: "admin"
}

_assertConn_ping: _testConnectivity.ping.command & "ping -c 3 10.0.1.5"
_assertConn_ssh:  _testConnectivity.ssh.command & "ssh admin@10.0.1.5"

// =============================================================================
// TEST: #ContainerLifecycle generates correct commands
// =============================================================================

_testContainerLifecycle: patterns.#ContainerLifecycle & {
	CTID: 101
	NODE: "pve1"
}

_assertCTLife_start:   _testContainerLifecycle.start.command & "ssh pve1 'pct start 101'"
_assertCTLife_stop:    _testContainerLifecycle.stop.command & "ssh pve1 'pct shutdown 101'"
_assertCTLife_restart: _testContainerLifecycle.restart.command & "ssh pve1 'pct reboot 101'"

// =============================================================================
// TEST: #ContainerSnapshots generates correct commands
// =============================================================================

_testContainerSnapshots: patterns.#ContainerSnapshots & {
	CTID: 101
	NODE: "pve1"
}

_assertCTSnap_list:   _testContainerSnapshots.list.command & =~"pct listsnapshot 101"
_assertCTSnap_create: _testContainerSnapshots.create.command & =~"pct snapshot 101"
_assertCTSnap_revert: _testContainerSnapshots.revert.command & =~"pct rollback 101"

// =============================================================================
// TEST: #GuestAgent generates correct commands
// =============================================================================

_testGuestAgent: patterns.#GuestAgent & {
	VMID: 100
	NODE: "pve1"
}

_assertGA_exec: _testGuestAgent.exec.command & =~"qm guest exec 100"
_assertGA_info: _testGuestAgent.info.command & =~"qm agent 100"

// =============================================================================
// TEST: #BackupActions generates correct commands
// =============================================================================

_testBackup: patterns.#BackupActions & {
	VMID:    100
	NODE:    "pve1"
	STORAGE: "local"
}

_assertBackup_backup: _testBackup.backup.command & =~"vzdump 100"
_assertBackup_list:   _testBackup.list_backups.command & =~"pvesm list"

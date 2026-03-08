// VCF Migration — Provider bindings (Layer 2: Providers)
//
// Four providers bound simultaneously to the SAME resources:
//   govc    — VMware vSphere CLI (current platform + VCF target)
//   proxmox — Proxmox VE (KVM, open source, mature)
//   smartos — SmartOS/Triton (illumos, ZFS-native, zones + KVM)
//   kubevirt — KubeVirt (VMs on Kubernetes, containerization path)
//
// The #BindCluster matches providers by @type overlap:
//   govc matches {VirtualMachine: true} and {VMwareCluster: true}
//   proxmox, smartos, kubevirt match {VirtualMachine: true}
//
// All produce concrete commands for the same VMs — proving you
// can operate on any platform without changing your resource
// definitions. The provider is a dial, not a decision.
//
// Run: cue eval ./examples/vcf-migration/ -e binding.summary --out json
// Run: cue eval ./examples/vcf-migration/ -e binding.bound.vm-artifactory.actions --out json

package main

import (
	"quicue.ca/patterns@v0"
	govc_patterns "quicue.ca/template/govc/patterns"
)

// ── Provider Declarations ───────────────────────────────────────

_providers: {
	govc: patterns.#ProviderDecl & {
		types: {VirtualMachine: true, VMwareCluster: true}
		registry: govc_patterns.#GovcRegistry
	}
	// Proxmox as exit-path provider: same VMs, different commands.
	// In production, you'd import quicue.ca/template/proxmox/patterns.
	// Here we inline a minimal registry to keep the example self-contained.
	proxmox: patterns.#ProviderDecl & {
		types: {VirtualMachine: true}
		registry: {
			vm_status: {
				name:             "VM Status"
				description:      "Check VM status via qm"
				category:         "monitor"
				params: vm_id:    {from_field: "vm_id"}
				command_template: "qm status {vm_id}"
				idempotent:       true
			}
			vm_config: {
				name:             "VM Config"
				description:      "Show VM configuration"
				category:         "info"
				params: vm_id:    {from_field: "vm_id"}
				command_template: "qm config {vm_id}"
				idempotent:       true
			}
			vm_snapshot: {
				name:             "Create Snapshot"
				description:      "Create VM snapshot before migration"
				category:         "admin"
				params: vm_id:    {from_field: "vm_id"}
				command_template: "qm snapshot {vm_id} pre-migration-$(date +%Y%m%d)"
			}
			vm_migrate: {
				name:        "Live Migrate"
				description: "Live-migrate VM to target node"
				category:    "admin"
				params: {
					vm_id:  {from_field: "vm_id"}
					target: {default: "pve-target-01"}
				}
				command_template: "qm migrate {vm_id} {target} --online"
			}
		}
	}

	// SmartOS/Triton — illumos-based, ZFS-native, zones + KVM.
	// MNX Solutions (post-Joyent). Type 1 hypervisor, DTrace, MPL 2.0.
	// vmadm for VM management, imgadm for images.
	smartos: patterns.#ProviderDecl & {
		types: {VirtualMachine: true}
		registry: {
			vm_get: {
				name:             "VM Info"
				description:      "Get VM properties via vmadm"
				category:         "info"
				params: vm_uuid:  {from_field: "vm_uuid"}
				command_template: "vmadm get {vm_uuid}"
				idempotent:       true
			}
			vm_list: {
				name:             "List VMs"
				description:      "List all VMs on this compute node"
				category:         "info"
				command_template: "vmadm list -o uuid,type,ram,state,alias"
				idempotent:       true
			}
			vm_start: {
				name:             "Start VM"
				description:      "Boot a KVM VM"
				category:         "admin"
				params: vm_uuid:  {from_field: "vm_uuid"}
				command_template: "vmadm start {vm_uuid}"
			}
			vm_create: {
				name:        "Create VM from manifest"
				description: "Create KVM VM from JSON manifest"
				category:    "admin"
				params: {
					manifest: {from_field: "manifest_path"}
				}
				command_template: "vmadm create -f {manifest}"
			}
			img_import: {
				name:        "Import Image"
				description: "Import VM image from repository"
				category:    "admin"
				params: {
					img_uuid: {from_field: "image_uuid"}
				}
				command_template: "imgadm import {img_uuid}"
			}
		}
	}
	// KubeVirt — VMs on Kubernetes. Containerization path for
	// workloads that can't be refactored to containers yet.
	// kubectl + virtctl CLI for VM lifecycle.
	kubevirt: patterns.#ProviderDecl & {
		types: {VirtualMachine: true}
		registry: {
			vm_get: {
				name:        "VM Info"
				description: "Get VirtualMachine resource"
				category:    "info"
				params: {
					name:      {from_field: "name"}
					namespace: {default: "default"}
				}
				command_template: "kubectl get vm {name} -n {namespace} -o yaml"
				idempotent:       true
			}
			vm_start: {
				name:        "Start VM"
				description: "Start a VirtualMachine via virtctl"
				category:    "admin"
				params: {
					name:      {from_field: "name"}
					namespace: {default: "default"}
				}
				command_template: "virtctl start {name} -n {namespace}"
			}
			vm_stop: {
				name:        "Stop VM"
				description: "Stop a VirtualMachine via virtctl"
				category:    "admin"
				params: {
					name:      {from_field: "name"}
					namespace: {default: "default"}
				}
				command_template: "virtctl stop {name} -n {namespace}"
			}
			vm_migrate: {
				name:        "Live Migrate"
				description: "Trigger live migration via VirtualMachineInstanceMigration"
				category:    "admin"
				params: {
					name:      {from_field: "name"}
					namespace: {default: "default"}
				}
				command_template: "virtctl migrate {name} -n {namespace}"
			}
			vm_console: {
				name:        "Console"
				description: "Attach to VM serial console"
				category:    "connect"
				params: {
					name:      {from_field: "name"}
					namespace: {default: "default"}
				}
				command_template: "virtctl console {name} -n {namespace}"
			}
		}
	}
}

// ── Binding ─────────────────────────────────────────────────────
//
// #BindCluster iterates every resource, checks @type overlap with
// each provider, and resolves command templates. The output is
// resources with actions namespaced by provider:
//
//   vm-artifactory.actions.govc.vm_info       → "govc vm.info /DC1/vm/Artifactory"
//   vm-artifactory.actions.proxmox.vm_status  → "qm status 1001"
//   vm-artifactory.actions.smartos.vm_get     → "vmadm get <uuid>"
//   vm-artifactory.actions.kubevirt.vm_get    → "kubectl get vm artifactory -n default -o yaml"

binding: patterns.#BindCluster & {
	"resources": resources
	providers:   _providers
}

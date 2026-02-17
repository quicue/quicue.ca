// Demo: PowerCLI provider usage
package examples

import "quicue.ca/template/powercli/patterns"

actions: patterns.#PowerCLIRegistry

output: {
	example_commands: {
		connect:       "Connect-VIServer -Server vcsa.lab.local -User admin@vsphere.local -Password changeme"
		vm_info:       "Get-VM -Name DC0_H0_VM0 | Format-List"
		vm_start:      "Start-VM -VM DC0_H0_VM0 -Confirm:$false"
		snapshot_list: "Get-Snapshot -VM DC0_H0_VM0"
		host_info:     "Get-VMHost -Name esxi-01.lab.local | Format-List"
	}
}

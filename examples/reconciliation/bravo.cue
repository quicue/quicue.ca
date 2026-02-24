// Source Bravo — asset management / CMDB (authority rank 2)
//
// Analogous to: TopDesk, ServiceNow, Snipe-IT, or any CMDB
// that tracks physical assets, ownership, and location.
//
// Bravo knows things Alpha doesn't: who manages this VM, where
// the physical hardware lives, what model it is. But Bravo's IP
// data is often stale compared to the hypervisor.

package reconciliation

vms: {
	"web-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.10"
		asset_type: "VirtualMachine", managed_by: "web-team"
		location:   "DC-East", rack:              "R-A04", bravo_status: "Active"
	}
	"web-p02": {
		_in_bravo:  true, bravo_ip:               "198.51.100.11"
		asset_type: "VirtualMachine", managed_by: "web-team"
		location:   "DC-East", rack:              "R-A04", bravo_status: "Active"
	}
	"db-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.20"
		asset_type: "VirtualMachine", managed_by: "dba-team"
		location:   "DC-East", rack:              "R-B02", bravo_status: "Active"
	}
	"db-p02": {
		_in_bravo:  true, bravo_ip:               "198.51.100.21"
		asset_type: "VirtualMachine", managed_by: "dba-team"
		location:   "DC-West", rack:              "R-C01", bravo_status: "Active"
	}
	"lb-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.30"
		asset_type: "VirtualMachine", managed_by: "network-team"
		location:   "DC-East", rack:              "R-A01", bravo_status: "Active"
	}
	"ci-d01": {
		_in_bravo:  true, bravo_ip:               "203.0.113.10"
		asset_type: "VirtualMachine", managed_by: "devops-team"
		location:   "DC-East", rack:              "R-D01", bravo_status: "Active"
	}
	"mon-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.40"
		asset_type: "VirtualMachine", managed_by: "ops-team"
		location:   "DC-West", rack:              "R-C02", bravo_status: "Active"
	}
	"bak-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.50"
		asset_type: "VirtualMachine", managed_by: "ops-team"
		location:   "DC-West", rack:              "R-C03", bravo_status: "Active"
	}
	"auth-p01": {
		_in_bravo:  true, bravo_ip:               "198.51.100.60"
		asset_type: "VirtualMachine", managed_by: "security-team"
		location:   "DC-East", rack:              "R-A02", bravo_status: "Active"
	}
	"vpn-p01": {
		// Bravo has a STALE IP — Alpha's is authoritative
		_in_bravo:  true, bravo_ip:               "198.51.100.71"
		asset_type: "VirtualMachine", managed_by: "network-team"
		location:   "DC-East", rack:              "R-A01", bravo_status: "Active"
	}
	// Bravo-only VMs: tracked in CMDB but not (yet) visible to hypervisor
	"legacy-p10": {
		_in_bravo:     true, bravo_ip:               "192.0.2.10"
		asset_type:    "PhysicalServer", model:      "Dell R640"
		serial_number: "SN-EXAMPLE-001", managed_by: "legacy-team"
		location:      "DC-East", rack:              "R-E01", bravo_status: "Decommissioning"
	}
	"printer-p01": {
		_in_bravo:  true, bravo_ip:          "192.0.2.20"
		asset_type: "NetworkPrinter", model: "HP LaserJet"
		managed_by: "facilities", location:  "DC-East", bravo_status: "Active"
	}
}

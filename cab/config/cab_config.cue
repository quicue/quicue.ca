// CAB Configuration Schema
//
// Defines settings for Change Advisory Board workflows including
// scheduling, approval requirements, and artifact naming.
//
// Usage:
//   import "quicue.ca/cab/config"
//
//   cabConfig: config.#CABConfig & {
//       organization: "ACME Corp"
//       environment: "production"
//   }

package config

import "time"

// #CABConfig - Configuration for CAB workflow
#CABConfig: {
	// Organization name for reports
	organization: string | *"Organization"

	// Environment being managed (production, staging, etc.)
	environment: string | *"production"

	// Schedule configuration
	schedule: #Schedule

	// Approval configuration
	approval: #Approval

	// Artifact configuration
	artifacts: #ArtifactConfig

	// Report configuration
	reports: #ReportConfig

	// Notification configuration (optional)
	notifications?: #NotificationConfig
}

// #Schedule - When CAB activities run
#Schedule: {
	// Nightly validation time (cron format for GitLab)
	nightly_validation: string | *"0 2 * * *" // 2 AM daily

	// Artifact retention in days
	artifact_retention_days: int | *30

	// How often to run full analysis (vs incremental)
	full_analysis_frequency: "daily" | "weekly" | *"daily"

	// Timezone for scheduling
	timezone: string | *"UTC"
}

// #Approval - CAB approval requirements
#Approval: {
	// Minimum approvers required
	min_approvers: int | *2

	// Required approver roles
	required_roles: [...string] | *["cab_member"]

	// Whether changes require explicit approval
	require_explicit_approval: bool | *true

	// Auto-approve low-risk changes
	auto_approve_low_risk: bool | *false

	// Risk thresholds
	risk_thresholds: {
		low:      int | *3  // Changes affecting <= 3 resources
		medium:   int | *10 // Changes affecting <= 10 resources
		high:     int | *25 // Changes affecting <= 25 resources
		critical: int | *25 // Changes affecting > 25 resources
	}
}

// #ArtifactConfig - How artifacts are named and packaged
#ArtifactConfig: {
	// Prefix for artifact names
	prefix: string | *"datacenter"

	// Date format for artifact naming
	date_format: string | *"2006-01-02" // Go time format

	// Include timestamp in artifact name
	include_timestamp: bool | *true

	// Artifact format
	format: "tar.gz" | "zip" | *"tar.gz"

	// What to include in artifacts
	include: {
		configs:     bool | *true // Generated configs (Ansible, Prometheus, etc.)
		reports:     bool | *true // CAB reports
		source:      bool | *false // Original CUE source
		git_history: bool | *false // Git log for the period
	}
}

// #ReportConfig - Report generation settings
#ReportConfig: {
	// Output format
	format: "markdown" | "html" | "json" | *"markdown"

	// Include in reports
	include: {
		change_summary:     bool | *true
		impact_analysis:    bool | *true
		blast_radius:       bool | *true
		deployment_runbook: bool | *true
		rollback_plan:      bool | *true
		redundancy_check:   bool | *true
		environment_diff:   bool | *false // Requires reference environment
	}

	// Detail level
	detail_level: "summary" | "standard" | "verbose" | *"standard"

	// Include resource details in reports
	resource_details: bool | *true

	// Include mermaid diagrams
	include_diagrams: bool | *true
}

// #NotificationConfig - Optional notification settings
#NotificationConfig: {
	// Notification channels
	channels: {
		email?: {
			enabled:    bool | *false
			recipients: [...string]
		}
		slack?: {
			enabled:    bool | *false
			webhook:    string
			channel:    string
		}
		webhook?: {
			enabled: bool | *false
			url:     string
			method:  "POST" | "PUT" | *"POST"
		}
	}

	// When to send notifications
	triggers: {
		on_validation_failure: bool | *true
		on_artifact_ready:     bool | *true
		on_high_risk_change:   bool | *true
		on_deployment_start:   bool | *false
		on_deployment_complete: bool | *false
	}
}

// #CABMetadata - Metadata for tracking deployments
#CABMetadata: {
	// Artifact identifier
	artifact_id: string

	// Git commit SHA
	git_commit: string

	// Git tag (if any)
	git_tag?: string

	// Generation timestamp
	generated_at: time.Time | string

	// Last deployed timestamp (if known)
	last_deployed?: time.Time | string

	// Configuration used
	config: #CABConfig

	// Validation status
	validation: {
		passed:  bool
		errors:  [...string]
		warnings: [...string]
	}

	// Change statistics
	changes: {
		resources_added:    int
		resources_modified: int
		resources_removed:  int
		total_affected:     int
	}
}

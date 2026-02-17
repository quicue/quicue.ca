// Change Report Generator
//
// Generates human-readable reports of changes since last deployment.
// Designed for CAB review sessions.
//
// Usage:
//   import "quicue.ca/cab/reports"
//
//   changeReport: reports.#ChangeReport & {
//       Current: currentGraph
//       Previous: previousGraph  // Optional: from last deployment
//       Config: cabConfig
//   }

package reports

import "strings"

// #ChangeReport - Generate change report for CAB review
#ChangeReport: {
	// Current infrastructure graph (after changes)
	Current: [string]: {
		name: string
		"@type": {[string]: true}
		depends_on?: {[string]: true}
		...
	}

	// Previous infrastructure graph (before changes, optional)
	Previous: [string]: {
		name: string
		"@type": {[string]: true}
		depends_on?: {[string]: true}
		...
	} | *{}

	// Configuration
	Config: {
		organization: string | *"N/A"
		environment:  string | *"N/A"
		...
	} | *{organization: "N/A", environment: "N/A"}

	// Extract current resource names
	_currentNames: {for n, _ in Current {(n): true}}

	// Extract previous resource names
	_previousNames: {for n, _ in Previous {(n): true}}

	// Added resources (in current but not in previous)
	added: [
		for name, _ in _currentNames
		if _previousNames[name] == _|_ {name},
	]

	// Removed resources (in previous but not in current)
	removed: [
		for name, _ in _previousNames
		if _currentNames[name] == _|_ {name},
	]

	// Modified resources (in both, but different)
	_modifiedDetails: [
		for name, curr in Current
		if _previousNames[name] != _|_ {
			let prev = Previous[name]
			let _typeChanged = curr["@type"] != prev["@type"]
			let _hasCurrDeps = curr.depends_on != _|_
			let _hasPrevDeps = prev.depends_on != _|_
			let _depsChanged = _hasCurrDeps != _hasPrevDeps || (_hasCurrDeps && _hasPrevDeps && curr.depends_on != prev.depends_on)
			if _typeChanged || _depsChanged {
				{
					resourceName: name
					typeChanged:  _typeChanged
					depsChanged:  _depsChanged
				}
			}
		},
	]

	modified: [for m in _modifiedDetails {m.resourceName}]

	// Summary statistics
	_currentCount: len([for _, _ in Current {1}])
	summary: {
		total_current:     _currentCount
		total_previous:    len([for _, _ in Previous {1}])
		added_count:       len(added)
		removed_count:     len(removed)
		modified_count:    len(modified)
		total_changes:     len(added) + len(removed) + len(modified)
		change_percentage: _changePercentage
		has_changes:       len(added) + len(removed) + len(modified) > 0
	}

	// Calculate change percentage safely
	_changePercentage: [
		if _currentCount > 0 {(len(added) + len(modified)) * 100 / _currentCount},
		0,
	][0]

	// Risk assessment based on change scope
	risk: {
		level: [
			if summary.total_changes > 25 {"critical"},
			if summary.total_changes > 10 {"high"},
			if summary.total_changes > 3 {"medium"},
			if summary.total_changes > 0 {"low"},
			"none",
		][0]

		factors: [
			if len(removed) > 0 {"resources removed"},
			if summary.total_changes > 10 {"large change set"},
			if summary.change_percentage > 20 {"high change percentage"},
		]
	}

	// Generate markdown report
	_header: """
		# Change Report

		**Organization**: \(Config.organization)
		**Environment**: \(Config.environment)

		---

		## Summary

		| Metric | Value |
		|--------|-------|
		| Total Resources | \(summary.total_current) |
		| Added | \(summary.added_count) |
		| Removed | \(summary.removed_count) |
		| Modified | \(summary.modified_count) |
		| **Total Changes** | \(summary.total_changes) |
		| Change % | \(summary.change_percentage)% |
		| **Risk Level** | \(risk.level) |

		"""

	_addedSection: [
		if len(added) > 0 {"## Added Resources\n\n"},
		"",
	][0]

	_addedList: strings.Join([for name in added {"- `\(name)`"}], "\n")

	_removedSection: [
		if len(removed) > 0 {"\n\n## Removed Resources\n\n"},
		"",
	][0]

	_removedList: strings.Join([for name in removed {"- `\(name)`"}], "\n")

	_modifiedSection: [
		if len(modified) > 0 {"\n\n## Modified Resources\n\n"},
		"",
	][0]

	_modifiedList: strings.Join([for name in modified {"- `\(name)`"}], "\n")

	_riskSection: [
		if len(risk.factors) > 0 {"\n\n## Risk Factors\n\n"},
		"",
	][0]

	_riskList: strings.Join([for f in risk.factors {"- \(f)"}], "\n")

	// Complete markdown report
	markdown: strings.Join([
		_header,
		_addedSection, _addedList,
		_removedSection, _removedList,
		_modifiedSection, _modifiedList,
		_riskSection, _riskList,
	], "")
}

// #DiffReport - Compare two named environments
#DiffReport: {
	SourceName: string | *"source"
	TargetName: string | *"target"
	Source: [string]: {...}
	Target: [string]: {...}

	// Compute diffs directly (not via #ChangeReport to avoid field conflicts)
	_sourceNames: {for n, _ in Source {(n): true}}
	_targetNames: {for n, _ in Target {(n): true}}

	only_in_source: [for name, _ in _sourceNames if _targetNames[name] == _|_ {name}]
	only_in_target: [for name, _ in _targetNames if _sourceNames[name] == _|_ {name}]
	in_both: [for name, _ in _sourceNames if _targetNames[name] != _|_ {name}]

	_sourceCount: len([for _, _ in Source {1}])
	summary: {
		source_count:   _sourceCount
		target_count:   len([for _, _ in Target {1}])
		only_in_source: len(only_in_source)
		only_in_target: len(only_in_target)
		in_both:        len(in_both)
		parity: [
			if _sourceCount > 0 {
				(_sourceCount - len(only_in_source)) * 100 / _sourceCount
			},
			100,
		][0]
	}

	markdown: """
		# Environment Diff: \(SourceName) vs \(TargetName)

		## Summary

		| Metric | Value |
		|--------|-------|
		| \(SourceName) Resources | \(summary.source_count) |
		| \(TargetName) Resources | \(summary.target_count) |
		| Only in \(SourceName) | \(summary.only_in_source) |
		| Only in \(TargetName) | \(summary.only_in_target) |
		| In Both | \(summary.in_both) |
		| Parity | \(summary.parity)% |

		"""
}

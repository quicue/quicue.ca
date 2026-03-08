// PM Queries — Pre-built analysis compositions for project management.
//
// Uses precomputed topology from Python toposort.py for O(1) graph
// analytics. No #InfraGraph dependency — scales to any project size.
//
// Usage:
//   dashboard: pm.#ProjectDashboard & {Project: myProject}
//   report:    pm.#StatusReport & {Project: myProject, AsOf: "2026-03-04"}

package pm

import "list"

// #ProjectDashboard — all-in-one project status view.
#ProjectDashboard: {
	Project: #Project

	// ── Summary metrics ──────────────────────────────────────────
	summary: {
		name:             Project.name
		owner:            Project.owner
		total_work_items: len(Project.work_items)
		root_count:       len(Project._graph.roots)
		_depths: [for _, d in Project.precomputed.depth {d}]
		max_depth: *0 | int
		if len(_depths) > 0 {
			max_depth: list.Max(_depths)
		}
		schedule_phases: max_depth + 1
		_edges: [
			for _, w in Project.work_items
			if w.depends_on != _|_
			for _, _ in w.depends_on {1},
		]
		dependency_links: len(_edges)
		charter_complete: Project._gaps.complete
		next_gate:        Project._gaps.next_gate
	}

	// ── Schedule ──────────────────────────────────────────────────
	schedule: {
		_max: summary.max_depth
		phases: [
			for d in list.Range(0, _max+1, 1) {
				phase: d
				work_items: [
					for name, depth in Project.precomputed.depth
					if depth == d {name},
				]
				gate: "Phase \(d) complete"
			},
		]
	}

	// ── Critical path (from precomputed dependents) ──────────────
	critical_path: {
		_ranked: list.Sort([
			for name, deps in Project.precomputed.dependents {
				let _count = len([for _, _ in deps {1}])
				work_item:           name
				downstream_affected: _count
				if Project.work_items[name].owner != _|_ {
					owner: Project.work_items[name].owner
				}
				if Project.work_items[name].team != _|_ {
					team: Project.work_items[name].team
				}
			},
		], {x: {}, y: {}, less: x.downstream_affected > y.downstream_affected})
		ranked: [for r in _ranked if r.downstream_affected > 0 {r}]
	}

	// ── Risk register (SPOFs from precomputed) ───────────────────
	risks: {
		_by_type: {
			for name, w in Project.work_items {
				for t, _ in w["@type"] {
					(t): (name): true
				}
			}
		}
		// Compute dependent counts per item
		_dep_counts: {
			for name, deps in Project.precomputed.dependents {
				(name): len([for _, _ in deps {1}])
			}
		}
		// SPOF: has dependents, no peer of same type at same depth
		_spof_map: {
			for name, deps in Project.precomputed.dependents
			if _dep_counts[name] > 0 {
				let _depth = Project.precomputed.depth[name]
				let _types = Project.work_items[name]["@type"]
				let _peers = [
					for t, _ in _types
					for peer, _ in _by_type[t]
					if peer != name && Project.precomputed.depth[peer] == _depth {peer},
				]
				if len(_peers) == 0 {
					(name): {
						work_item:           name
						downstream_affected: _dep_counts[name]
						schedule_phase:      _depth
					}
				}
			}
		}
		items: [for _, r in _spof_map {r}]
		spof_count: len(items)
	}

	// ── Charter / gate status ────────────────────────────────────
	charter_status: Project._gaps.gate_status
	gates_satisfied: len([
		for _, gs in Project._gaps.gate_status
		if gs.satisfied {1},
	])
	gates_total: len([for _, _ in Project._gaps.gate_status {1}])

	// ── Status breakdown ─────────────────────────────────────────
	status_breakdown: {
		not_started: len([for _, w in Project.work_items if w.status == "not_started" {1}])
		in_progress: len([for _, w in Project.work_items if w.status == "in_progress" {1}])
		blocked:     len([for _, w in Project.work_items if w.status == "blocked" {1}])
		complete:    len([for _, w in Project.work_items if w.status == "complete" {1}])
		cancelled:   len([for _, w in Project.work_items if w.status == "cancelled" {1}])
	}

	// ── Schedule duration (CPM forward pass) ─────────────────────
	timeline: {
		by_phase: [
			for p in schedule.phases {
				phase:      p.phase
				work_items: p.work_items
				_durations: [
					for wi in p.work_items
					if Project.work_items[wi].duration_weeks != _|_ {
						Project.work_items[wi].duration_weeks
					},
				]
				max_weeks: *0 | number
				if len(_durations) > 0 {
					max_weeks: list.Max(_durations)
				}
			},
		]
		_phase_durations: [for p in by_phase {p.max_weeks}]
		total_weeks: list.Sum(_phase_durations)
	}
}

// #StatusReport — structured status report with RAG per gate.
#StatusReport: {
	Project: #Project
	AsOf:    string

	_dashboard: #ProjectDashboard & {"Project": Project}

	report: {
		project:    Project.name
		owner:      Project.owner
		as_of:      AsOf
		overall_rag: [
			if _dashboard.status_breakdown.blocked > 0 {"RED"},
			if _dashboard.risks.spof_count > 3 {"AMBER"},
			"GREEN",
		][0]
		summary:          _dashboard.summary
		status_breakdown: _dashboard.status_breakdown
		timeline:         _dashboard.timeline
		gate_progress: {
			satisfied: _dashboard.gates_satisfied
			total:     _dashboard.gates_total
			next_gate: _dashboard.summary.next_gate
			details:   _dashboard.charter_status
		}
		top_risks: [
			for r in _dashboard.risks.items
			if r.downstream_affected > 2 {r},
		]
	}
}

// #ResourceAllocation — who's doing what, capacity check.
#ResourceAllocation: {
	Project:      #Project
	MaxPerPerson: *5 | int

	by_owner: {
		for _, w in Project.work_items
		if w.owner != _|_ && w.status != "complete" && w.status != "cancelled" {
			(w.owner): (w.name): true
		}
	}

	by_team: {
		for _, w in Project.work_items
		if w.team != _|_ && w.status != "complete" && w.status != "cancelled" {
			(w.team): (w.name): true
		}
	}

	_owner_counts: {
		for owner, items in by_owner {
			(owner): len([for _, _ in items {1}])
		}
	}

	overallocated: {
		for owner, count in _owner_counts
		if count > MaxPerPerson {
			(owner): {
				items:   count
				over_by: count - MaxPerPerson
			}
		}
	}

	summary: {
		unique_owners:       len([for _, _ in by_owner {1}])
		unique_teams:        len([for _, _ in by_team {1}])
		overallocated_count: len([for _, _ in overallocated {1}])
	}
}

// #PortfolioDashboard — multiple projects in one view.
#PortfolioDashboard: {
	Projects: [string]: #Project

	// Per-project dashboards
	dashboards: {
		for pname, p in Projects {
			(pname): #ProjectDashboard & {Project: p}
		}
	}

	// Aggregate status
	summary: {
		total_projects: len(Projects)
		total_work_items: list.Sum([
			for _, d in dashboards {d.summary.total_work_items},
		])
		projects_on_track: len([
			for _, d in dashboards
			if d.summary.charter_complete {1},
		])
		total_spof: list.Sum([
			for _, d in dashboards {d.risks.spof_count},
		])
	}

	// Cross-project resource conflicts
	_all_owners: {
		for pname, p in Projects {
			for _, w in p.work_items
			if w.owner != _|_ && w.status != "complete" && w.status != "cancelled" {
				(w.owner): (pname + "/" + w.name): true
			}
		}
	}
	resource_conflicts: {
		for owner, _ownerItems in _all_owners {
			let _count = len([for _, _ in _ownerItems {1}])
			if _count > 5 {
				(owner): {
					total_items: _count
					items:       _ownerItems
				}
			}
		}
	}
}

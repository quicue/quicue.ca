// Justfile generation patterns for infrastructure projects.
//
// Generates complete justfiles from infraGraph resources and project actions.
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   justfileContent: (patterns.#JustfileProjection & {
//       InfraGraph:     infraGraph
//       ProjectActions: projectActions
//       ProjectName:    "myproject"
//   }).Output

package patterns

import "strings"

// #JustfileProjection generates a justfile from infraGraph actions and project actions.
#JustfileProjection: {
	InfraGraph: [string]: _
	ProjectActions: [string]: #ProjectAction
	ProjectName:        string
	ProjectDescription: string | *"Infrastructure management"

	#sanitize: {
		in:  string
		out: strings.Replace(strings.Replace(in, "-", "_", -1), ".", "_", -1)
	}

	#indentCommand: {
		in: string
		let lines = strings.Split(in, "\n")
		out: strings.Join([
			for i, line in lines {
				if i == 0 {line}
				if i > 0 {"    " + line}
			},
		], "\n")
	}

	_projectRecipeList: [
		for name, action in ProjectActions {
			let sname = (#sanitize & {in: name}).out
			let cmd = (#indentCommand & {in: action.command}).out
			let argsVal = (action & {args: [...string] | *[]}).args
			let argStr = [
				if len(argsVal) > 0 {" " + strings.Join(argsVal, " ")},
				"",
			][0]
			"""
			# \(action.description)
			\(sname)\(argStr):
			    \(cmd)

			"""
		},
	]

	_resourceRecipeList: [
		for rname, resource in InfraGraph
		if resource.actions != _|_
		for aname, action in resource.actions
		if action.command != _|_ {
			let srname = (#sanitize & {in: rname}).out
			let saname = (#sanitize & {in: aname}).out
			let desc = [
				if action.description != _|_ {action.description},
				if action.name != _|_ {action.name},
				aname,
			][0]
			"""
			# [\(rname)] \(desc)
			\(srname)_\(saname):
			    \(action.command)

			"""
		},
	]

	Output: """
		# \(ProjectName) - \(ProjectDescription)
		# Generated from CUE - DO NOT EDIT MANUALLY

		default:
		    @just --list

		# =============================================================================
		# Project Actions
		# =============================================================================

		\(strings.Join(_projectRecipeList, ""))
		# =============================================================================
		# Resource Actions
		# =============================================================================

		\(strings.Join(_resourceRecipeList, ""))
		"""
}

// #ProjectAction defines a project-level action
#ProjectAction: {
	name:        string
	description: string
	command:     string
	category:    string | *"workflow"
	args?: [...string]
}

// #ProjectActionTemplates provides common project actions
#ProjectActionTemplates: {
	validate: #ProjectAction & {
		name:        string | *"Validate"
		description: string | *"Validate CUE configuration"
		command:     string | *"mise exec -- cue vet ./cluster"
	}

	fmt: #ProjectAction & {
		name:        string | *"Format"
		description: string | *"Format CUE files"
		command:     string | *"mise exec -- cue fmt ./cluster/*.cue"
	}

	query: #ProjectAction & {
		name:        string | *"Query"
		description: string | *"Query CUE config"
		command:     string | *"mise exec -- cue eval ./cluster -e '{{expr}}'"
		category:    string | *"query"
	}

	graph_resources: #ProjectAction & {
		name:        string | *"Graph Resources"
		description: string | *"List all resources in the semantic graph"
		command:     string | *"mise exec -- cue eval ./cluster -e '[for k, _ in infraGraph {k}]'"
		category:    string | *"graph"
	}

	graph_export: #ProjectAction & {
		name:        string | *"Graph Export"
		description: string | *"Export infraGraph as JSON"
		command:     string | *"mise exec -- cue export ./cluster -e 'infraGraph'"
		category:    string | *"graph"
	}

	generate_justfile: #ProjectAction & {
		name:        string | *"Generate Justfile"
		description: string | *"Regenerate justfile from CUE"
		command:     string | *"mise exec -- cue export ./cluster -e 'justfileContent' --out text > justfile"
	}
}

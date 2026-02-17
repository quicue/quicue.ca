// TOON (Token Oriented Object Notation) export pattern.
//
// Reduces payload size by ~55% compared to JSON for tabular infrastructure data.
// Groups resources by field signature, producing compact tables.
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   toon: (patterns.#TOONExport & {
//       Input:  resources
//       Fields: ["name", "types", "ip", "host", "container_id"]
//   }).TOON
//
// Output format:
//   resources[N]{field1,field2,...}:
//     value1,value2,...
//     value1,value2,...

package patterns

import (
	"list"
	"strings"
)

// #TOONExport converts a resource map to TOON format.
#TOONExport: {
	// Input: resources map (unifies with #Resource-like structures)
	Input: [string]: {
		name: string
		"@type": {[string]: true}
		ip?:           string
		host?:         string
		url?:          string
		fqdn?:         string
		region?:       string
		container_id?: int | string
		vm_id?:        int | string
		depends_on?: {[string]: true}
		...
	}

	// Fields: which fields to include in tabular output
	// "types" is a virtual field - flattens @type struct to pipe-separated string
	Fields: [...string] | *["name", "types", "ip", "host"]

	// IncludeDeps: whether to generate separate dependency edges table
	IncludeDeps: bool | *true

	// FieldSeparator: separator between fields (default comma)
	FieldSeparator: string | *","

	// TypeSeparator: separator between types in @type (default pipe)
	TypeSeparator: string | *"|"

	// -------------------------------------------------------------------
	// Internal: Transform @type struct-as-set to string
	// -------------------------------------------------------------------
	_withTypes: {
		for rname, r in Input {
			(rname): r & {
				_types: strings.Join([for t, _ in r."@type" {t}], TypeSeparator)
			}
		}
	}

	// -------------------------------------------------------------------
	// Internal: Compute field signature for each resource
	// Signature = comma-joined list of fields that exist on this resource
	// "types" virtual field is always present (computed from @type)
	// -------------------------------------------------------------------
	_signatures: {
		for rname, r in _withTypes {
			(rname): strings.Join([
				for f in Fields
				// "types" always present, other fields checked for existence
				if f == "types" || r[f] != _|_ {f},
			], ",")
		}
	}

	// -------------------------------------------------------------------
	// Internal: Group resources by signature
	// -------------------------------------------------------------------
	_groups: {
		for rname, r in _withTypes {
			(_signatures[rname]): {
				(rname): r
			}
		}
	}

	// -------------------------------------------------------------------
	// Internal: Generate TOON tables per signature group
	// Each group contains resources with identical field signatures.
	// -------------------------------------------------------------------
	_tables: [
		for sig, members in _groups if sig != "" {
			_fields: strings.Split(sig, ",")
			_count:  len(members)
			_header: "resources[\(_count)]{\(sig)}:"
			_rows: [
				for rname, r in members {
					strings.Join([
						for f in _fields {
							// "types" uses computed _types, others interpolate directly
							if f == "types" {r._types}
							if f != "types" {"\(r[f])"}
						},
					], FieldSeparator)
				},
			]
			// Sort rows for deterministic output
			_sortedRows: list.Sort(_rows, list.Ascending)
			table: _header + "\n" + strings.Join([
				for row in _sortedRows {"  " + row},
			], "\n")
		},
	]

	// -------------------------------------------------------------------
	// Internal: Extract dependency edges for separate table
	// -------------------------------------------------------------------
	_depEdges: [
		for rname, r in Input
		if r.depends_on != _|_
		for dep, _ in r.depends_on {
			{from: rname, to: dep}
		},
	]

	// Sort edges for deterministic output
	_sortedDepEdges: list.Sort(_depEdges, {
		x:    _
		y:    _
		less: x.from < y.from || (x.from == y.from && x.to < y.to)
	})

	_depTable: {
		if IncludeDeps && len(_depEdges) > 0 {
			"dependencies[\(len(_depEdges))]{from,to}:\n" + strings.Join([
				for e in _sortedDepEdges {"  \(e.from),\(e.to)"},
			], "\n")
		}
		if !IncludeDeps || len(_depEdges) == 0 {""}
	}

	// -------------------------------------------------------------------
	// Output: Final TOON string
	// -------------------------------------------------------------------
	// Sort tables for deterministic output
	_sortedTables: list.Sort([for t in _tables {t.table}], list.Ascending)

	TOON: strings.TrimSpace(strings.Join([
		strings.Join(_sortedTables, "\n\n"),
		_depTable,
	], "\n\n"))
}

// #TOONCompare provides token comparison metrics.
#TOONCompare: {
	Input: [string]: _

	// TOON output
	_toon: (#TOONExport & {Input: Input}).TOON

	// Rough token estimates (chars/4 approximation)
	toon_chars:           len(_toon)
	toon_tokens_estimate: toon_chars / 4
	resource_count:       len(Input)
	_rc:                  resource_count
	chars_per_resource: {
		if _rc > 0 {toon_chars / _rc}
		if _rc == 0 {0}
	}
	tokens_per_resource: {
		if _rc > 0 {toon_tokens_estimate / _rc}
		if _rc == 0 {0}
	}
}

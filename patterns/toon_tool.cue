// TOON export tool commands.
//
// Provides `cue cmd` commands for TOON export.
//
// Usage:
//   cue cmd toon ./path/to/config
//   cue cmd toon-export ./path/to/config
//
// The consuming package must define:
//   resources: [string]: vocab.#Resource

package patterns

import (
	"tool/cli"
	"tool/file"
)

// toon: Display TOON output to stdout
command: toon: {
	// Requires resources to be defined in consuming package
	$resources: [string]: _

	_export: #TOONExport & {Input: $resources}

	display: cli.Print & {
		text: _export.TOON
	}
}

// toon-export: Write TOON output to file
command: "toon-export": {
	// Requires resources to be defined in consuming package
	$resources: [string]: _

	_export: #TOONExport & {Input: $resources}

	outfile: file.Create & {
		filename: "infra.toon"
		contents: _export.TOON + "\n"
	}

	display: cli.Print & {
		text: "Wrote TOON export to infra.toon"
	}
}

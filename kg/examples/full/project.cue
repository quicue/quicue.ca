// Full example: quicue-kg's own knowledge graph (self-referential)
package kg

import "quicue.ca/kg/ext@v0"

project: ext.#Context & {
	"@id":       "https://quicue.ca/project/quicue-kg"
	name:        "quicue-kg"
	description: "CUE-native knowledge graph framework"
	module:      "quicue.ca/kg@v0"
	status:      "active"
	license:     "Apache-2.0"
	cue_version: "v0.15.4"
}

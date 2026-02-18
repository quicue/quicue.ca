// Known downstream consumers of quicue.ca patterns, vocab, and kg
package kb

downstream: {
	grdn: {
		"@id":       "https://quicue.ca/project/grdn"
		module:      "grdn.quicue.ca"
		description: "Production infrastructure graph — multi-node cluster with ZFS storage, networking, and container orchestration"
		imports: ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
		pattern_count: 14
		status:        "active"
	}
	cjlq: {
		"@id":       "https://rfam.cc/project/cjlq"
		module:      "rfam.cc/cjlq@v0"
		description: "Energy efficiency scenario modeling (NHCF deep retrofit, Greener Homes processing platform)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 15
		has_kb:        true
		status:        "active"
	}
	"maison-613": {
		"@id":       "https://rfam.cc/project/maison-613"
		module:      "rfam.cc/maison-613@v0"
		description: "Real estate operations — 7 graphs (transaction, referral, compliance, listing, operations, onboarding, client)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 14
		has_kb:        true
		status:        "active"
	}
	apercue: {
		"@id":       "https://apercue.ca/project/apercue"
		module:      "apercue.ca@v0"
		description: "Production datacenter instances — real deployments consuming quicue.ca patterns"
		imports: ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
		status: "active"
	}
	"mud-futurama": {
		"@id":       "https://quique.ca/project/mud-futurama"
		module:      "quicue.ca/mud-futurama@v0"
		description: "Futurama-themed MUD — realm federation, mode composition, corpus derivation pipeline"
		imports: ["quicue.ca/kg@v0"]
		has_kb: true
		status: "active"
	}
	"fing-mod": {
		"@id":       "https://quique.ca/project/fing-mod"
		module:      "quicue.ca/fing-mod@v0"
		description: "Game mode modules (adventure, jrpg, survival) with derived knowledge audit"
		imports: ["quicue.ca/kg@v0"]
		has_kb: true
		status: "active"
	}
}

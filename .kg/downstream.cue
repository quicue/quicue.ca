// Known downstream consumers of quicue.ca patterns and vocab
package kg

downstream: {
	grdn: {
		"@id":       "https://quicue.ca/project/grdn"
		module:      "grdn.quicue.ca"
		path:        "~/grdn"
		description: "Production homelab infrastructure graph (tulip/poppy/clover)"
		imports: ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
		pattern_count: 14
		status:        "active"
	}
	cjlq: {
		"@id":       "https://rfam.cc/project/cjlq"
		module:      "rfam.cc/cjlq@v0"
		path:        "~/cjlq"
		description: "Energy efficiency scenario modeling (NHCF, Greener Homes)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 15
		has_kg:        true
		status:        "active"
	}
	"maison-613": {
		"@id":       "https://rfam.cc/project/maison-613"
		module:      "rfam.cc/maison-613@v0"
		path:        "~/maison-613"
		description: "Real estate operations — 7 graphs (transaction, referral, compliance, listing, operations, onboarding, client)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 14
		has_kg:        true
		status:        "active"
	}
	apercue: {
		"@id":       "https://apercue.ca/project/apercue"
		module:      "apercue.ca@v0"
		path:        "~/apercue"
		description: "Production datacenter instances — real deployments consuming quicue.ca"
		imports: ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
		status: "active"
	}
}

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
		pattern_count: 17
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

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
	"cmhc-retrofit": {
		"@id":       "https://quicue.ca/project/cmhc-retrofit"
		module:      "quicue.ca/cmhc-retrofit@v0"
		description: "Construction program management (NHCF deep retrofit, Greener Homes processing platform)"
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
	// Note: apercue.ca is the upstream foundation (Layer 0), not a downstream consumer.
	// quicue.ca imports apercue.ca/patterns and apercue.ca/charter, not the reverse.
}

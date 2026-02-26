// Deployed sites in the quicue ecosystem
package kb

sites: {
	docs: {
		url:         "https://docs.quicue.ca"
		description: "MkDocs Material documentation site — architecture, patterns, templates, charter"
		deploy:      "github-pages"
		status:      "active"
	}
	demo: {
		url:         "https://demo.quicue.ca"
		description: "Operator dashboard — D3 graph, planner, resource browser, Hydra explorer"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	api: {
		url:         "https://api.quicue.ca"
		description: "Static API showcase — 727 pre-computed JSON endpoints from cue export"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	cat: {
		url:         "https://cat.quicue.ca"
		description: "DCAT 3 data catalogue — dataset registry with SPARQL and LDES endpoints"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	kg: {
		url:         "https://kg.quicue.ca"
		description: "Knowledge graph framework spec and JSON-LD context"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	"cmhc-retrofit": {
		url:         "https://cmhc-retrofit.quicue.ca"
		description: "Construction program management — NHCF deep retrofit and Greener Homes"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	maison613: {
		url:         "https://maison613.quicue.ca"
		description: "Real estate operations — transaction, referral, compliance workflows"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
}

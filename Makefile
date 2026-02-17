.PHONY: test validate examples providers datacenter homelab summary impact clean

# Full test suite — run this before committing
test: validate examples providers
	@echo "=== .kg/ ==="
	@cd .kg && cue vet .
	@echo ""
	@echo "All tests passed."

# Core validation
validate:
	cue vet ./vocab/ ./patterns/

# Validate all examples
examples:
	@for d in examples/*/; do \
		echo "=== $$(basename $$d) ==="; \
		cue vet "./$$d"; \
	done

# Validate all provider templates
providers:
	@for d in template/*/; do \
		echo "=== $$(basename $$d) ==="; \
		cue vet "./$$d/..."; \
	done

# Validate everything (alias for test)
all: test

# Datacenter example
datacenter:
	cue eval ./examples/datacenter/ -e output.summary

# Homelab example
homelab:
	cue eval ./examples/homelab/ -e output.summary

# What breaks if the router dies?
impact:
	cue eval ./examples/datacenter/ -e 'output.impact."router-core"'

# Blast radius
blast:
	cue eval ./examples/datacenter/ -e output.blast_radius

# SPOF detection
spof:
	cue eval ./examples/datacenter/ -e output.single_points_of_failure

# Full JSON export
export:
	cue export ./examples/datacenter/ -e output --out json

# JSON-LD graph
jsonld:
	cue export ./examples/datacenter/ -e jsonld --out json

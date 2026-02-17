.PHONY: test validate examples providers check-downstream datacenter homelab devbox summary impact clean

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

# Devbox example
devbox:
	cue eval ./examples/devbox/ -e output.summary

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

# Validate known downstream consumers still unify with current patterns
check-downstream:
	@echo "=== grdn ==="
	@cd ~/grdn && cue vet .
	@echo "=== grdn .kg/ ==="
	@cd ~/grdn/.kg && cue vet .
	@echo "=== cjlq (nhcf) ==="
	@cd ~/cjlq/nhcf && cue vet .
	@echo "=== cjlq (greener-homes) ==="
	@cd ~/cjlq/greener-homes && cue vet .
	@echo "=== cjlq .kg/ ==="
	@cd ~/cjlq/.kg && cue vet .
	@echo "=== maison-613 (transaction) ==="
	@cd ~/maison-613/transaction && cue vet .
	@echo "=== maison-613 (compliance) ==="
	@cd ~/maison-613/compliance && cue vet .
	@echo "=== maison-613 .kg/ ==="
	@cd ~/maison-613/.kg && cue vet .
	@echo ""
	@echo "All downstream consumers validated."

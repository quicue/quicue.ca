.PHONY: validate test-valid test-invalid examples lint all index

# Validate all schemas
validate:
	cue vet ./core/ ./ext/ ./aggregate/

# Run valid test instances
test-valid:
	cue vet ./tests/valid/

# Run invalid test instances (each should fail)
test-invalid:
	@for f in tests/invalid/*.cue; do \
		echo -n "$$f: "; \
		if cue vet "$$f" 2>/dev/null; then \
			echo "FAIL (should have errored)"; \
		else \
			echo "OK (correctly rejected)"; \
		fi; \
	done

# Validate examples
examples:
	cue vet ./examples/minimal/
	cue vet ./examples/full/

# All checks
all: validate test-valid test-invalid examples

# Export full example index
index:
	cue export ./examples/full/ -e index.summary

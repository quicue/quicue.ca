# quicue.ca — CUE infrastructure vocabulary framework
# Standard recipes: validate, test, check
# Wraps existing Makefile targets for CI compatibility.

# Default: show available recipes
default:
    @just --list

# Validate core vocab + patterns
validate:
    make validate

# Full test suite (validate + examples + providers + charter + kb)
test:
    make test

# Pre-merge gate
check:
    make test

# Knowledge base validation only
kb:
    make kb

# Validate all examples
examples:
    make examples

# Validate all provider templates
providers:
    make providers

# Charter module validation
charter:
    make charter

# Full semantic export (DCAT, N-Triples, SHACL)
semantic-export:
    make semantic-export

# Validate downstream consumers
check-downstream:
    make check-downstream

# Hidden Wrapper for Exports

**Category:** cue

## Problem

CUE exports all public fields. Definitions with large input as public fields leak that data.

## Solution

Use hidden fields (_prefix) for intermediate computation. Expose only the final projection.

## Context

Any CUE definition that produces export-ready JSON from larger input data.

## Example

`_viz holds computation, viz: {data: _viz.data} exposes output only`

## Used In

- quicue.ca


---
*Generated from quicue.ca registries by `#DocsProjection`*
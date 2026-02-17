# PostgreSQL Provider

Database administration via psql and pg_* utilities.

## Requirements

- psql, pg_dump, PGHOST/PGUSER configured

## Usage

```cue
import "quicue.ca/template/postgresql/patterns"

actions: patterns.#PostgreSQLRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```

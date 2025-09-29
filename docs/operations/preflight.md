# Preflight & Readiness

Run the preflight script to verify local tooling and cluster readiness.

```bash
./scripts/preflight.sh
```

Checks
- Helm repos present and up-to-date
- `kubectl` connectivity and default storage class
- Basic environment sanity


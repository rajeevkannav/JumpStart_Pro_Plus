## Summary

Closes #

## Evidence Ledger

| Gate | Result |
| :--- | :--- |
| Minitest | PASS / FAIL / NOT RUN |
| RuboCop | PASS / FAIL / NOT RUN |
| Brakeman | PASS / FAIL / NOT RUN |
| bundler-audit / npm audit | PASS / FAIL / NOT RUN |
| Gitleaks | PASS / FAIL / NOT RUN |
| Playwright axe + 320px reflow | PASS / FAIL / NOT RUN |
| CycloneDX SBOM | PASS / FAIL / NOT RUN |
| Render deploy `/up` | PASS / FAIL / NOT RUN |

## Checklist

- [ ] No changes to `.github/workflows/` or `.mogra.yaml`
- [ ] No secrets committed (`RAILS_MASTER_KEY`, API keys stay in Render / GitHub Secrets)
- [ ] Queries scoped to `Current.account`

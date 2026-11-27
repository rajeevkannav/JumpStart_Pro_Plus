# Contributing

1. **Open an issue** using the Feature or Bug template. One capability per issue, with clear acceptance criteria.
2. `mogra` builds the change on a `mogra/issue-<N>` branch and opens a PR. Human PRs are welcome too and go through the same gates.
3. **Gates** (all must pass): Minitest, RuboCop, Brakeman, bundler-audit / npm audit, Gitleaks, CodeQL, Playwright axe + 320px reflow, CycloneDX SBOM.
4. **Rules**
   - Scope every tenant-owned query to `Current.account`.
   - Don't change `.github/workflows/` or `.mogra.yaml` in feature PRs; the verifier rejects automated PRs that do.
   - No secrets in Git. Use Render env vars or GitHub Secrets.
   - Commit messages follow Conventional Commits (`feat(scope): ...`, `fix(scope): ...`).

Security issues: see [SECURITY.md](SECURITY.md).

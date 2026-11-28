# JumpStart Pro Plus

A clean-room Rails 8 SaaS starter built feature-by-feature from GitHub Issues by **[ProductionLine (`mogra`)](https://github.com/rajeevkannav/ProductionLine)** v0.2.0, deployed to **Railway** (free plan) with a **Neon** free Postgres database.

## Demo account
To create a demo account, set the following environment variables in your Railway project:
- `DEMO_EMAIL`: The email address for the demo user.
- `DEMO_PASSWORD`: A secure password (12+ characters).

These will be used by `db/seeds.rb` during deployment to create or update the demo user.

## How it works

Open an issue with the **Feature** or **Bug** template. `mogra` routes it to a stack, builds the change on `mogra/issue-<N>`, opens a PR, and an independent verifier runs Minitest, RuboCop, Brakeman, bundler-audit, Gitleaks, Playwright a11y/reflow, and SBOM. When all gates pass it merges to `main` and Railway auto-deploys; `mogra` checks `/up` and comments the live URL.

Web ships first. Android and iOS issues start once auth, multi-tenancy, API v1, and the Hotwire Native path-configuration endpoints are live on Railway.

## Setup

### 1. Repository settings
- **Settings → Actions → General:** Workflow permissions **Read and write**; enable **Allow GitHub Actions to create and approve pull requests**.
- **Settings → General → Pull Requests:** enable **Allow auto-merge**.
- **Settings → Code security:** enable **Private vulnerability reporting** and **Dependabot alerts**.

### 2. Secrets (never commit)

```sh
gh secret set MOGRA_BOT_TOKEN -R rajeevkannav/JumpStart_Pro_Plus
gh secret set GEMINI_API_KEY -R rajeevkannav/JumpStart_Pro_Plus
```

| Secret | When | Purpose |
| :--- | :--- | :--- |
| `MOGRA_BOT_TOKEN` | Now | Fine-grained PAT: Contents, Issues, Pull requests R/W; Metadata R |
| `GEMINI_API_KEY` | Now | Default `gemini-cli` harness |
| `RAILS_MASTER_KEY` | Before the first issue | 32 hex characters. Never committed |
| `RAILWAY_APP_URL` | After Railway setup | Public URL |
| `DEMO_EMAIL`, `DEMO_PASSWORD` | Optional | Demo account credentials |

### 3. Neon + Railway (no credit card)
1. **Neon:** create a project (AWS US West), then copy the **direct** connection string.
2. **Railway:** **New Project → Deploy from GitHub repo** → this repo.
3. Service **Variables:** `DATABASE_URL` (Neon string), `RAILS_MASTER_KEY`, `PORT=80`, `DEMO_EMAIL`, `DEMO_PASSWORD`.

## License
[MIT](LICENSE)
# JumpStart Pro Plus

A clean-room Rails 8 SaaS starter built feature-by-feature from GitHub Issues by **[ProductionLine (`mogra`)](https://github.com/rajeevkannav/ProductionLine)** v0.2.0, deployed to **Railway** (free plan) with a **Neon** free Postgres database. Neither has a credit card on file, so the app can never be billed: if the free credit runs out, the service stops until next month.

- **Web:** Ruby on Rails 8 + PostgreSQL + Hotwire (Turbo/Stimulus) + Tailwind CSS v4 + esbuild
- **Background/Cache/Cable:** Solid Queue + Solid Cache + Solid Cable on the single Neon Postgres database (no Redis)
- **Tests:** Minitest + Playwright (`@axe-core/playwright`, 320px reflow)
- **Design:** QuantumBlack design language (OKLCH, dark-first Obsidian + light Mist)
- **Mobile:** Hotwire Native clients in `clients/android` (`.apk`) and `clients/ios` (Simulator build / signed `.ipa` when Apple signing is configured)

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
| `GEMINI_API_KEY` | Now | Default `gemini-cli` harness (or `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` if overridden in `.mogra.yaml`) |
| `RAILS_MASTER_KEY` | Before the first issue | 32 hex characters. `mogra` encrypts `config/credentials.yml.enc` with it when it creates the app; the same value is set on Railway. Never committed |
| `RAILWAY_APP_URL` | After Railway setup | Public URL; `mogra` checks `/up` after each merge |
| `ANDROID_KEYSTORE_*`, `ANDROID_KEY_*` | Mobile | Signed release `.apk` |

### 3. Neon + Railway (no credit card)
1. **Neon:** create a project (AWS US West), then copy the **direct** connection string (connection pooling off; it includes `sslmode=require`).
2. **Railway:** **New Project → Deploy from GitHub repo** → this repo. Railway builds the `Dockerfile` using `railway.toml`; `bin/docker-entrypoint` runs `db:prepare` on boot.
3. Service **Variables:** `DATABASE_URL` (Neon string), `RAILS_MASTER_KEY` (same value as the repo secret), `PORT=80`.
4. **Settings → Networking → Generate Domain** (port `80`), then `gh secret set RAILWAY_APP_URL -R rajeevkannav/JumpStart_Pro_Plus`.

Free-tier notes: the service sleeps when idle and Neon suspends its compute, so the first request after a pause is slow. Railway's trial gives $5 for 30 days, then $1 of usage a month. No background poller runs (`SOLID_QUEUE_IN_PUMA` is unset) so both can sleep. Neon free storage is 0.5 GB. Use an HTTP email API (e.g. Resend) rather than SMTP.

## Configuration
`.mogra.yaml` uses the same defaults as TodoMVC-Plus (`gemini-cli`, human-in-the-loop off). Override the harness, model, per-agent settings, or enable `human_in_the_loop` there.

## License
[MIT](LICENSE)

# JumpStart Pro Plus

A clean-room Rails 8 SaaS starter built feature-by-feature from GitHub Issues by **[ProductionLine (`mogra`)](https://github.com/rajeevkannav/ProductionLine)** v0.2.0, deployed to **Render** (free tier, region `oregon`).

- **Web:** Ruby on Rails 8 + PostgreSQL + Hotwire (Turbo/Stimulus) + Tailwind CSS v4 + esbuild
- **Background/Cache/Cable:** Solid Queue + Solid Cache + Solid Cable on the single free Postgres (no Redis)
- **Tests:** Minitest + Playwright (`@axe-core/playwright`, 320px reflow)
- **Design:** QuantumBlack design language (OKLCH, dark-first Obsidian + light Mist)
- **Mobile:** Hotwire Native clients in `clients/android` (`.apk`) and `clients/ios` (Simulator build / signed `.ipa` when Apple signing is configured)

## How it works

Open an issue with the **Feature** or **Bug** template. `mogra` routes it to a stack, builds the change on `mogra/issue-<N>`, opens a PR, and an independent verifier runs Minitest, RuboCop, Brakeman, bundler-audit, Gitleaks, Playwright a11y/reflow, and SBOM. When all gates pass it merges to `main` and Render auto-deploys; `mogra` checks `/up` and comments the live URL.

Web ships first. Android and iOS issues start once auth, multi-tenancy, API v1, and the Hotwire Native path-configuration endpoints are live on Render.

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
| `RENDER_DEPLOY_HOOK_URL`, `RENDER_APP_URL` | Optional | Post-merge deploy trigger and `/up` check |
| `ANDROID_KEYSTORE_*`, `ANDROID_KEY_*` | Mobile | Signed release `.apk` |

### 3. Render
Render Dashboard → **New → Blueprint** → select this repo (`render.yaml`, added by Issue #1), then set `RAILS_MASTER_KEY` in the service environment.

Render free-tier notes: cold start after ~15 min idle, free Postgres expires after 30 days (seeds are idempotent), SMTP is blocked (use an HTTP email API such as Resend).

## Configuration
`.mogra.yaml` uses the same defaults as TodoMVC-Plus (`gemini-cli`, human-in-the-loop off). Override the harness, model, per-agent settings, or enable `human_in_the_loop` there.

## License
[MIT](LICENSE)

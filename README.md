# toi-frontend-workflows

Reusable GitHub workflows og composite actions for frontend (Next.js / Node) hos team Toi.

Backend-relaterte workflows ligger i [navikt/toi-github-actions-workflows](https://github.com/navikt/toi-github-actions-workflows).

## Struktur

```
.github/
  workflows/
    build-and-deploy-nextjs.yaml   # Hoved-reusable workflow
  actions/
    install-pnpm-dependencies/
    install-npm-dependencies/
    build-next-pnpm/
    build-next-npm/
    build-storybook/
    next-testserver/
    run-playwright-tests/
    run-pa11y/
    deployment-success-summary/
    deployment-failure-summary/
```

## Versjonering

**Én tag på top-nivå styrer alt.** Workflow-filene refererer sine egne interne actions
med samme tag (f.eks. `@v1`). For å holde dette i sync brukes scriptet under, som bumper
alle interne `@vNN`-referanser i ett sveip og lager release.

I appens workflow refererer du kun den øverste taggen:

```yaml
jobs:
  call-build-and-deploy:
    uses: navikt/toi-frontend-workflows/.github/workflows/build-and-deploy-nextjs.yaml@v1
    secrets: inherit
```

Pin alltid på en konkret major-tag (`@v1`, `@v2`), ikke `@main`.

### Publiser ny versjon

Forutsetter at [`gh`](https://cli.github.com/) er installert og at du står på `main` med ren working tree.

```bash
./scripts/publiser-ny-versjon.sh
```

Scriptet:

1. Foreslår neste versjon basert på siste tag (kan overstyres)
2. Bumper alle interne `@vNN`-referanser i `.github/`
3. Viser diff og ber om bekreftelse
4. Committer, pusher og lager GitHub-release

### Når skal versjonen bumpes?

- **Breaking change** → bump major (`v1` → `v2`). Alle apper må oppdatere `@v1` → `@v2`.
- **Non-breaking change** → ikke bump; merge til `main` og flytt eksisterende tag:
  ```bash
  git tag -f v1 main && git push --force origin v1
  ```

## Henvendelser

### For Nav-ansatte

- Eies av [team Toi](https://teamkatalog.nav.no/team/76f378c5-eb35-42db-9f4d-0e8197be0131)
- Slack: [#arbeidsgiver-toi-dev](https://nav-it.slack.com/archives/C02HTU8DBSR)

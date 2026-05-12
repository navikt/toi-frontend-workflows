#!/usr/bin/env bash
#
# Publiser ny versjon av toi-frontend-workflows.
#
#   1. Spør om ny versjon (vNN), foreslår neste basert på siste tag
#   2. Bumper alle interne @vNN-referanser i workflow-filene
#   3. Committer, pusher og lager GitHub-release med ny tag
#
# Bruk: ./scripts/publiser-ny-versjon.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

# --- Sjekk forutsetninger ---
if ! command -v gh >/dev/null 2>&1; then
  echo "❌ gh (GitHub CLI) er ikke installert. Se https://cli.github.com/" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Working tree er ikke ren. Commit eller stash endringene dine først." >&2
  git status --short
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "❌ Du må stå på main-branchen (er på '$CURRENT_BRANCH')." >&2
  exit 1
fi

git fetch --tags --quiet

# --- Foreslå neste versjon ---
LATEST=$(git tag -l 'v*' | sort -V | tail -n1 || true)
if [[ -n "$LATEST" ]]; then
  CURRENT_NUM=${LATEST#v}
  SUGGESTED="v$((CURRENT_NUM + 1))"
  echo "Nåværende siste versjon: $LATEST"
else
  SUGGESTED="v1"
  echo "Ingen tidligere versjon funnet."
fi

read -r -p "Ny versjon [$SUGGESTED]: " NEW
NEW=${NEW:-$SUGGESTED}

if [[ ! "$NEW" =~ ^v[0-9]+$ ]]; then
  echo "❌ Versjonen må være på formatet vNN (f.eks. v2)" >&2
  exit 1
fi

if git rev-parse "$NEW" >/dev/null 2>&1; then
  echo "❌ Tag '$NEW' finnes allerede." >&2
  exit 1
fi

# --- Bump interne @vNN-referanser ---
echo ""
echo "→ Bumper interne @vNN-referanser til $NEW"

FILES=$(grep -rlE 'navikt/toi-frontend-workflows/[^@]+@v[0-9]+' .github || true)

if [[ -z "$FILES" ]]; then
  echo "  (Ingen interne @vNN-referanser funnet — hopper over fil-bump)"
else
  echo "$FILES" | sed 's/^/  - /'
  SED_INPLACE=(-i)
  if [[ "$(uname)" == "Darwin" ]]; then
    SED_INPLACE=(-i '')
  fi
  echo "$FILES" | xargs sed "${SED_INPLACE[@]}" -E \
    "s|(navikt/toi-frontend-workflows/[^@[:space:]]+)@v[0-9]+|\1@${NEW}|g"
fi

# --- Bekreft før push ---
echo ""
echo "→ Endringer som vil bli committet:"
git --no-pager diff --stat

read -r -p "Fortsett med commit, push og release ${NEW}? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Avbrutt. Kjør 'git checkout .' for å forkaste endringene."
  exit 1
fi

# --- Commit, push, release ---
if [[ -n "$(git status --porcelain)" ]]; then
  git commit -am "bump til ${NEW}"
  git push
else
  echo "(Ingen filer å committe — taggen settes på eksisterende HEAD)"
fi

echo ""
echo "→ Oppretter release ${NEW}"
gh release create "$NEW" --target main --generate-notes --title "$NEW"

echo ""
echo "✅ Ferdig. ${NEW} er publisert."

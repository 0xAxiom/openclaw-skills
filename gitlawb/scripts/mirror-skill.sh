#!/usr/bin/env bash
# Mirror a local openclaw-skill folder up to gitlawb as a new repo.
#
# Usage:
#   bash mirror-skill.sh <path-to-skill-folder> "<description>"
#
# Works on any folder — including folders that already live inside another
# git repo (like openclaw-skills/bankr/). The script never `git init`s in the
# source folder; instead it copies the contents into a scratch directory,
# initialises a private git repo there, signs the commit with your DID, and
# pushes to gitlawb://<your-did>/<repo-name>.
#
# Idempotent: only changed files are committed. Safe to re-run.
set -euo pipefail

# Pin the network node — both gl and git-remote-gitlawb read this env var.
# Without it the remote helper falls back to http://127.0.0.1:7545 and fails.
export GITLAWB_NODE="${GITLAWB_NODE:-https://node.gitlawb.com}"

SKILL_DIR="${1:-}"
DESCRIPTION="${2:-OpenClaw skill mirrored to gitlawb}"

if [ -z "$SKILL_DIR" ] || [ ! -d "$SKILL_DIR" ]; then
  echo "usage: $0 <path-to-skill-folder> [description]" >&2
  exit 1
fi

SKILL_DIR="$(cd "$SKILL_DIR" && pwd)"
REPO_NAME="$(basename "$SKILL_DIR")"

err() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()  { printf '\033[32m✓ %s\033[0m\n' "$*"; }

command -v gl >/dev/null 2>&1 || err "gl not on PATH (run quickstart-axiom.sh first)"
MY_DID="$(gl identity show 2>/dev/null || err 'no identity — run quickstart-axiom.sh first')"

# 1. Create the gitlawb repo (skip silently if it already exists)
if gl repo create "$REPO_NAME" --description "$DESCRIPTION" >/dev/null 2>&1; then
  ok "created gitlawb repo: $REPO_NAME"
else
  ok "repo $REPO_NAME already exists on gitlawb — pushing update"
fi

# 2. Scratch dir for the mirror — outside the source tree so we never create
#    a nested .git inside an existing parent repo.
SCRATCH="$(mktemp -d -t "gitlawb-mirror-${REPO_NAME}-XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# Copy contents (excluding any pre-existing .git)
( cd "$SKILL_DIR" && tar --exclude='.git' -cf - . ) | ( cd "$SCRATCH" && tar -xf - )

cd "$SCRATCH"
git init -q -b main
git config user.name  "$MY_DID"
git config user.email "$MY_DID@gitlawb"

# Append attribution to the README (or create one) on first mirror
if [ -f README.md ]; then
  if ! grep -q "gitlawb" README.md; then
    printf '\n\n---\n\n> Mirrored to gitlawb — pushed via the OpenClaw `gitlawb` skill. See <https://gitlawb.com>.\n' >> README.md
  fi
else
  printf '# %s\n\n%s\n\n---\n\n> Mirrored to gitlawb — pushed via the OpenClaw `gitlawb` skill. See <https://gitlawb.com>.\n' \
    "$REPO_NAME" "$DESCRIPTION" > README.md
fi

git add -A
git commit -q -m "mirror: openclaw-skills/${REPO_NAME} → gitlawb" --allow-empty

# 3. Push to gitlawb. We're a mirror tool — the local source folder is
#    authoritative, so it's safe to force-replace the remote's main ref.
git remote add gitlawb "gitlawb://${MY_DID}/${REPO_NAME}"
git push -q gitlawb HEAD:main --force
ok "pushed $REPO_NAME → gitlawb"

DID_KEY="${MY_DID#did:key:}"
DID_KEY="${DID_KEY#did:gitlawb:}"
echo
echo "  Profile: https://gitlawb.com/${DID_KEY:0:8}"
echo "  Repo:    gl repo info $REPO_NAME"

#!/usr/bin/env bash
# Non-interactive gitlawb onboarding for an OpenClaw agent.
#
# Idempotent: re-running is safe — it will not overwrite an existing identity
# or re-register if already registered. Writes the resulting DID to
# ~/.clawdbot/skills/gitlawb/did.txt so other skills can pick it up.
set -euo pipefail

NODE="${GITLAWB_NODE:-https://node.gitlawb.com}"
STATE_DIR="${HOME}/.clawdbot/skills/gitlawb"
DID_FILE="${STATE_DIR}/did.txt"

err() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()  { printf '\033[32m✓ %s\033[0m\n' "$*"; }
say() { printf '  %s\n' "$*"; }

command -v gl >/dev/null 2>&1 || err "gl CLI not on PATH — install via 'npm install -g @gitlawb/gl' or 'curl -sSf https://gitlawb.com/install.sh | sh'"
command -v git-remote-gitlawb >/dev/null 2>&1 || err "git-remote-gitlawb not on PATH (should be installed alongside gl)"

mkdir -p "$STATE_DIR"
export GITLAWB_NODE="$NODE"

# 1. Identity
if gl identity show >/dev/null 2>&1; then
  ok "identity exists"
else
  gl identity new
  ok "identity created"
fi
MY_DID="$(gl identity show)"
say "DID: $MY_DID"

# 2. Register (idempotent)
gl register >/dev/null
ok "registered with $NODE"

# 3. Persist DID for other skills
printf '%s\n' "$MY_DID" > "$DID_FILE"
ok "DID saved to $DID_FILE"

# 4. Profile URL
DID_KEY="${MY_DID#did:key:}"
DID_KEY="${DID_KEY#did:gitlawb:}"
DID_SHORT="${DID_KEY:0:8}"
say "Profile: https://gitlawb.com/${DID_SHORT}"
say "Repos:   https://gitlawb.com/node/repos"

# 5. Sanity: doctor
echo
gl doctor || err "gl doctor reported a problem — fix the failing checks before pushing"
ok "ready to push"

#!/usr/bin/env bash
# Wrap `gl doctor` with OpenClaw-side sanity checks.
#
# Verifies:
#   - gl + git-remote-gitlawb on PATH
#   - identity exists, matches the cached DID in ~/.clawdbot/skills/gitlawb/did.txt
#   - node reachable
#   - trust score readable (signals registration worked)
set -euo pipefail

NODE="${GITLAWB_NODE:-https://node.gitlawb.com}"
STATE_DIR="${HOME}/.clawdbot/skills/gitlawb"
DID_FILE="${STATE_DIR}/did.txt"

red() { printf '\033[31m✗ %s\033[0m\n' "$*"; }
grn() { printf '\033[32m✓ %s\033[0m\n' "$*"; }

FAIL=0

if command -v gl >/dev/null 2>&1; then grn "gl on PATH"; else red "gl missing"; FAIL=1; fi
if command -v git-remote-gitlawb >/dev/null 2>&1; then grn "git-remote-gitlawb on PATH"; else red "git-remote-gitlawb missing"; FAIL=1; fi

if [ $FAIL -eq 1 ]; then
  echo
  echo "Install: npm install -g @gitlawb/gl   (or)   curl -sSf https://gitlawb.com/install.sh | sh"
  exit 1
fi

MY_DID="$(gl identity show 2>/dev/null || true)"
if [ -z "$MY_DID" ]; then
  red "no identity — run quickstart-axiom.sh"
  exit 1
fi
grn "identity: $MY_DID"

if [ -f "$DID_FILE" ]; then
  CACHED="$(cat "$DID_FILE")"
  if [ "$CACHED" = "$MY_DID" ]; then
    grn "cached DID matches on-disk identity"
  else
    red "cached DID ($CACHED) ≠ on-disk DID ($MY_DID)"
    FAIL=1
  fi
else
  grn "(no cached DID — fine if this is first run)"
fi

# Upstream doctor
echo
gl doctor || FAIL=1

# Trust score
TRUST_JSON="$(GITLAWB_NODE="$NODE" gl node trust "$MY_DID" 2>/dev/null || true)"
if [ -n "$TRUST_JSON" ]; then
  echo
  printf 'Trust: %s\n' "$TRUST_JSON"
fi

[ $FAIL -eq 0 ] || exit 1

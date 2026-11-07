#!/usr/bin/env bash
#
# setup_repo.sh — enforce GitHub protection rules on this repository.
#
# What it applies (idempotent — safe to re-run):
#
#   1. Repository settings:
#        - delete_branch_on_merge: the feature branch is deleted automatically
#          after a PR is merged.
#        - dependabot_security_updates: Dependabot raises PRs to fix
#          vulnerable dependencies (Security tab).
#        - secret_scanning_validity_checks: leaked tokens are checked against
#          their provider and marked active/inactive.
#          NOTE: GitHub silently ignores this field over the API for some
#          account tiers (verified 2026-11-07: HTTP 200, state unchanged). If
#          the final verification below still reports "disabled", enable it in
#          the UI: Settings -> Code security -> Secret scanning -> Validity checks.
#
#   2. A branch ruleset ("main-protection") targeting the default branch:
#        - every change must land through a Pull Request (0 approvals
#          required, so a maintainer can merge their own PR);
#        - branch deletion is blocked;
#        - force pushes are blocked;
#        - nobody can bypass the rules — admins included (bypass_actors: []).
#
# Usage:
#   ./setup_repo.sh             # apply to the repo this terminal is in (inferred by gh)
#   ./setup_repo.sh OWNER/REPO  # apply to an explicit repository
#
# Requirements:
#   - gh CLI (https://cli.github.com), logged in, with admin access to the repo.
#
# API notes discovered while validating against this repo (2026-11-07):
#   - Updating a repository ruleset is PUT, not PATCH: PATCH answers 404.
#   - The "pull_request" rule fails schema validation (422) unless ALL of its
#     required_* parameters are present, even when their value is "off".
set -euo pipefail

RULESET_NAME="main-protection"

step() { printf '\n==> %s\n' "$1"; }
ok()   { printf '    ok: %s\n' "$1"; }
die()  { printf '        error: %s\n' "$1" >&2; exit 1; }

command -v gh >/dev/null 2>&1 \
  || die "gh CLI not found. Install it from https://cli.github.com and run 'gh auth login'."

# Repository to configure: explicit argument, or inferred by gh from the git remote.
REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
[ -n "$REPO" ] || die "Could not infer the repository. Run this from the repo or pass OWNER/REPO."

# ---------------------------------------------------------------------------
# 0) Sanity check — the caller must be an admin, otherwise the calls below
#    would fail halfway through.
# ---------------------------------------------------------------------------
step "Checking admin access on ${REPO}"
admin=$(gh api "repos/${REPO}" --jq '.permissions.admin // false')
[ "$admin" = "true" ] || die "Admin access is required to change protection rules on ${REPO}."
ok "authenticated user has admin rights"

# ---------------------------------------------------------------------------
# 1) Repository settings: PATCH /repos/{owner}/{repo} (idempotent).
#    Sent as a JSON body: nested security_and_analysis paths passed to gh as
#    --field arguments only get partially applied.
# ---------------------------------------------------------------------------
step "Updating repository settings"
gh api --method PATCH "repos/${REPO}" \
  --jq '[ "  delete_branch_on_merge: \(.delete_branch_on_merge)",
          "  dependabot_security_updates: \(.security_and_analysis.dependabot_security_updates.status)",
          "  secret_scanning_validity_checks: \(.security_and_analysis.secret_scanning_validity_checks.status)" ] | join("\n")' \
  --input - <<'JSON'
{
  "delete_branch_on_merge": true,
  "security_and_analysis": {
    "dependabot_security_updates": { "status": "enabled" },
    "secret_scanning_validity_checks": { "status": "enabled" }
  }
}
JSON

# ---------------------------------------------------------------------------
# 2) Branch ruleset: create it if missing, PUT-update it if already present.
#    "~DEFAULT_BRANCH" targets the default branch whatever its name, so the
#    rules survive a default-branch rename.
# ---------------------------------------------------------------------------
step "Creating or updating the \"${RULESET_NAME}\" ruleset"

RULESET_JSON=$(cat <<'JSON'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    },
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ]
}
JSON
)

ruleset_id=$(gh api "repos/${REPO}/rulesets" \
  --jq ".[] | select(.name == \"${RULESET_NAME}\") | .id" | head -n1)

if [ -n "$ruleset_id" ]; then
  # PUT and not PATCH: PATCH /repos/{owner}/{repo}/rulesets/{id} answers 404.
  gh api --method PUT "repos/${REPO}/rulesets/${ruleset_id}" \
    --jq '"  ruleset \(.id) (\(.name)) updated: enforcement \(.enforcement)"' \
    --input - <<<"$RULESET_JSON"
else
  gh api --method POST "repos/${REPO}/rulesets" \
    --jq '"  ruleset \(.id) (\(.name)) created: enforcement \(.enforcement)"' \
    --input - <<<"$RULESET_JSON"
fi

# ---------------------------------------------------------------------------
# 3) Verification — read back what GitHub actually enforces (the PATCH in
#    step 1 may silently drop unsupported fields, e.g. validity checks).
# ---------------------------------------------------------------------------
step "Verifying enforced rules"
default_branch=$(gh api "repos/${REPO}" --jq .default_branch)

echo "    rules active on ${default_branch}:"
gh api "repos/${REPO}/rules/branches/${default_branch}" \
  --jq '.[] | "      - \(.type) (ruleset \(.ruleset_id))"'

echo "    repo settings observed:"
gh api "repos/${REPO}" \
  --jq '[ "      delete_branch_on_merge: \(.delete_branch_on_merge)",
          "      dependabot_security_updates: \(.security_and_analysis.dependabot_security_updates.status)",
          "      secret_scanning_validity_checks: \(.security_and_analysis.secret_scanning_validity_checks.status)" ] | join("\n")'

step "Done — ${REPO} is protected: changes only land through Pull Requests."

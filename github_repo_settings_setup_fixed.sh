#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# GitHub repository bootstrap for Terraform CI/CD
#
# What it does
# - Sets the default branch
# - Enables GitHub Actions and allows all actions
# - Sets default GITHUB_TOKEN permissions to read
# - Creates/updates dev, stage, prod environments
# - Optionally assigns required reviewers to stage/prod environments
# - Applies branch protection to the main branch
#
# Prereqs
# - gh CLI installed and authenticated
# - jq installed
# - Admin access to the repository
#
# Example:
#   REPO_OWNER=sqkcloud \
#   REPO_NAME=iac-devops-aws \
#   MAIN_BRANCH=main \
#   STAGE_REVIEWERS='sqkcloud,sqklab' \
#   PROD_REVIEWERS='sqkcloud' \
#   bash github_repo_settings_setup.sh
# -----------------------------------------------------------------------------

REPO_OWNER="${REPO_OWNER:?REPO_OWNER is required}"
REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"

# Comma-separated GitHub usernames. Leave empty to create environments with no reviewers.
DEV_REVIEWERS="${DEV_REVIEWERS:-}"
STAGE_REVIEWERS="${STAGE_REVIEWERS:-}"
PROD_REVIEWERS="${PROD_REVIEWERS:-}"

# Environment names
DEV_ENV_NAME="${DEV_ENV_NAME:-dev}"
STAGE_ENV_NAME="${STAGE_ENV_NAME:-stage}"
PROD_ENV_NAME="${PROD_ENV_NAME:-prod}"

# Required status checks on main
REQUIRED_CHECKS="${REQUIRED_CHECKS:-plan-dev,plan-stage,plan-prod}"

# If "true", the person who triggered the deployment cannot approve it.
STAGE_PREVENT_SELF_REVIEW="${STAGE_PREVENT_SELF_REVIEW:-true}"
PROD_PREVENT_SELF_REVIEW="${PROD_PREVENT_SELF_REVIEW:-true}"

API_VERSION="${API_VERSION:-2026-03-10}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is required but not installed." >&2
    exit 1
  }
}

gh_api() {
  gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    "$@"
}

json_api() {
  local method="$1"
  local endpoint="$2"
  local payload="$3"

  gh api \
    --method "$method" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    "$endpoint" \
    --input - <<<"$payload"
}

to_bool_json() {
  case "${1,,}" in
    true|1|yes)  printf 'true' ;;
    false|0|no|"") printf 'false' ;;
    *)
      echo "Invalid boolean value: $1" >&2
      exit 1
      ;;
  esac
}

require_auth() {
  gh auth status >/dev/null 2>&1 || {
    echo "Error: gh is not authenticated. Run: gh auth login" >&2
    exit 1
  }
}

repo_exists() {
  gh repo view "${REPO_OWNER}/${REPO_NAME}" >/dev/null 2>&1
}

user_login_to_reviewer_json() {
  local login="$1"
  local id

  id="$(gh_api "/users/${login}" --jq '.id')" || {
    echo "Error: could not resolve GitHub user '${login}' to an id." >&2
    exit 1
  }

  jq -cn --argjson id "$id" '{type:"User", id:$id}'
}

csv_to_reviewers_json_or_null() {
  local csv="$1"

  if [[ -z "${csv// }" ]]; then
    printf 'null'
    return
  fi

  local IFS=','
  read -r -a items <<<"$csv"

  local reviewer_jsons=()
  local item
  for item in "${items[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    [[ -z "$item" ]] && continue
    reviewer_jsons+=("$(user_login_to_reviewer_json "$item")")
  done

  if [[ ${#reviewer_jsons[@]} -eq 0 ]]; then
    printf 'null'
    return
  fi

  printf '%s\n' "${reviewer_jsons[@]}" | jq -cs '.'
}

create_or_update_environment() {
  local env_name="$1"
  local reviewers_csv="$2"
  local prevent_self_review="${3:-false}"

  local reviewers_json
  reviewers_json="$(csv_to_reviewers_json_or_null "$reviewers_csv")"

  local prevent_self_review_json
  prevent_self_review_json="$(to_bool_json "$prevent_self_review")"

  # deployment_branch_policy = null means all branches can deploy.
  local payload
  payload="$(jq -cn \
    --argjson reviewers "$reviewers_json" \
    --argjson prevent_self_review "$prevent_self_review_json" \
    '{
      wait_timer: 0,
      prevent_self_review: $prevent_self_review,
      reviewers: $reviewers,
      deployment_branch_policy: null
    }'
  )"

  log "Creating/updating environment: ${env_name}"
  json_api PUT "/repos/${REPO_OWNER}/${REPO_NAME}/environments/${env_name}" "$payload" >/dev/null
}

set_default_branch() {
  local payload
  payload="$(jq -cn --arg branch "$MAIN_BRANCH" '{default_branch:$branch}')"

  log "Ensuring default branch is ${MAIN_BRANCH}"
  json_api PATCH "/repos/${REPO_OWNER}/${REPO_NAME}" "$payload" >/dev/null
}

configure_actions_permissions() {
  local payload1 payload2

  # enabled must be a JSON boolean, not the string "true".
  payload1="$(jq -cn '{enabled:true, allowed_actions:"all"}')"

  log "Configuring Actions permissions"
  json_api PUT "/repos/${REPO_OWNER}/${REPO_NAME}/actions/permissions" "$payload1" >/dev/null

  payload2="$(jq -cn '{default_workflow_permissions:"read", can_approve_pull_request_reviews:false}')"

  log "Configuring default workflow permissions"
  json_api PUT "/repos/${REPO_OWNER}/${REPO_NAME}/actions/permissions/workflow" "$payload2" >/dev/null
}

protect_main_branch() {
  local checks_json
  checks_json="$(printf '%s' "$REQUIRED_CHECKS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')"

  local payload
  payload="$(jq -cn \
    --argjson checks "$checks_json" \
    '{
      required_status_checks: {
        strict: true,
        contexts: $checks
      },
      enforce_admins: false,
      required_pull_request_reviews: {
        dismiss_stale_reviews: true,
        require_code_owner_reviews: false,
        required_approving_review_count: 1
      },
      restrictions: null,
      required_linear_history: false,
      allow_force_pushes: false,
      allow_deletions: false,
      block_creations: false,
      required_conversation_resolution: true,
      lock_branch: false,
      allow_fork_syncing: true
    }'
  )"

  log "Applying branch protection to ${MAIN_BRANCH}"
  json_api PUT "/repos/${REPO_OWNER}/${REPO_NAME}/branches/${MAIN_BRANCH}/protection" "$payload" >/dev/null
}

main() {
  need_cmd gh
  need_cmd jq
  require_auth

  repo_exists || {
    echo "Error: repository '${REPO_OWNER}/${REPO_NAME}' not found or you do not have access." >&2
    exit 1
  }

  set_default_branch
  configure_actions_permissions

  # Create environments
  create_or_update_environment "$DEV_ENV_NAME"   "$DEV_REVIEWERS"   "false"
  create_or_update_environment "$STAGE_ENV_NAME" "$STAGE_REVIEWERS" "$STAGE_PREVENT_SELF_REVIEW"
  create_or_update_environment "$PROD_ENV_NAME"  "$PROD_REVIEWERS"  "$PROD_PREVENT_SELF_REVIEW"

  protect_main_branch

  log "Done."
  log "Repository: ${REPO_OWNER}/${REPO_NAME}"
  log "Default branch: ${MAIN_BRANCH}"
  log "Environments: ${DEV_ENV_NAME}, ${STAGE_ENV_NAME}, ${PROD_ENV_NAME}"
}

main "$@"

#!/bin/bash
# Cursor hook (beforeShellExecution): block Databricks deploy commands while the
# repo has uncommitted changes, so every deployed version can be found again in git.
#
# Input (stdin, from Cursor): JSON with "command" and "cwd".
# Output (stdout): {"permission": "allow" | "deny", ...}
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "deploy-commit-guard: jq is required but not installed" >&2
  exit 1
fi

input=$(cat)
cmd=$(jq -r '.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // "."' <<<"$input")

deny() {
  # shellcheck disable=SC2016  # $user and $agent are jq variables, not shell ones
  jq -cn --arg user "$1" --arg agent "$2" \
    '{permission: "deny", user_message: $user, agent_message: $agent}'
  exit 0
}

# A deploy is `databricks ... bundle|apps [flags] deploy`, run as its own command:
# at the start, or after ; && || |, optionally after VAR=value assignments.
# Text inside a commit message ("fix bundle deploy") does not match.
sep='(^|[;&|][[:space:]]*)'
env_vars='([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
global_args='([[:space:]]+[^[:space:];&|]+)*'
flags='([[:space:]]+-[^[:space:];&|]+([[:space:]]+[^-[:space:];&|][^[:space:];&|]*)?)*'
deploy_re="${sep}${env_vars}databricks${global_args}[[:space:]]+(bundle|apps)${flags}[[:space:]]+deploy([[:space:];&|]|$)"

if [[ ! "$cmd" =~ $deploy_re ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

# Can't verify the working tree → don't guess, block.
if ! git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  deny "Deploy blocked: $cwd is not a git repository, so the deployed version could not be traced." \
       "Deploy blocked: run deploys from inside the git repository."
fi

if ! changes=$(git -C "$cwd" status --porcelain 2>/dev/null); then
  deny "Deploy blocked: git status failed, so uncommitted changes could not be ruled out." \
       "Deploy blocked: git status failed. Fix the repository state, then deploy."
fi

if [[ -n "$changes" ]]; then
  deny "Uncommitted changes. Commit and open a pull request before you deploy." \
       "Deploy blocked: commit the changes and open a pull request first."
fi

echo '{"permission":"allow"}'

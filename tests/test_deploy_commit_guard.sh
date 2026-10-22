#!/bin/bash
# Runs deploy-commit-guard.sh against throwaway git repos and checks each decision.
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/deploy-commit-guard.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

# shellcheck disable=SC2016  # $c and $d are jq variables
run() { jq -cn --arg c "$1" --arg d "$2" '{command: $c, cwd: $d}' | "$HOOK" | jq -r '.permission'; }

expect() {
  local name="$1" want="$2" got="$3"
  if [[ "$got" == "$want" ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: want $want, got $got"
    failures=$((failures + 1))
  fi
}

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init
}

repo="$tmp/repo"
new_repo "$repo"

expect "clean, bundle deploy"                 allow "$(run 'databricks bundle deploy -t dev' "$repo")"
expect "clean, apps deploy"                   allow "$(run 'databricks apps deploy my-app' "$repo")"

echo change > "$repo/file.txt"
expect "dirty, bundle deploy"                 deny  "$(run 'databricks bundle deploy -t dev' "$repo")"
expect "dirty, apps deploy"                   deny  "$(run 'databricks apps deploy my-app' "$repo")"
expect "dirty, extra spaces"                  deny  "$(run 'databricks bundle   deploy' "$repo")"
expect "dirty, flags before deploy"           deny  "$(run 'databricks bundle -t dev deploy' "$repo")"
expect "dirty, --flag=value before deploy"    deny  "$(run 'databricks bundle --target=dev deploy' "$repo")"
expect "dirty, global flag before bundle"     deny  "$(run 'databricks --profile x bundle deploy' "$repo")"
expect "dirty, env var prefix"                deny  "$(run 'DATABRICKS_HOST=x databricks bundle deploy' "$repo")"
expect "dirty, && chain"                      deny  "$(run 'cd /tmp && databricks bundle deploy' "$repo")"
expect "dirty, ; chain"                       deny  "$(run 'echo hi; databricks apps deploy x' "$repo")"
expect "dirty, commit message mentions it"    allow "$(run 'git commit -am "fix databricks bundle deploy"' "$repo")"
expect "dirty, bundle validate"               allow "$(run 'databricks bundle validate' "$repo")"
expect "dirty, deployment word"               allow "$(run 'databricks bundle deployment bind x y' "$repo")"
expect "dirty, non-deploy command"            allow "$(run 'ls -la' "$repo")"

staged="$tmp/staged"; new_repo "$staged"
echo x > "$staged/a.txt"; git -C "$staged" add a.txt
expect "staged only, deploy"                  deny  "$(run 'databricks bundle deploy' "$staged")"

untracked="$tmp/untracked"; new_repo "$untracked"
echo x > "$untracked/new.txt"
expect "untracked only, deploy"               deny  "$(run 'databricks bundle deploy' "$untracked")"

ignored="$tmp/ignored"; new_repo "$ignored"
echo '*.log' > "$ignored/.gitignore"
git -C "$ignored" add .gitignore
git -C "$ignored" -c user.email=t@example.com -c user.name=t commit -q -m ignore
echo x > "$ignored/run.log"
expect "ignored files only, deploy"           allow "$(run 'databricks bundle deploy' "$ignored")"

odd="$tmp/dir with \"quotes\" and spaces"
mkdir -p "$odd"
odd_out=$(jq -cn --arg c 'databricks bundle deploy' --arg d "$odd" '{command: $c, cwd: $d}' | "$HOOK")
expect "odd path, deny is valid JSON"         deny  "$(jq -r '.permission' <<<"$odd_out")"

mkdir -p "$tmp/not-a-repo"
expect "not a git repo, deploy"               deny  "$(run 'databricks bundle deploy' "$tmp/not-a-repo")"
expect "not a git repo, other command"        allow "$(run 'echo hi' "$tmp/not-a-repo")"

expect "empty input"                          allow "$(echo '{}' | "$HOOK" | jq -r '.permission')"

# Malformed input must make the hook fail, so failClosed blocks the command.
code=0; echo 'not json' | "$HOOK" >/dev/null 2>&1 || code=$?
if [[ $code -ne 0 ]]; then
  echo "ok   malformed input exits non-zero ($code)"
else
  echo "FAIL malformed input: hook exited 0"; failures=$((failures + 1))
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "all tests passed"

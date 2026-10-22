# Hook: no deploy with uncommitted changes

A rule can only ask the AI to commit before it deploys. A hook makes sure.

`deploy-commit-guard.sh` runs before every shell command the Cursor agent wants to execute.
If the command is a Databricks deploy (`bundle deploy` or `apps deploy`) and the working tree
has uncommitted changes, the hook denies it and tells both you and the agent why.

## Install (Cursor)

1. Copy `deploy-commit-guard.sh` to `hooks/` in your project root and make it executable
   (`chmod +x hooks/deploy-commit-guard.sh`). Requires `jq` and `git`.
   Because the hook is set to fail closed, a missing `jq` blocks **every** shell command
   the agent runs, not only deploys. Install `jq` first.
2. Copy `.cursor/hooks.json` to `.cursor/hooks.json` in your project root
   (merge the entry if you already have one).
3. Ask the agent to deploy with an uncommitted change. It should be blocked.

## Design choices

- **Block, not ask.** If it must never happen and the fix is cheap (commit first), block.
  Use `ask` for things that are sometimes right, like a production deploy.
- **`failClosed: true`.** By default Cursor lets a command through when a hook crashes or
  times out. This hook protects something you can't undo, so a broken hook blocks instead.
- **Not a git repo → block.** If the hook can't check the working tree, it doesn't guess.
- **What counts as a deploy.** `databricks ... bundle|apps [flags] deploy` run as its own
  command: at the start, after `;`, `&&`, `||` or `|`, or after `VAR=value`. A commit message
  that mentions "bundle deploy" is not a deploy, so the agent can still commit to clear the block.
- **Scope.** It checks for uncommitted changes only (staged, unstaged and untracked; ignored
  files don't count), not whether a pull request exists. Deploys run through a wrapper
  (`make deploy`, `./deploy.sh`, a CI job) are not seen.

## Cost

One `git status` per deploy command, and one script to maintain. Other commands pass through
without touching git.

## Test

`bash tests/test_deploy_commit_guard.sh` runs every case (deploy variants, commit messages,
staged / untracked / ignored files, non-repo folders, malformed input) in throwaway git repos.

Reference: [Cursor hooks documentation](https://cursor.com/docs/agent/hooks).

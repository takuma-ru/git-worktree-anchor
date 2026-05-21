# Git Worktree Anchor

Git Worktree Anchor is a small helper for sharing ignored local development files across Git worktrees.

It links files from `.git/shared/` into the current worktree when the `post-checkout` hook runs. This is useful for files such as `.env.local` or `.vscode/settings.local.json` that should not be committed but should be reused across multiple worktrees.

The linker script is `scripts/git-worktree-anchor.sh`. Git hooks are not tracked by Git, so each target repository must configure its own `post-checkout` hook to call this script.

## Prerequisites

- Use this in a Git repository.
- Bash is required. macOS, Linux, and WSL are the intended environments.
- The `git` command must be available.
- Files under `.git/` are not committed, so `.git/shared/` and `.git/hooks/post-checkout` must be created per local repository.

## Getting Started

Clone this repository to any location.

```bash
git clone https://github.com/takuma-ru/git-worktree-anchor.git
```

Register the clone location in an environment variable.

```bash
cd git-worktree-anchor
export GIT_WORKTREE_ANCHOR_HOME="$(pwd)"
```

To keep using it across shell sessions, add the same value to your shell configuration. If you use Bash, replace `~/.zshrc` with `~/.bashrc` or another file loaded by your shell.

```bash
echo "export GIT_WORKTREE_ANCHOR_HOME=\"$GIT_WORKTREE_ANCHOR_HOME\"" >> ~/.zshrc
```

Git must be run from a shell where `GIT_WORKTREE_ANCHOR_HOME` is exported, because the hook reads this variable at runtime.

Optionally, enable automatic updates. When this is enabled, the script runs `git pull --ff-only` in the Git Worktree Anchor clone before linking files. Update failures do not stop the linking step.

```bash
export GIT_WORKTREE_ANCHOR_AUTO_UPDATE=1
echo "export GIT_WORKTREE_ANCHOR_AUTO_UPDATE=1" >> ~/.zshrc
```

Move to the repository where you want to use Git Worktree Anchor.

```bash
cd /path/to/target-repository
```

Create the shared file directory.

```bash
COMMON_GIT_DIR=$(git rev-parse --git-common-dir)
mkdir -p "$COMMON_GIT_DIR/shared"
```

Create a `post-checkout` hook that calls the cloned linker script.

```bash
COMMON_GIT_DIR=$(git rev-parse --git-common-dir)

cat > "$COMMON_GIT_DIR/hooks/post-checkout" <<'HOOK'
#!/usr/bin/env bash

set -euo pipefail

exec "$GIT_WORKTREE_ANCHOR_HOME/scripts/git-worktree-anchor.sh"
HOOK

chmod +x "$COMMON_GIT_DIR/hooks/post-checkout"
```

Move the local file you want to share into `.git/shared/`.

```bash
COMMON_GIT_DIR=$(git rev-parse --git-common-dir)
mv .env.local "$COMMON_GIT_DIR/shared/.env.local"
```

Run the linker manually to verify the setup.

```bash
"$GIT_WORKTREE_ANCHOR_HOME/scripts/git-worktree-anchor.sh"
ls -l .env.local
```

The setup is complete if `.env.local` is shown as a symlink that points to `.git/shared/.env.local`.

## Shared Files

Place any file you want to share under `.git/shared/`.

Example:

```bash
COMMON_GIT_DIR=$(git rev-parse --git-common-dir)
mkdir -p "$COMMON_GIT_DIR/shared/.vscode"
mv .env.local "$COMMON_GIT_DIR/shared/.env.local"
mv .vscode/settings.local.json "$COMMON_GIT_DIR/shared/.vscode/settings.local.json"
```

The directory structure under `.git/shared/` is mirrored into each worktree.

For example, these shared files:

```text
.git/shared/.env.local
.git/shared/.vscode/settings.local.json
```

create these links in the worktree:

```text
.env.local -> .git/shared/.env.local
.vscode/settings.local.json -> .git/shared/.vscode/settings.local.json
```

## Usage

Normally, Git runs the `post-checkout` hook when a branch is checked out.

```bash
git checkout <branch>
```

After a worktree is created, a checkout inside that worktree links the files registered under `.git/shared/`.

You can also run the linker manually.

```bash
"$GIT_WORKTREE_ANCHOR_HOME/scripts/git-worktree-anchor.sh"
ls -l .env.local
```

The setup is valid if `.env.local` is shown as a symlink that points to `.git/shared/.env.local`.

## Notes

If `.env.local` already exists in the worktree, the script exits without changing anything. This prevents accidental overwrites of existing local configuration.

If shared files contain secrets, confirm that `.git/shared/` remains outside Git tracking and manage file permissions according to your local environment.

Automatic linking depends on Git hooks. It will not run automatically if hooks are disabled or if `.git/hooks/post-checkout` is not executable. In that case, run `"$GIT_WORKTREE_ANCHOR_HOME/scripts/git-worktree-anchor.sh"` manually.

Automatic updates are disabled by default. Set `GIT_WORKTREE_ANCHOR_AUTO_UPDATE=1` to opt in.

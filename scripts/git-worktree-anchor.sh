#!/usr/bin/env bash

set -euo pipefail

# Git Worktree Anchor
# Link files from the repository common Git directory into the current worktree.

COMMON_GIT_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
SHARED_DIR="$COMMON_GIT_DIR/shared"
PROJECT_ROOT=$(git rev-parse --show-toplevel)

if [ ! -d "$SHARED_DIR" ]; then
  exit 0
fi

if [ -e "$PROJECT_ROOT/.env.local" ] || [ -L "$PROJECT_ROOT/.env.local" ]; then
  exit 0
fi

echo "[Git Worktree Anchor] Synchronizing shared files from .git/shared..."

cd "$SHARED_DIR"

find . -type f | while read -r FILE_PATH; do
  TARGET_PATH="$PROJECT_ROOT/${FILE_PATH#./}"
  TARGET_DIR=$(dirname "$TARGET_PATH")
  ABS_SRC_PATH="$SHARED_DIR/${FILE_PATH#./}"

  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
  fi

  ln -sf "$ABS_SRC_PATH" "$TARGET_PATH"
  echo "   Created link: ${FILE_PATH#./}"
done

echo "[Git Worktree Anchor] All shared files linked successfully."

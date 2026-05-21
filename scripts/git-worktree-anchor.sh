#!/usr/bin/env bash

set -euo pipefail

# Git Worktree Anchor
# Link files from the repository common Git directory into the current worktree.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ANCHOR_HOME=$(cd "$SCRIPT_DIR/.." && pwd -P)
COMMON_GIT_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
SHARED_DIR="$COMMON_GIT_DIR/shared"
PROJECT_ROOT=$(git rev-parse --show-toplevel)

if [ -n "${NO_COLOR:-}" ]; then
  BOLD=""
  DIM=""
  CYAN=""
  GREEN=""
  YELLOW=""
  RESET=""
else
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  CYAN=$'\033[36m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RESET=$'\033[0m'
fi

ANCHOR_HEADER_PRINTED=0

print_anchor_header() {
  if [ "$ANCHOR_HEADER_PRINTED" -eq 0 ]; then
    echo "${CYAN}${BOLD}◆ anchor${RESET} ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    ANCHOR_HEADER_PRINTED=1
  fi
}

if [ "${GIT_WORKTREE_ANCHOR_AUTO_UPDATE:-0}" = "1" ]; then
  print_anchor_header
  echo "${CYAN}│${RESET} Updating Git Worktree Anchor"

  if git -C "$ANCHOR_HOME" pull --ff-only --quiet >/dev/null 2>&1; then
    echo "${GREEN}├─${RESET} updated"
  else
    echo "${YELLOW}├─${RESET} update skipped"
  fi
fi

if [ ! -d "$SHARED_DIR" ]; then
  exit 0
fi

if [ -e "$PROJECT_ROOT/.env.local" ] || [ -L "$PROJECT_ROOT/.env.local" ]; then
  exit 0
fi

print_anchor_header
echo "${CYAN}│${RESET} Linking shared files from ${BOLD}.git/shared${RESET}"

cd "$SHARED_DIR"

find . -type f | while read -r FILE_PATH; do
  TARGET_PATH="$PROJECT_ROOT/${FILE_PATH#./}"
  TARGET_DIR=$(dirname "$TARGET_PATH")
  ABS_SRC_PATH="$SHARED_DIR/${FILE_PATH#./}"

  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
  fi

  ln -sf "$ABS_SRC_PATH" "$TARGET_PATH"
  echo "${GREEN}├─${RESET} linked ${BOLD}${FILE_PATH#./}${RESET}"
done

echo "${GREEN}└─ done${RESET}"

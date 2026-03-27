#!/bin/bash
# Install repository-managed git hooks

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if [ ! -d ".githooks" ]; then
  echo "❌ .githooks directory not found in repository root: $REPO_ROOT"
  exit 1
fi

chmod +x .githooks/* || true
git config core.hooksPath .githooks

echo "✅ Git hooks installed successfully"
echo "   core.hooksPath=$(git config --get core.hooksPath)"

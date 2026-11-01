#!/usr/bin/env bash
# setup-tasks.sh — invoked by /speckit-tasks.
# Resolves the active feature directory, copies the tasks template into it when
# tasks.md is missing, and prints a single-line JSON on stdout with the
# available design documents under the feature directory.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$REPO_ROOT"

FEATURE_JSON=".specify/feature.json"
TASKS_TEMPLATE="$REPO_ROOT/.specify/templates/tasks-template.md"

feature_dir=""
if [ -f "$FEATURE_JSON" ]; then
  feature_dir="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$FEATURE_JSON" | head -n 1)"
fi

if [ -z "$feature_dir" ]; then
  echo '{"error":"No active feature: .specify/feature.json is missing or invalid. Run /speckit-specify first."}' >&2
  exit 1
fi

case "$feature_dir" in
  /*) ;;
  *) feature_dir="$REPO_ROOT/$feature_dir" ;;
esac

if [ ! -d "$feature_dir" ]; then
  echo "{\"error\":\"Feature directory $feature_dir does not exist. Run /speckit-specify first.\"}" >&2
  exit 1
fi

TASKS_FILE="$feature_dir/tasks.md"
if [ ! -f "$TASKS_FILE" ] && [ -f "$TASKS_TEMPLATE" ]; then
  cp "$TASKS_TEMPLATE" "$TASKS_FILE"
fi

docs=""
for f in spec.md plan.md research.md data-model.md quickstart.md tasks.md; do
  if [ -f "$feature_dir/$f" ]; then
    if [ -z "$docs" ]; then
      docs="\"$f\""
    else
      docs="$docs, \"$f\""
    fi
  fi
done
if [ -d "$feature_dir/contracts" ]; then
  if [ -z "$docs" ]; then
    docs="\"contracts/\""
  else
    docs="$docs, \"contracts/\""
  fi
fi

printf '{"FEATURE_DIR":"%s","TASKS_TEMPLATE":"%s","AVAILABLE_DOCS":[%s]}\n' \
  "$feature_dir" "$TASKS_TEMPLATE" "$docs"

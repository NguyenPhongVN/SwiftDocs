#!/usr/bin/env bash
# setup-plan.sh — invoked by /speckit-plan.
# Resolves the active feature directory (from .specify/feature.json, written by
# /speckit-specify), copies the plan template into it when plan.md is missing,
# and prints a single-line JSON on stdout.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$REPO_ROOT"

FEATURE_JSON=".specify/feature.json"
TEMPLATES_DIR=".specify/templates"
SPECS_DIR="$REPO_ROOT/specs"

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

FEATURE_SPEC="$feature_dir/spec.md"
if [ ! -f "$FEATURE_SPEC" ]; then
  echo "{\"error\":\"spec.md not found in $feature_dir. Run /speckit-specify first.\"}" >&2
  exit 1
fi

IMPL_PLAN="$feature_dir/plan.md"
if [ ! -f "$IMPL_PLAN" ] && [ -f "$TEMPLATES_DIR/plan-template.md" ]; then
  cp "$TEMPLATES_DIR/plan-template.md" "$IMPL_PLAN"
fi

BRANCH="$(git branch --show-current 2>/dev/null || true)"
if [ -z "$BRANCH" ]; then
  BRANCH="none"
fi

printf '{"FEATURE_SPEC":"%s","IMPL_PLAN":"%s","SPECS_DIR":"%s","BRANCH":"%s"}\n' \
  "$FEATURE_SPEC" "$IMPL_PLAN" "$SPECS_DIR" "$BRANCH"

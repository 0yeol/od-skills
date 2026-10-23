#!/usr/bin/env bash
# od-skills — install design skills from nexu-io/open-design into every AI coding agent.
#
# Usage:
#   od-skills install [--force]   # install/update skills (idempotent)
#   od-skills uninstall           # remove everything installed by od-skills
#   od-skills list                # show installed skills
#
# Install targets:
#   ~/.agents/skills/<name>/           canonical shared copy (real files)
#   <agent>/skills/<name> -> symlink   per-agent link, for each agent found on this machine
#
# Collision policy: a skill name that already exists (and was not installed by
# od-skills) is kept as-is and skipped. Use --force to overwrite.
set -euo pipefail

REPO="0yeol/od-skills"
VERSION="0.1.0"

cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
die()   { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# --- resolve skill source: vendored skills/ next to this script, or download a tarball ---
script_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }
SRC="$(script_dir)"
if [ ! -d "$SRC/skills" ]; then
  command -v curl >/dev/null || die "curl is required to fetch skills from GitHub."
  cyan "Downloading ${REPO}@main …"
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  curl -fsSL "https://github.com/${REPO}/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
  SRC="$TMP/od-skills-main"
fi
[ -d "$SRC/skills" ] || die "skills/ not found in $SRC"

AGENTS_DIR="$HOME/.agents/skills"
MANIFEST="$AGENTS_DIR/.od-skills-installed"

# Agent skill directories. A link is created only when the agent's config dir exists.
# Extra dirs: OD_SKILLS_AGENT_DIRS="~/.foo/skills:~/.bar/skills" (colon-separated)
AGENT_SKILL_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.qwen/skills"
  "$HOME/.iflow/skills"
  "$HOME/.gemini/config/skills"
  "$HOME/.kiro/skills"
  "$HOME/.pi/agent/skills"
)
if [ -n "${OD_SKILLS_AGENT_DIRS:-}" ]; then
  IFS=':' read -ra _extra <<< "$OD_SKILLS_AGENT_DIRS"
  AGENT_SKILL_DIRS+=("${_extra[@]}")
fi

owns() { [ -f "$MANIFEST" ] && grep -qx "$1" "$MANIFEST"; }

linked_agent_dirs() {
  local d base
  for d in "${AGENT_SKILL_DIRS[@]}"; do
    base="$(dirname "$d")"
    [ -d "$base" ] && printf '%s\n' "$d"
  done
}

do_install() {
  local force=0
  [ "${1:-}" = "--force" ] && force=1

  mkdir -p "$AGENTS_DIR"
  touch "$MANIFEST"

  local dirs=("$SRC"/skills/*/) installed=0 updated=0
  local skipped=() name d agent_dir

  for d in "${dirs[@]}"; do
    [ -f "$d/SKILL.md" ] || continue
    name="$(basename "$d")"

    if [ -e "$AGENTS_DIR/$name" ] && ! owns "$name" && [ $force -eq 0 ]; then
      skipped+=("$name")
      continue
    fi
    if owns "$name" || [ -e "$AGENTS_DIR/$name" ]; then updated=$((updated+1)); else installed=$((installed+1)); fi

    rm -rf "$AGENTS_DIR/$name"
    cp -R "$d" "$AGENTS_DIR/$name"
    owns "$name" || echo "$name" >> "$MANIFEST"

    for agent_dir in $(linked_agent_dirs); do
      mkdir -p "$agent_dir"
      ln -sfn "$AGENTS_DIR/$name" "$agent_dir/$name"
    done
  done

  green "od-skills v$VERSION: installed $installed, updated $updated skills into ~/.agents/skills"
  if [ ${#skipped[@]} -gt 0 ]; then
    yellow "Skipped ${#skipped[@]} (name already exists, not from od-skills; --force to overwrite):"
    printf '  %s\n' "${skipped[@]}"
  fi
  echo "Linked into agents:"
  linked_agent_dirs | sed 's/^/  /'
  echo "Uninstall anytime with: od-skills uninstall"
}

do_uninstall() {
  [ -f "$MANIFEST" ] || die "nothing installed (no manifest at $MANIFEST)."
  local name agent_dir count=0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    rm -rf "$AGENTS_DIR/$name"
    for agent_dir in $(linked_agent_dirs); do
      rm -f "$agent_dir/$name"
    done
    count=$((count+1))
  done < "$MANIFEST"
  rm -f "$MANIFEST"
  green "Removed $count skills and their agent links."
}

case "${1:-install}" in
  install)   do_install "${2:-}" ;;
  uninstall) do_uninstall ;;
  list)      [ -f "$MANIFEST" ] && cat "$MANIFEST" || echo "(nothing installed)" ;;
  --version) echo "od-skills $VERSION (upstream: nexu-io/open-design)" ;;
  *) die "unknown command: $1 (use install|uninstall|list)" ;;
esac

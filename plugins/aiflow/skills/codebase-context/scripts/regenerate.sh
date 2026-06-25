#!/usr/bin/env bash
# regenerate.sh — profile-driven, stack-agnostic codebase-context generator.
#
# Reads .claude/pipeline/profile.json for scan roots / surface noun / project class / refs dir,
# then runs `claude -p` with stack-neutral prompts parameterized for THIS project (doc-types.md).
#
# Usage:
#   Run from your PROJECT ROOT (where .claude/pipeline/profile.json lives):
#     bash "$CLAUDE_PLUGIN_ROOT/skills/codebase-context/scripts/regenerate.sh"             # all docs
#     bash "$CLAUDE_PLUGIN_ROOT/skills/codebase-context/scripts/regenerate.sh" architecture  # one doc
#
# Requires: claude CLI (authenticated) + jq.

set -euo pipefail

# Locate the CONSUMING project root = nearest ancestor of CWD containing the profile.
# Works whether this script lives in-repo or inside an installed plugin (run it from the project).
find_root() { local d="$PWD"; while [ "$d" != "/" ]; do [ -f "$d/.claude/pipeline/profile.json" ] && { printf '%s' "$d"; return 0; }; d="$(dirname "$d")"; done; printf '%s' "$PWD"; }
REPO_ROOT="$(find_root)"
cd "$REPO_ROOT"
PROFILE=".claude/pipeline/profile.json"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required to read $PROFILE"; exit 1; }
[ -f "$PROFILE" ] || { echo "ERROR: $PROFILE not found — run /setup first."; exit 1; }

# ── read profile ──────────────────────────────────────────────────────────────
SKILL_PATH="$(jq -r '.context.skillPath // ".claude/skills/codebase-context"' "$PROFILE")"
REFS="$SKILL_PATH/references"
CLASS="$(jq -r '.detection.projectClass // "unknown"' "$PROFILE")"
NOUN="$(jq -r '.context.surfaceNoun // "surface"' "$PROFILE")"
SURFACES="$(jq -r '.context.scanRoots.surfaces | join(", ")' "$PROFILE")"
MODULES="$(jq -r '.context.scanRoots.modules | join(", ")' "$PROFILE")"
COMPONENTS="$(jq -r '.context.scanRoots.components | join(", ")' "$PROFILE")"
HAS_DESIGN="$(jq -r '.capabilities.design.tool // "none"' "$PROFILE")"
TOOLS='Read,Write,Glob,Grep,Bash(git:*),Bash(ls:*)'

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
log()  { echo -e "${CYAN}[regenerate]${NC} $1"; }
ok()   { echo -e "${GREEN}[regenerate]${NC} ✓ $1"; }

# ── doc generators (prompts from doc-types.md, interpolated) ─────────────────────
gen_architecture() {
  log "architecture.md"
  claude -p "Scan ${MODULES} and the project root. Regenerate ${REFS}/architecture.md: framework + version, build/config files, directory layout, entrypoints, module/dependency graph, env vars, run/build scripts. Project class: ${CLASS}. Write directly to the file." --allowedTools "$TOOLS"
  ok "architecture.md"
}
gen_coding_standards() {
  log "coding-standards.md"
  claude -p "Scan ${MODULES} for conventions. Regenerate ${REFS}/coding-standards.md: naming, import/module organization, state/data patterns, error handling, styling approach (if UI), testing conventions. Derive from actual code; prioritize most recently modified areas (git log). Write directly." --allowedTools "$TOOLS"
  ok "coding-standards.md"
}
gen_component_catalog() {
  log "component-catalog.md"
  claude -p "Scan ${COMPONENTS} and ${MODULES}. Regenerate ${REFS}/component-catalog.md — for each reusable unit (component/service/module/package per class ${CLASS}): name, import/path, purpose, key props/exports. Group by category. Write directly." --allowedTools "$TOOLS"
  ok "component-catalog.md"
}
gen_design_system() {
  log "design-system.md"
  if [ "$HAS_DESIGN" != "none" ] && printf '%s' "$CLASS" | grep -Eq '^(web-|ios|android|flutter|react-native)'; then
    claude -p "Scan styles/components of the newest features (git log) in ${MODULES}/${COMPONENTS}. Regenerate ${REFS}/design-system.md: color tokens, typography, spacing scale, breakpoints, border/shadow/radius, button/input styles. Write directly." --allowedTools "$TOOLS"
  else
    mkdir -p "$REFS"; printf 'N/A — no UI layer for %s.\n' "$CLASS" > "$REFS/design-system.md"
  fi
  ok "design-system.md"
}
gen_surface_map() {
  log "surface-map.md (${NOUN}s)"
  claude -p "Scan ${SURFACES}. Regenerate ${REFS}/surface-map.md — map every ${NOUN} to its implementation in ${MODULES}. Format: ${NOUN} -> impl path -> brief description. Group by domain. Run 'git log -1 --format=%ai' per dir for last-modified. Include entry/special files. Write directly." --allowedTools "$TOOLS"
  ok "surface-map.md"
}
gen_feature_catalog() {
  log "feature-catalog.md"
  claude -p "Scan ALL of ${SURFACES} and ${MODULES}. Regenerate ${REFS}/feature-catalog.md — for each feature: type, domain, shape, inputs, outputs, key behaviors, path. Run 'git log -1 --format=%ai' per dir. Mark the most recently modified feature of each type '✅ Latest design'; older '⚠️ may use older patterns'. Group by type; add a quick-reference table. Write directly." --allowedTools "$TOOLS"
  ok "feature-catalog.md"
}
gen_checklists() {
  log "feature-checklists/"
  local classfiles
  case "$CLASS" in
    web-*)                        classfiles="page.md, form.md" ;;
    backend-*)                    classfiles="endpoint.md, job.md" ;;
    ios|android|flutter|react-native*) classfiles="screen.md, flow.md" ;;
    *)                            classfiles="command.md" ;;
  esac
  claude -p "Analyze all features in ${SURFACES}/${MODULES} grouped by type; find common patterns (prioritize recent by git log). Regenerate ${REFS}/feature-checklists/common.md (cross-cutting patterns) plus class-specific files for ${CLASS}: ${classfiles}. Format as checklists; mark recent patterns (follow), older-only (verify). Write all files directly." --allowedTools "$TOOLS"
  ok "feature-checklists/"
}

ALL="architecture coding-standards component-catalog design-system surface-map feature-catalog checklists"
run() {
  case "$1" in
    architecture)      gen_architecture ;;
    coding-standards)  gen_coding_standards ;;
    component-catalog) gen_component_catalog ;;
    design-system)     gen_design_system ;;
    surface-map)       gen_surface_map ;;
    feature-catalog)   gen_feature_catalog ;;
    checklists)        gen_checklists ;;
    *) echo "Unknown target: $1"; echo "Valid: $ALL"; exit 1 ;;
  esac
}

mkdir -p "$REFS/feature-checklists"
if [ $# -eq 0 ]; then
  log "Regenerating ALL docs for class '${CLASS}' (refs: ${REFS}) ..."
  for t in $ALL; do run "$t"; echo ""; done
  ok "All reference docs regenerated."
else
  for t in "$@"; do run "$t"; done
fi

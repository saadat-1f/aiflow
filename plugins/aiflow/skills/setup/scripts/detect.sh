#!/usr/bin/env bash
# detect.sh — deterministic, READ-ONLY project detection for /setup.
#
# Emits canonical JSON to stdout describing what the project IS. Makes NO writes
# and NO network calls. Pure function of repo files (+ `git remote` URL string).
# The /setup SKILL combines this output with `claude mcp list` (tool availability)
# to resolve capability bindings — this script never picks tools/MCPs.
#
# Usage:
#   bash detect.sh [REPO_ROOT]      # defaults to current directory
#
# Implements references/detection-rules.md. Same commit ⇒ identical output.

set -euo pipefail
ROOT="${1:-$(pwd)}"
cd "$ROOT"

PKG="package.json"

# ── helpers ───────────────────────────────────────────────────────────────────
exists()      { [ -e "$1" ]; }
glob_exists() { compgen -G "$1" >/dev/null 2>&1; }
file_has()    { [ -f "$1" ] && grep -Eq "$2" "$1"; }
has_dep()     { [ -f "$PKG" ] && grep -Eq "\"$1\"[[:space:]]*:" "$PKG"; }

json_str()  { printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"; }
json_arr() { # args → ["a","b",...]
  local out="[" first=1 a
  for a in "$@"; do [ $first -eq 1 ] && first=0 || out+=","; out+="$(json_str "$a")"; done
  printf '%s]' "$out"
}
keep_existing() { # args = candidate dirs → JSON array of those that exist
  local kept=() d
  for d in "$@"; do [ -d "$d" ] && kept+=("$d"); done
  json_arr "${kept[@]}"
}
pkg_script() { # $1 = script name → its command string (needs node; empty otherwise)
  [ -f "$PKG" ] || return 0
  command -v node >/dev/null 2>&1 || return 0
  node -e "try{const s=(require('./package.json').scripts)||{};process.stdout.write(s['$1']||'')}catch(e){}" 2>/dev/null || true
}
pkg_version() { # $1 = dep → resolved version string or empty
  [ -f "$PKG" ] || return 0
  command -v node >/dev/null 2>&1 || return 0
  node -e "try{const p=require('./package.json');const d={...(p.dependencies||{}),...(p.devDependencies||{})};process.stdout.write((d['$1']||'').replace(/[^0-9.]/g,''))}catch(e){}" 2>/dev/null || true
}
parse_port() { # $1 = command string → port if -p/--port/PORT= present, else empty
  printf '%s' "$1" | grep -oE '(--port[ =]|[ =]-p |PORT=)[0-9]+' | grep -oE '[0-9]+' | head -1 || true
}

# ── ordered detection (collect all matches in table order; first wins) ──────────
CANDS=(); MARKS=()
add() { CANDS+=("$1"); MARKS+=("$2"); }

glob_exists "*.xcodeproj" || glob_exists "*.xcworkspace" || compgen -G "ios/*.xcodeproj" >/dev/null 2>&1 && add ios "xcodeproj" || true
file_has pubspec.yaml "(^|[[:space:]])flutter:" && add flutter "pubspec.yaml:flutter" || true
{ has_dep react-native && has_dep expo; } && add react-native-expo "package.json:expo" || true
{ has_dep react-native && ! has_dep expo; } && add react-native "package.json:react-native" || true
{ { exists build.gradle || exists build.gradle.kts; } && { find . -maxdepth 4 -name AndroidManifest.xml 2>/dev/null | grep -q . || file_has build.gradle "com.android.application"; }; } && add android "build.gradle:android" || true
has_dep next     && add web-next "package.json:next" || true
has_dep nuxt     && add web-nuxt "package.json:nuxt" || true
exists angular.json && add web-angular "angular.json" || true
has_dep "@sveltejs/kit" && add web-sveltekit "package.json:@sveltejs/kit" || true
{ { has_dep react || has_dep vue || has_dep svelte; } && { has_dep vite || has_dep webpack; } && ! has_dep next && ! has_dep nuxt && ! exists angular.json && ! has_dep "@sveltejs/kit"; } && add web-spa "package.json:spa" || true
{ has_dep express || has_dep fastify || has_dep "@nestjs/core" || has_dep koa || has_dep hapi; } && add backend-node "package.json:server" || true
{ exists manage.py || file_has pyproject.toml "fastapi|flask" || file_has requirements.txt "fastapi|flask|[Dd]jango"; } && add backend-python "python" || true
exists go.mod && add backend-go "go.mod" || true
{ exists pom.xml || file_has build.gradle "spring-boot"; } && add backend-java "java" || true
{ exists Cargo.toml && { exists src/main.rs || file_has Cargo.toml "\[\[bin\]\]"; }; } && add backend-rust "Cargo.toml:bin" || true
{ glob_exists "*.csproj" || glob_exists "*.sln"; } && add backend-dotnet "dotnet" || true
{ exists pnpm-workspace.yaml || exists turbo.json || exists nx.json || exists lerna.json || exists go.work || file_has Cargo.toml "\[workspace\]"; } && add monorepo "workspace-manifest" || true
{ [ ${#CANDS[@]} -eq 0 ] && [ -f "$PKG" ] && grep -Eq "\"(main|exports|module)\"[[:space:]]*:" "$PKG"; } && add library "package.json:lib" || true

if [ ${#CANDS[@]} -eq 0 ]; then CLASS="unknown"; else CLASS="${CANDS[0]}"; fi

# ── package manager ─────────────────────────────────────────────────────────────
PM=""
case "$CLASS" in
  web-*|backend-node|react-native*|library|monorepo)
    if   exists pnpm-lock.yaml;     then PM="pnpm"
    elif exists yarn.lock;          then PM="yarn"
    elif exists bun.lockb;          then PM="bun"
    elif exists package-lock.json;  then PM="npm"
    elif [ -f "$PKG" ];             then PM="npm"; fi ;;
  backend-python|flutter)
    if   exists poetry.lock;        then PM="poetry"
    elif exists uv.lock;            then PM="uv"
    elif exists requirements.txt || exists pyproject.toml; then PM="pip"; fi ;;
esac

# ── runtime command + url ───────────────────────────────────────────────────────
RT_CMD=""; RT_URL=""; def_port=""
case "$CLASS" in
  web-next)        def_port=3000 ;;
  web-nuxt)        def_port=3000 ;;
  web-sveltekit)   def_port=5173 ;;
  web-spa)         def_port=5173 ;;
  web-angular)     def_port=4200 ;;
  backend-node)    def_port=3000 ;;
  backend-python)  def_port=8000 ;;
  backend-go)      def_port=8080 ;;
  backend-java)    def_port=8080 ;;
esac
case "$CLASS" in
  web-*|backend-node)
    for s in dev start serve; do
      cmd="$(pkg_script "$s")"
      if [ -n "$cmd" ]; then RT_CMD="${PM:-npm} run $s"; p="$(parse_port "$cmd")"; [ -n "$p" ] && def_port="$p"; break; fi
    done
    [ -n "$def_port" ] && RT_URL="http://localhost:$def_port" ;;
  backend-python)
    if exists manage.py; then RT_CMD="python manage.py runserver"; fi
    [ -n "$def_port" ] && RT_URL="http://localhost:$def_port" ;;
  backend-go)
    exists go.mod && RT_CMD="go run ./..."; [ -n "$def_port" ] && RT_URL="http://localhost:$def_port" ;;
  flutter)         RT_CMD="flutter run" ;;
  react-native-expo) RT_CMD="expo start" ;;
  android)         RT_CMD="./gradlew installDebug" ;;
  ios)             RT_CMD="xcodebuild" ;;
esac

# ── test runner ─────────────────────────────────────────────────────────────────
TR_FW=""; TR_CMD=""
if   has_dep "@playwright/test" || exists playwright.config.js || exists playwright.config.ts; then TR_FW="playwright"; TR_CMD="npx playwright test"
elif has_dep vitest;            then TR_FW="vitest";  TR_CMD="${PM:-npm} run test"
elif has_dep jest;              then TR_FW="jest";    TR_CMD="${PM:-npm} test"
elif exists pytest.ini || file_has pyproject.toml "pytest"; then TR_FW="pytest"; TR_CMD="pytest"
elif exists go.mod;             then TR_FW="go-test"; TR_CMD="go test ./..."
elif exists Cargo.toml;         then TR_FW="cargo-test"; TR_CMD="cargo test"
elif exists pom.xml;            then TR_FW="junit";   TR_CMD="mvn test"
elif [ "$CLASS" = "ios" ];      then TR_FW="xctest";  TR_CMD="xcodebuild test"
elif [ -f "$PKG" ] && [ -n "$(pkg_script test)" ]; then TR_FW="npm-test"; TR_CMD="${PM:-npm} test"; fi

# ── vcs remote host ─────────────────────────────────────────────────────────────
REMOTE_HOST="unknown"
if command -v git >/dev/null 2>&1; then
  url="$(git remote get-url origin 2>/dev/null || true)"
  case "$url" in
    *dev.azure.com*|*visualstudio.com*) REMOTE_HOST="azure-repos" ;;
    *github.com*)                        REMOTE_HOST="github" ;;
    *gitlab*)                            REMOTE_HOST="gitlab" ;;
    *bitbucket*)                         REMOTE_HOST="bitbucket" ;;
    "")                                  REMOTE_HOST="none" ;;
  esac
fi

# ── scan roots + surface noun ────────────────────────────────────────────────────
case "$CLASS" in
  web-next)        SURF="route";   SR_S=$(keep_existing pages app src/pages);            SR_M=$(keep_existing source/modules src app);          SR_C=$(keep_existing source/modules/components components src/components) ;;
  web-*)           SURF="route";   SR_S=$(keep_existing src/pages src/routes app pages); SR_M=$(keep_existing src app);                          SR_C=$(keep_existing src/components components) ;;
  backend-*)       SURF="endpoint";SR_S=$(keep_existing routes controllers api cmd handlers src/routes); SR_M=$(keep_existing src internal pkg app); SR_C=$(keep_existing services modules src/services) ;;
  ios|android|flutter|react-native*) SURF="screen"; SR_S=$(keep_existing Screens screens lib app/src/main src/screens); SR_M=$(keep_existing Sources lib src);  SR_C=$(keep_existing Views components widgets src/components) ;;
  *)               SURF="command"; SR_S=$(keep_existing cmd bin src);                    SR_M=$(keep_existing src lib internal);                 SR_C=$(keep_existing src lib) ;;
esac

# ── signals (advisory versions; never branch on these) ───────────────────────────
SIG="{"
sig_first=1
add_sig() { local v; v="$(pkg_version "$1")"; if [ -n "$v" ]; then [ $sig_first -eq 1 ] && sig_first=0 || SIG+=","; SIG+="$(json_str "$1"):$(json_str "$v")"; fi; }
for d in next nuxt react vue svelte react-native expo express fastify "@nestjs/core"; do add_sig "$d"; done
[ -n "$PM" ] && { [ $sig_first -eq 1 ] && sig_first=0 || SIG+=","; SIG+="$(json_str packageManager):$(json_str "$PM")"; }
SIG+="}"

# ── emit canonical JSON (fixed key order) ────────────────────────────────────────
cat <<JSON
{
  "projectClass": $(json_str "$CLASS"),
  "candidates": $(json_arr "${CANDS[@]}"),
  "markersMatched": $(json_arr "${MARKS[@]}"),
  "packageManager": $(json_str "$PM"),
  "signals": $SIG,
  "runtime": { "command": $(json_str "$RT_CMD"), "url": $(json_str "$RT_URL") },
  "testRunner": { "framework": $(json_str "$TR_FW"), "command": $(json_str "$TR_CMD") },
  "vcs": { "remoteHost": $(json_str "$REMOTE_HOST") },
  "scanRoots": { "surfaces": $SR_S, "modules": $SR_M, "components": $SR_C },
  "surfaceNoun": $(json_str "$SURF")
}
JSON

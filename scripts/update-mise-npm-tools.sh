#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIN_AGE_DAYS=7

usage() {
  cat <<'EOF'
Usage: scripts/update-mise-npm-tools.sh [--min-age-days DAYS]

Updates pinned npm CLI versions in the Home Manager mise configs.
The selected version is the newest stable npm release older than the
configured minimum age threshold.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-age-days)
      MIN_AGE_DAYS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_cmd jq
require_cmd node
require_cmd npm
require_cmd perl

DARWIN_FILE="$ROOT_DIR/darwin/home-manager/mise/default.nix"
NIXOS_FILE="$ROOT_DIR/nixos/home-manager/mise/default.nix"

COMMON_TOOLS=(
  "npm:aws-cdk"
  "npm:@redocly/cli"
  "npm:corepack"
  "npm:@google/gemini-cli"
  "npm:reviewit"
  "npm:vibe-kanban"
  "npm:@openai/codex"
  "npm:@vibe-kit/grok-cli"
  "npm:ccusage"
  "npm:@aikidosec/safe-chain"
)

DARWIN_ONLY_TOOLS=(
  "npm:difit"
)

current_version() {
  local file="$1"
  local tool="$2"

  rg -o "\"${tool//\//\\/}\" = \"[^\"]+\"" "$file" \
    | sed -E 's/^".*" = "([^"]+)"$/\1/' \
    | head -n1
}

eligible_version() {
  local npm_tool="$1"
  local package_name="${npm_tool#npm:}"
  local versions_json
  local times_json

  versions_json="$(npm view "$package_name" versions --json)"
  times_json="$(npm view "$package_name" time --json)"

  PACKAGE_NAME="$package_name" \
  MIN_AGE_DAYS="$MIN_AGE_DAYS" \
  VERSIONS_JSON="$versions_json" \
  TIMES_JSON="$times_json" \
  node <<'EOF'
const minAgeDays = Number(process.env.MIN_AGE_DAYS);
const versions = JSON.parse(process.env.VERSIONS_JSON);
const times = JSON.parse(process.env.TIMES_JSON);
const cutoff = Date.now() - minAgeDays * 24 * 60 * 60 * 1000;

function parse(version) {
  const [core, prerelease = ""] = version.split("-", 2);
  const parts = core.split(".").map((part) => Number(part));
  return { parts, prerelease };
}

function compare(a, b) {
  const pa = parse(a);
  const pb = parse(b);
  const length = Math.max(pa.parts.length, pb.parts.length);

  for (let i = 0; i < length; i += 1) {
    const av = pa.parts[i] ?? 0;
    const bv = pb.parts[i] ?? 0;
    if (av !== bv) return av - bv;
  }

  if (!pa.prerelease && pb.prerelease) return 1;
  if (pa.prerelease && !pb.prerelease) return -1;
  return pa.prerelease.localeCompare(pb.prerelease);
}

const eligible = versions
  .filter((version) => !version.includes("-"))
  .filter((version) => {
    const published = times[version];
    return published && new Date(published).getTime() <= cutoff;
  })
  .sort(compare);

const selected = eligible.at(-1);
if (!selected) {
  console.error(`No eligible release found for ${process.env.PACKAGE_NAME}`);
  process.exit(1);
}

process.stdout.write(selected);
EOF
}

update_tool_version() {
  local file="$1"
  local tool="$2"
  local version="$3"

  TOOL="$tool" VERSION="$version" perl -0pi -e '
    my $tool = quotemeta($ENV{TOOL});
    my $replacement = "\"$ENV{TOOL}\" = \"$ENV{VERSION}\";";
    my $count = s/"$tool" = "[^"]+";/$replacement/g;
    if ($count == 0) {
      die "Failed to update $ENV{TOOL} in " . $ARGV . "\n";
    }
  ' "$file"
}

process_tool() {
  local file="$1"
  local tool="$2"
  local current
  local target

  current="$(current_version "$file" "$tool")"
  target="$(eligible_version "$tool")"

  if [[ "$current" == "$target" ]]; then
    echo "$tool: unchanged at $current"
    return 0
  fi

  update_tool_version "$file" "$tool" "$target"
  echo "$tool: $current -> $target"
}

echo "Updating pinned npm CLI versions with min age ${MIN_AGE_DAYS} days"

for tool in "${COMMON_TOOLS[@]}"; do
  process_tool "$DARWIN_FILE" "$tool"
  process_tool "$NIXOS_FILE" "$tool"
done

for tool in "${DARWIN_ONLY_TOOLS[@]}"; do
  process_tool "$DARWIN_FILE" "$tool"
done

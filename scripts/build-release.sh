#!/usr/bin/env bash
# Build the distributable artifacts for the singlepane plugin into dist/:
#
#   dist/singlepane-<ver>.zip   plugin folder zipped (org admins upload this; archive source for Claude Code)
#   dist/singlepane.zip         same bytes, unversioned name for the rolling "latest" release
#   dist/<skill>.skill          each skill folder zipped, for claude.ai / Office add-in skill uploads
#   dist/marketplace.json       hosted marketplace catalog pointing at the versioned zip, sha256-pinned
#
# The zip is deterministic (fixed mtimes, sorted entries, no extra attrs) so the same
# source always yields the same sha256. Used by .github/workflows/release.yml and
# runnable locally: scripts/build-release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${REPO:-singlepane-hospitality/sp-claude-plugins}"
PLUGIN="singlepane"
PLUGIN_DIR="$ROOT/plugins/$PLUGIN"
DIST="$ROOT/dist"
FIXED_MTIME="202001010000"   # touch -t format; any constant works

VER="$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")"
[ -n "$VER" ] && [ "$VER" != "null" ] || { echo "plugin.json has no version" >&2; exit 1; }

rm -rf "$DIST"
mkdir -p "$DIST"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Deterministic zip of a directory. $1 = parent dir, $2 = folder name inside it, $3 = output path.
zip_dir() {
  local parent="$1" name="$2" out="$3"
  local tmp="$STAGE/$name.$$"
  mkdir -p "$tmp"
  cp -R "$parent/$name" "$tmp/"
  find "$tmp" \( -name .DS_Store -o -name '__MACOSX' -o -path '*/.claude/*' -o -name '*.pyc' \) -prune -exec rm -rf {} + 2>/dev/null || true
  find "$tmp" -exec touch -t "$FIXED_MTIME" {} +
  ( cd "$tmp" && find "$name" -type f | LC_ALL=C sort | zip -X -D -q "$out" -@ )
  rm -rf "$tmp"
}

# 1. Plugin zip: contents wrapped in a singlepane/ folder (claude.ai "Upload a plugin" expects the
#    plugin folder zipped; Claude Code's archive source accepts the plugin root one directory down).
zip_dir "$ROOT/plugins" "$PLUGIN" "$DIST/$PLUGIN-$VER.zip"
cp "$DIST/$PLUGIN-$VER.zip" "$DIST/$PLUGIN.zip"

# 2. One .skill per skill folder.
for d in "$PLUGIN_DIR"/skills/*/; do
  s="$(basename "$d")"
  zip_dir "$PLUGIN_DIR/skills" "$s" "$DIST/$s.skill"
done

# 3. Hosted marketplace.json: same catalog as .claude-plugin/marketplace.json, but the plugin
#    source is the versioned release zip (a url-sourced marketplace can't use relative paths).
SHA="$(shasum -a 256 "$DIST/$PLUGIN-$VER.zip" | cut -d' ' -f1)"
ASSET_URL="https://github.com/$REPO/releases/download/v$VER/$PLUGIN-$VER.zip"
jq --arg url "$ASSET_URL" --arg sha "$SHA" --arg ver "$VER" --arg name "$PLUGIN" '
  .plugins |= map(
    if .name == $name
    then .source = {source: "archive", url: $url, sha256: $sha} | .version = $ver
    else . end)
' "$ROOT/.claude-plugin/marketplace.json" > "$DIST/marketplace.json"

echo "version:  $VER"
echo "sha256:   $SHA"
echo "archive:  $ASSET_URL"
ls -la "$DIST"

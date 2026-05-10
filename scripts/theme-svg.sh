#!/usr/bin/env bash
# Remap hardcoded fills/strokes in an SVG (typically one exported by
# Anthropic's diagramming tool) to the site's CSS variables, so the
# diagram tracks the page's light/dark theme.
#
# Idempotent — running twice is safe.
#
# Usage:  scripts/theme-svg.sh path/to/diagram.svg
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 path/to/diagram.svg" >&2
  exit 2
fi

f="$1"
[[ -f "$f" ]] || { echo "not a file: $f" >&2; exit 1; }

sed -i \
  -e 's/fill:rgb(250, 249, 245)/fill:var(--fg)/g' \
  -e 's/fill:rgb(194, 192, 182)/fill:var(--muted-strong)/g' \
  -e 's/stroke:rgb(194, 192, 182)/stroke:var(--muted)/g' \
  -e 's/stroke:rgb(156, 154, 146)/stroke:var(--muted)/g' \
  -e 's/fill-opacity="0.18"/fill-opacity="0.32"/g' \
  "$f"

# Soften any <polygon> that has no fill-opacity yet.
# On dark bg this dims the pastels; on light bg it lightens them.
sed -i -E '/<polygon /{/fill-opacity/!s/<polygon /<polygon fill-opacity="0.55" /;}' "$f"

# Force the threshold callout text to a fixed light color. It sits on a
# fixed deep-purple pill, so it must NOT follow the theme — otherwise
# the dark-mode light text becomes dark in light mode and disappears.
sed -i -E '/Indian traditions show|the way beyond/{s/fill:var\(--[a-z-]+\)/fill:#FAF9F5/;}' "$f"

echo "themed: $f"
echo "  text fills (--fg):           $(grep -c 'fill:var(--fg)' "$f" || true)"
echo "  text fills (--muted-strong): $(grep -c 'fill:var(--muted-strong)' "$f" || true)"
echo "  line strokes (--muted):      $(grep -c 'stroke:var(--muted)' "$f" || true)"
echo "  tier polygons at 0.32:       $(grep -c 'fill-opacity="0.32"' "$f" || true)"
leftover=$(grep -cE 'rgb\(250, 249, 245\)|rgb\(194, 192, 182\)|rgb\(156, 154, 146\)' "$f" || true)
if [[ "$leftover" -gt 0 ]]; then
  echo "  warning: $leftover hardcoded light colors remain — check the source" >&2
fi

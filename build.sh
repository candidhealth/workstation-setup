#!/usr/bin/env bash
# Assemble a self-contained bootstrap script for each recipe in recipes/.
#
# A recipe is an ordered list of fragment names (one per line, # = comment).
# Fragments live in fragments/<name>.sh. Output lands in dist/bootstrap-<recipe>.sh
# with __TOTAL_STEPS__ replaced by the number of step() calls in the assembled file.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAG="$ROOT/fragments"
RECIPES="$ROOT/recipes"
OUT="$ROOT/dist"

mkdir -p "$OUT"

build_recipe() {
  local recipe="$1"
  local name body total frag f
  name="$(basename "$recipe" .txt)"
  body=""

  while IFS= read -r frag || [[ -n "$frag" ]]; do
    frag="${frag%%#*}"                      # strip trailing comments
    frag="$(echo "$frag" | xargs)"          # trim whitespace
    [[ -z "$frag" ]] && continue
    f="$FRAG/$frag.sh"
    [[ -f "$f" ]] || { echo "ERROR: $recipe references missing fragment '$frag'" >&2; exit 1; }
    body+=$'\n'"$(cat "$f")"$'\n'
  done < "$recipe"

  total="$(grep -c '^[[:space:]]*step "' <<<"$body" || true)"
  body="${body//__TOTAL_STEPS__/$total}"

  {
    printf '#!/usr/bin/env bash\n'
    printf '# GENERATED from recipes/%s.txt — DO NOT EDIT.\n' "$name"
    printf '# Edit fragments/ and recipes/, then run ./build.sh\n'
    printf 'set -euo pipefail\n'
    printf '%s\n' "$body"
  } > "$OUT/bootstrap-$name.sh"
  chmod +x "$OUT/bootstrap-$name.sh"
  echo "built dist/bootstrap-$name.sh ($total steps)"
}

shopt -s nullglob
recipes=("$RECIPES"/*.txt)
[[ ${#recipes[@]} -gt 0 ]] || { echo "ERROR: no recipes in $RECIPES" >&2; exit 1; }

for recipe in "${recipes[@]}"; do
  build_recipe "$recipe"
done

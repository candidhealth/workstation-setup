# --- Colors & helpers -------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

TOTAL_STEPS=__TOTAL_STEPS__
CURRENT_STEP=0

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf "\n%b==> Step %d/%d: %s%b\n" "$BOLD" "$CURRENT_STEP" "$TOTAL_STEPS" "$1" "$RESET"
}

success() { printf "    %b[done]%b %s\n" "$GREEN" "$RESET" "$1"; }
skip()    { printf "    %b[skip]%b %s\n" "$YELLOW" "$RESET" "$1"; }
die()     { printf "    %b[FAIL]%b %s\n" "$RED" "$RESET" "$*" >&2; exit 1; }

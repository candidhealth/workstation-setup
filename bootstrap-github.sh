#!/usr/bin/env bash
# GENERATED from recipes/github.txt — DO NOT EDIT.
# Edit fragments/ and recipes/, then run ./build.sh
set -euo pipefail

# --- Colors & helpers -------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

TOTAL_STEPS=10
CURRENT_STEP=0

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf "\n%b==> Step %d/%d: %s%b\n" "$BOLD" "$CURRENT_STEP" "$TOTAL_STEPS" "$1" "$RESET"
}

success() { printf "    %b[done]%b %s\n" "$GREEN" "$RESET" "$1"; }
skip()    { printf "    %b[skip]%b %s\n" "$YELLOW" "$RESET" "$1"; }
die()     { printf "    %b[FAIL]%b %s\n" "$RED" "$RESET" "$*" >&2; exit 1; }

# --- Detect shell rc --------------------------------------------------------

if [[ "$SHELL" == *zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
  SHELL_PROFILE="$HOME/.zprofile"
else
  SHELL_RC="$HOME/.bashrc"
  SHELL_PROFILE="$HOME/.bash_profile"
fi
touch "$SHELL_RC"
touch "$SHELL_PROFILE"

# --- Welcome banner ----------------------------------------------------------

printf '%b' "$BOLD"
cat << 'BANNER'

  +-------------------------------------------------+
  |              Workstation Setup                   |
  |                                                  |
  |  Installing and configuring your developer       |
  |  tools. This is safe to re-run anytime.          |
  +-------------------------------------------------+

BANNER
printf '%b' "$RESET"

# --- Xcode Command Line Tools ------------------------------------------------

step "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  skip "Xcode Command Line Tools already installed"
else
  xcode-select --install 2>/dev/null || true
  echo "    Waiting for Xcode Command Line Tools to finish installing..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  success "Xcode Command Line Tools installed"
fi

# --- Homebrew ----------------------------------------------------------------

step "Installing Homebrew..."
if command -v brew &>/dev/null; then
  skip "Homebrew already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  success "Homebrew installed"
fi

# Load brew into the current session so later steps can use it. PATH for future
# shells is owned by the managed block in the login profile (see profile.sh).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- GitHub CLI --------------------------------------------------------------

step "Installing GitHub CLI..."
if command -v gh &>/dev/null; then
  skip "GitHub CLI already installed"
else
  brew install gh
  success "GitHub CLI installed"
fi

# --- GitHub auth -------------------------------------------------------------

step "Authenticating with GitHub..."
if gh auth status &>/dev/null; then
  skip "Already authenticated with GitHub"
else
  echo "    You will be prompted to log in to GitHub."
  if gh auth login; then
    success "Authenticated with GitHub"
  else
    printf "    %b[FAIL]%b GitHub login failed. Please run manually:\n" "$RED" "$RESET"
    echo "           gh auth login"
  fi
fi

# --- Google Cloud SDK --------------------------------------------------------

step "Installing Google Cloud SDK..."
if command -v gcloud &>/dev/null || [[ -x "$HOME/google-cloud-sdk/bin/gcloud" ]]; then
  skip "Google Cloud SDK already installed"
else
  curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
  success "Google Cloud SDK installed"
fi

# Load gcloud into the current session so later steps can use it. PATH for future
# shells is owned by the managed block in the login profile (see profile.sh).
if ! command -v gcloud &>/dev/null && [[ -f "$HOME/google-cloud-sdk/path.bash.inc" ]]; then
  # shellcheck disable=SC1091  # file exists only after the SDK installs at runtime
  source "$HOME/google-cloud-sdk/path.bash.inc"
fi

# --- Google Cloud auth -------------------------------------------------------

step "Authenticating with Google Cloud..."
if gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q .; then
  skip "Already authenticated with Google Cloud"
else
  echo "    A browser window will open for you to sign in with your Google account."
  if gcloud auth login; then
    success "Authenticated with Google Cloud"
  else
    printf "    %b[FAIL]%b Authentication failed. Please run manually:\n" "$RED" "$RESET"
    echo "           gcloud auth login"
  fi
fi

# --- Application Default Credentials -----------------------------------------

step "Setting up Application Default Credentials..."
if [[ -f "$HOME/.config/gcloud/application_default_credentials.json" ]]; then
  skip "Application Default Credentials already configured"
else
  echo "    A browser window will open for you to authorize application access."
  if gcloud auth application-default login; then
    success "Application Default Credentials configured"
  else
    printf "    %b[FAIL]%b ADC login failed. Please run manually:\n" "$RED" "$RESET"
    echo "           gcloud auth application-default login"
  fi
fi

# --- Google Cloud project ----------------------------------------------------

step "Configuring Google Cloud project..."
gcloud config set project candid-v0 2>/dev/null
success "Project set to candid-v0"

# --- Stable env + PATH (login shell) -----------------------------------------
# Stable env vars and PATH belong in the login profile ($SHELL_PROFILE), not the
# interactive rc file. We write a single managed block (between markers) so the
# step is idempotent: re-running rewrites the block in place instead of stacking
# duplicates. No eval/source — just plain exports and a deduped PATH.

step "Configuring login-shell environment ($SHELL_PROFILE)..."

PROFILE_BEGIN="# >>> candid workstation-setup >>>"
PROFILE_END="# <<< candid workstation-setup <<<"

# Identity (CANDID_USER / SESSION_OWNER). Resolve a value without re-prompting if
# we already have one: existing managed block, current env, then a gcloud-account
# default offered at the prompt. We only ask when it isn't already set.
CANDID_EMAIL=""
if [[ -f "$SHELL_PROFILE" ]]; then
  CANDID_EMAIL="$(awk -F'"' '/^export CANDID_USER="/{v=$2} END{print v}' "$SHELL_PROFILE")"
fi
[[ -z "$CANDID_EMAIL" && -n "${CANDID_USER:-}" ]] && CANDID_EMAIL="${CANDID_USER:-}"

if [[ -z "$CANDID_EMAIL" ]]; then
  GCLOUD_ACCOUNT=""
  if command -v gcloud &>/dev/null; then
    GCLOUD_ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
    [[ "$GCLOUD_ACCOUNT" == "(unset)" ]] && GCLOUD_ACCOUNT=""
  fi
  if [[ -e /dev/tty ]]; then
    if [[ -n "$GCLOUD_ACCOUNT" ]]; then
      printf "    Candid email for CANDID_USER / SESSION_OWNER [%s]: " "$GCLOUD_ACCOUNT" > /dev/tty
      read -r reply < /dev/tty || reply=""
      CANDID_EMAIL="${reply:-$GCLOUD_ACCOUNT}"
    else
      printf "    Candid email for CANDID_USER / SESSION_OWNER (blank to skip): " > /dev/tty
      read -r CANDID_EMAIL < /dev/tty || CANDID_EMAIL=""
    fi
  else
    CANDID_EMAIL="$GCLOUD_ACCOUNT"
  fi
fi

# Build the managed block. Common section first, then a shell-specific PATH tail:
# zsh gets a deduped path=() array, bash a plain export.
BLOCK_FILE="$(mktemp)"
{
  printf '# Stable env + PATH. Managed by workstation-setup; edit the generator, not here.\n'
  if [[ -n "$CANDID_EMAIL" ]]; then
    printf 'export CANDID_USER="%s"\n' "$CANDID_EMAIL"
    printf 'export SESSION_OWNER="%s"\n' "$CANDID_EMAIL"
  fi
} > "$BLOCK_FILE"
cat >> "$BLOCK_FILE" << 'BLOCK'
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1
BLOCK
if [[ "$SHELL_PROFILE" == *.zprofile || "$SHELL" == *zsh ]]; then
  cat >> "$BLOCK_FILE" << 'BLOCK'

path=(
  $HOME/google-cloud-sdk/bin
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  $path
)
export PATH
typeset -aU path
BLOCK
else
  cat >> "$BLOCK_FILE" << 'BLOCK'

export PATH="$HOME/google-cloud-sdk/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
BLOCK
fi

NEW_PROFILE="$(mktemp)"
# Drop any existing managed block and trailing blank lines (so re-runs don't
# accumulate whitespace), then append the fresh block.
awk -v b="$PROFILE_BEGIN" -v e="$PROFILE_END" '
  $0==b {skip=1; next}
  $0==e {skip=0; next}
  skip {next}
  NF {for (i=0; i<blanks; i++) print ""; blanks=0; print; next}
  {blanks++}
' "$SHELL_PROFILE" > "$NEW_PROFILE"
{
  printf '\n%s\n' "$PROFILE_BEGIN"
  cat "$BLOCK_FILE"
  printf '%s\n' "$PROFILE_END"
} >> "$NEW_PROFILE"
mv "$NEW_PROFILE" "$SHELL_PROFILE"
rm -f "$BLOCK_FILE"
success "Login-shell environment written to $SHELL_PROFILE"

# Export the stable vars into the current session so the rest of this run sees
# them (PATH is loaded in-session by the homebrew/gcloud steps).
if [[ -n "$CANDID_EMAIL" ]]; then
  export CANDID_USER="$CANDID_EMAIL"
  export SESSION_OWNER="$CANDID_EMAIL"
fi
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1

# --- Claude Code CLI ---------------------------------------------------------

step "Installing Claude Code..."
if command -v claude &>/dev/null; then
  skip "Claude Code already installed"
else
  curl -fsSL https://claude.ai/install.sh | bash
  success "Claude Code installed"
fi

# --- Done! -------------------------------------------------------------------

printf '\n%b%b' "$GREEN" "$BOLD"
cat << 'DONE'
  +-------------------------------------------------+
  |              Setup complete!                     |
  +-------------------------------------------------+
DONE
printf '%b\n' "$RESET"

echo "  Installed and configured:"
if command -v brew   &>/dev/null; then echo "    - Homebrew"; fi
if command -v gh     &>/dev/null; then echo "    - GitHub CLI"; fi
if command -v gcloud &>/dev/null; then echo "    - Google Cloud SDK"; fi
if command -v claude &>/dev/null; then echo "    - Claude Code"; fi

printf "\n  Env vars and PATH were written to %s (login shell).\n" "$SHELL_PROFILE"
printf "  To start using Claude Code, open a new terminal or run:\n"
printf "    source %s\n\n" "$SHELL_PROFILE"


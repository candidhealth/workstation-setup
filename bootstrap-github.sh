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
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! grep -q 'brew shellenv' "$SHELL_PROFILE" 2>/dev/null; then
      # shellcheck disable=SC2016  # literal line written to the rc file, expanded at login
      printf '\n# Homebrew\neval "$(/opt/homebrew/bin/brew shellenv)"\n' >> "$SHELL_PROFILE"
    fi
  fi
  success "Homebrew installed"
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
  if ! command -v gcloud &>/dev/null; then
    # shellcheck disable=SC1091  # file exists only after the SDK installs at runtime
    source "$HOME/google-cloud-sdk/path.bash.inc"
  fi
  skip "Google Cloud SDK already installed"
else
  curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
  # shellcheck disable=SC1091  # file exists only after the SDK installs at runtime
  source "$HOME/google-cloud-sdk/path.bash.inc"
  if ! grep -q 'google-cloud-sdk/path' "$SHELL_RC" 2>/dev/null; then
    # shellcheck disable=SC2016  # literal line written to the rc file, sourced at login
    printf '\n# Google Cloud SDK\nsource "$HOME/google-cloud-sdk/path.bash.inc"\n' >> "$SHELL_RC"
  fi
  success "Google Cloud SDK installed"
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

# --- Claude Code env (Vertex AI) ---------------------------------------------

step "Configuring Claude Code environment variables..."
if grep -q 'CLAUDE_CODE_USE_VERTEX' "$SHELL_RC" 2>/dev/null; then
  skip "Vertex AI environment variables already configured"
else
  cat >> "$SHELL_RC" << 'ENVBLOCK'

# Claude Code (Vertex AI)
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1
ENVBLOCK
  success "Environment variables added to $SHELL_RC"
fi

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
if command -v fnm    &>/dev/null; then echo "    - fnm + Node.js"; fi
if command -v gh     &>/dev/null; then echo "    - GitHub CLI"; fi
if command -v gcloud &>/dev/null; then echo "    - Google Cloud SDK"; fi
if command -v claude &>/dev/null; then echo "    - Claude Code"; fi
if [[ -d "$HOME/.local/share/boost" ]]; then echo "    - Boost"; fi

printf "\n  To start using Claude Code, open a new terminal or run:\n"
printf "    source %s\n\n" "$SHELL_RC"


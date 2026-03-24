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

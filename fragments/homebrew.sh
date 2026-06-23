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

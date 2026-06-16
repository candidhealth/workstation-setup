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

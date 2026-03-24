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

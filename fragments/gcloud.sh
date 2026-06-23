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

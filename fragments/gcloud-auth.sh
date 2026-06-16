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

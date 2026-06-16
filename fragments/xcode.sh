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

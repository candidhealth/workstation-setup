# --- Claude Code CLI ---------------------------------------------------------

step "Installing Claude Code..."
if command -v claude &>/dev/null; then
  skip "Claude Code already installed"
else
  curl -fsSL https://claude.ai/install.sh | bash
  success "Claude Code installed"
fi

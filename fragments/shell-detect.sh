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

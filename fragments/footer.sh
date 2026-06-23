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
if command -v gh     &>/dev/null; then echo "    - GitHub CLI"; fi
if command -v gcloud &>/dev/null; then echo "    - Google Cloud SDK"; fi
if command -v claude &>/dev/null; then echo "    - Claude Code"; fi

printf "\n  Env vars and PATH were written to %s (login shell).\n" "$SHELL_PROFILE"
printf "  To start using Claude Code, open a new terminal or run:\n"
printf "    source %s\n\n" "$SHELL_PROFILE"

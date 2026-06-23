# --- Stable env + PATH (login shell) -----------------------------------------
# Stable env vars and PATH belong in the login profile ($SHELL_PROFILE), not the
# interactive rc file. We write a single managed block (between markers) so the
# step is idempotent: re-running rewrites the block in place instead of stacking
# duplicates. No eval/source — just plain exports and a deduped PATH.

step "Configuring login-shell environment ($SHELL_PROFILE)..."

PROFILE_BEGIN="# >>> candid workstation-setup >>>"
PROFILE_END="# <<< candid workstation-setup <<<"

# Identity (CANDID_USER / SESSION_OWNER). Resolve a value without re-prompting if
# we already have one: existing managed block, current env, then a gcloud-account
# default offered at the prompt. We only ask when it isn't already set.
CANDID_EMAIL=""
if [[ -f "$SHELL_PROFILE" ]]; then
  CANDID_EMAIL="$(awk -F'"' '/^export CANDID_USER="/{v=$2} END{print v}' "$SHELL_PROFILE")"
fi
[[ -z "$CANDID_EMAIL" && -n "${CANDID_USER:-}" ]] && CANDID_EMAIL="${CANDID_USER:-}"

if [[ -z "$CANDID_EMAIL" ]]; then
  GCLOUD_ACCOUNT=""
  if command -v gcloud &>/dev/null; then
    GCLOUD_ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
    [[ "$GCLOUD_ACCOUNT" == "(unset)" ]] && GCLOUD_ACCOUNT=""
  fi
  if [[ -e /dev/tty ]]; then
    if [[ -n "$GCLOUD_ACCOUNT" ]]; then
      printf "    Candid email for CANDID_USER / SESSION_OWNER [%s]: " "$GCLOUD_ACCOUNT" > /dev/tty
      read -r reply < /dev/tty || reply=""
      CANDID_EMAIL="${reply:-$GCLOUD_ACCOUNT}"
    else
      printf "    Candid email for CANDID_USER / SESSION_OWNER (blank to skip): " > /dev/tty
      read -r CANDID_EMAIL < /dev/tty || CANDID_EMAIL=""
    fi
  else
    CANDID_EMAIL="$GCLOUD_ACCOUNT"
  fi
fi

# Build the managed block. Common section first, then a shell-specific PATH tail:
# zsh gets a deduped path=() array, bash a plain export.
BLOCK_FILE="$(mktemp)"
{
  printf '# Stable env + PATH. Managed by workstation-setup; edit the generator, not here.\n'
  if [[ -n "$CANDID_EMAIL" ]]; then
    printf 'export CANDID_USER="%s"\n' "$CANDID_EMAIL"
    printf 'export SESSION_OWNER="%s"\n' "$CANDID_EMAIL"
  fi
} > "$BLOCK_FILE"
cat >> "$BLOCK_FILE" << 'BLOCK'
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1
BLOCK
if [[ "$SHELL_PROFILE" == *.zprofile || "$SHELL" == *zsh ]]; then
  cat >> "$BLOCK_FILE" << 'BLOCK'

path=(
  $HOME/google-cloud-sdk/bin
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  $path
)
export PATH
typeset -aU path
BLOCK
else
  cat >> "$BLOCK_FILE" << 'BLOCK'

export PATH="$HOME/google-cloud-sdk/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
BLOCK
fi

NEW_PROFILE="$(mktemp)"
# Drop any existing managed block and trailing blank lines (so re-runs don't
# accumulate whitespace), then append the fresh block.
awk -v b="$PROFILE_BEGIN" -v e="$PROFILE_END" '
  $0==b {skip=1; next}
  $0==e {skip=0; next}
  skip {next}
  NF {for (i=0; i<blanks; i++) print ""; blanks=0; print; next}
  {blanks++}
' "$SHELL_PROFILE" > "$NEW_PROFILE"
{
  printf '\n%s\n' "$PROFILE_BEGIN"
  cat "$BLOCK_FILE"
  printf '%s\n' "$PROFILE_END"
} >> "$NEW_PROFILE"
mv "$NEW_PROFILE" "$SHELL_PROFILE"
rm -f "$BLOCK_FILE"
success "Login-shell environment written to $SHELL_PROFILE"

# Export the stable vars into the current session so the rest of this run sees
# them (PATH is loaded in-session by the homebrew/gcloud steps).
if [[ -n "$CANDID_EMAIL" ]]; then
  export CANDID_USER="$CANDID_EMAIL"
  export SESSION_OWNER="$CANDID_EMAIL"
fi
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1

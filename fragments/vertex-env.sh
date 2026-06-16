# --- Claude Code env (Vertex AI) ---------------------------------------------

step "Configuring Claude Code environment variables..."
if grep -q 'CLAUDE_CODE_USE_VERTEX' "$SHELL_RC" 2>/dev/null; then
  skip "Vertex AI environment variables already configured"
else
  cat >> "$SHELL_RC" << 'ENVBLOCK'

# Claude Code (Vertex AI)
export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1
ENVBLOCK
  success "Environment variables added to $SHELL_RC"
fi

export GOOGLE_CLOUD_PROJECT="candid-v0"
export GCP_PROJECT="candid-v0"
export GCLOUD_PROJECT="candid-v0"
export GOOGLE_CLOUD_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="candid-claudecode"
export CLAUDE_CODE_USE_VERTEX=1

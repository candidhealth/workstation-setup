# workstation-setup

One-shot setup scripts to reduce the pain of downloading tools.

The scripts you run are **generated** from small fragments and published to the
[`dist`](https://github.com/candidhealth/workstation-setup/tree/dist) branch on
every merge to `main`. Don't edit the generated files — edit `fragments/` and
`recipes/` (see [Developing](#developing)).

## Base

Installs everything needed to run Claude Code via Vertex AI: Homebrew, Google Cloud SDK, auth, and Claude Code.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candidhealth/workstation-setup/dist/bootstrap-base.sh)
```

## GitHub + Ops

Everything in base, plus GitHub CLI.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candidhealth/workstation-setup/dist/bootstrap-github.sh)
```

## What gets installed

| Tool                     | Base | GitHub + Ops |
| ------------------------ | :--: | :----------: |
| Xcode Command Line Tools |  x   |      x       |
| Homebrew                 |  x   |      x       |
| GitHub CLI               |      |      x       |
| Google Cloud SDK         |  x   |      x       |
| Claude Code (Vertex AI)  |  x   |      x       |

Both scripts are **idempotent** — safe to re-run. Already-installed tools are skipped.

## Notes

- Scripts detect your shell (zsh/bash) and append configuration to the appropriate rc file
- Homebrew shellenv is added to your profile (`~/.zprofile` or `~/.bash_profile`) so it loads in login shells
- Google Cloud auth and GitHub auth open a browser for sign-in
- Claude Code is configured to use Vertex AI with the `candid-v0` project
- After running, open a new terminal (or `source ~/.zshrc`) to pick up all env vars

## Developing

Source lives in two places:

- `fragments/<name>.sh` — one install step each (Homebrew, fnm, gcloud, …). Shared across recipes.
- `recipes/<name>.txt` — an ordered list of fragment names. One recipe = one published script.

Build locally:

```bash
./build.sh          # writes dist/bootstrap-<recipe>.sh for every recipe
```

`build.sh` concatenates the fragments in order and substitutes `__TOTAL_STEPS__`
with the number of `step` calls in the assembled script, so step counts stay
correct no matter which fragments a recipe includes.

**Add a tool:** write `fragments/<tool>.sh`, then add its name to the recipes that need it.
**Add a recipe:** create `recipes/<name>.txt`; it publishes as `bootstrap-<name>.sh`.

On merge to `main`, CI (`.github/workflows/build.yml`) runs the build and pushes
the results to the `dist` branch. `dist/` is gitignored on `main`. To roll back a
bad build, revert the offending commit on the `dist` branch.

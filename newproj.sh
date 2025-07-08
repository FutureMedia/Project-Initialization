#!/usr/bin/env bash
# newproj — interactive Bash wizard (2025‑07)
# ==============================================================================
# Walk‑through:
#   1. Initialise local git repo.
#   2. Optional GitHub push (public / private).
#   3. Optional npm init.
#   4. Optional Tailwind CSS:
#        • defaults to stable v3.x
#        • v4 (beta) if you opt‑in — installs correctly **and** writes PRD_Tailwind_v4.md.
# ------------------------------------------------------------------------------
# INSTALL once:
#   mkdir -p "$HOME/bin" && cp newproj "$HOME/bin/newproj" && chmod +x "$HOME/bin/newproj"
#   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
# ------------------------------------------------------------------------------
set -euo pipefail

################################ helpers #######################################
ask_yn() {             # ask_yn "Prompt (Y/n) " [default]
  local prompt="$1" default=${2:-y} reply
  while true; do
    read -rp "$prompt" reply
    reply=${reply:-$default}
    case "$reply" in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please answer y or n." ;; esac
  done
}
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ need '$1'" >&2; exit 1; }; }

write_prd_v4() {
cat > PRD_Tailwind_v4.md <<'EOF'
# Tailwind CSS v4 Integration PRD

**Purpose**: lock down install steps & common pitfalls so no one (human or AI) blows up the build.

## Install
```bash
npm install -D tailwindcss@latest postcss @tailwindcss/postcss
```

## PostCSS config (ESM)
```js
export default { plugins: ["@tailwindcss/postcss"] };
```

## Pitfalls & fixes
| Mistake | Fix |
|---------|-----|
| `npx tailwindcss init -p` | Don’t run it — write configs manually |
| Using CommonJS `require()` | Use `.mjs` files and `export default {}` |
| Installing `@tailwindcss/postcss` alone | You still need plain `postcss` |
| Forgetting `content` paths | Add your HTML/JS glob patterns |

EOF
}

safe_npm_install() { npm install -D "$1" >/dev/null; }

setup_tailwind() {
  local version="$1"  # "^3" or "latest"
  safe_npm_install "tailwindcss@$version"
  safe_npm_install postcss
  safe_npm_install "@tailwindcss/postcss"

  [[ $version == "latest" ]] && write_prd_v4

  cat > postcss.config.mjs <<'EOF'
export default { plugins: ["@tailwindcss/postcss"] };
EOF

  mkdir -p src
  echo '@import "tailwindcss";' > src/style.css
  cat > index.html <<EOF
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>$PROJ</title>
<link rel="stylesheet" href="./src/style.css"></head>
<body class="bg-slate-50 p-8 font-sans"><h1 class="text-4xl font-bold text-teal-600">Hello, Tailwind! ✨</h1></body>
</html>
EOF
}

################################ wizard ########################################
[[ ${1:-} == -h || ${1:-} == --help ]] && grep '^#' "$0" | sed -E 's/^# ?//' && exit 0

read -rp "Project name: " PROJ
[[ -z $PROJ ]] && { echo "❌ name required" >&2; exit 1; }
need git

mkdir "$PROJ" && cd "$PROJ"
git init -q
echo "# $PROJ" > README.md
touch .gitignore
git add .
git commit -q -m "Initial commit"
echo "📚 Local repo ready."

# GitHub push
if command -v gh >/dev/null 2>&1 && ask_yn "Push to GitHub? (Y/n) " y; then
  PRIV_ARG="--public"; ask_yn "Make it private? (y/N) " n && PRIV_ARG="--private"
  gh repo create "$PROJ" --source=. $PRIV_ARG -y
  git branch -M main
  git push -u origin main
  echo "☁️  Repo pushed to GitHub."
fi

# npm init & Tailwind
if ask_yn "Initialise npm? (Y/n) " y; then
  need npm
  npm init -y >/dev/null
  echo "📦 npm initialised."

  if ask_yn "Add Tailwind CSS? (Y/n) " y; then
    TW_VER="^3"  # default stable
    if ask_yn "Opt into Tailwind v4 beta? (y/N) " n; then TW_VER="latest"; fi
    setup_tailwind "$TW_VER"
    echo "🎨 Tailwind $TW_VER installed.";
    [[ $TW_VER == "latest" ]] && echo "   ↪︎ See PRD_Tailwind_v4.md for v4 guidelines."
  fi
fi

echo "✅  $PROJ ready. Happy coding!"

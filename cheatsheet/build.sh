#!/usr/bin/env bash
# Builds cheatsheet.pdf from cheatsheet.md (pandoc -> HTML -> headless Chrome).
set -euo pipefail
cd "$(dirname "$0")"

chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
html="$(mktemp -t cheatsheet).html"
trap 'rm -f "$html"' EXIT

pandoc cheatsheet.md --standalone --embed-resources --css style.css --lua-filter unescape.lua \
  --metadata pagetitle="Neovim cheat sheet" -o "$html"
"$chrome" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/cheatsheet.pdf" "file://$html" 2>/dev/null
echo "$PWD/cheatsheet.pdf"

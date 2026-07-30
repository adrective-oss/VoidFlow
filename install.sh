#!/bin/sh
#
# VoidFlow installer — https://github.com/adrective-oss/VoidFlow
#
# Downloads the latest release, verifies its SHA-256, and installs it.
# Nothing here phones home, and nothing runs with elevated privileges.
#
#   curl -fsSL https://raw.githubusercontent.com/adrective-oss/VoidFlow/main/install.sh | sh
#
set -eu

REPO="adrective-oss/VoidFlow"
APP="VoidFlow.app"
MIN_MACOS_MAJOR=14

say()  { printf '  %s\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
die()  { printf '\n  \033[31m✗\033[0m %s\n\n' "$1" >&2; exit 1; }

printf '\n  \033[1mVoidFlow\033[0m — private dictation for macOS\n\n'

# ---------------------------------------------------------------- requirements

[ "$(uname -s)" = "Darwin" ] || die "VoidFlow is macOS only."

case "$(uname -m)" in
  arm64) ;;
  *) die "VoidFlow requires Apple Silicon. Transcription runs on the Neural Engine,
    which Intel Macs do not have." ;;
esac

macos_version=$(sw_vers -productVersion)
macos_major=${macos_version%%.*}
[ "$macos_major" -ge "$MIN_MACOS_MAJOR" ] \
  || die "VoidFlow requires macOS $MIN_MACOS_MAJOR or later. You are on $macos_version."

ok "macOS $macos_version on Apple Silicon"

# --------------------------------------------------------------- find a release

api="https://api.github.com/repos/$REPO/releases/latest"
release=$(curl -fsSL "$api" 2>/dev/null) || die "No public release yet.

    The beta hasn't opened. Watch the repo to hear when it does:
    https://github.com/$REPO"

# Pull the .zip and its .sha256 out of the release JSON without requiring jq.
zip_url=$(printf '%s' "$release" \
  | grep -o '"browser_download_url": *"[^"]*\.zip"' \
  | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')
sum_url=$(printf '%s' "$release" \
  | grep -o '"browser_download_url": *"[^"]*\.zip\.sha256"' \
  | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')
tag=$(printf '%s' "$release" \
  | grep -o '"tag_name": *"[^"]*"' \
  | head -n1 | sed 's/.*"\([^"]*\)"$/\1/')

[ -n "$zip_url" ] || die "That release has no .zip asset. Please open an issue."
[ -n "$sum_url" ] || die "That release ships no .sha256 checksum, so this installer
    cannot verify what it downloaded. Refusing to install. Please open an issue."

ok "found ${tag:-latest}"

# -------------------------------------------------------- download and verify

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

say "downloading…"
curl -fsSL "$zip_url" -o "$tmp/VoidFlow.zip" || die "Download failed."
curl -fsSL "$sum_url" -o "$tmp/VoidFlow.zip.sha256" || die "Checksum download failed."

expected=$(awk '{print $1; exit}' "$tmp/VoidFlow.zip.sha256")
actual=$(shasum -a 256 "$tmp/VoidFlow.zip" | awk '{print $1}')

[ -n "$expected" ] || die "The checksum file is empty. Refusing to install."
[ "$expected" = "$actual" ] || die "Checksum mismatch — refusing to install.

    expected  $expected
    actual    $actual

    Do not run this download. Please report it: https://github.com/$REPO/issues"

ok "sha-256 verified"

# ------------------------------------------------------------------- install

ditto -x -k "$tmp/VoidFlow.zip" "$tmp/unpacked" || die "Could not unpack the download."
[ -d "$tmp/unpacked/$APP" ] || die "The archive does not contain $APP."

# /Applications needs no sudo when the user is an admin; fall back rather than
# asking for a password we have no business requesting.
if [ -w /Applications ]; then
  dest="/Applications"
else
  dest="$HOME/Applications"
  mkdir -p "$dest"
  say "/Applications isn't writable — installing to ~/Applications instead"
fi

if pgrep -x VoidFlow >/dev/null 2>&1; then
  say "quitting the running copy…"
  osascript -e 'quit app "VoidFlow"' >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x VoidFlow >/dev/null 2>&1 || break
    sleep 1
  done
  pgrep -x VoidFlow >/dev/null 2>&1 && die "VoidFlow is still running. Quit it and re-run this."
fi

rm -rf "$dest/$APP"
mv "$tmp/unpacked/$APP" "$dest/$APP" || die "Could not install to $dest."

ok "installed to $dest/$APP"

# -------------------------------------------------------------------- finish

cat <<'EOF'

  Open it from Spotlight or your Applications folder.

  On first launch it will ask for Microphone and Accessibility, and download
  its speech-recognition model (~600 MB, one time). After that it makes no
  network connections at all — point Little Snitch at it and check.

  Beta builds aren't signed with an Apple Developer ID yet, so macOS treats
  each update as a new app and you'll re-grant Accessibility after updating.
  That goes away at 1.0.

  Uninstall — the app, your history, and your settings:
    rm -rf "/Applications/VoidFlow.app" ~/Library/Application\ Support/VoidFlow

  The speech model is about 450 MB on disk and is NOT removed by that. It
  sits in a cache shared by every app built on FluidAudio, so it is listed
  separately rather than folded into the line above — deleting it would take
  the model out from under any other such app you have installed:
    ~/Library/Application\ Support/FluidAudio/Models/parakeet-tdt-0.6b-v2-coreml

EOF

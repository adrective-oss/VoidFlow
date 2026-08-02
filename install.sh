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
response=$(curl -sSL -w '\n%{http_code}' "$api" 2>/dev/null) \
  || die "Could not reach github.com. Check your internet connection (a proxy
    or firewall can also cause this) and try again."

status=$(printf '%s\n' "$response" | tail -n1)
release=$(printf '%s\n' "$response" | sed '$d')

case "$status" in
  200) ;;
  403) die "GitHub is rate-limiting this connection (HTTP 403). Unauthenticated
    API access is capped at 60 requests/hour per IP address, which a shared
    office or campus network can hit easily on its own. Wait an hour, or from
    a different network, and try again." ;;
  404) die "No public release yet.

    The beta hasn't opened. Watch the repo to hear when it does:
    https://github.com/$REPO" ;;
  *) die "GitHub returned HTTP $status looking up the release. Try again in a
    bit, or check https://github.com/$REPO yourself." ;;
esac

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

# Set before the trap because the trap reads them and this script runs under
# `set -u`. `staged` stays empty until there is actually something staged.
dest=""
staged=""

# The cleanup has to do more than delete the scratch directory, because there
# is one window — between moving the old bundle aside and the new one landing
# — where the user has no app at all. Interrupt the script there and the old
# behaviour deleted their only copy: the backup was staged inside `$tmp`, and
# `$tmp` is precisely what this trap removes. It is staged beside the install
# now, and this puts it back.
cleanup() {
  if [ -n "$staged" ] && [ -d "$staged" ] && [ ! -d "$dest/$APP" ]; then
    mv "$staged" "$dest/$APP" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}

# INT/TERM re-enter cleanup through the EXIT trap as well. That is harmless:
# after a restore `$dest/$APP` exists, so the guard above declines, and
# `rm -rf` on an already-removed directory is a no-op.
trap 'cleanup' EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

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

# Stage-then-swap: move the current install aside before the new one lands, so
# a failure — disk full, an interrupted run, a stray permission bit — leaves
# the user with the app they started with rather than with nothing.
#
# The backup goes to a sibling inside "$dest", not into "$tmp". That placement
# is the whole point: "$tmp" is what the cleanup trap deletes, so staging the
# user's only copy there meant a Ctrl-C in the window below destroyed it —
# the exact outcome this block exists to prevent. The name is dot-prefixed and
# does not end in .app, so it stays out of Finder and is not picked up as a
# second copy of the app while it sits there.
staged="$dest/.$APP.previous"

# A leftover here means an earlier run was killed hard enough to skip its trap
# (SIGKILL, power loss). If nothing is installed, that leftover *is* the
# user's app — put it back rather than deleting it and reporting success.
if [ -d "$staged" ]; then
  if [ -d "$dest/$APP" ]; then
    rm -rf "$staged"
  else
    say "recovering the install an interrupted run left behind…"
    mv "$staged" "$dest/$APP" \
      || die "Found a previous install at $staged but could not move it back.
    Restore it with:  mv \"$staged\" \"$dest/$APP\""
  fi
fi

if [ -d "$dest/$APP" ]; then
  mv "$dest/$APP" "$staged" \
    || die "Could not move aside the existing install at $dest/$APP. Nothing has changed."
fi

if ! mv "$tmp/unpacked/$APP" "$dest/$APP"; then
  if [ -d "$staged" ] && mv "$staged" "$dest/$APP"; then
    die "Could not install the new version to $dest. Your previous install
    has been restored — nothing has changed."
  fi
  die "Could not install to $dest, and could not move your previous install
    back automatically. It has not been deleted — it is at:

      $staged

    Restore it with:  mv \"$staged\" \"$dest/$APP\""
fi

# Only now, with the new bundle confirmed in place, is the backup expendable.
rm -rf "$staged"
staged=""

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

  Before you uninstall: if you turned on Advanced → Startup → Launch at
  login inside the app, turn it off there first. Deleting the app does not
  clear that Login Items entry, and macOS will keep pointing at a bundle
  that no longer exists.

  Uninstall — the app, your history, and your settings:
    rm -rf "/Applications/VoidFlow.app" ~/Library/Application\ Support/VoidFlow

  The ~600 MB above is the download. Once FluidAudio finishes caching it,
  the model itself is about 450 MB on disk, and that cache is NOT removed
  by the rm -rf above. It sits in a cache shared by every app built on
  FluidAudio, so it is listed separately rather than folded into the
  rm -rf line — deleting it would take the model out from under any other
  such app you have installed:
    ~/Library/Application\ Support/FluidAudio/Models/parakeet-tdt-0.6b-v2-coreml

EOF

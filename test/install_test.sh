#!/bin/sh
#
# Tests for install.sh.
#
# install.sh is the highest-consequence file in this repository: every user
# pipes it into a shell, and it is the only code here that can leave someone
# with no application at all. It had no automated coverage until a review found
# three defects in its swap logic — two of which a careful hand-trace missed and
# only surfaced once the thing was actually executed under an interrupt.
#
# So these run the real functions out of install.sh, sourced with
# VOIDFLOW_TEST_LIB=1, against throwaway directories. Nothing here touches
# /Applications, the network, or anything outside its own scratch space.
#
#   sh test/install_test.sh
#
set -u

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
INSTALLER="$SCRIPT_DIR/install.sh"
WORK=$(mktemp -d)
# With an explicit exit, for the reason this suite exists: a trap handler that
# merely returns does not stop a POSIX shell. Without it, a Ctrl-C here wipes
# WORK out from under the still-running cases below — which is how the first
# draft of this file managed to reproduce the bug it was written to catch.
trap 'rm -rf "$WORK"' EXIT
trap 'rm -rf "$WORK"; exit 130' INT
trap 'rm -rf "$WORK"; exit 143' TERM

passed=0
failed=0

pass() { passed=$((passed + 1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
fail() { failed=$((failed + 1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ $# -lt 2 ] || printf '         %s\n' "$2"; }

check() { # name, actual, expected
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected [$3], got [$2]"; fi
}

# A fresh sandbox per case: a destination holding an "old" app, and a scratch
# directory holding the "new" one, each marked so we can tell which survived.
new_sandbox() { # case name -> echoes its root
  root="$WORK/$1"
  rm -rf "$root"
  mkdir -p "$root/dest" "$root/tmp/unpacked/$APP_NAME"
  printf 'NEW\n' > "$root/tmp/unpacked/$APP_NAME/marker"
  echo "$root"
}

with_existing_install() { # root
  mkdir -p "$1/dest/$APP_NAME"
  printf 'OLD\n' > "$1/dest/$APP_NAME/marker"
}

# What is actually installed afterwards: NEW, OLD, or the word "none".
installed_marker() { # root
  if [ -f "$1/dest/$APP_NAME/marker" ]; then
    tr -d '\n' < "$1/dest/$APP_NAME/marker"
  else
    printf 'none'
  fi
}

# Whether the staged backup is still sitting beside the install. Checked
# directly rather than by listing the directory: the question is only ever
# about this one path, and a listing would also drift if anything else ever
# lands in there.
backup_state() { # root
  if [ -e "$1/dest/.$APP_NAME.previous" ]; then printf 'present'; else printf 'gone'; fi
}

# Runs the real install_bundle against a sandbox, in a subshell so each case
# gets a clean set of the globals it reads and cannot leak them into the next.
#
# shellcheck disable=SC2030  # "modification is local to the subshell" is the
# entire point: install_bundle reads tmp/dest/staged, and confining them to
# one case is what keeps the cases independent.
run_install() { # root -> echoes whatever install_bundle printed
  ( tmp="$1/tmp"; dest="$1/dest"; staged=""; install_bundle 2>&1 )
}

APP_NAME="VoidFlow.app"

printf '\n  install.sh\n\n'

[ -f "$INSTALLER" ] || { printf '  cannot find %s\n' "$INSTALLER"; exit 1; }

# Non-vacuity for the whole file: if sourcing ever stops defining these, every
# case below would silently test nothing.
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=install.sh
VOIDFLOW_TEST_LIB=1 . "$INSTALLER"

# install.sh sets `-e` at file scope, so sourcing it turns errexit on *here*.
# This suite exists to run failing paths on purpose — a refused checksum, a
# blocked destination, an interrupted swap — and under errexit the first of
# them takes the runner down mid-file. It did, silently: the interrupt case's
# expected exit 130 aborted the command substitution before it could report,
# which looked exactly like the runner being signalled and cost a while to
# tell apart. Everything below checks statuses explicitly instead.
set +e
for fn in install_bundle cleanup install_traps check_http_status parse_release_assets verify_checksum; do
  if command -v "$fn" >/dev/null 2>&1; then
    pass "sourcing defines $fn"
  else
    fail "sourcing defines $fn" "not defined — every case below is vacuous"
  fi
done

# --------------------------------------------------------------- the swap

root=$(new_sandbox fresh)
run_install "$root" >/dev/null
check "fresh install puts the new app in place" "$(installed_marker "$root")" NEW

root=$(new_sandbox upgrade); with_existing_install "$root"
run_install "$root" >/dev/null
check "upgrade replaces the old app with the new one" "$(installed_marker "$root")" NEW
check "upgrade leaves no backup behind" "$(backup_state "$root")" gone

# The regression that matters most. Between moving the old bundle aside and the
# new one landing there is a window with nothing installed; an interrupt there
# used to run the cleanup trap over the only remaining copy.
#
# The install runs as a backgrounded child and this signals it from outside,
# which is what a real Ctrl-C is. Having the child `kill -INT $$` itself is the
# obvious shortcut and the wrong one: inside a `( … )` subshell `$$` is still
# the *parent* shell's PID, so the first draft of this file signalled the test
# runner instead of the code under test — and the runner's own trap, which then
# also lacked an `exit`, cleaned up and carried on. This suite reproduced the
# bug it exists to catch, twice over.
#
# The child reports reaching the danger window by touching a sentinel, so the
# signal lands inside it rather than on a guessed delay.
interrupt_mid_swap() { # root -> echoes the interrupted installer's exit status
  root=$1
  rm -f "$root/pid"

  # The installer runs in the FOREGROUND and a backgrounded watcher signals it.
  # The obvious arrangement — background the installer, signal it from here —
  # is silently broken: a shell starting an asynchronous list sets SIGINT to
  # ignore, an ignored disposition is inherited, and POSIX says a shell must
  # refuse to trap a signal that was ignored on entry. So backgrounding the
  # installer disarms the exact trap under test. It did, and two assertions
  # below passed anyway — off the EXIT trap, which restores the app too. Only
  # the exit-status check caught that they had stopped meaning anything.
  (
    waited=0
    while [ ! -f "$root/pid" ] && [ "$waited" -lt 100 ]; do
      sleep 0.1
      waited=$((waited + 1))
    done
    [ -f "$root/pid" ] && kill -INT "$(cat "$root/pid")" 2>/dev/null
  ) &
  watcher=$!

  sh -c '
    set -u
    VOIDFLOW_TEST_LIB=1 . "$1"
    tmp="$2/tmp"; dest="$2/dest"; staged=""
    install_traps
    staged="$dest/.$3.previous"
    mv "$dest/$3" "$staged"
    # No app is installed as of this line. Publish the PID to be signalled —
    # atomically, so the watcher cannot read a half-written file — then stay
    # alive long enough to be signalled inside the window.
    echo $$ > "$2/pid.partial" && mv "$2/pid.partial" "$2/pid"
    sleep 2
  ' sh "$INSTALLER" "$root" "$APP_NAME" >/dev/null 2>&1
  status=$?

  wait "$watcher" 2>/dev/null
  echo "$status"
}

root=$(new_sandbox interrupt); with_existing_install "$root"
status=$(interrupt_mid_swap "$root")
check "Ctrl-C mid-swap leaves the previous app installed" "$(installed_marker "$root")" OLD
check "Ctrl-C mid-swap removes the scratch directory" "$([ -d "$root/tmp" ] && echo present || echo gone)" gone
check "an interrupt actually aborts rather than continuing" "$status" 130

# A failed install must put the old app back, not leave the user empty-handed.
root=$(new_sandbox install_fails); with_existing_install "$root"
rm -rf "$root/tmp/unpacked/$APP_NAME"
run_install "$root" >/dev/null
check "a failed install restores the previous app" "$(installed_marker "$root")" OLD

# Killed hard enough to skip the trap: the leftover backup IS the user's app.
#
# Mutation-checked, and the result is worth recording: deleting the recovery
# branch entirely leaves the *end state* identical, because the failure path
# further down restores from "$staged" regardless and a successful install
# replaces the app either way. The branch is belt-and-braces, not load-bearing.
# What it uniquely does is tell the user their app was recovered rather than
# silently swapped, so that message is what this pins — asserting on the end
# state alone would be a test that cannot fail.
root=$(new_sandbox recover_leftover)
mkdir -p "$root/dest/.$APP_NAME.previous"
printf 'OLD\n' > "$root/dest/.$APP_NAME.previous/marker"
output=$(run_install "$root")
check "a leftover backup ends with the new app installed" "$(installed_marker "$root")" NEW
check "recovering a leftover backup is announced" "$(printf '%s' "$output" | grep -c 'recovering the install')" 1

# Same leftover, but an app is already installed — now it is genuinely stale.
root=$(new_sandbox stale_leftover); with_existing_install "$root"
mkdir -p "$root/dest/.$APP_NAME.previous"
printf 'STALE\n' > "$root/dest/.$APP_NAME.previous/marker"
run_install "$root" >/dev/null
check "a stale backup beside a live app is discarded" "$(installed_marker "$root")" NEW
check "the stale backup is gone" "$(backup_state "$root")" gone

# Cannot even stage aside: nothing may change.
root=$(new_sandbox readonly_dest); with_existing_install "$root"
chmod 555 "$root/dest"
run_install "$root" >/dev/null
chmod 755 "$root/dest"
if [ "$(id -u)" = "0" ]; then
  printf '  \033[33mskip\033[0m running as root — permission bits do not apply\n'
else
  check "a read-only destination changes nothing" "$(installed_marker "$root")" OLD
fi

# ------------------------------------------------------- checksum discipline

root=$(new_sandbox checksum)
printf 'payload\n' > "$root/tmp/VoidFlow.zip"
shasum -a 256 "$root/tmp/VoidFlow.zip" | awk '{print $1}' > "$root/tmp/good.sha256"
printf '%s\n' "0000000000000000000000000000000000000000000000000000000000000000" > "$root/tmp/bad.sha256"
: > "$root/tmp/empty.sha256"

( verify_checksum "$root/tmp/VoidFlow.zip" "$root/tmp/good.sha256" >/dev/null 2>&1 )
check "a matching checksum is accepted" "$?" 0
( verify_checksum "$root/tmp/VoidFlow.zip" "$root/tmp/bad.sha256" >/dev/null 2>&1 )
check "a mismatched checksum is refused" "$?" 1
( verify_checksum "$root/tmp/VoidFlow.zip" "$root/tmp/empty.sha256" >/dev/null 2>&1 )
check "an empty checksum file is refused" "$?" 1

# ---------------------------------------------------- release lookup branches

for pair in "200:0" "403:1" "404:1" "500:1"; do
  code=${pair%:*}; want=${pair#*:}
  ( check_http_status "$code" >/dev/null 2>&1 )
  check "HTTP $code is handled" "$?" "$want"
done

# Each failure has to say something different, or the "beta hasn't opened"
# message goes back to standing in for being offline and being rate-limited.
msg_403=$( ( check_http_status 403 ) 2>&1 || true )
msg_404=$( ( check_http_status 404 ) 2>&1 || true )
msg_500=$( ( check_http_status 500 ) 2>&1 || true )
check "rate-limiting is named as such" "$(printf '%s' "$msg_403" | grep -c 'rate-limit')" 1
check "only a real 404 says the beta hasn't opened" "$(printf '%s' "$msg_404" | grep -c "beta hasn't opened")" 1
check "403 does not claim the beta hasn't opened" "$(printf '%s' "$msg_403" | grep -c "beta hasn't opened")" 0
check "an unexpected status reports its code" "$(printf '%s' "$msg_500" | grep -c '500')" 1

# Both assets are required; missing either is fail-closed.
both='{"tag_name": "v9.9.9", "assets": [
  {"browser_download_url": "https://example.invalid/VoidFlow.zip"},
  {"browser_download_url": "https://example.invalid/VoidFlow.zip.sha256"}]}'
zip_only='{"tag_name": "v9.9.9", "assets": [
  {"browser_download_url": "https://example.invalid/VoidFlow.zip"}]}'
sum_only='{"tag_name": "v9.9.9", "assets": [
  {"browser_download_url": "https://example.invalid/VoidFlow.zip.sha256"}]}'

( parse_release_assets "$both" >/dev/null 2>&1 )
check "a complete release is accepted" "$?" 0
( parse_release_assets "$zip_only" >/dev/null 2>&1 )
check "a release with no checksum is refused" "$?" 1
( parse_release_assets "$sum_only" >/dev/null 2>&1 )
check "a release with no zip is refused" "$?" 1

zip_url=""; sum_url=""; tag=""
parse_release_assets "$both" >/dev/null 2>&1
check "the zip URL is parsed" "$zip_url" "https://example.invalid/VoidFlow.zip"
check "the checksum URL is parsed" "$sum_url" "https://example.invalid/VoidFlow.zip.sha256"
check "the tag is parsed" "$tag" "v9.9.9"

# ---------------------------------------------------------------------------

printf '\n  %d passed, %d failed\n\n' "$passed" "$failed"
[ "$failed" -eq 0 ]

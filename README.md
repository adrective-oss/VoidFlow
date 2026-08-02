<div align="center">

# VoidFlow

**Private dictation for macOS. Press a key, speak, get clean text — anywhere.**

Nothing leaves your Mac. Ever.

**Currently in beta.** Installed with a terminal command rather than a browser
download — [here's why](#beta-notes), and it's deliberate.

</div>

---

## Why another dictation app

Because every one you've tried has made you give something up.

Most dictation apps send your audio to a server to transcribe it. That is a
reasonable engineering choice, and it means your meetings, your half-formed
ideas, and anything you say by accident are processed on someone else's
machine under someone else's policy.

VoidFlow runs entirely on your own. Not "encrypted in transit." Not "processed
and deleted." **It never leaves.**

## It stays out of your way

| | VoidFlow |
|---|---|
| Idle memory | **77.9 MB** |
| Active CPU | **13.6%** |
| Idle wake-ups | **35** |

Idle wake-ups is the one nobody advertises, and it's the number that decides
whether your battery survives the afternoon.

<sub>Measured with Activity Monitor during ordinary daily use on an M-series Mac
with 18 GB of RAM. Single machine, single sample — an indication, not a
specification. There's no competitor column because we haven't measured one
under a controlled workload, and a comparison we can't hand you the method for
is exactly how a number like that ends up wrong. If we build a reproducible
harness, these get replaced with its output.</sub>

## What it does

- **Push-to-talk or hands-free**, on a global hotkey
- **Pastes straight into whatever you're using** — editor, terminal, browser
- **Learns your vocabulary** — names, jargon, and your own email address
- **Understands spoken punctuation and structure** — "open paren", "bullet
  point", "new paragraph" — without mangling the times you actually meant the
  words
- **Cleans up prompts** for coding agents, rather than transcribing your "um"s
- **Picks its formatting from context** — a commit message and a Slack reply
  shouldn't come out the same

## Verify the privacy claim yourself

Don't trust us. Point [Little Snitch](https://obdev.at/products/littlesnitch)
or [LuLu](https://objective-see.org/products/lulu.html) at VoidFlow and watch.
The only request it ever makes is the one-time model download on first launch —
which it asks you for before making, and which you can decline and still
dictate. After that, nothing at all.

That's a claim a cloud app cannot make, and it takes you thirty seconds to
check.

## Install

> **The beta is open.** Free while it lasts, and founding subscribers keep
> their entitlement.

```bash
curl -fsSL https://raw.githubusercontent.com/adrective-oss/VoidFlow/main/install.sh | sh
```

Requires macOS 14 or later on Apple Silicon. First launch downloads the
speech-recognition model (~600 MB, one time).

Prefer to read before you pipe? [`install.sh`](install.sh) is short, and most
of it is comments and error messages — it checks your Mac, downloads the
release, verifies its SHA-256 before unpacking anything, and moves the app
into place. You should read it, and any script anyone asks you to pipe into a
shell.

It also has [tests](test/install_test.sh), which run on every change to it.
They drive the real install against throwaway directories — including a real
Ctrl-C delivered in the window where the old app has been moved aside and the
new one hasn't landed yet, because getting that window wrong is the one bug in
an installer that can leave you with nothing.

## Beta notes

VoidFlow is in beta and works fully — these are the rough edges, stated up
front rather than discovered.

- **You'll re-grant Accessibility after each update.** Beta builds aren't
  signed with an Apple Developer ID yet, so macOS treats each update as a new
  app. This is the one that will annoy you, and it goes away at 1.0 — with one
  last re-grant when the real signature lands.
- **The install is a terminal command on purpose.** Files downloaded via
  `curl` aren't quarantined by Gatekeeper, which is what lets the beta ship
  before code signing is in place. The flip side: don't download the `.zip`
  from the Releases page in a browser. That *does* quarantine it, and macOS
  will refuse to open it. Use the command above.
- **The checksum proves the download arrived intact, not who built it.** Both
  files come from the same release, so it catches a corrupted or truncated
  transfer — not a compromised one. Only a Developer ID signature carries
  authorship, and that arrives at 1.0.

## Licence

VoidFlow is **proprietary software**, © 2026 Adrective. Free during the beta;
paid afterwards. Founding subscribers keep their entitlement.

- [End User Licence Agreement](EULA.md)
- [Privacy Policy](PRIVACY.md)
- [Third-party notices](NOTICE.md) — includes Parakeet TDT 0.6B v2 by NVIDIA,
  licensed CC BY 4.0

This repository contains the installer and releases. The application source is
not public.

---

<div align="center">

**[Adrective](https://adrective.com)** · hello@adrective.com

</div>

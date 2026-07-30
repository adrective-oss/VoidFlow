<div align="center">

# VoidFlow

**Private dictation for macOS. Press a key, speak, get clean text — anywhere.**

Nothing leaves your Mac. Ever.

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
with 18 GB of RAM. Single machine, single sample. A reproducible benchmark
harness — with competing apps measured under an identical scripted workload —
ships alongside the beta, and the numbers here will be replaced with its
output. We'd rather publish one honest column now than a comparison we can't
hand you the method for.</sub>

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
After the one-time model download on first launch, it makes no network
connections at all.

That's a claim a cloud app cannot make, and it takes you thirty seconds to
check.

## Install

> **The beta isn't open yet.** Watch this repo — the first build lands in
> [Releases](https://github.com/adrective-oss/VoidFlow/releases), and this
> command starts working the moment it does. Free while the beta lasts.

```bash
curl -fsSL https://raw.githubusercontent.com/adrective-oss/VoidFlow/main/install.sh | sh
```

Requires macOS 14 or later on Apple Silicon. First launch downloads the
speech-recognition model (~600 MB, one time).

Prefer to read before you pipe? [`install.sh`](install.sh) is 100 lines and
does nothing clever — you should read it, and any script anyone asks you to
pipe into a shell.

## Beta notes

- **You'll re-grant Accessibility after each update.** Beta builds aren't
  signed with an Apple Developer ID yet, so macOS treats each update as a new
  app. This goes away at 1.0.
- **The install is a terminal command on purpose.** Files downloaded via
  `curl` aren't quarantined by Gatekeeper, which is what lets the beta ship
  before code signing is in place.

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

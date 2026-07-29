# VoidFlow — Privacy Policy

**Last updated:** 28 July 2026
**Data controller:** Adrective · privacy@adrective.com

---

## The short version

**We receive nothing. There is no server to receive it.**

VoidFlow transcribes your speech entirely on your own Mac. Your audio, your
transcripts, and your dictionary never leave the machine, because the
application contains no code capable of sending them anywhere.

You do not have to take our word for this. Point Little Snitch, LuLu, or any
network monitor at VoidFlow and watch: after the one-time model download
described in section 3, it makes no network connections at all.

---

## 1. What we collect

**Nothing.** We operate no account system, no analytics, no crash reporting,
and no telemetry. We do not know who you are, that you installed VoidFlow, or
that you ever used it.

There is no "anonymised usage data" caveat here, because there is no data
collection to anonymise.

## 2. What VoidFlow stores on your Mac

All of it stays local, in `~/Library/Application Support/VoidFlow/`:

| File | Contents |
|---|---|
| `history.json` | Your recent dictations — the raw transcript, the final text, and **the name and window title of the app you dictated into**. Capped at the 200 most recent. |
| `dictionary.json` | Custom vocabulary you have taught it |
| `addresses.json` | Email addresses you added, so they transcribe correctly |
| `settings.json` | Your preferences |
| `latency.jsonl` | Timing measurements, for diagnosing slowness. No transcript text. |
| `transitions.jsonl` | Internal state transitions, for diagnosing bugs. No transcript text. |

These are plain, unencrypted JSON files, protected by your macOS user account
and by FileVault if you have it enabled. You can read them, back them up, or
delete them at any time. Deleting the folder resets VoidFlow completely.

**Worth stating plainly:** `history.json` records not only what you said but
which application and window you said it into. It is the most sensitive file
VoidFlow creates. It never leaves your Mac, but it is on your Mac.

## 3. Network activity — the complete list

**One-time model download.** On first launch, VoidFlow downloads its
speech-recognition model (approximately 600 MB) from Hugging Face
(`huggingface.co`). This is a plain file download. It contains nothing about
you. Once the model has loaded, VoidFlow disables further network access for
the remainder of the session.

**Licence validation (not yet active).** When a paid subscription is
introduced, VoidFlow will contact our payment provider to check your
entitlement. That request will carry only licence information — never audio,
never transcripts, never anything you dictated. This policy will be updated
before that ships.

That is the complete list. There is nothing else.

## 4. Audio recordings

Audio is written to a temporary file during a dictation and **deleted the
moment transcription finishes**.

An optional "Save temporary audio" setting keeps those files instead. It is
**off by default**. Turning it on keeps them in your system temp directory
until macOS clears it.

## 5. Speech recognition

Transcription uses Parakeet, running on your Mac's Neural Engine. While the
model is still loading, VoidFlow may briefly use Apple's Speech framework —
and it explicitly requires on-device recognition. If a Mac or language cannot
do on-device recognition, **VoidFlow refuses to transcribe rather than sending
audio to Apple's servers.**

An optional feature can ask Apple's on-device language model to resolve
ambiguous words. It runs entirely on your Mac and is **off by default**.

## 6. Permissions

| Permission | Why |
|---|---|
| Microphone | To hear your dictation |
| Accessibility | To type text into other apps. Also how VoidFlow reads the active window's title, which it uses to pick the right formatting |
| Speech Recognition | For the on-device live preview |

Revoke any of them at any time in System Settings → Privacy & Security.

## 7. Your rights

Because we hold no data about you, there is nothing for us to give you, correct,
or erase — the GDPR/CCPA rights of access, rectification, erasure, and
portability are satisfied by the fact that **you already hold all of it**, in
readable JSON, on your own machine.

To exercise them: open, edit, or delete the files in section 2. To erase
everything, delete `~/Library/Application Support/VoidFlow/`.

## 8. Children

VoidFlow is not directed at children under 13. Since we collect no data, we
cannot knowingly collect data from anyone.

## 9. Third parties

We share your data with no one, because we have none.

Two third parties are involved in delivering the software itself:

- **Hugging Face** — hosts the model file (section 3). Your IP address is
  visible to them during that download, as with any file download.
- **GitHub** — hosts the application download. Same.

Neither receives anything about your use of VoidFlow.

## 10. Changes

If this policy changes materially — in particular if VoidFlow ever transmits
anything beyond section 3 — we will say so prominently in-app before the
change takes effect, not quietly in a document nobody re-reads.

## 11. Contact

**Adrective** · privacy@adrective.com · https://adrective.com

---

*This policy describes VoidFlow's actual behaviour, verified against its
source. The zero-egress property is enforced by an automated test that fails
the build if networking code is introduced into the application.*

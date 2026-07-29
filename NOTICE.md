# Third-Party Notices

This application incorporates the third-party software and machine-learning
models listed below. Each entry states the licence it is used under and the
attribution that licence requires.

Scope note: this file covers what is **distributed to users** — the code
compiled into the shipped application binary, and the model weights the
application downloads on first run. Tooling used only to build and evaluate
the app is listed separately at the end and is not distributed.

Full licence texts referenced here live in `LICENSES/`.

---

## 1. Software compiled into the application

All of the following are statically linked into the application binary, so
their binary-redistribution terms apply to every copy shipped to a user.

### FluidAudio

Speech-recognition runtime and Core ML model management.

- Copyright © FluidInference
- Source: https://github.com/FluidInference/FluidAudio
- Version: 0.15.5
- Licence: **Apache License, Version 2.0** — see `LICENSES/Apache-2.0.txt`

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

FluidAudio is used as an unmodified dependency; no changes were made to its
source.

### fastcluster

Hierarchical clustering routines, vendored inside FluidAudio
(`Sources/FastClusterWrapper`).

- Licence: **BSD 2-Clause** — see `LICENSES/BSD-2-Clause-fastcluster.txt`

The following notice is reproduced as that licence requires for binary
redistribution:

> Copyright:
>   * Until package version 1.1.23: © 2011 Daniel Müllner <https://danifold.net>
>   * All changes from version 1.1.24 on: © Google Inc. <https://www.google.com>
> All rights reserved.
>
> Redistribution and use in source and binary forms, with or without
> modification, are permitted provided that the following conditions are met:
>
>   * Redistributions of source code must retain the above copyright notice,
>     this list of conditions and the following disclaimer.
>   * Redistributions in binary form must reproduce the above copyright
>     notice, this list of conditions and the following disclaimer in the
>     documentation and/or other materials provided with the distribution.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
> AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
> IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
> ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
> LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
> CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
> SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
> INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
> CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
> ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
> POSSIBILITY OF SUCH DAMAGE.

### VBx

Speaker-diarization components, vendored inside FluidAudio.

- Licence: **Apache License, Version 2.0** — see `LICENSES/Apache-2.0.txt`

---

## 2. Machine-learning models downloaded at first run

These weights are not bundled in the installer. The application downloads them
from Hugging Face the first time it runs and caches them locally; it does not
redistribute them.

### Parakeet TDT 0.6B v2

The speech-recognition model that performs all transcription.

- Original model: **`nvidia/parakeet-tdt-0.6b-v2`**, copyright © NVIDIA Corporation
- Core ML conversion: `FluidInference/parakeet-tdt-0.6b-v2-coreml`, by FluidInference
- Licence: **Creative Commons Attribution 4.0 International (CC BY 4.0)**
- Licence text: https://creativecommons.org/licenses/by/4.0/

**Required attribution:**

> This application performs speech recognition using the Parakeet TDT 0.6B v2
> model, created by NVIDIA Corporation and licensed under CC BY 4.0
> (https://creativecommons.org/licenses/by/4.0/). The model was converted to
> Core ML format by FluidInference. The model has been modified only by format
> conversion; its weights are unchanged.

CC BY 4.0 permits commercial use provided this attribution is given. Neither
NVIDIA nor FluidInference endorses this application.

No other model is downloaded. The application calls
`AsrModels.downloadAndLoad(version: .v2)` and nothing else — FluidAudio's
voice-activity-detection, diarization, and text-to-speech models are never
fetched. After the ASR model loads, the application sets
`ModelHub.offlineMode = true`, so no further network request is possible for
the remainder of the process.

---

## 3. Apple frameworks

AppKit, AVFoundation, Speech, ApplicationServices, and Foundation Models are
first-party Apple frameworks used under the Apple Developer Program Licence
Agreement. No separate attribution is required.

---

## 4. Development tooling — **not distributed**

Used to build, benchmark, and evaluate the application. None of it is compiled
into the shipped binary, and none of it requires attribution to end users. Listed
for completeness only; if any of it ever ships, move it to section 1.

| Component | Licence | Used by |
|---|---|---|
| argmax-oss-swift (WhisperKit) | MIT | `Bakeoff` accuracy-comparison target |
| swift-transformers | Apache-2.0 | transitive, via argmax-oss-swift |
| swift-argument-parser | Apache-2.0 | transitive, via argmax-oss-swift |

---

## Maintaining this file

`Package.resolved` lists every *resolved* package, including ones that only
the development targets use — it is not the right source for this file. What
belongs in section 1 is what the **application target** links. Verify with:

```bash
swift package show-dependencies --format json    # full graph
otool -L <App>.app/Contents/MacOS/<App>          # dynamically linked libraries
```

Re-check this file whenever a dependency is added, upgraded, or moved between
targets, and whenever the ASR model version changes.

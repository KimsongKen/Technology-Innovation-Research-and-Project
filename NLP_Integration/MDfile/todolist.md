# Voice / ASR — next steps

- [x] **Integrate a stronger voice stack** (bigger wins than small config tweaks alone):
  - [x] **Local GPU path:** `faster-whisper` + **CUDA** — set e.g. `SACA_USE_FASTER_WHISPER=1`, `SACA_WHISPER_MODEL=large-v3` (or `medium`), `SACA_WHISPER_DEVICE=cuda`, `SACA_WHISPER_COMPUTE_TYPE=float16`. See `api/bridge/config.py`.
  - [x] **Hosted path:** OpenAI-compatible **`/v1/audio/transcriptions`** — `SACA_USE_HOSTED_STT=1`, `SACA_HOSTED_STT_API_KEY` or `OPENAI_API_KEY`, optional `SACA_HOSTED_STT_BASE_URL` / `SACA_HOSTED_STT_MODEL`. Tried **before** local Whisper in `STTService` for English (`analyze-voice` with `language=en`, etc.). Swap in a medical/telehealth vendor that exposes the same API shape.

**Note:** Warlpiri-specific quality still depends on **language coverage** (e.g. MMS `wbp` vs fallback adapters) and/or **Warlpiri-finetuned** models — see `api/bridge/warlpiri_stt.py` and env vars in `api/bridge/config.py`.

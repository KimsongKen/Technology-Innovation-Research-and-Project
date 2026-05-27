# Files to Upload to GitHub — SACA Project

This document lists every file and folder that will go into the main branch.
Review this before pushing. When ready, run: `git push origin main --force`

---

## Root Files

| File | Purpose |
|------|---------|
| `README.md` | ✅ NEW — full project overview, architecture diagram, API reference, setup guide |
| `.gitignore` | ✅ UPDATED — excludes .venv, temp files, debug WAVs; allows .cbm models and test WAVs |
| `main.py` | Compatibility entry point (`uvicorn main:app` still works) |
| `requirements.txt` | Runtime Python dependencies (catboost, fastapi, faster-whisper, etc.) |
| `requirements.training.txt` | Training/fine-tuning dependencies (separate, not needed to run the API) |
| `run_api.ps1` | Windows PowerShell launcher for the backend |
| `run_api.cmd` | Windows CMD launcher |
| `test_api.ps1` | PowerShell smoke test script |
| `scrape_dictionary.py` | Utility to parse AuSIL/Lexique Pro Warlpiri HTML into a clinical map |
| `todolist.md` | Project task tracking |

---

## api/ — FastAPI Backend (Production Runtime)

| File | Purpose |
|------|---------|
| `api/main.py` | App entry point — FastAPI app, CORS, router registration |
| `api/bridge/router.py` | All API routes (`/triage/predict`, `/triage/analyze-voice`, `/health`, etc.) |
| `api/bridge/audio_pipeline.py` | WAV decode (8/16/24/32-bit), normalize, quality check, clipping detection |
| `api/bridge/stt_service.py` | faster-whisper STT + tiny fallback + 3-pass temperature retry |
| `api/bridge/warlpiri_stt.py` | Meta MMS ASR for Warlpiri voice input |
| `api/bridge/warlpiri_dict.py` | Clinical dictionary bridge — exact + Levenshtein fuzzy matching (~60 entries) |
| `api/bridge/nlp_service.py` | SBERT encoder (all-MiniLM-L6-v2) |
| `api/bridge/triage_service.py` | Orchestration — CatBoost ML + heuristic fallback |
| `api/bridge/ml_predictor.py` | CatBoost severity + disease predictor (loads .cbm files) |
| `api/bridge/symptom_lexicon.py` | 179-phrase canonical symptom map (no duplicate keys) |
| `api/bridge/clinical_text.py` | 67 emergency keywords + Warlpiri emergency pre-check |
| `api/bridge/hosted_stt.py` | Optional OpenAI-compatible hosted transcription API |
| `api/bridge/models.py` | Pydantic request/response schemas |
| `api/bridge/security.py` | Bearer token authentication |
| `api/bridge/config.py` | All env-var driven configuration (BridgeConfig dataclass) |
| `api/bridge/transcript_audit.py` | Optional JSONL audit logging |
| `api/bridge/examples/multipart_curl_example.md` | curl usage examples |
| `api/utils/warlpiri_normalizer.py` | Warlpiri text normalizer utility |
| `api/__init__.py` | Package marker |
| `api/bridge/__init__.py` | Package marker |
| `api/routes/__init__.py` | Package marker |
| `api/utils/__init__.py` | Package marker |

---

## archive/ — Model Evaluation + Trained Models

> ⚠️ The `.cbm` files inside `catboost_runtime_artifacts/` are the **live trained models** used
> by the API. They are also your proof of machine training.

| File | Purpose |
|------|---------|
| `archive/saca_model_evaluation/catboost_runtime_artifacts/catboost_severity.cbm` | **Trained CatBoost severity model** (1.1 MB) |
| `archive/saca_model_evaluation/catboost_runtime_artifacts/catboost_disease.cbm` | **Trained CatBoost disease model** (11 MB) |
| `archive/saca_model_evaluation/catboost_runtime_artifacts/severity_classes.json` | Severity class labels (Mild / Moderate / Severe) |
| `archive/saca_model_evaluation/catboost_runtime_artifacts/disease_classes.json` | 40 disease class labels |
| `archive/saca_model_evaluation/final_architecture_recommendation.md` | **Evaluation conclusion — CatBoost 7 pts vs ExtraNG 3 pts** |
| `archive/saca_model_evaluation/model_comparison_report.md` | Side-by-side model comparison |
| `archive/saca_model_evaluation/evaluation_results.json` | Raw evaluation scores |
| `archive/saca_model_evaluation/explainability_report.md` | Feature explainability analysis |
| `archive/saca_model_evaluation/explainability_results.json` | Explainability data |
| `archive/saca_model_evaluation/nlp_noise_report.md` | NLP noise robustness test results |
| `archive/saca_model_evaluation/nlp_noise_results.json` | NLP noise data |
| `archive/saca_model_evaluation/profiling_report.md` | Latency profiling results |
| `archive/saca_model_evaluation/profiling_results.json` | Profiling data |
| `archive/saca_model_evaluation/model_predictions.csv` | *(not uploaded — excluded by .gitignore)* |
| `archive/saca_model_evaluation/run_evaluation.py` | Script that ran the 7-criteria evaluation |
| `archive/saca_model_evaluation/data_prep.py` | Dataset preparation script |
| `archive/saca_model_evaluation/system_eval_utils.py` | Shared evaluation utilities |
| `archive/saca_model_evaluation/model_a_extrang_wrapper.py` | ExtraNG wrapper used during evaluation |
| `archive/saca_model_evaluation/model_b_catboost_wrapper.py` | CatBoost wrapper used during evaluation |
| `archive/saca_model_evaluation/test_explainability.py` | Explainability test script |
| `archive/saca_model_evaluation/test_nlp_noise.py` | NLP noise test script |
| `archive/saca_model_evaluation/test_profiling.py` | Profiling test script |
| `archive/saca_model_evaluation/interactive_symptom_test.py` | Interactive CLI test tool |
| `archive/saca_model_evaluation/build_final_architecture_recommendation.py` | Report generation script |
| `archive/saca_model_evaluation/standardized_split_meta.json` | Train/test split metadata |
| `archive/saca_model_evaluation/unique_disease_labels.txt` | All 40 disease label names |
| `archive/README.md` | Archive area documentation |

---

## data/ — Training Dataset

| File | Purpose |
|------|---------|
| `data/saca_top_40_dataset.csv` | 40-disease clinical training dataset |

---

## docs/ — Documentation

| File | Purpose |
|------|---------|
| `docs/warlpiri_finetune_guide.md` | How to fine-tune Meta MMS for Warlpiri (wbp) — full Python scripts |
| `docs/warlpiri_data_sourcing.md` | Where to get Warlpiri speech data (AIATSIS, PARADISEC, linguists) |
| `docs/reference/integration_prompt_reference.txt` | Internal integration reference |

---

## generated/ — Auto-Generated Files

| File | Purpose |
|------|---------|
| `generated/warlpiri_clinical_map.py` | Warlpiri → English clinical map (generated by scrape_dictionary.py) |
| `generated/__init__.py` | Package marker |

---

## tests/ — Test Suite

| File | Purpose |
|------|---------|
| `tests/warlpiri_test_cases.json` | 10 bilingual clinical test scenarios with expected triage levels |
| `tests/test_warlpiri_pipeline.py` | Text-only pipeline validator — no server needed, runs offline |
| `tests/test_warlpiri_api.py` | Full API integration test with HTML report output |
| `tests/generate_test_audio.py` | TTS WAV generator (edge-tts → pyttsx3 → gTTS fallback) |
| `tests/audio/TC-01_heart_attack.wav` | Test audio — heart attack symptoms in English |
| `tests/audio/TC-02_cannot_breathe__respiratory_emergency.wav` | Test audio — respiratory emergency |
| `tests/audio/TC-03_seizure_and_collapse.wav` | Test audio — seizure |
| `tests/audio/TC-04_stroke_signs.wav` | Test audio — stroke |
| `tests/audio/TC-05_severe_bleeding.wav` | Test audio — bleeding emergency |
| `tests/audio/TC-06_high_fever_with_cough__pneumonia.wav` | Test audio — pneumonia |
| `tests/audio/TC-07_stomach_pain_and_vomiting__gastroenteritis.wav` | Test audio — gastroenteritis |
| `tests/audio/TC-08_headache_and_dizziness__hypertension___migraine.wav` | Test audio — hypertension/migraine |
| `tests/audio/TC-09_sick_child_with_fever__paediatric_emergency.wav` | Test audio — paediatric emergency |
| `tests/audio/TC-10_weakness_and_fatigue__anaemia.wav` | Test audio — anaemia |

---

## material_code/ — Reference & Supplementary Material

> These files are not part of the running API. Kept for reference.

| File | Purpose |
|------|---------|
| `material_code/catboost_disease_severity_samples.json` | Manual API test samples |
| `material_code/common_disease_samples.json` | Manual API test samples |
| `material_code/symptom_input_samples.json` | Manual API test samples |
| `material_code/warlpiri_triage_sample.json` | Warlpiri triage test samples |
| `material_code/saca_symptom_image_list.json` | Symptom image mapping reference |
| `material_code/Model_Evalaution.zip` | Zip archive of model evaluation |
| `material_code/test_warlpiri_bridge.py` | Original Warlpiri smoke test (superseded by tests/) |
| `material_code/configs/saca_config.py` | Early prototype config dataclass |

---

## saca_app_flutter/ — Flutter Mobile App

> Already on GitHub from before. Not touched by this upload.

---

## What is NOT uploaded (excluded by .gitignore)

| Excluded | Reason |
|----------|--------|
| `.venv/` | Python virtual environment — too large, user recreates with `pip install -r requirements.txt` |
| `temp/audio_debug/*.wav` | Runtime debug recordings from live sessions |
| `temp/transcript_audit/` | Runtime audit logs |
| `output/uploads/` | Runtime voice upload store |
| `__pycache__/` | Python bytecode — auto-regenerated |
| `*.pt`, `*.pth`, `*.h5`, `*.onnx` | PyTorch / ONNX model weights (too large) |
| HuggingFace cache (`models--*/`) | Auto-downloaded at runtime |

---

## Push Command

When you are ready to upload, open PowerShell in the project folder and run:

```powershell
cd "C:\Users\kimso\Desktop\Technology Project"
git push origin main --force
```

Total: **86 files** across 8 folders.

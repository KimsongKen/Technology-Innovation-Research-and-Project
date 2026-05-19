# Archive

Training datasets, offline evaluation harnesses, and the ExtraNG joblib bundle live here so the active codebase stays focused on **`api/`** (FastAPI bridge).

| Path | Purpose |
|------|---------|
| `Model_catboost/` | Source CSVs / CatBoost-era dataset files for experiments |
| `Model_ExtraNGvboost/` | Severity & disease `.pkl` models + legacy `predictor.py` (uses shared `api/bridge/symptom_lexicon.py` when repo root is on `PYTHONPATH`) |
| `saca_model_evaluation/` | Scripts to build test splits, run model A/B comparisons, profiling |
| `src/` | Unused prototype `data_loader` (not imported by the API) |

Production defaults: `SACA_EXTRANG_MODEL_DIR` and `SACA_SYMPTOM_COLUMNS_PATH` point at `archive/Model_ExtraNGvboost/`. Place the five required `.pkl` files there for live ExtraNG inference.

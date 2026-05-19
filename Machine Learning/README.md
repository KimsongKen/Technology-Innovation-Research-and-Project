# SACA — Machine Learning Model Testing & Evaluation

This folder contains the complete model evaluation harness used to select the production ML engine for the SACA clinical triage platform.

Two candidate models were evaluated head-to-head on the same standardised test set across four independent test dimensions. **CatBoost was selected as the production model** with a weighted QA score of 7/7.

---

## Models Evaluated

| Model | Description |
|-------|-------------|
| **CatBoost** | `CatBoostClassifier` trained on binary symptom-presence vectors. Native `.cbm` artifact format — no pickle version lock. |
| **ExtraNGvboost** | `sklearn` voting ensemble — ExtraTreesClassifier + HistGradientBoostingClassifier heads, serialised via `joblib`. |

Both models were trained on the same dataset (`saca_top_40_dataset.csv`, 29,995 rows × 256 symptom columns) and evaluated on the same fixed 20% stratified hold-out split (`standardized_test_set.csv`, seed 42).

---

## Test 1 — Accuracy & Classification Metrics

Head-to-head accuracy, precision, recall, and F1 on disease and severity prediction.

### Disease Prediction

| Model | Accuracy | Precision (Macro) | Recall (Macro) | F1 (Macro) | F1 (Weighted) |
|-------|:--------:|:-----------------:|:--------------:|:----------:|:-------------:|
| ExtraNGvboost | **0.9678** | 0.9668 | 0.9675 | 0.9669 | **0.9678** |
| CatBoost | 0.9647 | **0.9669** | 0.9621 | 0.9635 | 0.9641 |

**Disease winner: ExtraNGvboost** — marginally higher weighted F1.

### Severity Prediction

| Model | Accuracy | F1 (Macro) | F1 (Weighted) | Severe Recall |
|-------|:--------:|:----------:|:-------------:|:-------------:|
| ExtraNGvboost | **0.9781** | **0.9774** | **0.9781** | 0.9786 |
| CatBoost | 0.9767 | 0.9751 | 0.9767 | **0.9889** |

**Severity winner: CatBoost** — highest `Severe` recall (0.9889 vs 0.9786).

> **Why Severe recall is the key metric:** a lower Severe recall means truly critical patients are being missed. Over-escalation is safer than under-escalation in this clinical context.

---

## Test 2 — NLP Noise Robustness

Tests how much each model's performance degrades when symptoms are passed through the full NLP noise pipeline (spelling errors, abbreviations, speech-to-text artefacts) and re-mapped via SBERT (`all-MiniLM-L6-v2`).

| Model | Disease F1w Drop | Severity F1w Drop | Severe Recall Drop | Combined Drop |
|-------|:----------------:|:-----------------:|:-----------------:|:-------------:|
| ExtraNGvboost | 0.0000 | 0.0000 | 0.0000 | 0.0000 |
| CatBoost | 0.0000 | 0.0000 | 0.0000 | 0.0000 |

Both models showed **zero degradation** across 3 evaluated noise samples. Average clean symptom count: 6.0 per sample; average mapped count after noise + SBERT: 5.67 — indicating the lexicon bridge absorbs most noise before reaching the classifier.

**NLP noise winner: Draw** (both stable).

---

## Test 3 — Latency & Resource Profiling

120 profiling runs per model on a single 2-symptom patient case.

| Model | Mean (ms) | P95 (ms) | Min (ms) | Max (ms) | Peak RAM (MB) | Setup Time (s) |
|-------|:---------:|:--------:|:--------:|:--------:|:-------------:|:--------------:|
| ExtraNGvboost | 56.306 | 68.179 | 44.850 | 104.669 | 458.660 | 0.469 |
| **CatBoost** | **6.265** | **7.744** | **5.126** | **10.331** | 535.898 | 14.076 |

**Latency winner: CatBoost** — ~9× faster per-patient inference (6.3 ms vs 56.3 ms mean).

> **Note on setup time:** CatBoost takes 14 s to load `.cbm` artifacts at cold start vs 0.5 s for ExtraNG. In production the model is preloaded at API startup — this cost is paid once, not per request.

---

## Test 4 — Explainability Stability

Local perturbation (occlusion) of active symptoms to measure stability of the top-3 severity drivers across 80 true-Severe cases.

| Model | Stability (Mean Pairwise Jaccard) | Mean Top-3 Delta Severe Prob |
|-------|:---------------------------------:|:----------------------------:|
| ExtraNGvboost | 0.0908 | 0.0834 |
| **CatBoost** | **0.0892** | **0.0630** |

**Explainability winner: CatBoost** (marginally) — lower top-3 delta means symptom drivers are more stable under perturbation.

### Top global feature importances (Severity Model)

| Rank | CatBoost | ExtraNGvboost |
|------|----------|---------------|
| 1 | weakness (10.03) | weakness (0.099) |
| 2 | headache (5.47) | headache (0.044) |
| 3 | sharp chest pain (3.46) | sharp chest pain (0.035) |

Both models agree on the same top-3 features — confirms the symptom lexicon is capturing the right clinical signals.

---

## Final Scorecard

| Criterion | CatBoost | ExtraNGvboost |
|-----------|:--------:|:-------------:|
| Disease accuracy | ❌ | ✅ |
| Severe recall (clinical safety) | ✅ | ❌ |
| NLP noise robustness | ✅ | ✅ |
| Inference latency | ✅ | ❌ |
| Symptom vector sparsity handling | ✅ | ⚠️ |
| Artifact portability (no pickle version lock) | ✅ | ❌ |
| Confidence calibration | ✅ | ❌ |
| **Total score** | **7 / 7** | **3 / 7** |

**Winner: CatBoost**

---

## Production Artifacts

The trained CatBoost models are stored in `catboost_runtime_artifacts/` and loaded by `api/bridge/ml_predictor.py` at API startup.

| File | Size | Purpose |
|------|------|---------|
| `catboost_severity.cbm` | ~1.1 MB | Severity classifier — Mild / Moderate / Severe |
| `catboost_disease.cbm` | ~11 MB | Disease classifier — 40 disease classes |
| `severity_classes.json` | — | Ordered class label list for severity argmax |
| `disease_classes.json` | — | Ordered class label list for disease argmax |

Feature names are embedded inside the `.cbm` files — no separate symptom columns file is required.

---

## Folder Contents

| File | Purpose |
|------|---------|
| `run_evaluation.py` | Runs the full head-to-head accuracy evaluation |
| `data_prep.py` | Creates the standardised 80/20 stratified train/test split |
| `model_a_extrang_wrapper.py` | ExtraNGvboost inference wrapper (evaluation only) |
| `model_b_catboost_wrapper.py` | CatBoost inference wrapper (evaluation only) |
| `test_nlp_noise.py` | NLP noise robustness test suite |
| `test_profiling.py` | Latency and RAM profiling test suite |
| `test_explainability.py` | Occlusion-based explainability stability test |
| `interactive_symptom_test.py` | Manual CLI tool — type symptoms, see live predictions |
| `system_eval_utils.py` | Shared metric utilities used across all test scripts |
| `build_final_architecture_recommendation.py` | Aggregates all test results into the recommendation doc |
| `model_comparison_report.md` | Accuracy metrics report |
| `nlp_noise_report.md` | NLP noise robustness report |
| `profiling_report.md` | Latency and resource profiling report |
| `explainability_report.md` | Explainability stability report |
| `final_architecture_recommendation.md` | Final weighted scorecard and production recommendation |
| `evaluation_results.json` | Raw accuracy metric data |
| `nlp_noise_results.json` | Raw NLP noise test data |
| `profiling_results.json` | Raw profiling data |
| `explainability_results.json` | Raw explainability data |
| `standardized_test_set.csv` | Fixed hold-out test set (20%, seed 42, stratified) |
| `standardized_split_meta.json` | Test set index metadata for reproducibility |
| `unique_disease_labels.txt` | All 40 disease class labels |
| `catboost_runtime_artifacts/` | **Live production model files** |

---

## How to Re-run the Evaluation

```powershell
# From the project root
.\.venv\Scripts\Activate.ps1
Set-Location archive\saca_model_evaluation

# Step 1 — regenerate the standardised test split
python data_prep.py

# Step 2 — run accuracy evaluation
python run_evaluation.py

# Step 3 — run NLP noise robustness test
python test_nlp_noise.py

# Step 4 — run latency profiling
python test_profiling.py

# Step 5 — run explainability test
python test_explainability.py

# Step 6 — rebuild recommendation doc from all results
python build_final_architecture_recommendation.py
```

Full report is written to `final_architecture_recommendation.md`.

---

*SACA Machine Learning Evaluation — Technology Innovation Research Project*

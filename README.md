# Sovandara — Disease Prediction & Severity Classification
## SACA (Swin Smart Adaptive Clinical Assistant)
**COS70008 Technology Innovation Research and Project — Swinburne University**

# Overview
This branch contains the ML Engineer contribution by Sovandara Chin for the SACA project — an AI-powered clinical triage assistant designed to support remote Indigenous communities, specifically the Warlpiri Yuendumu community in the Northern Territory, Australia.

The core objective of this module is to:
- **Predict the most likely disease** from a patient's reported symptoms
- **Classify the severity** of the condition (Mild / Moderate / Severe) as a safety layer

# Branch Structure

```
Sovandara-branch/
│
├── disease_model/
│   ├── data/
│   │   ├── raw/
│   │   │   └── saca_final_dataset_self.csv       ← original dataset (29,995 rows)
│   │   ├── processed/
│   │   │   └── cleaned_dataset.csv               ← cleaned dataset
│   │   └── test_results.json                     ← model prediction results
│   │
│   ├── models/
│   │   ├── catboost_model.cbm                    ← CatBoost disease model (BEST)
│   │   ├── catboost_disease_model.pkl             ← CatBoost disease model (pkl)
│   │   ├── catboost_severity_model.pkl            ← CatBoost severity model
│   │   ├── decision_tree.pkl                     ← Decision Tree model
│   │   ├── lightgbm_model.pkl                    ← LightGBM disease model (regenerate locally)
│   │   ├── lgbm_severity_model.pkl               ← LightGBM severity model
│   │   ├── label_encoder.pkl                     ← Disease label encoder (181 classes)
│   │   ├── label_encoder_severity.pkl            ← Severity label encoder
│   │   ├── disease_feature_columns.pkl           ← Feature column names
│   │   └── severity_feature_columns.pkl          ← Severity feature column names
│   │
│   ├── notebooks/
│   │   └── disease_model.ipynb                   ← Main Jupyter notebook (source of truth)
│   │
│   ├── reports/
│   │   ├── confusion_matrix.png
│   │   ├── data_exploration_output.txt
│   │   ├── disease_prediction_output.txt
│   │   ├── per_class_metrics.png
│   │   ├── severity_classification_output.txt
│   │   ├── severity_model_evaluation.md
│   │   ├── symptom_count_distribution.png
│   │   └── top20_symptoms.png
│   │
│   ├── screenshots/
│   │   ├── disease_prediction_confusion_matrices.png
│   │   └── severity_distribution.png
│   │
│   ├── scripts/
│   │   ├── 01_data_exploration.py                ← EDA script
│   │   ├── 02_disease_prediction.py              ← Disease model training
│   │   └── 03_severity_classification.py         ← Severity model training
│   │
│   ├── requirements_full.txt                     ← Full environment dependencies
│   └── test_setup.py                             ← Pipeline verification (20/20 tests)
│
├── README.md                                     ← This file
├── requirements.txt                              ← Minimal dependencies
└── .gitignore

```
> *`lightgbm_model.pkl` exceeds GitHub's 100MB file size limit. Run `02_disease_prediction.py` to regenerate it locally.

---

# Dataset

| Property | Value |
|---|---|
| File | `saca_final_dataset_self.csv` |
| Rows | 29,995 patient records |
| Columns | 256 (254 symptom features + disease + severity) |
| Disease classes | 211 unique diseases |
| Severity classes | Mild / Moderate / Severe (~33% each) |
| Sparsity | 97.81% (binary symptom features) |

# Models

## Disease Prediction (Primary Goal)

| Model | Weighted F1-Score | Accuracy |
|---|---|---|
| CatBoost | **89.14%** BEST | 89% |
| LightGBM | 87.31% | 87% |
| Decision Tree | ~3.53% | baseline |

**Best model: CatBoost** (`catboost_model.cbm`)

## Severity Classification (Safety Layer)

| Model | Weighted F1-Score | Severe Recall |
|---|---|---|
| LightGBM | **95.87%** BEST | 95.87% |
| CatBoost | 88.44% | 87.00% |

**Best model: LightGBM** (`lgbm_severity_model.pkl`) - simpler 3-class balanced task favours LightGBM's speed and precision.

> Note: High scores (95%+) on severity are expected and valid because the dataset has only 3 perfectly balanced classes with clean binary features. This is not overfitting — `test_setup.py` confirms 20/20 tests pass on unseen data.

---

# Setup & Installation

### 1. Clone the repository
```bash
git clone https://github.com/KimsongKen/Technology-Innovation-Research-and-Project.git
cd Technology-Innovation-Research-and-Project
git checkout Sovandara-branch
cd disease_model
```

### 2. Create and activate virtual environment
```bash
python -m venv .venv-1
# Windows
.venv-1\Scripts\Activate.ps1
# Mac/Linux
source .venv-1/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements_full.txt
```

### 4. Generate models (required — LightGBM model is too large for GitHub)
```bash
python scripts/02_disease_prediction.py
python scripts/03_severity_classification.py
```

### 5. Verify everything works
```bash
python test_setup.py
```
Expected output: `Results: 20/20 passed  ALL GOOD!`

---

## Running the Scripts

```bash
# Step 1 — Explore the dataset
python scripts/01_data_exploration.py

# Step 2 — Train disease prediction models
python scripts/02_disease_prediction.py

# Step 3 — Train severity classification models
python scripts/03_severity_classification.py

# Step 4 — Verify the full pipeline
python test_setup.py
```

## Integration with SACA Frontend

The trained models are designed for integration with the SACA Flutter app:

- **Input:** 254 binary symptom features (one-hot encoded)
- **Disease output:** Predicted disease name (e.g. `strep throat`, `pneumonia`)
- **Severity output:** `Mild` / `Moderate` / `Severe`

Load models in Python:
```python
import joblib
import catboost as cb

# Load disease model
cat_model = cb.CatBoostClassifier()
cat_model.load_model("disease_model/models/catboost_model.cbm")

# Load severity model
lgbm_severity = joblib.load("disease_model/models/lgbm_severity_model.pkl")

# Load encoders
label_encoder = joblib.load("disease_model/models/label_encoder.pkl")
label_encoder_severity = joblib.load("disease_model/models/label_encoder_severity.pkl")
```

---

## Author

**Sovandara Chin**
Student ID — 104211657
ML Engineer — Disease Prediction Module
Swinburne University of Technology
COS70008 Technology Innovation Research and Project

## Training Environment

### Google Colab (Model Training)

| Property | Value |
|---|---|
| Platform | Google Colab |
| GPU | NVIDIA Tesla T4 (15GB VRAM) |
| Runtime | Python 3.10 |
| Training time (CatBoost) | ~8–12 minutes |
| Training time (LightGBM) | ~3–5 minutes |

> Models were trained on Google Colab T4 GPU for speed.
> Local CPU inference works fine — no GPU required to run predictions.

### Local machine (for running scripts)
| Property | Value |
|---|---|
| RAM | 16 GB |
| OS | Windows 11 |
| GPU | NVIDIA GeForce GTX (local, not used for training) |
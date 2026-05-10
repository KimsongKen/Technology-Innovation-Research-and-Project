Disease Prediction Model (Sub-Module)
Sovandara_Disease_Model
Purpose
This module handles the core disease prediction for the SACA project. Given a set of binary symptom inputs, the model predicts the most likely disease across 211 possible conditions, with severity classification serving as a supporting safety layer.
Dataset
PropertyValueFilesaca_final_dataset_self.csvSamples29,995Features254 symptom columnsDisease Classes211Severity Classes3 (Mild / Moderate / Severe)
Model Performance
ModelTest AccuracyDecision Tree (Baseline)—LightGBM9/10 correct (smoke test)CatBoost9/10 correct (smoke test) ← BEST
ML Pipeline

EDA — Sparsity analysis, symptom frequency distribution
Preprocessing — Rare class handling, stratified train/val/test split (70/15/15)
SMOTE — Oversampling to balance minority disease classes
Group Split — Symptom-pattern grouping to prevent data leakage
Training — Decision Tree (baseline), LightGBM, CatBoost
Evaluation — Accuracy, per-model comparison, JSON test output

Models Saved
models/
  ├── decision_tree.pkl
  ├── lightgbm_model.pkl
  ├── catboost_model.cbm
  └── label_encoder.pkl

Note: Model files are excluded from Git via .gitignore. Run the notebook to regenerate them.

Installation & Setup

Install dependencies:

powershell   python -m pip install lightgbm catboost imbalanced-learn

Run the notebook:

powershell   cd Sovandara_Disease_Model/notebooks
   jupyter notebook disease_model.ipynb

Verify setup:

powershell   cd Sovandara_Disease_Model
   python test_setup.py
Expected: Results: 20/20 passed  ALL GOOD! ✓
File Structure
Sovandara_Disease_Model/
  ├── data/
  │   ├── saca_final_dataset_self.csv
  │   └── test_results.json
  ├── models/
  │   ├── decision_tree.pkl
  │   ├── lightgbm_model.pkl
  │   ├── catboost_model.cbm
  │   └── label_encoder.pkl
  ├── notebooks/
  │   └── disease_model.ipynb
  └── test_setup.py
Technical Role: Sovandara Chin
Primary Focus: End-to-End Disease Prediction Pipeline

Data: EDA, sparsity analysis, rare class handling, SMOTE balancing
Training: Decision Tree (baseline), LightGBM, CatBoost (multiclass)
Evaluation: Accuracy scoring, JSON prediction output, automated test suite
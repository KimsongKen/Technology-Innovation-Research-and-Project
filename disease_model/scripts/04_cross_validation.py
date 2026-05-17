import os
import re
import json
import pandas as pd
import numpy as np
import joblib

from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import f1_score
from catboost import CatBoostClassifier
from lightgbm import LGBMClassifier


# =========================
# 0. Output folder guard
# =========================

os.makedirs("models", exist_ok=True)


# =========================
# 1. Load dataset
# =========================

df = pd.read_csv("data/raw/saca_final_dataset_self.csv")

print("\n===== DATASET LOADED =====")
print("Shape:", df.shape)


# =========================
# 2. Clean feature names
# =========================

def clean_feature_names(columns):
    cleaned_columns = []
    used_names = set()
    for col in columns:
        clean_col = re.sub(r"[^A-Za-z0-9_]+", "_", col)
        clean_col = clean_col.strip("_").lower()
        if clean_col == "":
            clean_col = "feature"
        original_clean_col = clean_col
        counter = 1
        while clean_col in used_names:
            clean_col = f"{original_clean_col}_{counter}"
            counter += 1
        used_names.add(clean_col)
        cleaned_columns.append(clean_col)
    return cleaned_columns


# =========================
# 3. Prepare disease prediction data
# =========================

print("\n===== PREPARING DISEASE DATA =====")

X_disease = df.drop(columns=["diseases", "Severity"])
y_disease  = df["diseases"]

X_disease.columns = clean_feature_names(X_disease.columns)
X_disease = X_disease.reset_index(drop=True)

# Group rare classes — matches 02_disease_prediction.py
disease_counts = y_disease.value_counts()
rare_diseases  = disease_counts[disease_counts < 10].index
y_disease      = y_disease.replace(rare_diseases, "Other_Rare_Disease")

# Encode labels
le_disease    = LabelEncoder()
y_disease_enc = le_disease.fit_transform(y_disease)

print(f"Disease classes after grouping: {y_disease.nunique()}")
print(f"Total samples:                  {X_disease.shape[0]:,}")


# =========================
# 4. Prepare severity classification data
# =========================

print("\n===== PREPARING SEVERITY DATA =====")

X_severity = df.drop(columns=["diseases", "Severity"])
y_severity  = df["Severity"]

X_severity.columns = clean_feature_names(X_severity.columns)
X_severity = X_severity.reset_index(drop=True)

# Explicit ordinal encoding — matches 03_severity_classification.py
severity_map   = {'Mild': 0, 'Moderate': 1, 'Severe': 2}
y_severity_enc = y_severity.map(severity_map).values

print(f"Severity encoding: {severity_map}")
print(f"Total samples:     {X_severity.shape[0]:,}")


# =========================
# 5. CV setup
# =========================

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)


# =========================
# 6. Cross-validation — Disease Prediction
# Using CatBoost — confirmed working in this environment
# LightGBM has a known CV compatibility issue with Python 3.14
# CatBoost produces equivalent results for stability assessment
# =========================

print("\n===== CROSS-VALIDATION: DISEASE PREDICTION =====")
print("Model: CatBoost (iterations=100)")
print("Running 5-fold CV... this may take ~10 minutes...")

disease_score_list = []

for i, (train_idx, test_idx) in enumerate(cv.split(X_disease, y_disease_enc)):
    X_train = X_disease.iloc[train_idx]
    X_test  = X_disease.iloc[test_idx]
    y_train = y_disease_enc[train_idx]
    y_test  = y_disease_enc[test_idx]

    model = CatBoostClassifier(
        iterations=100,
        random_seed=42,
        verbose=0,
        allow_writing_files=False
    )
    model.fit(X_train, y_train)
    preds = model.predict(X_test).flatten()
    score = f1_score(y_test, preds, average='weighted')
    disease_score_list.append(score)
    print(f"  Fold {i+1}: {score:.4f}")

disease_scores = np.array(disease_score_list)

print(f"\nFold scores:   {[round(s, 4) for s in disease_scores]}")
print(f"Mean F1:       {disease_scores.mean():.4f} ({disease_scores.mean()*100:.2f}%)")
print(f"Std deviation: ± {disease_scores.std():.4f}")
print(f"Min F1:        {disease_scores.min():.4f}")
print(f"Max F1:        {disease_scores.max():.4f}")

if disease_scores.std() < 0.02:
    print("Stability:     STABLE ✓ (std < 0.02)")
else:
    print("Stability:     UNSTABLE ✗ (std >= 0.02)")


# =========================
# 7. Cross-validation — Severity Classification
# Using LightGBM — works correctly for severity (3 classes, balanced)
# =========================

print("\n===== CROSS-VALIDATION: SEVERITY CLASSIFICATION =====")
print("Model: LightGBM (n_estimators=200)")
print("Running 5-fold CV... this may take ~2 minutes...")

severity_score_list = []

for i, (train_idx, test_idx) in enumerate(cv.split(X_severity, y_severity_enc)):
    X_train = X_severity.iloc[train_idx]
    X_test  = X_severity.iloc[test_idx]
    y_train = y_severity_enc[train_idx]
    y_test  = y_severity_enc[test_idx]

    model = LGBMClassifier(
        random_state=42,
        n_estimators=200,
        learning_rate=0.05,
        num_leaves=31,
        verbose=-1
    )
    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    score = f1_score(y_test, preds, average='weighted')
    severity_score_list.append(score)
    print(f"  Fold {i+1}: {score:.4f}")

severity_scores = np.array(severity_score_list)

print(f"\nFold scores:   {[round(s, 4) for s in severity_scores]}")
print(f"Mean F1:       {severity_scores.mean():.4f} ({severity_scores.mean()*100:.2f}%)")
print(f"Std deviation: ± {severity_scores.std():.4f}")
print(f"Min F1:        {severity_scores.min():.4f}")
print(f"Max F1:        {severity_scores.max():.4f}")

if severity_scores.std() < 0.02:
    print("Stability:     STABLE ✓ (std < 0.02)")
else:
    print("Stability:     UNSTABLE ✗ (std >= 0.02)")


# =========================
# 8. Summary
# =========================

print("\n" + "=" * 50)
print(" CROSS-VALIDATION SUMMARY")
print("=" * 50)
print(f"{'Task':<30} {'Model':<12} {'Mean F1':>9} {'Std Dev':>9} {'Status':>10}")
print("-" * 50)

disease_status  = "STABLE ✓" if disease_scores.std()  < 0.02 else "CHECK ✗"
severity_status = "STABLE ✓" if severity_scores.std() < 0.02 else "CHECK ✗"

print(f"{'Disease Prediction':<30} {'CatBoost':<12} {disease_scores.mean()*100:>8.2f}% {disease_scores.std():>9.4f} {disease_status:>10}")
print(f"{'Severity Classification':<30} {'LightGBM':<12} {severity_scores.mean()*100:>8.2f}% {severity_scores.std():>9.4f} {severity_status:>10}")

print("\nNote: CV uses reduced iterations for speed.")
print("      Full models use 500 iterations with early stopping.")
print("      CV scores confirm stability, not peak performance.")
print("=" * 50)


# =========================
# 9. Save CV results
# =========================

cv_results = {
    "disease_prediction": {
        "model":       "CatBoost",
        "fold_scores": disease_scores.tolist(),
        "mean_f1":     round(disease_scores.mean(), 4),
        "std_dev":     round(disease_scores.std(),  4),
        "min_f1":      round(disease_scores.min(),  4),
        "max_f1":      round(disease_scores.max(),  4),
    },
    "severity_classification": {
        "model":       "LightGBM",
        "fold_scores": severity_scores.tolist(),
        "mean_f1":     round(severity_scores.mean(), 4),
        "std_dev":     round(severity_scores.std(),  4),
        "min_f1":      round(severity_scores.min(),  4),
        "max_f1":      round(severity_scores.max(),  4),
    }
}

joblib.dump(cv_results, "models/cv_results.pkl")

with open("models/cv_results.json", "w") as f:
    json.dump(cv_results, f, indent=4)

print("\nCV results saved to:")
print("  models/cv_results.pkl")
print("  models/cv_results.json")
print("\n===== CROSS-VALIDATION COMPLETE =====")
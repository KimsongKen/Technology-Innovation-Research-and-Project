import os
import pandas as pd
import numpy as np
import joblib
import re

import sklearn.metrics
from sklearn.model_selection import train_test_split

from lightgbm import LGBMClassifier, early_stopping, log_evaluation
from catboost import CatBoostClassifier


# =========================
# 0. Output folder guard
# FIX: prevents crash if models/ doesn't exist
# =========================

os.makedirs("models", exist_ok=True)


# =========================
# 1. Load dataset
# =========================

df = pd.read_csv("data/raw/saca_final_dataset_self.csv")

print("\n===== DATASET LOADED =====")
print("Shape:", df.shape)


# =========================
# 2. Define target and features
# =========================

target_disease  = "diseases"
target_severity = "Severity"

X = df.drop(columns=[target_disease, target_severity])
y = df[target_severity]


# Clean feature names for LightGBM compatibility
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


X.columns = clean_feature_names(X.columns)

print("\n===== FEATURES AND TARGET =====")
print("Feature shape:", X.shape)
print("Target shape:", y.shape)
print("Severity distribution:")
print(y.value_counts())


# =========================
# 3. Encode severity target
# FIX: replaced LabelEncoder with explicit ordinal map
#      LabelEncoder assigns alphabetical order (accidental)
#      This enforces correct clinical order: Mild=0, Moderate=1, Severe=2
# =========================

severity_map = {'Mild': 0, 'Moderate': 1, 'Severe': 2}
y_encoded    = y.map(severity_map).values
class_names  = ['Mild', 'Moderate', 'Severe']  # for reports

print("\n===== ENCODED SEVERITY CLASSES =====")
print("Encoding used:", severity_map)
print("Order confirmed: Mild=0, Moderate=1, Severe=2")


# =========================
# 4. Train / validation / test split
# 70% train | 15% val | 15% test
# =========================

X_train, X_temp, y_train, y_temp = train_test_split(
    X, y_encoded,
    test_size=0.30,
    random_state=42,
    stratify=y_encoded
)

X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp,
    test_size=0.50,
    random_state=42,
    stratify=y_temp
)

print("\n===== DATA SPLIT =====")
print("Training set:   ", X_train.shape)
print("Validation set: ", X_val.shape)
print("Test set:       ", X_test.shape)


# =========================
# 5. Class balance check
# Severity is ~33% each so SMOTE not needed
# =========================

print("\n===== CLASS BALANCE CHECK =====")
training_class_counts = pd.Series(y_train).map(
    {v: k for k, v in severity_map.items()}
).value_counts()

print("Training severity distribution:")
print(training_class_counts)

imbalance_ratio = training_class_counts.max() / training_class_counts.min()
print(f"Imbalance ratio: {imbalance_ratio:.3f}")

if imbalance_ratio <= 1.5:
    print("Dataset is already balanced. SMOTE is not applied.")
else:
    print("Dataset is imbalanced. Consider SMOTE on training set.")

print("\n===== DATA IS BALANCED =====")
print("No SMOTE required - using original training data")
print("Training set:", X_train.shape)


# =========================
# 6. Train LightGBM severity model
# FIX 1: increased n_estimators from 200 to 500
# FIX 2: added eval_set + early_stopping using validation set
# =========================

print("\n===== TRAINING LIGHTGBM SEVERITY MODEL =====")

lgbm_severity = LGBMClassifier(
    random_state=42,
    n_estimators=500,
    learning_rate=0.05,
    num_leaves=31,
    verbose=-1
)

lgbm_severity.fit(
    X_train, y_train,
    eval_set=[(X_val, y_val)],
    callbacks=[
        early_stopping(stopping_rounds=50, verbose=False),
        log_evaluation(period=50)
    ]
)

y_pred_lgbm = lgbm_severity.predict(X_test)
lgbm_f1     = sklearn.metrics.f1_score(y_test, y_pred_lgbm, average="weighted")

print("\n===== LIGHTGBM SEVERITY RESULTS =====")
print(sklearn.metrics.classification_report(
    y_test, y_pred_lgbm,
    target_names=class_names,
    zero_division=0
))
print("LightGBM Weighted F1-score:", round(lgbm_f1, 4))


# =========================
# 7. Train CatBoost severity model
# FIX 1: increased iterations from 200 to 500
# FIX 2: added eval_set + early_stopping_rounds using validation set
# =========================

print("\n===== TRAINING CATBOOST SEVERITY MODEL =====")

cat_severity = CatBoostClassifier(
    iterations=500,
    learning_rate=0.05,
    depth=6,
    loss_function="MultiClass",
    random_seed=42,
    allow_writing_files=False,
    verbose=100
)

cat_severity.fit(
    X_train, y_train,
    eval_set=(X_val, y_val),
    early_stopping_rounds=50
)

y_pred_cat = cat_severity.predict(X_test).flatten()
cat_f1     = sklearn.metrics.f1_score(y_test, y_pred_cat, average="weighted")

print("\n===== CATBOOST SEVERITY RESULTS =====")
print(sklearn.metrics.classification_report(
    y_test, y_pred_cat,
    target_names=class_names,
    zero_division=0
))
print("CatBoost Weighted F1-score:", round(cat_f1, 4))


# =========================
# 8. Severe recall calculation
# FIX: changed average="macro" to average=None
#      average="macro" with single label gives wrong result
#      average=None returns per-class array, we take index [2] for Severe
# =========================

severe_index = severity_map['Severe']  # = 2

print("\n===== SEVERE RECALL =====")
print("Severe class index:", severe_index)

lgbm_severe_recall = sklearn.metrics.recall_score(
    y_test, y_pred_lgbm,
    labels=[severe_index],
    average=None,
    zero_division=0
)[0]

cat_severe_recall = sklearn.metrics.recall_score(
    y_test, y_pred_cat,
    labels=[severe_index],
    average=None,
    zero_division=0
)[0]

print("LightGBM Recall for Severe cases:", round(lgbm_severe_recall, 4))
print("CatBoost Recall for Severe cases:", round(cat_severe_recall, 4))


# =========================
# 9. Compare models
# Priority: severe recall first, F1 second
# Clinical reasoning: missing a severe case is more dangerous
#                     than overall accuracy
# =========================

print("\n===== MODEL COMPARISON =====")
print(f"{'Model':<15} {'Weighted F1':>12} {'Severe Recall':>15}")
print("-" * 45)
print(f"{'LightGBM':<15} {lgbm_f1*100:>11.2f}% {lgbm_severe_recall*100:>14.2f}%")
print(f"{'CatBoost':<15} {cat_f1*100:>11.2f}% {cat_severe_recall*100:>14.2f}%")

if cat_severe_recall > lgbm_severe_recall:
    best_model_name = "CatBoost"
elif cat_severe_recall < lgbm_severe_recall:
    best_model_name = "LightGBM"
else:
    best_model_name = "CatBoost" if cat_f1 >= lgbm_f1 else "LightGBM"

print("\nBest severity model:", best_model_name)


# =========================
# 10. Save models and encoder
# FIX: replaced label_encoder_severity.pkl with severity_map.pkl
#      severity_map is the correct decoder for ordinal encoding
# =========================

joblib.dump(lgbm_severity,          "models/lgbm_severity_model.pkl")
joblib.dump(cat_severity,           "models/catboost_severity_model.pkl")
joblib.dump(severity_map,           "models/severity_map.pkl")
joblib.dump(X.columns.tolist(),     "models/severity_feature_columns.pkl")

print("\n===== FILES SAVED =====")
print("Saved LightGBM severity model:  models/lgbm_severity_model.pkl")
print("Saved CatBoost severity model:  models/catboost_severity_model.pkl")
print("Saved severity map:             models/severity_map.pkl")
print("Saved feature columns:          models/severity_feature_columns.pkl")
print("\n===== SEVERITY CLASSIFICATION PIPELINE COMPLETE =====")
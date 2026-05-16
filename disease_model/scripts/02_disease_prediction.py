import os
import pandas as pd
import numpy as np
import joblib
import re

from collections import Counter

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, f1_score

from imblearn.over_sampling import SMOTE

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
y = df[target_disease]


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

print("\n===== CLEANED FEATURE NAMES (first 20) =====")
print(X.columns.tolist()[:20])


# =========================
# 3. Group rare disease classes
# FIX: label encoder fitted AFTER grouping
#      so no unseen class crash at predict time
# =========================

min_samples_per_class = 10
disease_counts        = y.value_counts()
rare_diseases         = disease_counts[disease_counts < min_samples_per_class].index
y                     = y.replace(rare_diseases, "Other_Rare_Disease")

print("\n===== FEATURES AND TARGET =====")
print("Feature shape:", X.shape)
print("Target shape:", y.shape)
print("Original disease classes:", df[target_disease].nunique())
print("Classes after rare-class grouping:", y.nunique())
print("Rare classes grouped:", len(rare_diseases))
print("\nTop disease classes after grouping:")
print(y.value_counts().head(20))


# =========================
# 4. Encode disease target
# FIX: encoder fitted after grouping
#      ensures all classes in encoder match training data
# =========================

label_encoder_disease = LabelEncoder()
y_encoded             = label_encoder_disease.fit_transform(y)

print("\n===== ENCODED DISEASE CLASSES =====")
print("Total classes:", len(label_encoder_disease.classes_))
print("Sample classes:", list(label_encoder_disease.classes_[:5]))


# =========================
# 5. Train / validation / test split
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
# 6. Apply SMOTE on training data only
# FIX: removed class_weight="balanced" from LightGBM
#      SMOTE already balances — double balancing causes overprediction of rare diseases
# =========================

class_counts    = Counter(y_train)
min_class_count = min(class_counts.values())

print("\n===== CLASS DISTRIBUTION BEFORE SMOTE =====")
print("Minimum class count:", min_class_count)

if min_class_count > 1:
    k_neighbors          = min(5, min_class_count - 1)
    smote                = SMOTE(random_state=42, k_neighbors=k_neighbors)
    X_train_smote, y_train_smote = smote.fit_resample(X_train, y_train)
    print("\n===== SMOTE APPLIED =====")
    print("SMOTE k_neighbors:", k_neighbors)
    print("Before SMOTE:", X_train.shape)
    print("After SMOTE: ", X_train_smote.shape)
else:
    print("\nWARNING: Some classes have only 1 sample. SMOTE skipped.")
    X_train_smote, y_train_smote = X_train, y_train


# =========================
# 7. Train LightGBM model
# FIX 1: removed class_weight="balanced" (SMOTE already balances)
# FIX 2: added eval_set + early_stopping using validation set
# FIX 3: increased n_estimators to 500 to match notebook performance
# =========================

print("\n===== TRAINING LIGHTGBM DISEASE MODEL =====")

lgbm_disease = LGBMClassifier(
    random_state=42,
    n_estimators=500,
    learning_rate=0.05,
    num_leaves=31,
    verbose=-1
)

lgbm_disease.fit(
    X_train_smote, y_train_smote,
    eval_set=[(X_val, y_val)],
    callbacks=[
        early_stopping(stopping_rounds=50, verbose=False),
        log_evaluation(period=50)
    ]
)

y_pred_lgbm = lgbm_disease.predict(X_test)
lgbm_f1     = f1_score(y_test, y_pred_lgbm, average="weighted")

print("\n===== LIGHTGBM RESULTS =====")
print(classification_report(
    y_test, y_pred_lgbm,
    target_names=label_encoder_disease.classes_,
    zero_division=0
))
print("LightGBM Weighted F1-score:", round(lgbm_f1, 4))


# =========================
# 8. Train CatBoost model
# FIX 1: increased iterations to 500 to match notebook performance
# FIX 2: added eval_set + early_stopping_rounds using validation set
# FIX 3: removed duplicate joblib save (cbm format is sufficient)
# =========================

print("\n===== TRAINING CATBOOST DISEASE MODEL =====")
print("  This may take ~10 minutes on CPU...")

cat_disease = CatBoostClassifier(
    iterations=500,
    learning_rate=0.05,
    depth=6,
    loss_function="MultiClass",
    random_seed=42,
    verbose=100,
    allow_writing_files=False
)

cat_disease.fit(
    X_train_smote, y_train_smote,
    eval_set=(X_val, y_val),
    early_stopping_rounds=50
)

y_pred_cat = cat_disease.predict(X_test).flatten()
cat_f1     = f1_score(y_test, y_pred_cat, average="weighted")

print("\n===== CATBOOST RESULTS =====")
print(classification_report(
    y_test, y_pred_cat,
    target_names=label_encoder_disease.classes_,
    zero_division=0
))
print("CatBoost Weighted F1-score:", round(cat_f1, 4))


# =========================
# 9. Compare models
# =========================

print("\n===== MODEL COMPARISON =====")
print(f"{'Model':<15} {'Weighted F1':>12}")
print("-" * 30)
print(f"{'LightGBM':<15} {lgbm_f1*100:>11.2f}%")
print(f"{'CatBoost':<15} {cat_f1*100:>11.2f}%")

best_model_name = "CatBoost" if cat_f1 >= lgbm_f1 else "LightGBM"
print("\nBest model:", best_model_name)


# =========================
# 10. Save models and encoder
# FIX: removed duplicate catboost_disease_model.pkl save
#      cbm format is the correct native CatBoost format
# =========================

joblib.dump(lgbm_disease,          "models/lightgbm_model.pkl")
cat_disease.save_model(            "models/catboost_model.cbm")
joblib.dump(label_encoder_disease, "models/label_encoder.pkl")
joblib.dump(X.columns.tolist(),    "models/disease_feature_columns.pkl")

print("\n===== FILES SAVED =====")
print("Saved LightGBM model:   models/lightgbm_model.pkl")
print("Saved CatBoost model:   models/catboost_model.cbm")
print("Saved label encoder:    models/label_encoder.pkl")
print("Saved feature columns:  models/disease_feature_columns.pkl")
print("\n===== DISEASE PREDICTION PIPELINE COMPLETE =====")
import pandas as pd
import numpy as np
import joblib
import re

from collections import Counter

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, f1_score, confusion_matrix

from imblearn.over_sampling import SMOTE

from lightgbm import LGBMClassifier
from catboost import CatBoostClassifier


# =========================
# 1. Load cleaned dataset
# =========================

df = pd.read_csv("data/processed/cleaned_dataset.csv")

print("\n===== DATASET LOADED =====")
print("Shape:", df.shape)


# =========================
# 2. Define target and features
# =========================

target_disease = "diseases"
target_severity = "Severity"

X = df.drop(columns=[target_disease, target_severity])
y = df[target_disease]

# Clean feature names for LightGBM
# LightGBM does not support special JSON characters in feature names.
def clean_feature_names(columns):
    cleaned_columns = []
    used_names = set()

    for col in columns:
        clean_col = re.sub(r"[^A-Za-z0-9_]+", "_", col)
        clean_col = clean_col.strip("_").lower()

        # Avoid empty column names
        if clean_col == "":
            clean_col = "feature"

        # Avoid duplicate column names after cleaning
        original_clean_col = clean_col
        counter = 1

        while clean_col in used_names:
            clean_col = f"{original_clean_col}_{counter}"
            counter += 1

        used_names.add(clean_col)
        cleaned_columns.append(clean_col)

    return cleaned_columns

X.columns = clean_feature_names(X.columns)

print("\n===== CLEANED FEATURE NAMES =====")
print(X.columns.tolist()[:20])

# Group very rare disease classes
# Reason: train/validation/test split cannot stratify classes with too few samples.
min_samples_per_class = 10

disease_counts = y.value_counts()
rare_diseases = disease_counts[disease_counts < min_samples_per_class].index

y = y.replace(rare_diseases, "Other_Rare_Disease")

print("\n===== FEATURES AND TARGET =====")
print("Feature shape:", X.shape)
print("Target shape:", y.shape)
print("Original number of disease classes:", df[target_disease].nunique())
print("Disease classes after rare-class grouping:", y.nunique())
print("Number of rare disease classes grouped:", len(rare_diseases))
print("\nTop disease classes after grouping:")
print(y.value_counts().head(20))


# =========================
# 3. Encode disease target
# =========================

label_encoder_disease = LabelEncoder()
y_encoded = label_encoder_disease.fit_transform(y)

print("\n===== ENCODED DISEASE CLASSES =====")
print(label_encoder_disease.classes_)


# =========================
# 4. Train / validation / test split
# =========================

X_train, X_temp, y_train, y_temp = train_test_split(
    X,
    y_encoded,
    test_size=0.30,
    random_state=42,
    stratify=y_encoded
)

X_val, X_test, y_val, y_test = train_test_split(
    X_temp,
    y_temp,
    test_size=0.50,
    random_state=42,
    stratify=y_temp
)

print("\n===== DATA SPLIT =====")
print("Training set:", X_train.shape)
print("Validation set:", X_val.shape)
print("Test set:", X_test.shape)


# =========================
# 5. Apply SMOTE only on training data
# =========================

class_counts = Counter(y_train)
min_class_count = min(class_counts.values())

print("\n===== CLASS DISTRIBUTION BEFORE SMOTE =====")
print("Minimum class count:", min_class_count)

if min_class_count > 1:
    k_neighbors = min(5, min_class_count - 1)

    smote = SMOTE(
        random_state=42,
        k_neighbors=k_neighbors
    )

    X_train_smote, y_train_smote = smote.fit_resample(X_train, y_train)

    print("\n===== SMOTE APPLIED =====")
    print("SMOTE k_neighbors:", k_neighbors)
    print("Before SMOTE:", X_train.shape)
    print("After SMOTE:", X_train_smote.shape)
else:
    print("\nWARNING: Some classes have only 1 sample. SMOTE skipped.")
    X_train_smote, y_train_smote = X_train, y_train


# =========================
# 6. Train LightGBM model
# =========================

print("\n===== TRAINING LIGHTGBM DISEASE MODEL =====")

lgbm_disease = LGBMClassifier(
    random_state=42,
    class_weight="balanced",
    n_estimators=200,
    learning_rate=0.05,
    num_leaves=31
)

lgbm_disease.fit(X_train_smote, y_train_smote)

y_pred_lgbm = lgbm_disease.predict(X_test)

lgbm_f1 = f1_score(y_test, y_pred_lgbm, average="weighted")

print("\n===== LIGHTGBM RESULTS =====")
print(classification_report(
    y_test,
    y_pred_lgbm,
    target_names=label_encoder_disease.classes_,
    zero_division=0
))
print("LightGBM Weighted F1-score:", lgbm_f1)


# =========================
# 7. Train CatBoost model
# =========================

print("\n===== TRAINING CATBOOST DISEASE MODEL =====")

cat_disease = CatBoostClassifier(
    iterations=200,
    learning_rate=0.05,
    depth=6,
    loss_function="MultiClass",
    random_seed=42,
    verbose=0
)

cat_disease.fit(X_train_smote, y_train_smote)

y_pred_cat = cat_disease.predict(X_test)
y_pred_cat = y_pred_cat.flatten()

cat_f1 = f1_score(y_test, y_pred_cat, average="weighted")

print("\n===== CATBOOST RESULTS =====")
print(classification_report(
    y_test,
    y_pred_cat,
    target_names=label_encoder_disease.classes_,
    zero_division=0
))
print("CatBoost Weighted F1-score:", cat_f1)


# =========================
# 8. Compare models
# =========================

print("\n===== MODEL COMPARISON =====")
print("LightGBM Weighted F1-score:", lgbm_f1)
print("CatBoost Weighted F1-score:", cat_f1)

if lgbm_f1 >= cat_f1:
    best_model = lgbm_disease
    best_model_name = "LightGBM"
    best_model_path = "models/lgbm_disease_model.pkl"
else:
    best_model = cat_disease
    best_model_name = "CatBoost"
    best_model_path = "models/catboost_disease_model.pkl"

print("Best model:", best_model_name)


# =========================
# 9. Save models and encoder
# =========================

joblib.dump(lgbm_disease, "models/lgbm_disease_model.pkl")
joblib.dump(cat_disease, "models/catboost_disease_model.pkl")
joblib.dump(best_model, "models/best_disease_model.pkl")
joblib.dump(label_encoder_disease, "models/label_encoder_disease.pkl")
joblib.dump(X.columns.tolist(), "models/disease_feature_columns.pkl")

print("\n===== FILES SAVED =====")
print("Saved LightGBM model: models/lgbm_disease_model.pkl")
print("Saved CatBoost model: models/catboost_disease_model.pkl")
print("Saved best model: models/best_disease_model.pkl")
print("Saved disease label encoder: models/label_encoder_disease.pkl")
print("Saved feature columns: models/disease_feature_columns.pkl")
import pandas as pd
import joblib
import re

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import sklearn.metrics

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
y = df[target_severity]


# Clean feature names for LightGBM
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
# =========================

label_encoder_severity = LabelEncoder()
y_encoded = label_encoder_severity.fit_transform(y)

print("\n===== ENCODED SEVERITY CLASSES =====")
print(label_encoder_severity.classes_)


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

print("\n===== CLASS BALANCE CHECK =====")

y_train_labels = label_encoder_severity.inverse_transform(y_train)
training_class_counts = pd.Series(y_train_labels, name="Severity").value_counts()

print("Training severity distribution before modelling:")
print(training_class_counts)

imbalance_ratio = training_class_counts.max() / training_class_counts.min()
print(f"Imbalance ratio: {imbalance_ratio:.3f}")

if imbalance_ratio <= 1.5:
    print("Dataset is already balanced. SMOTE is not applied.")
else:
    print("Dataset is imbalanced. SMOTE may be considered only on the training set.")

# =========================
# 5. Train directly on split data (no SMOTE needed)
# =========================

# Dataset is already balanced (~33% each class), so no oversampling needed
print("\n===== DATA IS BALANCED =====")
print("No SMOTE required - using original training data")
print("Training set:", X_train.shape)


# =========================
# 6. Train LightGBM severity model
# =========================

print("\n===== TRAINING LIGHTGBM SEVERITY MODEL =====")

lgbm_severity = LGBMClassifier(
    random_state=42,
    n_estimators=200,
    learning_rate=0.05,
    num_leaves=31
)

lgbm_severity.fit(X_train, y_train)

y_pred_lgbm = lgbm_severity.predict(X_test)

lgbm_f1 = sklearn.metrics.f1_score(y_test, y_pred_lgbm, average="weighted")

print("\n===== LIGHTGBM SEVERITY RESULTS =====")
print(sklearn.metrics.classification_report(
    y_test,
    y_pred_lgbm,
    target_names=label_encoder_severity.classes_,
    zero_division=0
))
print("LightGBM Weighted F1-score:", lgbm_f1)


# =========================
# 7. Train CatBoost severity model
# =========================

print("\n===== TRAINING CATBOOST SEVERITY MODEL =====")

cat_severity = CatBoostClassifier(
    iterations=200,
    learning_rate=0.05,
    depth=6,
    loss_function="MultiClass",
    random_seed=42,
    allow_writing_files=False,
    verbose=0
)

cat_severity.fit(X_train, y_train)

y_pred_cat = cat_severity.predict(X_test)
y_pred_cat = y_pred_cat.flatten()

cat_f1 = sklearn.metrics.f1_score(y_test, y_pred_cat, average="weighted")

print("\n===== CATBOOST SEVERITY RESULTS =====")
print(sklearn.metrics.classification_report(
    y_test,
    y_pred_cat,
    target_names=label_encoder_severity.classes_,
    zero_division=0
))
print("CatBoost Weighted F1-score:", cat_f1)


# =========================
# 8. Severe recall calculation
# =========================

severity_classes = list(label_encoder_severity.classes_)
print("\n===== SEVERE RECALL =====")
print("Severity classes:", severity_classes)

severe_index = [
    i for i, label in enumerate(severity_classes)
    if label.lower() == "severe"
][0]

lgbm_severe_recall = sklearn.metrics.recall_score(
    y_test,
    y_pred_lgbm,
    labels=[severe_index],
    average="macro",
    zero_division=0
)

cat_severe_recall = sklearn.metrics.recall_score(
    y_test,
    y_pred_cat,
    labels=[severe_index],
    average="macro",
    zero_division=0
)

print("LightGBM Recall for Severe cases:", lgbm_severe_recall)
print("CatBoost Recall for Severe cases:", cat_severe_recall)


# =========================
# 9. Compare models
# =========================

print("\n===== MODEL COMPARISON =====")
print("LightGBM Weighted F1-score:", lgbm_f1)
print("CatBoost Weighted F1-score:", cat_f1)
print("LightGBM Severe Recall:", lgbm_severe_recall)
print("CatBoost Severe Recall:", cat_severe_recall)

# Prioritise severe recall first, then F1-score
if cat_severe_recall > lgbm_severe_recall:
    best_model = cat_severity
    best_model_name = "CatBoost"
elif cat_severe_recall < lgbm_severe_recall:
    best_model = lgbm_severity
    best_model_name = "LightGBM"
else:
    if cat_f1 >= lgbm_f1:
        best_model = cat_severity
        best_model_name = "CatBoost"
    else:
        best_model = lgbm_severity
        best_model_name = "LightGBM"

print("Best severity model:", best_model_name)


# =========================
# 10. Save models and encoder
# =========================

joblib.dump(lgbm_severity, "models/lgbm_severity_model.pkl")
joblib.dump(cat_severity, "models/catboost_severity_model.pkl")
joblib.dump(best_model, "models/best_severity_model.pkl")
joblib.dump(label_encoder_severity, "models/label_encoder_severity.pkl")
joblib.dump(X.columns.tolist(), "models/severity_feature_columns.pkl")

print("\n===== FILES SAVED =====")
print("Saved LightGBM severity model: models/lgbm_severity_model.pkl")
print("Saved CatBoost severity model: models/catboost_severity_model.pkl")
print("Saved best severity model: models/best_severity_model.pkl")
print("Saved severity label encoder: models/label_encoder_severity.pkl")
print("Saved feature columns: models/severity_feature_columns.pkl")

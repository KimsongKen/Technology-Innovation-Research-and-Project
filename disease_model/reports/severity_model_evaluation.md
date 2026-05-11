# Severity Classification Model Evaluation

## 1. Component Overview

This component supports the SACA project by classifying patient-reported symptoms into severity levels: Mild, Moderate, and Severe.

The severity classification model is a support component for the broader disease prediction system. Disease prediction focuses on identifying what illness may be associated with the symptoms, while severity classification estimates how serious the case may be.

## 2. My Role

My role is ML Engineer #2: Data + Core ML Models.

My main responsibility is disease prediction, with severity classification as a supporting function. This includes:

- data cleaning and preprocessing;
- preparing symptom-based features;
- building machine learning models;
- evaluating model performance;
- checking class balance;
- prioritising recall for Severe cases in a triage context.

## 3. Dataset Summary

The dataset contained 29,995 records and 256 columns.

After feature and target preparation:

- Feature shape: 29,995 rows and 254 features
- Target shape: 29,995 severity labels

Severity class distribution:

| Severity | Count |
|---|---:|
| Moderate | 10,000 |
| Mild | 9,998 |
| Severe | 9,997 |

The dataset was balanced, with an imbalance ratio of 1.000 in the training set. Therefore, SMOTE was not applied.

## 4. Train / Validation / Test Split

| Split | Shape |
|---|---:|
| Training set | 20,996 × 254 |
| Validation set | 4,499 × 254 |
| Test set | 4,500 × 254 |

## 5. Model Approach

Two machine learning models were implemented:

- LightGBM
- CatBoost

The models were trained using the training data and evaluated using classification metrics. The final selected model was LightGBM because it achieved stronger weighted F1-score and higher recall for Severe cases.

## 6. Final Model Metrics

Selected model: **LightGBM**

| Metric | LightGBM | CatBoost |
|---|---:|---:|
| Weighted F1-score | 0.9487 | 0.8844 |
| Severe Recall | 0.9587 | 0.8700 |
| Accuracy | 0.95 | 0.88 |

LightGBM was selected as the best severity classification model.

## 7. Why Severe Recall Matters

In a triage context, Severe Recall is important because the system should minimise the risk of missing serious cases. If a severe case is incorrectly classified as mild or moderate, the user may receive delayed or unsuitable advice.

Therefore, the model comparison considered overall performance, but gave special attention to recall for the Severe class.

## 8. Evaluation Outputs

The following visual outputs were generated:

- `reports/confusion_matrix.png`
- `reports/per_class_metrics.png`
- `reports/symptom_count_distribution.png`
- `reports/top20_symptoms.png`

## 9. Local Model Artefacts

The script generates model artefacts locally in the `models/` folder:

- `models/lgbm_severity_model.pkl`
- `models/catboost_severity_model.pkl`
- `models/best_severity_model.pkl`
- `models/label_encoder_severity.pkl`
- `models/severity_feature_columns.pkl`

The `models/` folder is ignored by Git because these files are generated artefacts and can be recreated by running the script.
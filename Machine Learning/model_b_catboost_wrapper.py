from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

import pandas as pd
from catboost import CatBoostClassifier
from sklearn.preprocessing import LabelEncoder


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DATASET_PATH = PROJECT_ROOT / "archive" / "Model_catboost" / "saca_top40_dataset 1.csv"
SPLIT_META_PATH = Path(__file__).resolve().parent / "standardized_split_meta.json"


def _clean_feature_columns(df: pd.DataFrame) -> pd.DataFrame:
    cleaned = df.copy()
    cleaned.columns = [re.sub(r"[^A-Za-z0-9_]", "_", str(c)) for c in cleaned.columns]
    return cleaned


@dataclass
class CatBoostArtifacts:
    disease_model: CatBoostClassifier
    severity_model: CatBoostClassifier
    disease_encoder: LabelEncoder
    severity_encoder: LabelEncoder


def get_feature_columns(dataset_path: Path = SOURCE_DATASET_PATH) -> list[str]:
    df = pd.read_csv(dataset_path, nrows=1)
    return [c for c in df.columns if c not in {"diseases", "Severity"}]


def _load_train_df(
    dataset_path: Path = SOURCE_DATASET_PATH,
    split_meta_path: Path = SPLIT_META_PATH,
) -> pd.DataFrame:
    full_df = pd.read_csv(dataset_path)
    split_meta = json.loads(split_meta_path.read_text(encoding="utf-8"))
    test_indices = set(split_meta["test_indices"])
    train_df = full_df.loc[~full_df.index.isin(test_indices)].copy().reset_index(drop=True)
    return train_df


def train_models() -> CatBoostArtifacts:
    train_df = _load_train_df()
    x_train = train_df.drop(columns=["diseases", "Severity"])
    x_train = _clean_feature_columns(x_train)

    y_train_disease = train_df["diseases"].astype(str)
    y_train_severity = train_df["Severity"].astype(str)

    disease_encoder = LabelEncoder()
    severity_encoder = LabelEncoder()

    y_train_disease_enc = disease_encoder.fit_transform(y_train_disease)
    y_train_severity_enc = severity_encoder.fit_transform(y_train_severity)

    # Parameters mirror the notebook's CatBoost setup.
    common_params = {
        "iterations": 500,
        "learning_rate": 0.05,
        "depth": 6,
        "verbose": False,
        "random_seed": 42,
        "task_type": "CPU",
    }

    disease_model = CatBoostClassifier(loss_function="MultiClass", **common_params)
    disease_model.fit(x_train, y_train_disease_enc)

    severity_model = CatBoostClassifier(loss_function="MultiClass", **common_params)
    severity_model.fit(x_train, y_train_severity_enc)

    return CatBoostArtifacts(
        disease_model=disease_model,
        severity_model=severity_model,
        disease_encoder=disease_encoder,
        severity_encoder=severity_encoder,
    )


def predict(test_df: pd.DataFrame, artifacts: CatBoostArtifacts | None = None) -> pd.DataFrame:
    artifacts = artifacts or train_models()

    x_test = test_df.drop(columns=["diseases", "Severity"])
    x_test = _clean_feature_columns(x_test)

    disease_pred_enc = artifacts.disease_model.predict(x_test).astype(int).ravel()
    severity_pred_enc = artifacts.severity_model.predict(x_test).astype(int).ravel()

    disease_pred = artifacts.disease_encoder.inverse_transform(disease_pred_enc)
    severity_pred = artifacts.severity_encoder.inverse_transform(severity_pred_enc)

    return pd.DataFrame(
        {
            "disease_pred": disease_pred,
            "severity_pred": severity_pred,
        }
    )


def predict_from_symptoms(
    symptoms: list[str],
    artifacts: CatBoostArtifacts | None = None,
    feature_columns: list[str] | None = None,
) -> dict[str, object]:
    artifacts = artifacts or train_models()
    feature_columns = feature_columns or get_feature_columns()

    symptom_set = {s.strip().lower() for s in symptoms if s.strip()}
    one_row = pd.DataFrame(
        [{col: (1 if col.strip().lower() in symptom_set else 0) for col in feature_columns}]
    )
    one_row = _clean_feature_columns(one_row)

    disease_proba = artifacts.disease_model.predict_proba(one_row)[0]
    severity_proba = artifacts.severity_model.predict_proba(one_row)[0]

    disease_pred_enc = [int(disease_proba.argmax())]
    severity_pred_enc = [int(severity_proba.argmax())]

    disease_pred = artifacts.disease_encoder.inverse_transform(disease_pred_enc)[0]
    severity_pred = artifacts.severity_encoder.inverse_transform(severity_pred_enc)[0]

    disease_conf = float(disease_proba[disease_pred_enc[0]])
    severity_conf = float(severity_proba[severity_pred_enc[0]])

    disease_probs = {
        str(label): round(float(prob), 3)
        for label, prob in zip(artifacts.disease_encoder.classes_, disease_proba)
    }
    severity_probs = {
        str(label): round(float(prob), 3)
        for label, prob in zip(artifacts.severity_encoder.classes_, severity_proba)
    }

    return {
        "disease": str(disease_pred),
        "severity": str(severity_pred),
        "disease_confidence": round(disease_conf, 3),
        "severity_confidence": round(severity_conf, 3),
        "disease_probs": disease_probs,
        "severity_probs": severity_probs,
    }

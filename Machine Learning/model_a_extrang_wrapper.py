from __future__ import annotations

import importlib.util
from pathlib import Path
from types import ModuleType

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
EXTRA_MODEL_DIR = PROJECT_ROOT / "archive" / "Model_ExtraNGvboost"
PREDICTOR_PATH = EXTRA_MODEL_DIR / "predictor.py"


def _load_predictor_module(predictor_path: Path = PREDICTOR_PATH) -> ModuleType:
    spec = importlib.util.spec_from_file_location("saca_extra_predictor", predictor_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to create import spec for {predictor_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_predictor() -> ModuleType:
    return _load_predictor_module()


def _row_to_symptom_list(row: pd.Series, symptom_columns: list[str]) -> list[str]:
    symptoms: list[str] = []
    for col in symptom_columns:
        val = row.get(col, 0)
        if pd.notna(val) and float(val) > 0:
            symptoms.append(col)
    return symptoms


def predict_from_symptoms(symptoms: list[str], predictor_module: ModuleType | None = None) -> dict:
    module = predictor_module or _load_predictor_module()
    return module.predict(symptoms)


def predict(test_df: pd.DataFrame) -> pd.DataFrame:
    predictor_module = _load_predictor_module()
    symptom_columns = [
        c for c in test_df.columns if c not in {"diseases", "Severity"}
    ]

    rows = []
    for _, row in test_df.iterrows():
        symptoms = _row_to_symptom_list(row, symptom_columns)
        result = predictor_module.predict(symptoms)
        rows.append(
            {
                "disease_pred": result["disease"],
                "severity_pred": result["severity"],
                "severity_confidence": result["severity_confidence"],
                "disease_confidence": result["disease_confidence"],
                "matched_symptom_count": len(result["matched_syms"]),
            }
        )

    return pd.DataFrame(rows)

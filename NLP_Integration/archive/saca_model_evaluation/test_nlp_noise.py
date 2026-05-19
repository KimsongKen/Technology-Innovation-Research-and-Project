from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

import pandas as pd
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, recall_score

from model_a_extrang_wrapper import load_predictor, predict as predict_extra_clean
from model_a_extrang_wrapper import predict_from_symptoms as predict_extra_symptoms
from model_b_catboost_wrapper import get_feature_columns, predict as predict_cat_clean
from model_b_catboost_wrapper import predict_from_symptoms as predict_cat_symptoms
from model_b_catboost_wrapper import train_models
from system_eval_utils import (
    SbertSymptomMapper,
    inject_human_noise,
    load_standardized_test_set,
    row_to_symptoms,
    symptom_columns_from_df,
)


EVAL_DIR = Path(__file__).resolve().parent
JSON_PATH = EVAL_DIR / "nlp_noise_results.json"
REPORT_PATH = EVAL_DIR / "nlp_noise_report.md"


def metric_bundle(y_true: pd.Series, y_pred: pd.Series) -> dict[str, float]:
    p_macro, r_macro, f1_macro, _ = precision_recall_fscore_support(
        y_true, y_pred, average="macro", zero_division=0
    )
    p_weighted, r_weighted, f1_weighted, _ = precision_recall_fscore_support(
        y_true, y_pred, average="weighted", zero_division=0
    )
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "precision_macro": float(p_macro),
        "recall_macro": float(r_macro),
        "f1_macro": float(f1_macro),
        "precision_weighted": float(p_weighted),
        "recall_weighted": float(r_weighted),
        "f1_weighted": float(f1_weighted),
    }


def severe_recall(y_true: pd.Series, y_pred: pd.Series) -> float:
    return float(
        recall_score(y_true, y_pred, labels=["Severe"], average="macro", zero_division=0)
    )


def _fmt(v: float) -> str:
    return f"{v:.4f}"


def run(max_samples: int | None = None, random_seed: int = 42) -> dict:
    rng = random.Random(random_seed)

    test_df = load_standardized_test_set()
    if max_samples is not None:
        test_df = test_df.head(max_samples).copy()

    y_true_disease = test_df["diseases"].astype(str)
    y_true_severity = test_df["Severity"].astype(str)

    # Baseline clean metrics (no synthetic text noise).
    clean_extra = predict_extra_clean(test_df)
    clean_cat = predict_cat_clean(test_df)

    clean_metrics = {
        "ExtraNGvboost": {
            "disease": metric_bundle(y_true_disease, clean_extra["disease_pred"].astype(str)),
            "severity": metric_bundle(y_true_severity, clean_extra["severity_pred"].astype(str)),
            "severe_recall": severe_recall(y_true_severity, clean_extra["severity_pred"].astype(str)),
        },
        "CatBoost": {
            "disease": metric_bundle(y_true_disease, clean_cat["disease_pred"].astype(str)),
            "severity": metric_bundle(y_true_severity, clean_cat["severity_pred"].astype(str)),
            "severe_recall": severe_recall(y_true_severity, clean_cat["severity_pred"].astype(str)),
        },
    }

    symptom_cols = symptom_columns_from_df(test_df)
    mapper = SbertSymptomMapper(symptom_names=symptom_cols, threshold=0.35)
    extra_predictor = load_predictor()
    cat_artifacts = train_models()
    cat_features = get_feature_columns()

    noisy_records: list[dict] = []
    for _, row in test_df.iterrows():
        clean_symptoms = row_to_symptoms(row, symptom_cols)
        noisy_chunks = inject_human_noise(clean_symptoms, rng)
        mapped_symptoms = mapper.map_noisy_symptoms(noisy_chunks)

        res_extra = predict_extra_symptoms(mapped_symptoms, predictor_module=extra_predictor)
        res_cat = predict_cat_symptoms(
            mapped_symptoms, artifacts=cat_artifacts, feature_columns=cat_features
        )
        noisy_records.append(
            {
                "true_disease": str(row["diseases"]),
                "true_severity": str(row["Severity"]),
                "extra_disease_pred": str(res_extra["disease"]),
                "extra_severity_pred": str(res_extra["severity"]),
                "cat_disease_pred": str(res_cat["disease"]),
                "cat_severity_pred": str(res_cat["severity"]),
                "clean_symptom_count": len(clean_symptoms),
                "mapped_symptom_count": len(mapped_symptoms),
            }
        )

    noisy_df = pd.DataFrame(noisy_records)
    noisy_metrics = {
        "ExtraNGvboost": {
            "disease": metric_bundle(y_true_disease, noisy_df["extra_disease_pred"]),
            "severity": metric_bundle(y_true_severity, noisy_df["extra_severity_pred"]),
            "severe_recall": severe_recall(y_true_severity, noisy_df["extra_severity_pred"]),
        },
        "CatBoost": {
            "disease": metric_bundle(y_true_disease, noisy_df["cat_disease_pred"]),
            "severity": metric_bundle(y_true_severity, noisy_df["cat_severity_pred"]),
            "severe_recall": severe_recall(y_true_severity, noisy_df["cat_severity_pred"]),
        },
    }

    drops: dict[str, dict[str, float]] = {}
    for model_name in ["ExtraNGvboost", "CatBoost"]:
        drops[model_name] = {
            "disease_f1_weighted_drop": clean_metrics[model_name]["disease"]["f1_weighted"]
            - noisy_metrics[model_name]["disease"]["f1_weighted"],
            "severity_f1_weighted_drop": clean_metrics[model_name]["severity"]["f1_weighted"]
            - noisy_metrics[model_name]["severity"]["f1_weighted"],
            "severe_recall_drop": clean_metrics[model_name]["severe_recall"]
            - noisy_metrics[model_name]["severe_recall"],
        }
        drops[model_name]["combined_drop_score"] = (
            0.4 * drops[model_name]["disease_f1_weighted_drop"]
            + 0.4 * drops[model_name]["severity_f1_weighted_drop"]
            + 0.2 * drops[model_name]["severe_recall_drop"]
        )

    winner = min(drops.keys(), key=lambda m: drops[m]["combined_drop_score"])

    results = {
        "config": {
            "max_samples": max_samples,
            "random_seed": random_seed,
            "sbert_model": "all-MiniLM-L6-v2",
            "sbert_similarity_threshold": 0.35,
        },
        "sample_count": int(len(test_df)),
        "clean_metrics": clean_metrics,
        "noisy_metrics": noisy_metrics,
        "drops": drops,
        "winner": winner,
        "mapping_quality": {
            "avg_mapped_symptom_count": float(noisy_df["mapped_symptom_count"].mean()),
            "avg_clean_symptom_count": float(noisy_df["clean_symptom_count"].mean()),
        },
    }
    return results


def build_report(results: dict) -> str:
    winner = results["winner"]
    d = results["drops"]
    return "\n".join(
        [
            "# NLP Noise Robustness Report",
            "",
            f"- Samples evaluated: `{results['sample_count']}`",
            f"- SBERT model: `{results['config']['sbert_model']}`",
            f"- Winner (least performance drop): `{winner}`",
            "",
            "## Drop Summary (Lower is Better)",
            "",
            "| Model | Disease F1w Drop | Severity F1w Drop | Severe Recall Drop | Combined Drop Score |",
            "| --- | --- | --- | --- | --- |",
            f"| ExtraNGvboost | {_fmt(d['ExtraNGvboost']['disease_f1_weighted_drop'])} | {_fmt(d['ExtraNGvboost']['severity_f1_weighted_drop'])} | {_fmt(d['ExtraNGvboost']['severe_recall_drop'])} | {_fmt(d['ExtraNGvboost']['combined_drop_score'])} |",
            f"| CatBoost | {_fmt(d['CatBoost']['disease_f1_weighted_drop'])} | {_fmt(d['CatBoost']['severity_f1_weighted_drop'])} | {_fmt(d['CatBoost']['severe_recall_drop'])} | {_fmt(d['CatBoost']['combined_drop_score'])} |",
            "",
            "## Mapping Quality",
            "",
            f"- Average clean symptom count per sample: `{_fmt(results['mapping_quality']['avg_clean_symptom_count'])}`",
            f"- Average mapped symptom count after noise+SBERT: `{_fmt(results['mapping_quality']['avg_mapped_symptom_count'])}`",
            "",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Run NLP noise robustness test with SBERT.")
    parser.add_argument("--max-samples", type=int, default=None)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    results = run(max_samples=args.max_samples, random_seed=args.seed)
    JSON_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")
    REPORT_PATH.write_text(build_report(results), encoding="utf-8")

    print(f"Saved noise test JSON to: {JSON_PATH}")
    print(f"Saved noise test report to: {REPORT_PATH}")
    print(f"Noise robustness winner: {results['winner']}")


if __name__ == "__main__":
    main()

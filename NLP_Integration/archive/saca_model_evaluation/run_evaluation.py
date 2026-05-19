from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pandas as pd
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, recall_score

from data_prep import OUTPUT_TEST_PATH, create_standardized_test_set
from model_a_extrang_wrapper import predict as predict_extrang
from model_b_catboost_wrapper import predict as predict_catboost


EVAL_DIR = Path(__file__).resolve().parent
REPORT_PATH = EVAL_DIR / "model_comparison_report.md"
RESULTS_JSON_PATH = EVAL_DIR / "evaluation_results.json"
PREDICTIONS_PATH = EVAL_DIR / "model_predictions.csv"


def _metric_bundle(y_true: pd.Series, y_pred: pd.Series) -> dict[str, float]:
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


def _severity_specific(y_true: pd.Series, y_pred: pd.Series) -> dict[str, float]:
    severe_recall = recall_score(
        y_true,
        y_pred,
        labels=["Severe"],
        average="macro",
        zero_division=0,
    )
    return {"severe_recall": float(severe_recall)}


def _pick_disease_winner(results: dict[str, dict[str, float]]) -> str:
    return max(
        results.keys(),
        key=lambda m: (
            results[m]["f1_weighted"],
            results[m]["f1_macro"],
            results[m]["accuracy"],
        ),
    )


def _pick_severity_winner(results: dict[str, dict[str, float]]) -> str:
    return max(
        results.keys(),
        key=lambda m: (
            results[m]["severe_recall"],
            results[m]["f1_weighted"],
            results[m]["f1_macro"],
            results[m]["accuracy"],
        ),
    )


def _fmt(v: float) -> str:
    return f"{v:.4f}"


def _comparison_table_md(
    title: str,
    model_results: dict[str, dict[str, float]],
    include_severe_recall: bool = False,
) -> str:
    headers = [
        "Model",
        "Accuracy",
        "Precision (Macro)",
        "Recall (Macro)",
        "F1 (Macro)",
        "Precision (Weighted)",
        "Recall (Weighted)",
        "F1 (Weighted)",
    ]
    if include_severe_recall:
        headers.append("Recall (Severe Class)")

    lines = [
        f"### {title}",
        "",
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for model_name, m in model_results.items():
        row = [
            model_name,
            _fmt(m["accuracy"]),
            _fmt(m["precision_macro"]),
            _fmt(m["recall_macro"]),
            _fmt(m["f1_macro"]),
            _fmt(m["precision_weighted"]),
            _fmt(m["recall_weighted"]),
            _fmt(m["f1_weighted"]),
        ]
        if include_severe_recall:
            row.append(_fmt(m["severe_recall"]))
        lines.append("| " + " | ".join(row) + " |")
    lines.append("")
    return "\n".join(lines)


def _build_report(results: dict[str, Any]) -> str:
    disease_winner = results["winners"]["disease"]
    severity_winner = results["winners"]["severity"]
    disease_scores = results["disease_metrics"]
    severity_scores = results["severity_metrics"]

    disease_reason = (
        f"{disease_winner} is selected because it has the highest weighted F1 "
        f"({_fmt(disease_scores[disease_winner]['f1_weighted'])}) and strong macro F1 "
        f"({_fmt(disease_scores[disease_winner]['f1_macro'])}) on disease classes."
    )
    severity_reason = (
        f"{severity_winner} is selected because it achieves the best Severe recall "
        f"({_fmt(severity_scores[severity_winner]['severe_recall'])}) while also maintaining "
        f"competitive weighted F1 ({_fmt(severity_scores[severity_winner]['f1_weighted'])})."
    )

    report_parts = [
        "# SACA Model Evaluation Report (CatBoost vs ExtraNGvboost)",
        "",
        "## Evaluation Setup",
        "",
        "- Test data source: `archive/Model_catboost/saca_top40_dataset 1.csv`",
        "- Standardized hold-out split: 20% test set, fixed random seed 42, stratified by `Severity`",
        "- Both models were evaluated on the exact same `standardized_test_set.csv`",
        "- Targets evaluated: `diseases` and `Severity`",
        "",
        _comparison_table_md("Disease Prediction Metrics", disease_scores),
        _comparison_table_md(
            "Severity Prediction Metrics", severity_scores, include_severe_recall=True
        ),
        "## Winners",
        "",
        f"- **Disease Winner:** `{disease_winner}`",
        f"- **Severity Winner:** `{severity_winner}`",
        "",
        "## Why These Winners",
        "",
        f"- **Disease:** {disease_reason}",
        f"- **Severity:** {severity_reason}",
        "",
        "## Clinical Safety Note",
        "",
        "The `Recall (Severe Class)` metric is the most clinically sensitive signal here. "
        "A lower value means more truly severe patients are being missed.",
        "",
    ]
    return "\n".join(report_parts)


def main() -> None:
    test_df = create_standardized_test_set()
    y_true_disease = test_df["diseases"].astype(str)
    y_true_severity = test_df["Severity"].astype(str)

    preds_extra = predict_extrang(test_df)
    preds_cat = predict_catboost(test_df)

    disease_metrics = {
        "ExtraNGvboost": _metric_bundle(y_true_disease, preds_extra["disease_pred"].astype(str)),
        "CatBoost": _metric_bundle(y_true_disease, preds_cat["disease_pred"].astype(str)),
    }

    severity_metrics = {
        "ExtraNGvboost": _metric_bundle(
            y_true_severity, preds_extra["severity_pred"].astype(str)
        ),
        "CatBoost": _metric_bundle(y_true_severity, preds_cat["severity_pred"].astype(str)),
    }
    severity_metrics["ExtraNGvboost"].update(
        _severity_specific(y_true_severity, preds_extra["severity_pred"].astype(str))
    )
    severity_metrics["CatBoost"].update(
        _severity_specific(y_true_severity, preds_cat["severity_pred"].astype(str))
    )

    winners = {
        "disease": _pick_disease_winner(disease_metrics),
        "severity": _pick_severity_winner(severity_metrics),
    }

    merged_preds = pd.DataFrame(
        {
            "true_disease": y_true_disease,
            "true_severity": y_true_severity,
            "extra_disease_pred": preds_extra["disease_pred"],
            "extra_severity_pred": preds_extra["severity_pred"],
            "cat_disease_pred": preds_cat["disease_pred"],
            "cat_severity_pred": preds_cat["severity_pred"],
        }
    )
    merged_preds.to_csv(PREDICTIONS_PATH, index=False)

    results = {
        "disease_metrics": disease_metrics,
        "severity_metrics": severity_metrics,
        "winners": winners,
        "artifacts": {
            "standardized_test_set": str(OUTPUT_TEST_PATH),
            "predictions_csv": str(PREDICTIONS_PATH),
        },
    }
    RESULTS_JSON_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")

    report = _build_report(results)
    REPORT_PATH.write_text(report, encoding="utf-8")

    print(f"Evaluation complete. Report saved to: {REPORT_PATH}")
    print(f"Structured metrics saved to: {RESULTS_JSON_PATH}")
    print(f"Per-sample predictions saved to: {PREDICTIONS_PATH}")
    print(f"Disease winner: {winners['disease']}")
    print(f"Severity winner: {winners['severity']}")


if __name__ == "__main__":
    main()

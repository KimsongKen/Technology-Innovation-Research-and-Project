from __future__ import annotations

import argparse
import itertools
import json
from pathlib import Path

import pandas as pd

from model_a_extrang_wrapper import load_predictor, predict_from_symptoms as predict_extra
from model_b_catboost_wrapper import get_feature_columns, predict_from_symptoms as predict_cat
from model_b_catboost_wrapper import train_models
from system_eval_utils import load_standardized_test_set, row_to_symptoms, symptom_columns_from_df


EVAL_DIR = Path(__file__).resolve().parent
JSON_PATH = EVAL_DIR / "explainability_results.json"
REPORT_PATH = EVAL_DIR / "explainability_report.md"


def _severity_prob(pred: dict) -> float:
    return float(pred.get("severity_probs", {}).get("Severe", 0.0))


def _top3_by_occlusion(symptoms: list[str], predict_fn) -> list[dict]:
    if not symptoms:
        return []

    base = predict_fn(symptoms)
    base_prob = _severity_prob(base)

    impacts: list[dict] = []
    for s in symptoms:
        reduced = [x for x in symptoms if x != s]
        alt = predict_fn(reduced)
        delta = base_prob - _severity_prob(alt)
        impacts.append({"symptom": s, "delta_severe_prob": float(delta)})

    impacts.sort(key=lambda x: x["delta_severe_prob"], reverse=True)
    return impacts[:3]


def _mean_pairwise_jaccard(top3_sets: list[set[str]]) -> float:
    if len(top3_sets) < 2:
        return 1.0
    vals: list[float] = []
    for a, b in itertools.combinations(top3_sets, 2):
        inter = len(a & b)
        union = len(a | b)
        vals.append(1.0 if union == 0 else inter / union)
    return float(sum(vals) / len(vals))


def _native_importance_top3_extra(extra_module) -> list[dict]:
    model = extra_module.severity_model
    model_symptom_cols = list(extra_module.sym_cols)
    importances = None

    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
    elif hasattr(model, "estimators_"):
        per_estimator = []
        for est in model.estimators_:
            if hasattr(est, "feature_importances_"):
                per_estimator.append(est.feature_importances_)
        if per_estimator:
            importances = pd.DataFrame(per_estimator).mean(axis=0).to_numpy()

    if importances is None:
        return []

    s = pd.Series(importances, index=model_symptom_cols).sort_values(ascending=False).head(3)
    return [{"symptom": str(k), "importance": float(v)} for k, v in s.items()]


def _native_importance_top3_cat(cat_artifacts, feature_cols: list[str]) -> list[dict]:
    importances = cat_artifacts.severity_model.get_feature_importance()
    s = pd.Series(importances, index=feature_cols).sort_values(ascending=False).head(3)
    return [{"symptom": str(k), "importance": float(v)} for k, v in s.items()]


def run(max_cases: int = 60) -> dict:
    df = load_standardized_test_set()
    severe_cases = df[df["Severity"].astype(str) == "Severe"].head(max_cases).copy()
    symptom_cols = symptom_columns_from_df(df)

    extra_predictor = load_predictor()
    cat_artifacts = train_models()
    cat_features = get_feature_columns()

    def pred_extra(symptoms: list[str]) -> dict:
        return predict_extra(symptoms, predictor_module=extra_predictor)

    def pred_cat(symptoms: list[str]) -> dict:
        return predict_cat(symptoms, artifacts=cat_artifacts, feature_columns=cat_features)

    extra_cases: list[dict] = []
    cat_cases: list[dict] = []

    for idx, row in severe_cases.iterrows():
        symptoms = row_to_symptoms(row, symptom_cols)
        top_extra = _top3_by_occlusion(symptoms, pred_extra)
        top_cat = _top3_by_occlusion(symptoms, pred_cat)
        extra_cases.append(
            {"row_index": int(idx), "top3": top_extra, "top3_set": {x["symptom"] for x in top_extra}}
        )
        cat_cases.append(
            {"row_index": int(idx), "top3": top_cat, "top3_set": {x["symptom"] for x in top_cat}}
        )

    extra_stability = _mean_pairwise_jaccard([x["top3_set"] for x in extra_cases])
    cat_stability = _mean_pairwise_jaccard([x["top3_set"] for x in cat_cases])

    extra_mean_delta = float(
        pd.Series([x["delta_severe_prob"] for c in extra_cases for x in c["top3"]]).mean()
    )
    cat_mean_delta = float(
        pd.Series([x["delta_severe_prob"] for c in cat_cases for x in c["top3"]]).mean()
    )

    winner = max(
        ["ExtraNGvboost", "CatBoost"],
        key=lambda m: (
            extra_stability if m == "ExtraNGvboost" else cat_stability,
            extra_mean_delta if m == "ExtraNGvboost" else cat_mean_delta,
        ),
    )

    return {
        "config": {"max_cases": max_cases, "focus": "Severity explainability"},
        "evaluated_cases": int(len(severe_cases)),
        "models": {
            "ExtraNGvboost": {
                "stability_jaccard": extra_stability,
                "mean_top3_delta_severe_prob": extra_mean_delta,
                "sample_case": extra_cases[0]["top3"] if extra_cases else [],
                "native_global_top3": _native_importance_top3_extra(extra_predictor),
            },
            "CatBoost": {
                "stability_jaccard": cat_stability,
                "mean_top3_delta_severe_prob": cat_mean_delta,
                "sample_case": cat_cases[0]["top3"] if cat_cases else [],
                "native_global_top3": _native_importance_top3_cat(cat_artifacts, cat_features),
            },
        },
        "winner": winner,
    }


def _fmt(v: float) -> str:
    return f"{v:.4f}"


def build_report(results: dict) -> str:
    extra = results["models"]["ExtraNGvboost"]
    cat = results["models"]["CatBoost"]
    return "\n".join(
        [
            "# Explainability Stability Report",
            "",
            "- Method: local perturbation (occlusion) of active symptoms and change in Severe probability.",
            f"- Cases evaluated (true Severe): `{results['evaluated_cases']}`",
            f"- Winner (cleaner/stabler top-3 drivers): `{results['winner']}`",
            "",
            "| Model | Stability (Mean Pairwise Jaccard) | Mean Top-3 Delta Severe Prob |",
            "| --- | --- | --- |",
            f"| ExtraNGvboost | {_fmt(extra['stability_jaccard'])} | {_fmt(extra['mean_top3_delta_severe_prob'])} |",
            f"| CatBoost | {_fmt(cat['stability_jaccard'])} | {_fmt(cat['mean_top3_delta_severe_prob'])} |",
            "",
            "## Example Top-3 Drivers (First Severe Case)",
            "",
            f"- ExtraNGvboost: `{extra['sample_case']}`",
            f"- CatBoost: `{cat['sample_case']}`",
            "",
            "## Native Global Importance (Severity Model)",
            "",
            f"- ExtraNGvboost native top-3: `{extra['native_global_top3']}`",
            f"- CatBoost native top-3: `{cat['native_global_top3']}`",
            "",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate explainability stability for both models.")
    parser.add_argument("--max-cases", type=int, default=60)
    args = parser.parse_args()

    results = run(max_cases=args.max_cases)
    JSON_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")
    REPORT_PATH.write_text(build_report(results), encoding="utf-8")

    print(f"Saved explainability JSON to: {JSON_PATH}")
    print(f"Saved explainability report to: {REPORT_PATH}")
    print(f"Explainability winner: {results['winner']}")


if __name__ == "__main__":
    main()

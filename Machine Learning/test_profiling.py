from __future__ import annotations

import argparse
import json
import statistics
import time
from pathlib import Path

import psutil

from model_a_extrang_wrapper import load_predictor, predict_from_symptoms as predict_extra
from model_b_catboost_wrapper import get_feature_columns, predict_from_symptoms as predict_cat
from model_b_catboost_wrapper import train_models
from system_eval_utils import load_standardized_test_set, row_to_symptoms, symptom_columns_from_df


EVAL_DIR = Path(__file__).resolve().parent
JSON_PATH = EVAL_DIR / "profiling_results.json"
REPORT_PATH = EVAL_DIR / "profiling_report.md"


def _rss_mb() -> float:
    proc = psutil.Process()
    return float(proc.memory_info().rss / (1024 * 1024))


def _profile_callable(fn, runs: int) -> dict[str, float]:
    times_ms: list[float] = []
    peak_rss = _rss_mb()

    for _ in range(runs):
        before = _rss_mb()
        t0 = time.perf_counter()
        fn()
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        after = _rss_mb()

        times_ms.append(elapsed_ms)
        peak_rss = max(peak_rss, before, after)

    p95 = sorted(times_ms)[max(0, int(0.95 * len(times_ms)) - 1)]
    return {
        "mean_ms": float(statistics.mean(times_ms)),
        "median_ms": float(statistics.median(times_ms)),
        "p95_ms": float(p95),
        "min_ms": float(min(times_ms)),
        "max_ms": float(max(times_ms)),
        "peak_rss_mb": float(peak_rss),
    }


def _fmt(v: float) -> str:
    return f"{v:.3f}"


def run(runs: int = 100) -> dict:
    test_df = load_standardized_test_set()
    severe_df = test_df[test_df["Severity"].astype(str) == "Severe"]
    row = severe_df.iloc[0] if len(severe_df) > 0 else test_df.iloc[0]
    symptoms = row_to_symptoms(row, symptom_columns_from_df(test_df))

    # ExtraNGvboost setup + profiling
    t0 = time.perf_counter()
    extra_predictor = load_predictor()
    extra_setup_s = time.perf_counter() - t0
    extra_profile = _profile_callable(
        lambda: predict_extra(symptoms, predictor_module=extra_predictor),
        runs=runs,
    )

    # CatBoost setup + profiling
    t0 = time.perf_counter()
    cat_artifacts = train_models()
    cat_features = get_feature_columns()
    cat_setup_s = time.perf_counter() - t0
    cat_profile = _profile_callable(
        lambda: predict_cat(symptoms, artifacts=cat_artifacts, feature_columns=cat_features),
        runs=runs,
    )

    winner = min(
        ["ExtraNGvboost", "CatBoost"],
        key=lambda m: (
            extra_profile["mean_ms"] if m == "ExtraNGvboost" else cat_profile["mean_ms"],
            extra_profile["peak_rss_mb"] if m == "ExtraNGvboost" else cat_profile["peak_rss_mb"],
        ),
    )

    return {
        "config": {"runs": runs},
        "single_patient_symptom_count": len(symptoms),
        "models": {
            "ExtraNGvboost": {
                "setup_time_seconds": float(extra_setup_s),
                **extra_profile,
            },
            "CatBoost": {
                "setup_time_seconds": float(cat_setup_s),
                **cat_profile,
            },
        },
        "winner": winner,
    }


def build_report(results: dict) -> str:
    extra = results["models"]["ExtraNGvboost"]
    cat = results["models"]["CatBoost"]
    return "\n".join(
        [
            "# Latency & Resource Profiling Report",
            "",
            f"- Profiling runs per model: `{results['config']['runs']}`",
            f"- Single patient symptom count: `{results['single_patient_symptom_count']}`",
            f"- Winner (faster/lighter inference): `{results['winner']}`",
            "",
            "| Model | Mean ms | P95 ms | Min ms | Max ms | Peak RAM MB | Setup Time s |",
            "| --- | --- | --- | --- | --- | --- | --- |",
            f"| ExtraNGvboost | {_fmt(extra['mean_ms'])} | {_fmt(extra['p95_ms'])} | {_fmt(extra['min_ms'])} | {_fmt(extra['max_ms'])} | {_fmt(extra['peak_rss_mb'])} | {_fmt(extra['setup_time_seconds'])} |",
            f"| CatBoost | {_fmt(cat['mean_ms'])} | {_fmt(cat['p95_ms'])} | {_fmt(cat['min_ms'])} | {_fmt(cat['max_ms'])} | {_fmt(cat['peak_rss_mb'])} | {_fmt(cat['setup_time_seconds'])} |",
            "",
            "Setup time is separated from per-patient inference time; production should preload models at service startup.",
            "",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Profile latency and RAM for model inference.")
    parser.add_argument("--runs", type=int, default=100)
    args = parser.parse_args()

    results = run(runs=args.runs)
    JSON_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")
    REPORT_PATH.write_text(build_report(results), encoding="utf-8")

    print(f"Saved profiling JSON to: {JSON_PATH}")
    print(f"Saved profiling report to: {REPORT_PATH}")
    print(f"Profiling winner: {results['winner']}")


if __name__ == "__main__":
    main()

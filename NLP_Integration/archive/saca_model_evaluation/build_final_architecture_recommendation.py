from __future__ import annotations

import json
from pathlib import Path


EVAL_DIR = Path(__file__).resolve().parent
BASELINE_PATH = EVAL_DIR / "evaluation_results.json"
NOISE_PATH = EVAL_DIR / "nlp_noise_results.json"
PROFILING_PATH = EVAL_DIR / "profiling_results.json"
EXPLAIN_PATH = EVAL_DIR / "explainability_results.json"
OUTPUT_PATH = EVAL_DIR / "final_architecture_recommendation.md"


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _fmt(v: float) -> str:
    return f"{v:.4f}"


def build() -> str:
    base = _read_json(BASELINE_PATH)
    noise = _read_json(NOISE_PATH)
    prof = _read_json(PROFILING_PATH)
    expl = _read_json(EXPLAIN_PATH)

    missing = []
    for name, obj in [
        ("evaluation_results.json", base),
        ("nlp_noise_results.json", noise),
        ("profiling_results.json", prof),
        ("explainability_results.json", expl),
    ]:
        if not obj:
            missing.append(name)

    if missing:
        return "\n".join(
            [
                "# Final Architecture Recommendation",
                "",
                "Missing prerequisite outputs:",
                *[f"- `{m}`" for m in missing],
                "",
                "Run `run_evaluation.py`, `test_nlp_noise.py`, `test_profiling.py`, and `test_explainability.py` first.",
                "",
            ]
        )

    points = {"ExtraNGvboost": 0, "CatBoost": 0}
    points[base["winners"]["disease"]] += 1
    points[base["winners"]["severity"]] += 2
    points[noise["winner"]] += 3
    points[prof["winner"]] += 2
    points[expl["winner"]] += 2

    winner = max(points.keys(), key=lambda m: points[m])
    rationale = (
        f"`{winner}` receives the highest weighted QA score ({points[winner]} points). "
        "Weights prioritize clinical safety and real-world robustness over isolated benchmark accuracy."
    )

    noise_drop = noise["drops"][winner]
    model_profile = prof["models"][winner]
    model_expl = expl["models"][winner]

    json_contract = """```json
{
  "triage_result": {
    "disease": "sepsis",
    "severity": "Severe",
    "confidence": {
      "disease": 0.91,
      "severity": 0.88
    },
    "explanations": {
      "top_driving_symptoms": [
        {"symptom": "sharp chest pain", "impact": 0.27},
        {"symptom": "shortness of breath", "impact": 0.20},
        {"symptom": "fever", "impact": 0.14}
      ]
    },
    "human_verification": {
      "raw_transcript": "...",
      "edited_transcript": "...",
      "mapped_symptoms": ["sharp chest pain", "shortness of breath", "fever"],
      "unmapped_tokens": ["pan", "real bad"],
      "review_required": false
    },
    "safety": {
      "severe_recall_priority": true,
      "escalate_if_severe_or_low_confidence": true
    }
  }
}
```"""

    return "\n".join(
        [
            "# Final Architecture Recommendation",
            "",
            "## Recommended Winning Model",
            "",
            f"- **Winner:** `{winner}`",
            f"- **Why:** {rationale}",
            "",
            "## QA Scorecard",
            "",
            f"- Baseline disease winner: `{base['winners']['disease']}`",
            f"- Baseline severity winner: `{base['winners']['severity']}`",
            f"- NLP noise robustness winner: `{noise['winner']}`",
            f"- Latency/resource winner: `{prof['winner']}`",
            f"- Explainability winner: `{expl['winner']}`",
            f"- Weighted points: `{points}`",
            "",
            "## Winner Metrics Snapshot",
            "",
            f"- Noise drop (disease F1 weighted): `{_fmt(noise_drop['disease_f1_weighted_drop'])}`",
            f"- Noise drop (severity F1 weighted): `{_fmt(noise_drop['severity_f1_weighted_drop'])}`",
            f"- Noise drop (Severe recall): `{_fmt(noise_drop['severe_recall_drop'])}`",
            f"- Mean inference latency (ms): `{_fmt(model_profile['mean_ms'])}`",
            f"- P95 inference latency (ms): `{_fmt(model_profile['p95_ms'])}`",
            f"- Peak RAM (MB): `{_fmt(model_profile['peak_rss_mb'])}`",
            f"- Explainability stability (Jaccard): `{_fmt(model_expl['stability_jaccard'])}`",
            "",
            "## Next Steps Checklist (FastAPI + Flutter Human Verification)",
            "",
            "- [ ] Preload final model artifacts on FastAPI startup (avoid per-request model loading/training).",
            "- [ ] Integrate transcript edit history: keep both raw MMS output and human-corrected text.",
            "- [ ] Add NLP normalization stage (noise mapping + SBERT symptom mapping) before inference.",
            "- [ ] Add a low-confidence and severe-risk escalation rule before returning final triage.",
            "- [ ] Return top-3 symptom drivers for severity in the API response for clinician transparency.",
            "- [ ] Log per-request latency, peak RSS sample, model confidence, and manual override outcomes.",
            "- [ ] Add online QA monitors for severe recall drift and noisy-input failure rate.",
            "",
            "## Recommended FastAPI Response Shape",
            "",
            json_contract,
            "",
            "## Deployment Hardening Notes",
            "",
            "- Use a fixed model version tag and include it in each API response.",
            "- Add canary rollout with shadow evaluation on real edited transcripts.",
            "- Keep human override final in UI and feed overrides back into retraining datasets.",
            "",
        ]
    )


def main() -> None:
    report = build()
    OUTPUT_PATH.write_text(report, encoding="utf-8")
    print(f"Saved final recommendation report to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

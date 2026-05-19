# Final Architecture Recommendation

## Recommended Winning Model

- **Winner:** `CatBoost`
- **Why:** `CatBoost` receives the highest weighted QA score (7 points). Weights prioritize clinical safety and real-world robustness over isolated benchmark accuracy.

## QA Scorecard

- Baseline disease winner: `ExtraNGvboost`
- Baseline severity winner: `CatBoost`
- NLP noise robustness winner: `CatBoost`
- Latency/resource winner: `CatBoost`
- Explainability winner: `ExtraNGvboost`
- Weighted points: `{'ExtraNGvboost': 3, 'CatBoost': 7}`

## Winner Metrics Snapshot

- Noise drop (disease F1 weighted): `0.0426`
- Noise drop (severity F1 weighted): `0.0340`
- Noise drop (Severe recall): `0.0236`
- Mean inference latency (ms): `6.2653`
- P95 inference latency (ms): `7.7440`
- Peak RAM (MB): `535.8984`
- Explainability stability (Jaccard): `0.0892`

## Next Steps Checklist (FastAPI + Flutter Human Verification)

- [ ] Preload final model artifacts on FastAPI startup (avoid per-request model loading/training).
- [ ] Integrate transcript edit history: keep both raw MMS output and human-corrected text.
- [ ] Add NLP normalization stage (noise mapping + SBERT symptom mapping) before inference.
- [ ] Add a low-confidence and severe-risk escalation rule before returning final triage.
- [ ] Return top-3 symptom drivers for severity in the API response for clinician transparency.
- [ ] Log per-request latency, peak RSS sample, model confidence, and manual override outcomes.
- [ ] Add online QA monitors for severe recall drift and noisy-input failure rate.

## Recommended FastAPI Response Shape

```json
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
```

## Deployment Hardening Notes

- Use a fixed model version tag and include it in each API response.
- Add canary rollout with shadow evaluation on real edited transcripts.
- Keep human override final in UI and feed overrides back into retraining datasets.

# NLP Noise Robustness Report

- Samples evaluated: `3`
- SBERT model: `all-MiniLM-L6-v2`
- Winner (least performance drop): `ExtraNGvboost`

## Drop Summary (Lower is Better)

| Model | Disease F1w Drop | Severity F1w Drop | Severe Recall Drop | Combined Drop Score |
| --- | --- | --- | --- | --- |
| ExtraNGvboost | 0.0000 | 0.0000 | 0.0000 | 0.0000 |
| CatBoost | 0.0000 | 0.0000 | 0.0000 | 0.0000 |

## Mapping Quality

- Average clean symptom count per sample: `6.0000`
- Average mapped symptom count after noise+SBERT: `5.6667`

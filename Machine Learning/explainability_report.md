# Explainability Stability Report

- Method: local perturbation (occlusion) of active symptoms and change in Severe probability.
- Cases evaluated (true Severe): `80`
- Winner (cleaner/stabler top-3 drivers): `ExtraNGvboost`

| Model | Stability (Mean Pairwise Jaccard) | Mean Top-3 Delta Severe Prob |
| --- | --- | --- |
| ExtraNGvboost | 0.0908 | 0.0834 |
| CatBoost | 0.0892 | 0.0630 |

## Example Top-3 Drivers (First Severe Case)

- ExtraNGvboost: `[{'symptom': 'fainting', 'delta_severe_prob': 0.469}, {'symptom': 'nausea', 'delta_severe_prob': 0.039000000000000035}]`
- CatBoost: `[{'symptom': 'fainting', 'delta_severe_prob': 0.33799999999999997}, {'symptom': 'nausea', 'delta_severe_prob': 0.11199999999999999}]`

## Native Global Importance (Severity Model)

- ExtraNGvboost native top-3: `[{'symptom': 'weakness', 'importance': 0.0988244830865019}, {'symptom': 'headache', 'importance': 0.04438261471133959}, {'symptom': 'sharp chest pain', 'importance': 0.034929947572777946}]`
- CatBoost native top-3: `[{'symptom': 'weakness', 'importance': 10.029262115835495}, {'symptom': 'headache', 'importance': 5.470713435821892}, {'symptom': 'sharp chest pain', 'importance': 3.4602612455196953}]`
